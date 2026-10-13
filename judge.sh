#!/bin/bash
# ============================================================
# FROZEN JUDGE. The agent must never edit this file.
# Scores one thing: line coverage of the target package, as a
# percentage. Prints exactly one final line:  SCORE: <number>
# Score is 0 if any test fails or any guardrail is broken.
#
# Platform-neutral port of the Apex judge (July 2026). Works on
# any Python project laid out as  <pkg>/  +  tests/  with pytest.
# ============================================================
set -u
cd "$(dirname "$0")"
HARNESS_DIR="$(pwd)"

TARGET_DIR="${TARGET_DIR:-$HARNESS_DIR/work/example_target}"
PKG="${TARGET_PKG:-calcpkg}"
PY="$HARNESS_DIR/.venv/bin/python"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"

fail() { echo "JUDGE FAIL: $1"; echo "SCORE: 0"; exit 0; }

[ -x "$PY" ] || fail "no virtualenv, run ./setup.sh first"
cd "$TARGET_DIR" || fail "target dir not found: $TARGET_DIR"

# What did the agent touch? (vs last commit of the TARGET repo)
CHANGED_ALL=$(git status --porcelain | awk '{print $NF}')
CHANGED_TESTS=$(echo "$CHANGED_ALL" | grep -E '^tests/.*\.py$' || true)
DELETED=$(git status --porcelain | awk '$1=="D" {print $2}')

# ---- Guardrail 1: only files under tests/ may change -----------
for f in $CHANGED_ALL; do
  case "$f" in
    tests/*.py) ;;
    *) fail "non-test file changed: $f (source, config, and harness files are off limits)";;
  esac
done

# ---- Guardrail 2: no test file deleted -------------------------
[ -z "$DELETED" ] || fail "test file deleted: $DELETED"

# ---- Guardrail 3: conftest.py is frozen ------------------------
echo "$CHANGED_TESTS" | grep -q 'conftest\.py' && fail "tests/conftest.py changed (fixtures and plugins are frozen)"

# ---- Guardrail 4: test count must not shrink -------------------
OLD_COUNT=$(git grep -hoE '^\s*(async )?def test_' HEAD -- 'tests/*.py' 2>/dev/null | wc -l | tr -d ' ')
NEW_COUNT=$(grep -rhoE '^\s*(async )?def test_' tests --include='*.py' 2>/dev/null | wc -l | tr -d ' ')
[ "$NEW_COUNT" -ge "$OLD_COUNT" ] || fail "test count shrank ($OLD_COUNT -> $NEW_COUNT), deleting tests is cheating"

# Per-file guardrails on changed test files only (legacy files grandfathered)
for f in $CHANGED_TESTS; do
  [ -f "$f" ] || continue

  # ---- Guardrail 5: no new skip / xfail markers ----------------
  OLD_SKIPS=$(git show "HEAD:$f" 2>/dev/null | grep -cE 'pytest\.(mark\.)?(skip|xfail)|@skip|unittest\.skip' || true)
  NEW_SKIPS=$(grep -cE 'pytest\.(mark\.)?(skip|xfail)|@skip|unittest\.skip' "$f" || true)
  [ "${NEW_SKIPS:-0}" -le "${OLD_SKIPS:-0}" ] || fail "skip/xfail marker added in $f"

  # ---- Guardrail 6: no trivial always-true assertions ----------
  grep -qE '^\s*assert\s+(True|1|not\s+False|not\s+None)\s*(#.*)?$' "$f" && fail "trivial assertion in $f"

  # ---- Guardrail 7: changed test files must really assert ------
  grep -qE '\bassert\b|pytest\.raises|assertEqual|assertTrue|assertRaises' "$f" || fail "no assertions in $f"

  # ---- Guardrail 8: no coverage tampering from inside tests ----
  grep -qE 'pragma:\s*no\s*cover|import coverage|from coverage|COVERAGE_|--no-cov|pytest\.main' "$f" && fail "coverage tampering in $f"

  # ---- Guardrail 9: no sys.exit / os._exit to short-circuit ----
  grep -qE 'sys\.exit|os\._exit' "$f" && fail "process exit call in $f"
done

# ---- Run the tests with coverage ------------------------------
rm -f coverage.json .coverage
# Portable timeout (macOS has no `timeout` binary): run pytest in the
# background and kill it if it outlives TEST_TIMEOUT seconds.
"$PY" -m pytest -q -p no:cacheprovider \
  --cov="$PKG" --cov-report=json:coverage.json --cov-report=term-missing:skip-covered \
  tests > .last_test_output.txt 2>&1 &
TPID=$!; T0=$(date +%s)
while kill -0 "$TPID" 2>/dev/null && [ $(( $(date +%s) - T0 )) -lt "$TEST_TIMEOUT" ]; do sleep 1; done
if kill -0 "$TPID" 2>/dev/null; then kill "$TPID" 2>/dev/null; wait "$TPID" 2>/dev/null; fail "tests timed out after ${TEST_TIMEOUT}s"; fi
wait "$TPID"; RC=$?
if [ "$RC" -ne 0 ]; then
  echo "JUDGE FAIL: tests failed (pytest exit $RC):"
  grep -E '^(FAILED|ERROR)' .last_test_output.txt | head -10 | sed 's/^/JUDGE FAIL:   /'
  echo "SCORE: 0"; exit 0
fi
[ -f coverage.json ] || fail "no coverage.json produced"

"$PY" - <<'PY'
import json
d = json.load(open("coverage.json"))
t = d["totals"]
covered, total = t["covered_lines"], t["num_statements"]
pct = round(100.0 * covered / total, 1) if total else 0.0
files = sorted(((f, v["summary"]["percent_covered"]) for f, v in d["files"].items()),
               key=lambda x: x[1])
print(f"COVERAGE: {covered}/{total} lines covered across {len(files)} files")
worst = [f"{f} {p:.0f}%" for f, p in files[:3] if p < 100]
if worst: print("JUDGE: lowest coverage (targetable): " + ", ".join(worst))
print("JUDGE: 95% target MET" if pct >= 95 else f"JUDGE: target 95%, {round(95 - pct, 1)} points to go")
print(f"SCORE: {pct}")
PY

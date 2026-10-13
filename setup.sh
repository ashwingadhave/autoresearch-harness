#!/bin/bash
# One-time setup: private virtualenv + test tools. Nothing global is touched.
set -eu
cd "$(dirname "$0")"
if [ ! -d .venv ]; then python3 -m venv .venv; fi
./.venv/bin/pip install --quiet --upgrade pip
./.venv/bin/pip install --quiet pytest pytest-cov
echo "OK: tools installed in $(pwd)/.venv"
# The loop needs a target that is its own git repo (to keep/revert). We never
# run on the pristine example_target; we copy it to work/ and git-init the copy.
# Re-run ./setup.sh --reset to throw away the working copy and start fresh.
if [ "${1:-}" = "--reset" ]; then rm -rf work/example_target; fi
if [ ! -d work/example_target/.git ]; then
  mkdir -p work && rm -rf work/example_target && cp -R example_target work/example_target
  ( cd work/example_target && git init -q && git add -A && git commit -qm "baseline" )
  echo "OK: working copy created at work/example_target (its own git repo)"
fi

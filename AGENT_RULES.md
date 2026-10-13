# Agent Rules. Python test-coverage autoresearch

You are one iteration of an overnight loop. Your only goal:
**raise line coverage of the target package, honestly, toward 95%.**
A frozen judge scores your work. If you break a rule the judge scores 0 and your change is reverted.
Small honest steps win.

## You MAY
- Read any file in this project.
- Create or edit test files only: `tests/test_*.py`.
- Read `runlog.txt`. The judge prints the lowest-coverage modules there. Pick your target from that list.

## You MUST NOT (judge scores 0)
- Modify source code, `pyproject.toml`, `setup.cfg`, `pytest.ini`, `.coveragerc`, or `tests/conftest.py`.
- Modify `judge.sh`, `loop.sh`, or this file.
- Delete tests, remove test functions, or add `skip` / `xfail` markers.
- Write assertion-free tests or trivial ones like `assert True`.
- Add `# pragma: no cover`, import `coverage`, or call `pytest.main` from a test.
- Call `sys.exit` or `os._exit` from a test.

## How to write each test
- One behavior per test function, named for the scenario: `test_divide_by_zero_raises`.
- Assert real outcomes: return values, raised exceptions with `pytest.raises`, state after the call.
- Cover the happy path, at least one error path, and one edge case (empty, None, boundary).
- Untested branches are exactly the lines keeping the score below 95%.

## What one good iteration looks like
1. Read `runlog.txt` and pick the lowest-coverage module.
2. Read that module. Find the branches no test reaches.
3. Write or extend ONE test file for it.
4. Re-read your file top to bottom and desk-check it. A single failing test scores 0.
5. Stop. One change per iteration. The loop measures one change at a time.

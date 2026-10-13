#!/bin/bash
# One-time setup: private virtualenv + test tools. Nothing global is touched.
set -eu
cd "$(dirname "$0")"
if [ ! -d .venv ]; then python3 -m venv .venv; fi
./.venv/bin/pip install --quiet --upgrade pip
./.venv/bin/pip install --quiet pytest pytest-cov
echo "OK: tools installed in $(pwd)/.venv"
# The example target must be its own git repo so the loop can keep/revert.
if [ ! -d example_target/.git ]; then
  ( cd example_target && git init -q && git add -A && git commit -qm "baseline" )
  echo "OK: example_target initialised as a git repo"
fi

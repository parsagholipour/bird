#!/usr/bin/env bash
# Runs the Flutter test suite under a machine-wide lock. Every copy of the
# tree (rehearsals, ../*-ws workspaces) shares the lock, so a second broad
# run waits for the first instead of both fighting over the CPU.
#
#   tool/test_full.sh                     the whole suite
#   tool/test_full.sh -r failures-only    extra arguments go to flutter test
#   JOBS=4 tool/test_full.sh              fewer test processes (default 8)
set -euo pipefail
cd "$(dirname "$0")/.."

lock=/tmp/push-up-bird-tests.lock
exec 9>>"$lock"
if ! flock -n 9; then
  echo "Waiting for another test run: $(cat "$lock")" >&2
  flock 9
fi
echo "${TEST_RUN:-full} suite, pid $$, $PWD, since $(date '+%H:%M:%S')" > "$lock"

# flutter and its test processes inherit the lock, so it is held until the
# last of them exits, even if this script is killed first.
nice -n 10 "${FLUTTER:-flutter}" test -j "${JOBS:-8}" "$@"

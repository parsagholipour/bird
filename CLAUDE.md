# Push-Up Bird

## Running tests

Many sessions share this machine and run tests in copies of this tree (rehearsals, `../*-ws` workspaces). Overlapping full suites have run 2–5× slower than the ~4.5 min a quiet machine needs and pushed it into swap, so broad runs share one machine-wide lock and queue:

- **Iterating**: run only the files your change touches: `flutter test test/a_test.dart test/b_test.dart`.
- **Broad check**: `tool/test_fast.sh`, the suite minus the heavy files in `tool/slow_tests.txt`.
- **Landing**: `tool/test_full.sh` once, after the change is final (`make test` is analyze plus this).

Both scripts may wait for the lock and then run for minutes: start them with `run_in_background` and send the output to a log in your scratchpad, e.g. `tool/test_full.sh -r failures-only > "$SP/full.log" 2>&1`. Extra arguments go to `flutter test`; `JOBS=4` lowers the process count (default 8). In a copy of the tree, run that copy's `tool/test_full.sh` (copy the script into older copies that lack it) so the copy queues on the same lock.

A test file that takes 15 s or more in a broad run belongs in `tool/slow_tests.txt`.

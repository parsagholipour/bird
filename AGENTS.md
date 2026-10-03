# Push-Up Bird

## Test selection

Use the smallest set of checks that covers the changed behavior. A passing
targeted check is sufficient to finish a scoped change; committing or opening
a PR does not itself require a broad suite.

1. Inspect the diff and identify the behaviors and callers affected. Find tests
   with `rg` using the changed symbols, imports, and feature names in `test/`
   and `tool/`. Follow shared helpers and indirect callers; matching filenames
   alone is not enough.
2. Before running tests, state the selected files and what they cover. For a
   bug, start with the reproducing test; after the fix, run the affected test
   files and any relevant integration or regression tests.
3. Use `make test TESTS="test/a_test.dart test/b_test.dart"` for analysis and
   selected files. During iteration, `flutter test -j 2 test/a_test.dart
   --plain-name 'test description'` can narrow a reproduction; finish with the
   relevant file(s) without the name filter. Include affected tests from
   `tool/` when changing tooling.
4. Include relevant slow tests even if they appear in `tool/slow_tests.txt`.
   That list is a cost hint, not permission to omit affected coverage.
5. Stop once the required checks pass on the final relevant code. Rerun only
   when subsequent edits invalidate those results or a failure needs diagnosis.
   Report the commands, results, and material coverage gaps. Describe targeted
   results as targeted; never imply the full suite passed.

For documentation-only changes, inspect the diff and links; Flutter tests are
unnecessary. For scripts or build commands, validate the changed commands with
focused syntax checks or a stub runner before considering application tests.

## Broad checks

Use `make test-fast` only when affected coverage spans several features or
cannot reasonably be isolated. It excludes slow files, so also select any
relevant excluded tests. Use `make test-full` for an explicit full-suite request,
a release validation task, or a cross-cutting change whose impact cannot be
covered reliably by selected tests (for example SDK/dependency changes, shared
test infrastructure, or pervasive game-rule/replay changes). Explain the
concrete coverage need before a broad run. Choose the needed scope directly;
running targeted, fast, and full suites in succession is not a default ladder.
Never use bare `flutter test` or `flutter test test/` as a routine final check.

Many sessions share this machine. Broad runs must use `tool/test_fast.sh` or
`tool/test_full.sh` (also used by the Make targets) to share the machine-wide
lock. In another checkout, use that checkout's scripts. Queue one broad run
after the final relevant edit, retain its log, and wait for its result instead
of starting another. Extra script arguments go to Flutter; `JOBS=4` lowers the
default process count of 8. A file taking 15 seconds or more in a broad run
belongs in `tool/slow_tests.txt`.

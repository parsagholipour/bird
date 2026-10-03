#!/usr/bin/env bash
# The suite minus the heavy files listed in tool/slow_tests.txt, under the
# same lock as tool/test_full.sh. Arguments and JOBS work the same way.
set -euo pipefail
cd "$(dirname "$0")/.."

declare -A slow=()
while read -r f _; do
  [[ -z $f || $f == \#* ]] && continue
  [[ -f test/$f ]] || echo "tool/slow_tests.txt: test/$f no longer exists" >&2
  slow[$f]=1
done < tool/slow_tests.txt

files=()
while IFS= read -r f; do
  [[ -n ${slow[${f#test/}]:-} ]] || files+=("$f")
done < <(find test -name '*_test.dart' | sort)

TEST_RUN=fast exec tool/test_full.sh "$@" "${files[@]}"

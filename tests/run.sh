#!/usr/bin/env bash
# Test runner: compiles every tests/unit/*.typ file. A test passes if it
# compiles without errors (tests use `assert`/`panic` to fail).
set -u
cd "$(dirname "$0")/.."

fail=0
pass=0
filter="${1:-}"

for f in tests/unit/*.typ; do
    name="$(basename "$f")"
    if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
        continue
    fi
    out="$(typst compile --root . -f pdf "$f" /dev/null 2>&1)"
    if [[ $? -eq 0 ]]; then
        pass=$((pass + 1))
        echo "PASS $name"
    else
        fail=$((fail + 1))
        echo "FAIL $name"
        echo "$out" | sed 's/^/     /'
    fi
done

echo "----"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]

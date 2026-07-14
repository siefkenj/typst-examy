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

# tests/unit/config.typ marks <show-solutions-effective> only when the
# effective show-solutions value (as seen through elembic's e.get) is true,
# with config itself set to `false`. Check all three --input states so the
# `--input show-solutions=..` CLI override is verified against config, not
# just its no-input fallback.
if [[ -z "$filter" || "config.typ" == *"$filter"* ]]; then
    check_show_solutions() {
        local input="$1" expected="$2"
        local args=()
        [[ -n "$input" ]] && args=(--input "show-solutions=$input")
        local got
        got="$(typst eval --root . "query(<show-solutions-effective>).len() > 0" --in tests/unit/config.typ "${args[@]}" 2>&1)"
        if [[ "$got" == "$expected" ]]; then
            pass=$((pass + 1))
            echo "PASS config.typ (show-solutions=${input:-none})"
        else
            fail=$((fail + 1))
            echo "FAIL config.typ (show-solutions=${input:-none}): expected $expected, got $got"
        fi
    }
    check_show_solutions "" false
    check_show_solutions "true" true
    check_show_solutions "false" false
fi

echo "----"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]

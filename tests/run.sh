#!/usr/bin/env bash
# Test runner: compiles every tests/unit/*.typ file. A test passes if it
# compiles without errors (tests use `assert`/`panic` to fail). The
# documents in tests/not-laid-out/ are checked for examy's warning (see below).
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

# Each command-line option is also read by its name in the singular, so that
# either spelling works; given both, they must agree.
if [[ -z "$filter" || "constants" == *"$filter"* ]]; then
    check_input() {
        local name="$1" expected="$2"
        shift 2
        local args=()
        for i in "$@"; do args+=(--input "$i"); done
        local got
        got="$(typst eval --root . "{ import \"/src/constants.typ\": $name; $name }" --in tests/unit/config.typ "${args[@]}" 2>&1)"
        if [[ "$got" == *"$expected"* ]]; then
            pass=$((pass + 1))
            echo "PASS constants ($name with $*)"
        else
            fail=$((fail + 1))
            echo "FAIL constants ($name with $*): expected $expected, got $got"
        fi
    }
    check_input SHOW_RUBRICS_OVERRIDE null
    check_input SHOW_RUBRICS_OVERRIDE true show-rubrics=true
    check_input SHOW_RUBRICS_OVERRIDE true show-rubric=true
    check_input SHOW_RUBRICS_OVERRIDE false show-rubric=false show-rubrics=false
    check_input SHOW_RUBRICS_OVERRIDE "disagree" show-rubric=true show-rubrics=false
    check_input SHOW_SOLUTIONS_OVERRIDE false show-solution=false
    check_input SHOW_SOLUTIONS_OVERRIDE "disagree" show-solution=false show-solutions=true
    check_input SHOW_RUBRICS_OVERRIDE "must be \`true\` or \`false\`, got \`yes\`" show-rubric=yes
    check_input SHOW_RUBRICS_OVERRIDE "must be \`true\` or \`false\`, got \`yes\`" show-rubrics=true show-rubric=yes
    check_input SHOW_SOLUTIONS_OVERRIDE "must be \`true\` or \`false\`, got \`1\`" show-solutions=1
fi

# tests/unit/answer-box-exam-view.typ must hold whatever the
# `--input show-solutions=..` override says, which wins over `config`; the
# loop above compiled it with none.
if [[ -z "$filter" || "answer-box-exam-view.typ" == *"$filter"* ]]; then
    for input in true false; do
        out="$(typst compile --root . -f pdf --input "show-solutions=$input" tests/unit/answer-box-exam-view.typ /dev/null 2>&1)"
        if [[ $? -eq 0 ]]; then
            pass=$((pass + 1))
            echo "PASS answer-box-exam-view.typ (show-solutions=$input)"
        else
            fail=$((fail + 1))
            echo "FAIL answer-box-exam-view.typ (show-solutions=$input)"
            echo "$out" | sed 's/^/     /'
        fi
    done
fi

# tests/not-laid-out/*.typ each hold a question no exam lays out. By default
# (`--input _debug_panic=text-warning`) it must compile with examy's warning
# drawn in its place, one `<examy-warning>` each; with `_debug_panic=panic`,
# fail with examy's message instead; and with `_debug_panic=none`, compile
# with no warning at all.
for f in tests/not-laid-out/*.typ; do
    name="not-laid-out/$(basename "$f")"
    if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
        continue
    fi
    for mode in "" text-warning none; do
        args=()
        [[ -n "$mode" ]] && args=(--input "_debug_panic=$mode")
        expected='["not-laid-out"]'
        [[ "$mode" == none ]] && expected='[]'
        got="$(typst eval --root . "query(<examy-warning>).map(m => m.value.kind)" --in "$f" "${args[@]}" 2>&1)"
        if [[ "$got" == "$expected" ]]; then
            pass=$((pass + 1))
            echo "PASS $name (_debug_panic=${mode:-default}: $expected)"
        else
            fail=$((fail + 1))
            echo "FAIL $name (_debug_panic=${mode:-default}): expected $expected, got $got"
        fi
    done
    out="$(typst compile --root . -f pdf --input _debug_panic=panic "$f" /dev/null 2>&1)"
    if [[ $? -ne 0 && "$out" == *"was not laid out by an exam"* ]]; then
        pass=$((pass + 1))
        echo "PASS $name (_debug_panic=panic fails)"
    else
        fail=$((fail + 1))
        echo "FAIL $name (_debug_panic=panic): expected the not-laid-out error"
        echo "$out" | sed 's/^/     /'
    fi
done

# tests/fail/*.typ must each fail to compile, with the message their first
# line gives after `// expect: `.
for f in tests/fail/*.typ; do
    name="fail/$(basename "$f")"
    if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
        continue
    fi
    expected="$(head -n 1 "$f" | sed -n 's|^// expect: ||p')"
    out="$(typst compile --root . -f pdf "$f" /dev/null 2>&1)"
    if [[ $? -ne 0 && -n "$expected" && "$out" == *"$expected"* ]]; then
        pass=$((pass + 1))
        echo "PASS $name (fails as expected)"
    else
        fail=$((fail + 1))
        echo "FAIL $name: expected an error with: $expected"
        echo "$out" | sed 's/^/     /'
    fi
done

echo "----"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]

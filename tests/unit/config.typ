// Verifies (via tests/run.sh) that `show-solutions(get)` (src/elements/solution.typ)
// prefers a `--input show-solutions=..` command-line override over the value set on
// `config`, and otherwise falls back to `config`'s value, when read through elembic's
// `e.get`.
//
// Marks <show-solutions-effective> only when the effective value is `true`.
// tests/run.sh checks for that label's presence with `typst eval ... query(..)`
// under each --input state, rather than asserting inline here, so the same
// compiled document can be inspected for all three states from the shell.
#import "/src/lib.typ": *

#show: e.prepare()
// Deliberately the opposite of what a "true" override would give, so a
// present label can't be confused with just reading back the config value.
#show: e.set_(config, show-solutions: false)

#e.get(get => {
  if show-solutions(get) == true {
    [#metadata(none)<show-solutions-effective>]
  }
})

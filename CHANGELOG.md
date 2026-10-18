# Changelog

## 1.0.0 (unreleased)

- `show-solutions(get)` is now always `true` or `false`: unset, solutions
  are shown, as `#solution` and the bubbles already took it, and it is
  `true`, not `none`. `exam`'s `solutions-only` now agrees with them too: it
  hid its content when `show-solutions` was unset.
- **Breaking:** `question`, `part`, and `subpart` no longer take a
  `solution:` argument. Write the solution in the body, as `#solution[..]`,
  where it should be drawn. (The argument drew the solution after the
  division's parts, run into the last line of its text.)
- Documentation site: <https://siefkenj.github.io/typst-examy/>, with a guide
  whose examples are rendered from their own code, and a reference generated
  from the package itself. The README is shorter, and links to it.
- Every function checks its arguments: a misspelled argument or a value of
  the wrong type is reported at the call, naming the argument and the types
  it takes (e.g. "question: `points` must be int | float | none, got "2"").
  The messages of `question`, `part`, `subpart`, and `answer-box` read
  differently than before.
- Fixed: in a document with several exams (such as a bundle export of the
  exam and its key), `num-points`, `num-questions`, `num-bonus-points`, and
  `points-table` showed the last exam's numbers everywhere. Each is now about
  the exam it is in, else the next one, else the last.
- `question`, `part`, and `subpart` take a `height` (a length, or `1fr` for
  a share of what is left of the page): the division is laid out as one
  block of that height, in which `fr` answer boxes share what its text
  leaves. A `#pagebreak()` inside such a division is an error. An answer box
  (`stroke: none` for no border) is still the preferred way to give a
  question room to write in.
- Fixed: a `#show: e.set_(..)` rule inside a question or part hid the parts
  after it from the exam: they were drawn as plain text, unnumbered. The
  rule now applies to the rest of its division, parts included.
- **Breaking:** an answer box with no `height` now fits its content instead
  of always being `default_height` tall. A box holding only a prompt shrinks to
  the prompt; give it a height (e.g. `height: 2cm`) to keep room to write.
- Solutions in a box with no `height` take no space, so the answer key lays
  out exactly like the exam. `height: auto` makes the box grow to hold them.
- `choices(enumerate: ...)` puts labels (A, B, C, … or any numbering pattern)
  inside the bubbles. Set it for the whole document with `choices-enumerate`.
- New `config` options: `bubble-stroke` and `bubble-label-font`.
- A `choice`, and each choice of `choices(inline: true)`, is kept whole: when
  its text wraps, the further lines hang under the text instead of flowing
  under the bubble, as they already did one per line and in `columns`.
- Template: start a new exam with `typst init @preview/examy`.
- Points badges: `config`'s `points-position` puts them at the start (as
  before), in the left or right margin, or flush right at the end of the
  opening text; `points-format` draws them (e.g. `p => [[#p]]`, or another
  language). With `points-show-totals`, a question shows the total of its
  parts.
- Points table layouts, set on `config`: `points-table-direction` (vertical),
  `points-table-by` (page), `points-table-score` (an empty Score row),
  `points-table-bonus` (a Bonus row), and `points-table-max-columns`.
- Points per page: `page-points()`, and `page-score-box` for a page footer.
  Also `num-bonus-points`.
- `config`'s `division-numbering` sets how questions, parts, and subparts are
  numbered (e.g. `("Problem 1.", "(a)", "i.")`), and `strings` the words
  examy prints (Question, Points, Total, ...).
- `answer-box(stroke: ..)` sets the box's outline, or removes it (`none`).
- `solution(otherwise: ..)` shows content in the solution's place when
  solutions are hidden, such as lines to write on. In an answer box with no
  height, the key draws the solution over it, so the layout does not change.
- Fixed: a gutter label too long for the gutter now runs out into the margin
  instead of wrapping.
- Fixed: a body starting with a full-width answer box gets its label on the
  box's first line, not its last.
- Fixed: a labelled question or part whose body starts with a part (or a
  block) no longer leaves an empty line between the two labels.
- Fixed: a display equation in a question that contains a page break or an
  `fr` box is centered on the text again.

## 0.4.0 — 2026-10-05

- Multiple-choice bubbles: `choice`, `choices`.
- Solutions in an answer box widen automatically to fill it.
- Fixed the spacing of points on a question with no body.

## 0.3.0 — 2026-09-19

- `fr` answer boxes on the same page share the leftover space equally.

## 0.2.0 — 2026-07-14

- Redesign of the package.

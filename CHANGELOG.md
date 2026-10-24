# Changelog

## 1.0.0 (unreleased)

- `points-table(by: "part")` and `by: "subpart"` give a column per part or
  subpart. A question or part with points of its own keeps a column of them,
  so every point is in one column and the total is the same at every level.
  `config`'s `points-table-by` takes them too.
- A points table labels each column exactly as a reference to its question
  or part reads (so `numbering-full` labels a part "2 (a)"), and each label is
  a link to it. An unnumbered question (`number: none`) reads "??", as a
  reference to it does, instead of "–".
- Fixed: with `points-position: "end"`, a badge that wrapped to a line of
  its own, after a full-width answer box of fixed height in the line, was
  drawn at the left instead of flush right.
- Fixed: on a page of no fixed height (`#set page(height: auto)`), the badge
  at the `"end"` of a question or part with an `fr` answer box was drawn
  over what followed it, such as the next part's badge. An `fr` height comes
  to nothing on such a page, so the box is only its outline; the badge now
  follows it.
- The badge of bonus points (`intent: "bonus"`) reads "(2 bonus points)"
  instead of "(2 points)". It is drawn by the new option
  `bonus-points-format`, as `points-format` draws the others, e.g.
  `bonus-points-format: p => [(#p Bonuspunkte)]`.
- Fixed: content that takes no room, such as a labelled `#metadata(..)`, was
  left out of the exam when it stood alone at the start of a question's
  body, or next to an `fr` answer box, with nothing visible beside it: a
  `query` found nothing, and a link to its label failed. It is kept, and
  still takes no room.
- `answer-box` is an elembic element: set rules give it any of its fields,
  e.g. `#show: e.set_(answer-box, stroke: none)` for the whole document, or
  in a scope of their own. Redefining it with `.with(..)` still works. In an
  exam, which draws its boxes itself, only `e.set_` and `e.apply` rules apply
  to them, their `stroke`, `radius` and `outset` folded as elembic folds
  them, and an `e.reset` undoes them; elembic's other rules on answer boxes
  (`e.show_`, `e.cond-set`, `e.filtered`, `e.select`, and an `e.revoke` of a
  rule that set them) are an error, inside the exam or before it. Typst's own show rules
  on `e.selector(answer-box)` apply to the exam's boxes too.
- New options `answer-box-height`, `answer-box-width`,
  `answer-box-default-height` and `answer-box-default-width` give the
  `height`, `width`, `default-height` and `default-width` of every answer box
  that doesn't give its own, e.g.
  `#show: exam.with(answer-box-height: 1fr, answer-box-width: 100%)`. A box's
  own arguments win over a set rule on `answer-box`, which wins over the
  options; a box given `height: none` or `width: auto` keeps it.
- Fixed: an answer box inside another element, such as `align`, whose `fr`
  height came from a set rule on `answer-box` rather than its call, took the
  whole page, as the exam did not know it was `fr`.
- `answer-box`'s `default_height` and `default_width` are now
  `default-height` and `default-width`, kebab-case like the rest of examy.
  The old names still work, on a call or in a set rule, but are deprecated;
  given both, the new name wins, but a call's old name wins over a set
  rule's new one, as any call's field does.
- `choice`'s `bubble:` also takes `bubble` and `square-bubble`, as
  `choices`' does, so both take the same spellings of a shape. Only
  `"circle"` and `"square"` are documented; the others keep working.
- `presets.utoronto.name_fields` is now `presets.utoronto.name-fields`,
  kebab-case like the rest of examy. The old name still works, but is
  deprecated.
- A `question`, `part`, or `subpart` that no exam lays out shows a warning in
  red where it is: one outside any exam, or inside one but built where the
  exam cannot see it (inside a `context`, or by a show rule). Until now it
  was drawn as plain text, unnumbered, with no sign of the problem. The
  warning is also left as `metadata` labelled `<examy-warning>`, for a
  script to find. `--input _debug_panic=panic` makes it an error that stops
  the compile, and `--input _debug_panic=none` leaves the check out.
- `exam` can be a show rule: `#show: exam` makes the rest of the document the
  exam, and is now the recommended way to start one. `exam` also takes any
  `config` option, applied to everything in the exam (a cover page before the
  first question included) and nothing after it:
  `#show: exam.with(show-solutions: true, points-position: "end")`. The
  questions can be given positionally, `#exam[..]`, as well as with
  `questions:`. `exam` applies `#show: e.prepare()` to its own content, so a
  document only needs it for references from outside the exam. A set rule
  after `#show: exam` applies once to what follows it, as anywhere else (a
  `#set page(..)` starts one run of pages, not one per question). A `config`
  rule inside the exam that sets an option the exam reads once for all its
  questions (`numbering`, `points-position`, `show-rubrics`, ..) is an error,
  as it would change nothing.
- `answer-box`'s `solution:` argument is drawn exactly as a `#solution[..]`
  written at the end of the box's body, in a paragraph of its own. It no
  longer stretches to fill the rest of a box of set height.
- **Breaking:** `points-table` is a function, called as `#points-table()`,
  and takes its layout as arguments: `direction`, `by`, `score`, `bonus`,
  and `max-columns`. Each left out is `config`'s `points-table-..` option,
  as before. An old `#points-table` no longer draws the table: it shows the
  word "points-table". `page-score-box()` and `rubric-list()` are called the
  same way.
- **Breaking:** `maketitle` and `name-block` no longer force the DejaVu Sans
  Mono font: they are set in the document's font, like everything else. To
  keep the old look, set the font in a code block around them:
  ```typst
  #{
    set text(font: "DejaVu Sans Mono")
    maketitle()
    name-block()
  }
  ```
- **Breaking:** `exam` is a function, no longer an elembic element, so
  `e.set_(exam, ..)` and `e.show_(exam, ..)` no longer apply to it. (It had
  nothing to set but its questions.)
- Rubrics: `#rubric(points: ..)[..]` items, in a division's `rubric:` field
  or in its body (a solution, say) where the criterion is met, with groups
  (`pick: "one"` for alternatives) that can nest. `show-rubrics` draws each
  division's rubric in the margin (`rubric-position`), with a dotted line
  from each item written in the body to its place; a rubric takes no room,
  so the exam lays out the same with or without it. `rubric-list` lays out
  every rubric on its own, and every exam with rubrics leaves them in the
  document as data, `<examy-rubric>`, for `typst eval` to read out as JSON.
  The `rubric:` argument, accepted but ignored until now, is drawn.
- **Breaking:** `config`'s `show-rubric`, accepted but ignored until now, is
  `show-rubrics`, and so is its command-line option,
  `--input show-rubrics=..`. Both command-line options are also accepted in
  the singular, `--input show-rubric=..` and `--input show-solution=..`.
- **Breaking:** `config`'s `show-solutions` is `true` or `false`, `true` by
  default, as solutions were shown when it was unset; `none` is no longer
  accepted. `show-solutions(get)` is always `true` or `false` too, not
  `none`. `exam`'s `solutions-only` now agrees with `#solution` and the
  bubbles: it hid its content when `show-solutions` was unset.
- **Breaking:** `question`, `part`, and `subpart` no longer take a
  `solution:` argument. Write the solution in the body, as `#solution[..]`,
  where it should be drawn. (The argument drew the solution after the
  division's parts, run into the last line of its text.)
- Documentation site: <https://siefkenj.github.io/typst-examy/>, with a guide
  whose examples are rendered from their own code, a reference generated
  from the package itself, and a playground for writing an exam in the
  browser. The README is shorter, and links to it.
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
- `duration`, in `config` or given to `maketitle`, can also be content, shown
  as it is written: `duration: [1 h 50 min]`. A Typst `duration` is still
  shown in minutes.
- `choices(correct: ...)` also names a choice by the label drawn in its
  bubble, for choices labelled with `enumerate`: `correct: "C"`, or
  `correct: ("A", "C")` for several. Case and punctuation do not matter, so
  `"c"` and `"(c)"` work too. Indices still work, and the two can be mixed.
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
- Points per page: `num-points-page`, and `page-score-box` for a page
  footer. Also `num-bonus-points`.
- Every count is also a number, to compute or test with, in context:
  `get-num-points()`, `get-num-questions()`, `get-num-bonus-points()`, and
  `get-num-points-page(page: .., bonus: ..)`, e.g. a pass mark,
  `#context calc.ceil(get-num-points() * .6)`. `num-points` and the others
  show them, with no context to write.
- `config`'s `numbering` sets how questions, parts, and subparts are
  numbered, as `enum`'s `numbering` does: a pattern (`"1.a.i."`), a function
  of the number, or one of those per level (`("Problem 1.", "(a)", "i.")`).
  `numbering-full: true` numbers a part with its question's number too
  ("1.a."), as `enum`'s `full` does, in references as well; with one
  pattern per level, a level whose pattern has one counting symbol follows
  the number above it, after a thin space and without its trailing "." or
  "," ("1 (a)"), unless every level is a number in digits ("1.1."). `strings`
  sets the words examy prints (Question, Points, Total, ...).
- `answer-box(stroke: ..)` sets the box's outline, or removes it (`none`);
  `fill`, `radius`, `outset`, and `clip` work as `box`'s do.
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

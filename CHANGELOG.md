# Changelog

## 1.0.0 (unreleased)

### Breaking changes

- `points-table`, `page-score-box` and `rubric-list` are functions: write
  `#points-table()`. A bare `#points-table` now shows its name instead of a
  table.
- `maketitle` and `name-block` use the document's font instead of DejaVu Sans
  Mono. To keep the old look, set the font around them, e.g.
  `#{ set text(font: "DejaVu Sans Mono"); maketitle() }`.
- An answer box with no `height` fits its content instead of always being
  2cm tall. Give it a `height` to keep room to write below a prompt.
- `question`, `part` and `subpart` no longer take `solution:`. Write
  `#solution[..]` in the body, where it should be drawn.
- `config`'s `show-rubric` is now `show-rubrics`, and so is its command-line
  option, `--input show-rubrics=..`.
- `show-solutions` is `true` or `false` (`true` by default); `none` is no
  longer accepted.
- `exam` is a function, not an elembic element, so `e.set_(exam, ..)` and
  `e.show_(exam, ..)` no longer apply to it.

### Added

- Documentation site, <https://siefkenj.github.io/typst-examy/>, with a guide,
  a reference, and a playground for writing an exam in the browser.
- `#show: exam` makes the rest of the document the exam, and `exam` takes any
  `config` option: `#show: exam.with(show-solutions: true)`.
- Rubrics: `rubric` items and groups, drawn in the margin or after each
  question with `show-rubrics`, with a dotted line from where each item is
  written (`rubric-trace`, or an item's own `trace`), `rubric-list` for a
  grading guide, and the rubrics as data (`<examy-rubric>`) to export as
  JSON.
- Points: badges in the margin or at the end (`points-position`), drawn by
  `points-format` and `bonus-points-format`; totals of parts
  (`points-show-totals`); points tables by question, part, subpart or page
  (`granularity`), vertical, with Score and Bonus rows, split over several
  rows of columns; points per page (`num-points-page`, `page-score-box`); and
  the counts as numbers to compute with (`get-num-points()` and the others).
- Numbering: `numbering` and `numbering-full`, for the whole exam or for one
  question and its parts, and `strings` to translate the words examy prints.
- Answer boxes: set rules (`#show: e.set_(answer-box, ..)`), `stroke`,
  `fill`, `radius`, `outset` and `clip`, a fractional width (`width: 1fr`),
  and `config` options for every box's size and look (`answer-box-*`).
  Solutions in a box with no `height` take no space, so the key lays out like
  the exam.
- Solutions: `otherwise:`, shown in a solution's place on the exam, and their
  own `color` and `background-color`.
- Multiple choice: labels in the bubbles (`enumerate`, `choices-enumerate`),
  `correct:` by label (`correct: "C"`), and options for the bubbles' size,
  outline, spacing, label font and colors, and for the layout of every
  `choices` (`choices-inline`, `choices-columns`, `choices-gap`).
- A `config` rule inside an exam can change `points-format`,
  `bonus-points-format`, `points-position`, `points-show-totals`, the
  `rubric-*` options and `indent` for the questions after it, e.g.
  `#show: e.set_(config, points-position: "end")` before a section of the
  exam.
- Questions: `height`, `indent` (and `config`'s `indent`), and a warning in
  red where a question is drawn that no exam lays out.
- `duration` can be content, shown as written: `duration: [1 h 50 min]`.
- Every function checks its arguments, and an error names the argument and
  the types it takes.
- Template: `typst init @preview/examy`.

### Changed

- The badge of bonus points reads "(2 bonus points)".
- A points table labels each column as a reference to its question reads,
  and links to it.
- `answer-box`'s `solution:` is drawn like a `#solution[..]` at the end of the
  box, and no longer stretches to fill a box of set height.

### Deprecated

- `answer-box`'s `default_height` and `default_width`: use `default-height`
  and `default-width`.
- `presets.utoronto.name_fields`: use `presets.utoronto.name-fields`.
- `solution`'s `boxed`: ignored. Solutions are always drawn in a box.

### Fixed

- In a document with several exams, such as an exam and its key in one
  bundle, point counts, points tables and references are about their own
  exam.
- A set rule inside a question no longer hides the parts after it from the
  exam.
- Many fixes to the layout of points badges, question numbers, answer boxes,
  solutions and equations.

## 0.4.0 — 2026-10-05

- Multiple-choice bubbles: `choice`, `choices`.
- Solutions in an answer box widen automatically to fill it.
- Fixed the spacing of points on a question with no body.

## 0.3.0 — 2026-09-19

- `fr` answer boxes on the same page share the leftover space equally.

## 0.2.0 — 2026-07-14

- Redesign of the package.

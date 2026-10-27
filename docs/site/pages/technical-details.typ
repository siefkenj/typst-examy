#import "../template.typ": *

Examy is written entirely in Typst, heavily relying on #link(
  "https://typst.app/universe/package/elembic",
)[elembic] for managing settings and options. Understanding this document is not needed for using
examy, but might be of interest.

== No nested boxes

A straightforward implementation of examy would wrap each question/part/subpart in a box and apply
an appropriate inset. Unfortunately, `#pagebreak()` cannot work inside a #typst-link(
  "reference/layout/box/",
)[box] and, worse still, boxes can only negotiate #typst-link(
  "reference/layout/fraction/",
)[fractional units] if they are peers of each other. So, the box approach would make it impossible
to have a part and a subpart both share the remaining space on the page.

Instead, examy flattens all question/part/subpart contents and tags the start and end of each block
with #typst-link("reference/introspection/metadata/")[`metadata`]. The flat stream is then parsed,
indentation level is tracked, and peer boxes are produced, so that `#pagebreak()` and `fr` units can
negotiate space.

== Step 1: Questions are annotated with metadata

#api("question"), #api("part"), and #api("subpart") don't draw anything themselves. Each one returns
its body unchanged but between two invisible markers (`metadata` values) that record the points,
number, label, rubric, etc. associated with the question/part/subpart.

Additionally, a test is inserted into the content stream. This test is later removed if the exam is
well-formed, but it allows the query ```sh typst eval --in exam.typ 'query(<examy-warning>)'``` to
report information about a malformed exam.

== Step 2: Layout

#api("exam", arg: "[]") receives the question stream (with `metadata` tags already inserted). It
then runs through the following steps.

/ Tokenize: The question stream is scanned for examy's `metadata` and `#pagebreak()`s. The stream is
  split to give special handling to breaks as well as #typst-link(
    "reference/styling/#set-rules",
  )[`set`] and #typst-link(
    "reference/styling/#show-rules",
  )[`show` rules]. Warning markers are also removed from the stream. Everything else is kept whole.
  From here on, a question/part/subpart inside a box (e.g., list item, box, table, etc.) is an
  error.

/ Parse: The tokens become a tree of questions/parts/subparts with their numbers, points, and
  options pre-computed. This allows for a global analysis of the exam (e.g., for use in #api(
    "points-table",
    arg: "()",
  )) without appealing to `context` or `query`s.

/ Plan: A question with no `#pagebreak()` and no `fr` answer box is drawn using nested blocks. Any
  other question is split into peer blocks, each indented to appear as if it is nested.

/ Render: Each block is drawn with its number and points badge. Labelled questions/parts/subparts
  get a typst label that can be used for `@name` references, and the point information recorded for
  #api(
    "points-table",
    arg: "()",
  ), #api("num-points"), etc.

#note[
  _Note._ The downside of this parsing is that "click back" in tools like #link(
    "https://github.com/Myriad-Dreamin/tinymist",
  )[tinymist] can be broken since the source stream has been parsed and reconstructed. (Usually it
  works to click a sub-boxed item, like an equation.)
]

== Settings and elembic

The global #api("config") object as well as question references is controlled by elembic, which is
re-exported as #api("e").

/ Settings: The global #api("config") is an elembic element that is never drawn; its fields are
  examy's options. `#show: e.set_(config, ..)` works like a Typst `set` rule, applying until the end
  of its block, and `#show: exam.with(..)` applies its options the same way. Options are read with
  `e.get`, which, like Typst's `context`, gives the values in effect where it is placed. This is why
  #api("show-solutions", arg: "(get)") takes `get`.

  The exam reads its options where it starts. A `config` rule inside the exam applies to the
  questions in its scope, except for `numbering`, `numbering-full`, `strings`, and `show-rubrics`,
  which hold for the whole exam.

/ References: Each labelled question/part/subpart leaves an invisible elembic element as its anchor.
  Elembic lets an element decide how references to it are drawn, so a reference can show "1 (a)" or
  just "(a)" depending on where it is. `#show: e.prepare()` sets this up. The exam applies it to its
  own content, so a document only needs it for references from outside the exam.

While #api("solution") and #api("answer-box") are elembic elements, the #api("exam", arg: "[..]"),
#api(
  "question",
  arg: "[..]",
), #api("part", arg: "[..]"), and #api("subpart", arg: "[..]") commands are plain Typst functions.
However, during the _Render_ phase of examy, these items are typeset using elembic elements (and so
can respond to elembic's set rules).

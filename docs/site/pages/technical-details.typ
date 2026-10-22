#import "../template.typ": *

examy is written entirely in Typst. This page explains what happens when an exam is compiled. You
don't need it to write exams, but it explains why some things must be written the way they are, what
some error messages mean, and how examy relates to
#link("https://typst.app/universe/package/elembic")[elembic], the package it is built on.

== Why not boxes

A straightforward implementation of examy would wrap each question/part/subpart in a box and apply
an appropriate inset. Unfortunately, `#pagebreak()` cannot work inside a box and, worse still, boxes
can only negotiate fractional units if they are peers of each other. So, the box approach would make
it impossible to have a part and a subpart both share the remaining space on the page.

Instead, examy flattens all question/part/subpart contents and tags the start and end of each block
with `metadata`. The flat stream is then parsed, indentation level is tracked, and peer boxes are
produced, so that `#pagebreak()` and `fr` units can negotiate space. The rest of this page follows
those steps.

== Questions are markers

#api("question"), #api("part"), and #api("subpart") don't draw anything themselves. Each one returns
its body unchanged, between two invisible markers (`metadata` values) that record where the
question/part/subpart begins and ends, along with its arguments: points, number, label, rubric, and
so on. A part is a part only because its markers sit inside its question's markers. Nesting is
determined by position, not by which function was called, which is why `question`, `part`, and
`subpart` take the same arguments.

Each one also carries a check, beside its first marker, which the exam removes when it reads the
markers. A question that no exam lays out still has its check, which shows a warning in red where the
question is. That catches a question outside any exam, and one inside an exam but in content the exam
can't see into, such as a question built inside a `context`. Either would otherwise be drawn as plain
text, without a number. A script can find these warnings with
`typst eval --in exam.typ 'query(<examy-warning>)'`. The `--input _debug_panic=panic` command-line
option turns them into errors that stop the compile, for a build that must not produce a document
with one, and `--input _debug_panic=none` leaves the check out altogether.

== The exam lays them out

#api("exam") receives the questions as one piece of content and draws them in four steps: tokenize,
parse, plan, and render.

/ Tokenize: The content is scanned for markers and page breaks. Only content that contains one is
  taken apart, and only two kinds of content can be: plain sequences, and the result of a `set` or
  `show` rule (whose styles are remembered and applied again afterwards). Everything else is kept
  whole, which keeps lists, equations, and spacing intact. A part inside anything else, such as a
  list item, a box, or a table, can't be found in order, so it is an error: "Questions, parts, and
  subparts may only appear at the top level of their parent's body".

/ Parse: The tokens become a list of questions/parts/subparts, each with its level, number, address
  (2 (a) is question 2, part 1), points, and the total of its parts. This step works on plain data,
  without Typst counters or layout, so all the numbers are known before anything is drawn. That is
  why a reference can point forward, and why #api("points-table") can come before the exam.

/ Plan: Typst cannot break a page inside a nested block, and `fr` heights are only shared out at the
  top level of the page. A question with neither is drawn as one block, with its parts nested inside.
  A question with a `#pagebreak()` or an `fr` answer box is cut into blocks that sit side by side at
  the top level, each indented to look nested, so the break and the `fr` work as they do outside an
  exam.

/ Render: Each block is drawn with its number in the gutter and its points badge. A labelled
  question/part/subpart leaves an anchor for references, and the exam records its point totals for
  `points-table`, #api("num-points"), and the rest, which can read them anywhere in the document.

#note[
  _Note._ The downside of this parsing is that "click back" in tools like #link(
    "https://github.com/Myriad-Dreamin/tinymist",
  )[tinymist], from the rendered exam to its source, can be broken. (Usually it works to click a
  sub-boxed item, like an equation.)
]

== Settings and elembic

elembic adds custom elements to Typst: elements with typed fields that can be changed with elembic's
own `set` and `show` rules (`e.set_`, `e.show_`). examy re-exports it as #api("e") and uses it in
two ways.

/ Settings: The global #api("config") is an element that is never drawn; its fields are examy's
  options. `#show: e.set_(config, ..)` is a `set` rule for it, so a setting applies from where it is
  made to the end of its block, and a later rule only changes the options it names. Options given to
  the exam, as in `#show: exam.with(..)`, are applied the same way, around the exam's content. examy reads the
  options with `e.get`, which, like Typst's `context`, gives the values in effect where it is placed.
  This is why #api("show-solutions") takes `get`. The options that number and lay out the
  questions are read once, where the exam starts, so a rule inside the exam may not set them.

/ References: Each labelled question/part/subpart leaves an invisible elembic element, its anchor.
  elembic lets an element decide how references to it are drawn, so the anchor can show "1 (a)" or
  "(a)" depending on where the reference is. `#show: e.prepare()` installs the rules that make this
  work. The exam applies it to its own content, so a document only needs it for references from
  outside the exam.

#api("solution") is an elembic element too, but #api("exam"), `question`, `part`, `subpart`, and
the other functions are plain functions. An elembic element is drawn later, by a show rule, and
`exam` needs to see the markers in its questions as soon as it receives them. These functions still
declare their arguments with elembic's `e.field`, so every call is checked, and the reference is
generated from the same declarations.

#api("answer-box") is an elembic element as well, so that set rules can give its fields, and an
exam draws its boxes itself. When it receives its questions, it reads the boxes' fields and the
`answer-box-` options where it starts, with `get`. It then goes through the questions, applying the
`e.set_` and `e.apply` rules on answer boxes and on those options that it meets, to draw each box
from its call's own arguments, its fields, and the options, in that order. That is done once, in the
exam's own `e.get`, so that the exam can read every box's height and width as it reads any other
`box` or `block`, which it needs to share out `fr` heights and to place question numbers. A box
inside an element the exam doesn't go through, such as `align`, draws itself, and the exam leaves a
note of its `fr` height beside it. It also follows an `e.reset`, drawing the boxes after it as if no
rules had been set. Elembic's other rules on answer boxes inside an exam, such as `e.show_`, are an
error, since the exam does not follow them.

Use the `e` that examy exports rather than importing elembic yourself, since it is the version examy
was made with. examy's elements are named after its version, so two versions of examy in one
document don't share settings.

== Command line and data

The `--input show-solutions=..` and `--input show-rubrics=..` command-line options are read from
`sys.inputs` and override `config`. Rubrics in a margin are placed with `place`, so they take up no
space, and the exam is laid out the same with or without them. Every exam with rubrics also stores
them in the document as data, labelled `<examy-rubric>`, for `typst eval` to read out (see
#page-link("rubrics.html")[Rubrics]).

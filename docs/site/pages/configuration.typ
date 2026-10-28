#import "../template.typ": *

Global #api("config") options can be set either directly on an exam, using `#show: exam.with(..)` or
using elembic's `#show: e.set_(config, ..)` mechanism.
#example(
  ```typ
  // Instead of using exam.with(..), you could uncomment the following lines
  //
  // #show: e.set_(config,
  //   numbering: ("Problem 1.", "(a)"),
  //   points-position: "end",
  //   points-format: p => [[#p pts]],
  //   solution-color: maroon,
  // )

  #show: exam.with(
    numbering: ("Problem 1.", "(a)"),
    points-position: "end",
    points-format: p => [[#p pts]],
    solution-color: maroon,
  )

  #question(points: 3)[
    Find the derivative of $x^3$.
    #answer-box(width: 100%)[#solution[$3x^2$]]
  ]
  #question[
    #part(points: 1)[Is $91$ prime? #solution[No.]]
    #part(points: 2)[Factor $91$. #solution[$7 dot 13$]]
  ]
  ```,
  inset: 4.5em,
)

Inside of an exam, values can be set with elembic's `#show: e.set_(..)` mechanism. Such values will
affect the exam from that point onwards. However, some values _cannot_ be set in an exam. For
example, `numbering-full` cannot be set inside an exam (it would lead to ambiguous references).

#warning[
  _Warning._ A few options cannot be changed in the middle of an exam: `numbering-full`,
  `strings`, and `show-rubrics`. Set these with `#show: exam.with(..)`.
]

#example(
  ```typ
  #show: exam.with(
    solution-color: maroon,
  )

  #question(points: 3)[
    Find the derivative of $x^3$.
    #answer-box(width: 100%)[#solution[$3x^2$]]
  ]
  // Solution color will change from now onward
  #show: e.set_(config, solution-color: orange.darken(20%))
  #question[
    #part(points: 1)[Is $91$ prime? #solution[No.]]
    #part(points: 2)[Factor $91$. #solution[$7 dot 13$]]
  ]
  ```,
  inset: 4.5em,
)

== Reading config values

The global config can be read with elembic's `e.get(get => ..)` mechanism. The following example
shows how you might create a fully custom cover page with the exam's name and term.

#example(
  ```typ
  #show: exam.with(
    exam-name: [MAT 101 Quiz 3],
    term: [Fall 2026],
  )

  #e.get(get => [
    *#text(fill: blue)[#get(config).exam-name]*, #get(config).term
  ])
  ```,
)

#note[
  _Note._ To check whether solutions are shown, use #api("show-solutions", arg: "(get)") instead of
  reading the value directly from #api("config") (see #page-link("solutions.html")[Solutions]). This
  ensures that settings passed through the commandline via #typst-link(
    "reference/foundations/sys/",
  )[```sh --input show-solutions=..```] are taken into account.
]


// Every option, by topic, each table generated from `config`'s declaration.
// An option in none of them fails the build (see the check at the end).

== All `config` options

// The topics below are unnumbered, as each is named by the page it links to.
#set heading(numbering: none)

=== #page-link("solutions.html")[Solutions]

#config-options(
  "show-solutions",
  "solution-color",
  "solution-background-color",
)

=== #page-link("cover-pages.html")[Cover pages]

#config-options("institution", "exam-name", "term", "duration")

=== #page-link("questions.html")[Numbering and indentation]

#config-options("numbering", "numbering-full", "indent")

=== #page-link("points.html")[Points]

#config-options(
  "points-format",
  "bonus-points-format",
  "strings",
  "points-position",
  "points-show-totals",
  "points-table-direction",
  "points-table-granularity",
  "points-table-score",
  "points-table-bonus",
  "points-table-max-columns",
)

=== #page-link("answer-boxes.html")[Answer boxes]

#config-options(
  "answer-box-height",
  "answer-box-width",
  "answer-box-stroke",
  "answer-box-fill",
  "answer-box-default-height",
  "answer-box-default-width",
)

=== #page-link("choices.html")[Multiple choice]

#config-options(
  "bubble-size",
  "bubble-stroke",
  "bubble-outset",
  "bubble-label-font",
  "choices-enumerate",
  "choices-inline",
  "choices-columns",
  "choices-gap",
)

=== #page-link("rubrics.html")[Rubrics]

#config-options("show-rubrics", "rubric-position", "rubric-trace", "rubric-width")

#config-options-check()

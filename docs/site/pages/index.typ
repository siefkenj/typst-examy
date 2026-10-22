#import "../template.typ": *

A #link("https://typst.app")[Typst] package for writing exams, quizzes, and homework with
automatically numbered questions, answer boxes, points accounting, smart cross-references, and
solutions that can be toggled on and off. This package follows the spirit of the #link(
  "https://ctan.org/pkg/exam?lang=en",
)[exam class for LaTeX].

#screenshots(
  screenshot("quiz.png", "A quiz with empty answer boxes and multiple-choice bubbles", caption: [A
    quiz…]),
  screenshot("quiz-solutions.png", "The same quiz compiled with solutions shown", caption: […and
    solutions from the same source.]),
)

== Installation

To use examy, import it and start the exam with a show rule:

#raw(IMPORT + "\n\n#show: exam", lang: "typ", block: true)

A quick-start template is available by choosing examy under _Start from template_ in the Typst web
app or in the command line by running

```bash
typst init @preview/examy
```

== A first exam

A basic document is built out of an #api("exam", body: raw("#exam[...]")) (alternatively
`#show: exam`). Inside are questions, created with the command
#api("question", body: raw("#question[...]")) (see
#page-link("questions.html")[Questions and numbering]); boxes for students to write in, created with
#api("answer-box", body: raw("#answer-box[...]")) (see #page-link("answer-boxes.html")[Answer
boxes]); and solutions, created with #api("solution", body: raw("#solution[...]")) (see
#page-link("solutions.html")[Solutions]). A #api("name-block", body: raw("#name-block()")) gives
students a place to write their name (see #page-link("cover-pages.html")[Cover pages and name
blocks]).

Solutions are only shown when the `show-solutions` #page-link("configuration.html")[config option]
is `true`. It can be given to the exam directly, as in `#show: exam.with(show-solutions: false)`.

#example(
  ```typ
  #import "@preview/examy:1.0.0": *

  #show: exam.with(show-solutions: false)

  // A fill-in block (Name / Student ID) at the top of the page
  #{
    set text(font: "DejaVu Sans Mono")
    name-block()
  }

  #question(points: 2)[
    State the definition of a _continuous function_.
    #answer-box(height: 1fr)[
      #solution[A function $f$ is continuous at $a$ if
        $lim_(x -> a) f(x) = f(a)$.]
    ]
  ]
  #question(points: 3)[
    Give an example of a continuous function that is not
    differentiable.
    #answer-box(height: 2fr)[
      #solution[$f(x) = |x|$, at $x = 0$.]
    ]
  ]
  ```,
  height: 12cm,
)

#note[
  _Note._ `#show: exam` makes everything after it part of the exam, including a cover page before
  the first question. It also sets up the #link(
    "https://typst.app/universe/package/elembic",
  )[elembic] environment that cross-references need (`#show: e.prepare()`). If you use
  `#exam[...]` around just the questions instead, and refer to them from outside it, add
  `#show: e.prepare()` at the top of the document yourself.
]

== Basic Features

#features(
  (
    "questions.html",
    [Questions and numbering],
    [Questions, parts, and subparts, and their respective numbering.],
  ),
  (
    "points.html",
    [Points],
    [Points associated with each question/part/subpart, as well as points tables.],
  ),
  (
    "cross-references.html",
    [Cross-references],
    [Use `@name` syntax reference to a question/part/subpart.],
  ),
  (
    "answer-boxes.html",
    [Answer boxes],
    [Providing a student with space to write. These can have a fixed size or can use available space
      via fractional units (e.g. `height: 1fr`).],
  ),
  (
    "choices.html",
    [Multiple choice],
    [Add bubbles for students to answer multiple-choice questions.],
  ),
  (
    "solutions.html",
    [Solutions],
    [Add solutions to questions/parts/subparts that only show up on an answer-key version of the
      exam.],
  ),
  (
    "rubrics.html",
    [Rubrics],
    [Annotate questions and solutions with grading rubrics (positive or negative points), exportable
      as JSON.],
  ),
  ("cover-pages.html", [Cover pages], [Basic commands for creating name/exam info areas.]),
  (
    "configuration.html",
    [Global Config],
    [Configuration options that affect the look and feel of your test.],
  ),
  ("reference.html", [API Reference], [Complete documentation for functions provided by examy.]),
)

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

To use examy, import it and run the mandatory show rule:

#raw(IMPORT + "\n\n#show: e.prepare()", lang: "typ", block: true)

A quick-start template is available by choosing examy under _Start from template_ in the Typst web
app or in the command line by running

```bash
typst init @preview/examy
```

== A first exam

A basic document document starts with an `#exam()` and contains `#question[...]`s and
`#solution[...]`s. Content of each `#solution[...]` is shown based on the 
`show-solutions: true/false` #page-link("configuration.html")[config option].

#example(
  ```typ
  #import "@preview/examy:1.0.0": *

  #show: e.prepare()
  #show: e.set_(config, show-solutions: false)

  // A fill-in block (Name / Student ID) at the top of the page
  #name-block()

  #exam(
    questions: [
      #question(points: 2)[
        State the definition of a _continuous function_.
        #answer-box(width: 100%, height: 1fr)[
          #solution[A function $f$ is continuous at $a$ if
            $lim_(x -> a) f(x) = f(a)$.]
        ]
      ]
      #question(points: 3)[
        Give an example of a continuous function that is not
        differentiable.
        #answer-box(width: 100%, height: 2fr)[
          #solution[$f(x) = |x|$, at $x = 0$.]
        ]
      ]
    ],
  )
  ```,
  height: 12cm,
)

#note[
  _Note._ The `#show: e.prepare()` is required to set up the #link(
    "https://typst.app/universe/package/elembic",
  )[elembic] environment for enabling cross-references. Forgetting it can cause confusing errors.
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

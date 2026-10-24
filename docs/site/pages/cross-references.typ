#import "../template.typ": *

To reference a question/part/subpart, add a `label: <name>` attribute and use Typst's `@name` syntax
to refer to it. By default, a reference is rendered as the shortest unambiguous string. 

#example(
  ```typ
  #question[
    Let $f(x) = x^2$.
    #part(points: 2, label: <continuity>)[
      Show that $f$ is continuous at $0$.
    ]
    #part[
      Using your proof in @continuity, show that $f$ is
      continuous at every point.
    ]
  ]
  #question[
    Redo @continuity for $g(x) = x^3$.
  ]
  ```,
)

Notice how in 1 (b), the reference `@continuity` is rendered as "(a)" while in question 2 the same reference is rendered as "1 (a)".

To ensure all labels are globally unique, you can use the `numbering-full: true` option.

#example(
  ```typ
  #show: exam.with(numbering-full: true)
  
  #question[
    Let $f(x) = x^2$.
    #part(points: 2, label: <continuity>)[
      Show that $f$ is continuous at $0$.
    ]
    #part[
      Using your proof in @continuity, show that $f$ is
      continuous at every point.
    ]
  ]
  #question[
    Redo @continuity for $g(x) = x^3$.
  ]
  ```,
)

Questions can be labelled too, as in `#question(label: <q-limits>)[..]`, and a reference to one
shows its number. References follow the numbering style set with `numbering` (see #page-link(
  "questions.html",
)[Questions and numbering]).

#note[
  _Note._ Labels are given as an argument, `label: <name>`, rather than written after the question
  as `#question[..] <name>`, because examy takes questions apart to lay them out (see #page-link(
    "technical-details.html",
  )[Technical details]).
]

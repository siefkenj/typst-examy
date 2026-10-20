#import "../template.typ": *

Label a question, part, or subpart with `label: <name>` and refer to it with `@name`. A reference
shows the shortest number that uniquely identifies the question/part/subpart: question 1's part (a)
reads "1 (a)" from question 2, but just "(a)" from elsewhere in question 1.

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

Questions can be labelled too, as in `#question(label: <q-limits>)[..]`, and a reference to one
shows its number. References follow the numbering style set with `division-numbering` (see
#page-link("questions.html")[Questions and numbering]).

#note[
  _Note._ Labels are given as an argument, `label: <name>`, rather than written after the question
  as `#question[..] <name>`, because examy takes questions apart to lay them out (see
  #page-link("technical-details.html")[Technical details]).
]

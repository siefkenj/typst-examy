#import "../template.typ": *

Label a question, part, or subpart with `label: <name>` and refer to it with
`@name`. What the reference shows depends on where it is: question 1's part
(a) reads "1 (a)" from question 2, but just "(a)" from elsewhere in question 1.

#example(
  ```typ
  #question[
    Let $f(x) = x^2$.
    #part(points: 2, label: <continuity>)[Show that $f$ is continuous at $0$.]
    #part[From a sibling part, @continuity shows as its short name.]
  ]
  #question[From another question, @continuity shows with its question number.]
  ```,
)

A label can be attached to a question as well, `#question(label: <q-limits>)[..]`,
and a reference to it reads as its number: "Question 2". References follow the
numbering style set with `division-numbering` (see
#page-link("questions.html")[Questions and numbering]).

#note[
  Labels are given as an argument, `label: <name>`, rather than written after
  the division as `#question[..] <name>`, since examy takes divisions apart to
  lay them out (see #page-link("index.html")[How examy works]).
]

#import "../template.typ": *

A document is built out of an #api("exam"), whose `questions` hold the
questions. Inside them, #api("question"), #api("part"), and #api("subpart")
make a hierarchy, each numbered for you: questions `1.`, `2.`, …, parts
`(a)`, `(b)`, …, and subparts `i.`, `ii.`, …. Any of them can be given points,
a solution, and a label to refer to it by.

#example(
  ```typ
  #question[
    Let $f(x) = x^2 sin(1/x)$ for $x != 0$ and let $f(0) = 0$.
    #part(points: 2)[
      Show that $f$ is continuous at $x = 0$.
      #answer-box(width: 100%, height: 1fr)[]
    ]
    #part(points: 3)[
      Is $f$ differentiable at $x = 0$? Justify your answer.
      #subpart[Compute the difference quotient.]
      #subpart[Take its limit.]
      #answer-box(width: 100%, height: 1fr)[]
    ]
  ]
  ```,
  height: 9cm,
)

What a part is numbered depends on how deeply it is nested, not on which of
the three functions made it: they take identical arguments.

== Numbering a division

A division's `number` overrides its automatic number: `auto` (the default)
numbers it in turn, an integer sets the number (later divisions continue from
it), any other content is shown as it is, and `none` leaves it unnumbered.

#example(
  ```typ
  #question[An automatically numbered question.]
  #question[Another one.]
  #question(number: 10)[An integer sets the number.]
  #question[…and numbering continues from it.]
  #question(number: "★")[Content is shown verbatim.]
  #question(number: none)[An unnumbered question.]
  #question[The automatic counter ignores the previous two.]
  ```,
)

== Numbering styles

The numbering style of each level is set for the whole document with
#api("config")'s `division-numbering`: one pattern (or function) per level,
as Typst's `numbering` takes. References follow it, dropping a pattern's
trailing `.` (a function's result is used as it is).

#example(
  ```typ
  #show: e.set_(config, division-numbering: ("Problem 1.", "(A)", "i."))

  #question[
    The first problem.
    #part[A part.]
    #part[From another problem, @later reads in full.]
  ]
  #question[
    #part(label: <later>)[A part with a label.]
    #part[From a sibling, @later reads as the part alone.]
  ]
  ```,
  inset: 5em,
)

A label wider than the gutter runs out into the margin to its left rather than
wrapping; widen the gutter with a division's `indent` if needed.

== The words examy prints

The words examy prints itself — in the points table, the score box, and the
references — are set with `strings`, for another language or another wording.
Only the keys given are replaced; they are `question`, `page`, `points`,
`bonus`, `score`, and `total`.

```typ
#show: e.set_(config, strings: (question: [Aufgabe], points: [Punkte], total: [Summe]))
```

The words in a points badge, "(2 points)", are drawn by `points-format`
instead (see #page-link("points.html")[Points]).

== Page breaks inside questions

`#pagebreak()` works inside questions, parts, and subparts: the division
continues on the next page at the same indentation, without repeating its
number. `fr` answer boxes on each page share what is left of that page.

#import "../template.typ": *

A document is built out of an #api("exam", body: raw("#exam(..., questions: [...])")).
Inside of `questions`, the commands #api("question", body: raw("#question[...]")),
#api("part", body: raw("#part[...]")), and #api("subpart", body: raw("#subpart[...]"))
can be used to create a question hierarchy. Questions/parts/subparts can be
assigned points, heights, etc.

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
  #show: e.set_(
    config,
    division-numbering: ("Problem 1.", "(A)", "i."),
  )

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
#show: e.set_(config, strings: (
  question: [Aufgabe],
  points: [Punkte],
  total: [Summe],
))
```

The words in a points badge, "(2 points)", are drawn by `points-format`
instead (see #page-link("points.html")[Points]).

== A question of a set height

A question, part, or subpart given a `height` is laid out as one block of
that height, its parts included: a length such as `4.5cm`, or a fraction such
as `1fr`, a share of what is left of the page (as an answer box's is). `fr`
answer boxes inside it share what its own text leaves of it.

#example(
  ```typ
  #question(height: 4.5cm, points: 4)[
    Sketch the graph of $f(x) = x^3 - x$.
    #part[
      Mark its zeros.
      #answer-box(width: 100%, height: 1fr)[]
    ]
    #part[
      Mark its turning points.
      #answer-box(width: 100%, height: 1fr)[]
    ]
  ]
  #question[The next question starts below the first one's 4.5cm.]
  ```,
)

Being one block, it cannot break across pages: a `#pagebreak()` inside a
division with a `height` is an error. What it holds is not shrunk to fit:
content taller than the `height` runs out of the block, over what comes after
it.

#note[
  The preferred way to give a question room to write in is an answer box:
  #api("answer-box", body: raw("#answer-box(width: 100%, height: 3cm)[]")).
  If you do not want a border, give it `stroke: none`, and it is blank space
  of that size, which on the answer key holds the solution.
]

#example(
  ```typ
  #question(points: 2)[
    Explain why every differentiable function is continuous.
    #answer-box(width: 100%, height: 2.5cm, stroke: none)[
      #solution[If $f'(a)$ exists,
        $f(a + h) - f(a) = h dot (f(a + h) - f(a)) / h
          -> 0 dot f'(a) = 0$.]
    ]
  ]
  #question[The next question.]
  ```,
)

== Page breaks inside questions

`#pagebreak()` works inside questions, parts, and subparts: the division
continues on the next page at the same indentation, without repeating its
number. `fr` answer boxes on each page share what is left of that page. The
exception is a division given a `height`, which is one block (see above): a
`#pagebreak()` inside it is an error.

#import "../template.typ": *

A document is built out of an #api("exam", body: raw("#exam[...]")) (alternatively `#show: exam`).
Inside are questions created with the commands #api("question", body: raw("#question[...]")), #api(
  "part",
  body: raw("#part[...]"),
), and #api("subpart", body: raw("#subpart[...]")), used to create a question hierarchy.
Questions/parts/subparts can be assigned points, heights, etc.

#example(
  ```typ
  #show: exam

  #question[
    Let $f(x) = x^2 sin(1/x)$ for $x != 0$ and let $f(0) = 0$.
    #part(points: 2)[
      Show that $f$ is continuous at $x = 0$.
      #answer-box(height: 1fr)[]
    ]
    #part(points: 3)[
      Is $f$ differentiable at $x = 0$? Justify your answer.
      #subpart[Compute the difference quotient.]
      #subpart[Take its limit.]
      #answer-box(height: 1fr)[]
    ]
  ]
  ```,
  height: 9cm,
)

A part's numbering is determined _only_ by how deeply it is nested, so `#question[#question[...]]`
and `#question[#part[...]]` are numbered the same. The aliases `question`/`part`/`subpart` are
provided for convenience.

== Numbering a question

By default, questions automatically increment their number. Providing a `number: ...` argument to a
`question`/`part`/`subpart` overrides this behaviour. A numerical value will cause numbering to skip
to that value; a non-numerical value or general content will pause the counter and show that
content. To omit a number completely, you can set `number: none`.

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

The numbering style of each level is set for the document via the global #api("config")'s
`numbering` option. It takes what `enum`'s `numbering` takes: a pattern such as `"1.a.i."`, whose
counting symbols number the levels in turn, a function of the number, or an array with one of
those per level.

#example(
  ```typ
  #show: exam.with(
    numbering: ("Problem 1.", "(A)", "i."),
  )

  #question[
    The first problem.
    #part[A part.]
    #part[Translate the question statement of @later to German.]
  ]
  #question[
    #part(label: <later>)[Where is the nearest grocery store?]
    #part[Relative to your answer in part @later, where is the nearest train station?]
  ]
  ```,
  inset: 5em,
)

With `numbering-full: true`, as with `enum`'s `full`, a part or subpart is numbered with the
numbers of the divisions it is in: `"1.a.i."` numbers part (b) of question 2 "2.b.", and a
function is given every level's number. References then read as the full number too, and a
question whose body starts with a part shows only the part's number on their shared line, as it
holds the question's.

#example(
  ```typ
  #show: exam.with(numbering: "1.a.i.", numbering-full: true)

  #question[
    #part[A part.]
    #part(label: <second>)[Another, with #subpart[a subpart.]]
  ]
  #question[See @second.]
  ```,
  inset: 3em,
)

== A question of a set height

Giving a question/part/subpart a `height` reserves exactly that much space for it, parts included.
The height can be a length like `4.5cm`, or a fraction like `1fr`, which takes a share of the space
left on the page, just as an answer box does. Any `fr` answer boxes inside share the space that the
text leaves over.

#example(
  ```typ
  #question(height: 4.5cm, points: 4)[
    Sketch the graph of $f(x) = x^3 - x$.
    #part[
      Mark its zeros.
      #answer-box(height: 1fr)[]
    ]
    #part[
      Mark its turning points.
      #answer-box(height: 1fr)[]
    ]
  ]
  #question[The next question starts below the first one's 4.5cm.]
  ```,
)

A question/part/subpart with a `height` is laid out as a single block, so it cannot break across
pages, and a `#pagebreak()` inside it is an error. Its content is not shrunk to fit either: content
taller than the `height` overflows onto whatever comes next.

#note[
  _Note._ The preferred way to give a question room to write in is an answer box, #api(
    "answer-box",
    body: raw("#answer-box(width: 100%, height: 3cm)[]"),
  ). If you don't want a border, set `stroke: none` to get blank space of that size. On the answer
  key, that space holds the solution.
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

`#pagebreak()` works inside questions, parts, and subparts. The question/part/subpart continues on
the next page at the same indentation, without repeating its number, and the `fr` answer boxes on
each page share the space left on that page. The only exception is a question/part/subpart with a
`height` (see above), where a `#pagebreak()` is an error.

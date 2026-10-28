#import "../template.typ": *

An #api("answer-box", arg: "[..]") provides an area for students to write in. It can have a set
height in #typst-link("reference/layout/length/")[fixed units] (`2cm`, `1in`, …) or
#typst-link("reference/layout/fraction/")[_fractional_ units] (`1fr`, `2fr`, …). When the height is
set as a fractional unit, an #api("answer-box", arg: "[..]") will negotiate with all other items on
the page and adjust its height based on the available room.

#example(
  ```typ
  #question[
    State the Mean Value Theorem.
    #answer-box(width: 100%, height: 1cm)[]
  ]
  #question[
    Let $f(x) = x^3 - 3x$.
    #part[
      Find $f'(x)$.
      #answer-box(height: 1fr)[]
    ]
    #part[
      Find and classify the critical points of $f$.
      #answer-box(height: 2fr)[
        Critical points: #answer-box(height: 1cm, width: 1fr)[]

        Classification(s):
      ]
    ]
  ]
  ```,
  height: 9cm,
)

Answer boxes can also be used mid-sentence.

#example(
  ```typ
  #question[
    The derivative of $x^3$ at $x = 2$
    is #answer-box(height: 1.4em)[#solution[12]].
  ]
  ```,
)

== Height and width

Without a height set, an answer box will size to its content (excluding any
#api("solution", arg: "[..]")s), with an empty answer box taking up a
#api("answer-box", field: "default-height") (normally set to `2cm`).

#example(
  ```typ
  #question[
    What is $6 times 7$?
    #answer-box(width: 100%)[#solution[42]]
  ]
  #question[
    Is $sqrt(2)$ rational?
    #answer-box(width: 100%)[Explain your reasoning:]
  ]
  ```,
)

Setting #api("answer-box", field: "width", value: "100%") or
#api("answer-box", field: "height", value: "1fr") (or another fractional unit) makes an answer box
act like a #typst-link("reference/layout/block/")[block]. Otherwise, it is placed as
#typst-link("reference/layout/box/")[inline content], centered on the current sentence's baseline.

A fractional width, such as `width: 1fr`, fills the rest of the line, so a box can run from a prompt
to the end of its line, as in ```typ Critical points: #answer-box(width: 1fr)[]``` above. Two boxes
in one line share it in proportion to their fractions.

#note[
  _Note._ It is good practice to explicitly set a `height: ..` on an answer box.
]

== Borders

An answer box's border is set with #api("answer-box", field: "stroke"), which accepts anything
#typst-link("reference/layout/box/#parameters-stroke")[`box`'s `stroke`] does.

#example(
  ```typ
  #question[
    Sketch the graph of $y = sin x$.
    #answer-box(width: 100%, height: 1.5cm, stroke: none)[]
  ]
  #question[
    The capital of France is #answer-box(
      width: 4cm,
      height: 1em,
      stroke: (bottom: .5pt),
    )[]
  ]
  ```,
)

== Global settings for answer boxes

Exam-wide defaults can be set for answer boxes via the `answer-box-*` options of the global
#api("config").

#example(
  ```typ
  #show: exam.with(
    answer-box-height: 1fr,
    answer-box-width: 100%,
    answer-box-stroke: (paint: blue, dash: "dashed"),
  )

  #question[
    Find the derivative of $x^3 + 2x$.
    #answer-box[]
  ]
  #question[
    Is $x^3 + 2x$ increasing? Explain.
    #answer-box(height: 1.5cm)[_Only 1.5cm available for your answer. Be concise!_]
  ]
  #question[
    Find the critical points of $x^3 - 3x$.
    #answer-box[]
  ]
  ```,
  height: 11cm,
)

Global settings can be overridden on a case-by-case basis.

#example(
  ```typ
  #show: exam.with(answer-box-stroke: (bottom: .5pt))

  #question[
    $2 + 2 =$ #answer-box(height: 1em)[] and
    $3 + 3 =$ #answer-box(height: 1em, stroke: .5pt)[]
  ]
  ```,
)

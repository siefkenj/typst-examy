#import "../template.typ": *

#api("answer-box") draws a box for students to write in. A fixed height (`2cm`, `1in`, …) gives a
box of that size. A _fractional_ height (`1fr`, `2fr`, …) makes the box grow to fill the space left
on the page, and several `fr` boxes on one page share that space in proportion.

#example(
  ```typ
  #question[
    State the Mean Value Theorem.
    #answer-box(width: 100%, height: 1.5cm)[]
  ]
  #question[
    Let $f(x) = x^3 - 3x$.
    #part[
      Find $f'(x)$.
      #answer-box(width: 100%, height: 1fr)[]
    ]
    #part[
      Find and classify the critical points of $f$.
      #answer-box(width: 100%, height: 2fr)[]
    ]
  ]
  ```,
  height: 11cm,
)

Without a `width`, a box is `default_width` (`2cm`) wide and sits in the line like a word. This
suits a short answer in a sentence:

#example(
  ```typ
  #question[
    The derivative of $x^3$ at $x = 2$ is
    #answer-box[#solution[12]].
  ]
  ```,
)

== Boxes without a height

Without a `height`, a box sizes itself to its content. A blank box (empty, or holding only a
#api("solution")) is `default_height` (`2cm`) tall, leaving room to write. A box with content, such
as a prompt or a list of #api("choices"), grows to fit it.

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

In a box without a `height`, solutions take up no space, so the answer key is laid out exactly like
the exam. Every box is the same size on both, and nothing after a box moves. A solution is drawn
where it would be, on top of whatever follows it, even past the bottom of the box. To make a box
grow to hold its solutions, give it a height, which can be `auto`:

#example(
  ```typ
  #question[
    Solve $2x = 8$. The box is the same size on the key:
    #answer-box(width: 100%)[
      #solution[Dividing both sides by 2, $x = 4$.]
    ]
  ]
  #question[
    #answer-box(width: 100%, height: auto)[
      Solve $3x = 9$. This box grows on the key:

      #solution[Dividing both sides by 3, $x = 3$.]
    ]
  ]
  ```,
)

A solution only counts as blank when it is written directly in the box. Wrapped in another element,
as in `#align(center)[#solution[...]]`, it counts as content, and the box grows to fit it.

#note(kind: "warning")[
  *Changed in 1.0.0.* In examy 0.4.0 and earlier, a box with no height (or with `height: auto`) was
  always `default_height` tall, whatever it held. Now a box holding a prompt, such as
  `#answer-box(width: 100%)[Explain your reasoning:]`, shrinks to fit the prompt and leaves no room
  to write. To keep the old size, set the height explicitly, e.g. `height: 2cm`.
]

A fractional height only gets the space left over once everything else on the page is placed, which
may be less than the box's content needs. If the content must fit, leave the height out, or use a
fixed length.

== Outlines

A box's outline is set with `stroke`, which accepts anything `box`'s `stroke` does. A dictionary
outlines only the sides it names, and `none` removes the outline, leaving blank space:

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

To change the outline of every box in a document, redefine `answer-box` after the import.
Individual boxes can still set their own:

#example(
  ```typ
  #import "@preview/examy:1.0.0": *
  #let answer-box = answer-box.with(stroke: (bottom: .5pt))

  #question[
    $2 + 2 =$ #answer-box(height: 1em)[] and
    $3 + 3 =$ #answer-box(height: 1em, stroke: .5pt)[]
  ]
  ```,
)

The redefinition only applies where the new name is in scope, so repeat it in each file that imports
examy.

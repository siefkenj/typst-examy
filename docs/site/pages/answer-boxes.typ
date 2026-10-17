#import "../template.typ": *

#api("answer-box") draws a box for students to write in. A fixed height
(`2cm`, `1in`, …) gives a box of that size; a _fraction_ (`1fr`, `2fr`, …)
makes the box grow to fill the space left on the page, and several `fr`
boxes on one page share it in proportion.

#example(
  ```typ
  #question[
    A box of a set height.
    #answer-box(width: 100%, height: 1.5cm)[]
  ]
  #question[
    Two boxes sharing what is left of the page, one twice the other.
    #part[#answer-box(width: 100%, height: 1fr)[]]
    #part[#answer-box(width: 100%, height: 2fr)[]]
  ]
  ```,
  height: 11cm,
)

A box without a `width` is `default_width` (`2cm`) wide and sits in the line
like a word, which suits a short answer in a sentence:

#example(
  ```typ
  #question[The derivative of $x^3$ at $x = 2$ is #answer-box[#solution[12]].]
  ```,
)

== Boxes without a height

With no height, the box sizes itself by what it holds. A blank box — empty, or
holding only a #api("solution") — is `default_height` (`2cm`) tall, leaving
room to write. A box with content, such as a prompt or a list of
#api("choices"), grows to fit it.

#example(
  ```typ
  #question[
    A blank box is `default_height` tall.
    #answer-box(width: 100%)[#solution[42]]
  ]
  #question[
    A box with content fits it.
    #answer-box(width: 100%)[Explain your reasoning:]
  ]
  ```,
)

In a box with no height, solutions take no height either, so the answer key
lays out exactly like the exam: every box is the same size on both, and
nothing after a box moves. A solution is drawn where it would be: over what
follows it in the box, or, when it comes last, hanging out of the box over
whatever comes next. To have a box hold its solutions instead, give it a
height, which can be `auto`:

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

A solution counts as blank only when written directly in the box: wrapped in
another element, as in `#align(center)[#solution[...]]`, it is content, and
the box fits it.

#note(kind: "warning")[
  *Changed in 1.0.0:* in examy 0.4.0 and earlier, a box with no height (or
  with `height: auto`) was always `default_height` tall, whatever it held. Now
  a box holding a prompt, such as `#answer-box(width: 100%)[Explain your
  reasoning:]`, shrinks to the prompt and leaves no room to write. To keep the
  old size, give the height explicitly: `height: 2cm`.
]

A fraction height gets only the space left over once everything else on the
page is placed, which can be less than the box's content needs. For a box
whose content must fit, leave the height out, or give a length.

== Outlines

The box's outline is set with `stroke`, which takes anything `box`'s `stroke`
does. A dictionary outlines only the sides it names, and `none` leaves blank
space with no outline:

#example(
  ```typ
  #question[
    Blank space with no outline:
    #answer-box(width: 100%, height: 1.5cm, stroke: none)[]
  ]
  #question[
    A rule to write on: #answer-box(width: 4cm, height: 1em, stroke: (bottom: .5pt))[]
  ]
  ```,
)

To change the outline of every box in a document, redefine `answer-box` after
the import; a box can still set its own:

#example(
  ```typ
  #import "@preview/examy:1.0.0": *
  #let answer-box = answer-box.with(stroke: (bottom: .5pt))

  #question[
    Every box is a rule, #answer-box(height: 1em)[]
    unless it says otherwise: #answer-box(height: 1em, stroke: .5pt)[]
  ]
  ```,
)

The redefinition only affects code that uses the redefined name, so set it
again in each file that imports examy itself.

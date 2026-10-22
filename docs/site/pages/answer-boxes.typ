#import "../template.typ": *

#api("answer-box") draws a box for students to write in. A fixed height (`2cm`, `1in`, …) gives a
box of that size. A _fractional_ height (`1fr`, `2fr`, …) makes the box grow to fill the space left
on the page, and several `fr` boxes on one page share that space in proportion. A box with a
fractional height is as wide as the text unless it is given a `width`.

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
      #answer-box(height: 1fr)[]
    ]
    #part[
      Find and classify the critical points of $f$.
      #answer-box(height: 2fr)[]
    ]
  ]
  ```,
  height: 11cm,
)

Any other box without a `width` is `default-width` (`2cm`) wide and sits in the line like a word.
This suits a short answer in a sentence:

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
#api("solution")) is `default-height` (`2cm`) tall, leaving room to write. A box with content, such
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

== Settings for every box

The exam's options `answer-box-height` and `answer-box-width` give the size of every box that doesn't
give its own `height` or `width`. Like the exam's other options, they can be given to the exam, or
set with `#show: e.set_(config, ..)` for part of it. Here every box fills the space left on its page,
except one that gives its own height:

#example(
  ```typ
  #show: exam.with(answer-box-height: 1fr, answer-box-width: 100%)

  #question[
    Find the derivative of $x^3 + 2x$.
    #answer-box[]
  ]
  #question[
    Is $x^3 + 2x$ increasing? Explain.
    #answer-box(height: 1.5cm)[]
  ]
  #question[
    Find the critical points of $x^3 - 3x$.
    #answer-box[]
  ]
  ```,
  height: 11cm,
)

In the same way, `answer-box-default-height` is the height of a blank box with no `height` (`2cm`
unless it is set), and `answer-box-default-width` the width of a box in a line with no `width`.

Any of a box's fields, such as its `stroke`, can also be set with a set rule on `answer-box`. Like a
`set` rule, it applies from where it is made to the end of the document (or of the block it is in):

#example(
  ```typ
  #show: e.set_(answer-box, stroke: (bottom: .5pt))

  #question[
    $2 + 2 =$ #answer-box(height: 1em)[] and
    $3 + 3 =$ #answer-box(height: 1em, stroke: .5pt)[]
  ]
  ```,
)

A box's own arguments win over a set rule on `answer-box`, and a set rule wins over the exam's
options. A box given `height: none` keeps it, even when `answer-box-height` is set.

#note(kind: "warning")[
  _Warning._ Inside an exam, the exam draws its answer boxes itself. It applies only the `e.set_` and
  `e.apply` rules on answer boxes and on the `answer-box-` options. Elembic's other rules on them
  (`e.show_`, `e.cond-set`, `e.filtered`, `e.select`, `e.reset`, and an `e.revoke` of a rule that
  set them) are an error, whether they are written inside the exam or before it. Typst's own show
  rules on `e.selector(answer-box)`, such as `#show e.selector(answer-box): set text(blue)`, apply
  to the exam's boxes as to any other.
]

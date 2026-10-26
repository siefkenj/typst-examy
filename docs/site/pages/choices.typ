#import "../template.typ": *

Multiple choice questions can be written with #api("choices", arg: "[...]") for an automatically
formatted list, or with #api("choice", arg: "[...]") and #api("bubble", arg: "()") for finer-grained
control.

A #api("choices", arg: "[...]") accepts a mixed list with both
#typst-link("reference/model/list/")[```typ -```] and
#typst-link("reference/model/enum/")[```typ +```] starting a line or an
#typst-link("reference/foundations/array/")[array] of content. Lines starting with ```typ +``` are
recorded as correct choices. Alternatively, correct choices can be specified by supplying a
0-indexed array.

#example(
  ```typ
  #question(points: 1)[
    What is the capital of Canada? _Select one._
    #choices[
      - Toronto
      + Ottawa
      - Montreal
      - Vancouver
    ]
  ]
  #question(points: 1)[
    Which cities lie on the Canada's southern border? _Select all that apply._
    #choices(
      bubble: "square",
      correct: (0,2,3),
      ([Toronto], [Ottawa], [Montreal], [Vancouver])
    )
  ]
  ```,
  width: 9cm,
)

== Rows and columns

By default, choices are listed one per line, but they can also be laid out in a paragraph or in
columns.

/ `inline: true`: Run the choices side by side, wrapping like words. This suits short choices.
/ `columns: n`: Lay the choices out in `n` equal columns, filled row by row.
/ `gap`: The space between choices. Inline, `gap: 1fr` spreads the choices across the line.

#example(
  ```typ
  #question(points: 1)[
    Which of these numbers is prime?
    #choices(inline: true, correct: 1, (9, 11, 15, 21))
  ]
  #question(points: 2)[
    Which of these functions are continuous at $x = 0$?
    _Select all that apply._
    #choices(bubble: "square", columns: 2)[
      + $sin x$
      - $1/x$
      + $abs(x)$
      - $floor(x)$
    ]
  ]
  ```,
  width: 10cm,
)

== Round, square, and labelled bubbles

The shape of a choice's bubble can be set using `bubble: "circle"` (default) or `bubble: "square"` (often used for select-all-that-apply questions).

Setting `enumerate: true` will label each bubbles with the letters A, B, C, … in sequence. 
For custom lettering, you can supply a
#typst-link("reference/model/numbering/")[numbering string], an array, or a function that
determines the label.

#example(
  ```typ
  #question(points: 1)[
    Which planet is largest?
    #choices(enumerate: true)[
      - Mars
      + Jupiter
      - Venus
    ]
  ]
  #question(points: 1)[
    Which planet is your favorite?
    #choices(enumerate: "i", inline: true)[
      - Mars
      + Jupiter
      - Venus
    ]
  ]
  ```,
  width: 9cm,
)

If you would like to set exam-wite defaults for choices, use the global #api("config").
```typ
#show: exam.with(choices-enumerate: "a", bubble-stroke: .06em)
```
Relevant options are:

/ `choices-enumerate`: Letters in the bubbles of every #api("choices", arg: "[...]"), as `enumerate`
  gives them.
/ `choices-inline`, `choices-columns`, `choices-gap`: The layout of every `choices`, as `inline`,
  `columns`, and `gap` give it. A `choices` given `inline` or `columns` itself ignores both
  `choices-inline` and `choices-columns`.
/ `bubble-label-font`: The font of those letters (by default, the monospaced font bundled with
  Typst).
/ `bubble-size`: The size of every round bubble (by default, `1em`). Square bubbles are drawn a
  little smaller, in the same proportion as by default.
/ `bubble-stroke`: The outline thickness of every bubble (by default, `.1em`).
/ `bubble-outset`: The space around every bubble, as `outset` gives it.

A single `choice` takes `size`, `stroke`, and `outset` itself, and a single `choices` takes
`stroke` and `label-font`. Each wins over the global option. Both also take `color` and
`background-color`, which set the colors of a correct bubble on the answer key in place of
`solution-color` and `solution-background-color`.


== Custom layouts

To fully customize layouts, you can use the 
#api("choice", arg: "[...]") function directly to draw choices one at a time, or 
the #api("bubble", arg: "()") and #api("square-bubble", arg: "()") functions to draw bubbles without associated content.

#example(
  ```typ
  #question(points: 1)[
    Let $f(x) = 1/x$. Which statement is true?
    #table(
      columns: (auto, 1fr),
      align: (center + horizon, left),
      [#bubble()], [$f$ is increasing on $(0, 1)$.],
      [#bubble(correct: true)], [$f$ is decreasing on $(0, 1)$.],
    )
  ]
  #question[
    #choice[Agree] #h(1em)
    #choice(correct: true)[Disagree] #h(1em)
    #choice[Unsure]
  ]
  ```,
  width: 10cm,
)

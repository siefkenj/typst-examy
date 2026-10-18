#import "../template.typ": *

#api("choice", body: raw("#choice[]")) draws a bubble (circle or square) to the
left of text. #api("choices", body: raw("#choices[...]")) takes a list and
draws a bubble before each item for students to fill in. Write each choice on
its own line starting with `-`. Starting an item with `+` will mark it as a
correct choice (it will only render differently if solutions are shown).

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
  ```,
  width: 9cm,
)

== `#choices[...]` API


- `correct: int | array` — An alternative to using `+` to mark a correct
  choice. Setting `correct: 0` marks the first choice as correct,
  `correct: (0, 2)` marks the first and third.
- `bubble: "circle" | "square"` — Round bubbles (the default) for "select
  one", square ones for "select all that apply".
- `columns: int` — Lay the choices out in this many equal columns, filled
  row by row.
- `inline: bool` — Run the choices side by side in a paragraph, wrapping like
  words. Suits short choices. Cannot be combined with `columns`.
- `gap: length` — The space between choices. One per line, it is the space
  between rows (by default, the text's line spacing). Side by side, it is the
  space between them (by default `1.5em`); inline, `1fr` spreads the choices
  across the line.

The choices can also be given as an array:

#example(
  ```typ
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
  #question(points: 1)[
    Which of these numbers is prime?
    #choices(inline: true, correct: 1, (9, 11, 15, 21))
  ]
  ```,
  width: 10cm,
)

== Letters in the bubbles

`enumerate: bool | str | function` — Labels inside the bubbles: `true` for
A, B, C, …, or any numbering pattern or function `enum` takes (`"a"`, `"1"`,
`"(i)"`). Off by default; set it for the whole document with
`#show: e.set_(config, choices-enumerate: true)`. Labels are set in the
monospaced font bundled with Typst, changed with #api("config")'s
`bubble-label-font`; on the answer key, a correct one gets a thin ring
inside its outline.

#example(
  ```typ
  #question(points: 1)[
    Which planet is largest?
    #choices(enumerate: true, gap: .8em)[
      - Mars
      + Jupiter
      - Venus
    ]
  ]
  ```,
  width: 9cm,
)

== Single bubbles

For a layout of your own, #api("choice", body: raw("#choice[...]")) draws a
single bubble before its content; mark an answer with `correct: true`. It
takes `bubble: "circle" | "square"`. #api("bubble") and #api("square-bubble")
are the same with the shape fixed, and draw a bare bubble without content:

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

In every layout, a choice is kept whole. When its text wraps, the bubble stays
on the first line and the further lines hang under the text, not under the
bubble. The gap between a choice bubble and its content can be set with
`outset` (e.g. `outset: .6em`). The outline thickness of every bubble in the
document is set with `#show: e.set_(config, bubble-stroke: .06em)` (default
`.1em`). An outline thick enough to cover a filled-in bubble's check mark,
about a fifth of the bubble's size, is drawn at that limit instead.

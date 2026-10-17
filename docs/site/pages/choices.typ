#import "../template.typ": *

#api("choices") takes a list and draws a bubble before each item for students
to fill in. Write each choice on its own line starting with `-`; start the
correct ones with `+` instead. They look the same on the exam, and are filled
in and checked on the answer key.

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

== Layouts

One per line is the default. `columns: n` sets the choices in `n` equal
columns, filled row by row; `inline: true` runs them side by side in a
paragraph, wrapping like words, which suits short choices. Square bubbles
(`bubble: "square"`) are for "select all that apply". Choices can also be
given as an array, with the correct ones named by their index with `correct`:

#example(
  ```typ
  #question(points: 2)[
    Which of these functions are continuous at $x = 0$? _Select all that apply._
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

`gap` sets the space between choices: one per line, between rows (by default
the text's line spacing); side by side, between them (by default `1.5em`), and
there `1fr` spreads the choices across the line.

== Letters in the bubbles

`enumerate: true` letters the bubbles A, B, C, …; it also takes any numbering
pattern or function `enum` does (`"a"`, `"1"`, `"(i)"`). Set it for the whole
document with #api("config")'s `choices-enumerate`. On the answer key, a
correct lettered bubble is filled in with its letter, and a thin ring inside
its outline.

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

The letters are set in the monospaced font bundled with Typst, changed with
#api("config")'s `bubble-label-font`.

== Single bubbles

For a layout of your own, #api("choice") draws a single bubble before its
content; mark an answer with `correct: true`. #api("bubble") and
#api("square-bubble") are the same with the shape fixed, and draw a bare
bubble without content:

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
    #choice[Agree] #h(1em) #choice(correct: true)[Disagree] #h(1em) #choice[Unsure]
  ]
  ```,
  width: 10cm,
)

In every layout, a choice is kept whole. When its text wraps, the bubble stays
on the first line and the further lines hang under the text, not under the
bubble. The gap between a bubble and its content is set with `outset` (e.g.
`outset: .6em`). The outline of every bubble in the document is set with
`#show: e.set_(config, bubble-stroke: .06em)` (default `.1em`); one thick
enough to cover a filled-in bubble's check mark is drawn at that limit instead.

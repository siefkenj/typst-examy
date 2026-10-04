// Demonstrates multiple-choice questions: each option of `#choices[...]`,
// and a bare `#bubble()` in a table. The README shows this file verbatim,
// below everything up to and including the import line (with the import
// pointed at @preview/examy), above its two renders — keep them in step.
//
// Student version:  typst compile --root .. --input show-solutions=false multiple-choice.typ
// Answer key:       typst compile --root .. --input show-solutions=true multiple-choice.typ
#import "../src/lib.typ": *

// A small page, so the screenshot stays readable; drop it for a full page.
#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()
// `true` prints the answer key, with the correct bubbles filled in.
#show: e.set_(config, show-solutions: true)

#exam(questions: [
  #question(points: 1)[
    What is the capital of Canada? _Select one._
    // One per line (the default), spread out with `gap`.
    #choices(gap: 0.8em)[
      - Toronto
      + Ottawa
      - Montreal
      - Vancouver
    ]
  ]
  #question(points: 2)[
    Which of these functions are continuous at $x = 0$? _Select all that apply._
    // Square bubbles, in two columns.
    #choices(bubble: "square", columns: 2)[
      + $sin x$
      - $1/x$
      + $abs(x)$
      - $floor(x)$
    ]
  ]
  #question(points: 1)[
    Which of these numbers is prime?
    // Side by side, with the choices as an array and the answer by index.
    #choices(inline: true, correct: 1, (9, 11, 15, 21))
  ]
  #question(points: 1)[
    Let $f(x) = 1/x$. Which statement is true?
    // A bare `#bubble()` in each row of a table, for a layout of your own.
    #table(
      columns: (auto, 1fr),
      align: (center + horizon, left),
      [#bubble()], [$f$ is increasing on $(0, 1)$.],
      [#bubble(correct: true)], [$f$ is decreasing on $(0, 1)$.],
    )
  ]
])

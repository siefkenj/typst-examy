// End-to-end smoke test: exercises the full pipeline (exam → tokenize →
// parse → plan → render), references, points table, solutions, answer
// boxes, and both ISSUES regressions. Passes if it compiles.
#import "/src/lib.typ": *

#show: e.prepare()
#show: e.set_(config, show-solutions: true)
#show: e.set_(
  config,
  institution: "Test University",
  exam-name: [Integration Test],
  term: "Fall 2026",
  duration: duration(minutes: 60),
)

There are #num-questions questions worth #num-points points.

#points-table

#maketitle()
#name-block()
Answer everything.
#pagebreak()

#exam(
  questions: [
    Some prose before the questions.

    #question(points: 1, label: <q1>)[
      A question with parts.
      #part(points: 2, label: <q1p1>)[First part.]
      #part(points: 4, label: <q1p2>)[
        Second part; refers to @q1p1 (should show "(a)").
        #subpart(label: <q1p2s1>)[A subpart referring to @q1p1 (shows "(a)").]
      ]
    ]

    #question(points: 3)[
      Refers to @q1p1 (should show "1 (a)"), to @q1 (should show "1"),
      and to @q1p2s1 (should show "1 (b) i").

      // ISSUES regression #2: a part after a markup enum
      + first item
      + second item

      #part[This part must be visible.]
      // ISSUES regression #1: an empty part still shows its label
      #part[]
    ]

    #pagebreak()

    #question(points: 2, solution: [A solution.])[
      A question split by an explicit pagebreak.
      #part[
        Before the break.
        #pagebreak()
        After the break; refers to @q1p1 (should show "1 (a)").
      ]
    ]

    #question[
      A question with a fill-the-page answer box.
      #answer-box(width: 100%, height: 1fr)[
        #solution[The answer.]
      ]
    ]

    #question(number: "XX")[
      Custom-numbered question.
      #part(points: 1, intent: "bonus")[With a bonus part.]
    ]

    // Gutter-label alignment: the boxed solution makes the first line taller
    // than the line height; the "6." must sit on the text baseline.
    #question(points: 2, solution: [An inline boxed solution.])[
      A one-line question with a tall first line.
    ]
    // ...and a body starting with a block element keeps the placed label.
    #question[
      #answer-box(width: 100%, height: 2cm)[]
    ]
  ],
)

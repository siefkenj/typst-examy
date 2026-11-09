// Every field the exported data (`<examy-rubric>`, `<examy-regions>`) can
// have, and each value it can take: `null` and not. Not a unit test: the
// data is checked against the types the manual gives for it
// (docs/site/examy-*.ts) by docs/site/check-metadata-schema.mjs.
#import "/src/lib.typ": *

#set page(width: 6in, height: 5in, margin: .5in)

#name-block()
#exam(embed-metadata: true, exam-name: [MAT 101 *Final*])[
  #question(points: 2, rubric: [
    Check the units.
    #rubric(points: 1)[Sets up the equation]
    #rubric(annotation: [pick one])[Solving

      Only the best attempt counts.
      #rubric(points: 1)[Solves it]
      #rubric(points: .5)[Solves it, with one slip]
      Partial credit is at your discretion.
    ]
    #rubric[Writes neatly]
  ])[
    Solve $2x + 1 = 5$. #answer-box(width: 100%, height: 1cm)[]
  ]
  #question[
    #part(points: 2, rubric: rubric(points: 2)[Right])[
      Factor $x^2 - 1$.
      #subpart(points: 0)[Check it. #answer-box(width: 3cm, height: 1cm)[]]
    ]
    #part(points: 1, intent: "bonus", rubric: rubric(points: 1)[Right])[A bonus.]
    #part(points: 1, intent: "practice")[For practice.]
  ]
  #question(number: none, points: 1)[Unnumbered.]
  #columns(2)[
    #question(points: 1, height: 2cm)[Left.]
    #colbreak()
    #question(points: 1)[Right.]
  ]
]

#exam(embed-metadata: true)[
  #question(points: 1, rubric: rubric(points: 1)[Right])[A second exam, without a name.]
]

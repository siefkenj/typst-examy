// Demonstrates points: badges, rollup to the question, the points table,
// and bonus points. Uses a small auto-height page so the render is easy to
// read in the README.
//
// Compile: typst compile --root .. points.typ
#import "../src/lib.typ": *

#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()

// `num-questions`, `num-points`, and `points-table` work anywhere in the
// document — even before the exam.
This exam has #num-questions questions worth #num-points points.

#{
  set align(center)
  points-table
}

#exam(questions: [
  #question(points: 2)[A question worth two points.]
  #question[
    Points on parts roll up to their question.
    #part(points: 1)[One point.]
    #part(points: 3)[Three points.]
  ]
  #question(points: 4)[
    Bonus points are tallied separately and excluded from the totals.
    #part(points: 2, intent: "bonus")[*Bonus:* not counted above.]
  ]
])

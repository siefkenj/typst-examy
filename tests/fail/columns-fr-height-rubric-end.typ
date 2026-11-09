// expect: so the rubric drawn at the `"end"`, after the `columns`, gets no room in the block
// An `fr` height in `columns` takes all of a block's height, and a rubric at the
// `"end"` of the part holding them, drawn after them, has no page to move on to:
// it would be drawn out of the block, over the next question.
#import "/src/lib.typ": *

#show: exam.with(show-rubrics: true, rubric-position: "end")

#question(height: 3in)[
  Q.
  #part(rubric: [#rubric(points: 1)[Part rubric]])[
    #columns(2)[#answer-box(height: 1fr)[] #colbreak() #answer-box(height: 1fr)[]]
  ]
]
#question[Next]

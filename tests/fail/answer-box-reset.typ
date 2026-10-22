// expect: an `e.reset` rule inside an exam, around answer boxes
// An `e.reset` around answer boxes inside an exam: the exam draws the boxes
// itself, and cannot follow what it undoes.
#import "/src/lib.typ": *

#show: e.set_(answer-box, stroke: none)
#show: exam
#question[A. #answer-box(width: 100%)[]]
#[
  #show: e.reset(answer-box)
  #question[B. #answer-box(width: 100%)[]]
]

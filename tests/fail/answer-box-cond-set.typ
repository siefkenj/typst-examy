// expect: an `e.cond-set` rule inside an exam, around answer boxes
// An `e.cond-set` on answer boxes inside an exam: elembic applies it box by
// box as it draws them, and the exam draws its boxes itself.
#import "/src/lib.typ": *

#show: exam
#show: e.cond-set(answer-box.with(stroke: none), height: 3cm)
#question[A. #answer-box(width: 100%, stroke: none)[]]

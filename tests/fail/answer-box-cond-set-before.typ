// expect: an `e.cond-set` rule on `answer-box` before an exam
// An `e.cond-set` on answer boxes before an exam: elembic applies it box by
// box as it draws them, so not to the boxes the exam draws itself.
#import "/src/lib.typ": *

#show: e.cond-set(answer-box.with(height: 1cm), fill: red)
#show: exam
#question[A. #answer-box(width: 100%, height: 1cm)[]]

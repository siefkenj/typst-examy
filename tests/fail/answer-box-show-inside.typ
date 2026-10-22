// expect: an `e.show_` rule inside an exam, around answer boxes
// An `e.show_` rule on answer boxes inside an exam: elembic applies it to a
// box as it draws it, and the exam draws its boxes itself.
#import "/src/lib.typ": *

#show: exam
#show: e.show_(answer-box, it => [Replaced])
#question[A. #answer-box(width: 100%, height: 1cm)[]]

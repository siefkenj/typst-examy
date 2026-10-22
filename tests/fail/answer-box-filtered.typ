// expect: an `e.filtered` rule inside an exam, around answer boxes
// An `e.filtered` rule setting answer boxes inside an exam: elembic applies
// it to the boxes inside the elements it matches as it draws them, and the
// exam draws its boxes itself.
#import "/src/lib.typ": *

#show: exam
#show: e.filtered(solution, e.set_(answer-box, stroke: none))
#question[A. #answer-box(width: 100%)[]]

// expect: an `e.cond-set` rule inside an exam, around answer boxes
// An `e.cond-set` on `config` inside an exam, setting an option for answer
// boxes: elembic applies it where it matches, and the exam draws its boxes
// itself.
#import "/src/lib.typ": *

#show: exam
#show: e.cond-set(config.with(show-solutions: true), answer-box-height: 3cm)
#question[A. #answer-box(width: 100%)[]]

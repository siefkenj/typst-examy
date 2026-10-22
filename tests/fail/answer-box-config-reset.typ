// expect: an `e.reset` rule inside an exam, around answer boxes
// An `e.reset` of `config` around answer boxes inside an exam that sets an
// option for them: the exam draws the boxes itself, and cannot follow what
// it undoes.
#import "/src/lib.typ": *

#show: exam.with(answer-box-height: 3cm)
#question[A. #answer-box(width: 100%)[]]
#[
  #show: e.reset(config)
  #question[B. #answer-box(width: 100%)[]]
]

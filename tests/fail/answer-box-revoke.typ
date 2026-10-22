// expect: an `e.revoke` rule inside an exam, around answer boxes
// An `e.revoke` of a named `answer-box` rule inside an exam: the exam draws
// the boxes itself, and cannot follow what it undoes.
#import "/src/lib.typ": *

#show: exam
#show: e.named("tall", e.set_(answer-box, height: 1fr))
#question[A. #answer-box(width: 100%)[]]
#[
  #show: e.revoke("tall")
  #question[B. #answer-box(width: 100%)[]]
]

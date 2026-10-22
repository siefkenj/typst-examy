// expect: an `e.revoke` rule inside an exam, around answer boxes
// An `e.revoke` inside an answer box, of a named rule in force around the
// box: the exam draws the box inside it too.
#import "/src/lib.typ": *

#show: exam
#show: e.named("thick", e.set_(answer-box, stroke: 2pt))
#question[A. #answer-box(width: 100%, height: 3cm)[
  Show your work.
  #show: e.revoke("thick")
  #answer-box(height: 1cm)[]
]]

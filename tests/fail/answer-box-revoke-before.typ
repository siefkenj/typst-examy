// expect: an `e.revoke` rule inside an exam, around answer boxes
// An `e.revoke`, inside an exam, of a named `answer-box` rule made before
// it: it would undo fields the exam read where it starts.
#import "/src/lib.typ": *

#show: e.named("thick", e.set_(answer-box, stroke: 2pt))
#show: exam
#show: e.revoke("thick")
#question[A. #answer-box(width: 100%, height: 1cm)[]]

// expect: an `e.show_` rule on `answer-box` before an exam
// An `e.show_` rule on answer boxes before an exam: it would replace boxes
// outside the exam, but not those the exam draws itself.
#import "/src/lib.typ": *

#show: e.show_(answer-box, it => [Replaced])
#show: exam
#question[A. #answer-box(width: 100%, height: 1cm)[]]

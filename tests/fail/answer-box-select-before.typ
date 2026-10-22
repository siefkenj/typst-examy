// expect: an `e.select` rule on `answer-box` before an exam
// An `e.select` on answer boxes around an exam: elembic labels the boxes it
// matches as it draws them, so not the boxes the exam draws itself.
#import "/src/lib.typ": *

#e.select(answer-box.with(height: 1cm), prefix: "tall", tall => {
  show tall: set text(red)
  exam[#question[A. #answer-box(width: 100%, height: 1cm)[]]]
})

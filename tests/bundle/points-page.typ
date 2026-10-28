// The exam and its key from one compile, as a bundle (as the guide's
// Solutions page shows): each document numbers its pages from 1, so page 1
// of the key is not page 1 of the exam. The points on a page, and a points
// table by page, count only the document they are in.
#import "/src/lib.typ": *

#let quiz = [
  #show: exam
  #question(points: 2)[First.]
  #question(points: 3)[Second.]
  #question(points: 1, intent: "bonus")[Bonus.]
  Points on this page: #num-points-page.
  #context [#metadata((
      points: get-num-points-page(),
      bonus: get-num-points-page(bonus: true),
      page: get-num-points-page(page: 1),
    ))<page-points>]
  #points-table(granularity: "page", bonus: true)
  #pagebreak()
  #question(points: 4)[On page 2.]
  Points on this page: #num-points-page.
  #context [#metadata(get-num-points-page())<page-2-points>]
  #context {
    let first = query(<page-points>).map(m => m.value)
    assert(first.len() == 2, message: "expected one record per document, got " + str(first.len()))
    for v in first {
      assert(v == (points: 5, bonus: 1, page: 5), message: "page 1 of one document: expected 5 points and 1 bonus, got " + repr(v))
    }
    let second = query(<page-2-points>).map(m => m.value)
    assert(second == (4, 4), message: "page 2 of each document: expected 4 points, got " + repr(second))
  }
]

#document("exam.pdf", {
  show: e.set_(config, show-solutions: false)
  quiz
})
#document("key.pdf", {
  show: e.set_(config, show-solutions: true)
  quiz
})

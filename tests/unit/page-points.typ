// `page-points` counts the points of each division on the page it starts
// on, regular and bonus apart, and `page-score-box`, made for a footer,
// uses it.
#import "/src/lib.typ": *

#set page(width: 4in, height: 4in, margin: .5in, footer: page-score-box + context [#metadata(page-points())<footer>])
#show: e.prepare()

Cover page: no points.
#pagebreak()

#exam(questions: [
  #question(points: 2)[On page 2.]
  #question[
    #part(points: 3)[Also on page 2.]
    #pagebreak()
    #part(points: 1)[On page 3.]
    #part(points: 4, intent: "bonus")[A bonus on page 3.]
    #part(points: 5, intent: "practice")[Practice, not counted.]
  ]
])

#context {
  let got = range(1, 4).map(p => page-points(page: p))
  assert(got == (0, 5, 1), message: repr(got))
  let got = range(1, 4).map(p => page-points(page: p, bonus: true))
  assert(got == (0, 0, 4), message: repr(got))
  // The current page.
  assert(page-points() == 1)
}

// In a footer, `page-points()` is the points of the page the footer is on.
#context {
  let got = query(<footer>).map(m => m.value)
  assert(got == (0, 5, 1), message: repr(got))
}

// The counts, as numbers (`get-num-..()`, in context) and shown
// (`num-..`, anywhere). `get-num-points-page` counts the points of each
// division on the page it starts on, regular and bonus apart;
// `num-points-page` shows the current page's, and `page-score-box`, made
// for a footer, uses it.
#import "/src/lib.typ": *

#set page(
  width: 4in,
  height: 4in,
  margin: .5in,
  footer: page-score-box() + [ Points here: #num-points-page] + context [#metadata(get-num-points-page())<footer>],
)
#show: e.prepare()

Cover page: no points. This exam has #num-questions questions, #num-points points, and
#num-bonus-points bonus points.
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
  let got = range(1, 4).map(p => get-num-points-page(page: p))
  assert(got == (0, 5, 1), message: repr(got))
  let got = range(1, 4).map(p => get-num-points-page(page: p, bonus: true))
  assert(got == (0, 0, 4), message: repr(got))
  // The current page.
  assert(get-num-points-page() == 1)
  // The exam's counts, as numbers to compute with.
  assert.eq((get-num-questions(), get-num-points(), get-num-bonus-points()), (2, 6, 4))
  [Pass mark: #calc.ceil(get-num-points() * .6) of #num-points.]
}

// In a footer, `get-num-points-page()` is the points of the page the footer
// is on.
#context {
  let got = query(<footer>).map(m => m.value)
  assert(got == (0, 5, 1), message: repr(got))
}

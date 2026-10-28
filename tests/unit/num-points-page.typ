// The counts, as numbers, in context: shown with `#context num-..()`, and
// computed with. `num-points` and `num-points-page` count the points of an
// `intent`, regular by default; `num-points-page` those of each division on
// the page it starts on, the current page's by default, and
// `page-score-box`, made for a footer, uses it.
#import "/src/lib.typ": *

#set page(
  width: 4in,
  height: 4in,
  margin: .5in,
  footer: page-score-box() + [ Points here: #context num-points-page()] + context [#metadata(num-points-page())<footer>],
)
#show: e.prepare()

Cover page: no points. This exam has #context num-questions() questions, #context num-points() points,
#context num-points(intent: "bonus") bonus points, and #context num-points(intent: "practice") practice
points.
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
  let got = range(1, 4).map(p => num-points-page(page: p))
  assert(got == (0, 5, 1), message: repr(got))
  let got = range(1, 4).map(p => num-points-page(page: p, intent: "bonus"))
  assert(got == (0, 0, 4), message: repr(got))
  let got = range(1, 4).map(p => num-points-page(page: p, intent: "practice"))
  assert(got == (0, 0, 5), message: repr(got))
  // The current page.
  assert(num-points-page() == 1)
  // The exam's counts, as numbers to compute with.
  assert.eq(
    (num-questions(), num-points(), num-points(intent: "bonus"), num-points(intent: "practice")),
    (2, 6, 4, 5),
  )
  [Pass mark: #calc.ceil(num-points() * .6) of #num-points().]
}

// In a footer, `num-points-page()` is the points of the page the footer is
// on.
#context {
  let got = query(<footer>).map(m => m.value)
  assert(got == (0, 5, 1), message: repr(got))
}

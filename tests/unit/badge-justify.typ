// The points badge must not be stretched by paragraph justification. A body
// that starts with a full-width inline `answer-box` pushes that box onto the
// next line, which makes the badge's line a non-final (and so justified) one;
// an unboxed badge then spread "(1 point)" across the whole measure.
#import "/src/lib.typ": *

#set page(paper: "us-letter", margin: 1in)
#set par(justify: true)
#show: e.prepare()
#show: e.set_(config, show-solutions: false)

#exam(
  questions: [
    #question(points: 1)[
      A prompt.
      #part(points: 1)[
        #box(width: 0pt)[#metadata(none)<after-badge>]
        #answer-box(height: 1in, width: 100%)[]
      ]
    ]
  ],
)

#context {
  // Sits immediately after the badge: with a stretched badge it would be
  // flung to the right margin (x ~ 7.5in) instead of staying next to the
  // part's gutter label.
  let x = query(<after-badge>).first().location().position().x
  assert(
    x < 3in,
    message: "points badge was stretched by justification; content after it starts at " + repr(x),
  )
}

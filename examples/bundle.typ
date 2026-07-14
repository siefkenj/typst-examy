// Produces TWO PDFs from a single file using Typst's (experimental) bundle
// export: `quiz-nosolutions.pdf` and `quiz-solutions.pdf`.
//
// Bundle export is experimental and must be enabled explicitly:
//
// Compile: typst compile --root .. --features bundle -f bundle bundle.typ out/
#import "../src/lib.typ": *

/// The quiz itself, parameterized over whether solutions are shown.
#let quiz(solutions) = {
  set page(paper: "us-letter", margin: 1in)
  show: e.prepare()
  show: e.set_(config, show-solutions: solutions)

  name-block()

  exam(questions: [
    #question(points: 2)[
      Compute $integral_0^1 3 x^2 dif x$.
      #answer-box(width: 100%, height: 1fr)[
        #solution[$integral_0^1 3 x^2 dif x = lr([x^3])_0^1 = 1$.]
      ]
    ]
    #question(points: 1)[
      True or false: every continuous function is differentiable.
      #solution[False: $|x|$ is continuous but not differentiable at $0$.]
    ]
  ])
}

#document("quiz-nosolutions.pdf", quiz(false))
#document("quiz-solutions.pdf", quiz(true))

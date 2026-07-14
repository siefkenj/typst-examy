// A compact single-page quiz.
//
// Compile:                  typst compile --root .. quiz.typ
// Compile with solutions:   typst compile --root .. --input show-solutions=true quiz.typ
#import "../src/lib.typ": *
#import "@preview/lilaq:0.6.0" as lq

#set page(paper: "us-letter", margin: 1in, header: text(fill: gray.darken(50%))[
  MAT 101 #h(1fr) Quiz 3
])
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

// A fill-in block for the student's name; `name-block` can be placed
// anywhere — here it sits at the top of the quiz page.
#name-block(title: [Your name])

#exam(
  questions: [
    #question(points: 2)[
      State the $epsilon$-$delta$ definition of what it means for a function $f$ to be _continuous_
      at a point $a$.
      #answer-box(width: 100%, height: 1fr)[
        #solution[
          $f$ is continuous at $a$ if for every $epsilon > 0$ there exists a $delta > 0$ such that
          whenever $|x - a| < delta$, we have $|f(x) - f(a)| < epsilon$.
        ]
      ]
    ]
    #question(points: 3)[
      Give an example of a function that is continuous everywhere but fails to be differentiable at
      exactly one point. Justify your answer.
      #answer-box(width: 100%, height: 2fr)[
        #solution[
          $f(x) = |x|$ is continuous everywhere. At $x = 0$ the difference quotient $(|h| - 0)/h$
          approaches $1$ from the right and $-1$ from the left, so $f'(0)$ does not exist. At every
          other point $f$ is locally a linear function, hence differentiable.
        ]
      ]
    ]
    #question(points: 2)[
      The graph below shows a function $f$. On the graph, sketch the graph of its derivative $f'$.

      // The solution is part of the *plot*, so `#solution[...]` can't hide
      // it. Instead, retrieve the `show-solutions` value from elembic with
      // `e.get` and add the solution curve to the diagram only when
      // solutions are enabled.
      #{
        set align(center)
        e.get(get => {
          // `get(config).show-solutions` would read the raw config value;
          // the `show-solutions` helper also honors the command-line
          // `--input show-solutions=...` override.
          let solutions = show-solutions(get) != false
          let xs = lq.linspace(-2 * calc.pi, 2 * calc.pi, num: 200)
          lq.diagram(
            width: 12cm,
            height: 5.5cm,
            xlabel: $x$,
            ylabel: $y$,
            lq.plot(xs, xs.map(x => calc.sin(x)), mark: none, color: black, label: $f$),
            ..if solutions {
              (
                lq.plot(
                  xs,
                  xs.map(x => calc.cos(x)),
                  mark: none,
                  color: blue,
                  stroke: 2pt,
                ),
              )
            } else { () },
          )
        })
      }
    ]
  ],
)

// A compact single-page quiz.
//
// Compile:                  typst compile --root .. quiz.typ
// Compile with solutions:   typst compile --root .. --input show-solutions=true quiz.typ
#import "../src/lib.typ": *

#set page(paper: "us-letter", margin: 1in, header: text(fill: gray.darken(50%))[
  MAT 101 #h(1fr) Quiz 3
])
#show: e.prepare()
#show: e.set_(config, show-solutions: false)

#exam(
  name_list: (none,),
  questions: [
    #question(points: 2)[
      State the $epsilon$-$delta$ definition of what it means for a function
      $f$ to be _continuous_ at a point $a$.
      #answer-box(width: 100%, height: 1fr)[
        #solution[
          $f$ is continuous at $a$ if for every $epsilon > 0$ there exists a
          $delta > 0$ such that whenever $|x - a| < delta$, we have
          $|f(x) - f(a)| < epsilon$.
        ]
      ]
    ]
    #question(points: 3)[
      Give an example of a function that is continuous everywhere but fails
      to be differentiable at exactly one point. Justify your answer.
      #answer-box(width: 100%, height: 2fr)[
        #solution[
          $f(x) = |x|$ is continuous everywhere. At $x = 0$ the difference
          quotient $(|h| - 0)/h$ approaches $1$ from the right and $-1$
          from the left, so $f'(0)$ does not exist. At every other point $f$
          is locally a linear function, hence differentiable.
        ]
      ]
    ]
  ],
)

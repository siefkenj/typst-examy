// Demonstrates `#solution[...]`: inside an answer box and inline. Uses a
// small auto-height page so the render is easy to read in the README.
//
// Student version:  typst compile --root .. --input show-solutions=false solutions.typ
// Answer key:       typst compile --root .. --input show-solutions=true solutions.typ
#import "../src/lib.typ": *

#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()
#show: e.set_(config, show-solutions: false)

#exam(questions: [
  #question(points: 2)[
    Compute $integral_0^1 3 x^2 dif x$.
    #answer-box(width: 100%, height: 2.4cm)[
      #solution[
        $integral_0^1 3 x^2 dif x = lr([x^3])_0^1 = 1$.
      ]
    ]
  ]
  #question(points: 1)[
    True or false: every continuous function is differentiable.
    #solution[False: $|x|$ is continuous but not differentiable at $0$.]
  ]
])

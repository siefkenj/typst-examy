#import "../template.typ": *

Wrap a solution in #api("solution"), anywhere in the document — inside an
answer box, or on its own. Solutions are only shown when they are turned on,
so the same source produces both the exam and its answer key:

#example(
  ```typ
  #question(points: 2)[
    Compute $integral_0^1 3 x^2 dif x$.
    #answer-box(width: 100%, height: 2.4cm)[
      #solution[$integral_0^1 3 x^2 dif x = lr([x^3])_0^1 = 1$.]
    ]
  ]
  #question(points: 1)[
    True or false: every continuous function is differentiable.
    #solution[False: $|x|$ is continuous but not differentiable at $0$.]
  ]
  ```,
)

Solutions are turned on in the document, with #api("config"):

```typ
#show: e.set_(config, show-solutions: true)
```

== Exam and answer key from the command line

The `show-solutions` input overrides the document's setting, so that a build
script can produce either version whatever the source currently says:

```bash
typst compile exam.typ                                 # whatever the document configures
typst compile --input show-solutions=false exam.typ    # student version (force solutions off)
typst compile --input show-solutions=true exam.typ     # answer key (force solutions on)
```

Typst's (experimental) _bundle_ export can also emit both PDFs from a single
compilation: wrap the exam in a function of the `show-solutions` value and
make one `document` of each version.

```typ
#let quiz(solutions) = {
  set page(paper: "us-letter", margin: 1in)
  show: e.prepare()
  show: e.set_(config, show-solutions: solutions)

  name-block()
  exam(questions: [
    ...
  ])
}

#document("quiz-nosolutions.pdf", quiz(false))
#document("quiz-solutions.pdf", quiz(true))
```

```bash
typst compile --features bundle -f bundle bundle.typ out/
# writes out/quiz-nosolutions.pdf and out/quiz-solutions.pdf
```

== Something in the solution's place

A solution can have something shown in its place on the exam, with
`otherwise`: a blank to fill in, or lines to write on. Inside an answer box
with no height, the key draws the solution over it, in the space it took on
the exam, so the two still lay out the same. Elsewhere, the solution replaces
it.

#example(
  ```typ
  #let lines = block(width: 100%, for _ in range(3) { v(1.6em); line(length: 100%) })

  #question[
    Differentiate $f(x) = x^2$.
    #answer-box(width: 100%, stroke: none)[
      #solution(otherwise: lines)[By the power rule, $f'(x) = 2x$.]
    ]
  ]
  #question[
    #answer-box(width: 100%, stroke: none)[
      The capital of Canada is #solution(otherwise: box(width: 3cm, stroke: (bottom: .5pt)))[Ottawa].
    ]
  ]
  ```,
)

== Solution colors

Solutions are drawn in a pair of colors: the text, and the highlight behind
it. Set one and the other is derived from it.

#example(
  ```typ
  #show: e.set_(config, solution-color: maroon)

  #question[What is $6 times 7$? #answer-box[#solution[42]]]
  #question[
    Name the largest planet.
    #answer-box(width: 100%)[#solution[Jupiter.]]
  ]
  ```,
)

```typ
#show: e.set_(config, solution-color: maroon)                        // highlight follows
#show: e.set_(config, solution-background-color: olive.lighten(90%)) // text follows
#show: e.set_(config, solution-color: maroon, solution-background-color: luma(93%))
```

== An answer key that differs from the exam

A `#solution` only changes what is drawn in its own place. When the key
should differ from the exam in what it holds — a part of its own, an answer
box of another size — give #api("exam") its questions as a function. It is
called with a function of its own, `solutions-only` here: `solutions-only(x)`
is `x` on the key and nothing on the exam, and `solutions-only(x, otherwise:
y)` is `y` on the exam. What it is given is drawn as it is, not as a
solution.

#example(
  ```typ
  #exam(questions: solutions-only => [
    #question(points: 2)[
      Compute $integral_0^1 2x dif x$.
      // Room to write on the exam; on the key, just the answer.
      #answer-box(width: 100%, height: solutions-only(auto, otherwise: 2cm))[
        #solution[$lr(x^2 |)_0^1 = 1$]
      ]
      // A note to the grader, on the key only.
      #solutions-only(part(number: none)[_Award 1 point for the antiderivative._])
    ]
    #question(points: 1)[Is $f(x) = x^2$ even?]
  ])
  ```,
)

A question only on the key would renumber the questions after it, so give one
`number: none`, or put what the key adds in a part, as above.

== Solutions `#solution` cannot wrap

Some answers cannot be wrapped in a solution, such as one curve of a plot that
only the key should draw. #api("show-solutions") reads the effective setting,
command-line override included, inside `e.get`:

#example(
  ```typ
  #e.get(get => {
    let solutions = show-solutions(get)
    let s = 2.5cm
    box(width: s, height: s, stroke: .5pt, {
      place(line(start: (0pt, s), end: (s, 0pt), stroke: gray))
      if solutions {
        place(line(start: (0pt, 0pt), end: (s, s), stroke: 1.5pt + blue))
      }
    })
  })
  ```,
  key: true,
  width: 2.5cm + .5pt,
)

The quiz on the #page-link("index.html")[first page] uses this to draw the
answer to a sketch-the-derivative question, plotted with
#link("https://typst.app/universe/package/lilaq")[lilaq], on the key only.

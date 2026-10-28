#import "../template.typ": *

Wrapping content in #api("solution", arg: "[..]") ensures that it is only shown in an "answer key"
version of an exam, which means you can use a single source to render both an exam and its answer
key. Solutions can be placed anywhere in an exam, but are often placed in an #api(
  "answer-box",
  arg: "[..]",
).

#example(
  ```typ
  #solution[SOLUTIONS]

  #question(points: 2)[
    Compute $integral_0^1 3 x^2 dif x$.
    #answer-box(width: 100%, height: 2.4cm)[
      #solution[$integral_0^1 3 x^2 dif x = lr([x^3])_0^1 = 1$.]
    ]
  ]
  #question(points: 1)[
    True or false: every continuous function is differentiable.
    #solution[False: $|x|$ is continuous but not
      differentiable at $0$.]
  ]
  ```,
)

To toggle whether solutions are visible, set #api("config", field: "show-solutions") on the global
#api("config").

```typ
#show: exam.with(show-solutions: true)
```

or

```typ
#show: e.set_(config, show-solutions: true)
```


== Compiling with and without solutions

There are three ways to create solution/no-solution versions of an exam: (1) explicitly set
#api("config", field: "show-solutions", body: raw("show-solutions:")) as `true`/`false` and
recompile, (2) use a command-line flag, or (3) Typst's experimental bundle option.

=== Manually setting the flag

By default, solutions are shown in an exam. To create a no-solutions version, use
```typ
#show: exam.with(
  show-solutions: false
)
```
Putting `show-solutions` on its own line allows you to easily comment/uncomment the line to produce
multiple exam versions.


=== Command-line flag

The `show-solutions` #typst-link("reference/foundations/sys/")[input] given on the command line
overrides the document's `show-solutions` setting, so it can be used to create solution/no-solution
versions regardless of the current exam state.

```bash
# whatever the exam has set
typst compile exam.typ
# the exam (solutions off)
typst compile --input show-solutions=false exam.typ
# the answer key (solutions on)
typst compile --input show-solutions=true exam.typ
```

=== Experimental bundle option

Typst's (experimental) #typst-link("reference/bundle/")[_bundle_ export] can produce multiple PDFs
during a single compile. To use it, save the exam as content, and make one #typst-link(
  "reference/model/document/#parameters-path",
)[`document`] of each version, setting `show-solutions` around it with `e.set_`.

```typ
#let quiz = [
  #show: exam

  #question[..]
  #question[..]
]

#document("quiz-nosolutions.pdf", {
  show: e.set_(config, show-solutions: false)
  quiz
})
#document("quiz-solutions.pdf", {
  show: e.set_(config, show-solutions: true)
  quiz
})
```

```bash
typst compile --features bundle -f bundle bundle.typ out/
# writes out/quiz-nosolutions.pdf and out/quiz-solutions.pdf
```

#note[
  _Note._ The documents of a bundle share their labels, so each version of the exam has the same
  labelled questions. A reference to a question/part/subpart refers to the one in its own version.
  Other labelled content in the exam, such as a heading or a figure, is in every version too, and a
  reference to it is an error.
]

== Customizing solutions

=== Colors

The colors of solutions can be set via the global #api("config") with:

/ #api("config", field: "solution-color"): The color of a solution's text. The highlight behind it
  is derived from it, unless set too.
/ #api("config", field: "solution-background-color"): The color of the highlight. The text color is
  derived from it, unless set too.

If only one is set, the other is inferred by lightening or darkening the set color.

A single solution takes its own #api("solution", field: "color") and
#api("solution", field: "background-color"), which win over the global options for that solution, as
in the last question below.

#example(
  ```typ
  #show: exam.with(solution-color: maroon)

  #question[What is $6 times 7$? #answer-box[#solution[42]]]
  #question[
    Name the largest planet.
    #answer-box(width: 100%)[#solution[Jupiter.]]
  ]
  #question[
    Name a primary color.
    #answer-box(width: 100%)[
      #solution(background-color: yellow.darken(30%))[Yellow.]
    ]
  ]
  ```,
)


=== The `otherwise:` argument

Normally, when a solution is not rendered, nothing is shown. Setting its
#api("solution", field: "otherwise", value: "..") value to content will show that content when a
solution is not shown. This can be used, for example, to show lined space on a no-solutions version
of an exam, but replace it with just a solution on the solutions version.

#example(
  ```typ
  #let lines = block(width: 100%, for _ in range(3) {
    v(1.6em)
    line(length: 100%)
  })

  #question[
    Differentiate $f(x) = x^2$.
    #answer-box(width: 100%, stroke: none)[
      #solution(otherwise: lines)[By the power rule,
        $f'(x) = 2x$.]
    ]
  ]
  #question[
    #answer-box(width: 100%, stroke: none)[
      The capital of Canada is #solution(
        otherwise: box(width: 3cm, stroke: (bottom: .5pt)),
      )[Ottawa].
    ]
  ]
  ```,
)

== Solutions inside graphics and other advanced solutions

A #api("solution", arg: "[..]") is wrapped in context, and as such, its output cannot be used
as the input for most functions, like those that draw graphics.

An alternative is to pass #api("exam", arg: "[..]") a function of the form `solutions-only => ..`.
The first argument is a function which returns its content only when solutions are rendered and
returns its `otherwise:` argument otherwise. This needs `#exam(solutions-only => [..])` around the
questions; with `#show: exam`, the exam is given content, not a function.

#example(
  ```typ
  #exam(solutions-only => [
    #question[
      Mark the top and right sides of the box.

      #box(width: 2cm, height: 2cm, stroke: (
        rest: .5pt,
        top: solutions-only(2pt + blue, otherwise: .5pt),
        right: solutions-only(2pt + blue, otherwise: .5pt),
      ))
    ]
  ])
  ```,
)

This can also be used to achieve effects like changing a question's height between solution and
no-solution versions.

#example(
  ```typ
  #exam(solutions-only => [
    _An exam with a compact key._
    #question[
      Find the derivative of $f(x) = x^3 - 2x$.
      // Room to work on the exam; on the key, only as tall as the answer.
      #answer-box(
        width: 100%,
        height: solutions-only(auto, otherwise: 3cm),
      )[#solution[$f'(x) = 3x^2 - 2$]]
    ]
    #question[Is $f$ increasing at $x = 1$?]
  ])
  ```,
)

The `solutions-only` function behaves in the following way:

/ `solutions-only(x)`: `x` on the key, and nothing on the exam.
/ `solutions-only(x, otherwise: y)`: `x` on the key, and `y` on the exam.

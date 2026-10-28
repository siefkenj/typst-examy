#import "../template.typ": *

A document is built out of an #api("exam", arg: "[..]") (alternatively `#show: exam`). Inside are
questions created with the commands #api("question", arg: "[..]"), #api("part", arg: "[..]"), and
#api("subpart", arg: "[..]"), used to create a question hierarchy. Questions/parts/subparts can be
assigned points, heights, etc.

#example(
  ```typ
  #show: exam

  #question[
    Let $f(x) = x^2 sin(1/x)$ for $x != 0$ and let $f(0) = 0$.
    #part(points: 2)[
      Show that $f$ is continuous at $x = 0$.
      #answer-box(height: 1fr)[]
    ]
    #part(points: 3)[
      Is $f$ differentiable at $x = 0$? Justify your answer.
      #subpart[Compute the difference quotient.]
      #subpart[Take its limit.]
      #answer-box(height: 1fr)[]
    ]
  ]
  ```,
  height: 9cm,
)

A part's numbering is determined _only_ by how deeply it is nested, so `#question[#question[..]]`
and `#question[#part[..]]` are numbered the same. The aliases `question`/`part`/`subpart` are
provided for convenience.

== Numbering a question

By default, questions automatically increment their number. Providing a
#api("question", field: "number", value: "..") argument to a `question`/`part`/`subpart` overrides
this behaviour. A numerical value will cause numbering to skip to that value; a non-numerical value
or general content will pause the counter and show that content. To omit a number completely, you
can set `number: none`.

#example(
  ```typ
  #question[An automatically numbered question.]
  #question[Another one.]
  #question(number: 10)[An integer sets the number.]
  #question[…and numbering continues from it.]
  #question(number: "★")[Content is shown verbatim.]
  #question(number: none)[An unnumbered question.]
  #question[The automatic counter ignores the previous two.]
  ```,
)

== Numbering styles

The numbering style of each level is set for the document via the global #api("config")'s
`numbering` option. It takes an array of #typst-link("reference/model/numbering/")[numbering
  patterns] (e.g., `("1.", "(a)", "(i)")`) or #typst-link("reference/model/numbering/")[numbering
  strings] following the same format as an #typst-link(
  "reference/model/enum/#parameters-numbering",
)[`enum`'s `numbering` argument] (e.g., `"1.a.i."`). Questions/parts/subparts are labelled
hierarchically with the left-most numbering pattern being assigned to the outer-most
question/part/subpart.

#example(
  ```typ
  #show: exam.with(
    numbering: ("Problem 1.", "(A)", "i."),
  )

  #question[
    The first problem.
    #part[A part.]
    #part[Translate the question statement of @later to German.]
  ]
  #question[
    #part(label: <later>)[Where is the nearest grocery store?]
    #part[Relative to your answer in part @later, where is the nearest train station?]
  ]
  ```,
  inset: 5em,
)

To force each question/part/subpart to be labelled with a globally unique identifier, use
`numbering-full: true`. This is similar to setting the #typst-link(
  "reference/model/enum/#parameters-full",
)[`full` argument] on an `enum`.

#example(
  ```typ
  #show: exam.with(numbering: "1.a.i.", numbering-full: true)

  #question[
    #part[A part.]
    #part(label: <second>)[Another, with #subpart[a subpart.]]
  ]
  #question[See @second.]
  ```,
  inset: 3em,
)

To number some questions/parts/subparts differently, set `numbering` with a #api("config") rule
inside the exam. It takes the same values as the global `numbering` option and applies to the
questions/parts/subparts after the rule, up to the end of its scope.

#note[_Note._ Setting the `numbering` #api("config") rule does not change the question's
  #api("question", field: "number"). Set #api("question", field: "number") on the
  question/part/subpart if you additionally want the counting in the question label to reset, as
  the bonus question below does.]

#example(
  ```typ
  #question[What is $3 + 4$?]
  #[
    #show: e.set_(config, numbering: ("Bonus 1.", "(i)"))
    #question(number: 1)[
      #part[Name a prime number larger than 100.]
      #part(label: <largest>)[Name the largest prime number you know.]
    ]
  ]
  #question[Is your answer to @largest really prime?]
  ```,
  inset: 4em,
)

The #api("config", field: "indent") option sets how far each part and subpart is indented from the
question/part it is in (by default, `1.5em`). A question/part/subpart given
#api("question", field: "indent") itself uses its own.

== Height and writing space

To allow students a space to write, use #api("answer-box", arg: "(height: ..)[]"). However, if you
need a question and all its part/subparts to cumulatively take up a fixed amount of space, you can
provide a #api("question", field: "height", value: "..") argument directly on a question.

#example(
  ```typ
  #question(height: 4.5cm, points: 4)[
    Sketch the graph of $f(x) = x^3 - x$.
    #part[
      Mark its zeros.
      #answer-box(height: 1fr)[]
    ]
    #part[
      Mark its turning points.
      #answer-box(height: 1fr)[]
    ]
  ]
  #question[The next question starts below the first one's 4.5cm.]
  ```,
)

#warning[
  _Warning._
  A question/part/subpart with a #api("question", field: "height") is laid out as a single block,
  so it cannot break across pages, and the height of its part/subparts cannot be shared with other
  questions. Usually, you want to use something like
  #api("answer-box", arg: "(width: 100%, stroke: none, height: ..)[]") instead.
]

== Pagebreaks

#typst-link("reference/layout/pagebreak/")[`#pagebreak()`] works inside questions, parts, and
subparts. The question/part/subpart continues on the next page with the same indentation.

#example(
  ```typ
  #question(points: 2)[
    Explain why every differentiable function is continuous.
    #answer-box(width: 100%, height: 1.5cm)[
      #solution[If $f'(a)$ exists,
        $f(a + h) - f(a) = h dot (f(a + h) - f(a)) / h
          -> 0 dot f'(a) = 0$.]
    ]
    #pagebreak()
    #answer-box(width: 100%, height: 1.5cm)[
      #text(fill:gray)[_Scratch area_]
    ]
  ]
  #question[The next question.]
  ```,
)

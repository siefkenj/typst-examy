#import "../template.typ": *

Supplying a question/part/subpart with #api("question", field: "points", value: "x") will cause an
"(x points)" annotation to be shown next to the question/part/subpart. Points defined this way will
show up in the #api("points-table", arg: "()") as well as related functions like
#api("num-points", arg: "()"), #api("num-questions", arg: "()"), etc.

#example(
  ```typ
  #show: exam

  This exam has #context num-questions() questions worth #context num-points() points.

  #align(center, points-table())

  #question(points: 2)[A question worth two points.]
  #question[
    Points on parts roll up to their question.
    #part(points: 1)[One point.]
    #part(points: 3)[Three points.]
  ]
  #question(points: 4)[
    Bonus points are tallied separately and excluded from the
    totals.
    #part(points: 2, intent: "bonus")[
      *Bonus:* not counted above.
    ]
  ]
  ```,
)

== The "points" marker <points-badge>

A question/part/subpart with a value for #api("question", field: "points", value: "..") will display
the number of points for that question. The display can be customized in several ways.

=== Customizing the position of "points"

The global #api("config")'s `points-position` option sets where the points badge is placed:

/ `"start"`: (default) Directly after the question number.
/ `"margin-left"` or `"margin-right"`: In the page margin, level with the question number.
/ `"end"`: Flush right, at the end of the question (including any answer boxes), but before any
  part/subparts.


#example(
  ```typ
  #show: exam.with(
    points-position: "end",
  )

  #question(points: 2)[What is $2 + 2$?]
  #question[
    #part(points: 1)[
      Name a prime number.
      #answer-box(height:1fr)[]
    ]
    #part(points: 3)[Prove there are infinitely many.]
  ]
  ```,
)

=== Customizing the display and spelling of "points"

The display of points can be fully customized by setting the `points-format` and
`bonus-points-format` options of the global #api("config").

#example(
  ```typ
  #show: exam.with(
    points-format: p => [(#p #if p == 1 [Punkt] else [Punkte])],
    bonus-points-format: p => [
      (#p #if p == 1 [Bonuspunkt] else [Bonuspunkte])
    ],
  )

  #question(points: 1)[Ein Punkt.]
  #question(points: 2)[
    Zwei Punkte.
    #part(points: 1, intent: "bonus")[Ein Bonuspunkt.]
  ]
  ```,
)

=== Question totals

With `points-show-totals: true`, a question/part/subpart will show subtotals with the cumulative
number of points of all descendants. These additional subtotals are for display only and do not show
up in #api("num-points", arg: "()") or the points table.

#example(
  ```typ
  #show: exam.with(points-show-totals: true)

  #question[
    A question whose parts have points.
    #part(points: 2)[Two points.]
    #part[
      #subpart(points: 1)[My subpart]
      #subpart(points: 1)[My other subpart]
    ]
  ]
  #question(points: 4)[
    A question with points *and* points on its parts has no
    single total.
    #part(points: 1)[One point.]
  ]
  ```,
)

With `points-show-totals`, a question with #api("question", field: "points") of its own that also
has a part with `points` has no single total, so a red warning is shown in place of its points.

== Points tables

A #api("points-table", arg: "()") displays point totals for each question.
Multiple points tables can be included in an exam, and a points table can be customized via the
`points-table-..` options on the global #api("config") or by passing arguments directly to
#api("points-table", arg: "()").

#example(
  ```typ
  #show: exam

  #points-table(
    // A row per question (the default is "horizontal").
    direction: "vertical",
    // An empty Score row for the grader.
    score: true,
    // A Bonus row, when there are bonus points.
    bonus: true,
  )

  #question(points: 2)[First.]
  #question(points: 3)[Second.]
  #question(points: 5)[
    Third.
    #part(points: 1, intent: "bonus")[Bonus.]
  ]
  ```,
  width: 9cm,
)

By default, a points table has a column per question. Specifying
#api("points-table", field: "granularity", body: raw("granularity:")) as `"part"` or `"subpart"`
will create columns for each part or subpart instead, and `"page"` a column for each page (of the
questions/parts/subparts that start on it).

#example(
  ```typ
  #show: exam

  #points-table(granularity: "part")

  #question(points: 2)[What is $2 + 2$?]
  #question[
    #part(points: 3)[Factor $x^2 - 1$.]
  ]
  #question(points: 4)[
    Solve $x^2 = 4$.
    #part(points: 5)[Check both answers.]
  ]
  ```,
)

=== Localizing the points table

Examy includes some fixed strings which can be localized via the `strings` option in the global
#api("config"), including those that show up in the points table.

#example(```typ
#show: exam.with(
  strings: (
    question: [Aufgabe],
    points: [Punkte],
    total: [Summe],
  ),
  points-format: p => [(#p #if p == 1 [Punkt] else [Punkte])],
)

#points-table()

#question(points: 2)[What is $2 + 2$?]
#question(points: 3)[Factor $x^2 - 1$.]
```)

#note[
  _Note._ The `points` string affects the word "Points" as displayed in the points table. To change
  the display of "points" in a question, use `points-format`.
]

== Computing with points

#api("num-questions", arg: "()"), #api("num-points", arg: "()") and
#api("num-points-page", arg: "()") return numbers, which can be shown or computed with anywhere in
the document. They read the exam's points, so they must be called inside of a
#typst-link("reference/context/")[`context`] (e.g. `#context num-points()`).

`num-points` and `num-points-page` count the regular points by default. Give them an
#api("num-points", field: "intent") (`"bonus"` or `"practice"`, as on a question/part/subpart) to
count those points instead.

#example(
  ```typ
  #show: exam

  #context [
    This exam is worth #num-points() points over
    #num-questions() questions.

    You have 50 minutes: about
    #calc.round(50 / num-points(), digits: 1) minutes per point.

    A pass is #calc.ceil(num-points() * .6) points or more.

    #if num-points(intent: "bonus") > 0 [
      There are also #num-points(intent: "bonus") bonus points.
    ]
  ]

  #question(points: 4)[Differentiate $x^3 sin x$.]
  #question(points: 6)[
    Find $integral_0^1 x e^x dif x$.
    #part(points: 2, intent: "bonus")[
      *Bonus:* find $integral_0^1 x^2 e^x dif x$.
    ]
  ]
  ```,
)

=== Showing points per page

You can use #api("num-points-page", arg: "()") in a
#typst-link("reference/layout/page/#parameters-header")[page header] or
#typst-link("reference/layout/page/#parameters-footer")[footer] (or anywhere else on the page) to
show the number of points on the current page, subtotalling each question/part/subpart appearing on
that page.

This can be used to achieve effects like adding a "Score: \_\_\_\_ / 7" box on the footer of each
page.

```typ
#set page(footer: align(right, page-score-box()))

// Or one of your own:
#set page(footer: context if num-points-page() > 0 [
  Page total:
  #box(width: 2em, stroke: (bottom: .5pt))
  out of #num-points-page()
])
```

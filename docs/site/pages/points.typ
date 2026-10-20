#import "../template.typ": *

Giving any question/part/subpart a value with `points: x` will cause an "(x points)" annotation to
show next to the question/part/subpart. Related to points are:

- #api("points-table", body: raw("#points-table")) renders a scoring table.
- #api("num-points", body: raw("#num-points")) and #api("num-questions", body: raw(
    "#num-questions",
  )) give the total number of points and questions, and #api(
    "num-bonus-points",
    body: raw("#num-bonus-points"),
  ) the total number of bonus points.
- `intent: "bonus"` marks bonus points, which are tracked separately and excluded from the regular
  totals.
- #api("page-points", body: raw("page-points()")) gives the number of points on a page, and #api(
    "page-score-box",
    body: raw("#page-score-box"),
  ) draws a score box for a page footer.

#example(
  ```typ
  This exam has #num-questions questions worth #num-points points.

  #align(center, points-table)

  #exam(questions: [
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
  ])
  ```,
)

The totals can be used anywhere in the document, even before the exam. A part's points are added to
its question's total, and points marked `intent: "practice"` are left out of every total.

== Where the badge goes <points-badge>

The global #api("config")'s `points-position` option sets where the points badge is placed:

- `"start"` (the default): before the first word of the question.
- `"margin-left"` or `"margin-right"`: in the page margin, level with the question's first line. The
  margin must be wide enough to fit it.
- `"end"`: flush right, at the end of the question's own text (answer boxes included) and before its
  first part.

The badge itself is drawn by `points-format`, a function of the number of points. Use it to change
the badge's wording, or to translate it:

#example(
  ```typ
  #show: e.set_(
    config,
    points-position: "end",
    points-format: p => [[#p]],
  )

  #question(points: 2)[What is $2 + 2$?]
  #question(points: 1)[
    Name a prime number.
    #part(points: 3)[Prove there are infinitely many.]
  ]
  ```,
)

#example(
  ```typ
  #show: e.set_(
    config,
    points-format: p => [(#p #if p == 1 [Punkt] else [Punkte])],
  )

  #question(points: 1)[Ein Punkt.]
  #question(points: 2)[Zwei Punkte.]
  ```,
)

== Totals on questions

With `points-show-totals: true`, a question whose parts have points shows the total of its parts,
and each part still shows its own points. The total is for display only; it is not counted again in
#api("num-points") or the points table.

#example(
  ```typ
  #show: e.set_(config, points-show-totals: true)

  #question[
    A question whose parts have points.
    #part(points: 2)[Two points.]
    #part(points: 2)[Two more.]
  ]
  #question(points: 4)[
    A question with points of its own *and* on its parts has no
    single total.
    #part(points: 1)[One point.]
  ]
  ```,
)

A question with points of its own _and_ points on its parts, like the second one above, shows a
warning in red instead of its badge. Give the points to one or the other. Bonus and practice parts
don't count, so a `question(points: 4)` with a bonus part still shows "(4 points)".

== Points table layouts

The layout of #api("points-table") is set with the global #api("config"). To lay out one table
differently from the rest, set the options in a scope around it:

#example(
  ```typ
  #[
    #show: e.set_(
      config,
      // A row per question (the default is "horizontal").
      points-table-direction: "vertical",
      // An empty Score row for the grader.
      points-table-score: true,
      // A Bonus row, when there are bonus points.
      points-table-bonus: true,
    )
    #points-table
  ]

  #exam(questions: [
    #question(points: 2)[First.]
    #question(points: 3)[Second.]
    #question(points: 5)[
      Third.
      #part(points: 1, intent: "bonus")[Bonus.]
    ]
  ])
  ```,
  width: 9cm,
)

`points-table-by: "page"` totals the points per page instead of per question, and
`points-table-max-columns: 8` splits a long horizontal table into several tables, one below the
other.

== Points per page

#api("page-points") gives the number of points on the current page, where each question/part/subpart
counts toward the page it starts on. It needs `context` and returns a number, so you can use it in a
footer. #api("page-score-box") is a ready-made "Score: \_\_\_\_ / 7" box for a footer, and draws
nothing on pages without points:

```typ
#set page(footer: align(right, page-score-box))

// Or one of your own:
#set page(footer: context {
  let points = page-points()
  if points > 0 [
    Page total:
    #box(width: 2em, stroke: (bottom: .5pt))
    out of #points
  ]
})
```

== Localization

Examy includes some fixed strings which can be localized via the `strings` option in the global
#api("config").

```typ
#show: e.set_(config, strings: (
  question: [Aufgabe],
  points: [Punkte],
  total: [Summe],
))
```

The words in a points badge, "(2 points)", are drawn by `points-format` instead (see
#link(<points-badge>)[Where the badge goes]).

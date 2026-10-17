#import "../template.typ": *

Give a question, part, or subpart `points` and it shows a badge, "(2 points)",
and counts toward the exam's totals. A part's points add up to its question's.

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
      Bonus points are tallied separately and excluded from the totals.
      #part(points: 2, intent: "bonus")[*Bonus:* not counted above.]
    ]
  ])
  ```,
)

- #api("num-points") and #api("num-questions") are the exam's totals, and
  #api("num-bonus-points") the total of its bonus points. They work anywhere
  in the document, even before the exam.
- `intent: "bonus"` makes a division's points bonus points: tallied
  separately, and left out of the regular totals. `intent: "practice"` leaves
  them out of every total.
- #api("points-table") draws a table of the points, and #api("page-points")
  and #api("page-score-box") count them page by page.

== Where the badge goes

#api("config")'s `points-position` sets where the badge goes, for the whole
document:

- `"start"` (the default): before the first word of the body.
- `"margin-left"` or `"margin-right"`: in the page margin, level with the
  body's first line. The margin must be wide enough to hold it.
- `"end"`: flush right, after all of the body's own text (answer boxes
  included) and before its first part, on the same line as the last of it
  when there is room. After an `fr` answer box, the box gives up a line to it.

`points-format` draws the badge from the number of points, which is also where
the word "points" is translated:

#example(
  ```typ
  #show: e.set_(config, points-position: "end", points-format: p => [[#p]])

  #question(points: 2)[What is $2 + 2$?]
  #question(points: 1)[
    Name a prime number.
    #part(points: 3)[Prove there are infinitely many.]
  ]
  ```,
)

#example(
  ```typ
  #show: e.set_(config, points-format: p => [(#p #if p == 1 [Punkt] else [Punkte])])

  #question(points: 1)[Ein Punkt.]
  #question(points: 2)[Zwei Punkte.]
  ```,
)

== Totals on questions

With `points-show-totals`, a question (or part) whose parts have points shows
their total, and each part still shows its own. The total is only shown; it is
not counted again in #api("num-points") or the points table.

#example(
  ```typ
  #show: e.set_(config, points-show-totals: true)

  #question[
    A question whose parts have points.
    #part(points: 2)[Two points.]
    #part(points: 2)[Two more.]
  ]
  #question(points: 4)[
    A question with points of its own *and* on its parts has no single total.
    #part(points: 1)[One point.]
  ]
  ```,
)

A question with points of its own _and_ on its parts, as the second one above,
shows a warning in red in place of its badge: give the points to one or the
other. (Bonus and practice parts don't count: a `question(points: 4)` with a
bonus part shows "(4 points)".) With the points in the margin, a question that
starts directly with a part shares its first line with that part, and its
total is then left out, so the line shows the part's points only.

== Points table layouts

#api("points-table") is laid out by #api("config"). To lay out one table
differently from the rest, set these in a scope around it:

#example(
  ```typ
  #[
    #show: e.set_(
      config,
      points-table-direction: "vertical", // a row per question; default "horizontal"
      points-table-score: true,           // an empty Score row for the grader
      points-table-bonus: true,           // a Bonus row, when there are bonus points
    )
    #points-table
  ]

  #exam(questions: [
    #question(points: 2)[First.]
    #question(points: 3)[Second.]
    #question(points: 5)[Third. #part(points: 1, intent: "bonus")[Bonus.]]
  ])
  ```,
  width: 9cm,
)

`points-table-by: "page"` totals the points per page instead of per question,
and `points-table-max-columns: 8` splits a long horizontal table into several,
one below the other.

== Points per page

#api("page-points") is the number of points on the current page, counting each
question, part, and subpart on the page where it starts. It needs `context`
and returns a number, so a footer can test it. #api("page-score-box") is a
ready-made "Score: \_\_\_\_ / 7" box for a footer, which draws nothing on pages
without points:

```typ
#set page(footer: align(right, page-score-box))

// Or one of your own:
#set page(footer: context {
  let points = page-points()
  if points > 0 [Page total: #box(width: 2em, stroke: (bottom: .5pt)) out of #points]
})
```

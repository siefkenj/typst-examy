#import "../template.typ": *

examy's options are all set on one element, #api("config"), with a show rule
near the top of the document, after `#show: e.prepare()`:

```typ
#show: e.prepare()
#show: e.set_(
  config,
  show-solutions: false,
  points-position: "margin-right",
)
```

Like a `set` rule, a setting applies from where it is made to the end of the
document. A later `#show: e.set_(config, ..)` changes only the options it
names; the rest keep their values. Set options before #api("exam", body:
raw("#exam(...)")), so that they apply to the whole exam.

#example(
  ```typ
  #show: e.set_(
    config,
    division-numbering: ("Problem 1.", "(a)"),
    points-position: "end",
    points-format: p => [[#p pts]],
    solution-color: maroon,
  )

  #question(points: 3)[
    Find the derivative of $x^3$.
    #answer-box(width: 100%)[#solution[$3x^2$]]
  ]
  #question[
    #part(points: 1)[Is $91$ prime? #solution[No.]]
    #part(points: 2)[Factor $91$. #solution[$7 dot 13$]]
  ]
  ```,
  inset: 4.5em,
)

== Reading an option

Inside `e.get(get => ..)`, `get(config)` is a dictionary of every option's
value where it is read: for example, to use the exam's name and term in your
own title or page header.

#example(
  ```typ
  #show: e.set_(
    config,
    exam-name: [MAT 101 Quiz 3],
    term: [Fall 2026],
  )

  #e.get(get => [*#get(config).exam-name*, #get(config).term])
  ```,
)

Read whether solutions are shown with #api("show-solutions") instead (see
#page-link("solutions.html")[Solutions]): `get(config).show-solutions` misses
the command-line override, `--input show-solutions=..`.

// Every option, by topic. The tables are generated from `config`'s
// declaration; an option missing from all of them fails the build.
#let GROUPS = (
  (
    title: [Solutions],
    page: "solutions.html",
    options: ("show-solutions", "solution-color", "solution-background-color", "solution-text-color"),
  ),
  (
    title: [The title block],
    page: "cover-pages.html",
    options: ("institution", "exam-name", "term", "duration"),
  ),
  (
    title: [Numbering and wording],
    page: "questions.html",
    options: ("division-numbering", "strings"),
  ),
  (
    title: [Points],
    page: "points.html",
    options: (
      "points-format",
      "points-position",
      "points-show-totals",
      "points-table-direction",
      "points-table-by",
      "points-table-score",
      "points-table-bonus",
      "points-table-max-columns",
    ),
  ),
  (
    title: [Multiple choice],
    page: "choices.html",
    options: ("bubble-stroke", "bubble-label-font", "choices-enumerate"),
  ),
  (
    title: [Not yet in use],
    page: none,
    options: ("show-rubric",),
  ),
)
#{
  let listed = GROUPS.map(g => g.options).flatten()
  let missing = CONFIG_OPTIONS.filter(o => o not in listed)
  assert(missing.len() == 0, message: "configuration.typ: add " + missing.join(", ") + " to a group")
}

#for g in GROUPS {
  heading(level: 2, g.title)
  if g.page != none {
    let title = PAGES.find(p => p.path == g.page).title
    par[See #page-link(g.page, title) for these in use.]
  } else {
    par[Rubrics are accepted (a division's `rubric`) but not yet drawn.]
  }
  config-options(..g.options)
}

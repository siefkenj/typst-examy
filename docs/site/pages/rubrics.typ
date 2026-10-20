#import "../template.typ": *

// The examples with a rubric in the margin, whose dotted lines need to know
// where things are on the page: on the site, they are shown as images of a
// paged rendering (see `example`'s `paged-name`), which site.typ makes from
// this list.
#let PAGED_EXAMPLES = (
  margin: (
    paged-name: "rubrics-margin",
    code: ```typ
  #show: e.set_(config, show-rubric: auto, rubric-width: 4.4cm)

  #question(points: 3, rubric: [
    #rubric(points: 0)[Blank, or no derivative]
  ])[
    Compute $f'(x)$ for $f(x) = x^2 e^x$.
    #solution[
      By the product rule,#rubric(points: 2)[Uses the product rule]
      $f'(x) = 2x e^x + x^2 e^x = x e^x (x + 2)$.#rubric(points: 1)[Factors]
    ]
  ]
  ```,
    // As tall as the rubric, which is taller than the question.
    height: 2.4cm,
    inset: (right: 5cm),
  ),
  groups: (
    paged-name: "rubrics-groups",
    code: ```typ
  #show: e.set_(config, show-rubric: auto, rubric-width: 4.4cm)

  #question(points: 4, rubric: [
    #rubric[*Deductions*
      #rubric(points: -1)[Never says "lowest terms"]
      #rubric(pick: "one")[Logic
        #rubric(points: -2)[Circular]
        #rubric(points: -1)[A step not justified]
      ]
    ]
  ])[
    Prove that $sqrt(2)$ is irrational.
    #solution[
      #rubric(pick: "one")[Setup
        #rubric(points: 2)[Assumes $sqrt(2) = p/q$ in lowest terms]
        #rubric(points: 1)[Assumes $sqrt(2) = p/q$]
      ]Suppose $sqrt(2) = p/q$ with $p$ and $q$ coprime. Then
      $p^2 = 2q^2$, so $p$ and then $q$ are even,#rubric(points: 2)[Both even]
      which contradicts their being coprime.
    ]
  ]
  ```,
    height: 5.8cm,
    inset: (right: 5cm),
  ),
)
#let paged-example(ex) = example(ex.code, height: ex.height, inset: ex.inset, paged-name: ex.paged-name)

A rubric describes how a question is graded: what earns points and what loses them. Write rubric
items with the question using #api("rubric", body: raw("#rubric(points: ..)[..]")), and examy draws
them in the margin of the graders' copy. Items written inside a solution get a dotted line to the
spot they refer to. Rubrics are hidden unless turned on, and they take up no space, so the exam is
laid out the same with or without them.

#paged-example(PAGED_EXAMPLES.margin)

A question/part/subpart's rubric is made of the `#rubric` items in its body, in order, followed by
those in its `rubric:` argument. Put an item in the body (for example, in the solution) right where
the thing it gives points for appears, and the dotted line will show the grader where to look. Items
that aren't tied to a particular place, such as "Blank", go in the `rubric:` argument, along with
any notes for the grader, which are shown between the items.

An item's `points` are how much it changes the score: positive for credit, negative for a
deduction, and `0` for feedback only. Rubric points are not added to any total; only the question's
`points` are.

== Groups

A `#rubric` that contains other `#rubric`s is a group. Its first paragraph is the group's title, any
further text before the first item is a note, and the `#rubric`s inside are its items. With
`pick: "one"`, at most one of its items applies, and they are drawn as sections of a single box.
Groups can be nested.

#paged-example(PAGED_EXAMPLES.groups)

== Showing rubrics

Rubrics are turned on with the global #api("config")'s `show-rubric` option: `true`, `false` (the
default), or `auto`, which shows them whenever solutions are shown. As with solutions, the command
line overrides the document:

```bash
# the answer key, with its rubric, for the graders
typst compile --input show-solutions=true --input show-rubric=true exam.typ
```

== Where they go

The `rubric-position` option puts each rubric in the right margin (`"margin-right"`, the default),
in the left margin (`"margin-left"`), or at the `"end"` of its question/part/subpart, after its
parts. In a margin, a rubric lines up with the first line of its question/part/subpart, and moves
down if it would overlap the one before it. The margin needs to be wide enough to read it in.
`rubric-width` sets the rubric's width, which by default is the margin's width less a small gap on
each side.

To make room without changing the exam's layout, widen the page rather than the text. Keep the text
the same width, and add the rubric's space to the page and its margin, for the graders' copy only.

```typ
#let graders = sys.inputs.at("show-rubric", default: "false") == "true"
#set page(
  width: 8.5in + if graders { 2in } else { 0in },
  margin: (left: .75in, right: .75in + if graders { 2in } else { 0in }, y: .75in),
)
```

At the `"end"`, a rubric takes up space, so the exam is laid out differently with it. There, the
dotted lines are left out unless `rubric-trace: true` is set, and `rubric-trace: false` turns them
off in the margins too.

#example(
  ```typ
  #show: e.set_(config, show-rubric: auto, rubric-position: "end")

  #question(points: 2, rubric: [
    #rubric(points: 1)[States the hypotheses]
    #rubric(points: 1)[States the conclusion]
  ])[
    State the Mean Value Theorem.
    #answer-box(width: 100%, height: 2cm)[]
  ]
  ```,
)

#note(kind: "warning")[
  _Warning._ A rubric in the margin does not break across pages, so one that is too tall for the
  space left on its page runs off the page. Give its question a page of its own, or give the rubric
  more width.
]

== The rubrics on their own

#api("rubric-list", body: raw("#rubric-list")) lays out every rubric in the exam, one after another,
as a grading guide of its own. Put it after the exam, or in a separate document that includes the
exam. It works regardless of `show-rubric`.

== The rubrics as data

Every exam with rubrics also stores them in the document as invisible data, regardless of
`show-rubric`. Read them out as JSON from the command line:

```bash
typst eval --in exam.typ --pretty 'query(<examy-rubric>).first().value' > rubric.json
```

There is one entry per exam, in order. `exam` is the exam's number, starting from 1, and
`questions` lists each question/part/subpart that has a rubric, in order. Each one has a `number`
(`"2.1"` for 2 (a)), a `title` as shown on its card, its `points` (its parts' total if it has none
of its own), and its `rubric`, nested as written:

```json
{ "type": "item", "points": 2, "description": "Uses the product rule" }
{ "type": "group", "title": "Setup", "note": null, "pick": "one", "items": [..] }
{ "type": "note", "text": "Accept any equivalent form." }
```

Text is Markdown. Bold, italic, and lists are kept, and math is written in LaTeX between `$` (or
`$$` for display math). From there, a script (or an AI agent) can convert the rubrics into whatever
format a grading service needs, such as Gradescope's rubric upload.

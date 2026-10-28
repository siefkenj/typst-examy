#import "../template.typ": *

Rubrics indicate how points should be awarded when grading a question, and examy provides a
#api("rubric", arg: "(points: ..)[..]") for that purpose. By default, rubrics are shown in the
margin and take up no space in the exam. They can be nested in groups, and they can be authored
anywhere in an exam and will point back to the specific location where they are authored.

All rubric items in a particular question/part/subpart are grouped together and shown in a single
box in the margin. Rubric items set in the #api("question", field: "rubric", value: "..") option of
a question/part/subpart will not have a traceback line. To hide or show the traceback line of a
single rubric item, give it #api("rubric", field: "trace", value: "false") or `trace: true`;
#api("config")'s `rubric-trace` sets this for all of them.

// Shown as images of a paged rendering (`paged-name`), as a rubric's dotted
// lines need to know where things are on the page.
#example(
  ```typ
  #show: exam.with(show-rubrics: auto, rubric-width: 4.8cm)

  #question(points: 1, rubric: [
    #rubric(points: 1)[Name]
    Make sure it is correctly spelled.
  ])[
    Spell your name.
  ]

  #question(points: 3, rubric: [
    #rubric(points: 0)[Not a derivative]
    #rubric(points: 0)[Blank]
  ])[
    Compute $f'(x)$ for $f(x) = x^2 e^x$.
    #solution[
      By the product rule,#rubric(points: 2)[Uses the product rule]
      $f'(x) = 2x e^x + x^2 e^x = x e^x (x + 2)$.#rubric(points: 1)[Factors]
    ]
  ]
  ```,
  margin: (right: 5.5cm),
  // The rubrics are taller than the questions, which the site makes room for.
  pdf-height: (auto, 3.75cm),
  stacked: true,
  paged-name: "rubrics-margin",
)


A rubric item's #api("rubric", field: "points") can be positive or negative. No accounting/checking
is done by examy, and it is the author's responsibility to make sure that rubric points add up to
the correct total.

== Visibility

Rubrics are hidden by default and can be shown by setting `show-rubrics` on the global #api(
  "config",
).

/ `show-rubrics: false`: (default) Rubrics are hidden.
/ `show-rubrics: true`: Rubrics are shown.
/ `show-rubrics: auto`: Rubrics are shown whenever solutions are shown.

As with solutions, a command-line setting can be used to override the exam's settings.

```bash
# the answer key, with its rubric, for the graders
typst compile --input show-solutions=true --input show-rubrics=true exam.typ
```

== Groups

A #api("rubric", arg: "[..]") that contains other #api("rubric", arg: "[..]")s creates a group.
Its first paragraph is the group's title and the `#rubric`s inside are items. Any other non-rubric
text will show up as a note.

A rubric's #api("rubric", field: "annotation") argument supplies a short note for the grader, useful
for instructions like `annotation: [pick one]` on a group of mutually exclusive rubric items.

#example(
  ```typ
  #show: exam.with(show-rubrics: auto, rubric-width: 4.8cm)

  #question(points: 4, rubric: [
    #rubric[*Deductions*
      #rubric(points: -1)[Never says "lowest terms"]
      #rubric(annotation: [pick one])[Logic
        #rubric(points: -2)[Circular]
        #rubric(points: -1)[A step not justified]
      ]
    ]
  ])[
    Prove that $sqrt(2)$ is irrational.
    #solution[
      #rubric(annotation: [pick one])[Setup
        #rubric(points: 2)[Assumes $sqrt(2) = p/q$ in lowest terms]
        #rubric(points: 1)[Assumes $sqrt(2) = p/q$]
      ]Suppose $sqrt(2) = p/q$ with $p$ and $q$ coprime. Then
      $p^2 = 2q^2$, so $p$ and then $q$ are even,#rubric(points: 2)[Both even]
      which contradicts their being coprime.
    ]
  ]
  ```,
  margin: (right: 5.5cm),
  // The rubric is taller than the question, which the site makes room for.
  pdf-height: (auto, 5.0cm),
  stacked: true,
  paged-name: "rubrics-groups",
)

== Customizing the position of rubrics

The `rubric-position` option sets where each rubric is placed.

/ `"margin-right"`: (default) Place the rubric in the right margin.
/ `"margin-left"`: Place the rubric in the left margin.
/ `"end"`: Place the rubric at the end of the question/part/subpart where the rubric is placed.

When set in the margins, a rubric takes up no additional space. When `rubric-position: "end"` is
set, the rubrics will take up space on the page, so a rubric vs. no-rubric rendering will have
different spacings.

#example(
  ```typ
  #show: exam.with(show-rubrics: auto, rubric-position: "end")

  #question(points: 2, rubric: [
    #rubric(points: 1)[States the hypotheses]
    #rubric(points: 1)[States the conclusion]
  ])[
    State the Mean Value Theorem.
    #answer-box(width: 100%, height: 1cm)[#solution[Let $f:[a,b] -> RR$ ...]]
  ]
  #question(points: 1, rubric: rubric(points: 1)[Anything drawn])[
    Draw a picture.
  ]
  ```,
  stacked: true,
)

== Listing and exporting rubrics

To display all rubrics in a list, use the #api("rubric-list", arg: "()") function. It always
displays the rubrics, regardless of whether `show-rubrics` is set.

#example(
  ```typ
  #show: exam

  #question(points: 2, rubric: [
    #rubric(points: 1)[Uses $A = pi r^2$]
    #rubric(points: 1)[Gets $9 pi$]
  ])[What is the area of a circle of radius 3?]
  #question(points: 3, rubric: [
    #rubric(points: 2)[Uses the chain rule]
    #rubric(points: 1)[Simplifies]
    #rubric(points: -1, annotation: [once only])[Sign error]
  ])[Differentiate $sin(x^2)$.]

  *Grading guide*
  #rubric-list()
  ```,
)

Rubrics can also be exported as JSON data.

```bash
typst eval --in exam.typ --pretty 'query(<examy-rubric>).first().value' > rubric.json
```
The `.first().value` is used to retrieve the rubric from the first exam in the document (if your
document only has one exam, then the first exam will be your exam), and `.at(1)`, `.at(2)`, etc. can
be used to retrieve rubrics from other exams.

Rubric text is converted to Markdown and math is written as LaTeX between ```txt $``` (or
```txt $$``` for display math).

#example(
  ```typ
  #show: exam
  #set text(size: 0.8em)

  #question(points: 2, rubric: [
    #rubric(points: 1)[Uses $A = pi r^2$]
    #rubric(points: 1)[Gets $9 pi$]
  ])[What is the area of a circle of radius 3?]
  #question(points: 3, rubric: [
    #rubric(points: 2)[Uses the chain rule]
    #rubric(points: 1)[Simplifies]
    #rubric(points: -1, annotation: [once only])[Sign error]
  ])[Differentiate $sin(x^2)$.]

  *Rubric as JSON*
  #context {
    // Get the rubric data as JSON
    let data = query(<examy-rubric>).first().value
    raw(json.encode(data), lang: "json", block: true)
  }
  ```,
)


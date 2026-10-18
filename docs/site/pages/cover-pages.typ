#import "../template.typ": *

A cover page is ordinary content before #api("exam", body: raw("#exam(...)")):
a title block, a block of name fields, instructions, and a points table,
followed by a page break.

#screenshots(
  screenshot("cover.png", "An exam cover page with a title block, name fields, instructions, and a points table", caption: [The cover of #link(REPOSITORY + "/blob/main/examples/final-exam.typ")[`examples/final-exam.typ`].]),
)

== Name blocks

#api("name-block", body: raw("#name-block()")) renders a fill-in block
(Name / Student ID by default). It is ordinary content: put it at the top of a
quiz page or on a cover page. The rows are configurable with `fields:` — an
entry is either a `(prefix: ..., suffix: ...)` dictionary, rendered as the
prefix, an underline extending to the end of the line, and the suffix sitting
on the line at its right end, or any other content, shown as a row of its own.
An optional `title:` is shown above the block.

#example(
  ```typ
  // The default block: a Name row and a Student ID row.
  #name-block()

  #v(1.5em)

  // Custom rows.
  #name-block(fields: (
    (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
    (prefix: [Email address:], suffix: [`@university.edu`]),
    (prefix: [Student ID:]),
    {
      set align(center)
      text(size: .85em)[_Write legibly and darkly._]
    },
  ))
  ```,
  width: 10cm,
)

Institution-specific layouts ship with the package as #api("presets"); the
University of Toronto block is `#name-block(fields: presets.utoronto.name_fields)`.

== The title block

Set the exam's details (`institution`, `exam-name`, `term`, `duration`) on the
#api("config") object and render them with
#api("maketitle", body: raw("#maketitle()")). Each configured value can be
overridden by passing arguments to `maketitle()`, e.g.
`#maketitle(term: [Summer 2026])`.

#example(
  ```typ
  #show: e.set_(
    config,
    institution: [University of Examples],
    exam-name: [MAT 101 Final Exam],
    term: [Winter 2026],
    duration: duration(minutes: 150),
  )

  #maketitle()
  #v(1em)
  #name-block()
  ```,
  width: 13cm,
)

== A whole cover page

```typ
#show: e.set_(
  config,
  institution: [University of Examples],
  exam-name: [MAT 101 Final Exam],
  term: [Winter 2026],
  duration: duration(minutes: 150),
)

#maketitle()
#name-block(fields: (
  (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
  // ...more fields
))

#underline[_Instructions:_]
- Fill out your name and student information at the top of this
  page.
- Answer each question in the box provided; work outside the
  boxes will not be graded.
- No calculators or other aids are permitted.

#v(1fr)
#align(center, points-table)
#pagebreak()

#exam(questions: [...])
```

The repository's examples include
#link(REPOSITORY + "/blob/main/examples/quiz.typ")[a minimal quiz],
#link(REPOSITORY + "/blob/main/examples/final-exam.typ")[a complete exam] with
custom name fields, and
#link(REPOSITORY + "/blob/main/examples/utoronto-exam.typ")[an exam using the
University of Toronto preset].

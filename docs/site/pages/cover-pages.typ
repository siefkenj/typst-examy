#import "../template.typ": *

A cover page is ordinary content placed before the first question. Examy provides #api(
  "maketitle",
  arg: "()",
), #api("name-block", arg: "()"), and #api("points-table", arg: "()"), which may be used to
construct a typical cover page.

#screenshots(
  screenshot(
    "cover.png",
    "An exam cover page with a title block, name fields, instructions, and a points table",
    caption: [The cover of #link(
        REPOSITORY + "/blob/main/examples/final-exam.typ",
      )[```txt examples/final-exam.typ```].],
    // Short enough to fit on the chapter's first page.
    pdf-height: 15cm,
  ),
)

== Title blocks

A #api("maketitle", arg: "()") renders the exam's details, which are set with the global #api(
  "config",
). It includes the `institution`, `exam-name`, `term`, and `duration`. Each detail can be
overwritten by passing arguments directly to #api("maketitle", arg: "()") (e.g.
`#maketitle(term: [Summer 2026])`).

The exam's `duration` can be a typst #typst-link("reference/foundations/duration/")[`duration`] such
as `duration(minutes: 150)`, or content.

#example(
  ```typ
  #show: exam.with(
    institution: [University of Examples],
    exam-name: [MAT 101 Final Exam],
    term: [Winter 2026],
    duration: duration(minutes: 150),
  )

  #maketitle()
  ```,
  width: 13cm,
)

== Name blocks

A #api("name-block", arg: "()") renders a fill-in block, with a Name and a Student ID row by
default.

#note[
  _Note._ #api("maketitle", arg: "()") and #api("name-block", arg: "()") are typeset in the
  document's #typst-link("reference/text/text/#parameters-font")[font]. Use the usual
  `#set: text(font: ...)` commands to change the font.
]

=== Customizing

Name blocks can be customized by setting the `fields: (...)` attribute. The `fields` attribute
expects an array of content or dictionaries consisting of `(prefix: ..., suffix: ...)`.
`(prefix: ..., suffix: ...)` items will show before and after an underline.

#example(
  ```typ
  #set text(font: "DejaVu Sans Mono")

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

=== Presets

Institution-specific presets are available in #api("presets"). For example, the University of
Toronto standard can be typeset with `#name-block(fields: presets.utoronto.name-fields)`.

== Putting together a cover page

With `#show: exam` at the top of the document, the cover page is part of the exam, so the options
given to the exam apply to it too.

```typ
#show: exam.with(
  institution: [University of Examples],
  exam-name: [MAT 101 Final Exam],
  term: [Winter 2026],
  duration: duration(minutes: 150),
)

// The title and name blocks in the monospaced font bundled with Typst;
// the questions keep the document's font.
#{
  set text(font: "DejaVu Sans Mono")
  maketitle()
  name-block(fields: (
    (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
    // ...more fields
  ))
}

#underline[_Instructions:_]
- Fill out your name and student information at the top of this
  page.
- Answer each question in the box provided; work outside the
  boxes will not be graded.
- No calculators or other aids are permitted.

#v(1fr)
#align(center, points-table())
#pagebreak()

#question[...]
```

The repository's examples include #link(REPOSITORY + "/blob/main/examples/quiz.typ")[a minimal
  quiz], #link(REPOSITORY + "/blob/main/examples/final-exam.typ")[a complete exam] with custom name
fields, and #link(REPOSITORY + "/blob/main/examples/utoronto-exam.typ")[an exam using the University
  of Toronto preset].

#import "../template.typ": *

A cover page is ordinary content before the first question: a title block, a block of name fields,
instructions, and a points table, followed by a page break. With `#show: exam` at the top of the
document, the cover page is part of the exam, so the options given to the exam apply to it too.

#screenshots(
  screenshot("cover.png", "An exam cover page with a title block, name fields, instructions, and a points table", caption: [The cover of #link(REPOSITORY + "/blob/main/examples/final-exam.typ")[`examples/final-exam.typ`].]),
)

== Name blocks

#api("name-block", body: raw("#name-block()")) renders a fill-in block (Name / Student ID by
default). It is ordinary content, so put it at the top of a quiz page or on a cover page. The rows
are set with `fields:`. Each entry is either a `(prefix: ..., suffix: ...)` dictionary, drawn as the
prefix followed by a line to write on with the suffix at its right end, or any other content, shown
as a row of its own. An optional `title:` is shown above the block.

Like #api("maketitle"), a name block is set in the document's font. The examples here set both in
the monospaced font bundled with Typst with a `set` rule: in a code block (`#{ .. }`) around the
blocks when the questions after them should keep the document's font.

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

Institution-specific layouts ship with the package as #api("presets"). For example, the University
of Toronto block is `#name-block(fields: presets.utoronto.name-fields)`.

== The title block

Give the exam its details (`institution`, `exam-name`, `term`, `duration`) and render them with #api("maketitle", body: raw("#maketitle()")). Each configured value can be
overridden by passing arguments to `maketitle()`, e.g. `#maketitle(term: [Summer 2026])`.

A `duration` such as `duration(minutes: 150)` is shown in minutes, as "150 Minutes". To word it
another way, give content instead, e.g. `duration: [2 h 30 min]` or `duration: [2½ Stunden]`.

#example(
  ```typ
  #show: exam.with(
    institution: [University of Examples],
    exam-name: [MAT 101 Final Exam],
    term: [Winter 2026],
    duration: duration(minutes: 150),
  )
  #set text(font: "DejaVu Sans Mono")

  #maketitle()
  #v(1em)
  #name-block()
  ```,
  width: 13cm,
)

== A whole cover page

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

The repository's examples include
#link(REPOSITORY + "/blob/main/examples/quiz.typ")[a minimal quiz],
#link(REPOSITORY + "/blob/main/examples/final-exam.typ")[a complete exam] with
custom name fields, and
#link(REPOSITORY + "/blob/main/examples/utoronto-exam.typ")[an exam using the
University of Toronto preset].

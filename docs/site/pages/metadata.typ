#import "../template.typ": *

// The types of the data, from the files `tsc` checks, and that
// check-metadata-schema.mjs checks examy's output against: without their
// first comment, which says so.
#let schema(file) = {
  let lines = read("../" + file).split("\n")
  let n = lines.position(l => not l.starts-with("//"))
  raw(lines.slice(n).join("\n").trim(), lang: "ts", block: true)
}

Examy can embed data about the rubric and questions of an exam directly into the compiled PDF as an
attached JSON file with Markdown strings. This data can then be read by tools that process the PDF.

#note[
  _Note._ Typst syntax is converted to Markdown and math is converted to LaTeX when embedded into
  the PDF. This is primarily applicable to embedded rubric data.
]

== Embedding metadata in the PDF

The global `config`'s #api("config", field: "embed-metadata") option can be used to attach data to
the PDF as JSON files.

```typ
#show: exam.with(embed-metadata: true)
```

/ `embed-metadata: false`: (default) Nothing is attached.
/ `embed-metadata: "rubric"`: The rubrics are attached as `examy-rubric.json`.
/ `embed-metadata: "question-regions"`: Where each question is on the page is attached as
  `examy-regions.json`.
/ `embed-metadata: true`: Both are attached.
/ `embed-metadata: auto`: Question regions are always attached and rubric information is only
  attached when solutions are shown.

As with solutions, a command-line setting can be used to override the exam's settings. Its value is
written without quotes.

```bash
# the answer key, with its rubrics attached, for a grading tool
typst compile --input show-solutions=true --input embed-metadata=true exam.typ
```

Attaching data does not change the layout of the exam. If a document holds several exams, the second
exam's files are named `examy-rubric-2.json` and `examy-regions-2.json`, and so on.

#warning[
  _Warning._ If `"rubric"` data is embedded in an exam, it can be read even when
  `show-solutions: false` is set. This means that if a student has access to a version of the exam
  without solutions but with the rubric metadata, they might have access to information that you
  didn't want to share. Use `embed-metadata: auto` to attach the rubrics only when solutions are
  shown.
]

== Rubric data

Rubric data for an exam can be embedded regardless of whether rubrics are shown. Alternatively,
rubric data can be accessed directly via the command line or displayed in a document with a query
command.

```bash
typst eval --in exam.typ --pretty 'query(<examy-rubric>).first().value' > examy-rubric.json
```

#example(
  ```typ
  #show: exam.with(exam-name: "Example Exam")
  #set text(size: 0.8em)

  #question(points: 2, rubric: [
    #rubric(points: 1)[Uses $A = pi r^2$]
    #rubric(points: 1)[Gets $9 pi$]
  ])[What is the area of a circle of radius 3?]
  #question(points: 3, rubric: [
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

Using `.first().value` retrieves the rubric from the first exam in the document (if your document
only has one exam, then the first exam will be your exam), and `.at(1).value`, `.at(2).value`, etc.
can be used to retrieve rubrics from other exams.

A TypeScript schema for the embedded `examy-rubric.json` is shown below. Questions with no points
value will be given a `null` value for the `points` field.

#schema("examy-rubric.ts")

== Question regions

Data about the region that each question occupies can be embedded in the PDF as `examy-regions.json`
or retrieved from the command line via a Typst query command.

```bash
typst eval --in exam.typ --pretty 'query(<examy-regions>).first().value' > examy-regions.json
```

All positions are in points from the top left of the page (rounded to one decimal place). Question
regions overlap the regions of their parts, and the regions for #api("answer-box", arg: "[..]")s
contained in a question/part/subpart are included in an `answer-boxes` array.

If any #api("name-block") lines are present, their regions are included in `name-block-regions`.

#example(
  ```typ
  #show: exam.with(exam-name: "Example Exam", embed-metadata: true)
  #set text(size: 0.8em)

  #name-block()

  #question(points: 2, rubric: [
    #rubric(points: 1)[Uses $A = pi r^2$]
    #rubric(points: 1)[Gets $9 pi$]
  ])[What is the area of a circle of radius 3?]
  #question(points: 3, rubric: [
    #rubric(points: 1)[Simplifies]
    #rubric(points: -1, annotation: [once only])[Sign error]
  ])[
    Differentiate $sin(x^2)$.
    #answer-box(width: 100%, height: 1cm)[]
  ]

  *Regions as JSON*
  #context {
    // Get the regions data as JSON
    let data = query(<examy-regions>).first().value
    // Two columns: the first is filled to this height, then the second
    block(height: 17.5cm, columns(2, raw(json.encode(data), lang: "json", block: true)))
  }
  ```,
  // Shown as an image of a paged rendering (`paged-name`), as the regions
  // need to know where things are on the page; on a page of a fixed size,
  // which the regions give in `pages`, as tall as what it shows.
  paged-name: "metadata-regions",
  page-size: (width: 12cm, height: 22.5cm),
  // Not run in the PDF, where the regions would be of the manual's page,
  // which they would move the example about on, so that it never settled.
  pdf-output: false,
)

A TypeScript schema for the embedded `examy-regions.json` is shown below. `Question` is the same as
in the rubric data.

#schema("examy-regions.ts")

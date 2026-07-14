#import "../types.typ": *
#import "../tokenize.typ": tokenize
#import "../parse.typ": parse
#import "../plan.typ": plan
#import "../render.typ": render
#import "../points.typ": compute_points_data, points_data_state
#import "./solution.typ": show_solutions

/// The default rows for a name block.
#let DEFAULT_NAME_FIELDS = ((prefix: [Name:]), (prefix: [Student ID:]))

/// Render one entry of `name_fields` as grid cells. A dictionary entry
/// `(prefix: ..., suffix: ...)` (both optional) becomes a fill-in row:
/// the prefix, then an underline extending to the end of the line, with the
/// suffix sitting on the line at its right end. Any other entry is content
/// rendered verbatim, spanning the full block width.
#let _name_field_row(entry) = {
  if type(entry) != dictionary {
    return (grid.cell(colspan: 2, entry),)
  }
  let prefix = entry.at("prefix", default: none)
  let suffix = entry.at("suffix", default: none)
  (
    align(right + bottom, box(inset: (bottom: .35em), prefix)),
    align(bottom, box(
      width: 100%,
      stroke: (bottom: 1pt),
      inset: (bottom: .35em, x: .2em),
      {
        h(1fr)
        // An invisible character keeps empty lines the same height as ones
        // with a suffix.
        if suffix == none { hide[X] } else { suffix }
      },
    )),
  )
}

/// A block of fill-in rows (name, ID, ...) for the cover page.
#let name_row(title, fields) = {
  {
    set align(center)
    set text(size: .9em)
    if title != none and title != "" {
      title
    }
    v(-.7em)
  }

  grid(
    columns: (auto, 1fr),
    row-gutter: 1em,
    column-gutter: .3em,
    ..fields.map(_name_field_row).flatten()
  )
}

/// Run the questions content through the full pipeline:
/// tokenize → parse → plan → render (+ record point totals).
#let process_questions(questions) = {
  let items = parse(tokenize(questions))
  points_data_state.update(compute_points_data(items))
  render(items, plan(items))
}

/// Start an exam or homework list.
#let exam = e.element.declare(
  "exam",
  prefix: PREFIX,
  doc: "Declare an exam",
  display: it => {
    if it.name_list.len() > 0 {
      set text(font: "DejaVu Sans Mono")
      [#(
        {
          let name_fields = if it.name_fields == none { DEFAULT_NAME_FIELDS } else { it.name_fields }
          it
            .name_list
            .map(
              name_header => name_row(name_header, name_fields),
            )
            .join(v(.7em))
        }
      )]
    }
    // Cover page. Only show if there are some cover items specified.
    if (
      not (it.institution, it.exam_name, it.term, it.duration, it.exam_instructions).all(t => (
        t == none
      ))
    ) {
      set text(font: "DejaVu Sans Mono")
      grid(
        columns: (1fr, 1fr),
        row-gutter: 1em,
        // Exam info
        {
          set align(center)
          it.institution
        },
        {
          set align(center)
          it.term
          if it.duration != none {
            [\ ]
            text(size: .9em)[#it.duration.minutes() Minutes]
          }
        },

        {
          set align(center)
          text(weight: "bold", size: 1.2em)[#it.exam_name]
        },
      )

      set text(font: "Libertinus Serif")
      it.exam_instructions
      pagebreak()
    }

    // If `questions` is a function, call it with a `solutions_only` helper
    // that shows its argument only when solutions are enabled.
    if type(it.questions) == function {
      e.get(get => {
        let solutions_only(content, otherwise: none) = {
          if show_solutions(get) == true {
            content
          } else {
            otherwise
          }
        }
        process_questions((it.questions)(solutions_only))
      })
    } else {
      process_questions(it.questions)
    }
  },
  fields: (
    e.field(
      "name_list",
      e.types.array(content),
      doc: "The number of places to write a name on the cover of the exam",
    ),
    e.field(
      "name_fields",
      // An option (rather than an array with a default) because elembic
      // folds array fields by concatenating onto the default.
      e.types.option(e.types.array(e.types.union(content, dictionary))),
      doc: "The rows of each name block (default: a Name row and a Student ID row). A dictionary entry `(prefix: ..., suffix: ...)` (both optional) renders as a fill-in row: the prefix, an underline to the end of the line, and the suffix sitting on the line at its right end. A content entry is rendered verbatim as its own row.",
    ),
    e.field("institution", e.types.option(content), doc: "The institution name"),
    e.field("exam_name", e.types.option(content), doc: "The name of the exam"),
    e.field(
      "term",
      e.types.option(content),
      doc: "The term of the exam (e.g. Fall 2025)",
    ),
    e.field("duration", e.types.option(duration), doc: "The length of the exam"),
    e.field(
      "exam_instructions",
      e.types.option(content),
      doc: "Instructions for the exam that show up on the cover page",
    ),
    e.field(
      "questions",
      e.types.union(content, function),
      doc: "The questions in the exam or a function that accepts a `solutions_only` function and returns the exam questions",
      required: true,
      named: true,
    ),
  ),
)

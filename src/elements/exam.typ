#import "../types.typ": *
#import "../tokenize.typ": tokenize
#import "../parse.typ": parse
#import "../plan.typ": plan
#import "../render.typ": render
#import "../points.typ": compute_points_data, points_data_state
#import "../config.typ": config
#import "./solution.typ": show_solutions

/// The exam title block (in the spirit of LaTeX's `\maketitle`): the
/// institution, term, duration, and exam name, laid out as the head of a
/// cover page. Each value is taken from `config` unless overridden here
/// (pass `none` to suppress a configured value). Renders nothing if no
/// value is set at all.
///
/// ```typst
/// #show: e.set_(config, institution: [...], exam-name: [...],
///   term: [...], duration: duration(minutes: 110))
/// #maketitle()
/// // or, overriding the configured term:
/// #maketitle(term: [Summer 2026])
/// ```
#let maketitle(
  institution: auto,
  exam-name: auto,
  term: auto,
  duration: auto,
) = e.get(get => {
  let c = get(config)
  let institution = if institution == auto { c.institution } else { institution }
  let exam_name = if exam-name == auto { c.at("exam-name") } else { exam-name }
  let term = if term == auto { c.term } else { term }
  let duration = if duration == auto { c.duration } else { duration }
  if (institution, exam_name, term, duration).all(t => t == none) {
    return none
  }
  set text(font: "DejaVu Sans Mono")
  grid(
    columns: (1fr, 1fr),
    row-gutter: 1em,
    {
      set align(center)
      institution
    },
    {
      set align(center)
      term
      if duration != none {
        [\ ]
        text(size: .9em)[#duration.minutes() Minutes]
      }
    },

    {
      set align(center)
      text(weight: "bold", size: 1.2em)[#exam_name]
    },
  )
})

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

/// A block of fill-in rows (name, student ID, ...) for an exam cover or
/// quiz header. Place it on a cover page, at the top of a quiz, or anywhere
/// else in the document.
///
/// `fields` entries are either a `(prefix: ..., suffix: ...)` dictionary
/// (both keys optional), rendered as the prefix, an underline extending to
/// the end of the line, and the suffix sitting on the line at its right
/// end — or arbitrary content, rendered verbatim as its own row.
#let name_block(title: none, fields: DEFAULT_NAME_FIELDS) = {
  set text(font: "DejaVu Sans Mono")
  if title != none and title != "" {
    set align(center)
    set text(size: .9em)
    title
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
      "questions",
      e.types.union(content, function),
      doc: "The questions in the exam or a function that accepts a `solutions_only` function and returns the exam questions",
      required: true,
      named: true,
    ),
  ),
)

#import "../types.typ": *
#import "../tokenize.typ": tokenize
#import "../parse.typ": parse
#import "../plan.typ": plan
#import "../render.typ": render
#import "../points.typ": compute_points_data, points_data_state
#import "./solution.typ": show_solutions

/// A labeled fill-in row (name/email/UTORid) for the cover page.
#let name_row(title) = {
  {
    set align(center)
    set text(size: .9em)
    if title != none and title != "" {
      title
    }
    v(-.7em)
  }

  show: pad.with(left: -.2cm)
  grid(
    columns: (auto, 1fr),
    row-gutter: 1.5em,
    column-gutter: .3em,
    {
      box({
        set align(right)
        stack(
          spacing: .5em,
          text(size: .85em)[(Given then Family)],
          [NAME:],
        )
      })
    },
    {
      align(bottom, box(width: 1fr, stroke: (bottom: 1pt)))
    },

    align(right, [Email address:]),
    box(
      width: 1fr,
      stroke: (bottom: 1pt),
      inset: (bottom: .4em),
    )[#h(1fr) `@mail.utoronto.ca`],

    align(right, [UTORid:]), box(width: 1fr, height: 1em, stroke: (bottom: 1pt)),
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
        it
          .name_list
          .map(
            name_header => name_row(name_header),
          )
          .join(v(.7em))
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

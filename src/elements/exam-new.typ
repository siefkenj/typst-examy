#import "../types.typ": *
#import "./division.typ": (
  _division, divisions_to_array, generate_points_data, merge_duplicate_divisions,
  postprocess_divisions, render_division_meta,
)

#let points_data_state = state("points_data", ())

/// Construct a scoring table showing the point value for each question.
#let points_table = {
  context {
    let points_data = points_data_state.final()
    let q = points_data.map(x => {
      (
        label: if type(x.number) == int { [#(x.number + 1)] } else { [#x.number] },
        points: x.points,
      )
    })
    let num_points = points_data.map(x => x.points).sum()

    table(
      align: (right, ..(center,) * (q.len() + 1)),
      columns: q.len() + 2,
      stroke: .2pt,
      inset: .6em,
      [Question: ],
      ..q.map(x => x.label),
      [Total],
      [Points:],
      ..q.map(x => [#x.points]),
      [#num_points],
    )
  }
}

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
    //rows: 1.5em,
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

    // If it.questions is a function, call it and pass it an argument of `solution_only(...)`, a function that shows things only if solutions are enabled.
    let questions = if type(it.questions) == function {
      e.get(get => {
        let show-solutions = get(hw.config).show-solutions
        let show-solutions = if hw.SHOW_SOLUTIONS_OVERRIDE != none {
          hw.SHOW_SOLUTIONS_OVERRIDE
        } else {
          show-solutions
        }
        let solutions_only(content, otherwise: none) = {
          if show-solutions {
            content
          } else {
            otherwise
          }
        }
        (it.questions)(solutions_only)
      })
    } else {
      it.questions
    }

    // Do some checks. If questions is not a `_division` already, wrap it. Then process divisions.
    questions = if e.func-name(questions) == "_division" {
      questions
    } else {
      _division(indent: 0pt, questions)
    }
    let processed = postprocess_divisions(merge_duplicate_divisions(divisions_to_array(questions)))
    let points_data = generate_points_data(processed)
    points_data_state.update(points_data)
    processed.map(render_division_meta).join([])
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

#{
  import "division.typ": _division
  show: e.prepare()
  [hi there! fdsf]

  [\
    #points_table
  ]

  exam(
    name_list: (none,),
    questions: [
      Here are the questions

      #_division[foo]

      more text

      #_division(label: <bar>, points: 3)[bar
        #_division[baz#_division[bang and @bar]]
      ]
      #_division(label: <bar2>, number: "XX")[bar
        #_division[baz#_division(points: 4)[bang and @bar]]
      ]
    ],
  )
}

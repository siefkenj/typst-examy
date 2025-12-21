#import "../types.typ": *

#let exam = e.element.declare(
  "exam",
  prefix: "mat244_exam",
  doc: "Declare an exam",
  display: it => {
    // Cover page. Only show if there are some cover items specified.
    if (
      not (it.institution, it.exam_name, it.term, it.duration, it.exam_instructions).all(t => (
        t == none
      ))
        or it.name_list.len() > 0
    ) {
      set text(font: "DejaVu Sans Mono")
      [#(
        it
          .name_list
          .map(
            name_header => name_row(name_header),
          )
          .join(v(.7em))
      )]

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

    it.questions
    // // If it.questions is a function, call it and pass it an argument of `solution_only(...)`, a function that shows things only if solutions are enabled.
    // if type(it.questions) == function {
    //   e.get(get => {
    //     let show-solutions = get(hw.config).show-solutions
    //     let show-solutions = if hw.SHOW_SOLUTIONS_OVERRIDE != none {
    //       hw.SHOW_SOLUTIONS_OVERRIDE
    //     } else {
    //       show-solutions
    //     }
    //     let solutions_only(content, otherwise: none) = {
    //       if show-solutions {
    //         content
    //       } else {
    //         otherwise
    //       }
    //     }
    //     (it.questions)(solutions_only)
    //   })
    // } else {
    //   it.questions
    // }
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
  show: e.prepare()
  [hi there!]

  exam(
    institution: [University of Toronto Faculty of Arts & Science],
    exam_name: [Midterm Exam],
    term: [Fall 2025],
    duration: duration(minutes: 120),
    exam_instructions: [Please complete all questions.],
    questions: [
      Here are the questions
    ],
  )
}

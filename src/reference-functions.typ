#import "elements/questions.typ": *
#import "elements/utils.typ": augment_question_list

/// The total number of `questions`.
#let num_questions = {
  context {
    let q = query(<block-end>).at(-1, default: none)
    if q == none {
      return 0
    }
    let l = _GLOBALS.at(q.location()).all_questions
    l.filter(item => item.level == "question").len()
  }
}

/// The total number of non-bonus points.
#let num_points = {
  context {
    let q = query(<block-end>).at(-1, default: none)
    if q == none {
      return 0
    }
    let l = _GLOBALS.at(q.location()).all_questions
    l
      .map(item => if item.info.points != none and item.info.intent != "bonus" {
        item.info.points
      } else { 0 })
      .sum()
  }
}

/// Construct a scoring table showing the point value for each question.
#let points_table = {
  context {
    let q = query(<block-end>).at(-1, default: none)
    if q == none {
      return text(fill: red, "WARNING: No questions found! Can't make a points table.")
    }
    let l = _GLOBALS.at(q.location()).all_questions
    let l = augment_question_list(l)
    // Find all `question_end` items, read their ids, and look up the corresponding points
    let q = query(<question_end>)
    let labelling = LABELLING.at(0)
    if labelling.ends-with(".") {
      labelling = labelling.slice(0, labelling.len() - 1)
    }
    let q = q.map(v => (
      label: numbering(labelling, ..v.value.counter_value),
      id: v.value.id,
      points: (l.find(item => item.id == v.value.id)).total_points,
    ))

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



#{
  show: e.prepare()
  [hi there]

  [There are: #num_questions questions for a total of #num_points points.

    #points_table
  ]

  question(points: 1)[xxx

    #part(points: 2, label: <foo>)[xxx2]
    #part(points: 4)[xxx3
      #subpart(points: 1)[subpart1]
    ]

  ]
  question()[yyy]
  question(points: 3)[yyy

    Think about @foo.

    zzz]
}

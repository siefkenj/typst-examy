#import "../types.typ": *
#import "../question-common.typ": *
#import "./omni-box.typ": extract_height, find_content_with_heights, is_break
#import "./utils.typ": content_to_array, is_whitespace_content

#let labeled_number = e.element.declare(
  "labeled-number",
  prefix: PREFIX,
  doc: "An element to display a label and a number together.",
  display: it => {
    it.display_label
  },
  reference: (
    custom: it => {
      it.display_label
    },
  ),
  fields: (
    e.field("display_label", content, doc: "The label format"),
  ),
)

/// Render an instance of `_division_meta_type`.
#let render_division_meta(division_meta) = {
  // If the level is 0, we display the content without any wrapping. Level 0 things don't get labelled/numbered.
  // If the item is a break, we also display it without any wrapping.
  if division_meta.level == 0 or division_meta.is_break {
    return division_meta.body
  }
  // If we're a continuation consisting of only whitespace, we render nothing.
  if division_meta.continuation and is_whitespace_content(division_meta.body) {
    return none
  }

  // What to render for the points indicator
  let rendered_points = if not division_meta.continuation and division_meta.points != none {
    let point_word = if division_meta.points == 1 { "point" } else { "points" }
    [(#division_meta.points #point_word)#h(.5em)]
  } else {
    none
  }

  // If there is a child with a fraction height set, we want to inherit that height so that all fraction heights end up as "peers".
  let content_with_heights = find_content_with_heights(division_meta.body)
  let height = content_with_heights
    .map(child => extract_height(child))
    .filter(h => type(h) == fraction)
    .sum(default: auto)
  // If there is a break inside the content, we keep the height as auto, since setting an explicit height prevents page breaking.
  if content_with_heights.any(c => is_break(c)) {
    height = auto
  }
  if height == auto and is_whitespace_content(division_meta.body) {
    height = -.62em
  }

  let rendered_label = if division_meta.continuation or division_meta.number == none {
    none
  } else {
    let display_label = if type(division_meta.number) == int {
      let numbering_type = LABELLING.at(division_meta.level - 1, default: "1.")
      numbering(numbering_type, division_meta.number + 1)
    } else {
      [#division_meta.number]
    }
    labeled_number(display_label: display_label, label: division_meta.label)
  }

  block(
    inset: (left: division_meta.indent),
    height: height,
    {
      // Allow the use of `#pagebreak()` inside a question/part/subpart
      show pagebreak: it => colbreak(weak: it.weak)
      set enum(numbering: "(a)")
      place(dx: -1 * division_meta.indent, align(right, box(
        width: division_meta.indent - .5em,
        rendered_label,
      )))

      rendered_points
      division_meta.body
    },
  )
}


/// This function creates a renderer for the body of a question, part, or subpart.
#let render_factory(level) = {
  let item_label = (
    "question": LABELLING.at(0),
    "part": LABELLING.at(1),
    "subpart": LABELLING.at(2),
  ).at(level, default: "1.")

  division_meta => {
    // // Store a reference to the currently active question/part/subpart in globals
    // _GLOBALS.update(g => {
    //   // // Insert a reference to the current question.
    //   // g.insert(level, it)
    //   let id = g.num_divisions
    //   g.num_divisions += 1
    //   g.all_questions.push((
    //     level: level,
    //     id: id,
    //     children: (),
    //     info: (
    //       points: it.points,
    //       intent: it.intent,
    //     ),
    //   ))
    //   g.insert("active_" + level, id)
    //   g
    // })
    // let rendered_label = {
    //   e.counter(it).display(item_label)
    // }


    // // Mark the start of this question/part/subpart
    // [#metadata("block-start")#label(level + "_start")]
    let rendered_points = if division_meta.points != none {
      // Update the total points state
      // _total_points_state.update(p => p + it.points)

      let point_word = if division_meta.points == 1 { "point" } else { "points" }
      [(#division_meta.points #point_word)#h(.5em)]
    } else {
      []
    }

    // If there is a child with a fraction height set, we want to inherit that height so that all fraction heights end up as "peers".
    let content_with_heights = find_content_with_heights(division_meta.body)
    let height = content_with_heights
      .map(child => extract_height(child))
      .filter(h => type(h) == fraction)
      .sum(default: auto)
    // If there is a break inside the content, we keep the height as auto, since setting an explicit height prevents page breaking.
    if content_with_heights.any(c => is_break(c)) {
      height = auto
    }

    block(
      inset: (left: division_meta.indent),
      height: height,
      {
        // Allow the use of `#pagebreak()` inside a question/part/subpart
        show pagebreak: it => colbreak(weak: it.weak)
        set enum(numbering: "(a)")
        place(dx: -1 * division_meta.indent, align(right, box(
          width: division_meta.indent - .5em,
          rendered_label,
        )))

        rendered_points
        division_meta.body
      },
    )
  }
}

#{
  let question = _division
  let part = _division
  show: e.prepare()
  [hi there]

  postprocess_divisions(divisions_to_array(_division[
    #question()[
      #part(points: 2, label: <foo>)[xxx2]
      #part(points: 4)[xxx3]
    ]

    #v(1fr)
    #question()[yyy] #question(points: 3)[yyy Think about this Think about @foo.

      #v(1fr)
      zzz
    ]
  ]))
    .map(render_division_meta)
    .join([])
}

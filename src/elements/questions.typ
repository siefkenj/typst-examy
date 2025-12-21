#import "../types.typ": *
#import "../question-common.typ": *
#import "./omni-box.typ": extract_height, find_content_with_heights, is_break
#import "./utils.typ": content_to_array


// #{
//   [foo]
//   repr(_division_meta_type(
//     level: 1,
//     [bar],
//   ))
// }

/// General purpose division constructor. This will split `body` into chunks based on content and nested divisions.
#let _division(body, ..args) = {
  assert(type(body) == content, message: "`body` must be of type `content`")
  // Look at the array of body elements:
  // 1. Any sub-divisions get their level incremented by 1
  // 2. The first chunk gets wrapped in a division that will be numbered,
  // 3. Subsequent chunks get wrapped in divisions that are continuations.
  // 4. Any `pagebreak` or `colbreak` elements cause a split in the division.
  let chunks = content_to_array(body)
  chunks
    .map(c => {
      if e.func-name(c) == "_division" {
        "there is a sub-division"
      } else {
        _division_meta_type(c)
      }
    })
    .join()
  // let children = body.at("children")
  // _division_meta_type([fun])
  // #str(repr(chunks))
  // metadata((
  // "there are",
  // chunks,
  // // children.len(),
  // "children",
  // ))
  // metadata(_division_meta_type([xx]))
  // e.types.
}

#{
  show: repr
  _division([hi there#_division([xxx
      #_division(solution: [foo])[yyy]
    ])])
}

/// Reset the counters for every possible child of `level`.
#let reset_counters(level) = context {
  let counters_to_reset = ALLOWED_CHILDREN.at(level, default: ())
  let globals = _GLOBALS.get()
  for needs_reset in counters_to_reset {
    let item = globals.at(needs_reset, default: none)
    if item != none {
      e.counter(item).update(0)
    }
  }
}

/// This function creates a renderer for the body of a question, part, or subpart.
#let render_factory(level) = {
  let item_label = (
    "question": LABELLING.at(0),
    "part": LABELLING.at(1),
    "subpart": LABELLING.at(2),
  ).at(level, default: "1.")

  it => {
    // Store a reference to the currently active question/part/subpart in globals
    _GLOBALS.update(g => {
      // // Insert a reference to the current question.
      // g.insert(level, it)
      let id = g.num_divisions
      g.num_divisions += 1
      g.all_questions.push((
        level: level,
        id: id,
        children: (),
        info: (
          points: it.points,
          intent: it.intent,
        ),
      ))
      g.insert("active_" + level, id)
      g
    })
    let rendered_label = {
      e.counter(it).display(item_label)
    }

    // Mark the start of this question/part/subpart
    [#metadata("block-start")#label(level + "_start")]
    let rendered_points = if it.points != none {
      // Update the total points state
      // _total_points_state.update(p => p + it.points)

      let point_word = if it.points == 1 { "point" } else { "points" }
      [(#it.points #point_word)#h(.5em)]
    } else {
      []
    }

    // If there is a child with a fraction height set, we want to inherit that height so that all fraction heights end up as "peers".
    let content_with_heights = find_content_with_heights(it.body)
    let height = content_with_heights
      .map(child => extract_height(child))
      .filter(h => type(h) == fraction)
      .sum(default: auto)
    // If there is a break inside the content, we keep the height as auto, since setting an explicit height prevents page breaking.
    if content_with_heights.any(c => is_break(c)) {
      height = auto
    }

    block(
      inset: (left: it.indent),
      height: height,
      {
        // Allow the use of `#pagebreak()` inside a question/part/subpart
        show pagebreak: it => colbreak(weak: it.weak)
        set enum(numbering: "(a)")
        place(dx: -1 * it.indent, align(right, box(width: it.indent - .5em, rendered_label)))

        reset_counters(level)
        rendered_points
        it.body
      },
    )
    context [#metadata((
        type: "block-end",
        // cumulative_points: _total_points_state.get(),
        counter_value: e.counter(it).get(),
        id: _GLOBALS.get().at("active_" + level),
      ))#label(
        level + "_end",
      )
      #metadata("block-end")
      #label("block-end")]
  }
}

/// Write a `question`.
#let question = e.element.declare(
  "question",
  prefix: PREFIX,
  doc: "Declare a question for the homework assignment",
  display: render_factory("question"),
  reference: (
    supplement: [Question],
    numbering: LABELLING.at(0),
  ),
  fields: _COMMON_FIELDS,
)

/// Write a `part` of a question for the homework assignment.
#let part = e.element.declare(
  "part",
  prefix: PREFIX,
  doc: "Declare a part of a question for the homework assignment",
  display: render_factory("part"),
  reference: (
    custom: part => {
      e.counter(question).display(LABELLING.at(0))
      [ ]
      e.counter(part).display(LABELLING.at(1))
    },
  ),
  fields: _COMMON_FIELDS,
)

#let subpart = e.element.declare(
  "subpart",
  prefix: PREFIX,
  doc: "Declare a subpart of a part of a question for the homework assignment",
  display: render_factory("subpart"),
  reference: (
    custom: subpart => {
      e.counter(question).display(LABELLING.at(0))
      [ ]
      e.counter(part).display(LABELLING.at(1))
      [ ]
      e.counter(subpart).display(LABELLING.at(2))
    },
  ),
  fields: _COMMON_FIELDS,
)

#{
  show: e.prepare()
  [hi there]

  question(points: 1)[xxx

    #part(points: 2, label: <foo>)[xxx2]
    #part(points: 4)[xxx3]

  ]
  question()[yyy]
  question(points: 3)[yyy

    Think about @foo.

    #pagebreak()

    zzz]

  context {
    _GLOBALS.get()
  }
}

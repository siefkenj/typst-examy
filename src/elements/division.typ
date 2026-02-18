#import "../types.typ": *
#import "../question-common.typ": *
#import "./omni-box.typ": extract_height, find_content_with_heights, is_break
#import "./utils.typ": content_to_array, is_whitespace_content

/// Converts a full address `(self_number, parent_number, grandparent_number, ...)` into a display label.
#let full_address_to_label(full_address) = {
  full_address
    .rev()
    .enumerate()
    .map(((level, n)) => {
      let display_label = if type(n) == int {
        let numbering_type = LABELLING.at(level, default: "1.")
        numbering(numbering_type, n + 1)
      } else {
        [#n]
      }
      // If the display label ends with a `.`, remove it so we get "1 (a)" instead of "1. (a)".
      if type(display_label) == str and display_label.ends-with(".") {
        display_label = display_label.slice(0, -1)
      }
      display_label
    })
}



#let labeled_number = e.element.declare(
  "labeled-number",
  prefix: PREFIX,
  doc: "An element to display a label and a number together.",
  display: it => {
    it.display_label
    // Store a reference to the currently active question/part/subpart in globals
    // This is used for computing references later on.
    _GLOBALS.update(g => {
      g.insert("current_address", it.full_address)
      g
    })
  },
  reference: (
    custom: it => {
      // If we are locally referencing a part, we only show the local address. If we are referencing a part of one question from another,
      // we need to show more of the address. E.g.,
      // 1. (a) <foo>
      //    (b) @foo    -> shows "(a)"
      // 2. (a) @foo    -> shows "1 (a)"
      let global_label = full_address_to_label(it.full_address)
      context {
        let current_address = full_address_to_label(_GLOBALS
          .get()
          .at("current_address", default: (-1) * global_label.len()))
        let local_label = current_address.zip(global_label).rev()
        while local_label.len() > 0 and local_label.at(-1).at(0) == local_label.at(-1).at(1) {
          let _ = local_label.pop()
        }
        local_label = local_label.rev().map(pair => pair.at(1))
        // If we are labelling ourselves, `local_label` will now be empty. We never want to show an empty label, so we display a minimal local label.
        if local_label.len() == 0 {
          local_label = (global_label.at(-1),)
        }

        link(it.label_name, local_label.join(sym.space.thin))
      }
    },
  ),
  fields: (
    e.field("display_label", content, doc: "The label format"),
    e.field(
      "label_name",
      e.types.option(label),
      doc: "The label name again, so that we can query for its location",
    ),
    e.field(
      "full_address",
      e.types.array(NUMBER_TYPE),
      doc: "The full address of the item as an array `(self_number, parent_number, grandparent_number, ...)`. Numbering starts at 0.",
    ),
  ),
)

/// Render an instance of `_division_meta_type`.
#let render_division_meta(division_meta) = {
  // Debug info gets printed straight away
  if division_meta._DEBUG != none {
    text(fill: red, `DEBUG: `)
    repr(division_meta._DEBUG)
  }
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
    labeled_number(
      display_label: display_label,
      label_name: division_meta.label,
      label: division_meta.label,
      full_address: (division_meta.number, ..division_meta.ancestor_numbering),
    )
  }

  block(
    inset: (left: division_meta.indent),
    height: height,
    {
      // Allow the use of `#pagebreak()` inside a question/part/subpart
      show pagebreak: it => colbreak(weak: it.weak)
      set enum(numbering: LABELLING.at(division_meta.level, default: "(a)"))
      place(dx: -1 * division_meta.indent, align(right, box(
        width: division_meta.indent - .5em,
        rendered_label,
      )))

      rendered_points
      division_meta.body
    },
  )
}

#{
  // TESTING THE RENDERING OF DIVISIONS
  let question = _division
  let part = _division
  show: e.prepare()
  [hi there]

  postprocess_divisions(divisions_to_array(_division[
    #question()[
      #part(points: 2, label: <foo>)[xxx2
        + hi
        + there "@foo" "@bar"
      ]
      #part(points: 4, label: <bar>)[xxx3]

      + hi
      + there
    ]

    #v(1fr)
    #question()[yyy] #question(points: 3)[yyy Think about this Think about "@foo[xx]" #pagebreak()
      and
      #part[the item @bar.]

      #v(1fr)
      zzz
    ]
  ]))
    .map(render_division_meta)
    .join([])
}

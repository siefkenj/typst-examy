#import "../types.typ": *

#let generalized_size = e.types.union(length, fraction, ratio, relative, auto)
// #let box_info_type = e.types.declare(
//   "box-info",
//   prefix: PREFIX,
//   doc: "Information about a box's sizing",
//   fields: (
//     e.field("is_block", bool, doc: "Whether the box is a block element"),
//     e.field(
//       "width",
//       e.types.union(length, fraction, ratio, relative, auto),
//       doc: "The width of the box",
//       default: auto,
//     ),
//     e.field(
//       "height",
//       e.types.union(length, fraction, ratio, relative, auto),
//       doc: "The height of the box",
//       default: auto,
//     ),
//   ),
//   casts: (
//     (
//       from: (dictionary),
//     ),
//     // (
//     //   from: (generalized_size, generalized_size),
//     //   with: self => ((width, height)) => {
//     //     self(
//     //       is_block: type(height) == fraction,
//     //       width: width,
//     //       height: height,
//     //     )
//     //   },
//     // ),
//   ),
// )

/// Extract the height of elements who have their height explicitly set.
#let extract_height(it) = {
  let e_data = e.data(it)
  // Extract the height from known elements that can have their heights specified
  if e_data.data-kind == "content" {
    return if e_data.func == v {
      e_data.fields.at("amount", default: none)
    } else if e_data.func == box or e_data.func == block {
      e_data.fields.at("height", default: none)
    } else if e_data.func == image {
      e_data.fields.at("height", default: none)
    } else {
      none
    }
  } else if e_data.data-kind == "element-instance" {
    if ("omni-box", "answer-box").contains(e_data.name) {
      return e_data.fields.at("height", default: none)
    }
  }
  none
}

#let is_break(it) = {
  it == pagebreak() or it == colbreak()
}

/// Determine if an element contains a break (pagebreak, colbreak, etc.) as an immediate child.
#let has_break(it) = {
  if type(it) == content {
    if it.has("children") {
      return it.at("children").any(child => is_break(child))
    }
  }
  false
}

/// Determine if an element contains a break (pagebreak, colbreak, etc.). This searches recursively into children,
/// but ignores children if the container has an explicit height set.
#let has_break_recursive(it) = {
  find_content_with_heights(it).any(child => is_break(child))
}

/// Get a list of all children that may have a height set. If an element has an explicit child set, its children are not searched.
/// If it contains a `colbreak` or `pagebreak` as an immediate child, that break is also included.
#let find_content_with_heights(it) = {
  if type(it) == array {
    return it.map(child => find_content_with_heights(child)).flatten()
  }
  if is_break(it) {
    return (it,)
  }
  // If the height is explicitly set, we don't need to search children
  if extract_height(it) != none {
    return (it,)
  }

  let e_data = e.data(it)
  if e_data.data-kind == "element-instance" {
    return if (
      e_data.name == "omni-box" or HIERARCHY.contains(e_data.name)
    ) {
      find_content_with_heights(e_data.fields.at("body", default: ()))
    } else {
      ()
    }
  }

  // Recurse into regular content
  if type(it) == content {
    if type(it) == metadata {
      (it,)
    } else if it.has("text") {
      (it.at("text"),)
    } else if it.has("children") {
      find_content_with_heights(it.at("children"))
    } else if it.has("body") {
      find_content_with_heights(it.at("body"))
    } else {
      ()
    }
  } else {
    ()
  }
}

// #let get_box_info(width, height) = {
//   let is_block = type(height) == fraction
//   let box_height = if is_block { 100% } else if height == none { auto } else { height }

//   let box_width = if is_block and width == auto {
//     // The default width for block elements is 100%
//     100%
//   } else {
//     width
//   }
//   if box_width == none {
//     box_width = auto
//   }
//   (is_block: is_block, width: width, height: height)
// }

/// An omni-box is a box whose size can be given in fractions or other units. It can be nested, and
/// any fraction units from children will be propagated up to the parent.
#let omni-box = e.element.declare(
  "omni-box",
  prefix: PREFIX,
  doc: "Box that can be nested and whose size is affected by its children.",
  display: it => {
    let height = it.height
    if height == none {
      // If we didn't specify a height, check the children for any fraction heights. If so, add them up and use the result as our height.
      let child_heights = find_content_with_heights(it.body).map(extract_height)
      let total_fraction = child_heights.filter(h => type(h) == fraction).sum(default: none)
      if total_fraction != none {
        height = total_fraction
      }
    }
    let is_block = type(height) == fraction

    // The height of a box cannot be a fraction, so we change it to 100% if it is
    let box_height = if is_block { 100% } else if height == none { auto } else { height }

    let width = if is_block and it.width == auto {
      // The default width for block elements is 100%
      100%
    } else {
      it.width
    }
    if width == none {
      width = auto
    }

    // If we contain a colbreak or pagebreak, we keep our height at auto to allow the breaking algorithm to work.
    if has_break(it.body) {
      height = auto
    }

    // If our height is given as a fraction, we must be a block element
    show: it_ => {
      if is_block {
        block(
          width: width,
          height: height,
          it_,
        )
      } else {
        it_
      }
    }
    show: _it => {
      if has_break(it.body) {
        _it
      } else {
        box(
          stroke: .5pt,
          width: width,
          height: box_height,
          // This only matters if we are inline, so it is okay to always set this.
          baseline: 50% - .3em,
          // inset: 5pt,
          _it,
        )
      }
    }

    // [#(type(it.body) == content)]
    // repr(it.body.fields())
    // repr(box_height)
    // repr(height)
    it.body
  },
  fields: (
    e.field(
      "body",
      content,
      doc: "Content that should be placed inside the box",
      required: false,
      named: false,
    ),
    e.field(
      "width",
      e.types.option(e.types.union(length, fraction, ratio, relative, auto)),
      doc: "The width of the box",
    ),
    e.field(
      "height",
      e.types.option(e.types.union(length, fraction, ratio, relative, auto)),
      doc: "The height of the box. `fraction` heights (like `1fr`) will force the box to layout as a block. To have an inline box, use a non-fraction height (like `2em` or `3cm`)",
    ),
  ),
)

#{
  omni-box[hi there]

  omni-box(height: 2fr)[2fr]
  omni-box(height: 1fr)[1fr]

  pagebreak()
  omni-box()[
    This box has a frame that should size up.
    #omni-box(height: 2fr)[2fr]
    #omni-box(height: 2fr)[2fr]
    the
    #colbreak()
    break
    #omni-box(height: 1fr)[2fr]
  ]
  omni-box(height: 1fr)[
    1fr
  ]

  let cc = [#metadata("hi there,")]
  repr(cc)
  repr(cc.fields())
  let x = [hi there\ and stuff #omni-box()[2fr #omni-box(height: 2fr)[inside] #omni-box()[xx #v(
          1em,
        )]] #block([foo])]
  ["#find_content_with_heights(x).map(extract_height)"]


  // repr(x.fields())
  // [ID: "#e.data(omni-box(height: 1fr)[sdf and #omni-box(height: 2fr)[inside]])"]
  // [ID: "#e.data(box(height: 1em, [hi]))"]
  [ID: "#e.data(omni-box()[hi])"]
  repr([hi #[there ]])
  e.eid(omni-box)
}

#{
  // TESTS
  assert(extract_height(omni-box(height: 1fr)[content]) == 1fr)
  assert(extract_height(omni-box()[content]) == none)
  assert(extract_height(v(2fr)) == 2fr)
  assert(extract_height(box(height: 3cm)[content]) == 3cm)
  assert(extract_height(block(height: 4cm)) == 4cm)
  assert(is_break(pagebreak()) == true)
  assert(is_break(colbreak()) == true)
  assert(is_break([sample content]) == false)
  assert(has_break([sample content, #pagebreak()]) == true)
  assert(has_break([sample content, #colbreak()]) == true)
  assert(has_break([sample content, #text(fill: red, "foo")]) == false)
  assert(find_content_with_heights([sample content, #pagebreak()]).any(c => is_break(c)) == true)
  assert(find_content_with_heights([sample content, #colbreak()]).any(c => is_break(c)) == true)
  assert(find_content_with_heights([#omni-box()[#pagebreak()]]).any(c => is_break(c)) == true)
  assert(
    find_content_with_heights([A block with a break #block()[#colbreak()]]).any(c => is_break(c))
      == true,
  )
}

#pagebreak()

#{
  [xxx]
  repr(find_content_with_heights([hi there #pagebreak() #colbreak() #omni-box(height: 2fr)[inside]
    #block()[xx #colbreak()]]))
}

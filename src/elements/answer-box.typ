#import "../types.typ": *
#import "../config.typ": config
#import "./omni-box.typ": omni-box

#let answer-box = e.element.declare(
  "answer-box",
  prefix: PREFIX,
  doc: "Display a box where students can write answers",
  display: it => {
    let is_block = type(it.height) == fraction
    let height = it.height
    // The height of a box cannot be a fraction, so we change it to 100% if it is
    let box_height = if is_block { 100% } else if height == none { auto } else { height }
    if box_height == auto {
      box_height = it.default_height
    }

    let width = if is_block and it.width == auto {
      // The default width for block elements is 100%
      100%
    } else {
      it.width
    }
    if width == auto {
      width = it.default_width
    }

    // If our height is given as a fraction, we must be a block element
    show: it_ => {
      if is_block {
        block(
          width: width,
          height: height,
          it_,
        )
        // omni-box(
        //   width: width,
        //   height: height,
        //   {
        //     [#width #height]
        //     it_
        //   },
        // )
      } else {
        it_
      }
    }
    show: box.with(
      stroke: .5pt,
      width: width,
      height: box_height,
      // This only matters if we are inline, so it is okay to always set this.
      baseline: 50% - .3em,
      inset: 5pt,
    )

    it.body
    set block(spacing: 8pt)
    if it.solution != none {
      e.get(get => {
        show: it_ => {
          set text(fill: get(config).solution-text-color)
          show: pad.with(-3pt)
          block(
            width: 100%,
            height: 1fr,
            fill: get(config).solution-background-color,
            inset: 3pt,
            it_,
          )
        }
        it.solution
      })
    }
  },
  fields: (
    e.field(
      "body",
      content,
      doc: "Content that should be placed inside the box (this is not the answer)",
      required: false,
      named: false,
    ),
    e.field(
      "solution",
      e.types.option(content),
      doc: "A solution visible in the box when show-solutions is enabled",
    ),
    e.field(
      "width",
      e.types.union(length, fraction, ratio, relative, auto),
      default: auto,
      doc: "The width of the box",
    ),
    e.field(
      "height",
      e.types.option(e.types.union(length, fraction, ratio, relative, auto)),
      doc: "The height of the box. `fraction` heights (like `1fr`) will force the box to layout as a block. To have an inline box, use a non-fraction height (like `2em` or `3cm`)",
    ),
    e.field(
      "baseline",
      e.types.union(length, ratio, relative),
      default: 50% - .3em,
      doc: "The position of the baseline of the box relative to its height. This only matters if the box is inline",
    ),
    e.field(
      "default_height",
      length,
      default: 2em,
      doc: "The default height of the box if no height is specified",
    ),
    e.field(
      "default_width",
      length,
      default: 2cm,
      doc: "The default width of the box if no width is specified",
    ),
  ),
)













// Testing
#[
  #type(1fr) #type(100%) #type(100% + 2em) #type(3cm) #type(auto) An answer box can be
  inline#answer-box(solution: [ABC])[XX]in a paragraph.

  It can also go between

  #answer-box()

  paragraphs.

  #answer-box(height: 1fr, solution: [This is my solution])[
    Show yor work:
  ]

  paragraphs.

  #answer-box(height: 1fr)[
    This is a really great answer box: it#answer-box(height: 3cm)[#box(
      width: 100%,
      fill: blue,
      height: 100%,
    )] has another answer box inside! #answer-box()
  ]

  paragraphs.

  #pagebreak()

  hi there
  #block(
    [xxx

      #colbreak()

      yyy],
  )

  We are #answer-box(width: 1fr) and stuff #answer-box(width: 2fr)
]

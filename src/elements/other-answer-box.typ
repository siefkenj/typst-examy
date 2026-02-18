#import "../types.typ": *
#import "../config.typ": *

/// Display a box where students can write answers
#let other-answer-box(
  body,
  solution: none,
  width: auto,
  height: none,
  baseline: 50% - .3em,
  default_height: 2cm,
  default_width: 2cm,
) = {
  let it = (
    body: body,
    solution: solution,
    width: width,
    height: height,
    baseline: baseline,
    default_height: default_height,
    default_width: default_width,
  )

  // return block(stroke: 1pt + black, height: 1fr)[hi there]
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
}

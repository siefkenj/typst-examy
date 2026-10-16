#import "../prelude.typ": *
#import "../config.typ": solution_colors
#import "../widen.typ": exam_content, par_events, widen_par_solutions
#import "solution.typ": show_solutions, solution as solution_element

/// API documentation for this module's exports, consumed by
/// docs/generate-api.typ (keyed by export name). Kept next to the
/// signature — update both together.
#let DOCS = (
  "answer-box": (
    desc: "A box for students to write answers in.",
    args: (
    (
      name: "body",
      type: "content",
      required: true,
      doc: "Content shown inside the box (a prompt, `#solution[..]`, or nothing).",
    ),
    (
      name: "solution",
      type: "content | none",
      default: "none",
      doc: "Solution content shown at the bottom of the box when solutions are shown. In a box of set height it fills the space left below the body. With `height: auto`, the box grows to hold it. With no height given, it takes no height, like any solution in such a box (see `height`).",
    ),
    (
      name: "width",
      type: "auto | length | ratio | relative",
      default: "auto",
      doc: "The width of the box; `auto` falls back to `default_width`.",
    ),
    (
      name: "height",
      type: "auto | length | fraction | none",
      default: "none",
      doc: "`none` sizes the box by what the exam shows in it: a box with content — a prompt, a list of choices — grows to fit it, while a box that is blank on the exam (empty, or holding only solutions) takes `default_height`, leaving room to write. A solution counts as blank only when written directly in the box: one inside another element, such as `align` or `strong`, is content, so the box fits it. Its solutions take no height, so the answer key lays out exactly like the exam: a solution is drawn where it would be, over whatever follows it, or hanging out of the box when it comes last. Any explicit height opts out of that. `auto` fits the content, solutions included, so the key's box grows to hold them. A length gives a box of that size; give one to leave room to write below a prompt. A fraction (`1fr`) makes the box fill the space left on the page, shared proportionally with the other `fr` boxes there; it gets only what the rest of the page leaves over, which may be less than its content needs.",
    ),
    (
      name: "baseline",
      type: "length | ratio | relative",
      default: "50% - .33em",
      doc: "Baseline shift for small boxes sitting inline in a sentence; ignored for block-mode and full-width boxes. The default centers the box on the center line of a capital letter, the same line `bubble` is centered on, so a bubble and a box side by side line up.",
    ),
    (
      name: "default_height",
      type: "length",
      default: "2cm",
      doc: "The height of a box that is blank on the exam (empty, or holding only solutions written directly in it) when `height` is `none`.",
    ),
    (
      name: "default_width",
      type: "length",
      default: "2cm",
      doc: "The width used when `width` is `auto` (inline boxes only).",
    ),
    ),
  ),
)

/// The spacing between a box's body and the solution given as its `solution`
/// argument. The body keeps the spacing of the document around it.
#let _SPACING = 8pt

/// The box's own inset: the space between its outline and its content.
#let _INSET = 5pt

/// Display a box where students can write answers
#let answer_box(
  body,
  solution: none,
  width: auto,
  height: none,
  // `.33em` is half the cap height of a typical serif face: the box is
  // centered on the center line of a capital letter, which is what `bubble`
  // centers on too, so the two line up side by side. `bubble` measures that
  // line from the font instead of approximating it, but it can afford a
  // `context` to do so and this cannot — one here would make the box opaque
  // to the exam pipeline's content scans (see the note on block spacing
  // below). tests/unit/bubble.typ holds the two to within .01em of each
  // other.
  baseline: 50% - .33em,
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

  // Since Typst 0.15, the `show` chain below is applied eagerly, so the
  // resulting block/box (and its height) is directly visible to the exam
  // pipeline's content scans — no height hint needed (emitting one would
  // double-count the fr height).
  let is_block = type(it.height) == fraction
  let height = it.height
  // With no height given, solutions take no height, so the answer key lays
  // out exactly like the exam: the box is sized by what the exam shows, and
  // nothing after it moves. Any explicit height, even `auto`, opts out, and
  // the box holds its solutions as usual.
  let no_height = height == none
  // What the body holds, walked once for both the sizing below and the
  // widening of its solutions.
  let events = par_events(it.body, split: no_height)
  // The height of a box cannot be a fraction, so we change it to 100% if it
  // is. With no height given, a box with something in it — a prompt, a list
  // of choices — grows to fit it, while a blank one (empty, or holding only
  // its solutions) takes `default_height`, so the student has room to write.
  // A solution wrapped in another element (`align`, `strong`, ...) is opaque
  // to `par_events`, and so counts as content: the box fits it.
  // One holding only a `context` expression may be either until it is laid
  // out, and so takes `default_height` at the least: room to write when it
  // shows nothing on the exam, and room for whatever it does show.
  let shows = if height == none { exam_content(it.body, events: events) } else { none }
  let box_height = if is_block {
    100%
  } else if height == none {
    if shows == "no" { it.default_height } else { auto }
  } else {
    height
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

  // A centering baseline only makes sense for a small box sitting inline in
  // a sentence. For block-mode boxes and full-width boxes on their own line
  // there is none: since Typst 0.14/0.15 the line's ascent honors the
  // baseline shift literally, so `50% - .33em` on a tall box pushes it half
  // its height down the page.
  let is_standalone = is_block or type(width) in (ratio, relative)

  // If our height is given as a fraction, we must be a block element
  show: it_ => {
    if is_block {
      block(
        width: width,
        height: height,
        // Match the gap a fixed-height (inline) answer box gets from line
        // leading, instead of the much larger default block spacing —
        // otherwise `height: 1fr` boxes sit noticeably lower below their
        // question text than `height: 2in` ones. 0.65em is Typst's default
        // `par.leading`. (Not read via `context` because that would make the
        // box opaque to the exam pipeline's content scans.)
        above: 0.65em,
        it_,
      )
    } else {
      it_
    }
  }
  // The baseline shift goes on an *outer* wrapper rather than on the drawn
  // box itself: a box inherits the baseline of its contents' last line, so a
  // box holding anything at all (a prompt, a solution) would be positioned
  // by that line instead of by its own bottom edge, and the shift would then
  // drop the whole box below the surrounding text. A `stack` discards the
  // baseline of what it holds, so the wrapper's baseline is reliably its
  // bottom edge — which is what `50% - .33em` is measured from. Wrapping the
  // finished box (instead of its contents) also leaves the contents' own
  // region alone, so `place(bottom)` and `height: 1fr` inside still see the
  // full box. The wrapper repeats the box's height so that it still reads as
  // a sized box to the exam pipeline's scans (`starts_inline` keeps a gutter
  // label off the baseline of a tall box only when it can see its height).
  show: it_ => if is_standalone { it_ } else {
    box(height: box_height, baseline: it.baseline, stack(dir: ttb, it_))
  }
  show: box.with(
    stroke: .5pt,
    width: width,
    height: box_height,
    inset: _INSET,
  )
  // At least `default_height` tall: a strut of that height beside the body,
  // in a column of no width.
  show: it_ => if shows != "maybe" { it_ } else {
    grid(columns: (0pt, 100%), box(height: it.default_height - 2 * _INSET), it_)
  }

  // Set either way, so that a box nested in another decides for its own
  // solutions.
  show: e.set_(solution_element, _no-height: no_height)
  // A solution standing alone in a paragraph fills the box, so the highlight
  // reads as the box's answer rather than a stray label; one used
  // mid-sentence stays inline and leaves its line intact.
  widen_par_solutions(it.body, events: events)
  set block(spacing: _SPACING)
  if it.solution != none {
    e.get(get => {
      // Like `#solution[..]`, shown only on the answer key.
      if show_solutions(get) == false { return }
      let colors = solution_colors(get)
      show: it_ => {
        set text(fill: colors.color)
        // Taking no height, in a box sized to what the exam shows: out of
        // the flow, below the body, where its block would have begun. (In a
        // blank box, of `default_height`, it fills the box as usual, which
        // does not change the box's height.)
        // It follows the body with no paragraph break, so the spacing the flow
        // would have put above it is the block spacing, after text or not.
        show: x => if no_height and box_height == auto { place(dy: _SPACING, x) } else { x }
        show: pad.with(-3pt)
        block(
          width: 100%,
          // The solution fills the rest of a box of known height. A box
          // sized to its content has no rest to fill — a `1fr` there would
          // collapse to nothing and spill the solution out below the box —
          // so the solution is sized to its own content instead, and the
          // box (with `height: auto`) grows to hold it.
          height: if box_height == auto { auto } else { 1fr },
          fill: colors.background,
          inset: 3pt,
          it_,
        )
      }
      it.solution
    })
  }
}

#import "../prelude.typ": *
#import "../constants.typ": SHOW_RUBRIC_OVERRIDE, SHOW_SOLUTIONS_OVERRIDE
#import "../config.typ": config, solution_colors
#import "../scan.typ": glue_rubrics, is_multi_par, rubric_markers
#import "../signature.typ": declare_function, define

/// Whether solutions are shown, given the configuration and the command line:
/// `true` or `false`. Unset, they are shown, as everything that draws a
/// solution has always taken it: only `show-solutions: false` hides them.
#let show_solutions(get) = {
  // `answer-box` measuring what the exam shows; see `config`'s `_exam-view`.
  if get(config)._exam-view { return false }
  if SHOW_SOLUTIONS_OVERRIDE != none {
    SHOW_SOLUTIONS_OVERRIDE
  } else {
    get(config).show-solutions != false
  }
}

/// Whether rubrics are shown, given the configuration, the command line, and
/// (for `auto`) whether solutions are.
#let show_rubric(get) = {
  if SHOW_RUBRIC_OVERRIDE != none { return SHOW_RUBRIC_OVERRIDE }
  let value = get(config).show-rubric
  if value == auto { show_solutions(get) } else { value }
}

#let _SHOW_SOLUTIONS = declare_function(
  "show-solutions",
  doc: "Whether solutions are shown, `true` or `false`: the `--input show-solutions=..` command-line override if given, otherwise `config`'s `show-solutions`, which shows them unless it is `false`. Use it to conditionally render content that `#solution[..]` cannot wrap (e.g. one curve of a plot).",
  fields: (
    e.field(
      "get",
      function,
      doc: "The accessor provided by `e.get(get => ..)`.",
      required: true,
      meta: (hint: "call it inside `e.get(get => ..)` and pass it `get`"),
    ),
  ),
)

/// `show_solutions` as exported, with its argument checked. The package
/// itself calls `show_solutions`, which is called for every solution and
/// bubble, directly.
#let show_solutions_checked = define(_SHOW_SOLUTIONS, it => show_solutions(it.get))

/// API documentation for this module's exports, consumed by docs/api.typ
/// (keyed by export name). `solution` needs no argument docs here: elembic
/// elements are introspected.
#let DOCS = (solution: (kind: "element"), "show-solutions": _SHOW_SOLUTIONS)

/// An inline solution that makes no line taller: its text highlighted where it
/// stands, so it flows and wraps with the words around it, rather than boxed.
/// A box would need vertical padding, which makes its line taller, and it
/// cannot break across lines. The sideways padding a boxed solution has comes
/// from a filled cap at each end, joined to the text so that a line break
/// cannot strand it, and drawn as an outset so it takes no height. `highlight`
/// covers only text, so an inline equation gets a fill of its own; an outset
/// again, which takes no height.
#let _inline_no_height(body, colors) = {
  let up = measure(text(top-edge: "ascender", bottom-edge: "baseline")[x]).height
  let down = measure(text(top-edge: "baseline", bottom-edge: "descender")[x]).height
  let cap = box(width: 3pt, height: 0pt, outset: (top: up, bottom: down), fill: colors.background)
  show math.equation.where(block: false): eq => box(fill: colors.background, outset: (y: 3pt), eq)
  (
    cap
      + sym.wj
      + highlight(
        fill: colors.background,
        top-edge: "ascender",
        bottom-edge: "descender",
        text(fill: colors.color, body),
      )
      + sym.wj
      + cap
  )
}

/// A solution that takes no height (see `answer-box`) and is a paragraph of
/// its own: out of the flow, so what follows takes its place, just as on the
/// exam — on top of the content after it, or hanging below the box when it is
/// last. Placed where its block would begin; when it is last, the flow trims
/// the spacing above it, so it is drawn that much lower itself. Needs
/// context, to read that spacing. The first of a run of solutions draws the
/// rest of the run after itself, in the flow of the block it is placed in
/// (`_then`; see `widen_par_solutions`).
#let _placed_no_height(it, body, colors, width) = {
  let gap = if it._last {
    // The flow spaces a block by its `above`, after text and after a block
    // alike. Unset, that reads `auto`, and the flow uses the paragraph
    // spacing. (A relative spacing is read the same way, which is close
    // enough for one nobody sets.)
    let above = block.above
    if type(above) != length { above = par.spacing }
    above
  } else { 0pt }
  let body = text(fill: colors.color, body)
  let drawn = if it.boxed { block(width: width, fill: colors.background, inset: 3pt, body) } else {
    block(width: width, body)
  }
  place(dy: gap, if it._then == none { drawn } else { block(width: 100%, drawn + it._then) })
}

/// A solution that takes no height and stands within a paragraph: it keeps
/// its line no taller than on the exam. With a width of its own, it is a box
/// of that width, padded only sideways and filled above and below as an
/// outset, so it is as tall as its text, though a long one still wraps onto
/// further lines.
#let _in_line_no_height(it, body, colors, width) = {
  if not it.boxed { return text(fill: colors.color, body) }
  if width == auto { return _inline_no_height(body, colors) }
  box(width: width, fill: colors.background, inset: (x: 3pt), outset: (y: 3pt), text(fill: colors.color, body))
}

/// A solution taking no height (see `answer-box`) with an `otherwise`,
/// drawn on the key in the space its `otherwise` takes on the exam: the
/// `otherwise` hidden, and the solution placed over it, so that it takes no
/// room of its own. A paragraph of its own (the `otherwise` runs over
/// several, or holds blocks) is placed at the top of that space; one within
/// a line sits on the bottom of it, as an answer written on a blank does.
#let _over_otherwise(it, colors) = {
  let w = if it.width == none { auto } else { it.width }
  if is_multi_par(it.otherwise) {
    let body = text(fill: colors.color, it.body)
    let drawn = if it.boxed { block(width: if w == auto { 100% } else { w }, fill: colors.background, inset: 3pt, body) } else { body }
    block(width: 100%, hide(it.otherwise) + place(top + left, drawn))
  } else {
    box(hide(it.otherwise) + place(bottom + left, _in_line_no_height(it, it.body, colors, w)))
  }
}

/// (Conditionally) show a solution for a question/part/subpart.
#let solution = e.element.declare(
  "solution",
  prefix: PREFIX,
  doc: "Declare a solution to a question, part, or subpart; this is only rendered if the config option to show solutions is enabled.",
  display: it => {
    e.get(get => {
      // Hidden, a solution still leaves its rubrics where it stands
      // (invisible), so that they are found for the rubric all the same.
      if show_solutions(get) == false {
        return {
          rubric_markers(it.body).join()
          it.otherwise
        }
      }
      let colors = solution_colors(get)
      // On the key, a solution taking no height that has something in its
      // place on the exam is drawn over that, hidden, so the key lays out
      // exactly like the exam.
      if it._no-height and it.otherwise != none {
        return _over_otherwise(it, colors)
      }
      {
        show: it_ => {
          // `width: none` means "not chosen": the context decides. `_fill-width`
          // is how an enclosing element (`answer-box`) asks for the full width,
          // so an explicit `width` — from an argument *or* a set rule, at any
          // scope — still wins over it.
          let w = if it.width != none { it.width } else if it._fill-width { 100% } else { auto }
          if it._no-height {
            // A paragraph of its own: alone in one, as `answer-box` found
            // (`_fill-width`), or holding blocks, which set it apart wherever
            // it stands, even where `answer-box` cannot see it (in an `align`,
            // say).
            return if it._fill-width or is_multi_par(it.body) {
              _placed_no_height(it, it_, colors, if w == auto { 100% } else { w })
            } else {
              _in_line_no_height(it, it_, colors, w)
            }
          }
          if it.boxed {
            // A width other than `auto` must use a block: a full-width *inline*
            // box would be pushed onto a line of its own, splitting any text
            // around it (and stretching a justified line before it).
            let wrap = if w == auto { box.with(width: auto) } else { block.with(width: w) }
            wrap(fill: colors.background, inset: 3pt, text(
              fill: colors.color,
              it_,
            ))
          } else {
            text(fill: colors.color, it_)
          }
        }
        // Rubrics in the solution, when they are drawn, stay with the text
        // beside them (see `glue_rubrics`).
        if show_rubric(get) { glue_rubrics(it.body) } else { it.body }
      }
    })
  },
  fields: (
    e.field("body", content, doc: "The solution content", required: true),
    e.field("boxed", bool, doc: "Whether to put the solution in a box", default: true),
    e.field(
      "width",
      e.types.option(e.types.union(auto, relative)),
      doc: "Width of the solution box. `auto` shrink-wraps it to its content; `none` lets the context choose (`answer-box` fills its width for a solution standing alone in a paragraph, otherwise it shrink-wraps).",
      default: none,
    ),
    e.field(
      "otherwise",
      e.types.option(content),
      doc: "What is shown in the solution's place when solutions are not: a blank to fill in, some lines to write on. In an `answer-box` with no `height`, the answer key draws the solution over it, in the space it takes, so the key lays out exactly like the exam; elsewhere, the solution replaces it.",
      default: none,
    ),
    // Internal: how `answer-box` asks a solution standing alone in a paragraph
    // to fill its width. Kept off the public API (`internal` is what
    // docs/api.typ filters on) because it is a channel between the
    // two elements, not a knob for documents: authors choose a width with
    // `width`, which takes precedence over this.
    e.field(
      "_fill-width",
      bool,
      doc: "Whether an unset `width` should fill the container instead of shrink-wrapping.",
      default: false,
      internal: true,
    ),
    // Internal: how `answer-box` with its default height keeps its solutions
    // from taking any height, so its answer key lays out like its exam. A
    // channel between the two elements, like `_fill-width`.
    e.field(
      "_no-height",
      bool,
      doc: "Whether the solution should take no height: placed out of the flow if it is a block, highlighted where it stands if inline.",
      default: false,
      internal: true,
    ),
    e.field(
      "_last",
      bool,
      doc: "With `_no-height`, whether the solution comes after the last of its box's visible content, where the flow leaves out the spacing it would have put above it, so that it is drawn that much lower itself.",
      default: false,
      internal: true,
    ),
    e.field(
      "_then",
      e.types.option(content),
      doc: "With `_no-height`, what the solution draws after itself, in the flow, in the block it is placed in: the solutions after it in a run with nothing visible between them, which would otherwise all be placed in the same place.",
      default: none,
      internal: true,
    ),
  ),
)

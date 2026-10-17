#import "prelude.typ": *

/// API documentation for `config` below, consumed by docs/api.typ
/// (keyed by export name). The properties are introspected from the
/// element declaration; `config` is never called like a function (its
/// properties are set with `e.set_`), so no call signature is shown.
#let DOCS = (
  config: (
    kind: "element",
    show-signature: false,
    desc: "Package options. Set them with a show rule: `#show: e.set_(config, show-solutions: false, ...)`.",
  ),
)

/// The outline thickness of a bubble (`choice`, `bubble`, `square-bubble`,
/// `choices`) when `bubble-stroke` is not configured. Relative to the font
/// size, so a bubble keeps its proportions in a footnote and in a heading
/// alike; heavier than `answer-box`'s hairline box, because at a bubble's size
/// a thin ring reads as a faint circle rather than as something a student is
/// meant to fill in.
#let DEFAULT_BUBBLE_STROKE = .1em

/// The font a bubble's label (see `choices`' `enumerate`) is set in when
/// `bubble-label-font` is not configured: the monospaced face bundled with
/// Typst, so it is there wherever the document is compiled. Its letters and
/// digits are all of a width, so labels read alike from one bubble to the
/// next, and as a sans face they stand apart from the text of the choice
/// beside them.
#let DEFAULT_BUBBLE_LABEL_FONT = "DejaVu Sans Mono"

/// How questions, parts, and subparts are numbered when
/// `division-numbering` is not configured: one numbering pattern per
/// nesting level. Deeper levels fall back to `"1."`.
#let DEFAULT_DIVISION_NUMBERING = ("1.", "(a)", "i.")

/// The words examy prints itself, when `strings` does not replace them.
#let DEFAULT_STRINGS = (
  question: [Question],
  page: [Page],
  points: [Points],
  bonus: [Bonus],
  score: [Score],
  total: [Total],
)

/// The points badge when `points-format` is not configured: "(1 point)",
/// "(2 points)".
#let default_points_format(points) = [(#points #if points == 1 [point] else [points])]

#let config = e.element.declare(
  "config",
  prefix: PREFIX,
  doc: "Global configuration for an exam",
  display: it => panic(
    "Config should not be displayed directly; instead use `e._set` to set properties on it.",
  ),
  fields: (
    e.field(
      "show-solutions",
      e.types.option(bool),
      doc: "Whether to show solutions. Unset, they are shown; the `--input show-solutions=..` command-line option overrides it",
    ),
    e.field(
      "institution",
      e.types.option(content),
      doc: "The institution name, shown by `maketitle`",
    ),
    e.field(
      "exam-name",
      e.types.option(content),
      doc: "The name of the exam, shown by `maketitle`",
    ),
    e.field(
      "term",
      e.types.option(content),
      doc: "The term of the exam (e.g. Fall 2026), shown by `maketitle`",
    ),
    e.field(
      "duration",
      e.types.option(duration),
      doc: "The length of the exam, shown by `maketitle`",
    ),
    e.field(
      "show-rubric",
      e.types.option(bool),
      doc: "Whether to show a rubric",
    ),
    e.field(
      "solution-color",
      e.types.union(auto, color),
      doc: "The color solutions are drawn in: the text of a solution, the outline and check mark of a filled-in bubble. `auto` derives it from `solution-background-color`, or falls back to the package default if that is `auto` too",
      default: auto,
    ),
    e.field(
      "solution-background-color",
      e.types.union(auto, color),
      doc: "The color behind a solution, and the fill of a filled-in bubble. `auto` derives it from `solution-color` by lightening",
      default: auto,
    ),
    e.field(
      "bubble-stroke",
      length,
      doc: "The outline thickness of the bubbles drawn by `choice`, `bubble`, `square-bubble` and `choices`. An `em` length scales with the text around each bubble. Must not be negative; an outline thick enough to cover a filled-in bubble's check mark (about a fifth of the bubble's size) is drawn thinner, at the most that leaves the check mark clear",
      default: DEFAULT_BUBBLE_STROKE,
    ),
    e.field(
      "bubble-label-font",
      e.types.union(str, array),
      doc: "The font the labels inside bubbles (`choices`' `enumerate`) are set in: a font name, or a list of them to fall back through, as `text`'s `font` takes. The default is the monospaced font bundled with Typst",
      default: DEFAULT_BUBBLE_LABEL_FONT,
    ),
    e.field(
      "choices-enumerate",
      e.types.union(bool, str, function),
      doc: "How `choices` labels its bubbles, unless it is given `enumerate` itself: `false` for no labels, `true` for A, B, C, …, or a numbering pattern or function, as `enum`'s `numbering` takes (`\"a\"`, `\"1\"`, `\"(i)\"`)",
      default: false,
    ),
    e.field(
      "division-numbering",
      e.types.array(e.types.union(str, function)),
      doc: "How questions, parts, and subparts are numbered: one numbering pattern or function per nesting level, as `numbering` takes, e.g. `(\"Problem 1.\", \"(a)\", \"i.\")`. Levels past the end of the array are numbered `\"1.\"`. A reference drops a pattern's trailing `.`, so `@label` reads \"Problem 1 (a)\"; a function's result is used as it is",
      default: DEFAULT_DIVISION_NUMBERING,
      // Set as a whole: the default folding of arrays would append to it.
      folds: false,
    ),
    e.field(
      "strings",
      e.types.dict(content),
      doc: "The words examy prints itself, keyed by `question`, `page`, `points`, `bonus`, `score`, and `total`. Only the keys given are replaced, e.g. `strings: (total: [Gesamt])`. The points badge's words are set by `points-format`",
      default: DEFAULT_STRINGS,
    ),
    e.field(
      "points-format",
      e.types.union(auto, function),
      doc: "How the points badge of a question, part, or subpart is drawn: a function taking the number of points and returning content, e.g. `p => [[#p]]` or `p => [(#p Punkte)]`. `auto` is \"(1 point)\", \"(2 points)\"",
      default: auto,
    ),
    e.field(
      "points-position",
      e.types.union("start", "margin-left", "margin-right", "end"),
      doc: "Where the points badge is drawn.\n\n`\"start\"`: before the first word of the body.\n\n`\"margin-left\"` or `\"margin-right\"`: in the page margin, level with the body's first line. The margin must be wide enough to hold it.\n\n`\"end\"`: flush right, after all of the body's own text (answer boxes included) and before its first part. After an `fr` box, the box gives up a line to it",
      default: "start",
    ),
    e.field(
      "points-show-totals",
      bool,
      doc: "Whether a question or part whose parts have points shows their total in its own badge: a question with two parts of 2 points each shows \"(4 points)\". The total is only shown; it is not counted again. A question with points of its own as well as on its parts shows a warning in red in place of its badge, as the two cannot both be its total",
      default: false,
    ),
    e.field(
      "points-table-direction",
      e.types.union("horizontal", "vertical"),
      doc: "The layout of `points-table`: `\"horizontal\"` with a column per question, or `\"vertical\"` with a row per question",
      default: "horizontal",
    ),
    e.field(
      "points-table-by",
      e.types.union("question", "page"),
      doc: "Whether `points-table` totals the points by question or by page; by page, a page without points is left out",
      default: "question",
    ),
    e.field(
      "points-table-score",
      bool,
      doc: "Whether `points-table` has an empty Score row (a column, when vertical) for the grader to fill in",
      default: false,
    ),
    e.field(
      "points-table-bonus",
      bool,
      doc: "Whether `points-table` has a Bonus row (a column, when vertical) with the bonus points, when the exam has any",
      default: false,
    ),
    e.field(
      "points-table-max-columns",
      e.types.option(int),
      doc: "The most questions (or pages) a horizontal `points-table` shows side by side; more are split into several tables, one below the other, with the total in the last. `none` keeps them all in one table",
      default: none,
    ),
    // The name `solution-color` had in 0.3 and earlier, when it colored only the
    // text of a solution. Kept so that documents written for 0.3 still
    // compile and keep their color.
    e.field(
      "solution-text-color",
      e.types.union(auto, color),
      doc: "Deprecated: the old name of `solution-color`, still accepted. Ignored when `solution-color` is set",
      default: auto,
    ),
    // Internal: set while `answer-box` lays out its body as the exam shows
    // it, to measure it. Overrides `show-solutions` and the command line
    // alike, so the measurement is of the exam even when compiling the key.
    e.field(
      "_exam-view",
      bool,
      doc: "Whether to lay out as the exam, whatever `show-solutions` and the command line say.",
      default: false,
      internal: true,
    ),
  ),
)

/// The color solutions are drawn in when neither `solution-color` nor
/// `solution-background-color` is configured.
#let DEFAULT_SOLUTION_COLOR = blue.darken(20%)

/// How much lighter than the solution color its background is.
#let _BACKGROUND_LIGHTEN = 90%

/// Derive a solution color from a background: the inverse of lightening it.
///
/// Darkening alone will not do. A background is a pale wash with almost no
/// saturation left, and darkening a near-white color keeps its (nearly
/// neutral) proportions, so `bg.darken(..)` comes out gray whatever the hue
/// was. The color is instead rebuilt at a readable lightness from the wash's
/// own hue, with its chroma scaled back up — capped, so a background that is
/// already vivid does not land far outside the gamut. A neutral gray
/// background has no hue to restore, and stays neutral.
#let _color_from_background(background) = {
  let (_, chroma, hue, ..) = oklch(background).components()
  oklch(45%, calc.min(chroma * 8, 0.2), hue)
}

/// Resolve the configured pair into the two colors actually drawn with.
/// Either may be given on its own, and the other is then derived from it;
/// given both, both are used as-is. Pure, so it is testable without a
/// document.
#let resolve_solution_colors(solution-color, background) = {
  if solution-color == auto and background == auto {
    solution-color = DEFAULT_SOLUTION_COLOR
  }
  if solution-color == auto {
    solution-color = _color_from_background(background)
  }
  if background == auto {
    background = solution-color.lighten(_BACKGROUND_LIGHTEN)
  }
  (color: solution-color, background: background)
}

/// `resolve_solution_colors` for the configured values, for use inside
/// `e.get(get => ..)`. The deprecated `solution-text-color` stands in for
/// `solution-color` when only it is set.
#let solution_colors(get) = {
  let cfg = get(config)
  let solution-color = if cfg.solution-color != auto { cfg.solution-color } else { cfg.solution-text-color }
  resolve_solution_colors(solution-color, cfg.solution-background-color)
}

/// The options the exam pipeline lays out with, resolved from `config`, for
/// use inside `e.get(get => ..)`. Passed down to `render` as a plain
/// dictionary, so that rendering itself needs no context.
#let exam_options(get) = {
  let cfg = get(config)
  (
    numbering: cfg.division-numbering,
    // Folded onto its default by elembic: a partial `strings` keeps the rest.
    strings: cfg.strings,
    points-format: if cfg.points-format == auto { default_points_format } else { cfg.points-format },
    points-position: cfg.points-position,
    points-show-totals: cfg.points-show-totals,
  )
}

/// `exam_options` with nothing configured, for rendering without a document
/// (the unit tests).
#let DEFAULT_EXAM_OPTIONS = (
  numbering: DEFAULT_DIVISION_NUMBERING,
  strings: DEFAULT_STRINGS,
  points-format: default_points_format,
  points-position: "start",
  points-show-totals: false,
)

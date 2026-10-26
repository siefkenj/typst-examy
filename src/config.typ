#import "prelude.typ": *

/// API documentation for `config` below, consumed by docs/api.typ
/// (keyed by export name). The properties are introspected from the
/// element declaration; `config` is never called like a function (its
/// properties are set with `e.set_`), so no call signature is shown.
#let DOCS = (
  config: (
    kind: "element",
    show-signature: false,
    desc: "Global configuration of package options. Give options to the exam, e.g. `#show: exam.with(show-solutions: true)`, or set them with `#show: e.set_(config, show-solutions: true)`.",
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

/// The space a bubble keeps around itself when `bubble-outset` is not
/// configured: a gap after it, parting it from whatever follows (see
/// `choice`'s `outset`).
#let DEFAULT_BUBBLE_OUTSET = (right: .4em)

/// How far the body of a question, part, or subpart is indented from the one
/// it is in, when `indent` is not configured.
#let DEFAULT_INDENT = 1.5em

/// A relative length, checked but kept as given: a plain length stays a
/// length (see signature.typ), as `answer-box` expects.
#let _RELATIVE = (length, ratio, e.types.exact(relative))

/// What an answer box's outline and background take, as `box`'s `stroke`
/// and `fill` do: `answer-box`'s fields and the options that give them.
#let BOX_STROKE = e.types.union(none, length, color, gradient, tiling, e.types.exact(stroke), dictionary)
#let BOX_FILL = e.types.union(none, color, gradient, tiling)

/// How questions, parts, and subparts are numbered when `numbering` is not
/// configured: one numbering pattern per nesting level. Deeper levels fall
/// back to `"1."`.
#let DEFAULT_NUMBERING = ("1.", "(a)", "i.")

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
/// "(2 points)"; with `bonus`, the badge when `bonus-points-format` is not
/// configured: "(1 bonus point)", "(2 bonus points)".
#let default_points_format(points, bonus: false) = {
  let word = if points == 1 [point] else [points]
  if bonus [(#points bonus #word)] else [(#points #word)]
}

/// The options that draw words, which `strings` takes too, though it is
/// not documented, as an author easily puts them there: `strings:
/// (points: [Punkte], points-format: p => ..)`. The option of the same name
/// wins over it (see `exam_options`).
#let _STRINGS_FORMATS = ("points-format", "bonus-points-format")

/// `strings`' type: a dictionary of content, as documented, which takes the
/// functions of `_STRINGS_FORMATS` too, named and failing as it would
/// without them.
#let _STRINGS_TYPE = {
  let base = e.types.dict(content)
  let formats(d) = d.keys().filter(k => k in _STRINGS_FORMATS and type(d.at(k)) == function)
  let words(d) = {
    for k in formats(d) { let _ = d.remove(k) }
    d
  }
  e.types.wrap(
    base,
    check: _ => d => e.types.cast(words(d), base).first(),
    cast: _ => d => e.types.cast(words(d), base).last() + formats(d).map(k => (k, d.at(k))).to-dict(),
    // Still a dictionary, folded as before: a rule's keys over the last's.
    output: prev => prev,
    fold: prev => prev,
    error: _ => d => e.types.cast(words(d), base).last(),
  )
}

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
      bool,
      doc: "Whether to show solutions. The `--input show-solutions=..` command-line option overrides this setting.",
      default: true,
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
      e.types.option(e.types.union(duration, content)),
      doc: "The length of the exam, shown by `maketitle`: a [`duration`](https://typst.app/docs/reference/foundations/duration/), shown in minutes (`duration(minutes: 110)` as \"110 Minutes\"), or content, shown as it is (`[1 h 50 min]`)",
    ),
    e.field(
      "show-rubrics",
      e.types.union(auto, bool),
      doc: "Whether to show the rubrics of questions, parts, and subparts (see `rubric`). `auto` shows them where solutions are shown, on the answer key; the `--input show-rubrics=..` command-line option overrides it. A rubric that is not shown takes no room, so the exam lays out the same either way",
      default: false,
    ),
    e.field(
      "rubric-position",
      e.types.union("margin-right", "margin-left", "end"),
      doc: "Where a division's rubric is drawn.\n\n`\"margin-right\"` or `\"margin-left\"`: in the page margin, level with the division's first line, below the rubric before it when they would overlap. Widen the margin to make room for it (see `rubric-width`).\n\n`\"end\"`: after the division, its parts included, in the flow, taking room of its own",
      default: "margin-right",
    ),
    e.field(
      "rubric-trace",
      e.types.union(auto, bool),
      doc: "Whether a rubric written in a division's body is traced by a dotted line from where it is written to its item in the rubric. `auto` traces them in the margins and not at the `\"end\"`",
      default: auto,
    ),
    e.field(
      "rubric-width",
      e.types.union(auto, length),
      doc: "The width of a rubric in the margin. `auto` fills the page margin it is in, less a gap on either side",
      default: auto,
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
      doc: "The font the labels inside bubbles (`choices`' `enumerate`) are set in: a font name, or a list of them to fall back through, as [`text`'s `font`](https://typst.app/docs/reference/text/text/#parameters-font) takes. The default is the monospaced font bundled with Typst",
      default: DEFAULT_BUBBLE_LABEL_FONT,
      // Set as a whole: the default folding of arrays would append to it.
      folds: false,
    ),
    e.field(
      "bubble-size",
      e.types.union(auto, length),
      doc: "The diameter of the round bubbles drawn by `choice`, `bubble`, `square-bubble` and `choices`, unless one is given `size`. A square bubble is drawn a little smaller across, in the same proportion as by default, so the two still read alike. `auto` is `1em`; an `em` length scales with the text around each bubble",
      default: auto,
    ),
    e.field(
      "bubble-outset",
      e.types.union(length, dictionary),
      doc: "The space bubbles keep around themselves, unless one is given `outset`, as `choice`'s `outset` takes it: a length for the gap after the bubble, or a dictionary of sides (`left`, `right`, `top`, `bottom`, `x`, `y`, `rest`), the sides it does not name keeping their defaults",
      default: DEFAULT_BUBBLE_OUTSET,
    ),
    e.field(
      "choices-enumerate",
      e.types.union(bool, str, function, array),
      doc: "How `choices` labels its bubbles, unless it is given `enumerate` itself: `false` for no labels, `true` for A, B, C, …, a numbering pattern or function, as [`enum`'s `numbering`](https://typst.app/docs/reference/model/enum/#parameters-numbering) takes (`\"a\"`, `\"1\"`, `\"(i)\"`), or an array of labels, one per choice in turn (`(\"x\", \"y\", \"z\")`)",
      default: false,
      // Set as a whole: the default folding of arrays would append to it.
      folds: false,
    ),
    e.field(
      "choices-inline",
      bool,
      doc: "Whether `choices` runs its choices together, side by side in a paragraph of their own, unless it is given `inline` or `columns`. Cannot be combined with `choices-columns`",
      default: false,
    ),
    e.field(
      "choices-columns",
      e.types.option(int),
      doc: "How many equal columns `choices` sets its choices in, unless it is given `inline` or `columns`. `none` sets them one per line. Cannot be combined with `choices-inline`",
      default: none,
    ),
    e.field(
      "choices-gap",
      e.types.union(auto, length, fraction),
      doc: "The space between two choices of `choices`, unless it is given `gap`; see its `gap` for what `auto` and the others mean",
      default: auto,
    ),
    e.field(
      "answer-box-height",
      e.types.union(auto, .._RELATIVE, fraction, none),
      doc: "The `height` of an `answer-box` that is not given one, by its call or a set rule on `answer-box`. `none` sizes a box by what the exam shows in it, and a blank one takes `answer-box-default-height`; see `answer-box`'s `height` for the others",
      default: none,
    ),
    e.field(
      "answer-box-width",
      e.types.union(auto, .._RELATIVE, fraction),
      doc: "The `width` of an `answer-box` that is not given one, by its call or a set rule on `answer-box`. `auto` is the full width for a box with a fractional height (`1fr`), and `answer-box-default-width` otherwise",
      default: auto,
    ),
    e.field(
      "answer-box-stroke",
      BOX_STROKE,
      doc: "The `stroke` of an `answer-box` that is not given one, by its call or a set rule on `answer-box`: its outline, as [`box`'s `stroke`](https://typst.app/docs/reference/layout/box/#parameters-stroke) takes it. `none` leaves blank space, and `(bottom: .5pt)` draws a single rule to write on",
      default: .5pt,
    ),
    e.field(
      "answer-box-fill",
      BOX_FILL,
      doc: "The `fill` of an `answer-box` that is not given one, by its call or a set rule on `answer-box`: its background, as [`box`'s `fill`](https://typst.app/docs/reference/layout/box/#parameters-fill) takes it, e.g. `luma(245)`",
      default: none,
    ),
    e.field(
      "answer-box-default-height",
      length,
      doc: "The height of an `answer-box` that is blank on the exam and has a `height` of `none`, unless it is given `default-height`",
      default: 2cm,
    ),
    e.field(
      "answer-box-default-width",
      length,
      doc: "The width of an `answer-box` with a `width` of `auto` and a height that is not a fraction, unless it is given `default-width`",
      default: 2cm,
    ),
    e.field(
      "numbering",
      e.types.union(str, function, e.types.array(e.types.union(str, function))),
      doc: "How questions, parts, and subparts are numbered, as [`enum`'s `numbering`](https://typst.app/docs/reference/model/enum/#parameters-numbering) takes it: a pattern such as `\"1.a.i.\"`, whose counting symbols number the levels in turn (the last one any deeper levels), or a function of the number. Or an array of them, one per level, e.g. `(\"Problem 1.\", \"(a)\", \"i.\")`, levels past its end numbered `\"1.\"`.\n\nA reference drops a pattern's trailing `.`, so `@label` reads \"Problem 1 (a)\"; a function's result is used as it is",
      default: DEFAULT_NUMBERING,
      // Set as a whole: the default folding of arrays would append to it.
      folds: false,
    ),
    e.field(
      "indent",
      length,
      doc: "How far the body of a question, part, or subpart is indented from the one it is in, unless it is given `indent`",
      default: DEFAULT_INDENT,
    ),
    e.field(
      "numbering-full",
      bool,
      doc: "Whether a part or subpart is numbered with the numbers of the divisions it is in, as [`enum`'s `full`](https://typst.app/docs/reference/model/enum/#parameters-full) does: `\"1.a.\"` numbers part (a) of question 1 \"1.a.\", and a function is given every level's number, `(1, 1)`. With an array of `numbering`s, a level's entry numbers it so if it has a counting symbol for each level (`(\"1.\", \"1.a.\")`); otherwise it is the number above it followed by its own, after a thin space and without the trailing `.` or `,` of the one above (\"1 (a)\"), unless every level is a number in digits, which keep their punctuation (\"1.1.\"). A reference then reads as the full number too, \"1.a\", and a question whose body starts with a part shows only the part's number on their shared line, which holds its own. A level whose numbers are not all counted (a division given `number: [..]` or `none`, or one inside it) is numbered on its own",
      default: false,
    ),
    e.field(
      "strings",
      _STRINGS_TYPE,
      doc: "The words examy prints itself, keyed by `question`, `page`, `points`, `bonus`, `score`, and `total`. Only the keys given are replaced, e.g. `strings: (total: [Gesamt])`. The points badge's words are set by `points-format` and `bonus-points-format`",
      default: DEFAULT_STRINGS,
    ),
    e.field(
      "points-format",
      e.types.union(auto, function),
      doc: "How the points badge of a question, part, or subpart is drawn: a function taking the number of points and returning content, e.g. `p => [[#p]]` or `p => [(#p Punkte)]`. `auto` is \"(1 point)\", \"(2 points)\". Bonus points are drawn by `bonus-points-format`",
      default: auto,
    ),
    e.field(
      "bonus-points-format",
      e.types.union(auto, function),
      doc: "How the points badge of a question, part, or subpart with `intent: \"bonus\"` is drawn, as `points-format` draws the others: a function taking the number of points and returning content, e.g. `p => [[#p bonus]]` or `p => [(#p Bonuspunkte)]`. `auto` is \"(1 bonus point)\", \"(2 bonus points)\"",
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
      doc: "The layout of `points-table`, unless it is given `direction`: `\"horizontal\"` with a column per question, or `\"vertical\"` with a row per question",
      default: "horizontal",
    ),
    e.field(
      "points-table-by",
      e.types.union("question", "part", "subpart", "page"),
      doc: "What `points-table` totals the points by, unless it is given `by`: `\"question\"`, `\"part\"`, `\"subpart\"`, or `\"page\"` (see `points-table`)",
      default: "question",
    ),
    e.field(
      "points-table-score",
      bool,
      doc: "Whether `points-table` has an empty Score row (a column, when vertical) for the grader to fill in, unless it is given `score`",
      default: false,
    ),
    e.field(
      "points-table-bonus",
      bool,
      doc: "Whether `points-table` has a Bonus row (a column, when vertical) with the bonus points, when the exam has any, unless it is given `bonus`",
      default: false,
    ),
    e.field(
      "points-table-max-columns",
      e.types.option(int),
      doc: "The most questions (or pages) a horizontal `points-table` shows side by side, unless it is given `max-columns`; more are split into several tables, one below the other, with the total in the last. `none` keeps them all in one table",
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
    // Internal: set by the documentation's examples, which are laid out in
    // blocks of no fixed height, where `fr` heights would come to nothing.
    e.field(
      "_fr-unit",
      e.types.option(length),
      doc: "The length an exam lays out each `1fr` of its own heights as (a segment's of `fr` answer boxes, a division's `height`), instead of a share of the page: `none` for a share, as usual.",
      default: none,
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
/// `solution-color` when only it is set. `color` and `background`, when not
/// `auto`, stand in for the configured ones, as a solution's own `color` and
/// `background-color` do.
#let solution_colors(get, color: auto, background: auto) = {
  let cfg = get(config)
  if color == auto {
    color = if cfg.solution-color != auto { cfg.solution-color } else { cfg.solution-text-color }
  }
  if background == auto { background = cfg.solution-background-color }
  resolve_solution_colors(color, background)
}

/// The options the exam pipeline lays out with, resolved from `config`, for
/// use inside `e.get(get => ..)`. Passed down to `render` as a plain
/// dictionary, so that rendering itself needs no context.
#let exam_options(get) = {
  let cfg = get(config)
  (
    numbering: cfg.numbering,
    numbering-full: cfg.numbering-full,
    // Folded onto its default by elembic: a partial `strings` keeps the rest.
    strings: cfg.strings,
    // The option, else one put in `strings` (see `_STRINGS_FORMATS`).
    points-format: if cfg.points-format != auto { cfg.points-format } else {
      cfg.strings.at("points-format", default: default_points_format)
    },
    bonus-points-format: if cfg.bonus-points-format != auto { cfg.bonus-points-format } else {
      cfg.strings.at("bonus-points-format", default: p => default_points_format(p, bonus: true))
    },
    points-position: cfg.points-position,
    points-show-totals: cfg.points-show-totals,
    // How the exam lays out its own `fr` heights (see `fr_height` in
    // render.typ): as a share of the page (`none`), as `_fr-unit` each, or,
    // on a page of no fixed height, where a share comes to nothing, as tall
    // as what they hold (`auto`).
    fr-unit: if cfg._fr-unit != none { cfg._fr-unit } else if page.height == auto { auto } else { none },
    // `shown` is resolved by the exam, which knows whether solutions are shown
    // (see `show_rubrics`), and `present`, whether it has rubrics at all, and
    // so `drawn`, whether they are drawn, and `traced`, whether their leaders
    // are too, and `positions`, those its divisions' rubrics are drawn at
    // (see `process_questions`).
    rubric: (
      shown: cfg.show-rubrics,
      present: false,
      drawn: false,
      traced: false,
      positions: (),
      position: cfg.rubric-position,
      trace: if cfg.rubric-trace == auto { cfg.rubric-position != "end" } else { cfg.rubric-trace },
      // As configured, for a division with a `rubric-position` of its own
      // (see `opts_of` in render.typ).
      trace-given: cfg.rubric-trace,
      width: cfg.rubric-width,
    ),
    indent: cfg.indent,
  )
}

/// The options an exam reads once, where it starts (see `exam_options`,
/// and `show_rubrics`), for all its questions: set inside it, around some of
/// them, they would change nothing (see `exam_wide_options_set`). Keep in
/// step with `exam_options`.
#let EXAM_WIDE_OPTIONS = (
  "numbering",
  "numbering-full",
  "strings",
  "points-format",
  "bonus-points-format",
  "points-position",
  "points-show-totals",
  "_fr-unit",
  "show-rubrics",
  "rubric-position",
  "rubric-trace",
  "rubric-width",
  "indent",
)

/// The options of `EXAM_WIDE_OPTIONS` that a question, part, or subpart
/// takes for itself too, under the same name (see divisions.typ).
#let DIVISION_OPTIONS = ("numbering", "rubric-position", "rubric-trace", "rubric-width", "indent")

/// The options of `EXAM_WIDE_OPTIONS` that a `config` set rule inside an
/// exam may set: the exam applies them to the questions, parts, and subparts
/// in the rule's scope (see `scoped_options_set`, and `localize` in
/// render.typ). The others are read once for all of them: `numbering` too,
/// as references across the exam would no longer read alike.
#let SCOPED_OPTIONS = (
  "points-format",
  "bonus-points-format",
  "points-position",
  "points-show-totals",
  "rubric-position",
  "rubric-trace",
  "rubric-width",
  "indent",
)

/// The `config` rules an elembic rule (its data, see `elembic_rule` in
/// scan.typ) is made of, in order: itself, or those an `apply` combines.
#let _config_rules(rule) = {
  let found = ()
  let stack = (rule,)
  while stack.len() > 0 {
    let r = stack.pop()
    if type(r) != dictionary { continue }
    let kind = r.at("kind", default: none)
    if kind == "apply" {
      stack += r.at("rules", default: ()).rev()
    } else if kind in ("set", "cond-set") and r.at("element", default: (:)).at("eid", default: none) == e.eid(config) {
      found.push(r)
    }
  }
  found
}

/// Which of `EXAM_WIDE_OPTIONS` an elembic rule sets on `config` that it may
/// not inside an exam, in order: any but `SCOPED_OPTIONS` that a `set_` rule
/// sets, and any that a `cond-set` rule sets, as a condition on `config`
/// would hold for some questions and not others.
#let exam_wide_options_set(rule) = {
  let found = ()
  for r in _config_rules(rule) {
    let keys = r.at("args", default: (:)).keys().filter(k => k in EXAM_WIDE_OPTIONS)
    found += if r.kind == "set" { keys.filter(k => k not in SCOPED_OPTIONS) } else { keys }
  }
  found.dedup()
}

/// The values of `SCOPED_OPTIONS` that an elembic rule sets on `config`, by
/// name: a later rule's (in an `apply`) over an earlier one's.
#let scoped_options_set(rule) = {
  let found = (:)
  for r in _config_rules(rule) {
    if r.kind != "set" { continue }
    for (k, v) in r.at("args", default: (:)) {
      if k in SCOPED_OPTIONS { found.insert(k, v) }
    }
  }
  found
}

/// The names of the rules before an exam that set any of
/// `EXAM_WIDE_OPTIONS`, from elembic's record of the rules in force where it
/// starts (`data`, as `e.internal.debug-get` passes it; see `exam`): a
/// `revoke` of one inside the exam would undo what it read there, and so
/// change nothing (see `exam_wide_rule_error`).
#let exam_wide_names(data) = {
  let d = data.elements.at(e.data(config).eid, default: none)
  if d == none { return () }
  let names = ()
  // `data-chain` has `none` for a rule with no names before a named one.
  for (args, info) in d.chain.zip(d.data-chain) {
    if info != none and type(args) == dictionary and args.keys().any(k => k in EXAM_WIDE_OPTIONS) {
      names += info.names
    }
  }
  names.dedup()
}

/// `exam_options` with nothing configured, for rendering without a document
/// (the unit tests).
#let DEFAULT_EXAM_OPTIONS = (
  numbering: DEFAULT_NUMBERING,
  numbering-full: false,
  strings: DEFAULT_STRINGS,
  points-format: default_points_format,
  bonus-points-format: p => default_points_format(p, bonus: true),
  points-position: "start",
  points-show-totals: false,
  fr-unit: none,
  rubric: (
    shown: false,
    present: false,
    drawn: false,
    traced: false,
    positions: (),
    position: "margin-right",
    trace: true,
    trace-given: auto,
    width: auto,
  ),
  indent: DEFAULT_INDENT,
)

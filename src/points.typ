/// Point totals, the scoring table, and the points on each page. The exam
/// element computes the per-question data once from the parsed item tree
/// and stores it in a state; the functions here read the final value, so
/// they work anywhere in the document (even before the exam). Points by page
/// come from markers the exam leaves where each division's points are drawn.

#import "prelude.typ": *
#import "config.typ": config, DEFAULT_NUMBERING
#import "refs.typ": format_component
#import "signature.typ": declare_function, define

/// The per-question point data of every exam in the document, one array per
/// exam, in order. A document can hold several exams (a bundle export of
/// the exam and its key, or a page of examples), so each reader picks its
/// own exam (see `exam_points_data`).
#let points_data_state = state(PREFIX + "/points-data", ())

/// How many exams have started, and how many ended, before a location.
#let EXAMS_STARTED = counter(PREFIX + "/exams-started")
#let EXAMS_ENDED = counter(PREFIX + "/exams-ended")

/// The point data of the exam a reader at `here()` is about: the exam it is
/// in; else the next exam, as a points table on a cover page is about the
/// exam that follows; else the last one, as a total at the end of a document
/// is. `none` if there is no exam. Needs context.
#let exam_points_data() = {
  let all = points_data_state.final()
  if all.len() == 0 { return none }
  let started = EXAMS_STARTED.get().first()
  let ended = EXAMS_ENDED.get().first()
  let i = if started > ended { started - 1 } else { calc.min(started, all.len() - 1) }
  all.at(i)
}

/// The label of the marker each division with points leaves at its start
/// (see `points_marker`).
#let POINTS_MARKER = label(PREFIX + "/points")

/// The marker a division with points leaves where it starts, which
/// `get-num-points-page` and the table by page count. Invisible.
#let points_marker(points, intent) = [#metadata((points: points, intent: intent))#POINTS_MARKER]

/// How a question is labelled in the points table: its number as a reference
/// would show it (without a trailing "."), or a dash for an unnumbered one.
#let _question_label(number, numbering) = {
  if number == none { sym.dash.en } else { format_component(0, number, numbering: numbering) }
}

/// Extract the per-question point data from parsed items.
#let compute_points_data(items, numbering: DEFAULT_NUMBERING) = {
  items
    .filter(it => it.kind == "division" and it.level == 1)
    .map(q => (
      number: q.number,
      label: _question_label(q.number, numbering),
      total_points: q.total_points,
      total_bonus_points: q.total_bonus_points,
    ))
}

/// The singular and plural names of the divisions at a level, for the
/// warning a points conflict shows.
#let _LEVEL_NAMES = ("question", "part", "subpart")

/// Decide the points badge of every division, given `config`'s
/// `points-show-totals` and `points-position`. Pure. Each division gets
/// - `badge`: `none`; `(kind: "points", points: n, total: bool)`, the number
///   to show, and whether it is the total of the division's parts; or
///   `(kind: "conflict", own: n, parts: m)` when, showing totals, a division
///   has points of its own as well as regular points on its parts, so that
///   neither is its total;
/// - `badge_takes_line`: whether the badge is drawn in the flow of the
///   division's first segment, so that `plan` keeps it out of a segment
///   holding an `fr` box, where it would spend the box's share of the page.
///   A badge in the margin takes no room, and one at the `"end"` follows the
///   division's text (taking a line after an `fr` box, in its segment, which
///   the box shares with it); a conflict warning is always drawn at the
///   start, in the flow.
/// - `badge_at_end`: whether the badge is drawn at the `"end"`, after the
///   division's own text, so that `plan` gives a division with none before
///   its first part a segment of its own, for the badge's line.
#let assign_badges(items, show-totals: false, position: "start") = {
  items.map(it => {
    if it.kind != "division" { return it }
    let own = it.fields.points
    let badge = if not show-totals {
      if own == none { none } else { (kind: "points", points: own, total: false) }
    } else {
      let own_regular = if own != none and it.fields.intent == none { own } else { 0 }
      let parts = it.total_points - own_regular
      if own != none and parts > 0 {
        (kind: "conflict", own: own, parts: parts, level: it.level)
      } else if own != none {
        (kind: "points", points: own, total: false)
      } else if parts > 0 {
        (kind: "points", points: parts, total: true)
      } else {
        none
      }
    }
    (
      ..it,
      badge: badge,
      badge_takes_line: badge != none and (badge.kind == "conflict" or position == "start"),
      badge_at_end: badge != none and badge.kind == "points" and position == "end",
    )
  })
}

/// The warning drawn in place of a badge in conflict (see `assign_badges`).
#let conflict_warning(badge) = {
  let name = _LEVEL_NAMES.at(badge.level - 1, default: "subpart")
  let parts = _LEVEL_NAMES.at(badge.level, default: "subpart") + "s"
  text(fill: red)[examy: this #name has points of its own (#badge.own) and points on its #parts (#badge.parts); with `points-show-totals`, give points to one or the other.]
}

// Each count comes twice: as a number, `get-num-..()`, to compute or test
// with, which needs context; and as content, `num-..`, which shows it
// anywhere, with no context of its own to write.

#let _GET_NUM_QUESTIONS = declare_function(
  "get-num-questions",
  doc: "The total number of questions in the exam, as a number, to compute or test with. Needs context: `context get-num-questions()`. To show it, `num-questions` needs none.",
)

/// The total number of questions in the exam (see DOCS). Needs context.
#let get_num_questions = define(_GET_NUM_QUESTIONS, it => {
  let data = exam_points_data()
  if data == none { 0 } else { data.len() }
})

#let _GET_NUM_POINTS = declare_function(
  "get-num-points",
  doc: "The total number of regular (non-bonus, non-practice) points, as a number, to compute or test with, e.g. a pass mark: `context calc.ceil(get-num-points() * .6)`. Needs context. To show it, `num-points` needs none.",
)

/// The total number of regular points (see DOCS). Needs context.
#let get_num_points = define(_GET_NUM_POINTS, it => {
  let data = exam_points_data()
  if data == none { 0 } else { data.map(q => q.total_points).sum(default: 0) }
})

#let _GET_NUM_BONUS_POINTS = declare_function(
  "get-num-bonus-points",
  doc: "The total number of bonus points, as a number, to compute or test with. Needs context: `context if get-num-bonus-points() > 0 [..]`. To show it, `num-bonus-points` needs none.",
)

/// The total number of bonus points (see DOCS). Needs context.
#let get_num_bonus_points = define(_GET_NUM_BONUS_POINTS, it => {
  let data = exam_points_data()
  if data == none { 0 } else {
    data.map(q => if q.total_bonus_points == none { 0 } else { q.total_bonus_points }).sum(default: 0)
  }
})

/// The total number of questions in the exam, shown (see DOCS).
#let num_questions = context get_num_questions()

/// The total number of regular points, shown (see DOCS).
#let num_points = context get_num_points()

/// The total number of bonus points, shown (see DOCS).
#let num_bonus_points = context get_num_bonus_points()

/// The points markers, grouped by page: an array of `(page: n, location,
/// points, bonus)`, one per page with points, in page order, where
/// `location` is that of the page's first marker. Needs context.
#let _points_by_page() = {
  let pages = (:)
  for m in query(POINTS_MARKER) {
    let page = m.location().page()
    let key = str(page)
    if key not in pages { pages.insert(key, (page: page, location: m.location(), points: 0, bonus: 0)) }
    if m.value.intent == none { pages.at(key).points += m.value.points }
    if m.value.intent == "bonus" { pages.at(key).bonus += m.value.points }
  }
  pages.values().sorted(key: p => p.page)
}

#let _GET_NUM_POINTS_PAGE = declare_function(
  "get-num-points-page",
  doc: "The number of points on a page, as a number, to compute or test with: the points of each question, part, and subpart that starts on it. Needs context, e.g. in a page footer: `context if get-num-points-page() > 0 [..]`. To show the current page's, `num-points-page` needs none.",
  fields: (
    e.field(
      "page",
      e.types.smart(int),
      doc: "The page, as its physical page number (counted from 1, whatever its numbering shows); `auto` is the current page.",
      default: auto,
    ),
    e.field(
      "bonus",
      bool,
      doc: "Count the bonus points on the page instead of the regular ones.",
      default: false,
    ),
  ),
)

/// The number of points on a page (see DOCS). Needs context.
#let get_num_points_page = define(_GET_NUM_POINTS_PAGE, it => {
  let page = if it.page == auto { here().page() } else { it.page }
  let intent = if it.bonus { "bonus" } else { none }
  query(POINTS_MARKER)
    .filter(m => m.value.intent == intent and m.location().page() == page)
    .map(m => m.value.points)
    .sum(default: 0)
})

/// The number of points on the current page, shown (see DOCS).
#let num_points_page = context get_num_points_page()

#let _PAGE_SCORE_BOX = declare_function(
  "page-score-box",
  doc: "A box for the grader to write the score of the current page in, \"Score: ____ / 7\", made for a page footer: `#set page(footer: align(right, page-score-box()))`. Draws nothing on a page without points. Its word is `strings`' `score`.",
)

/// A score box for the current page (see DOCS).
#let page_score_box = define(_PAGE_SCORE_BOX, it => e.get(get => {
  let points = get_num_points_page()
  if points == 0 { return }
  let strings = get(config).strings
  box(stroke: .5pt, inset: (x: .6em, y: .4em))[
    #strings.score: #box(width: 2.5em, stroke: (bottom: .5pt), outset: (bottom: .15em)) / #points
  ]
}))

/// The page number as the page shows it, for the table by page.
#let _page_label(loc) = {
  let pattern = loc.page-numbering()
  numbering(if pattern == none { "1" } else { pattern }, ..counter(page).at(loc))
}

/// The cell a number of points is shown in; nothing for none.
#let _cell(points) = if points == none or points == 0 { [] } else { [#points] }

/// Lay out the points table: `entries` are `(label, points, bonus)`, one per
/// question or page, and `o` the table's options, resolved (see
/// `points_table`).
#let _points_table(entries, heading, o) = {
  let strings = o.strings
  let total = (
    label: strings.total,
    points: entries.map(x => x.points).sum(default: 0),
    bonus: entries.map(x => if x.bonus == none { 0 } else { x.bonus }).sum(default: 0),
  )
  let with_bonus = o.bonus and total.bonus > 0
  // The series the table shows, in order: each a heading and a cell per entry.
  let series = (
    (heading: heading, cell: x => x.label),
    (heading: strings.points, cell: x => [#x.points]),
    ..if with_bonus { ((heading: strings.bonus, cell: x => _cell(x.bonus)),) },
    ..if o.score { ((heading: strings.score, cell: x => [], score: true),) },
  )
  let table_of(entries) = if o.direction == "vertical" {
    table(
      // The score column is wide enough to write in.
      columns: if o.score { (auto,) * (series.len() - 1) + (4em,) } else { series.len() },
      align: center,
      stroke: .2pt,
      inset: .6em,
      ..series.map(s => s.heading),
      ..entries.map(x => series.map(s => (s.cell)(x))).flatten(),
    )
  } else {
    table(
      align: (right, ..(center,) * entries.len()),
      columns: entries.len() + 1,
      stroke: .2pt,
      inset: .6em,
      // The score row is tall enough to write in.
      ..if o.score { (rows: (auto,) * (series.len() - 1) + (2.5em,)) },
      ..series.map(s => ([#s.heading:], ..entries.map(s.cell))).flatten(),
    )
  }
  let entries = entries + (total,)
  let per = o.max-columns
  if per == none or o.direction == "vertical" {
    table_of(entries)
  } else {
    assert(per > 0, message: "examy: points-table: `max-columns` must be positive, found " + str(per))
    entries.chunks(per).map(table_of).join()
  }
}

#let _POINTS_TABLE = declare_function(
  "points-table",
  doc: "A scoring table with a column per question plus a total. Works anywhere in the document, even before the exam.\n\nEach argument left `auto` is `config`'s option of the same name, `points-table-..`, so that all of a document's tables can be set at once; its words are set by `strings`.",
  fields: (
    e.field(
      "direction",
      e.types.union(auto, "horizontal", "vertical"),
      doc: "`\"horizontal\"`, with a column per question, or `\"vertical\"`, with a row per question. `auto`: `config`'s `points-table-direction`.",
      default: auto,
    ),
    e.field(
      "by",
      e.types.union(auto, "question", "page"),
      doc: "Whether to total the points by question or by page; by page, a page without points is left out. `auto`: `config`'s `points-table-by`.",
      default: auto,
    ),
    e.field(
      "score",
      e.types.union(auto, bool),
      doc: "Whether to add an empty Score row (a column, when vertical) for the grader to fill in. `auto`: `config`'s `points-table-score`.",
      default: auto,
    ),
    e.field(
      "bonus",
      e.types.union(auto, bool),
      doc: "Whether to add a Bonus row (a column, when vertical) with the bonus points, when the exam has any. `auto`: `config`'s `points-table-bonus`.",
      default: auto,
    ),
    e.field(
      "max-columns",
      e.types.union(auto, int, none),
      doc: "The most questions (or pages) a horizontal table shows side by side; more are split into several tables, one below the other, with the total in the last. `none` keeps them all in one table. `auto`: `config`'s `points-table-max-columns`.",
      default: auto,
    ),
  ),
)

/// A scoring table showing the point value of each question (or page) (see
/// DOCS).
#let points_table = define(_POINTS_TABLE, it => e.get(get => {
  let cfg = get(config)
  // Each option as given, else `config`'s.
  let pick(key) = if it.at(key) == auto { cfg.at("points-table-" + key) } else { it.at(key) }
  let o = (
    strings: cfg.strings,
    direction: pick("direction"),
    by: pick("by"),
    score: pick("score"),
    bonus: pick("bonus"),
    max-columns: pick("max-columns"),
  )
  let strings = o.strings
  let (entries, heading) = if o.by == "page" {
    (
      _points_by_page()
        .filter(p => p.points > 0 or p.bonus > 0)
        .map(p => (label: _page_label(p.location), points: p.points, bonus: p.bonus)),
      strings.page,
    )
  } else {
    let data = exam_points_data()
    (
      if data == none { () } else {
        data.map(q => (label: q.label, points: q.total_points, bonus: q.total_bonus_points))
      },
      strings.question,
    )
  }
  if entries.len() == 0 {
    let missing = if o.by == "page" { "points" } else { "questions" }
    return text(fill: red, "WARNING: No " + missing + " found! Can't make a points table.")
  }
  _points_table(entries, heading, o)
}))

/// API documentation for this module's exports, consumed by
/// docs/api.typ (keyed by export name).
#let DOCS = (
  "points-table": _POINTS_TABLE,
  "num-questions": (
    desc: "The total number of questions in the exam, shown: `#num-questions`. Works anywhere in the document. To compute or test with it, `get-num-questions()` gives it as a number.",
  ),
  "num-points": (
    desc: "The total number of regular (non-bonus, non-practice) points, shown: `#num-points`. Works anywhere in the document. To compute or test with it, `get-num-points()` gives it as a number.",
  ),
  "num-bonus-points": (
    desc: "The total number of bonus points, shown: `#num-bonus-points`. Works anywhere in the document. To compute or test with it, `get-num-bonus-points()` gives it as a number.",
  ),
  "num-points-page": (
    desc: "The number of points on the current page, shown: the points of each question, part, and subpart that starts on it, e.g. in a page footer. To compute or test with it, or for another page or the bonus points, `get-num-points-page()` gives it as a number.",
  ),
  "get-num-questions": _GET_NUM_QUESTIONS,
  "get-num-points": _GET_NUM_POINTS,
  "get-num-bonus-points": _GET_NUM_BONUS_POINTS,
  "get-num-points-page": _GET_NUM_POINTS_PAGE,
  "page-score-box": _PAGE_SCORE_BOX,
)

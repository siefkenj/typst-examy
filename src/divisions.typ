/// Public constructors for questions, parts, and subparts.
///
/// These are deliberately plain functions (not elembic elements): they must
/// emit their markers *eagerly* so the exam pipeline can find them by content
/// introspection, before any layout happens. Their arguments are declared
/// with `e.field` all the same (see signature.typ), which both checks them
/// and documents them.

#import "prelude.typ": e
#import "markers.typ": begin_marker, end_marker, outside_check
#import "constants.typ": DEBUG_PANIC
#import "signature.typ": UNSET, declare_function, define, unset_or

/// The arguments of a question, part, or subpart, which take identical ones.
#let _DIVISION_FIELDS = (
  e.field(
    "body",
    e.types.union(content, str),
    doc: "The text of the question/part/subpart.",
    required: true,
  ),
  e.field(
    "points",
    e.types.union(int, float, none),
    doc: "The number of points (e.g. `points: 2` shows \"(2 points)\"). Points are counted in `#points-table()` and the other point totals.",
    default: none,
  ),
  e.field(
    "intent",
    e.types.union(e.types.literal("practice"), e.types.literal("bonus"), none),
    doc: "Setting to `\"bonus\"` counts the points as bonus points, which are totaled separately. Setting to `\"practice\"` leaves the points out of all totals.",
    default: none,
  ),
  e.field(
    "rubric",
    e.types.option(content),
    doc: "Rubric items for the question/part/subpart (see `#rubric[..]`). Text between the items is shown as a note for the grader. Rubric items written in the body are listed first.",
    default: none,
  ),
  e.field(
    "number",
    e.types.union(auto, int, str, content, none),
    doc: "Setting to `auto` numbers the question/part/subpart in order. An integer sets the number (later ones continue from it), content is shown as is, and `none` leaves the number out.",
    default: auto,
  ),
  e.field(
    "height",
    e.types.union(auto, length, fraction),
    doc: "The height of the question/part/subpart, including its parts. A length or fraction (e.g. `1fr`) makes it a single block of that height, which cannot break across pages.

    Note: to give room to write in, use an `#answer-box[..]` instead (e.g. `#answer-box(width: 100%, height: 3cm)[]`).",
    default: auto,
  ),
  e.field(
    "indent",
    e.types.smart(length),
    doc: "The indentation level to use for the question/part/subpart. Setting to `auto` uses `config`'s `indent`.",
    default: auto,
  ),
  e.field(
    "numbering",
    e.types.union(auto, str, function, e.types.array(e.types.union(str, function))),
    doc: "Determines how the question/part/subpart and those inside it are numbered. This option behaves like [`enum`'s `numbering`](https://typst.app/docs/reference/model/enum/#parameters-numbering), taking a numbering pattern (e.g. `\"1.a.i.\"`) or a function that generates a label. In addition, `numbering` also accepts an array of numbering patterns (e.g. `(\"Bonus 1.\", \"(i)\")`), with the left-most pattern applying to this question/part/subpart. Setting to `auto` uses the setting of the enclosing question/part, or `config`'s.",
    default: auto,
  ),
  e.field(
    "rubric-position",
    e.types.union(auto, "margin-right", "margin-left", "end"),
    doc: "Determines where the rubrics of this question/part/subpart and those inside it are displayed.

    `\"margin-right\"` or `\"margin-left\"`: in the page margin, next to the question/part/subpart they belong to (see `rubric-width`).

    `\"end\"`: after the question/part/subpart, taking up space on the page. When set to `\"end\"`, visible rubrics will take up space in the document.

    Setting to `auto` uses the setting of the enclosing question/part, or `config`'s.",
    default: auto,
  ),
  e.field(
    "rubric-trace",
    unset_or(auto, bool),
    doc: "Whether to draw a dotted line from each rubric item written in the text to the rubric, for this question/part/subpart and those inside it. Setting to `auto` draws lines only for rubrics in the margin. When not given, uses the setting of the enclosing question/part, or `config`'s.",
    default: UNSET,
    meta: (default-shown: "auto"),
  ),
  e.field(
    "rubric-width",
    unset_or(auto, length),
    doc: "The width of rubrics in the margin, for this question/part/subpart and those inside it. Setting to `auto` fills the margin. When not given, uses the setting of the enclosing question/part, or `config`'s.",
    default: UNSET,
    meta: (default-shown: "auto"),
  ),
  e.field(
    "label",
    e.types.option(label),
    doc: "A label for referencing the question/part/subpart with `@name` (e.g. `label: <derivative>`).",
    default: none,
    meta: (hint: "write it in angle brackets, e.g. `label: <my-label>`"),
  ),
)

/// The three take identical arguments and differ only in numbering style
/// (chosen by nesting depth, not by which function is called), so the API
/// reference documents them as one group instead of repeating the same
/// argument list three times.
#let _DIVISION_DOC = "Declare a question, part, or subpart — numbered `1.`, `(a)`, or `i.` respectively. The three functions take identical arguments; the numbering style is chosen by nesting depth, not by which function is called."

/// Names an author might reach for that the divisions do not take.
#let _ALIASES = (
  solution: "write the solution in the body, as `#solution[..]`, where it should be drawn",
)

#let _spec(name) = declare_function(
  name,
  doc: _DIVISION_DOC,
  fields: _DIVISION_FIELDS,
  aliases: _ALIASES,
  group: "division",
)

#let _division(spec) = define(spec, it => {
  begin_marker((
    points: it.points,
    intent: it.intent,
    rubric: it.rubric,
    number: it.number,
    height: it.height,
    indent: it.indent,
    numbering: it.numbering,
    rubric-position: it.rubric-position,
    rubric-trace: it.rubric-trace,
    rubric-width: it.rubric-width,
    label: it.label,
    name: spec.name,
  ))
  // A warning, drawn if no exam lays the division out (see `outside_check`);
  // left out with `--input _debug_panic=none`.
  if DEBUG_PANIC != "none" { outside_check(spec.name, it.body) }
  [#it.body]
  end_marker()
})

#let _QUESTION = _spec("question")
#let _PART = _spec("part")
#let _SUBPART = _spec("subpart")

/// Declare a question. Nesting `part`/`subpart` inside the body creates
/// sub-divisions; the nesting depth (not the constructor name) determines
/// the numbering style.
#let question = _division(_QUESTION)

/// Declare a part of a question.
#let part = _division(_PART)

/// Declare a subpart of a part.
#let subpart = _division(_SUBPART)

/// API documentation for this module's exports, consumed by docs/api.typ
/// (keyed by export name).
#let DOCS = (question: _QUESTION, part: _PART, subpart: _SUBPART)

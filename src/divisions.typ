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
    doc: "The body of the question.",
    required: true,
  ),
  e.field(
    "points",
    e.types.union(int, float, none),
    doc: "The number of points: shows a \"(2 points)\" badge and feeds the points table.",
    default: none,
  ),
  e.field(
    "intent",
    e.types.union(e.types.literal("practice"), e.types.literal("bonus"), none),
    doc: "Practice and bonus points are excluded from the regular totals; bonus points are tallied separately.",
    default: none,
  ),
  e.field(
    "rubric",
    e.types.option(content),
    doc: "The division's rubric, or the part of it not tied to a place in its body: `rubric`s, and text between them as notes for the grader. Rubrics written in the body come first, then these. See `rubric`.",
    default: none,
  ),
  e.field(
    "number",
    e.types.union(auto, int, str, content, none),
    doc: "`auto` numbers sequentially; an integer is the number as displayed (later divisions continue from it); content is shown verbatim; `none` omits the number.",
    default: auto,
  ),
  e.field(
    "height",
    e.types.union(auto, length, fraction),
    doc: "How tall the division is, its parts included. `auto` (the default) is as tall as what it holds. A length, or a fraction such as `1fr` (a share of what is left of the page, as an answer box's), makes it one block of that height: `fr` answer boxes inside it share what its own text leaves of it, and the exam lays it out whole. Being one block, it cannot break across pages: a `#pagebreak()` inside it is an error. Content taller than the `height` runs out of the block, over what comes after it.\n\nTo give a question room to write in, prefer an answer box: `#answer-box(width: 100%, height: 3cm)[]`, or with `stroke: none` for blank space with no border.",
    default: auto,
  ),
  e.field(
    "indent",
    e.types.smart(length),
    doc: "How far the body is indented from the question or part it is in. `auto` is `config`'s `indent`, which is `1.5em` unless it is set.",
    default: auto,
  ),
  e.field(
    "numbering",
    e.types.union(auto, str, function, e.types.array(e.types.union(str, function))),
    doc: "How it is numbered, and the parts and subparts in it, as `config`'s `numbering` takes it, whose levels count from the question: `question(numbering: (\"Bonus 1.\", \"(i)\"))` numbers the question \"Bonus 1.\" and its parts \"(i)\", \"(ii)\". A reference to it, or to a part in it, is numbered so too. `auto` is that of the question or part it is in, or `config`'s.",
    default: auto,
  ),
  e.field(
    "rubric-position",
    e.types.union(auto, "margin-right", "margin-left", "end"),
    doc: "Where its rubric is drawn, and those of the parts and subparts in it, as `config`'s `rubric-position` says. `auto` is as the question or part it is in has them, or as `config` says.",
    default: auto,
  ),
  e.field(
    "rubric-trace",
    unset_or(auto, bool),
    doc: "Whether the rubrics written in its body, and in those of its parts and subparts, are traced to their items, as `config`'s `rubric-trace` says. Left out, it is as the question or part it is in has it, or as `config` says.",
    default: UNSET,
    meta: (default-shown: "auto"),
  ),
  e.field(
    "rubric-width",
    unset_or(auto, length),
    doc: "The width of its rubric in the margin, and those of its parts and subparts, as `config`'s `rubric-width` says. Left out, it is as the question or part it is in has it, or as `config` says.",
    default: UNSET,
    meta: (default-shown: "auto"),
  ),
  e.field(
    "label",
    e.types.option(label),
    doc: "Attach a label so the division can be referenced with `@name`.",
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

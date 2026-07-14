/// Public constructors for questions, parts, and subparts.
///
/// These are deliberately plain functions (not elembic elements): they must
/// emit their markers *eagerly* so the exam pipeline can find them by content
/// introspection, before any layout happens.

#import "markers.typ": begin_marker, end_marker

#let _division(
  body,
  points: none,
  intent: none,
  solution: none,
  rubric: none,
  number: auto,
  indent: 1.5em,
  label: none,
  name: "division",
) = {
  assert(
    type(body) in (content, str),
    message: "examy: the body of a " + name + " must be content, found " + repr(type(body)),
  )
  assert(
    points == none or type(points) in (int, float),
    message: "examy: `points` must be a number or none, found " + repr(points),
  )
  assert(
    intent in (none, "practice", "bonus"),
    message: "examy: `intent` must be none, \"practice\", or \"bonus\", found " + repr(intent),
  )
  assert(
    number == auto or number == none or type(number) in (int, str, content),
    message: "examy: `number` must be auto, none, an integer, or content, found " + repr(number),
  )
  assert(
    label == none or type(label) == std.label,
    message: "examy: `label` must be a label (e.g. `<my-label>`) or none, found " + repr(label),
  )
  assert(
    type(indent) == length,
    message: "examy: `indent` must be a length, found " + repr(indent),
  )

  begin_marker((
    points: points,
    intent: intent,
    solution: solution,
    rubric: rubric,
    number: number,
    indent: indent,
    label: label,
    name: name,
  ))
  [#body]
  end_marker()
}

/// Declare a question. Nesting `part`/`subpart` inside the body creates
/// sub-divisions; the nesting depth (not the constructor name) determines
/// the numbering style.
#let question = _division.with(name: "question")

/// Declare a part of a question.
#let part = _division.with(name: "part")

/// Declare a subpart of a part.
#let subpart = _division.with(name: "subpart")

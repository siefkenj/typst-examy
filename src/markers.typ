/// Stream markers: `question`/`part`/`subpart` emit these `metadata` values
/// inline (begin ... body ... end) instead of doing any layout. The exam
/// pipeline later tokenizes the stream and reconstructs the structure.

/// Version tag for the marker format; bump when the format changes.
#let MARKER_V = 1
#let MARKER_KEY = "_examy_marker"

/// Default fields carried by a `begin` marker.
#let DIVISION_FIELD_DEFAULTS = (
  points: none,
  intent: none,
  rubric: none,
  number: auto,
  height: auto,
  indent: 1.5em,
  label: none,
  // Name of the constructor ("question"/"part"/...); used only for diagnostics.
  name: "division",
)

/// Marker for the start of a division. `fields` are the user-supplied
/// division fields (points, number, label, ...).
#let begin_marker(fields) = metadata((
  "_examy_marker": MARKER_V,
  kind: "begin",
  fields: DIVISION_FIELD_DEFAULTS + fields,
))

/// Marker for the end of a division.
#let end_marker() = metadata(("_examy_marker": MARKER_V, kind: "end"))

/// Hint emitted by elements (like `answer-box`) whose rendered height cannot
/// be determined by content introspection (e.g. because it is produced by a
/// lazy `show` rule). The scanner uses these to propagate `fr` heights.
#let height_hint(height) = metadata((
  "_examy_marker": MARKER_V,
  kind: "height",
  height: height,
))

/// Return the marker dictionary if `c` is examy marker metadata, else `none`.
#let marker_value(c) = {
  if type(c) != content { return none }
  if c.func() != metadata { return none }
  let v = c.at("value", default: none)
  if type(v) == dictionary and v.at(MARKER_KEY, default: none) == MARKER_V {
    v
  } else {
    none
  }
}

/// The key of the data a `rubric` carries in its marker, and the label the
/// marker is placed with (see rubric.typ). A rubric is not a division
/// marker: it travels through the pipeline as part of a chunk, and is
/// invisible wherever it is placed.
#let RUBRIC_KEY = "_examy_rubric"
#let RUBRIC_LABEL = label("_examy_rubric")

/// A rubric marker: `metadata` holding the rubric's data, so that the same
/// call can be read where it is written (a division's `rubric:` field) and
/// found where it is placed (in the body, by a query).
#let rubric_marker(data) = [#metadata(((RUBRIC_KEY): MARKER_V, ..data))#RUBRIC_LABEL]

/// The data of a rubric marker, if `c` is one, else `none`.
#let rubric_value(c) = {
  if type(c) != content or c.func() != metadata { return none }
  let v = c.at("value", default: none)
  if type(v) == dictionary and v.at(RUBRIC_KEY, default: none) == MARKER_V { v } else { none }
}

/// The key of a rubric hint: an invisible mark that content holding rubrics
/// where they cannot be seen (an `answer-box`'s `solution:`, inside a
/// `context`) leaves beside them, for `has_any_rubric` to find. It is not a
/// rubric, and is placed with no label.
#let RUBRIC_HINT_KEY = "_examy_rubric_hint"
#let rubric_hint = metadata(((RUBRIC_HINT_KEY): MARKER_V))

/// Whether `c` is a rubric hint.
#let is_rubric_hint(c) = {
  if type(c) != content or c.func() != metadata { return false }
  let v = c.at("value", default: none)
  type(v) == dictionary and v.at(RUBRIC_HINT_KEY, default: none) == MARKER_V
}

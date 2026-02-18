#let _config = toml("../typst.toml")
#let version = _config.package.version
#let package_name = _config.package.name
/// Elembic prefix for this package.
#let PREFIX = "@preview/" + package_name + ",v" + version

/// Value used for determining if a key is in a dictionary.
#let NOT_FOUND_SENTINEL = () => {}
#let _GLOBALS = state(PREFIX + "/globals", (
  // XXX: not used, can delete
  all_questions: (),
  // XXX: not used, can delete
  num_divisions: 0,
  current_address: (),
))

#let HIERARCHY = ("question", "part", "subpart")
#let ALLOWED_CHILDREN = (
  "question": ("part", "subpart"),
  "part": ("subpart",),
  "subpart": (),
)
#let PARENTS = (
  "part": "question",
  "subpart": "part",
)
#let SHOW_SOLUTIONS_OVERRIDE = sys.inputs.at("show-solutions", default: none)
#let SHOW_SOLUTIONS_OVERRIDE = if SHOW_SOLUTIONS_OVERRIDE == "true" { true } else if (
  SHOW_SOLUTIONS_OVERRIDE == "false"
) { false } else { none }
#let SHOW_RUBRIC_OVERRIDE = sys.inputs.at("show-rubric", default: none)
#let SHOW_RUBRIC_OVERRIDE = if SHOW_RUBRIC_OVERRIDE == "true" { true } else if (
  SHOW_RUBRIC_OVERRIDE == "false"
) { false } else { none }

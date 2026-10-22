#let _config = toml("../typst.toml")
#let version = _config.package.version
#let package_name = _config.package.name
/// Elembic prefix for this package.
#let PREFIX = "@preview/" + package_name + ",v" + version

/// A `--input name=true|false` flag as a bool; `none` when it is absent.
/// `alias`, its name in the singular, is read too, so that either spelling
/// works; given both, they must agree. Any other value is an error.
#let _bool_input(name, alias: none) = {
  let read(name) = {
    let value = sys.inputs.at(name, default: none)
    assert(
      value in (none, "true", "false"),
      message: "examy: `--input " + name + "` must be `true` or `false`, got `" + repr(value).trim("\"") + "`",
    )
    if value == none { none } else { value == "true" }
  }
  let value = read(name)
  if alias == none { return value }
  let other = read(alias)
  assert(
    value == none or other == none or value == other,
    message: "examy: `--input " + name + "` and `--input " + alias + "` are the same option, and disagree",
  )
  if value == none { other } else { value }
}

#let SHOW_SOLUTIONS_OVERRIDE = _bool_input("show-solutions", alias: "show-solution")
#let SHOW_RUBRICS_OVERRIDE = _bool_input("show-rubrics", alias: "show-rubric")

/// `--input _debug_panic=..`: what the check every question carries does
/// when no exam lays the question out (see `outside_check`).
/// `"text-warning"` (the default) shows a warning in red where it is;
/// `"panic"` fails the compile, for a build that must not produce a
/// document with one; `"none"` leaves the check out of every question.
#let DEBUG_PANIC = {
  let value = sys.inputs.at("_debug_panic", default: "text-warning")
  let modes = ("text-warning", "panic", "none")
  assert(
    value in modes,
    message: "examy: `--input _debug_panic` must be " + modes.map(m => "`" + m + "`").join(", ", last: ", or ") + ", got `" + value + "`",
  )
  value
}

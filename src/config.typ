#import "types.typ": *

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
      doc: "Whether to show solutions",
    ),
    e.field(
      "show-rubric",
      e.types.option(bool),
      doc: "Whether to show a rubric",
    ),
    e.field(
      "solution-background-color",
      color,
      doc: "The background color to use for solution boxes",
      default: blue.lighten(90%),
    ),
    e.field(
      "solution-text-color",
      color,
      doc: "The text color to use for solution boxes",
      default: blue.darken(20%),
    ),
  ),
)

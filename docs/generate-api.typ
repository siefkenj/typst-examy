// Generates the package's API reference as a Markdown string, exposed via
// `#metadata(..) <api>` so it can be extracted with `typst query` (see
// make_docs.sh).
//
// The list of exports is not maintained anywhere: it is `dictionary(lib)`,
// so a name added to (or removed from) src/lib.typ shows up here
// automatically, in lib.typ's order. Documentation comes from two places:
// - elembic elements are introspected with `e.data(...)` — their one-line
//   docs, argument types, defaults, and required flags come straight from
//   the element declarations;
// - plain functions cannot be introspected (Typst has no reflection for
//   function signatures), so each module documents its own exports in a
//   `DOCS` dict (keyed by export name) next to the definitions.
// An export with no DOCS entry fails the build, so nothing can ship
// undocumented.

#import "/src/lib.typ"
#import "/src/types.typ": e
#import "/src/divisions.typ" as m-divisions
#import "/src/elements/other-answer-box.typ" as m-answer-box
#import "/src/elements/exam.typ" as m-exam
#import "/src/elements/solution.typ" as m-solution
#import "/src/config.typ" as m-config
#import "/src/points.typ" as m-points
#import "/src/presets.typ" as m-presets

/// Per-export documentation, merged from every module's `DOCS`. The only
/// entry living here is `e`, since it documents lib.typ's re-export itself.
#let REGISTRY = (
  m-divisions.DOCS
    + m-answer-box.DOCS
    + m-exam.DOCS
    + m-solution.DOCS
    + m-config.DOCS
    + m-points.DOCS
    + m-presets.DOCS
    + (
      e: (
        desc: "A re-export of [elembic](https://typst.app/universe/package/elembic). Every document needs `#show: e.prepare()`; options are set with `#show: e.set_(config, ..)`; element state is read with `e.get(get => ..)`.",
      ),
    )
)

/// Render an elembic typeinfo in TypeScript style: unions become
/// `a | b | none` (with `none` hoisted last) instead of "none or a or b".
#let ts_type(ti) = {
  let kind = ti.at("type-kind", default: none)
  if kind == "union" {
    let parts = ti.data.map(ts_type)
    let rest = parts.filter(p => p != "none")
    let nones = parts.filter(p => p == "none")
    (rest + nones).join(" | ")
  } else if kind == "native" {
    (
      boolean: "bool",
      integer: "int",
      string: "str",
    ).at(ti.name, default: ti.name)
  } else if kind == "any" {
    "any"
  } else if kind == "literal" {
    repr(ti.at("data", default: ti.at("name", default: "?")))
  } else {
    // Fall back to elembic's own name, pipe-ified.
    ti.at("name", default: "any").replace(" or ", " | ")
  }
}

/// Every export of src/lib.typ, in lib.typ's order, joined with its
/// documentation. Kinds are derived: `element` if the DOCS entry says so
/// (arguments are then introspected from the value), `function` if the
/// entry has args, `value` otherwise.
#let EXPORTS = (
  dictionary(lib)
    .pairs()
    .map(((name, value)) => {
    assert(
      name in REGISTRY,
      message: "no API documentation for export `"
        + name
        + "` — add an entry to the DOCS dict next to its definition",
    )
    let info = REGISTRY.at(name)
    let kind = if info.at("kind", default: none) == "element" {
      "element"
    } else if "args" in info {
      "function"
    } else {
      "value"
    }
    (name: name, value: value, kind: kind, ..info)
  })
)

/// One argument in a signature: required positional args appear bare,
/// required named args as `name: ..`, optional args as `name: default`.
#let sig_arg(a) = {
  let required = a.at("required", default: false)
  let named = a.at("named", default: not required)
  if required and not named {
    a.name
  } else if required {
    a.name + ": .."
  } else {
    a.name + ": " + a.default
  }
}

/// The full call signature for an export.
#let signature(name, args) = {
  name + "(" + args.map(sig_arg).join(", ") + ")"
}

/// Markdown list item for one argument spec:
/// (name: str, type: str, doc: str, required: bool or default: str).
#let arg_item(a) = {
  let head = if a.at("required", default: false) {
    "`" + a.name + ": " + a.type + "` (required)"
  } else {
    "`" + a.name + ": " + a.type + " = " + a.default + "`"
  }
  "- " + head + " — " + a.doc.replace("\n", " ")
}

/// Convert an elembic field spec into an argument spec.
#let field_to_arg(f) = (
  name: f.name,
  type: ts_type(f.typeinfo),
  required: f.required,
  named: f.named,
  default: if f.required { none } else { repr(f.at("default", default: none)) },
  doc: f.doc + if f.doc.ends-with(".") { "" } else { "." },
)

/// Markdown for one export.
#let entry_md(entry) = {
  let lines = ()
  let args = entry.at("args", default: ())
  let desc = entry.at("desc", default: none)
  let tag = ""
  if entry.kind == "element" {
    let data = e.data(entry.value)
    if desc == none {
      desc = data.doc
      if not desc.ends-with(".") { desc += "." }
    }
    args = data
      .at("user-fields")
      .values()
      .filter(f => not f.at("internal", default: false))
      .map(field_to_arg)
    tag = " (elembic element)"
  }
  let head = if entry.kind == "value" or not entry.at("show-signature", default: true) {
    entry.name
  } else {
    signature(entry.name, args)
  }
  lines.push("### `" + head + "`" + tag)
  lines.push("")
  lines.push(desc)
  if args.len() > 0 {
    lines.push("")
    lines += args.map(arg_item)
  }
  lines.join("\n")
}

// The generated Markdown is spliced into README.md between the
// API-DOCS-START/END markers by make_docs.sh, inside the "## API Reference"
// section — so entries are `###` headings and there is no title here.
#let md = (
  "All names below are exported by `#import \"@preview/examy:"
    + toml("/typst.toml").package.version
    + "\": *`."
    + "\n\n"
    + EXPORTS.map(entry_md).join("\n\n")
)

#metadata(md) <api>

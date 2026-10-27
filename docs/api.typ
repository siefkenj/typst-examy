// The package's API, as data: one entry per export of src/lib.typ, with its
// description, its signature, and its arguments. Read by readme-api.typ (the
// README's index of exports) and by the documentation site (site.typ).
//
// Nothing here is written by hand except the list of modules to read. The
// exports are `dictionary(lib)`, so a name added to (or removed from)
// src/lib.typ shows up here automatically, in lib.typ's order. Their
// documentation comes from each module's `DOCS`, keyed by export name:
// - an elembic element (`(kind: "element")`) is introspected with
//   `e.data(..)`: its doc and its fields' types, defaults and docs come
//   straight from the element declaration;
// - a plain function is declared with `declare_function` (see
//   src/signature.typ), whose fields are `e.field`s like an element's, and
//   which is the very spec that checks the function's arguments;
// - a value (`(desc: ..)`) has a description only;
// - an alias (`(alias-of: name, with: (..))`) is another export with some
//   arguments fixed.
// An export with no DOCS entry fails the build, so nothing can ship
// undocumented.

#import "/src/lib.typ"
#import "/src/prelude.typ": e
#import "/src/signature.typ": describe_type
#import "/src/divisions.typ" as m-divisions
#import "/src/elements/answer-box.typ" as m-answer-box
#import "/src/elements/bubble.typ" as m-bubble
#import "/src/elements/choices.typ" as m-choices
#import "/src/elements/exam.typ" as m-exam
#import "/src/elements/solution.typ" as m-solution
#import "/src/config.typ" as m-config
#import "/src/points.typ" as m-points
#import "/src/presets.typ" as m-presets
#import "/src/rubric.typ" as m-rubric

/// The package version, for import lines.
#let VERSION = toml("/typst.toml").package.version

/// The line that imports the package.
#let IMPORT = "#import \"@preview/examy:" + VERSION + "\": *"

/// Per-export documentation, merged from every module's `DOCS`. The only
/// entry living here is `e`, since it documents lib.typ's re-export itself.
#let REGISTRY = (
  m-divisions.DOCS
    + m-answer-box.DOCS
    + m-bubble.DOCS
    + m-choices.DOCS
    + m-exam.DOCS
    + m-solution.DOCS
    + m-config.DOCS
    + m-points.DOCS
    + m-presets.DOCS
    + m-rubric.DOCS
    + (
      e: (
        desc: "A re-export of [elembic](https://typst.app/universe/package/elembic), mainly for `e.set_` and `e.get` (e.g. `#show: e.set_(config, ..)`). Use it rather than importing elembic yourself.",
      ),
    )
)

/// `s`, ending in a full stop.
#let _sentence(s) = if s.ends-with(".") { s } else { s + "." }

/// A default value as code. `repr` gives a length in points (`2cm` is
/// `56.69pt`), so a length is written in the first of `in`, `cm`, `mm`, and
/// `pt` that gives it in at most two decimals, as it was most likely written.
#let show_value(v) = {
  if type(v) != length or v.abs == 0pt { return repr(v) }
  let abs = v.abs
  let written = none
  for (unit, size) in (("in", 1in), ("cm", 1cm), ("mm", 1mm), ("pt", 1pt)) {
    let x = abs / size
    if calc.abs(x - calc.round(x, digits: 2)) < 1e-6 {
      written = str(calc.round(x, digits: 2)) + unit
      break
    }
  }
  if written == none { return repr(v) }
  if v.em == 0 { written } else { repr(v.em) + "em + " + written }
}

/// One argument, from an `e.field` (an element's or a function's):
/// `(name, type, doc, required, named, variadic, default)`, where `type` and
/// `default` are written as Typst code (`default` is `none` for a required
/// argument). `variadic` is false: only a function's `rest` is (see
/// EXPORTS).
/// A field's `meta` can give either as it is to be shown, as `type-shown` or
/// `default-shown`: a type that takes more than is documented, say.
#let field_to_arg(f) = (
  name: f.name,
  type: f.meta.at("type-shown", default: describe_type(f.typeinfo)),
  required: f.required,
  named: f.named,
  variadic: false,
  default: if f.required { none } else {
    f.meta.at("default-shown", default: show_value(f.at("default", default: none)))
  },
  doc: _sentence(f.doc),
)

/// The arguments of a set of fields, leaving out internal ones.
#let _args(fields) = fields.filter(f => not f.at("internal", default: false)).map(field_to_arg)

/// Every export of src/lib.typ, in lib.typ's order, as
/// `(name, kind, desc, args, show-signature, group, alias-of, with)`.
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
      let kind = info.at("kind", default: none)
      let entry = (
        name: name,
        kind: "value",
        desc: info.at("desc", default: none),
        args: (),
        show-signature: info.at("show-signature", default: true),
        group: info.at("group", default: none),
        alias-of: info.at("alias-of", default: none),
        with: info.at("with", default: (:)),
      )
      if kind == "element" {
        let data = e.data(value)
        entry.kind = "element"
        if entry.desc == none { entry.desc = _sentence(data.doc) }
        entry.args = _args(data.at("user-fields").values())
      } else if kind == "function" {
        entry.kind = "function"
        entry.desc = _sentence(info.doc)
        entry.args = _args(info.fields.values())
        // Named arguments taken beyond its fields (`exam`'s `config`
        // options): `..name` in the signature, documented as one, with no
        // type of its own (each is checked against its own field).
        let rest = info.at("rest", default: none)
        if rest != none {
          entry.args.push((
            name: rest.name,
            type: none,
            doc: _sentence(rest.doc),
            required: false,
            named: true,
            variadic: true,
            default: none,
          ))
        }
      } else if entry.alias-of != none {
        entry.kind = "alias"
      }
      entry
    })
)

/// EXPORTS with those sharing a `group` (e.g. `question`/`part`/`subpart`,
/// which take identical arguments) collapsed into one entry, documented once
/// with one signature per name in `names`; in alphabetical order, a group
/// by its first name (`question`).
#let ENTRIES = {
  let names_by_group = (:)
  for entry in EXPORTS {
    if entry.group != none {
      names_by_group.insert(entry.group, names_by_group.at(entry.group, default: ()) + (entry.name,))
    }
  }
  let seen = (:)
  let out = ()
  for entry in EXPORTS {
    if entry.group == none {
      out.push((..entry, names: (entry.name,)))
    } else if entry.group not in seen {
      seen.insert(entry.group, true)
      out.push((..entry, names: names_by_group.at(entry.group)))
    }
  }
  out.sorted(key: x => x.names.first())
}

/// The entry documenting the export `name` (which may be one of a group).
#let entry(name) = ENTRIES.find(x => name in x.names)

/// An argument's name as written in a call: `..name` for any number of them
/// (a function's `rest`), else its name.
#let arg_name(a) = if a.variadic { ".." + a.name } else { a.name }

/// One argument in a signature: a positional one appears bare (an optional
/// one, like a bubble's content, shows its default in the argument list
/// instead), a required named one as `name: ..`, an optional named one as
/// `name: default`, and any number of them (a function's `rest`) as `..name`.
#let sig_arg(a) = {
  if a.variadic {
    arg_name(a)
  } else if not a.named {
    a.name
  } else if a.required {
    a.name + ": .."
  } else {
    a.name + ": " + a.default
  }
}

/// The call signature of `name`, an export taking `args`.
#let signature(name, args) = name + "(" + args.map(sig_arg).join(", ") + ")"

/// The signatures to show for an entry: one per name, or the bare name for a
/// value, an alias, or an entry that is not called (`config`).
#let signatures(entry) = {
  if entry.kind in ("value", "alias") or not entry.show-signature {
    return entry.names
  }
  entry.names.map(n => signature(n, entry.args))
}

/// What an alias is: its target with the fixed arguments, as code.
#let alias_code(entry) = (
  entry.alias-of + ".with(" + entry.with.pairs().map(((k, v)) => k + ": " + repr(v)).join(", ") + ")"
)

/// The first sentence of `s`, for a one-line summary. The full stops of
/// "e.g." and "i.e." do not end it.
#let summary(s) = {
  let m = s.match(regex("^(e\.g\.|i\.e\.|.)*?[.!?](\s|$)"))
  if m == none { s } else { m.text.trim() }
}

/// The page of an entry on the documentation site, relative to the site's
/// root (see site/template.typ); the README's index links to it.
#let page_path(entry) = "reference/" + entry.names.first() + ".html"

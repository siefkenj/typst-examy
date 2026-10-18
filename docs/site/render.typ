// How an example's code becomes a document: shared by the site's examples
// (see `example` in template.typ) and by anything else that compiles one,
// such as an interactive editor, so that an example compiles the same way
// everywhere. Needs only the package itself.

#import "/src/lib.typ"
#import "/src/prelude.typ": e

/// Lines an example may start with that set the document up rather than
/// belong to the exam: they stay outside the `exam(..)` an example is wrapped
/// in.
#let _SETUP = regex("^\s*(#(show|set|let|import)\b|//|$)")

/// How many more brackets `line` opens than it closes.
#let _depth(line) = line.matches(regex("[(\[{]")).len() - line.matches(regex("[)\]}]")).len()

/// Split an example's source into its setup lines and the rest. A setup
/// line's brackets left open take the lines up to their closing with it, so
/// that a `#show` rule over several lines stays whole.
#let _split(src) = {
  let lines = src.split("\n")
  let n = 0
  let depth = 0
  while n < lines.len() and (depth > 0 or lines.at(n).match(_SETUP) != none) {
    depth += _depth(lines.at(n))
    n += 1
  }
  (lines.slice(0, n).join("\n", default: ""), lines.slice(n).join("\n", default: ""))
}

/// Whether an example has anything that only the answer key shows.
#let has_key(src) = (
  src.contains("solution") or src.contains("correct") or src.match(regex("(?m)^\s*\+ ")) != none
)

/// The source an example is compiled from: its own, less the import line
/// (the package is in scope already) and any `show-solutions:` it sets (the
/// view decides), wrapped in an `exam(..)` when `wrap` is `true`, or when it
/// is `auto` and the code holds questions but no exam.
#let compiled_source(src, wrap: auto) = {
  let src = src.split("\n").filter(l => not l.trim().starts-with("#import \"@preview/examy")).join("\n")
  let src = src.replace(regex("show-solutions:\s*(true|false)\s*,?\s*"), "")
  let wrap = if wrap == auto { src.contains("#question") and not src.contains("#exam(") } else { wrap }
  if not wrap { return src }
  let (setup, body) = _split(src)
  setup + "\n#exam(questions: [\n" + body + "\n])"
}

/// Whether a line imports examy.
#let _is_import(line) = line.trim().starts-with("#import \"@preview/examy")

/// An example as a whole document, which compiles as it is in a document of
/// its own: the example, with what the site supplies around it written out.
/// That is the line importing examy, at `version`; `e.prepare()`; for an
/// example with an answer key, the `show-solutions` setting that picks it;
/// and the `exam(..)` the example is wrapped in when it is compiled (see
/// `compiled_source`), its questions indented within it. What the example
/// has of these already is kept as it is.
#let full_source(src, version, wrap: auto) = {
  let lines = src.split("\n")
  let imports = lines.filter(_is_import)
  let rest = lines.filter(l => not _is_import(l))
  // Leading blank lines would be left between the header and the code.
  while rest.len() > 0 and rest.first().trim() == "" { rest = rest.slice(1) }
  let rest = rest.join("\n")

  let header = if imports.len() > 0 { imports } else { ("#import \"@preview/examy:" + version + "\": *",) }
  let settings = ()
  if not src.contains("e.prepare()") { settings.push("#show: e.prepare()") }
  if has_key(src) and not src.contains("show-solutions:") {
    settings.push("#show: e.set_(config, show-solutions: false) // true for the answer key")
  }

  let wrap = if wrap == auto { rest.contains("#question") and not rest.contains("#exam(") } else { wrap }
  // The example's own setup lines stay before the exam; its questions go in.
  let (setup, code) = if wrap { _split(rest) } else { ("", rest) }
  let code = if wrap {
    let indented = code.trim().split("\n").map(l => if l.trim() == "" { "" } else { "  " + l })
    "#exam(questions: [\n" + indented.join("\n") + "\n])"
  } else { code }
  // In blocks, a blank line apart.
  (header.join("\n"), settings.join("\n", default: ""), setup.trim(), code.trim()).filter(b => b != "").join("\n\n")
}

/// An example compiled as the exam (`solutions: false`) or as its answer key,
/// on a page `width` wide and `height` high (`none`: as high as it is), with
/// `inset` around it for what is drawn outside the page's text, such as a
/// label run out into the margin: a length for the left side, or a
/// dictionary of sides. A little room is kept below the last line in any
/// case, for its descenders.
#let render(src, solutions: false, wrap: auto, width: 12cm, height: none, inset: 0pt) = {
  show: e.prepare()
  show: e.set_(lib.config, show-solutions: solutions)
  set text(size: 11pt)
  let height = if height == none { auto } else { height }
  let inset = if type(inset) == dictionary { inset } else { (left: inset) }
  block(
    inset: (bottom: .3em, ..inset),
    block(width: width, height: height, eval(compiled_source(src, wrap: wrap), mode: "markup", scope: dictionary(lib))),
  )
}

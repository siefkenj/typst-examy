// How an example's code becomes a document: shared by the site's examples
// (see `example` in template.typ) and by anything else that compiles one,
// such as an interactive editor, so that an example compiles the same way
// everywhere. Needs only the package itself.

#import "/src/lib.typ"
#import "/src/prelude.typ": e

/// Lines an example may start with that set the document up rather than
/// belong to the exam: they stay outside the `exam[..]` an example is wrapped
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

/// Whether an example lays out its own exam: `#exam[..]`, `#exam(..)`, or
/// `#show: exam` (or `exam.with(..)`).
#let _has_exam(src) = src.match(regex("#exam[\\[(]|#show:\\s*exam\\b")) != none

/// Whether an example has anything that only the answer key shows.
#let has_key(src) = (
  src.contains("solution") or src.contains("correct") or src.match(regex("(?m)^\s*\+ ")) != none
)

/// The source an example is compiled from: its own, less the import line
/// (the package is in scope already) and any `show-solutions:` it sets (the
/// view decides), wrapped in an `exam[..]` when `wrap` is `true`, or when it
/// is `auto` and the code holds questions but no exam.
#let compiled_source(src, wrap: auto) = {
  let src = src.split("\n").filter(l => not l.trim().starts-with("#import \"@preview/examy")).join("\n")
  let src = src.replace(regex("show-solutions:\s*(true|false)\s*,?\s*"), "")
  let wrap = if wrap == auto { src.contains("#question") and not _has_exam(src) } else { wrap }
  if not wrap { return src }
  let (setup, body) = _split(src)
  setup + "\n#exam[\n" + body + "\n]"
}

/// Whether a line imports examy.
#let _is_import(line) = line.trim().starts-with("#import \"@preview/examy")

/// Where the comment at the end of a line of code starts, its `//`; `none`
/// if it has none. A `//` in a string, or in a URL (`https://`), does not
/// start one.
#let _comment_start(line) = {
  let in_string = false
  let escaped = false
  // The byte offset of `ch`, and the character before it.
  let at = 0
  let prev = none
  for ch in line.clusters() {
    if in_string {
      if escaped { escaped = false } else if ch == "\\" { escaped = true } else if ch == "\"" { in_string = false }
    } else if ch == "\"" {
      in_string = true
    } else if ch == "/" and prev == "/" and not line.slice(0, at - 1).ends-with(":") {
      return at - 1
    }
    prev = ch
    at += ch.len()
  }
  none
}

/// An example as a whole document, which compiles as it is in a document of
/// its own: the example, with what the site supplies around it written out.
/// That is the line importing examy, at `version`, and, for an example
/// without an exam of its own, `#show: exam` after its setup lines (see
/// `compiled_source`). For an example with an answer key, the exam is given
/// the `show-solutions` setting that picks it. What the example has of these
/// already is kept as it is.
#let full_source(src, version, wrap: auto) = {
  let lines = src.split("\n")
  let imports = lines.filter(_is_import)
  let rest = lines.filter(l => not _is_import(l))
  // Leading blank lines would be left between the header and the code.
  while rest.len() > 0 and rest.first().trim() == "" { rest = rest.slice(1) }
  let rest = rest.join("\n")

  let header = if imports.len() > 0 { imports } else { ("#import \"@preview/examy:" + version + "\": *",) }
  // The setting that picks the view, for an example with an answer key.
  let pick = has_key(src) and not src.contains("show-solutions:")
  let note = " // true for the answer key"

  let wrap = if wrap == auto { rest.contains("#question") and not _has_exam(rest) } else { wrap }
  // The example's own setup lines stay before the exam's show rule.
  let (setup, code) = if wrap { _split(rest) } else { ("", rest) }
  let rule = if wrap { if pick { "#show: exam.with(show-solutions: false)" + note } else { "#show: exam" } }
  let code = if wrap or not pick {
    code
  } else {
    // The example's own `#show: exam` takes the setting: `head` is the rule
    // up to `exam`, `with` its `.with(` if it has one, and `rest` what
    // follows, its arguments and a comment, which the note goes before.
    let lines = code.split("\n")
    let i = lines.position(l => l.match(regex("^\\s*#show:\\s*exam\\b")) != none)
    if i != none {
      let (head, with, rest) = lines.at(i).match(regex("^(\\s*#show:\\s*exam)(\\.with\\()?(.*)$")).captures
      let j = _comment_start(rest)
      let (args, comment) = if j == none { (rest.trim(), none) } else { (rest.slice(0, j).trim(), rest.slice(j + 2).trim()) }
      let note = if comment == none { note } else { note + "; " + comment }
      lines.at(i) = if with == none {
        head + ".with(show-solutions: false)" + note
      } else if args == "" {
        head + ".with(\n  show-solutions: false," + note
      } else {
        head + ".with(show-solutions: false, " + args + note
      }
    } else {
      // No show rule: the exam is called (`#exam(..)`), and a set rule before
      // it takes the setting.
      lines.insert(0, "#show: e.set_(config, show-solutions: false)" + note)
    }
    lines.join("\n")
  }
  // In blocks, a blank line apart.
  (header.join("\n"), setup.trim(), rule, code.trim()).filter(b => b != none and b != "").join("\n\n")
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

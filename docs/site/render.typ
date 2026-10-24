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

/// A label's name, as Typst reads one in `<name>` or `@name`: not ending in
/// the `.` or `:` that may follow a reference in text.
#let _NAME = "[\\p{L}_](?:[\\p{L}\\p{N}_\\-:.]*[\\p{L}\\p{N}_\\-])?"

/// `src` with each of its labels (`<name>`, `label("name")`) and each
/// reference to one (`@name`) renamed with `suffix`, so that another copy of
/// the same example in the document, an answer key or another page of it,
/// or another example using the same names, has labels of its own: Typst
/// allows a label only once where something refers to it. Raw text (in
/// backticks) is left as it is, as Typst shows it as it is. Approximate: a
/// `@` after a letter, a quote, or a backslash, as in an email address, a
/// package's name, or an escaped `\@`, is left alone.
#let _relabel(src, suffix) = {
  let renamed(s) = (
    s
      .replace(regex("<(" + _NAME + ")>"), m => "<" + m.captures.first() + suffix + ">")
      .replace(regex("label\\(\"([^\"]+)\"\\)"), m => "label(\"" + m.captures.first() + suffix + "\")")
      .replace(regex("(^|[^\\p{L}\\p{N}_\"\\\\])@(" + _NAME + ")"), m => m.captures.at(0) + "@" + m.captures.at(1) + suffix)
  )
  // The raw spans (three backticks or one) kept, what is between them
  // renamed.
  let out = ""
  let at = 0
  for m in src.matches(regex("```[\\s\\S]*?```|`[^`]*`")) {
    out += renamed(src.slice(at, m.start)) + m.text
    at = m.end
  }
  out + renamed(src.slice(at))
}

/// How many pages an example's code makes: one more than it has page breaks.
#let _pages(src) = src.matches(regex("\\bpagebreak\\(")).len() + 1

/// A page's label, above it in an example of several pages.
#let _page_label(n) = text(font: "DejaVu Sans", size: 7pt, tracking: .06em, fill: luma(125), upper[Page #n])

/// `body(i)`, an example of `pages` pages (its copy for the page `i`, from
/// 0; see `render`), each `width` wide and `height` high
/// (`auto`: as high as the highest), one above the other, each labelled with
/// its number, a dashed rule between them. A page cannot break inside the
/// box an example is drawn in, so the example is laid out as that many
/// columns instead, its page breaks breaking the column, and each page shows
/// its own column, with the `inset` around it, through a window onto them.
/// The example is drawn once per page, as it is once per view (the exam and
/// its answer key) anyway.
#let _stacked(body, pages, width, height, inset) = context {
  // Each side as Typst's insets give it: by name, by axis, or `rest`.
  let side(name, axis) = inset.at(name, default: inset.at(axis, default: inset.at("rest", default: 0pt)))
  let (left, right, top, bottom) = (side("left", "x"), side("right", "x"), side("top", "y"), side("bottom", "y"))
  // Room for what one page draws outside it, clear of the next page.
  let gap = left + right + 1em
  let all(i) = {
    show pagebreak: it => colbreak(weak: it.weak)
    columns(pages, gutter: gap, body(i))
  }
  let total = pages * width + (pages - 1) * gap
  // As high as the highest page: the pages break only where the code does.
  let height = if height == auto { measure(block(width: total, all(0))).height } else { height }
  let page(i) = block(
    width: left + width + right,
    height: top + height + bottom,
    clip: true,
    place(dx: left - i * (width + gap), dy: top, block(width: total, height: height, all(i))),
  )
  let rule = line(length: left + width + right, stroke: (paint: luma(185), thickness: .6pt, dash: "dashed"))
  stack(
    spacing: .9em,
    ..range(pages).map(i => (
      ..if i > 0 { (rule,) },
      stack(spacing: .5em, pad(left: left, _page_label(i + 1)), page(i)),
    )).flatten(),
  )
}

/// `render`, for the example numbered `n` in the document.
#let render-numbered(src, n, solutions: false, wrap: auto, width: 12cm, height: none, inset: 0pt) = {
  show: e.prepare()
  show: e.set_(lib.config, show-solutions: solutions)
  set text(size: 11pt)
  // In an example of no fixed height, an `fr` height (an answer box's, a
  // question's) would come to nothing: each `1fr` is laid out as 1cm.
  show: if height == none { e.set_(lib.config, _fr-unit: 1cm) } else { it => it }
  let height = if height == none { auto } else { height }
  let inset = if type(inset) == dictionary { inset } else { (left: inset) }
  // The copy of the example for page `i` (from 0), its labels its own on
  // the answer key and on every page after the first (see `_relabel`).
  let body(i) = {
    let suffix = "--ex" + str(n) + (if solutions { "--key" } else { "" }) + if i > 0 { "--page" + str(i + 1) } else { "" }
    eval(_relabel(compiled_source(src, wrap: wrap), suffix), mode: "markup", scope: dictionary(lib))
  }
  let pages = _pages(src)
  if pages == 1 {
    block(inset: (bottom: .3em, ..inset), block(width: width, height: height, body(0)))
  } else {
    // The room below the last line kept inside each page's window.
    let bottom = inset.at("bottom", default: inset.at("y", default: inset.at("rest", default: 0pt)))
    _stacked(body, pages, width, height, (..inset, bottom: bottom + .3em))
  }
}

/// Counts the examples rendered, so that each has labels of its own (see
/// `render`).
#let _EXAMPLES = counter("examy-docs/examples")

/// An example compiled as the exam (`solutions: false`) or as its answer key,
/// on a page `width` wide and `height` high (`none`: as high as it is), with
/// `inset` around it for what is drawn outside the page's text, such as a
/// label run out into the margin: a length for the left side, or a
/// dictionary of sides. A little room is kept below the last line in any
/// case, for its descenders. Code with page breaks is drawn as one page more
/// than it has breaks, one above the other (see `_stacked`).
#let render(src, solutions: false, wrap: auto, width: 12cm, height: none, inset: 0pt) = {
  _EXAMPLES.step()
  // Each example's labels are its own, numbered after it (see `_relabel`):
  // two examples using the same label would otherwise put it twice in the
  // document, which Typst does not allow.
  context render-numbered(
    src,
    _EXAMPLES.get().first(),
    solutions: solutions,
    wrap: wrap,
    width: width,
    height: height,
    inset: inset,
  )
}

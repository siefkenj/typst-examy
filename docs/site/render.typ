// How an example's code becomes a document: shared by the site's examples
// (see `example` in template.typ) and by anything else that compiles one,
// such as an interactive editor, so that an example compiles the same way
// everywhere. Needs only the package itself.

#import "/src/lib.typ"
#import "/src/prelude.typ": e
#import "/src/rubric.typ": AREA
#import "/src/points.typ": EXAMS_STARTED

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

/// The labels examy itself puts in a document, which an example's code may
/// query: not renamed (see `_relabel`), as they are not the example's own.
/// A query of one is narrowed to the example instead (see `_own_queries`).
#let _PACKAGE_LABELS = ("examy-rubric", "examy-warning")

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
      .replace(regex("<(" + _NAME + ")>"), m => if m.captures.first() in _PACKAGE_LABELS { m.text } else {
        "<" + m.captures.first() + suffix + ">"
      })
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

/// `query(target)` as the example between the markers labelled `start` and
/// `end` would have it in a document of its own: only what it draws, and,
/// for `<examy-rubric>`, its exams numbered from 1, not among every example's
/// on the page. The rubric data is given as `(value: ..)`, so that it is read
/// as a query's result is (`.first().value`). In an example's scope as
/// `_example_query` (see `_own_queries`).
#let _example_query(target, start, end) = {
  let found = query(selector(target).after(start).before(end))
  if target != <examy-rubric> { return found }
  // The exams begun before the example.
  let before = EXAMS_STARTED.at(start).first()
  found.map(m => (value: (..m.value, exam: m.value.exam - before)))
}

/// `src` with each query of examy's own labels (see `_PACKAGE_LABELS`) made
/// as the example would make it in a document of its own (see
/// `_example_query`), between the markers labelled `start` and `end`: every
/// example on a page is in the same document, so `query(<examy-rubric>)` would
/// otherwise find every example's exam, as it would every exam of a document
/// of several. Any other use of one is narrowed to the example.
#let _own_queries(src, start, end) = {
  let (start, end) = (start, end).map(l => "label(\"" + str(l) + "\")")
  let names = "(" + _PACKAGE_LABELS.join("|") + ")"
  // A whole query, or else the label alone, in one pass.
  src.replace(regex("\\bquery\\(\\s*<" + names + ">\\s*\\)|<" + names + ">"), m => {
    let (queried, alone) = m.captures
    if queried != none {
      "_example_query(<" + queried + ">, " + start + ", " + end + ")"
    } else {
      "selector(<" + alone + ">).after(" + start + ").before(" + end + ")"
    }
  })
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
/// its answer key) anyway. `lines` outlines the sides of each page given a
/// margin (see `render`).
#let _stacked(body, pages, width, height, inset, lines: (:)) = context {
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
    {
      place(dx: left, dy: top, block(width: width, height: height, stroke: lines))
      place(dx: left - i * (width + gap), dy: top, block(width: total, height: height, all(i)))
    },
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

/// Room below an example's page, where it ends, for the rubrics drawn in
/// its margin past the page's bottom, which take no room of their own and
/// would otherwise be cut off with the page: down to the lowest of those
/// between the markers labelled `start`, where the page begins, and `end`,
/// where it ends (the room added after it moves this one). Needs the
/// rubrics laid out, so takes a layout pass more; and their positions, so
/// only for an example given a `margin`, which is shown as an image of a
/// paged rendering (an HTML frame does not keep where things are), and only
/// where it is laid out on its own (see `render`'s `overhang`).
#let _overhang(start, end) = context {
  let (from, to) = (query(start), query(end))
  if from.len() == 0 or to.len() == 0 { return }
  let p = to.first().location().position()
  let areas = query(selector(AREA).after(from.first().location()).before(to.first().location()))
    .map(m => m.value)
    .filter(a => "top" in a and a.page == p.page and a.natural > 0pt)
  if areas.len() == 0 { return }
  let lowest = areas.sorted(key: a => a.top + a.h).last()
  let bottom = lowest.top + lowest.h
  // Positions are on the page, scaled as the example is: as much as the
  // rubric's height on the page is of its own.
  if bottom > p.y { v((bottom - p.y) / (lowest.h / lowest.natural)) }
}

/// How wide `render` draws an example given `width`, `inset` and `margin`:
/// the page and the room on either side of it, which is known without
/// laying the example out.
#let rendered_width(width, inset, margin) = {
  let inset = if type(inset) == dictionary { inset } else { (left: inset) }
  let margin = if margin == none { (:) } else { margin }
  let side(name) = (
    inset.at(name, default: inset.at("x", default: inset.at("rest", default: 0pt))) + margin.at(name, default: 0pt)
  )
  width + side("left") + side("right")
}

/// `render`, for the example numbered `n` in the document.
#let render-numbered(
  src,
  n,
  solutions: false,
  wrap: auto,
  width: 12cm,
  height: none,
  inset: 0pt,
  margin: none,
  overhang: false,
) = {
  show: e.prepare()
  // Plain, as in a document of its own: the docs highlight their own inline
  // code (`inline_code` in template.typ), which an example's must escape.
  // Given a language, it no longer matches that rule.
  show raw.where(block: false, lang: none): it => raw(it.text, lang: "")
  show: e.set_(lib.config, show-solutions: solutions)
  set text(size: 11pt)
  // In an example of no fixed height, an `fr` height (an answer box's, a
  // question's) would come to nothing: each `1fr` is laid out as 1cm.
  show: if height == none { e.set_(lib.config, _fr-unit: 1cm) } else { it => it }
  let height = if height == none { auto } else { height }
  let inset = if type(inset) == dictionary { inset } else { (left: inset) }
  // Each side as Typst's insets give it, by name, by axis, or `rest`, and
  // the margin's room added on its sides, which are outlined.
  let side(name, axis, default: 0pt) = inset.at(name, default: inset.at(axis, default: inset.at("rest", default: default)))
  // On one page, the room below the last line is the bottom's, unless it
  // is given.
  let below = side("bottom", "y", default: .3em)
  let inset = (left: side("left", "x"), right: side("right", "x"), top: side("top", "y"), bottom: side("bottom", "y"))
  let margin = if margin == none { (:) } else { margin }
  for (name, room) in margin { inset.at(name) += room }
  let below = below + margin.at("bottom", default: 0pt)
  let lines = margin.keys().map(name => (name, .5pt + luma(200))).to-dict()
  // The copy of the example for page `i` (from 0), its labels its own on
  // the answer key and on every page after the first (see `_relabel`).
  let body(i) = {
    let suffix = "--ex" + str(n) + (if solutions { "--key" } else { "" }) + if i > 0 { "--page" + str(i + 1) } else { "" }
    // Where this copy begins and ends, for its queries of examy's own labels.
    let (start, end) = ("start", "end").map(k => label("examy-docs/example" + suffix + "-" + k))
    let code = _own_queries(_relabel(compiled_source(src, wrap: wrap), suffix), start, end)
    [#metadata(none)#start]
    eval(code, mode: "markup", scope: (..dictionary(lib), _example_query: _example_query))
    [#metadata(none)#end]
  }
  let pages = _pages(src)
  // No `return` below: the show rules above apply only to what the
  // function ends with.
  if pages == 1 and not (overhang and margin.len() > 0) {
    block(inset: (..inset, bottom: below), block(width: width, height: height, stroke: lines, body(0)))
  } else if pages == 1 {
    let (start, end) = ("start", "end").map(k => label("examy-docs/example-" + str(n) + "-" + k))
    block(inset: (..inset, bottom: below), {
      [#metadata(none)#start]
      // Outlined with the room added below it, so the line along the
      // margin runs down beside a rubric past the page's bottom.
      block(width: width, stroke: lines, {
        block(width: width, height: height, below: 0pt, body(0))
        // In an empty block of its own: bare, it would be where what
        // follows it starts, after the room it adds.
        block(above: 0pt, below: 0pt, [#metadata(none)#end])
        _overhang(start, end)
      })
    })
  } else {
    // The room below the last line kept inside each page's window.
    _stacked(body, pages, width, height, (..inset, bottom: inset.bottom + .3em), lines: lines)
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
/// case, for its descenders. `margin`, a dictionary of sides, is room for the
/// page's margin on those sides, beyond `inset`, with a thin gray line along
/// the page's edge there, so that what is drawn in the margin (a rubric) is
/// seen to be in it. With `overhang`, the room below the page grows to show
/// a rubric in the margin past the page's bottom (see `_overhang`): for an
/// example laid out in a document of its own, as in a long one the layout
/// passes it takes do not settle. Code with page breaks is drawn as one page
/// more than it has breaks, one above the other (see `_stacked`).
#let render(src, solutions: false, wrap: auto, width: 12cm, height: none, inset: 0pt, margin: none, overhang: false) = {
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
    margin: margin,
    overhang: overhang,
  )
}

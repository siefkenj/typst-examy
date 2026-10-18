// The documentation site's building blocks: the page layout (`layout`), the
// examples that are rendered from their own source (`example`), links into
// the reference (`api`), and the reference's pages, one per export
// (`entry_page`).
// Compiled with Typst's HTML export (see site.typ), and to a PDF of the same
// pages (see manual.typ): what is drawn with HTML elements on the site has a
// paged form too (see `_either`).

// Typst's `html` module exists only where HTML export is enabled (the site),
// not where the PDF is compiled; bullseye's `html` stands in for it there, so
// that the code naming it compiles either way.
#import "@preview/bullseye:0.1.0": html, match-target
#import "/src/lib.typ"
#import "/src/prelude.typ": e
#import "/docs/api.typ": ENTRIES, IMPORT, VERSION, alias_code, entry, page_path, signatures, summary
#import "render.typ": full_source, has_key, render

#let REPOSITORY = toml("/typst.toml").package.repository

/// The PDF of the guide and the reference (manual.typ), published beside the
/// pages by build.sh, by its path from the site's root.
#let MANUAL_PDF = "examy-manual.pdf"

/// The guide's pages and the reference's index, in the order of the sidebar:
/// `(path, title, file)`, `file` relative to site.typ.
#let PAGES = (
  (path: "index.html", title: "Getting started", file: "pages/index.typ"),
  (path: "questions.html", title: "Questions and numbering", file: "pages/questions.typ"),
  (path: "points.html", title: "Points", file: "pages/points.typ"),
  (path: "answer-boxes.html", title: "Answer boxes", file: "pages/answer-boxes.typ"),
  (path: "solutions.html", title: "Solutions", file: "pages/solutions.typ"),
  (path: "choices.html", title: "Multiple choice", file: "pages/choices.typ"),
  (path: "cross-references.html", title: "Cross-references", file: "pages/cross-references.typ"),
  (path: "cover-pages.html", title: "Cover pages and name blocks", file: "pages/cover-pages.typ"),
  (path: "configuration.html", title: "Configuration", file: "pages/configuration.typ"),
  (path: "reference.html", title: "Reference", file: "pages/reference.typ"),
)

/// The reference's pages, one per export (or group of exports that take the
/// same arguments, such as `question`/`part`/`subpart`), generated from the
/// package's declarations: `(path, title, entry)`.
#let REFERENCE_PAGES = ENTRIES.map(x => (path: page_path(x), title: x.names.join(", "), entry: x))

/// Every page, in reading order (for the links to the previous and next).
#let ALL_PAGES = PAGES + REFERENCE_PAGES

/// `for-html` on the site, `for-paged` in the PDF: each a function making
/// the content, so that the site's HTML elements are only made for the site.
#let _either(for-html, for-paged) = context match-target(html: for-html, paged: for-paged)()

/// The label of the reference's anchor for the export `name`, or for its
/// argument `arg`.
#let _anchor(name, arg: none) = label("api-" + name + if arg != none { "--" + arg })

/// The label of a guide page in the PDF, by its path on the site.
#let page_label(path) = label("page-" + path)

/// A link to the reference page of the export `name`, shown as its name in
/// code; with `arg`, to that argument of it, shown as the argument's name. A
/// label, so that Typst works out the link from wherever it is.
#let api(name, arg: none, body: auto) = {
  let x = ENTRIES.find(x => name in x.names)
  assert(x != none, message: "api: `" + name + "` is not an export of examy")
  assert(
    arg == none or x.args.any(a => a.name == arg),
    message: "api: `" + name + "` has no argument `" + repr(arg) + "`",
  )
  let shown = if body != auto { body } else if arg != none { raw(arg) } else { raw(name) }
  link(_anchor(if arg == none { name } else { x.names.first() }, arg: arg), shown)
}

/// A link to another page of the guide, by its path.
#let page-link(path, body) = {
  assert(PAGES.any(p => p.path == path), message: "page-link: no page " + path)
  _either(() => link(path, body), () => link(page_label(path), body))
}

/// A note set apart from the text.
#let note(kind: "note", body) = _either(
  () => html.elem("aside", attrs: (class: "callout " + kind), body),
  () => {
    let color = if kind == "warning" { rgb("#c27c0e") } else { rgb("#1d5fb4") }
    block(width: 100%, inset: (x: 1em, y: .8em), fill: color.lighten(92%), stroke: (left: 2pt + color), body)
  },
)

/// One of the package's screenshots, from examples/images/ (published with
/// the site by site.typ).
#let screenshot(name, alt, caption: none) = _either(
  () => html.elem("figure", attrs: (class: "screenshot"), {
    html.elem("img", attrs: (src: "images/" + name, alt: alt, loading: "lazy"))
    if caption != none { html.elem("figcaption", caption) }
  }),
  () => figure(
    box(stroke: .5pt + luma(200), image("/examples/images/" + name, alt: alt)),
    caption: caption,
    numbering: none,
  ),
)

/// Several screenshots side by side.
#let screenshots(..figures) = _either(
  () => html.elem("div", attrs: (class: "screenshots"), figures.pos().join()),
  () => grid(columns: (1fr,) * figures.pos().len(), gutter: 1em, align: center + horizon, ..figures.pos()),
)

/// Links to guide pages, as cards on the site: `(path, title, text)` each.
#let features(..cards) = _either(
  () => html.elem("div", attrs: (class: "features"), for (path, title, text) in cards.pos() {
    html.elem("a", attrs: (class: "feature", href: path), {
      html.elem("strong", title)
      html.elem("span", text)
    })
  }),
  () => list(..cards.pos().map(((path, title, text)) => [
    #link(page_label(path), strong(title)) --- #text
  ])),
)

// ---------------------------------------------------------------------------
// Examples

/// How an example's output looks, in the PDF and (through `output_css`) on
/// the site alike: on a panel shaded gray behind the exam, and, beside an
/// answer key, light blue behind the key, the shades meeting along a wavy
/// line down the middle. Each paper is white, labelled above in small
/// capitals.
#let OUTPUT = (
  exam-shade: luma(247),
  // examy's default solution color, much lightened.
  key-shade: blue.darken(20%).lighten(95%),
  line: luma(185),
  line-width: .7pt,
  // How far the wave swings to either side, and the length of one swing.
  amp: 2pt,
  step: 6pt,
  paper-edge: luma(205),
  // The subtle outline of the panel, and of the code above it: the site's
  // line color (`--line` in style.css).
  outline: rgb("#e2e6ee"),
  label: luma(125),
  // A font the dev container (and CI, built in it) installs.
  label-font: "DejaVu Sans",
)

/// The points of the wave down from `(x, y0)` to `(x, y1)`, starting with a
/// move there.
#let _wave(x, y0, y1) = {
  let (amp, step) = (OUTPUT.amp, OUTPUT.step)
  let n = calc.max(1, int((y1 - y0) / step))
  let s = (y1 - y0) / n
  (
    curve.move((x, y0)),
    ..range(n).map(i => curve.quad(
      (x + if calc.even(i) { amp } else { -amp }, y0 + (i + .5) * s),
      (x, y0 + (i + 1) * s),
    )),
  )
}

/// A paper's label: small capitals, spaced, less the space the spacing
/// leaves after the last letter, so that it centers.
#let _paper_label(body, tracking: .08em) = text(
  font: OUTPUT.label-font,
  size: 7pt,
  tracking: tracking,
  fill: OUTPUT.label,
  upper(body) + h(-tracking),
)

/// An example's output in the PDF: `papers` are one or two
/// `(content, label)`, each laid out on a white sheet, scaled down to its
/// share of the width if it is wider, and, two, centered on each other
/// vertically, with their labels above them on one baseline.
#let _paged_output(papers, gutter: 2.6em) = layout(size => {
  let w = size.width
  let two = papers.len() == 2
  let inset = (x: 1.1em, top: .8em, bottom: 1.1em)
  let column = (w - 2 * inset.x.to-absolute() - if two { gutter.to-absolute() } else { 0pt }) / papers.len()
  let sheet(body) = {
    let sheet = box(fill: white, stroke: .6pt + OUTPUT.paper-edge, radius: 2pt, inset: .7em, body)
    let wide = measure(sheet).width
    if wide <= column { sheet } else { scale(column / wide * 100%, reflow: true, sheet) }
  }
  let labels = papers.map(((_, label)) => if label == none { [] } else { _paper_label(label) })
  let sheets = papers.map(((body, _)) => sheet(body))
  let body = block(width: w, inset: inset, grid(
    columns: if two { (1fr, gutter, 1fr) } else { (1fr,) },
    row-gutter: .5em,
    align: (_, y) => if y == 0 and labels.any(l => l != []) { center + bottom } else { center + horizon },
    ..if labels.any(l => l != []) { if two { (labels.at(0), [], labels.at(1)) } else { labels } },
    ..if two { (sheets.at(0), [], sheets.at(1)) } else { sheets },
  ))
  let h = measure(body, width: w).height
  box(width: w, height: h, radius: 5pt, clip: true, stroke: .6pt + OUTPUT.outline, {
    place(rect(width: w, height: h, fill: if two { OUTPUT.key-shade } else { OUTPUT.exam-shade }))
    if two {
      place(curve(
        fill: OUTPUT.exam-shade,
        curve.move((0pt, 0pt)),
        curve.line((w / 2, 0pt)),
        .._wave(w / 2, 0pt, h).slice(1),
        curve.line((0pt, h)),
        curve.close(),
      ))
      place(curve(stroke: OUTPUT.line-width + OUTPUT.line, .._wave(w / 2, 0pt, h)))
    }
    place(body)
  })
})

/// `OUTPUT` as CSS custom properties, for the site's stylesheet (see
/// site.typ): its colors, and the wave as a tile of SVG to repeat down the
/// middle of an output panel, the two shades meeting along it.
#let output_css() = {
  let pt(x) = str(calc.round(x / 1pt, digits: 3))
  let (amp, step) = (OUTPUT.amp, OUTPUT.step)
  let (w, h) = (16pt, 2 * step)
  let x = w / 2
  // One period of the wave: out to one side, then the other.
  let wave = "Q" + pt(x + amp) + " " + pt(step / 2) + " " + pt(x) + " " + pt(step) + "Q" + pt(x - amp) + " " + pt(1.5 * step) + " " + pt(x) + " " + pt(h)
  let svg = (
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 " + pt(w) + " " + pt(h) + "'>"
      + "<path fill='" + OUTPUT.key-shade.to-hex() + "' d='M0 0H" + pt(w) + "V" + pt(h) + "H0Z'/>"
      + "<path fill='" + OUTPUT.exam-shade.to-hex() + "' d='M0 0H" + pt(x) + wave + "H0Z'/>"
      + "<path fill='none' stroke='" + OUTPUT.line.to-hex() + "' stroke-width='" + pt(OUTPUT.line-width) + "' d='M" + pt(x) + " 0" + wave + "'/>"
      + "</svg>"
  )
  (
    "/* Generated from OUTPUT in docs/site/template.typ. */\n:root {\n"
      + "  --output-exam-shade: " + OUTPUT.exam-shade.to-hex() + ";\n"
      + "  --output-key-shade: " + OUTPUT.key-shade.to-hex() + ";\n"
      + "  --output-paper-edge: " + OUTPUT.paper-edge.to-hex() + ";\n"
      + "  --output-label: " + OUTPUT.label.to-hex() + ";\n"
      + "  --output-label-font: \"" + OUTPUT.label-font + "\";\n"
      + "  --output-wave: url(\"data:image/svg+xml," + svg.replace("#", "%23").replace("<", "%3C").replace(">", "%3E") + "\");\n"
      + "  --output-wave-size: " + pt(w) + "pt " + pt(h) + "pt;\n"
      + "}\n"
  )
}

/// A code example, shown with what it renders to, rendered by the package
/// itself from the very code shown, so the two cannot disagree (see
/// render.typ for how the code is compiled).
///
/// - `code`: a raw block, in Typst markup. A line importing examy is shown
///   but not compiled (the package is in scope already), and a
///   `show-solutions:` setting is left out (each view sets its own).
/// - `key`: whether to also show the answer key beside the exam; `auto` does
///   when the code has a solution or a correct choice.
/// - `wrap`: whether to wrap the code in `#exam(questions: [..])`; `auto`
///   does when it has a question but no exam. Leading `#show`, `#set` and
///   `#let` lines stay outside it.
/// - `width`, `height`: the size of the page the example is laid out on. A
///   `height` gives `fr` answer boxes a page to fill.
/// - `inset`: room around the page, for what is drawn outside it, as
///   `render` takes it.
///
/// On the site, the example is also shown as a whole document, which compiles
/// as it is in a document of its own (see `full_source`), in a second code
/// block, hidden until the reader asks for it; not for an example that is one
/// already. The code, the whole document, and these options are written into
/// the page as `data-` attributes too, for the live editor (live.ts) to pick
/// up. In the PDF, the code is followed by what it renders to, scaled down to
/// fit the page if it must be.
#let example(code, key: auto, wrap: auto, width: 12cm, height: none, inset: 0pt) = {
  // An import line shows the version this site documents, whatever the page
  // says, so that a new version needs no change to the pages.
  let src = code.text.replace(regex("@preview/examy:\d+\.\d+\.\d+"), "@preview/examy:" + VERSION)
  let key = if key == auto { has_key(src) } else { key }
  let full = full_source(src, VERSION, wrap: wrap)
  let views = if key { ((false, "Exam"), (true, "Answer key")) } else { ((false, none),) }
  let paged() = {
    block(sticky: true, raw(src, lang: "typ", block: true))
    // Laid out as on the site, not as the manual's text is, nor centered
    // as the panel is.
    let view(solutions) = {
      set par(justify: false)
      set align(start)
      render(src, solutions: solutions, wrap: wrap, width: width, height: height, inset: inset)
    }
    block(breakable: false, _paged_output(views.map(((solutions, label)) => (view(solutions), label))))
  }
  _either(
    () => html.elem(
      "figure",
      attrs: (
        class: "example" + if key { " with-key" } else { "" },
        data-source: src,
        // Only where the whole document says more than the example does.
        ..if full != src { (data-full: full) },
        data-wrap: repr(wrap),
        data-width: repr(width),
        data-height: repr(height),
        data-inset: repr(inset),
      ),
      {
        html.elem("div", attrs: (class: "example-code"), {
          html.elem("div", attrs: (class: "code-short"), raw(src, lang: "typ", block: true))
          if full != src {
            html.elem("div", attrs: (class: "code-full", hidden: ""), raw(full, lang: "typ", block: true))
          }
        })
        // The labels first, a row of their own above the papers (see
        // style.css), so that they share a baseline.
        html.elem("div", attrs: (class: "example-output"), {
          for (solutions, label) in views.filter(((_, label)) => label != none) {
            html.elem("span", attrs: (class: "paper-label", data-solutions: repr(solutions)), label)
          }
          for (solutions, label) in views {
            html.elem(
              "div",
              attrs: (class: "paper", data-solutions: repr(solutions)),
              html.frame(render(src, solutions: solutions, wrap: wrap, width: width, height: height, inset: inset)),
            )
          }
        })
      },
    ),
    paged,
  )
}

// ---------------------------------------------------------------------------
// The reference

/// The pieces of a description from the package's docs, which are plain text
/// with `code` and Markdown links (the README shows them as Markdown).
#let _PIECE = regex("`([^`]*)`|\[([^\]]+)\]\(([^)\s]+)\)")

/// A description from the package's docs, as content: `code` in code, links
/// as links, and everything else as plain text, never read as markup. The
/// code is not highlighted: what is quoted is as often a bit of output (a
/// number such as `1.`) or a name as it is Typst code.
#let doc(s) = {
  let inline(s) = {
    let out = ()
    let at = 0
    for m in s.matches(_PIECE) {
      out.push(s.slice(at, m.start))
      out.push(if m.captures.at(0) != none { raw(m.captures.at(0)) } else {
        link(m.captures.at(2), m.captures.at(1))
      })
      at = m.end
    }
    out.push(s.slice(at))
    out.join()
  }
  // A blank line (`\n\n` in the declaration) starts a new paragraph.
  s.split(regex("\n\s*\n")).map(p => inline(p.trim())).join(parbreak())
}

/// One argument of a reference entry, with the anchor `api(.., arg:)` links
/// to.
#let _arg(owner, a) = {
  [#metadata(a.name)#_anchor(owner, arg: a.name)]
  _either(
    () => html.elem("div", attrs: (class: "arg", id: owner + "." + a.name), {
      html.elem("div", attrs: (class: "arg-head"), {
        html.elem("code", attrs: (class: "arg-name"), a.name)
        html.elem("code", attrs: (class: "arg-type"), a.type)
        if a.required {
          html.elem("span", attrs: (class: "badge required"), [required])
        } else {
          html.elem("span", attrs: (class: "arg-default"), [default #raw(a.default, lang: "typc")])
        }
        if not a.named { html.elem("span", attrs: (class: "badge"), [positional]) }
      })
      html.elem("div", attrs: (class: "arg-doc"), doc(a.doc))
    }),
    () => block(above: 1.2em, {
      block(sticky: true, {
        strong(raw(a.name))
        h(.8em)
        text(fill: luma(90), raw(a.type))
        h(.8em)
        text(size: .9em, if a.required [_required_] else [default #raw(a.default, lang: "typc")])
        if not a.named { text(size: .9em)[ · _positional_] }
      })
      pad(left: 1.5em, doc(a.doc))
    }),
  )
}

/// A signature, one argument per line when it is too long for one.
#let _wrap(sig) = {
  if sig.len() <= 72 or not sig.contains("(") { return sig }
  let open = sig.position("(")
  let args = sig.slice(open + 1, -1)
  // Split at the commas between arguments, not those inside a default.
  let parts = ()
  let depth = 0
  let current = ""
  for c in args.clusters() {
    if c in ("(", "[") { depth += 1 } else if c in (")", "]") { depth -= 1 }
    if c == "," and depth == 0 { parts.push(current.trim()); current = "" } else { current += c }
  }
  parts.push(current.trim())
  sig.slice(0, open) + "(\n" + parts.map(p => "  " + p + ",").join("\n") + "\n)"
}

/// The heading of an export's reference page: its names, and what it is.
#let entry_heading(x) = _either(
  () => {
    x.names.map(n => html.elem("code", n)).join(", ")
    html.elem("span", attrs: (class: "kind"), x.kind)
  },
  () => {
    x.names.map(raw).join(", ")
    h(.5em)
    text(size: .7em, weight: "regular", fill: luma(90), x.kind)
  },
)

/// The reference page of one export, or of a group of them, less its
/// heading (see `layout`).
#let entry_page(x) = {
  // The anchors `api` links to, one per name.
  for n in x.names { [#metadata(n)#_anchor(n)] }
  // A group's members take the same arguments: the first is shown in full.
  let sigs = signatures(x)
  let shown = if sigs.len() > 1 and _wrap(sigs.first()) != sigs.first() {
    (_wrap(sigs.first()),) + x.names.slice(1).map(n => n + "(..)  // the same arguments")
  } else { sigs.map(_wrap) }
  // A call is shown as it is written in a document, in markup: `#choice(..)`.
  // A bare name (a value, or `config`) is shown as it is.
  let shown = shown.map(s => if s.contains("(") { "#" + s } else { s })
  raw(shown.join("\n"), lang: "typ", block: true)
  doc(x.desc)
  if x.kind == "alias" {
    par[Same as #raw(alias_code(x), lang: "typc"); takes the same arguments as #api(x.alias-of).]
  }
  if x.args.len() > 0 {
    let title = if x.kind == "element" and not x.show-signature [Fields] else [Arguments]
    _either(() => html.elem("h2", title), () => heading(level: 3, numbering: none, outlined: false, title))
    x.args.map(a => _arg(x.names.first(), a)).join()
  }
}

/// The reference's index: every export, with a link to its page and what it
/// is in a line. Each keeps an anchor of its name here, where the reference
/// once documented them all.
#let reference_index() = _either(
  () => html.elem("ul", attrs: (class: "api-index"), for x in ENTRIES {
    html.elem("li", attrs: (id: x.names.first()), {
      for n in x.names.slice(1) { html.elem("span", attrs: (id: n)) }
      html.elem("span", attrs: (class: "api-names"), x.names.map(n => api(n)).join(", "))
      html.elem("span", attrs: (class: "api-summary"), doc(summary(x.desc)))
    })
  }),
  () => table(
    columns: (auto, 1fr),
    stroke: none,
    inset: (x: 0pt, y: .4em),
    column-gutter: 1.5em,
    ..ENTRIES.map(x => (x.names.map(n => api(n)).join(", "), doc(summary(x.desc)))).flatten(),
  ),
)

/// The names of `config`'s options, in the order it declares them.
#let CONFIG_OPTIONS = entry("config").args.map(a => a.name)

/// A table of some of `config`'s options, each a link to its reference, with
/// the first sentence of its description.
#let config-options(..names) = {
  let args = entry("config").args
  let t = table(
    columns: (auto, 1fr),
    table.header[*Option*][*What it sets*],
    ..names.pos().map(n => {
      let a = args.find(a => a.name == n)
      assert(a != none, message: "config-options: `config` has no option `" + n + "`")
      (api("config", arg: n), doc(summary(a.doc)))
    }).flatten(),
  )
  _either(() => html.elem("div", attrs: (class: "config-options"), t), () => t)
}

// ---------------------------------------------------------------------------
// The page layout

/// The way from a page back to the site's root: `../` from a page in a
/// folder, such as the reference's.
#let _root(current) = "../" * (current.path.split("/").len() - 1)

/// A link from the current page to another, by its path from the root.
#let _href(current, path) = _root(current) + path

/// The sidebar: the guide's pages, and every export.
#let _sidebar(current) = html.elem("nav", attrs: (class: "sidebar", aria-label: "Site"), {
  let here(path) = if path == current.path { (aria-current: "page") } else { (:) }
  html.elem("p", attrs: (class: "sidebar-title"), [Guide])
  html.elem("ul", for p in PAGES.filter(p => p.path != "reference.html") {
    html.elem("li", html.elem("a", attrs: (href: _href(current, p.path), ..here(p.path)), p.title))
  })
  html.elem("p", attrs: (class: "sidebar-title"), html.elem(
    "a",
    attrs: (href: _href(current, "reference.html"), ..here("reference.html")),
    [Reference],
  ))
  // Every name, in alphabetical order, each a link to its page; a group's
  // later names (`part`, `subpart`) to their anchors on its page.
  let names = REFERENCE_PAGES.map(p => p.entry.names.map(n => (name: n, page: p))).flatten()
  html.elem("ul", attrs: (class: "sidebar-api"), for (name: n, page: p) in names.sorted(key: x => x.name) {
    let first = n == p.entry.names.first()
    html.elem("li", html.elem(
      "a",
      attrs: (
        href: _href(current, p.path) + if first { "" } else { "#api-" + n },
        ..if first { here(p.path) },
      ),
      html.elem("code", n),
    ))
  })
})

/// Previous and next page links at the foot of a page.
#let _pager(current) = {
  let i = ALL_PAGES.position(p => p.path == current.path)
  html.elem("nav", attrs: (class: "pager", aria-label: "Pages"), {
    if i > 0 {
      let p = ALL_PAGES.at(i - 1)
      html.elem("a", attrs: (class: "prev", href: _href(current, p.path)), [← #p.title])
    }
    if i + 1 < ALL_PAGES.len() {
      let p = ALL_PAGES.at(i + 1)
      html.elem("a", attrs: (class: "next", href: _href(current, p.path)), [#p.title →])
    }
  })
}

/// A whole page of the site: `current` is its entry in `ALL_PAGES`, and
/// `heading` what its heading shows, if not its title.
#let layout(current, body, heading: auto) = html.html(lang: "en", {
  let to(path) = _href(current, path)
  html.head({
    html.meta(charset: "utf-8")
    html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
    html.title(if current.path == "index.html" [examy — exams, quizzes and homework in Typst] else [#current.title — examy])
    html.link(rel: "stylesheet", href: to("style.css"))
    html.link(rel: "icon", href: to("favicon.svg"), type: "image/svg+xml")
    // The live editor, when the site is built with it (see site.typ).
    if sys.inputs.at("live-files", default: none) != none {
      html.elem("script", attrs: (type: "module", src: to("live.js")))
    }
  })
  html.body({
    html.elem("header", attrs: (class: "topbar"), {
      html.elem("a", attrs: (class: "brand", href: to("index.html")), [examy])
      html.elem("span", attrs: (class: "version"), [v#VERSION])
      html.elem("nav", attrs: (class: "toplinks", aria-label: "Links"), {
        html.elem("a", attrs: (href: to("index.html")), [Guide])
        html.elem("a", attrs: (href: to("reference.html")), [Reference])
        html.elem("a", attrs: (href: to(MANUAL_PDF), download: ""), [PDF])
        html.elem("a", attrs: (href: "https://typst.app/universe/package/examy"), [Typst Universe])
        html.elem("a", attrs: (href: REPOSITORY), [GitHub])
      })
    })
    html.elem("div", attrs: (class: "layout"), {
      _sidebar(current)
      html.elem("main", {
        html.elem("h1", if heading == auto { current.title } else { heading })
        body
        _pager(current)
      })
    })
    html.elem("footer", attrs: (class: "footer"), [
      examy #VERSION · Generated from the package source with Typst's HTML export. ·
      #link(REPOSITORY)[Source]
    ])
  })
})

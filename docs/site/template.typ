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
#import "/docs/api.typ": (
  ENTRIES, IMPORT, VERSION, alias_code, arg_name, entry, page_path, signatures, summary,
)
#import "render.typ": full_source, has_key, render, rendered_width

#let REPOSITORY = toml("/typst.toml").package.repository

/// The blue of the site's links and callouts, and of the manual's headings:
/// `--accent` in the site's stylesheet too (see `output_css`).
#let ACCENT = rgb("#1d5fb4")

/// The PDF of the guide and the reference (manual.typ), published beside the
/// pages by build.sh, by its path from the site's root.
#let MANUAL_PDF = "examy-manual.pdf"

/// The guide's pages and the reference's index, in the order of the sidebar:
/// `(path, title, file)`, `file` relative to site.typ, and optionally
/// `heading`, what the page's heading on the site shows if not its title.
#let PAGES = (
  // Headed "examy", as the README is, so that it opens with the README's
  // first paragraph.
  // The front page's heading is the logo, which site.typ renders as logo.svg.
  (
    path: "index.html",
    title: "Getting started",
    file: "pages/index.typ",
    heading: html.elem("img", attrs: (class: "logo", src: "logo.svg", alt: "examy")),
  ),
  (path: "questions.html", title: "Questions and numbering", file: "pages/questions.typ"),
  (path: "points.html", title: "Points", file: "pages/points.typ"),
  (path: "cross-references.html", title: "Cross-references", file: "pages/cross-references.typ"),
  (path: "answer-boxes.html", title: "Answer boxes", file: "pages/answer-boxes.typ"),
  (path: "choices.html", title: "Multiple choice", file: "pages/choices.typ"),
  (path: "solutions.html", title: "Solutions", file: "pages/solutions.typ"),
  (path: "rubrics.html", title: "Rubrics", file: "pages/rubrics.typ"),
  (path: "cover-pages.html", title: "Cover pages", file: "pages/cover-pages.typ"),
  (path: "configuration.html", title: "Configuration", file: "pages/configuration.typ"),
  (path: "technical-details.html", title: "Technical details", file: "pages/technical-details.typ"),
  (path: "reference.html", title: "Reference", file: "pages/reference.typ"),
  // Last, after the reference (see `ALL_PAGES`).
  (path: "changelog.html", title: "Changelog", file: "pages/changelog.typ"),
)

/// The reference's pages, one per export (or group of exports that take the
/// same arguments, such as `question`/`part`/`subpart`), generated from the
/// package's declarations: `(path, title, entry)`.
#let REFERENCE_PAGES = ENTRIES.map(x => (path: page_path(x), title: x.names.join(", "), entry: x))

/// Every page, in reading order (for the links to the previous and next): the
/// reference's pages after its index, and the changelog last.
#let ALL_PAGES = {
  let changelog = PAGES.filter(p => p.path == "changelog.html")
  PAGES.filter(p => p.path != "changelog.html") + REFERENCE_PAGES + changelog
}

/// `for-html` on the site, `for-paged` in the PDF: each a function making
/// the content, so that the site's HTML elements are only made for the site.
#let _either(for-html, for-paged) = context match-target(html: for-html, paged: for-paged)()

/// The label of the reference's anchor for the export `name`, or for its
/// argument `arg`.
#let _anchor(name, arg: none) = label("api-" + name + if arg != none { "--" + arg })

/// The label of a guide page in the PDF, by its path on the site.
#let page_label(path) = label("page-" + path)

/// A link to the reference page of the export `name`, shown as its name in
/// code. With `arg`, shown as a call to it in markup, `#name` followed by
/// `arg`: `arg: "[..]"` shows `#name[..]`, and `arg: ""` shows `#name`.
/// With `field`, a link to that argument of it instead, shown as the
/// argument's name as written in a call (`..options` for `exam`'s options),
/// or, with `value` too, as given that value: `field: "inline", value:
/// "true"` shows `inline: true`. `body` shows what it is given instead. A
/// label, so that Typst works out the link from wherever it is.
#let api(name, arg: none, field: none, value: none, body: auto) = {
  let x = ENTRIES.find(x => name in x.names)
  assert(x != none, message: "api: `" + name + "` is not an export of examy")
  assert(
    arg == none or type(arg) == str,
    message: "api: `arg` must be a string, such as \"[..]\" or \"\", got " + repr(arg),
  )
  let a = if field != none { x.args.find(a => a.name == field) }
  assert(
    field == none or a != none,
    message: "api: `" + name + "` has no argument `" + repr(field) + "`",
  )
  assert(
    value == none or (field != none and type(value) == str),
    message: "api: `value` must be a string, such as \"true\", and needs a `field`",
  )
  let shown = if body != auto { body } else if value != none {
    raw(field + ": " + value)
  } else if field != none { raw(arg_name(a)) } else if (
    arg != none
  ) {
    raw("#" + name + arg)
  } else { raw(name) }
  link(_anchor(if field == none { name } else { x.names.first() }, arg: field), shown)
}

/// A link to another page of the guide, by its path.
#let page-link(path, body) = {
  assert(PAGES.any(p => p.path == path), message: "page-link: no page " + path)
  _either(() => link(path, body), () => link(page_label(path), body))
}

/// A link to Typst's own documentation, by its path under typst.app/docs/,
/// e.g. `typst-link("reference/model/numbering/")[numbering pattern]`.
#let typst-link(path, body) = link("https://typst.app/docs/" + path, body)

/// A note set apart from the text.
#let note(kind: "note", body) = _either(
  () => html.elem("aside", attrs: (class: "callout " + kind), body),
  () => {
    let color = if kind == "warning" { rgb("#c27c0e") } else { ACCENT }
    // Its emphasis and bold text in its own color, as on the site.
    show emph: set text(fill: color)
    show strong: set text(fill: color)
    block(
      width: 100%,
      inset: (x: 1em, y: .8em),
      fill: color.lighten(92%),
      stroke: (left: 2pt + color),
      body,
    )
  },
)

/// A warning set apart from the text: a note of the warning kind.
#let warning(body) = note(kind: "warning", body)

/// One of the package's screenshots, from examples/images/ (published with
/// the site by site.typ). `pdf-height` is its height in the PDF, where it
/// is otherwise the width of the text: for one too tall to share its page.
#let screenshot(name, alt, caption: none, pdf-height: auto) = _either(
  () => html.elem("figure", attrs: (class: "screenshot"), {
    html.elem("img", attrs: (src: "images/" + name, alt: alt, loading: "lazy"))
    if caption != none { html.elem("figcaption", caption) }
  }),
  () => figure(
    box(stroke: .5pt + luma(200), image("/examples/images/" + name, alt: alt, height: pdf-height)),
    caption: caption,
    numbering: none,
  ),
)

/// Several screenshots side by side.
#let screenshots(..figures) = _either(
  () => html.elem("div", attrs: (class: "screenshots"), figures.pos().join()),
  () => grid(columns: (1fr,) * figures.pos().len(), gutter: 1em, align: center
      + horizon, ..figures.pos()),
)

/// Links to guide pages, as cards on the site: `(path, title, text)` each.
#let features(..cards) = _either(
  () => html.elem("div", attrs: (class: "features"), for (path, title, text) in cards.pos() {
    html.elem("a", attrs: (class: "feature", href: path), {
      html.elem("strong", title)
      html.elem("span", text)
    })
  }),
  () => terms(..cards
    .pos()
    .map(((path, title, text)) => terms.item(link(page_label(path), strong(title)), text))),
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
/// move there; with `across`, of the wave across from `(y0, x)` to `(y1, x)`.
#let _wave(x, y0, y1, across: false) = {
  let (amp, step) = (OUTPUT.amp, OUTPUT.step)
  let n = calc.max(1, int((y1 - y0) / step))
  let s = (y1 - y0) / n
  let at(p) = if across { (p.at(1), p.at(0)) } else { p }
  (
    curve.move(at((x, y0))),
    ..range(n).map(i => curve.quad(
      at((x + if calc.even(i) { amp } else { -amp }, y0 + (i + .5) * s)),
      at((x, y0 + (i + 1) * s)),
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
/// vertically, with their labels above them on one baseline. With
/// `stacked`, two are one above the other instead, each the full width, the
/// shades meeting along a wavy line across between them; `wide` is then how
/// wide the papers' content is (see `rendered_width`), so that it need not be
/// measured: measured, a rubric drawn past the bottom of the example (see
/// `_overhang` in render.typ) does not settle.
#let _paged_output(papers, gutter: 2.6em, stacked: false, wide: none) = layout(size => {
  let w = size.width
  let two = papers.len() == 2
  if two and stacked {
    let inset = (x: 1.1em, top: .8em, bottom: 1.1em)
    let column = w - 2 * inset.x.to-absolute()
    let sheet(body) = {
      let sheet = box(fill: white, stroke: .6pt + OUTPUT.paper-edge, radius: 2pt, inset: .7em, body)
      let wide = if wide == none { measure(sheet).width } else { (wide + 1.4em).to-absolute() }
      if wide <= column { sheet } else { scale(column / wide * 100%, reflow: true, sheet) }
    }
    let half((body, label), shade, inset) = block(
      width: w,
      fill: shade,
      inset: inset,
      below: 0pt,
      align(
        center,
        stack(spacing: .5em, _paper_label(label), sheet(body)),
      ),
    )
    // Between the halves, a band the shades meet across along the wave, so
    // that neither half needs measuring to find where it ends.
    let g = gutter.to-absolute()
    let band = block(width: w, height: g, above: 0pt, below: 0pt, {
      place(rect(width: w, height: g, fill: OUTPUT.key-shade))
      place(curve(
        fill: OUTPUT.exam-shade,
        curve.move((0pt, 0pt)),
        curve.line((0pt, g / 2)),
        .._wave(g / 2, 0pt, w, across: true).slice(1),
        curve.line((w, 0pt)),
        curve.close(),
      ))
      place(curve(stroke: OUTPUT.line-width + OUTPUT.line, .._wave(g / 2, 0pt, w, across: true)))
    })
    return box(width: w, radius: 5pt, clip: true, stroke: .6pt + OUTPUT.outline, {
      half(papers.at(0), OUTPUT.exam-shade, (x: inset.x, top: inset.top))
      band
      half(papers.at(1), OUTPUT.key-shade, (x: inset.x, bottom: inset.bottom))
    })
  }
  let inset = (x: 1.1em, top: .8em, bottom: 1.1em)
  let column = (
    (w - 2 * inset.x.to-absolute() - if two { gutter.to-absolute() } else { 0pt }) / papers.len()
  )
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
    align: (_, y) => if y == 0 and labels.any(l => l != []) { center + bottom } else {
      center + horizon
    },
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
/// site.typ), and `ACCENT` as `--accent`: its colors, and the wave as a
/// tile of SVG to repeat down the middle of an output panel, the two shades
/// meeting along it, and another to repeat across it, for when the papers
/// are one above the other.
#let output_css() = {
  let pt(x) = str(calc.round(x / 1pt, digits: 3))
  let (amp, step) = (OUTPUT.amp, OUTPUT.step)
  let (w, h) = (16pt, 2 * step)
  let x = w / 2
  // One period of the wave: out to one side, then the other.
  let wave = (
    "Q"
      + pt(x + amp)
      + " "
      + pt(step / 2)
      + " "
      + pt(x)
      + " "
      + pt(step)
      + "Q"
      + pt(x - amp)
      + " "
      + pt(1.5 * step)
      + " "
      + pt(x)
      + " "
      + pt(h)
  )
  let svg = (
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 "
      + pt(w)
      + " "
      + pt(h)
      + "'>"
      + "<path fill='"
      + OUTPUT.key-shade.to-hex()
      + "' d='M0 0H"
      + pt(w)
      + "V"
      + pt(h)
      + "H0Z'/>"
      + "<path fill='"
      + OUTPUT.exam-shade.to-hex()
      + "' d='M0 0H"
      + pt(x)
      + wave
      + "H0Z'/>"
      + "<path fill='none' stroke='"
      + OUTPUT.line.to-hex()
      + "' stroke-width='"
      + pt(OUTPUT.line-width)
      + "' d='M"
      + pt(x)
      + " 0"
      + wave
      + "'/>"
      + "</svg>"
  )
  // The same wave across, for papers one above the other: the exam's shade
  // above it and the key's below.
  let (xw, xh) = (2 * step, 16pt)
  let y = xh / 2
  let across = (
    "Q"
      + pt(step / 2)
      + " "
      + pt(y + amp)
      + " "
      + pt(step)
      + " "
      + pt(y)
      + "Q"
      + pt(1.5 * step)
      + " "
      + pt(y - amp)
      + " "
      + pt(xw)
      + " "
      + pt(y)
  )
  let svg-x = (
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 "
      + pt(xw)
      + " "
      + pt(xh)
      + "'>"
      + "<path fill='"
      + OUTPUT.exam-shade.to-hex()
      + "' d='M0 0H"
      + pt(xw)
      + "V"
      + pt(xh)
      + "H0Z'/>"
      + "<path fill='"
      + OUTPUT.key-shade.to-hex()
      + "' d='M0 "
      + pt(y)
      + across
      + "V"
      + pt(xh)
      + "H0Z'/>"
      + "<path fill='none' stroke='"
      + OUTPUT.line.to-hex()
      + "' stroke-width='"
      + pt(OUTPUT.line-width)
      + "' d='M0 "
      + pt(y)
      + across
      + "'/>"
      + "</svg>"
  )
  let url(svg) = (
    "url(\"data:image/svg+xml,"
      + svg.replace("#", "%23").replace("<", "%3C").replace(">", "%3E")
      + "\")"
  )
  (
    "/* Generated from OUTPUT and ACCENT in docs/site/template.typ. */\n:root {\n"
      + "  --accent: "
      + ACCENT.to-hex()
      + ";\n"
      + "  --output-exam-shade: "
      + OUTPUT.exam-shade.to-hex()
      + ";\n"
      + "  --output-key-shade: "
      + OUTPUT.key-shade.to-hex()
      + ";\n"
      + "  --output-paper-edge: "
      + OUTPUT.paper-edge.to-hex()
      + ";\n"
      + "  --output-label: "
      + OUTPUT.label.to-hex()
      + ";\n"
      + "  --output-label-font: \""
      + OUTPUT.label-font
      + "\";\n"
      + "  --output-wave: "
      + url(svg)
      + ";\n"
      + "  --output-wave-size: "
      + pt(w)
      + "pt "
      + pt(h)
      + "pt;\n"
      + "  --output-wave-x: "
      + url(svg-x)
      + ";\n"
      + "  --output-wave-x-size: "
      + pt(xw)
      + "pt "
      + pt(xh)
      + "pt;\n"
      + "  --output-wave-x-size-h: "
      + pt(xh)
      + "pt;\n"
      + "}\n"
  )
}

/// Where the image of a view of an example shown `paged-name` is published.
#let _paged_path(name, solutions) = (
  "examples/" + name + if solutions { "-key" } else { "-exam" } + ".svg"
)

/// The documents an example shown `paged-name` is drawn from on the site (see
/// `example`): an SVG of each of its views, laid out as a page of its own.
/// `ex` holds `example`'s arguments, `code` and `paged-name` among them.
/// Called by site.typ, at its top level, where documents are made.
#let paged_documents(ex) = {
  let src = ex.code.text.replace(regex("@preview/examy:\d+\.\d+\.\d+"), "@preview/examy:" + VERSION)
  let key = ex.at("key", default: auto)
  let key = if key == auto { has_key(src) } else { key }
  for solutions in if key { (false, true) } else { (false,) } {
    document(_paged_path(ex.paged-name, solutions), {
      set page(width: auto, height: auto, margin: 0pt)
      render(
        src,
        solutions: solutions,
        wrap: ex.at("wrap", default: auto),
        width: ex.at("width", default: 12cm),
        height: ex.at("height", default: none),
        inset: ex.at("inset", default: 0pt),
        margin: ex.at("margin", default: none),
        overhang: true,
      )
    })
  }
}

/// The arguments of each example in `src`, a page's source, shown
/// `paged-name` (see `example`), for site.typ to make their images from with
/// `paged_documents`: a page cannot make documents itself, as it is part of
/// one. Each `#example(..)` call is found in the source and evaluated with
/// an `example` that returns its arguments, so they must be written out in
/// it, not taken from the page's own variables.
#let paged_examples(src) = {
  // A raw block, a string, or a parenthesis: those in the first two are
  // not the call's.
  let tokens = regex("```[\\s\\S]*?```|`[^`\\n]*`|\"(?:[^\"\\\\]|\\\\.)*\"|[()]")
  let found = ()
  for m in src.matches("#example(") {
    let depth = 1
    let end = none
    for t in src.slice(m.end).matches(tokens) {
      if t.text == "(" { depth += 1 } else if t.text == ")" { depth -= 1 }
      if depth == 0 {
        end = m.end + t.end
        break
      }
    }
    if end == none { continue }
    let call = src.slice(m.start + 1, end)
    if not call.contains("paged-name") { continue }
    found.push(eval(call, scope: (example: (code, ..args) => (code: code, ..args.named()))))
  }
  found
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
/// - `wrap`: whether to wrap the code in `#exam[..]`; `auto` does when it
///   has a question but no exam. Leading `#show`, `#set` and `#let` lines
///   stay outside it.
/// - `width`, `height`: the size of the page the example is laid out on. A
///   `height` gives `fr` answer boxes a page to fill.
/// - `inset`: room around the page, for what is drawn outside it, as
///   `render` takes it.
/// - `margin`: room for the page's margin, as `render` takes it, with a thin
///   gray line where the margin starts: for an example that draws in it (a
///   rubric).
/// - `pdf-height`: the `height` in the PDF only, for an example the site
///   grows to fit a rubric past its page's bottom (see `render`'s
///   `overhang`), which the PDF cannot: there, too many examples doing so
///   keep the document's layout from settling. A length, or an array of two,
///   the exam's and the answer key's: `(auto, 3cm)` leaves the exam as tall
///   as it is. `none` or `auto` is `height`.
/// - `stacked`: whether the exam and its answer key are shown one above the
///   other, each the full width, rather than side by side: for an example
///   too wide to read at half the width.
/// - `paged-name`: on the site, show what it renders to as images of a paged
///   rendering, named after this (see `paged_documents`), rather than in an
///   HTML frame: for output that needs to know where things are on the page,
///   which Typst's HTML export does not keep inside a frame (a rubric's
///   dotted lines). site.typ makes the images, finding the example in the
///   page's source (see `paged_examples`).
///
/// On the site, the example is also shown as a whole document, which compiles
/// as it is in a document of its own (see `full_source`), in a second code
/// block, hidden until the reader asks for it; not for an example that is one
/// already. The code, the whole document, and these options are written into
/// the page as `data-` attributes too, for the live editor (live.ts) to pick
/// up. In the PDF, the code is followed by what it renders to, scaled down to
/// fit the page if it must be.
#let example(
  code,
  key: auto,
  wrap: auto,
  width: 12cm,
  height: none,
  inset: 0pt,
  margin: none,
  pdf-height: none,
  stacked: false,
  paged-name: none,
) = {
  // An import line shows the version this site documents, whatever the page
  // says, so that a new version needs no change to the pages.
  let src = code.text.replace(regex("@preview/examy:\d+\.\d+\.\d+"), "@preview/examy:" + VERSION)
  let key = if key == auto { has_key(src) } else { key }
  let full = full_source(src, VERSION, wrap: wrap)
  let views = if key { ((false, "Exam"), (true, "Answer key")) } else { ((false, none),) }
  let paged() = {
    // Not kept with what it renders to: a page may break between the two.
    raw(src, lang: "typ", block: true)
    // Laid out as on the site, not as the manual's text is, nor centered
    // as the panel is: both ways, since an alignment set one way only keeps
    // the other from around it, and the panel centers its papers vertically.
    let view(solutions) = {
      set par(justify: false)
      set align(start + top)
      let h = if type(pdf-height) == array { pdf-height.at(if solutions { 1 } else { 0 }) } else {
        pdf-height
      }
      let height = if h in (none, auto) { height } else { h }
      render(
        src,
        solutions: solutions,
        wrap: wrap,
        width: width,
        height: height,
        inset: inset,
        margin: margin,
      )
    }
    block(breakable: false, _paged_output(
      views.map(((solutions, label)) => (view(solutions), label)),
      stacked: stacked,
      wide: rendered_width(width, inset, margin),
    ))
  }
  _either(
    () => html.elem(
      "figure",
      attrs: (
        class: "example"
          + if key { " with-key" } else { "" }
          + if stacked { " stacked" } else { "" },
        data-source: src,
        // Only where the whole document says more than the example does.
        ..if full != src { (data-full: full) },
        data-wrap: repr(wrap),
        data-width: repr(width),
        data-height: repr(height),
        data-inset: repr(inset),
        data-margin: repr(margin),
      ),
      {
        html.elem("div", attrs: (class: "example-code"), {
          html.elem("div", attrs: (class: "code-short"), raw(src, lang: "typ", block: true))
          if full != src {
            html.elem("div", attrs: (class: "code-full", hidden: ""), raw(
              full,
              lang: "typ",
              block: true,
            ))
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
              if paged-name == none {
                html.frame(render(
                  src,
                  solutions: solutions,
                  wrap: wrap,
                  width: width,
                  height: height,
                  inset: inset,
                  margin: margin,
                ))
              } else {
                html.elem("img", attrs: (
                  src: _paged_path(paged-name, solutions),
                  alt: if solutions { "Answer key" } else { "Exam" },
                ))
              },
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

/// The names of the exports, which inline code calling one links to.
#let _EXPORT_NAMES = ENTRIES.map(x => x.names).flatten()

/// The names of `config`'s options, in the order it declares them.
#let CONFIG_OPTIONS = entry("config").args.map(a => a.name)

/// `config`'s options that are also an export (`show-solutions`) or another
/// export's argument (a question's `indent`, `maketitle`'s `term`): inline
/// code naming one could mean either, so it links to the option only in a
/// description that names `config` just before it (see `doc`).
#let _SHARED_OPTIONS = CONFIG_OPTIONS.filter(o => (
  o in _EXPORT_NAMES or ENTRIES.any(x => "config" not in x.names and x.args.any(a => a.name == o))
))

/// A call, as `#maketitle()`, `#choices[..]` or `#answer-box(..)[..]` are:
/// `#`, a name, and its arguments and its body, if any.
#let _CALL = regex("^#([a-z][a-z-]*)(\\(.*\\))?(\\[.*\\])?$")

/// A name, alone or given a value, as `numbering-full: true` is.
#let _NAMED = regex("^([a-z][a-z-]*)(:\\s.*)?$")

/// What inline code `c` links to, as `api`'s `(name, field)`: the export it
/// calls (`#maketitle()`), `config` (`config`), or a `config` option it
/// names, alone or given a value (`choices-inline`, `numbering-full: true`),
/// unless one of `_SHARED_OPTIONS`. Otherwise none.
#let _code-target(c) = {
  let call = c.match(_CALL)
  let named = c.match(_NAMED)
  if c == "config" { (name: "config", field: none) } else if (
    call != none and call.captures.first() in _EXPORT_NAMES
  ) { (name: call.captures.first(), field: none) } else if named != none {
    let o = named.captures.first()
    if o in CONFIG_OPTIONS and o not in _SHARED_OPTIONS { (name: "config", field: o) }
  }
}

/// Inline code as Typst: as markup when it starts with `#`, as code
/// otherwise, which is what most of it is (an option, a value, a call).
#let _typst-raw(c) = raw(c, lang: if c.starts-with("#") { "typ" } else { "typc" })

/// Inline code that names no language (`` `..` ``) highlighted as Typst (see
/// `_typst-raw`), and linked to the reference of what it names (see
/// `_code-target`), except in a link, a heading or the outline, where a link
/// cannot be. Inline code in another language names it (```` ```sh --input
/// ..``` ````), and code blocks are left as they are. Applied to every page,
/// on the site (see `layout`) and in the PDF: the one rule that links code,
/// in the guide's pages and the package's docs (see `doc`) alike.
#let inline_code(body) = {
  show raw.where(block: false, lang: none): it => {
    let target = _code-target(it.text)
    let shown = _typst-raw(it.text)
    if target == none { shown } else { api(target.name, field: target.field, body: shown) }
  }
  let unlinked(it) = {
    show raw.where(block: false, lang: none): it => _typst-raw(it.text)
    it
  }
  show link: unlinked
  show heading: unlinked
  show outline: unlinked
  body
}

/// The language of inline code quoted in Markdown (the package's docs, the
/// changelog), which cannot name it: a command line's (`--input ..`,
/// `typst ..`), Typst markup for a reference or a label (`@name`,
/// `<name>`), and otherwise none, for `inline_code` to choose.
#let markdown_code_lang(code) = {
  if code.starts-with("--") or code.starts-with("typst ") { "sh" } else if (
    code.starts-with("@") or code.starts-with("<")
  ) { "typ" } else { none }
}

/// The pieces of a description from the package's docs, which are plain text
/// with `code` and Markdown links (the README shows them as Markdown).
#let _PIECE = regex("`([^`]*)`|\[([^\]]+)\]\(([^)\s]+)\)")

/// What may come between the options of a list of them: "`a`, `b` and `c`".
#let _LIST_GLUE = (", ", " and ", ", and ", " or ", ", or ")

/// A description from the package's docs, as content: `code` in code, links
/// as links (their text read the same way, so that a link can be code, as
/// in [`box`'s `stroke`](..)), and everything else as plain text, never read
/// as markup. The code is highlighted and linked as `inline_code` and
/// `markdown_code_lang` say, and so are the guide's pages.
///
/// What `inline_code` cannot tell, an option of `_SHARED_OPTIONS` named as
/// `config`'s, after "`config`'s " or in a list of options after it
/// ("`config`'s `indent` and `numbering`"), links to the option here, but not
/// in a link of the description's own.
#let doc(s) = {
  let inline(s, links: true) = {
    let out = ()
    let at = 0
    // The last code, and whether it was an option in a list of `config`'s.
    let last = none
    let listing = false
    for m in s.matches(_PIECE) {
      let between = s.slice(at, m.start)
      out.push(between)
      let c = m.captures.at(0)
      listing = (
        c in CONFIG_OPTIONS
          and ((last == "config" and between == "'s ") or (listing and between in _LIST_GLUE))
      )
      out.push(if c == none {
        link(m.captures.at(2), inline(m.captures.at(1), links: false))
      } else if links and listing and c in _SHARED_OPTIONS {
        api("config", field: c, body: raw(c))
      } else {
        raw(c, lang: markdown_code_lang(c))
      })
      last = c
      at = m.end
    }
    out.push(s.slice(at))
    out.join()
  }
  // A blank line (`\n\n` in the declaration) starts a new paragraph.
  s.split(regex("\n\s*\n")).map(p => inline(p.trim())).join(parbreak())
}

/// A gear for a `config` option, `size` across, its middle `middle` above
/// the baseline: a dashed ring for its teeth, sixteen dashes and gaps to a
/// turn, around a ring for its body.
#let _gear(size, middle, fill: ACCENT) = box(width: size, height: size, baseline: size / 2 - middle, {
  let r = size / 2
  let teeth = 2 * calc.pi * r * .72 / 16
  place(center + horizon, circle(radius: r * .72, stroke: (paint: fill, thickness: r * .4, dash: (teeth, teeth))))
  place(center + horizon, circle(radius: r * .58, stroke: r * .22 + fill))
})

/// An argument's default: its value, written as code, in a blue box, under a
/// small "default" centered over it; and, when it comes from a `config`
/// option (`option`), in the same box, a gear and the option's name in blue,
/// linked to it.
#let default-badge(default, option: none) = _either(
  () => html.elem("span", attrs: (class: "default-badge"), html.elem("span", attrs: (class: "default-box"), {
    html.elem("span", attrs: (class: "default-value"), {
      html.elem("span", attrs: (class: "default-key"), [default])
      raw(default, lang: "typc")
    })
    if option != none {
      // The title on the link's whole text, as `link` takes no attributes.
      let title = "When auto this setting is inherited from config's " + option
      api("config", field: option, body: html.elem("span", attrs: (class: "default-config", title: title), raw(option)))
    }
  })),
  () => context {
    // Every piece's lines run between the same edges, whatever its font and
    // size, so that the pieces are of one height and stand on one baseline,
    // the text's.
    let (up, down, pad) = (.75em.to-absolute(), .3em.to-absolute(), .2em.to-absolute())
    set text(top-edge: up, bottom-edge: -down)
    // The middle of the code's lowercase letters, which the gear is centered
    // on. The code with no language, as the manual's other inline code (see
    // `inline_code`), and so of the same size.
    let x = measure(text(top-edge: "x-height", bottom-edge: "baseline", raw("x"))).height
    let piece(stroke: none, body) = box(stroke: stroke, inset: (x: .4em, y: pad), body)
    let value = piece(raw(default))
    let boxed = box(stroke: .5pt + ACCENT, radius: 2pt, {
      value
      if option != none {
        api("config", field: option, body: piece(
          stroke: (left: .5pt + ACCENT.lighten(60%)),
          text(fill: ACCENT)[#_gear(1.8 * x, x / 2)#h(.3em)#raw(option)],
        ))
      }
    })
    // "default" above the box, centered over the value, wider than it or not.
    let key = text(size: .65em, fill: ACCENT, top-edge: "cap-height", bottom-edge: "baseline")[default]
    let over = box(width: measure(value).width, height: measure(key).height, place(bottom + center, key))
    // A stack's baseline is its bottom edge (see `answer-box`), which is
    // raised to the text's, inside the box.
    box(baseline: down + pad, stack(spacing: .2em, over, boxed))
  },
)

/// The alternatives of a type as the reference writes it (`auto | length`),
/// split where they are joined at its top level, not inside parentheses (as
/// in `(str | function)[]`).
#let _alternatives(type) = {
  let parts = ("",)
  let depth = 0
  for (i, c) in type.clusters().enumerate() {
    if c in ("(", "[") { depth += 1 } else if c in (")", "]") { depth -= 1 }
    if c == "|" and depth == 0 { parts.push("") } else { parts.at(-1) += c }
  }
  parts.map(str.trim)
}

/// One argument of a reference entry, with the anchor `api(.., field:)` links
/// to. A default that is one of the alternatives of its type (`auto` of
/// `auto | length`) is shown once, as its badge, first among them; any other
/// is shown after the type.
#let _arg(owner, a) = {
  [#metadata(a.name)#_anchor(owner, arg: a.name)]
  let has_default = not a.variadic and not a.required
  let alts = if a.type == none { () } else { _alternatives(a.type) }
  let inline = has_default and a.default in alts
  // The type, less the default when its badge stands for it.
  let rest = if inline { alts.filter(t => t != a.default) } else { alts }
  let badge = if has_default { default-badge(a.default, option: a.config) }
  _either(
    () => html.elem("div", attrs: (class: "arg", id: owner + "." + a.name), {
      html.elem("div", attrs: (class: "arg-head"), {
        html.elem("code", attrs: (class: "arg-name"), arg_name(a))
        if inline { badge }
        if rest != () {
          html.elem("code", attrs: (class: "arg-type"), (if inline { "| " } else { "" }) + rest.join(" | "))
        }
        if a.variadic {
          html.elem("span", attrs: (class: "badge"), [any number])
        } else if a.required {
          html.elem("span", attrs: (class: "badge required"), [required])
        } else if not inline {
          badge
        }
        if not a.named { html.elem("span", attrs: (class: "badge"), [positional]) }
      })
      html.elem("div", attrs: (class: "arg-doc"), doc(a.doc))
    }),
    () => block(above: 1.2em, {
      block(sticky: true, {
        strong(_typst-raw(arg_name(a)))
        h(.8em)
        if inline {
          text(size: .9em, badge)
          h(.4em)
        }
        if rest != () {
          text(fill: luma(90), raw((if inline { "| " } else { "" }) + rest.join(" | ")))
          h(.8em)
        }
        if a.variadic { text(size: .9em)[_any number_] } else if a.required {
          text(size: .9em)[_required_]
        } else if not inline { text(size: .9em, badge) }
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
    if c == "," and depth == 0 {
      parts.push(current.trim())
      current = ""
    } else { current += c }
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
    x.names.map(_typst-raw).join(", ")
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
    par[Alias for #raw(alias_code(x), lang: "typc");; see #api(x.alias-of).]
  }
  if x.args.len() > 0 {
    let title = if x.kind == "element" and not x.show-signature [Fields] else [Arguments]
    _either(
      () => html.elem("h2", title),
      () => heading(level: 3, numbering: none, outlined: false, title),
    )
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

/// The label of the record each `config-options` table leaves of the options
/// it lists (see `config-options-check`).
#let _CONFIG_OPTIONS_LISTED = <docs-config-options-listed>

/// A table of some of `config`'s options, each a link to its reference with
/// its default and type below it, and its description.
#let config-options(..names) = {
  let args = entry("config").args
  // A default on one line, or, when that is long (`strings`'), as written,
  // over several lines.
  let one-line(d) = d.replace(regex("\\(\\s*\n\\s*"), "(").replace(regex(",?\\s*\n\\s*\\)"), ")").replace(regex("\\s*\n\\s*"), " ")
  let is-long(a) = one-line(a.default).len() > 24
  let default-of(a) = if is-long(a) { a.default } else { one-line(a.default) }
  // The name, and its default and type below it, slightly indented. They
  // wrap (the type at its `|`s), so a long one does not widen the column
  // past the name (or the widest piece of them). As in the reference (see
  // `_arg`), a default that is one of the alternatives of the type is shown
  // once, as its badge, first among them; any other short one after the
  // type; a long one, written over several lines, in a box of its own below.
  let name-cell(a) = {
    let long = not a.required and is-long(a)
    let alts = if a.type == none { () } else { _alternatives(a.type) }
    let inline = not a.required and not long and default-of(a) in alts
    let rest = if inline { alts.filter(t => t != default-of(a)) } else { alts }
    let badge = if not a.required and not long { default-badge(default-of(a)) }
    _either(
      () => {
        api("config", field: a.name)
        // Each alternative, the badge among them, in one piece with the `|`
        // after it: the line wraps between them.
        let bar = html.elem("code", attrs: (class: "arg-type"), "|")
        let pieces = rest.map(t => html.elem("code", attrs: (class: "arg-type"), t))
        if inline { pieces.insert(0, badge) }
        let pieces = pieces.enumerate().map(((i, p)) => if i < pieces.len() - 1 { [#p #bar] } else { p })
        if badge != none and not inline { pieces.push(badge) }
        html.elem("div", attrs: (class: "option-meta"), pieces.map(p => html.elem("span", p)).join(" "))
        // Outside the `option-meta`, so that the column fits it.
        if long {
          html.elem("div", attrs: (class: "option-pretty default-badge"), html.elem("div", attrs: (class: "default-box"), {
            html.elem("div", attrs: (class: "default-value"), {
              html.elem("span", attrs: (class: "default-key"), [default])
              raw(default-of(a), lang: "typc", block: true)
            })
          }))
        }
      },
      () => context {
        let name = api("config", field: a.name)
        let indent = .6em.to-absolute()
        let small(body) = text(size: .8em, body)
        let type(t) = text(fill: luma(90), raw(t))
        // Each alternative, the badge among them, in one box with the `|`
        // after it: the line wraps between them.
        let pieces = rest.map(type)
        if inline { pieces.insert(0, badge) }
        let pieces = pieces.enumerate().map(((i, p)) => if i < pieces.len() - 1 { [#p#type(" |")] } else { p })
        if badge != none and not inline { pieces.push(badge) }
        let pieces = pieces.map(p => box(small(p)))
        // Not wrapped: as wide as its widest line, under "default", as a
        // badge has it.
        let pretty = if long {
          small(stack(
            spacing: .2em,
            align(center, text(size: .65em, fill: ACCENT)[default]),
            box(stroke: .5pt + ACCENT, radius: 2pt, inset: (x: .4em, y: .3em), raw(default-of(a))),
          ))
        }
        // At least wide enough for a short type on one line, as `content | none`.
        let width = calc.max(
          8em.to-absolute(),
          measure(name).width - indent,
          ..(..pieces, pretty).filter(p => p != none).map(p => measure(p).width),
        )
        // The leading of their smaller size, not the text around them.
        set par(justify: false, leading: .5em)
        // Kept on one page with its row's start.
        block(breakable: false, stack(
          spacing: .5em,
          name,
          ..(pieces.join(" "), pretty).filter(x => x != none).map(x => pad(left: indent, block(width: width, x))),
        ))
      },
    )
  }
  let t = table(
    stroke: none,
    columns: (auto, 1fr),
    // table.header[*Option*][*Description*],
    ..names
      .pos()
      .map(n => {
        let a = args.find(a => a.name == n)
        assert(a != none, message: "config-options: `config` has no option `" + n + "`")
        (name-cell(a), doc(a.doc))
      })
      .flatten(),
  )
  _either(() => html.elem("div", attrs: (class: "config-options"), t), () => t)
  [#metadata(names.pos())#_CONFIG_OPTIONS_LISTED]
}

/// Fails the build if one of `config`'s options is in no `config-options`
/// table, so that a new option cannot be left out of them.
#let config-options-check() = context {
  let listed = query(_CONFIG_OPTIONS_LISTED).map(m => m.value).flatten()
  let missing = CONFIG_OPTIONS.filter(o => o not in listed)
  assert(missing.len() == 0, message: "config-options: no table lists " + missing.join(", "))
}

// ---------------------------------------------------------------------------
// The page layout

/// The way from a page back to the site's root: `../` from a page in a
/// folder, such as the reference's.
#let _root(current) = "../" * (current.path.split("/").len() - 1)

/// A link from the current page to another, by its path from the root.
#let _href(current, path) = _root(current) + path

/// The playground (pages/playground.typ), a page of its own, outside the
/// guide: by its path from the site's root.
#let PLAYGROUND = "playground.html"

/// A link to the playground, which opens it in a tab of its own. In the
/// guide's list, an edit icon follows it (see style.css), to set it apart from
/// the pages.
#let _playground_link(current) = html.elem(
  "a",
  attrs: (
    class: "playground-link",
    href: _href(current, PLAYGROUND),
    target: "_blank",
    title: "Write an exam in the browser (opens in a new tab)",
  ),
  [Playground],
)

/// The guide's pages, headed "Guide", and the playground: in the sidebar, and
/// in the menu on a small screen.
#let _guide_list(current) = {
  let here(path) = if path == current.path { (aria-current: "page") } else { (:) }
  html.elem("p", attrs: (class: "sidebar-title"), [Guide])
  html.elem("ul", {
    for p in PAGES.filter(p => p.path != "reference.html") {
      html.elem("li", html.elem(
        "a",
        attrs: (href: _href(current, p.path), ..here(p.path)),
        p.title,
      ))
    }
    html.elem("li", _playground_link(current))
  })
}

/// The sidebar: the guide's pages, and every export.
#let _sidebar(current) = html.elem("nav", attrs: (class: "sidebar", aria-label: "Site"), {
  let here(path) = if path == current.path { (aria-current: "page") } else { (:) }
  _guide_list(current)
  html.elem("p", attrs: (class: "sidebar-title"), html.elem(
    "a",
    attrs: (href: _href(current, "reference.html"), ..here("reference.html")),
    [Reference],
  ))
  // Every name, in alphabetical order, each a link to its page; a group's
  // later names (`part`, `subpart`) to their anchors on its page.
  let names = REFERENCE_PAGES.map(p => p.entry.names.map(n => (name: n, page: p))).flatten()
  html.elem("ul", attrs: (class: "sidebar-api"), for (name: n, page: p) in names.sorted(key: x => {
    x.name
  }) {
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
  // Every option of `config`, in alphabetical order, each a link to its
  // argument on `config`'s page.
  html.elem("p", attrs: (class: "sidebar-title"), html.elem(
    "a",
    attrs: (href: _href(current, "configuration.html")),
    [Config options],
  ))
  let config = entry("config")
  html.elem("ul", attrs: (class: "sidebar-api"), for n in CONFIG_OPTIONS.sorted() {
    html.elem("li", html.elem(
      "a",
      attrs: (href: _href(current, page_path(config)) + "#config." + n),
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

/// A page's head, titled `title`: the stylesheet, the icon, and the live
/// editor, when the site is built with it (see site.typ).
#let _head(current, title) = html.head({
  let to(path) = _href(current, path)
  html.meta(charset: "utf-8")
  html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
  html.title(title)
  html.link(rel: "stylesheet", href: to("style.css"))
  html.link(rel: "icon", href: to("favicon.svg"), type: "image/svg+xml")
  if sys.inputs.at("live-files", default: none) != none {
    html.elem("script", attrs: (type: "module", src: to("live.js")))
  }
})

/// A whole page of the site: `current` is its entry in `ALL_PAGES`, and
/// `heading` what its heading shows, if not its title.
#let layout(current, body, heading: auto) = html.html(lang: "en", {
  show: inline_code
  let to(path) = _href(current, path)
  let title = if current.path == "index.html" {
    [examy — exams, quizzes and homework in Typst]
  } else [#current.title — examy]
  _head(current, title)
  html.body({
    html.elem("header", attrs: (class: "topbar"), {
      html.elem("a", attrs: (class: "brand", href: to("index.html")), [examy])
      html.elem("span", attrs: (class: "version"), [v#VERSION])
      // On a small screen, the links and the guide's pages are in a menu
      // the button opens (see style.css); the sidebar is hidden there.
      html.elem(
        "button",
        attrs: (
          class: "menu-button",
          type: "button",
          aria-label: "Menu",
          aria-controls: "site-menu",
          aria-expanded: "false",
          onclick: "const open = this.parentElement.classList.toggle('menu-open'); this.setAttribute('aria-expanded', open)",
        ),
        html.elem("span") + html.elem("span") + html.elem("span"),
      )
      html.elem("div", attrs: (class: "menu", id: "site-menu"), {
        html.elem("nav", attrs: (class: "toplinks", aria-label: "Links"), {
          html.elem("a", attrs: (href: to("index.html")), [Guide])
          html.elem("a", attrs: (href: to("reference.html")), [Reference])
          _playground_link(current)
          html.elem("a", attrs: (href: to(MANUAL_PDF), download: ""), [PDF])
          html.elem("a", attrs: (href: "https://typst.app/universe/package/examy"), [Typst
            Universe])
          html.elem("a", attrs: (href: REPOSITORY), [GitHub])
        })
        html.elem("nav", attrs: (class: "menu-guide", aria-label: "Guide"), _guide_list(current))
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

/// The playground's page (see pages/playground.typ): `body` fills the window
/// under a top bar of its own, which links back to the guide and the
/// reference.
#let playground_layout(body) = html.html(lang: "en", {
  let current = (path: PLAYGROUND, title: "Playground")
  _head(current, [Playground — examy])
  html.elem("body", attrs: (class: "playground-page"), {
    html.elem("header", attrs: (class: "topbar"), {
      html.elem("a", attrs: (class: "brand", href: "index.html"), [examy])
      html.elem("span", attrs: (class: "version"), [v#VERSION])
      html.elem("span", attrs: (class: "topbar-title"), [Playground])
      html.elem("nav", attrs: (class: "toplinks", aria-label: "Links"), {
        html.elem("a", attrs: (href: "index.html"), [Guide])
        html.elem("a", attrs: (href: "reference.html"), [Reference])
        // Not on a narrow screen, where the bar has room for two.
        html.elem("a", attrs: (class: "toplink-wide", href: REPOSITORY), [GitHub])
      })
    })
    body
  })
})

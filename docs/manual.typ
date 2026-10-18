// The documentation as one PDF: the guide's pages and the reference, from
// the same sources as the site (site.typ), with every example rendered
// below its code.
//
//   typst compile --root . docs/manual.typ examy-manual.pdf
//
// The pages are written for both: what the site draws with HTML elements
// has a paged form too (see `_either` in site/template.typ).

#import "site/template.typ": OUTPUT, PAGES, REFERENCE_PAGES, REPOSITORY, entry_heading, entry_page, page_label
#import "api.typ": VERSION

#let ACCENT = rgb("#1d5fb4")
#let HOMEPAGE = toml("/typst.toml").package.homepage
#let UNIVERSE = "https://typst.app/universe/package/" + toml("/typst.toml").package.name

#set document(title: [examy #VERSION], description: [The examy manual])
#set page(
  paper: "us-letter",
  margin: (x: 1in, y: 1in),
  numbering: "1",
  number-align: center,
)
#set text(size: 10.5pt)
#set par(justify: true)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(2em)
  set text(size: 1.6em)
  it
  v(.6em)
}
#show heading: set block(above: 1.6em, below: .9em)
#show raw.where(block: true): set text(size: .9em)
#show raw.where(block: true): set par(justify: false)
// Code on the same gray as the panel behind an example's exam, outlined as
// the panel is.
#show raw.where(block: true): block.with(
  width: 100%,
  inset: .8em,
  radius: 3pt,
  fill: OUTPUT.exam-shade,
  stroke: .6pt + OUTPUT.outline,
)
// The manual's own links, not those inside a rendered example (a
// cross-reference there is a link too).
#show link: it => {
  let ours = type(it.dest) == str or (
    type(it.dest) == label and (str(it.dest).starts-with("api-") or str(it.dest).starts-with("page-"))
  )
  if ours { text(fill: ACCENT, it) } else { it }
}
// A link that shows its own URL, in the code font.
#show link: it => {
  let bare = type(it.dest) == str and it.body.func() == text and it.body.text == it.dest
  if bare { text(font: "DejaVu Sans Mono", size: .9em, it) } else { it }
}

// The title page.
#page(numbering: none, {
  v(25%)
  text(size: 3em, weight: "bold")[examy]
  h(.4em)
  text(size: 1.4em, fill: luma(90))[#VERSION]
  v(.2em)
  text(size: 1.3em)[Exams, quizzes, and homework in Typst]
  v(2em)
  grid(
    columns: 2,
    column-gutter: 1.5em,
    row-gutter: .8em,
    [Online], link(HOMEPAGE),
    [Typst Universe], link(UNIVERSE),
    [Source], link(REPOSITORY),
  )
})

#outline(depth: 2)

#for p in PAGES {
  [#heading(level: 1, p.title)#page_label(p.path)]
  include "site/" + p.file
  // The reference: each export after the index, as on the site's pages.
  if p.path == "reference.html" {
    for r in REFERENCE_PAGES {
      heading(level: 2, entry_heading(r.entry))
      entry_page(r.entry)
    }
  }
}

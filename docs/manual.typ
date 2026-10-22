// The documentation as one PDF: the guide's pages and the reference, from
// the same sources as the site (site.typ), with every example rendered
// below its code.
//
//   typst compile --root . docs/manual.typ examy-manual.pdf
//
// The pages are written for both: what the site draws with HTML elements
// has a paged form too (see `_either` in site/template.typ).

#import "site/template.typ": (
  OUTPUT, PAGES, REFERENCE_PAGES, REPOSITORY, entry_heading, entry_page, page_label,
)
#import "api.typ": VERSION
#import "logo/logo.typ": NAVY, examy-logo
#import "/src/elements/bubble.typ": check_mark

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
  let ours = (
    type(it.dest) == str
      or (
        type(it.dest) == label
          and (str(it.dest).starts-with("api-") or str(it.dest).starts-with("page-"))
      )
  )
  if ours { text(fill: ACCENT, it) } else { it }
}
// A link that shows its own URL, in the code font.
#show link: it => {
  let bare = type(it.dest) == str and it.body.func() == text and it.body.text == it.dest
  if bare { text(font: "DejaVu Sans Mono", size: .9em, it) } else { it }
}

// The title page: the logo on cream paper inside a double rule, and what the
// guide covers as a ticked checklist, like the sheet in the logo.
#{
  let ink = NAVY
  let rust = rgb("#a3392b")
  let cream = rgb("#f6f1e7")
  // A checkbox ticked with the check mark examy draws in a filled-in bubble,
  // grown so that, like a pen tick, it runs out past the box's corner.
  let ticked = box(width: .8em, height: .8em, baseline: .05em, stroke: .7pt + ink, place(
    bottom + left,
    dx: -.08em,
    dy: .16em,
    check_mark(2.5em, rust),
  ))
  page(numbering: none, margin: 0pt, fill: cream, {
    place(dx: .45in, dy: .45in, rect(width: 100% - .9in, height: 100% - .9in, stroke: 1.8pt + ink))
    place(dx: .55in, dy: .55in, rect(width: 100% - 1.1in, height: 100% - 1.1in, stroke: .5pt + ink))
    pad(x: 1.15in, top: 1.05in, bottom: .95in, {
      set align(center)
      set text(fill: ink)
      examy-logo(width: 2.6in)
      v(1.6em)
      text(size: 17pt)[Exams, quizzes, and homework in Typst]
      v(.9em)
      box(
        stroke: .8pt + rust,
        radius: 1em,
        inset: (x: 1em, y: .4em),
        text(size: 9pt, fill: rust, tracking: .12em, weight: "semibold", upper[Version #VERSION]),
      )
      v(1fr)
      // The guide's chapters, on a sheet of paper with a soft shadow.
      let chapters = PAGES.filter(p => p.path not in ("index.html", "changelog.html", "reference.html"))
      let sheet = block(width: 4.9in, inset: (x: 1.6em, top: 1.3em, bottom: 1.5em), fill: white, stroke: .6pt + ink, {
        set align(left)
        text(size: 9pt, tracking: .14em, weight: "semibold", upper[In this manual])
        v(.2em)
        line(length: 100%, stroke: .5pt + ink.lighten(60%))
        v(.4em)
        // In reading order down the first column, then the second.
        let item(p) = [#ticked#h(1em)#link(page_label(p.path), text(fill: ink, p.title))]
        let half = calc.ceil(chapters.len() / 2)
        grid(
          columns: (1fr, 1fr),
          column-gutter: 1.5em,
          ..(chapters.slice(0, half), chapters.slice(half)).map(col => stack(spacing: .75em, ..col.map(item))),
        )
      })
      context box({
        place(dx: 4pt, dy: 5pt, block(width: 4.9in, height: measure(sheet).height, fill: ink.transparentize(88%)))
        sheet
      })
      v(1fr)
      line(length: 100%, stroke: .5pt + ink)
      v(.6em)
      set text(size: 9.5pt)
      grid(
        columns: 3,
        column-gutter: 1fr,
        align: center,
        row-gutter: .35em,
        ..([Online], [Typst Universe], [Source]).map(t => text(tracking: .1em, weight: "semibold", upper(t))),
        link(HOMEPAGE)[siefkenj.github.io/typst-examy],
        link(UNIVERSE)[typst.app/universe/package/examy],
        link(REPOSITORY)[github.com/siefkenj/typst-examy],
      )
    })
  })
}

// The contents in two columns, under a heading across the page (the
// outline's own title would sit in the first column).
#heading(numbering: none, outlined: false)[Contents]
#columns(2, gutter: 2.5em, outline(title: none, depth: 2))

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

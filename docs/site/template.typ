// The documentation site's building blocks: the page layout (`layout`), the
// examples that are rendered from their own source (`example`), links into
// the reference (`api`), and the reference's pages, one per export
// (`entry_page`).
// Compiled with Typst's HTML export (see site.typ).

#import "/src/lib.typ"
#import "/src/prelude.typ": e
#import "/docs/api.typ": ENTRIES, IMPORT, VERSION, alias_code, page_path, signatures, summary
#import "render.typ": full_source, has_key, render

#let REPOSITORY = toml("/typst.toml").package.repository

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
  (path: "reference.html", title: "Reference", file: "pages/reference.typ"),
)

/// The reference's pages, one per export (or group of exports that take the
/// same arguments, such as `question`/`part`/`subpart`), generated from the
/// package's declarations: `(path, title, entry)`.
#let REFERENCE_PAGES = ENTRIES.map(x => (path: page_path(x), title: x.names.join(", "), entry: x))

/// Every page, in reading order (for the links to the previous and next).
#let ALL_PAGES = PAGES + REFERENCE_PAGES

/// The label of the reference's anchor for the export `name`.
#let _anchor(name) = label("api-" + name)

/// A link to the reference page of the export `name`, shown as its name in
/// code. A label, so that Typst works out the link from wherever it is.
#let api(name, body: auto) = {
  assert(
    ENTRIES.any(x => name in x.names),
    message: "api: `" + name + "` is not an export of examy",
  )
  link(_anchor(name), if body == auto { raw(name) } else { body })
}

/// A link to another page of the guide, by its path.
#let page-link(path, body) = {
  assert(PAGES.any(p => p.path == path), message: "page-link: no page " + path)
  link(path, body)
}

/// A note set apart from the text.
#let note(kind: "note", body) = html.elem("aside", attrs: (class: "callout " + kind), body)

/// One of the package's screenshots, from examples/images/ (published with
/// the site by site.typ).
#let screenshot(name, alt, caption: none) = html.elem("figure", attrs: (class: "screenshot"), {
  html.elem("img", attrs: (src: "images/" + name, alt: alt, loading: "lazy"))
  if caption != none { html.elem("figcaption", caption) }
})

/// Several screenshots side by side.
#let screenshots(..figures) = html.elem("div", attrs: (class: "screenshots"), figures.pos().join())

// ---------------------------------------------------------------------------
// Examples

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
/// The example is also shown as a whole document, which compiles as it is in
/// a document of its own (see `full_source`), in a second code block, hidden
/// until the reader asks for it. The code, the whole document, and these
/// options are written into the page as `data-` attributes too, for the live
/// editor (live.ts) to pick up.
#let example(code, key: auto, wrap: auto, width: 12cm, height: none, inset: 0pt) = {
  // An import line shows the version this site documents, whatever the page
  // says, so that a new version needs no change to the pages.
  let src = code.text.replace(regex("@preview/examy:\d+\.\d+\.\d+"), "@preview/examy:" + VERSION)
  let key = if key == auto { has_key(src) } else { key }
  let full = full_source(src, VERSION, wrap: wrap)
  let views = if key { ((false, "Exam"), (true, "Answer key")) } else { ((false, none),) }
  html.elem(
    "figure",
    attrs: (
      class: "example" + if key { " with-key" } else { "" },
      data-source: src,
      data-full: full,
      data-wrap: repr(wrap),
      data-width: repr(width),
      data-height: repr(height),
      data-inset: repr(inset),
    ),
    {
      html.elem("div", attrs: (class: "example-code"), {
        html.elem("div", attrs: (class: "code-short"), raw(src, lang: "typ", block: true))
        html.elem("div", attrs: (class: "code-full", hidden: ""), raw(full, lang: "typ", block: true))
      })
      html.elem("div", attrs: (class: "example-output"), {
        for (solutions, label) in views {
          html.elem("div", attrs: (class: "paper", data-solutions: repr(solutions)), {
            if label != none { html.elem("span", attrs: (class: "paper-label"), label) }
            html.frame(render(src, solutions: solutions, wrap: wrap, width: width, height: height, inset: inset))
          })
        }
      })
    },
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

/// One argument of a reference entry.
#let _arg(owner, a) = html.elem("div", attrs: (class: "arg", id: owner + "." + a.name), {
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
})

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
#let entry_heading(x) = {
  x.names.map(n => html.elem("code", n)).join(", ")
  html.elem("span", attrs: (class: "kind"), x.kind)
}

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
    html.elem("h2", if x.kind == "element" and not x.show-signature [Fields] else [Arguments])
    x.args.map(a => _arg(x.names.first(), a)).join()
  }
}

/// The reference's index: every export, with a link to its page and what it
/// is in a line. Each keeps an anchor of its name here, where the reference
/// once documented them all.
#let reference_index() = html.elem("ul", attrs: (class: "api-index"), for x in ENTRIES {
  html.elem("li", attrs: (id: x.names.first()), {
    for n in x.names.slice(1) { html.elem("span", attrs: (id: n)) }
    html.elem("span", attrs: (class: "api-names"), x.names.map(n => api(n)).join(", "))
    html.elem("span", attrs: (class: "api-summary"), doc(summary(x.desc)))
  })
})

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

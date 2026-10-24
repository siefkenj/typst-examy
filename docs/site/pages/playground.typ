#import "../template.typ": playground_layout

// The playground: a whole document, edited and compiled in the browser, on a
// page of its own (see playground.ts, which builds the editor, the preview
// and their controls in the `playground` element below; and site.typ, which
// makes the page). Until the editor has loaded, or without it, the
// document's code is shown as it is.

/// The document the playground starts from: the package's template.
#let SOURCE = read("/template/main.typ")

#let playground-page() = playground_layout(html.elem(
  "div",
  attrs: (class: "playground", data-source: SOURCE),
  {
    html.elem("section", attrs: (class: "playground-source", aria-label: "Document"), {
      html.elem("div", attrs: (class: "playground-code"), raw(SOURCE, lang: "typ", block: true))
    })
    html.elem("section", attrs: (class: "playground-output", aria-label: "Preview"), {
      html.elem("div", attrs: (class: "playground-preview"), html.elem(
        "p",
        attrs: (class: "playground-placeholder"),
        [The preview appears here once the Typst compiler has loaded.],
      ))
    })
  },
))

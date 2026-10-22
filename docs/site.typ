// The documentation site, built with Typst's bundle and HTML export: every
// page, the stylesheet, and the screenshots, in one compilation.
//
//   docs/site/build.sh        # writes _site/ (npm run build adds the editor)
//
// which runs
//
//   typst compile --root . --features bundle,html -f bundle docs/site.typ _site
//
// The reference is generated from the package's own declarations (see
// api.typ), and every example is rendered by the package from the code it
// shows (see `example` in site/template.typ), so neither can fall out of
// date with the package.

#import "site/template.typ": PAGES, REFERENCE_PAGES, entry_heading, entry_page, layout, output_css, paged_documents
#import "site/pages/rubrics.typ": PAGED_EXAMPLES as RUBRIC_EXAMPLES
#import "logo/logo.typ": examy-logo

#for p in PAGES {
  document(p.path, title: p.title, layout(p, include "site/" + p.file, heading: p.at("heading", default: auto)))
}

// The reference: a page per export, generated from its declaration.
#for p in REFERENCE_PAGES {
  document(p.path, title: p.title, layout(p, entry_page(p.entry), heading: entry_heading(p.entry)))
}

// The examples shown as images of a paged rendering, rather than in HTML
// frames, which do not keep where things are (see `example`'s `paged-name`).
#for ex in RUBRIC_EXAMPLES.values() {
  paged_documents(ex)
}

// The stylesheet, with the look of the examples' output from the template
// (`output_css`), which the PDF is drawn with too.
#asset("style.css", read("site/style.css") + "\n" + output_css())
#asset("favicon.svg", read("site/favicon.svg"))

// The logo heading the front page (see PAGES in site/template.typ), rendered
// from logo/logo.typ with its name drawn as outlines.
#document("logo.svg", {
  set page(width: auto, height: auto, margin: 0pt, fill: none)
  examy-logo(width: 240pt)
})

// The live editor (site/live.ts, bundled by Vite into live.js; see
// vite.config.ts): editing an example recompiles it in the
// browser with typst.ts, from the package's source and the same render.typ
// the site is built with. Its files are published as one manifest, mapping
// each file's path in the compiler's virtual file system to its text.
// build.sh passes the list of the package's files, which Typst cannot
// list itself; without it, the site is built without the editor.
#let LIVE_FILES = sys.inputs.at("live-files", default: none)
#if LIVE_FILES != none {
  let paths = LIVE_FILES.split(",").filter(p => p != "") + ("typst.toml", "docs/site/render.typ", "docs/site/live-main.typ", "docs/site/live-full.typ")
  asset("live/files.json", json.encode(paths.map(p => ("/" + p, read("/" + p))).to-dict(), pretty: false))
}

// The screenshots of whole documents, which an inline example cannot show
// (cover pages, page footers), are those make_dist.sh renders for the README.
#for name in (
  "cover.png",
  "question-page.png",
  "quiz.png",
  "quiz-solutions.png",
  "multiple-choice.png",
  "multiple-choice-key.png",
  "solutions.png",
  "solutions-key.png",
) {
  asset("images/" + name, read("/examples/images/" + name, encoding: none))
}

// The document the live editor (live.js) compiles in the browser, with
// typst.ts: one view of one example, compiled by render.typ exactly as the
// site's own build compiles it. The example's code is the file
// /example.typ; how to compile it comes in `sys.inputs`, as the example's
// `data-` attributes give it (see `example` in template.typ): `solutions`
// ("true" or "false"), and `wrap`, `width`, `height`, and `inset`, each as
// Typst code.

#import "render.typ": render

#let input(name, default) = eval(sys.inputs.at(name, default: default))

#set page(width: auto, height: auto, margin: 0pt)
#render(
  read("/example.typ"),
  solutions: sys.inputs.at("solutions", default: "false") == "true",
  wrap: input("wrap", "auto"),
  width: input("width", "12cm"),
  height: input("height", "none"),
  inset: input("inset", "0pt"),
)

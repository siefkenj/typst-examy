// The examy logo: the mark (mark.svg, drawn by mark.typ) above the name,
// which is set as text, so it can be selected and searched in a PDF.
//
//   #import "/docs/logo/logo.typ": examy-logo
//   #examy-logo(width: 160pt)
//
// Compiled on its own, this file is the logo with its name drawn as outlines,
// for the README (make_dist.sh renders it):
//
//   typst compile docs/logo/logo.typ docs/logo/logo.svg

#let NAVY = rgb("#0b1622")

#let examy-logo(width: 200pt, ink: NAVY) = {
  // Positions are in the units the mark was drawn in, where it is 388 wide;
  // `u` turns them into lengths at the requested width.
  let u = width / 388
  box(width: width, height: 390 * u, {
    place(image("mark.svg", width: width, alt: ""))
    // The name: Libertinus Serif Semibold, sized so it spans 364 units, its
    // baseline 355 units below the top of the mark.
    context {
      let style = (font: "Libertinus Serif", weight: "semibold", fill: ink, bottom-edge: "baseline")
      let size = 100pt * (364 * u / measure(text(..style, size: 100pt)[examy]).width)
      let name = text(..style, size: size)[examy]
      place(dx: 4 * u, dy: 355 * u - measure(name).height, name)
    }
  })
}

#set page(width: auto, height: auto, margin: 0pt, fill: none)
#examy-logo(width: 240pt)

// The examy logo's mark: a swash italic e with a curling checklist tucked
// behind it, drawn with Typst's curves. Its shapes were traced from an
// AI-generated sketch (Microsoft Designer), in the sketch's pixel
// coordinates, which `mark` crops and scales.
//
// logo.typ sets the name beside it as text and places the mark from
// mark.svg, which is this file compiled. After changing the drawing,
// regenerate it:
//
//   typst compile docs/logo/mark.typ docs/logo/mark.svg

// A smooth closed (or open) curve through `pts` (Catmull-Rom as cubics). A
// point written (x, y, true) is a corner: the curve turns there sharply.
#let spline(pts, closed: true) = {
  let n = pts.len()
  let xy(p) = (p.at(0), p.at(1))
  let corner(p) = p.len() > 2 and p.at(2)
  let get(i) = if closed { pts.at(calc.rem(i + n, n)) } else { pts.at(calc.max(0, calc.min(n - 1, i))) }
  let cubic(i) = {
    let (p0, p1, p2, p3) = (get(i - 1), get(i), get(i + 1), get(i + 2))
    let (a, b, c, d) = (xy(p0), xy(p1), xy(p2), xy(p3))
    let t1 = if corner(p1) { ((c.at(0) - b.at(0)) / 3, (c.at(1) - b.at(1)) / 3) } else {
      ((c.at(0) - a.at(0)) / 6, (c.at(1) - a.at(1)) / 6)
    }
    let t2 = if corner(p2) { ((c.at(0) - b.at(0)) / 3, (c.at(1) - b.at(1)) / 3) } else {
      ((d.at(0) - b.at(0)) / 6, (d.at(1) - b.at(1)) / 6)
    }
    curve.cubic(
      ((b.at(0) + t1.at(0)) * 1pt, (b.at(1) + t1.at(1)) * 1pt),
      ((c.at(0) - t2.at(0)) * 1pt, (c.at(1) - t2.at(1)) * 1pt),
      (c.at(0) * 1pt, c.at(1) * 1pt),
    )
  }
  let start = xy(pts.first())
  (curve.move((start.at(0) * 1pt, start.at(1) * 1pt)),)
  range(if closed { n } else { n - 1 }).map(cubic)
  if closed { (curve.close(mode: "straight"),) }
}

#let navy = rgb("#0b1622")

// The swash e on its own, in the coordinates it was measured in.
#let scroll-e-glyph(fill: navy) = curve(
  fill: fill,
  fill-rule: "even-odd",
  // Outside: over the head, down the hairline crossbar, round the bowl and
  // out along the tail to its rounded end, then back under and up the left.
  // The bowl and the left side are sampled from ellipses fitted to the
  // sketch's edges, so they stay smooth.
  ..spline((
    (250, 73.8), (268, 73.3), (286, 77.3), (298, 85.3), (304.5, 96), (307.1, 110), (305.1, 124),
    (299.5, 138), (290.5, 152), (279.2, 164), (266, 174.5), (249, 185.2), (225, 195.9), (201, 203.5),
    (177, 209.1), (165, 211.1), (154.5, 212.3, true),
    (155.9, 234.6), (160.8, 254.3), (168.8, 272), (179.8, 287.5), (193.4, 300.3), (209.4, 310.3),
    (227.5, 317), (247.2, 320.6), (268.1, 320.7), (289.9, 317.5), (306, 312.4), (322, 305.2),
    (338, 295.7), (348, 288.6), (355, 284), (362, 282), (367.5, 284.5), (369.5, 289.5), (366, 294.5),
    (358, 298.2), (346, 304.5), (330, 312.1), (314, 318.4), (298, 323.7), (282, 328.4), (266, 331.9),
    (247, 335.1), (228.2, 337.5), (189.9, 336.6), (154.6, 327.8), (124.3, 311.8), (101, 289.4),
    (85.9, 262), (80, 231.3), (83.6, 199.1), (96.6, 167.3), (118.1, 137.7), (146.9, 112.3),
    (181.2, 92.4), (219, 79.2),
  )),
  // The eye.
  ..spline((
    (155.3, 200.6, true), (177, 198.4), (201, 192.5), (225, 182.6), (237, 175.3), (249, 165.4),
    (259.5, 152), (263.6, 144), (266.2, 136), (267.4, 128), (266.5, 120), (263.5, 112), (256.5, 104),
    (243.6, 98.6), (230.7, 97.6), (217.4, 100.3), (204.1, 106.7), (191.5, 116.3), (180.1, 128.9),
    (170.4, 143.8), (162.7, 160.5), (157.5, 178.3),
  )),
)

// The checklist sheet behind the e, curling over at its top right.
#let scroll-e-paper(lines: rgb("#a2a5a9"), boxes: rgb("#8a9198"), check: rgb("#a3392b")) = {
  let pts(..ps) = ps.pos().map(p => (p.at(0) * 1pt, p.at(1) * 1pt))
  // Front of the sheet; its foot is hidden behind the bowl of the e.
  place(curve(
    fill: gradient.linear(
      (rgb("#f8f3ec"), 0%), (rgb("#f3eee5"), 50%), (rgb("#e6ded2"), 80%), (rgb("#d8cfc1"), 100%),
      angle: 120deg,
    ),
    stroke: (paint: rgb("#d6cfc3"), thickness: 0.6pt, join: "round"),
    ..spline((
      (328, 83.8), (345, 83.6), (370, 83.5), (400, 83.5), (440, 83.5, true), (444, 85.5, true),
      (436, 101), (427, 123), (418, 147), (410, 168), (402, 192), (394, 215), (386, 239), (376, 265),
      (364, 285, true),
      (346, 302), (318, 316), (280, 325), (240, 323), (212, 315), (192, 307, true),
      // The left edge levels off (concave up) as it bends in behind the bowl.
      (210, 298), (227, 283), (243, 262), (260, 232), (280, 191), (300, 148), (313, 112), (318.5, 95),
      (321.5, 88),
    )),
  ))
  // The underside of the curl.
  place(curve(
    fill: gradient.linear(rgb("#9b9ea6"), rgb("#afadb0"), rgb("#c8c5bf"), angle: 70deg),
    ..spline((
      (441, 84.5, true), (446.5, 86), (450.5, 93), (453.5, 110), (454.5, 130), (453.5, 147.5, true),
      (417.5, 148, true), (425, 125), (431, 107), (437, 92),
    )),
  ))
  // The boxes hang off one guide curve that follows the slant of the sheet:
  // every box's left side lies on it and every right side on the same curve
  // `bw` further right. The rules start from the same guide.
  let guide(y) = 323 - 0.4 * (y - 122) - 0.0003 * calc.pow(y - 122, 2)
  let (bw, bh, gap) = (25, 24.5, 14)
  let rows = (122, 162.5, 203, 243.5)
  let rule(x, y, length, paint: lines) = place(line(
    start: (x * 1pt, y * 1pt),
    end: ((x + length) * 1pt, (y + length * 0.03) * 1pt),
    stroke: (
      thickness: 3.4pt,
      cap: "round",
      paint: gradient.linear(
        (paint.lighten(40%), 0%), (paint, 22%), (paint, 65%), (paint.lighten(50%), 100%),
      ),
    ),
  ))
  rule(guide(106), 106, 76)
  for (i, top) in rows.enumerate() {
    let bottom = top + bh
    let (tl, bl) = (guide(top), guide(bottom))
    place(curve(
      stroke: (paint: if i == 0 { navy } else { boxes }, thickness: if i == 0 { 3pt } else { 2.6pt }, join: "miter"),
      curve.move((tl * 1pt, top * 1pt)),
      curve.line(((tl + bw) * 1pt, top * 1pt)),
      curve.line(((bl + bw) * 1pt, bottom * 1pt)),
      curve.line((bl * 1pt, bottom * 1pt)),
      curve.close(),
    ))
    rule(guide(top + 5) + bw + gap, top + 5, 44)
    rule(guide(bottom - 1) + bw + gap, bottom - 1, 40)
  }
  // The red check in the first box, running out past its corner.
  let (x0, y0) = (guide(122), 122)
  place(curve(
    stroke: (paint: check, thickness: 3.8pt, cap: "round", join: "round"),
    curve.move(((x0 + 2) * 1pt, (y0 + 8) * 1pt)),
    curve.line(((x0 + 6.5) * 1pt, (y0 + 18.5) * 1pt)),
    curve.line(((x0 + 31) * 1pt, (y0 - 4) * 1pt)),
  ))
}

// The mark, cropped to the e and its sheet, on a transparent background.
#let mark(width: 256pt) = {
  let (x0, y0, x1, y1) = (74, 66, 462, 345)
  scale(width / ((x1 - x0) * 1pt) * 100%, reflow: true, box(
    width: (x1 - x0) * 1pt,
    height: (y1 - y0) * 1pt,
    place(dx: -x0 * 1pt, dy: -y0 * 1pt, {
      scroll-e-paper()
      place(scroll-e-glyph())
    }),
  ))
}

// Compiled on its own, this file is the mark (mark.svg); importing it shows
// nothing.
#set page(width: auto, height: auto, margin: 0pt, fill: none)
#mark()

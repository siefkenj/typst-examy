// An exam's own `fr` heights (a segment's of `fr` answer boxes, a
// division's `height`) where a share of the page comes to nothing, and as
// `config`'s internal `_fr-unit` lays them out, which the documentation's
// examples, in blocks of no fixed height, set to 1cm.
//
// On a page of no fixed height, an `fr` segment is as tall as what it holds:
// a badge at the `"end"` after an `fr` box takes a line of its own, below
// the box, not over what follows (it used to be drawn over the next part's
// badge). With `_fr-unit`, `2fr` lays out exactly as its length, `2cm`;
// inside a division of fixed `height`, `fr` boxes are shares of it, as
// without `_fr-unit`; and a box of `height: 2fr` is 2cm tall.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 12cm, margin: (x: 1.5cm, y: 1cm))
#set text(size: 10pt)
#show: e.prepare()

/// A mark recording where it is, under a case's name and the way it is
/// laid out.
#let mark(case, way) = [#metadata((case: case, way: way))<mark>]
#let at(case, way) = {
  let p = query(<mark>).find(m => m.value == (case: case, way: way)).location().position()
  (x: p.x, y: p.y)
}

// --- a page of no fixed height ---
#page(height: auto)[
  #rule[A page of no fixed height: "(1 point)" on its own line, below part (a)'s box, above part (b).]
  #exam(points-position: "end", points-format: p => [#metadata(p)<badge>(#p points)])[
    #question(points: 2)[What is $2 + 2$?]
    #question[
      #part(points: 1)[Name a prime number. #answer-box(height: 1fr)[]]
      #part(points: 3)[#metadata("b")<part-b>Prove there are infinitely many.]
    ]
  ]
]
#context {
  let badge = query(<badge>).find(b => b.value == 1).location().position().y
  let b = query(<part-b>).first().location().position().y
  // On the line above: more than the 7pt the top of a badge on the same
  // line is above the mark.
  assert(badge + 12pt < b, message: "part (a)'s badge at " + repr(badge) + ", part (b) at " + repr(b))
}

// --- `_fr-unit`: `fr` heights as lengths; inside a fixed height, shares ---
#let CASES = (
  (
    "A question of height 2fr, with _fr-unit: 1cm, as one of 2cm",
    way => {
      show: e.set_(config, ..if way == "unit" { (_fr-unit: 1cm) })
      exam[
        #question(height: if way == "unit" { 2fr } else { 2cm })[Room.]
        #question[#mark(0, way)Next.]
      ]
    },
  ),
  (
    "An fr box with _fr-unit: 1cm, then 2cm: the next question 1cm lower",
    way => {
      show: e.set_(config, _fr-unit: if way == "unit" { 1cm } else { 2cm })
      exam[
        #question[Room below. #answer-box(width: 100%, height: 1fr)[]]
        #question[#mark(1, way)Next.]
      ]
    },
  ),
  (
    "fr boxes in a question of height 3cm share it, with _fr-unit or without",
    way => {
      show: e.set_(config, ..if way == "unit" { (_fr-unit: 1cm) })
      exam[
        #question(height: 3cm)[
          Two boxes. #answer-box(width: 100%, height: 1fr)[] #answer-box(width: 100%, height: 2fr)[]
        ]
        #question[#mark(2, way)Next.]
      ]
    },
  ),
)

// --- with `_fr-unit: 1cm`, a box of `height: 2fr` is 2cm tall ---
#pagebreak()
#rule[With `_fr-unit: 1cm`, a box of `height: 2fr` is 2cm tall, below its question's text.]
#{
  show: e.set_(config, _fr-unit: 1cm)
  exam[
    #question[
      Room below.
      #answer-box(width: 100%, height: 2fr)[#metadata("top")<box>#place(bottom)[#metadata("bottom")<box>]]
    ]
  ]
}
#context {
  let y(v) = query(<box>).find(m => m.value == v).location().position().y
  // Each mark is inside the box's inset (5pt), at its top and its bottom.
  let tall = y("bottom") - y("top") + 2 * 5pt
  assert(calc.abs((tall - 2cm).to-absolute().pt()) < .5, message: repr(tall))
}

// --- `_fr-unit: 1fr`: in a block of fixed height on a page of no fixed
// height, `fr` boxes share the block, as on a page of fixed height ---
#let in-block(way) = block(height: 4cm, stroke: .5pt + luma(200), {
  show: e.set_(config, ..if way == "unit" { (_fr-unit: 1fr) })
  [#metadata((case: 3, way: way, top: true))<block-top>]
  exam[
    #question[Room below. #answer-box(width: 100%, height: 1fr)[]]
    #question[#mark(3, way)Next.]
  ]
})
#page(height: auto)[
  #rule[A page of no fixed height, `_fr-unit: 1fr`: the box fills the 4cm block, "Next." at its bottom.]
  #in-block("unit")
]
#pagebreak()
#rule[The same block on a page of fixed height, without `_fr-unit`.]
#in-block("other")
#context {
  let below(way) = {
    let top = query(<block-top>).find(m => m.value.way == way).location().position().y
    at(3, way).y - top
  }
  assert.eq(below("unit"), below("other"), message: "case 3")
}

#for (i, (desc, doc)) in CASES.enumerate() {
  for way in ("unit", "other") {
    pagebreak()
    rule[#desc: #if way == "unit" [with `_fr-unit`] else [the other way]]
    doc(way)
  }
}

#context {
  assert.eq(at(0, "unit"), at(0, "other"), message: "case 0")
  let d = at(1, "other").y - at(1, "unit").y
  assert(calc.abs((d - 1cm).to-absolute().pt()) < .5, message: "case 1: " + repr(d))
  assert.eq(at(2, "unit"), at(2, "other"), message: "case 2")
}

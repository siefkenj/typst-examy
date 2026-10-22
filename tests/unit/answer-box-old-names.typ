// `answer-box`'s `default_height` and `default_width`, the names
// `default-height` and `default-width` had in 0.4.0, are still accepted, on
// a call and in a set rule: a box given a field by its old name lays out
// exactly as one given it by its name now. Given both names, the name now
// wins; a call's old name wins over a set rule's name now, as any call does.
// Each case is laid out both ways, on a page of its own, and every mark
// placed after a box must land in the same place.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 11cm, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)

/// A mark, after a box, recording where it is under the case's name.
#let mark(case, way, n) = [#metadata((case: case, way: way, n: n))<mark>·]

/// The fields, by their old names (`way` is `"old"`) or by their names now.
#let named(way, height, width) = if way == "old" {
  (default_height: height, default_width: width)
} else {
  (default-height: height, default-width: width)
}

#let CASES = (
  (
    "on the call, in an exam",
    way => exam(show-solutions: true)[
      #question[Inline: #answer-box(..named(way, 2.5cm, 3cm))[#solution[42]] #mark(0, way, 1)]
      #question[Blank: #answer-box(width: 100%, ..named(way, 1.5cm, 3cm))[] #mark(0, way, 2)]
    ],
  ),
  (
    "in a set rule, before the exam and inside it",
    way => {
      show: e.set_(answer-box, ..named(way, 1.5cm, 3cm))
      exam[
        #question[Inline: #answer-box[] #mark(1, way, 1)]
        #[
          #show: e.set_(answer-box, ..named(way, 2.5cm, 1cm))
          #question[Blank: #answer-box(width: 100%)[] #mark(1, way, 2)]
        ]
      ]
    },
  ),
  (
    "both names given (the name now wins), and a call's old name over a rule's name now",
    way => {
      show: e.set_(answer-box, default-height: 3cm)
      exam[
        #question[Both: #answer-box(
            width: 100%,
            ..if way == "old" { (default_height: 1cm, default-height: 2cm) } else { (default-height: 2cm) },
          )[] #mark(2, way, 1)]
        #question[Call: #answer-box(width: 100%, ..named(way, 1.5cm, 2cm))[] #mark(2, way, 2)]
      ]
    },
  ),
  (
    "outside any exam",
    way => {
      [Name: #answer-box(..named(way, 1.5cm, 4cm))[] #mark(3, way, 1)]
      answer-box(width: 100%, ..named(way, 1.5cm, 4cm))[]
      mark(3, way, 2)
    },
  ),
)

#for (i, (desc, doc)) in CASES.enumerate() {
  for way in ("old", "now") {
    if i > 0 or way == "now" { pagebreak() }
    rule[#desc: by the #if way == "old" [old names] else [names now]]
    doc(way)
  }
}

#context {
  let marks = query(<mark>)
  let at(case, way, n) = {
    let p = marks.find(m => m.value == (case: case, way: way, n: n)).location().position()
    (p.x, p.y)
  }
  for (i, _) in CASES.enumerate() {
    let ns = marks.filter(m => m.value.case == i and m.value.way == "old").map(m => m.value.n)
    assert(ns.len() > 0, message: "case " + str(i) + " left no marks")
    for n in ns {
      assert.eq(at(i, "old", n), at(i, "now", n), message: "case " + str(i) + ", mark " + str(n))
    }
  }
}

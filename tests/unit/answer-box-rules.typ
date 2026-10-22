// `answer-box` is an elembic element, so set rules give its fields. In an
// exam, the exam draws its boxes itself, from the fields set rules give them
// (see `resolve_boxes`), so that it reads each as the `box` or `block` it is:
// a box whose fields come from set rules lays out exactly as one given the
// same fields on its call. Each case is laid out both ways, on a page of its
// own, and every mark placed after a box must land in the same place.
// The rules the exam cannot follow are errors (see tests/fail/answer-box-*).
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 9cm, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)

/// A mark, after a box, recording where it is under the case's name. It
/// shows a dot: content after an `fr` box with nothing visible in it is
/// left out of the exam.
#let mark(case, way, n) = [#metadata((case: case, way: way, n: n))<mark>·]

#let CASES = (
  (
    "fr from a set rule before the exam",
    way => [
      #show: e.set_(answer-box, width: 100%, height: if way == "set" { 1fr } else { auto })
      #exam[
        #question[First. #answer-box(..if way == "call" { (height: 1fr) })[] #mark(0, way, 1)]
        #question[Second. #answer-box(height: 2fr)[] #mark(0, way, 2)]
      ]
    ],
  ),
  (
    "fr from a set rule scoped inside the exam",
    way => exam[
      #question[Fixed. #answer-box(width: 100%)[] #mark(1, way, 1)]
      #[
        #show: e.set_(answer-box, ..if way == "set" { (height: 1fr) })
        #question[Fills. #answer-box(width: 100%, ..if way == "call" { (height: 1fr) })[] #mark(1, way, 2)]
      ]
      #question[Fixed again. #answer-box(width: 100%)[] #mark(1, way, 3)]
    ],
  ),
  (
    "width, blank height, and outline from rules (one an apply); a body starting with a box",
    way => {
      let given = (width: 100%, default-height: 2.5cm, stroke: (bottom: .5pt))
      show: e.apply(e.set_(answer-box, ..if way == "set" { given } else { (:) }))
      exam(show-solutions: true)[
        #question[#answer-box(..if way == "call" { given })[First line #linebreak() second] #mark(2, way, 1)]
        #question[#part[#answer-box(..if way == "call" { given })[]] #mark(2, way, 2)]
      ]
    },
  ),
  (
    "a box redefined with .with, in a set rule's scope",
    way => {
      let ab = answer-box.with(width: 100%)
      show: e.set_(answer-box, ..if way == "set" { (stroke: none, height: 1.5cm) })
      exam[
        #question[Blank space. #ab(..if way == "call" { (stroke: none, height: 1.5cm) })[] #mark(3, way, 1)]
      ]
    },
  ),
  (
    "fr from a set rule for a box inside align, which draws itself",
    way => {
      show: e.set_(answer-box, ..if way == "set" { (height: 1fr) })
      exam[
        #question[Text. #align(center)[#answer-box(width: 50%, ..if way == "call" { (height: 1fr) })[]] #mark(4, way, 1)]
        #question[After. #mark(4, way, 2)]
      ]
    },
  ),
  (
    "fr from a set rule inside the align around a box, which draws itself",
    way => exam[
      #question[Text. #align(center)[
        #show: e.set_(answer-box, ..if way == "set" { (height: 1fr) })
        #answer-box(width: 50%, ..if way == "call" { (height: 1fr) })[]
      ] #mark(5, way, 1)]
      #question[After. #mark(5, way, 2)]
    ],
  ),
  (
    "a box outside any exam, drawing itself",
    way => {
      show: e.set_(answer-box, ..if way == "set" { (width: 100%, default-height: 1.5cm) })
      [Name: #answer-box(width: 4cm, ..if way == "call" { (default-height: 1.5cm) })[] #mark(6, way, 1)]
      answer-box(..if way == "call" { (width: 100%, default-height: 1.5cm) })[]
      mark(6, way, 2)
    },
  ),
)

#for (i, (desc, doc)) in CASES.enumerate() {
  for way in ("set", "call") {
    if i > 0 or way == "call" { pagebreak() }
    rule[#desc: fields from #if way == "set" [set rules] else [the calls]]
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
    let ns = marks.filter(m => m.value.case == i and m.value.way == "set").map(m => m.value.n)
    assert(ns.len() > 0, message: "case " + str(i) + " left no marks")
    for n in ns {
      assert.eq(at(i, "set", n), at(i, "call", n), message: "case " + str(i) + ", mark " + str(n))
    }
  }
}

// A `revoke` of a rule that is not on answer boxes, in a document whose
// boxes no rule sets, is no error.
#pagebreak()
#rule[A `revoke` of a `config` rule, around answer boxes no rule sets: no error]
#show: e.named("maroon", e.set_(config, solution-color: maroon))
#exam(show-solutions: true)[
  #question[A maroon solution. #answer-box(width: 100%, height: 1cm)[#solution[Maroon.]]]
  #[
    #show: e.revoke("maroon")
    #question[The default color again. #answer-box(width: 100%, height: 1cm)[#solution[Blue.]]]
  ]
]

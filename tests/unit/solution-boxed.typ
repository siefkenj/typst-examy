// `solution`'s `boxed`, which 0.4 had, is still accepted, on a call and in a
// set rule, and ignored: a solution given `boxed: false` is drawn in its box
// all the same, laying out exactly as one not given it, wherever it stands.
// Each case is laid out both ways, on a page of its own, and every mark
// placed after a solution must land in the same place.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 9cm, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)
#show: e.set_(config, show-solutions: true)

/// A mark, after a solution, recording where it is under the case's name.
#let mark(case, way, n) = [#metadata((case: case, way: way, n: n))<mark>·]

/// `boxed: false` (`way` is `"old"`), or nothing.
#let unboxed(way) = if way == "old" { (boxed: false) } else { (:) }

#let CASES = (
  (
    "on the call, in an exam",
    way => exam[
      #question[Inline: the capital is #solution(..unboxed(way))[Paris] #mark(0, way, 1), of course.]
      #question[On its own: #solution(..unboxed(way))[An answer.] #mark(0, way, 2)]
    ],
  ),
  (
    "in a set rule, in answer boxes",
    way => {
      show: e.set_(solution, ..unboxed(way))
      exam[
        #question[Inline: #answer-box(width: 100%)[The capital is #solution[Paris] #mark(1, way, 1), of course.]]
        #question[Own paragraph: #answer-box(width: 100%)[Prompt.

            #solution[An answer.

              Second para.]
          ] #mark(1, way, 2)]
        // The key's solution hangs below the box, as it takes no height.
        #v(1.2cm)
        #question[Over lines: #answer-box(width: 100%)[#solution(otherwise: [\_\_\_\_\_\_])[42] #mark(
              1,
              way,
              3,
            )]]
      ]
    },
  ),
  (
    "outside any exam",
    way => [The capital is #solution(..unboxed(way))[Paris] #mark(2, way, 1), of course.],
  ),
)

#for (i, (desc, doc)) in CASES.enumerate() {
  for way in ("old", "now") {
    if i > 0 or way == "now" { pagebreak() }
    rule[#desc: #if way == "old" [`boxed: false`] else [not given]]
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
  // Boxed, a solution is wider than its text by its padding.
  let plain = measure[Paris].width
  let drawn = measure(solution(boxed: false)[Paris]).width
  assert(drawn > plain + 5pt, message: "boxed: false still draws the box: " + repr((plain, drawn)))
}

// `config`'s `answer-box-height`, `answer-box-width`,
// `answer-box-default-height` and `answer-box-default-width` give the fields
// of the answer boxes that neither their call nor a set rule on `answer-box`
// gives. A box whose fields come from `config` lays out exactly as one given
// the same fields on its call, and a box given a field, on its call or by a
// set rule, keeps it whatever `config` says, `none` and `auto` included.
// Each case is laid out both ways, on a page of its own, and every mark
// placed after a box must land in the same place.
// The rules on those options the exam cannot follow are errors (see
// tests/fail/answer-box-config-*).
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 11cm, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)

/// A mark, after a box, recording where it is under the case's name. It
/// shows a dot: content after an `fr` box with nothing visible in it is
/// left out of the exam.
#let mark(case, way, n) = [#metadata((case: case, way: way, n: n))<mark>·]

/// `args` if the case is laid out with `way`, else nothing.
#let on(way, given, args) = if way == given { args } else { (:) }

#let CASES = (
  (
    "fr and full width from the exam's options",
    way => exam(..on(way, "config", (answer-box-height: 1fr, answer-box-width: 100%)))[
      #question[First. #answer-box(..on(way, "call", (height: 1fr, width: 100%)))[] #mark(0, way, 1)]
      #question[Second. #answer-box(height: 2fr, ..on(way, "call", (width: 100%)))[] #mark(0, way, 2)]
    ],
  ),
  (
    "fr from a config rule scoped inside the exam",
    way => exam[
      #question[Fixed. #answer-box(width: 100%)[] #mark(1, way, 1)]
      #[
        #show: e.set_(config, ..on(way, "config", (answer-box-height: 1fr)))
        #question[Fills. #answer-box(width: 100%, ..on(way, "call", (height: 1fr)))[] #mark(1, way, 2)]
      ]
      #question[Fixed again. #answer-box(width: 100%)[] #mark(1, way, 3)]
    ],
  ),
  (
    "the height of a blank box and the width of an inline one, from config",
    way => {
      show: e.set_(config, ..on(way, "config", (answer-box-default-height: 2.5cm, answer-box-default-width: 3cm)))
      let given = on(way, "call", (default-height: 2.5cm, default-width: 3cm))
      exam(show-solutions: true)[
        #question[Inline: #answer-box(..given)[#solution[42]] #mark(2, way, 1)]
        #question[Blank: #answer-box(width: 100%, ..given)[] #mark(2, way, 2)]
      ]
    },
  ),
  (
    "a box's own none and auto win over config's (the call way has no config)",
    way => exam(..on(way, "config", (answer-box-height: 3cm, answer-box-width: 50%)))[
      #question[A prompt it fits: #answer-box(height: none, width: auto)[Explain:] #mark(3, way, 1)]
      #question[Blank: #answer-box(height: none, width: 100%)[] #mark(3, way, 2)]
      #question[On the key too: #answer-box(height: auto, width: 100%)[Hi] #mark(3, way, 3)]
    ],
  ),
  (
    "a set rule on answer-box wins over config, and a call over both",
    way => {
      show: e.set_(config, answer-box-height: 3cm, answer-box-default-height: 3cm)
      show: e.set_(answer-box, ..on(way, "config", (height: 1cm)))
      exam[
        #question[Set: #answer-box(width: 100%, ..on(way, "call", (height: 1cm)))[] #mark(4, way, 1)]
        #question[Call: #answer-box(width: 100%, height: none, default-height: 1.5cm)[] #mark(4, way, 2)]
      ]
    },
  ),
  (
    "fr from config for boxes inside align, which draw themselves",
    way => exam(..on(way, "config", (answer-box-height: 1fr)))[
      #question[#align(center)[#answer-box(width: 50%, ..on(way, "call", (height: 1fr)))[]] #mark(5, way, 1)]
      #question[Text. #align(right)[#answer-box(width: 50%, ..on(way, "call", (height: 1fr)))[]] #mark(5, way, 2)]
      #question[After. #mark(5, way, 3)]
    ],
  ),
  (
    "boxes outside any exam, drawing themselves",
    way => {
      show: e.set_(config, ..on(way, "config", (answer-box-width: 100%, answer-box-default-height: 1.5cm)))
      [Name: #answer-box(width: 4cm, ..on(way, "call", (default-height: 1.5cm)))[] #mark(6, way, 1)]
      answer-box(..on(way, "call", (width: 100%, default-height: 1.5cm)))[]
      mark(6, way, 2)
    },
  ),
)

#for (i, (desc, doc)) in CASES.enumerate() {
  for way in ("config", "call") {
    if i > 0 or way == "call" { pagebreak() }
    rule[#desc: fields from #if way == "config" [config] else [the calls]]
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
    let ns = marks.filter(m => m.value.case == i and m.value.way == "config").map(m => m.value.n)
    assert(ns.len() > 0, message: "case " + str(i) + " left no marks")
    for n in ns {
      assert.eq(at(i, "config", n), at(i, "call", n), message: "case " + str(i) + ", mark " + str(n))
    }
  }
}

// A `reset` of `config` around answer boxes, where no `config` rule sets
// their options, is no error.
#pagebreak()
#rule[An `e.reset(config)` around answer boxes, with no `answer-box-..` option set: no error]
#exam(points-position: "end")[
  #[
    #show: e.reset(config)
    #question(points: 1)[A box. #answer-box(width: 100%, height: 1cm)[]]
  ]
]

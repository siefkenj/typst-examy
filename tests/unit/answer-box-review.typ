// Regressions from review of the elembic `answer-box`: an unnamed `config`
// rule before a named one, a box's own label inside an exam, `e.reset`
// rules around boxes (followed, as elembic follows them), a `select` rule
// undone before the exam, another package's element named `answer-box`,
// and `numbering-full` with an array of `numbering`s.
#import "/src/lib.typ": *
#import "/src/refs.typ": display_number
#import "/tests/record.typ": data, rule

#set page(width: 10cm, height: 9cm, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)
#show: e.prepare()

/// A mark, after a box, recording where it is under the case's name.
#let mark(case, way, n) = [#metadata((case: case, way: way, n: n))<mark>·]

/// Where the mark `(case, way, n)` landed.
#let at(case, way, n) = {
  let p = query(<mark>).find(m => m.value == (case: case, way: way, n: n)).location().position()
  (p.page, p.x, p.y)
}

// --- an unnamed rule on `config` before a named one: elembic records no
// names for the first, which the exam's reading of the rules skips ---
#rule[An unnamed `config` rule before a named one, around an exam with a box: no error.]
#{
  show: e.set_(config, answer-box-height: 1cm, points-position: "end")
  show: e.named("named", e.set_(config, show-solutions: true))
  exam[#question(points: 2)[A box. #answer-box(width: 100%)[#solution[42]]]]
}

// --- a box's own label, inside an exam, is kept on what the exam draws ---
#pagebreak()
#rule[A labelled box inside an exam: a `query` finds it, and a link goes to it.]
#exam[
  #question[Labelled: #answer-box(width: 100%, height: 1cm)[] <labelled-box>]
  #question[A #link(<labelled-box>)[link to it].]
]
#context assert.eq(query(<labelled-box>).len(), 1, message: "the labelled box")

// --- `e.reset` around boxes inside an exam is followed: the boxes after it
// are drawn as with no rules, so they land where boxes no rule set do ---
#let RESETS = (
  (
    "e.reset(answer-box), after a set rule before the exam",
    way => {
      show: e.set_(answer-box, ..if way == "reset" { (default-height: 3cm, stroke: red) })
      exam[
        #[
          #show: if way == "reset" { e.reset(answer-box) } else { it => it }
          #question[Blank. #answer-box(width: 100%)[] #mark(0, way, 1)]
        ]
      ]
    },
  ),
  (
    "e.reset(config), after an answer-box option given to the exam",
    way => exam(..if way == "reset" { (answer-box-height: 3cm) })[
      #[
        #show: if way == "reset" { e.reset(config) } else { it => it }
        #question[Blank. #answer-box(width: 100%)[] #mark(1, way, 1)]
      ]
    ],
  ),
  (
    "e.reset(), with no rules on boxes at all",
    way => exam[
      #[
        #show: if way == "reset" { e.reset() } else { it => it }
        #question[Blank. #answer-box(width: 100%, height: 1cm)[] #mark(2, way, 1)]
      ]
    ],
  ),
  (
    "e.reset(answer-box), then a set rule after it",
    way => {
      show: e.set_(answer-box, ..if way == "reset" { (height: 3cm) })
      exam[
        #[
          #show: if way == "reset" { e.reset(answer-box) } else { it => it }
          #show: e.set_(answer-box, height: 1.5cm)
          #question[Set after. #answer-box(width: 100%)[] #mark(3, way, 1)]
        ]
      ]
    },
  ),
)

#for (desc, doc) in RESETS {
  for way in ("reset", "none") {
    pagebreak()
    rule[#desc: #if way == "reset" [with the reset] else [with no rules]]
    doc(way)
  }
}
#context for (i, _) in RESETS.enumerate() {
  assert.eq(at(i, "reset", 1).slice(1), at(i, "none", 1).slice(1), message: "reset case " + str(i))
}

// --- a `select` rule on boxes that a reset undoes before the exam is no
// longer in force, so no error ---
#pagebreak()
#rule[An `e.select` on answer boxes, reset before the exam: no error.]
#e.select(answer-box.with(height: 1cm), prefix: "tall", tall => {
  show tall: set text(red)
  show: e.reset(answer-box)
  exam[#question[A. #answer-box(width: 100%, height: 1cm)[]]]
})

// --- another package's element named `answer-box`, with a `1fr` height
// field, is not taken for examy's `fr` box: it takes only its own height ---
#let other-box = e.element.declare(
  "answer-box",
  prefix: "@preview/not-examy,v0.0.1",
  display: it => block(width: 100%, height: 1cm, stroke: .5pt + gray)[another package's box],
  fields: (e.field("height", e.types.any, default: none),),
)
#for (way, b) in (("other", other-box(height: 1fr)), ("block", block(width: 100%, height: 1cm))) {
  pagebreak()
  rule[Another package's `answer-box`, `height: 1fr`, in an `align`: #if way == "other" [the element] else [a 1cm block]]
  exam[
    #question[#align(left, b) #mark(4, way, 1)]
    #question[After. #mark(4, way, 2)]
  ]
}
#context for n in (1, 2) {
  assert.eq(at(4, "other", n).slice(1), at(4, "block", n).slice(1), message: "other box, mark " + str(n))
}

// --- `numbering-full` with an array of `numbering`s: an entry with a
// counting symbol for each level numbers them all; one with fewer follows
// the number above it, rather than repeating its symbol for every level ---
#pagebreak()
#rule[`numbering-full` with the default numbering, and with a mixed array.]
#let FULL = (
  (auto, (1,), "2."),
  (auto, (1, 1), "2(b)"),
  (auto, (1, 1, 1), "2(b)ii."),
  (("1.", "1.a.", "(i)"), (1, 1), "2.b."),
  (("1.", "1.a.", "(i)"), (1, 1, 1), "2.b(ii)"),
  ("1.a.i.", (1, 1, 1), "2.b.ii."),
)
#for (numbering, address, expected) in FULL {
  let got = if numbering == auto { display_number(address, full: true) } else {
    display_number(address, numbering: numbering, full: true)
  }
  assert.eq(got, expected, message: repr((numbering, address)))
}
#data(FULL.map(((n, a, x)) => (n, a, x)))
#exam(numbering-full: true)[
  #question[First.]
  #question[#part[A part.] #part(label: <full-b>)[Another, with #subpart[a.] #subpart[b.]]]
  #question[See @full-b.]
]

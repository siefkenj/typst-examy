// What is around `columns` holding an `fr` height, and what else a `columns` must
// keep of what it was given when it is drawn by the exam. See columns.typ for the
// `columns` themselves, and columns-split.typ for a page break in them. Errors for
// a division with a `height` are in tests/fail/columns-fr-height-*.typ; what is
// allowed there is at the end here.
#import "/src/lib.typ": *
#import "/src/rubric.typ": AREA, row_label
#import "/tests/record.typ": rule

#let (W, H, M) = (6.5in, 3.5in, .6in)
#set page(width: W, height: H, margin: M)
#set text(size: 9pt)
#show: e.prepare()

#let mark(name) = box[#metadata(name)#label(name)]
#let at(name) = query(label(name)).first().location().position()
#let near(a, b) = calc.abs((a - b) / 1pt) < 2
#let BOTTOM = H - M
/// The answer boxes of the exam just before this, by where the exam embeds them.
#let boxes() = {
  let rows = query(selector(<examy-regions>).before(here())).last().value.question-regions
  rows.map(r => r.answer-boxes).flatten()
}
#let height(b) = (b.bottom.y - b.top.y) * 1pt
#let shown(b) = [#calc.round(height(b) / 1pt, digits: 1)pt on page #b.top.page]
/// A note of the boxes' heights, in the margin below: out of the flow, as moving
/// what they are measured from would move them.
#let measured(all) = place(bottom + right, dy: 1.5em, text(8pt, all.map(shown).join[, ]))
#let BOX(h, fill) = answer-box(height: h, fill: fill.lighten(70%))[]
/// A `1fr` box outside any question, which the exam does not embed: one to read
/// from a marker in it.
#let MARKED(name, fill) = answer-box(height: 1fr, fill: fill.lighten(70%))[#mark(name)]

#rule[An `fr` height in `columns` in another element: the element shares the page with the box after it, as any `fr` height would]
#exam(embed-metadata: "question-regions")[
  #question[Q #pad(left: 1cm)[#columns(2)[#BOX(1fr, red)]] #BOX(1fr, blue)]
]
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert.eq(a.top.page, b.top.page, message: repr((a, b)))
  assert(near(height(a), height(b)), message: repr((a, b)))
  assert(height(b) > 40pt, message: repr(b))
  assert(near(b.bottom.y * 1pt, BOTTOM), message: repr(b))
}

#pagebreak()
#rule[In `columns` in `columns`, the `fr` box is still drawn by the exam: it has what is left of the page, and the box after them starts the next]
#exam(embed-metadata: "question-regions")[
  #question[Q #columns(2)[#columns(2)[#BOX(1fr, red)]] #BOX(1fr, blue)]
]
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert.eq(b.top.page, a.top.page + 1, message: repr((a, b)))
  for x in (a, b) { assert(near(x.bottom.y * 1pt, BOTTOM), message: repr(x)) }
  assert(height(b) > 100pt, message: repr(b))
}

#pagebreak()
#rule[In `columns` in `columns`, a column break after the inner ones is the outer's, and an `fr` box there has its column of the outer]
#exam(embed-metadata: "question-regions")[
  #question[Q #columns(2)[#columns(2)[#BOX(1fr, red)] #BOX(1fr, blue)]]
]
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert.eq(a.top.page, b.top.page, message: repr((a, b)))
  assert(b.top.x > a.top.x + 50, message: repr((a, b)))
  for x in (a, b) { assert(near(x.bottom.y * 1pt, BOTTOM), message: repr(x)) }
}

#pagebreak()
#rule[What is between `columns` holding an `fr` box and the next `fr` box, and takes no room, stays behind: the box still starts the next page, and has all of it]
#exam[
  #columns(2)[#MARKED("g-a", red)]
  #counter("x").update(1)
  #state("x").update(1)
  #metadata("x")
  #v(1cm)
  #MARKED("g-b", blue)
  #question[Next.#mark("g1")]
]
#context {
  assert.eq(at("g-b").page, at("g-a").page + 1, message: repr((at("g-a"), at("g-b"))))
  assert.eq(at("g1").page, at("g-b").page, message: "the box shares its page with what is after it")
  assert(at("g-b").y < at("g1").y)
}

#pagebreak()
#rule[In a question, too: its text taking no room between them is left where it is]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[#BOX(1fr, red)]
    #counter("x").update(1)
    #BOX(1fr, blue)
  ]
]
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert.eq(b.top.page, a.top.page + 1, message: repr((a, b)))
  assert(height(b) > 100pt, message: repr(b))
}

#pagebreak()
#rule[But text between them takes room: it goes on to the next page by itself, and the box has what is left of that page, with no page lost]
#exam[
  #columns(2)[#MARKED("g2-a", red)]
  #counter("x").update(1)
  Text.#mark("g2")
  #MARKED("g2-b", blue)
]
#context {
  assert.eq(at("g2-b").page, at("g2-a").page + 1, message: repr((at("g2-a"), at("g2-b"))))
  assert.eq(at("g2").page, at("g2-b").page)
}

#pagebreak()
#rule[After a page break in `columns` holding an `fr` box, those on the next page hold only text: they do not fill it, so the box after them is on that page too]
#exam[
  #columns(2)[#MARKED("h-a", red) #pagebreak() short#mark("h1")]
  #MARKED("h-b", blue)
]
#context {
  assert.eq(at("h1").page, at("h-a").page + 1)
  assert.eq(at("h-b").page, at("h1").page, message: repr((at("h1"), at("h-b"))))
  assert(at("h1").y < at("h-b").y, message: repr((at("h1"), at("h-b"))))
}

#pagebreak()
#rule[And `columns` that do hold one on that page fill it, and the box after them starts another]
#exam[
  #columns(2)[short#mark("h2") #pagebreak() #MARKED("h2-a", red)]
  #MARKED("h2-b", blue)
]
#context {
  assert.eq(at("h2-a").page, at("h2").page + 1)
  assert.eq(at("h2-b").page, at("h2-a").page + 1, message: repr((at("h2-a"), at("h2-b"))))
}

#pagebreak()
#rule[With each `1fr` a length of its own (`_fr-unit`), no box fills the page, and they all stay on it]
#{
  show: e.set_(config, _fr-unit: 1cm)
  exam(embed-metadata: "question-regions")[
    #question[Q. #columns(2)[#BOX(1fr, red)] #BOX(1fr, blue)]
  ]
}
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert.eq(a.top.page, b.top.page, message: repr((a, b)))
  assert(near(height(a), 1cm) and near(height(b), 1cm), message: repr((a, b)))
}

#pagebreak()
#set page(height: auto)
#rule[On a page of no fixed height, no box fills it either: one page]
#exam(embed-metadata: "question-regions")[
  #question[#mark("au1")Q. #columns(2)[#BOX(1fr, red)] #BOX(1fr, blue)]
  After.#mark("au2")
]
#context assert.eq(at("au2").page, at("au1").page, message: "one page: " + repr((at("au1"), at("au2"))))
#set page(height: H)

#pagebreak()
#rule[A label on `columns` a page break splits is on the first of them only, for it to be found]
#exam[
  #columns(2)[#question[#mark("l1")A] #pagebreak() #question[#mark("l2")B]] <split>
]
#context {
  let found = query(<split>)
  assert.eq(found.len(), 1)
  assert.eq(found.first().func(), columns)
  assert.eq(locate(<split>).page(), at("l1").page)
  assert.eq(at("l2").page, at("l1").page + 1)
}

#pagebreak(to: "odd")
#rule[`pagebreak(to: ..)` between questions, in a question, and in `columns`, keeps its `to`: each starts an odd page, past a blank one]
#exam[
  #question[#mark("t1")A]
  #pagebreak(to: "odd")
  #question[#mark("t2")B #pagebreak(to: "odd") #mark("t3")C]
  #columns(2)[#question[#mark("t4")D] #pagebreak(to: "odd") #question[#mark("t5")E]]
]
#context {
  let (p, ..rest) = ("t1", "t2", "t3", "t4", "t5").map(n => at(n).page)
  assert(calc.odd(p))
  assert.eq(rest, (p + 2, p + 4, p + 4, p + 6))
}

#pagebreak()
#rule[With no `to`, a `#set pagebreak(to: ..)` still applies]
#exam[
  #set pagebreak(to: "even")
  #question[#mark("u1")A]
  #pagebreak()
  #question[#mark("u2")B]
]
#context assert(calc.even(at("u2").page), message: repr(at("u2")))

#pagebreak()
#rule[With no `weak`, a `#set pagebreak(weak: ..)` or `#set colbreak(weak: ..)` still applies: two weak breaks in a row are one]
#exam[
  #set pagebreak(weak: true)
  #set colbreak(weak: true)
  #question[#mark("wk1")A]
  #pagebreak()
  #pagebreak()
  #question[#mark("wk2")B]
  #columns(2)[#question[#mark("wk3")C] #colbreak() #colbreak() #question[#mark("wk4")D]]
]
#context {
  assert.eq(at("wk2").page, at("wk1").page + 1)
  assert.eq(at("wk4").page, at("wk3").page, message: "one column on: " + repr((at("wk3"), at("wk4"))))
  assert(at("wk4").x > at("wk3").x, message: repr((at("wk3"), at("wk4"))))
}

#set page(width: W, height: 4in, margin: (left: .6in, right: 1.6in, y: .4in))
#let BLOCK = 2.5in
#let LEFT = .6in + (W - .6in - 1.6in - BLOCK) / 2
#let badges(page) = query(<badge>).filter(m => m.location().page() == page).map(m => m.location().position())
#let BADGE = p => [#metadata(p)<badge>#p p]

#pagebreak()
#rule[In an exam in a box of its own, points in the margin from `columns` are beside the exam, level with those from outside them, not out at the page's margin]
#align(center, block(width: BLOCK, align(left, exam(points-position: "margin-right", points-format: BADGE)[
  #question(points: 1)[#mark("b1")Outside the `columns`.]
  #columns(2)[
    #question(points: 2)[#mark("b2")In the first.]
    #colbreak()
    #question(points: 3)[#mark("b3")In the second.]
  ]
])))
#context {
  let drawn = badges(here().page())
  assert.eq(drawn.len(), 3, message: repr(drawn))
  for b in drawn { assert(near(b.x, drawn.first().x), message: repr(drawn)) }
  assert(near(drawn.first().x, LEFT + BLOCK + 9pt), message: repr(drawn))
  assert(drawn.first().x < W - 1.6in, message: "not out at the page's margin: " + repr(drawn))
}

#pagebreak()
#rule[The same on the left]
#align(center, block(width: BLOCK, align(left, exam(points-position: "margin-left", points-format: BADGE)[
  #question(points: 1)[#mark("c1")Outside the `columns`.]
  #columns(2)[
    #question(points: 2)[#mark("c2")In the first.]
    #colbreak()
    #question(points: 3)[#mark("c3")In the second.]
  ]
])))
#context {
  let drawn = badges(here().page())
  assert.eq(drawn.len(), 3, message: repr(drawn))
  for b in drawn { assert(b.x < LEFT, message: repr(drawn)) }
  assert(drawn.first().x > .6in, message: "not out at the page's margin: " + repr(drawn))
  for b in drawn { assert(near(b.x, drawn.first().x), message: repr(drawn)) }
}

#pagebreak()
#rule[And rubrics, in the margin beside the exam from every column, stacked]
#align(center, block(width: BLOCK, align(left, exam(show-rubrics: true, show-solutions: true)[
  #columns(2)[
    #question(points: 1)[In the first. #solution[So.#rubric(points: 1)[First]]]
    #colbreak()
    #question(points: 1)[In the second. #solution[So.#rubric(points: 1)[Second]]]
  ]
])))
#context {
  let (a, b) = query(AREA).map(m => m.value).filter(a => a.page == here().page())
  assert(a.top + a.h <= b.top, message: repr((a, b)))
  // Its height in its own lengths, which the documentation scales by (see
  // `_overhang` in docs/site/render.typ).
  assert(a.natural > 0pt, message: repr(a))
  let rows = query(selector.or(..range(40).map(k => row_label(k, "left")))).filter(m => m.location().page() == here().page())
  assert.eq(rows.len(), 2)
  for x in rows.map(m => m.location().position().x) {
    assert(x > LEFT + BLOCK and x < LEFT + BLOCK + .5in, message: "beside the exam: " + repr(x))
  }
}

#pagebreak()
#set page(width: W, height: 4in, margin: (inside: .5in, outside: 2in, y: .4in))
#rule[With mirrored margins, an exam in a box goes by the page it is on, on every page]
#block(width: 2.5in, exam(points-position: "margin-right", points-format: BADGE)[
  #columns(2)[#question(points: 1)[#mark("e1")Here.]]
  // Runs on to the next page by itself, in the box.
  #block(width: 100%, height: 3.1in)
  #columns(2)[#question(points: 1)[#mark("e2")And the next.]]
])
#context {
  assert.eq(at("e2").page, at("e1").page + 1)
  let (a,) = badges(at("e1").page)
  let (b,) = badges(at("e2").page)
  let inside(p) = if calc.odd(p) { .5in } else { 2in }
  assert(near(a.x, inside(at("e1").page) + 2.5in + 9pt), message: repr(a))
  assert(near(b.x, inside(at("e2").page) + 2.5in + 9pt), message: repr(b))
}

#set page(width: W, height: H, margin: M)
#pagebreak()
#rule[In a block of a `height`: text before `columns` holding an `fr` box, what takes no room after them, and an `fr` box in `columns` of each column of `columns`, are all as they are on a page: no error, and the block is its height]
#let QUESTION_H = 2in
#exam(embed-metadata: "question-regions")[
  #question(height: QUESTION_H)[
    #mark("f1")Before them.
    #columns(2)[
      #columns(2)[#BOX(1fr, red)]
      #colbreak()
      #columns(2)[#BOX(1fr, blue)]
    ]
    #counter("x").update(1)
    #v(1cm)
  ]
  #question[#mark("f2")Below the block.]
]
#context {
  let (a, b) = boxes()
  measured((a, b))
  assert(near(a.bottom.y * 1pt, b.bottom.y * 1pt), message: repr((a, b)))
  assert(a.top.page == b.top.page and b.top.x > a.top.x, message: repr((a, b)))
  // The block's height, and the gap below it.
  let below = at("f2").y - at("f1").y - QUESTION_H
  assert(0pt <= below and below < 15pt, message: repr((at("f1"), at("f2"))))
}

#pagebreak()
#set page(height: auto)
#rule[On a page of no fixed height, a `question` of `height: 1fr` is as tall as what it holds, so text after `columns` holding an `fr` box has room: no error]
#exam[
  #question(height: 1fr)[Q. #columns(2)[#answer-box(height: 1fr)[#mark("f3")]] Text after.#mark("f4")]
]
#context {
  assert.eq(at("f3").page, at("f4").page)
  assert(at("f4").y > at("f3").y, message: repr((at("f3"), at("f4"))))
}
#set page(height: H)

#pagebreak()
#rule[A `#set pagebreak(..)` in a question applies to a page break in it: part (b) starts an odd page]
#exam[
  #question[
    #set pagebreak(to: "odd")
    #part[#mark("s1")a]
    #pagebreak()
    #part[#mark("s2")b]
  ]
]
#context assert(calc.odd(at("s2").page) and at("s2").page > at("s1").page, message: repr((at("s1"), at("s2"))))

#pagebreak()
#rule[A rubric at the `"end"` of a part in `columns` in `columns` stays under it, before a column break of the outer ones: the inner are not drawn again]
#exam(show-rubrics: true, rubric-position: "end")[
  #question[
    #columns(2)[
      #columns(2)[#part(rubric: [#rubric(points: 1)[Card]])[#mark("v1")x]]
      #colbreak()
      #mark("v2")y
    ]
  ]
]
#context {
  let (card,) = query(AREA).filter(m => m.value.side == "end" and m.location().page() == at("v1").page).map(m => m.location().position())
  assert(card.x < W / 2, message: "in the first column of the outer: " + repr(card))
  assert(card.y > at("v1").y, message: repr((card, at("v1"))))
  assert(at("v2").x > W / 2, message: repr(at("v2")))
  assert.eq(at("v2").page, at("v1").page)
}

#pagebreak()
#rule[A rubric at the `"end"` after `columns` holding an `fr` box moves on to the next page by itself: the next question's `fr` box shares that page, with no page lost]
#exam(show-rubrics: true, rubric-position: "end")[
  #question(rubric: [#rubric(points: 1)[Card]])[#mark("w1")#columns(2)[#BOX(1fr, red)]]
  #question[#MARKED("w2", blue)]
]
#context {
  let (card,) = query(AREA).filter(m => m.value.side == "end" and m.location().page() == at("w1").page + 1)
  assert.eq(at("w2").page, card.location().page(), message: repr((at("w1"), at("w2"))))
}

#pagebreak()
#rule[But a rubric at the `"end"` in the `columns` stays in them: the next `fr` box still starts the next page]
#exam(show-rubrics: true, rubric-position: "end")[
  #columns(2)[#question(rubric: [#rubric(points: 1)[Card]])[#mark("x1")#BOX(1fr, red)]]
  #question[#MARKED("x2", blue)]
]
#context assert.eq(at("x2").page, at("x1").page + 1, message: repr((at("x1"), at("x2"))))

#pagebreak()
#rule[A `config` rule around `columns` the exam draws, with no question in its scope, is around no divisions: it may set what the exam reads once, and changes nothing]
#exam[
  #[
    #show: e.set_(config, numbering-full: true)
    Scratch:#mark("y1")
    #columns(2)[#answer-box(height: 1fr)[]]
  ]
]
#context assert(at("y1").x > 0pt)

// Rubrics: `rubric` read into a tree; anchors glued to the text beside them;
// the export as data; and, laid out, which division each rubric belongs
// to, rubrics that must not be lost, cards in the margin that never overlap,
// and an exam that lays out the same whether its rubrics are shown or not.
#import "/src/lib.typ": answer-box, config, e, exam, part, question, rubric, rubric-list, solution
#import "/src/rubric.typ": AREA, RECORD, rubric_tree
#import "/src/markers.typ": rubric_value
#import "/src/scan.typ": glue_rubrics, has_any_rubric
#import "/src/export.typ": division_number, latex, markdown, rubric_entries
#import "/tests/record.typ": cases, data, rule

#set page(width: 7in, height: 6in, margin: (left: .5in, right: 2.2in, y: .4in))
#set text(size: 10pt)
#show: e.prepare()

// ---------------------------------------------------------------------------
// The tree
// ---------------------------------------------------------------------------

#let shape(nodes) = nodes.map(n => if n.kind == "group" {
  (n.kind, n.annotation, n.note != none, shape(n.children))
} else if n.kind == "item" { (n.kind, n.points) } else { (n.kind,) })

#let TREES = (
  (
    [#rubric(points: 2)[Right] #rubric(points: -1)[Sign]],
    (("item", 2), ("item", -1)),
    "items in order",
  ),
  (
    [Accept equivalent forms. #rubric(points: 1)[Right] Ask first.],
    (("note",), ("item", 1), ("note",)),
    "text between items is kept as notes",
  ),
  (
    [#rubric(annotation: [pick one])[Derivative #rubric(points: 3)[Right] #rubric(points: 1)[Tried]]],
    (("group", [pick one], false, (("item", 3), ("item", 1))),),
    "a rubric holding rubrics is a group, with its annotation",
  ),
  (
    [#rubric[*Proof*

        Only with the right claim.
        #rubric(points: 1)[Structure]
        #rubric[Logic #rubric(points: -1)[Circular]]
      ]],
    (("group", none, true, (("item", 1), ("group", none, false, (("item", -1),)))),),
    "a group's title is its first paragraph, the rest a note; groups nest",
  ),
)
#for (src, expected, desc) in TREES {
  assert.eq(shape(rubric_tree(src)), expected, message: desc)
}
// The title of a group keeps its spaces (only blanks at its ends go).
#let titled = rubric_tree([#rubric[Two words #rubric(points: 1)[x]]]).first()
#assert.eq(titled.title, [Two words])
// An item keeps its annotation too.
#assert.eq(rubric_tree([#rubric(points: 1, annotation: "once")[x]]).first().annotation, "once")

#rule[The tree of rubric content: what each kind of content becomes]
#cases(
  ([Content], [Tree]),
  ..TREES.map(((src, expected, desc)) => ([#desc], data(expected))),
)

// ---------------------------------------------------------------------------
// Anchors glued to the text beside them
// ---------------------------------------------------------------------------

// The pieces of the glued sequence: "m" for a marker, "wj" for a joiner,
// "t" for anything else visible.
#let glued(c) = glue_rubrics(c).children.filter(k => k.func() != [ ].func()).map(k => {
  if rubric_value(k) != none { "m" } else if k.at("text", default: none) == "\u{2060}" { "wj" } else { "t" }
})
#let M = rubric(points: 1)[x]
#let GLUES = (
  ([Text.#M], ("t", "m", "wj"), "after text: glued after, so as not to end the paragraph"),
  ([#M Text], ("wj", "m", "t"), "starting a paragraph: glued before, onto its first line"),
  ([Text.#M #M], ("t", "m", "wj", "m", "wj"), "several after text: each glued after"),
  ([$ x $ #M], ("t", "m"), "after a block (an equation): left as it is"),
  ([Text.

    #M

    More.], ("t", "t", "m", "t", "t"), "alone in a paragraph: left as it is (a joiner would make a line)"),
)
#for (src, expected, desc) in GLUES {
  assert.eq(glued(src), expected, message: desc)
}
#rule[Rubric anchors glued to the text beside them (m: marker, wj: word joiner)]
#cases(([Case], [Pieces]), ..GLUES.map(((src, expected, desc)) => ([#desc], raw(expected.join(" ")))))

// ---------------------------------------------------------------------------
// The export as data
// ---------------------------------------------------------------------------

#let TEX = (
  ($x in RR$, "x \\in \\mathbb{R}"),
  ($p/q$, "\\frac{p}{q}"),
  ($sqrt(2)$, "\\sqrt{2}"),
  ($f'(x)$, "f'(x)"),
  ($x_1^2$, "x^{2}_{1}"),
  (${x in ZZ : x "is even"}$, "\\{x \\in \\mathbb{Z} : x \\text{is even}\\}"),
  ($a <= b != c$, "a \\le b \\neq c"),
  ($sin x$, "\\sin x"),
)
#for (eq, expected) in TEX {
  assert.eq(latex(eq).replace(regex(" +"), " ").trim(), expected, message: repr(eq))
}
#assert.eq(markdown([*Bold* and _it_ with $x$.]), "**Bold** and *it* with $x$.")
#assert.eq(markdown([$ x = 1 $]), "$$x = 1$$")

#let ENTRIES = rubric_entries(rubric_tree([
  #rubric(points: 1)[Right]
  A note.
  #rubric(annotation: [pick _one_])[*Proof*

    Its note.
    #rubric(points: 2)[All]
    #rubric[Logic #rubric(points: -1, annotation: [at most once])[Circular]]
  ]
  #rubric[Unscored]
]))
#assert.eq(ENTRIES, (
  (type: "item", points: 1, description: "Right", annotation: none),
  (type: "note", text: "A note."),
  (
    type: "group",
    title: "**Proof**",
    note: "Its note.",
    annotation: "pick *one*",
    items: (
      (type: "item", points: 2, description: "All", annotation: none),
      (
        type: "group",
        title: "Logic",
        note: none,
        annotation: none,
        items: ((type: "item", points: -1, description: "Circular", annotation: "at most once"),),
      ),
    ),
  ),
  (type: "item", points: none, description: "Unscored", annotation: none),
))
#assert.eq(division_number((0,)), "1")
#assert.eq(division_number((1, 0)), "2.1")
#assert.eq(division_number(("A", 2)), "A.3")
#assert.eq(division_number((none,)), none)

#rule[Export: Typst math as LaTeX, and a tree as entries, nested as it is]
#cases(([Typst], [LaTeX]), ..TEX.map(((eq, tex)) => (eq, raw(tex))))
#data(ENTRIES)

// ---------------------------------------------------------------------------
// Laid out
// ---------------------------------------------------------------------------

// The records of the exam numbered `n`, by the heading's title as text.
#let plain(c) = if type(c) == str { c } else if c.func() == [ ].func() { " " } else if c.has("text") { c.text } else if c.has("children") { c.children.map(plain).join() } else if c.has("body") { plain(c.body) } else { "" }
#let records(n) = query(RECORD).map(m => m.value).filter(r => r.exam == n)
#let summary(n) = records(n).map(r => (plain(r.heading.title).replace(sym.space.thin, " "), shape(r.nodes)))

// An exam with rubrics in every place one can be: the `rubric:` field, the
// text, a solution, an answer box, after a part (back in its question),
// first in a body that starts with a part, and between questions (no
// division's).
#let EXAM = [
  #question(points: 3, rubric: [#rubric(points: 0)[Blank]])[
    Prompt one#metadata("q1")<probe>.
    #answer-box(width: 100%, height: 1.2cm)[#solution[Answer.#rubric(points: 2)[Right]]]
    #part(points: 1)[A part.#rubric(points: 1)[Part item] #metadata("pa")<probe>]
    Back in the question.#rubric(points: -1)[After the part]
  ]
  Between questions.#rubric(points: 5)[Nobody's]
  #question[
    #rubric(points: 1)[First in the body]
    #part(points: 2)[Prompt two#metadata("q2")<probe>. #solution[Two.#rubric(points: 2)[Two right]]]
  ]
]
#assert(has_any_rubric(EXAM), message: "rubrics are found, in solutions too")
#assert(not has_any_rubric([#question[A #solution[B]]]))

#let EXPECTED = (
  ("Question 1", (("item", 2), ("item", -1), ("item", 0))),
  ("Question 1 (a)", (("item", 1),)),
  ("Question 2", (("item", 1),)),
  ("Question 2 (a)", (("item", 2),)),
)

// Shown, with solutions: exam 1.
#pagebreak(weak: true)
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: true)
  #exam(questions: EXAM)
]
// Not shown: exam 2.
#pagebreak()
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: false)
  #exam(questions: EXAM)
]
// Shown, solutions hidden: exam 3. A hidden solution keeps its rubrics.
#pagebreak()
#[
  #show: e.set_(config, show-solutions: false, show-rubrics: true)
  #exam(questions: EXAM)
]

#context {
  for n in (1, 2, 3) {
    assert.eq(summary(n), EXPECTED, message: "the rubrics of exam " + str(n))
  }
  // Shown or not, the exam lays out the same.
  let probes = query(<probe>).map(m => (value: m.value, pos: m.location().position()))
  let shown = probes.slice(0, 3)
  let hidden = probes.slice(3, 6)
  for (a, b) in shown.zip(hidden) {
    assert.eq((a.value, a.pos.x, a.pos.y), (b.value, b.pos.x, b.pos.y), message: "laid out the same, shown or not")
  }
  // Cards in a margin never overlap: each starts below the one before it.
  let areas = query(AREA).map(m => m.value).filter(a => a.side == "margin-right" and a.page == shown.first().pos.page)
  for (a, b) in areas.zip(areas.slice(1)) {
    assert(a.top + a.h <= b.top + .01pt, message: "cards overlap: " + repr((a, b)))
  }
}

// Stacking: three parts whose cards are taller than the room between them.
#pagebreak()
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: true)
  #let tall = [#rubric(points: 1)[One] #rubric(points: 1)[Two] #rubric(points: 1)[Three] #rubric(points: 1)[Four]]
  #exam(questions: [
    #question[
      Close together.
      #part(rubric: tall)[A.]
      #part(rubric: tall)[B.]
      #part(rubric: tall)[C.]
    ]
  ])
]
#context {
  let page = here().page()
  let areas = query(AREA).map(m => m.value).filter(a => a.page == page and a.side == "margin-right")
  assert.eq(areas.len(), 3)
  for (a, b) in areas.zip(areas.slice(1)) {
    assert(a.top + a.h <= b.top + .01pt, message: "stacked cards overlap")
    assert(b.top > b.y, message: "a card moved down below the one before it")
  }
}

// The left margin and the end.
#pagebreak()
#[
  #set page(margin: (left: 2.2in, right: .5in, y: .4in))
  #show: e.set_(config, show-solutions: true, show-rubrics: true, rubric-position: "margin-left")
  #exam(questions: [
    #question(points: 2, rubric: [#rubric(points: 0)[Blank]])[In the left margin. #solution[Yes.#rubric(points: 2)[Right]]]
  ])
]
#context assert(query(AREA).map(m => m.value).any(a => a.side == "margin-left"))
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: true, rubric-position: "end")
  #exam(questions: [
    #question(points: 2)[At the end, after the part. #part(points: 2)[Part. #solution[Yes.#rubric(points: 2)[Right]]]]
  ])
]

// ---------------------------------------------------------------------------
// Regressions
// ---------------------------------------------------------------------------

// Exams 7 to 9: a question whose body is a rubric and then a part split by a
// break. The rubric takes no room: "1." shares its line with "(a)" as it
// does with no rubric, shown or not, and it is still the question's.
#let SPLIT(r) = [#question[#r #part[Part A#metadata("split")<split>. #colbreak() More.]]]
#for (shown, r) in ((false, none), (false, rubric(points: 1)[In the question]), (true, rubric(points: 1)[In the question])) {
  pagebreak(weak: true)
  rule[A rubric before a split part: "1." and "(a)" share a line (#if r == none [no rubric] else if shown [shown] else [hidden])]
  [#show: e.set_(config, show-rubrics: shown)
    #exam(questions: SPLIT(r))]
}
#context {
  let at = query(<split>).map(m => m.location().position())
  assert.eq(at.len(), 3)
  for p in at.slice(1) { assert.eq((p.x, p.y), (at.first().x, at.first().y), message: "a rubric moved the layout") }
  for n in (8, 9) { assert.eq(summary(n), (("Question 1", (("item", 1),)),)) }
}

// Exam 10: rubrics at the `"end"`, of a question whose body starts with a
// part given a `height`: the question's rubric is drawn after the part, and
// recorded.
#pagebreak()
#rule[At the `"end"`: a question's rubric after a part with a `height` it starts with]
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: true, rubric-position: "end")
  #exam(questions: [
    #question(rubric: [#rubric(points: 2)[The question's]])[#part(height: 2cm, rubric: [#rubric(points: 1)[The part's]])[A part.]]
  ])
]
#context {
  assert.eq(summary(10), (("Question 1", (("item", 2),)), ("Question 1 (a)", (("item", 1),))))
  let ends = query(AREA).map(m => m.value).filter(a => a.side == "end" and a.id.exam == 10)
  assert.eq(ends.map(a => a.id.address.len()).sorted(), (1, 2), message: "both rubrics drawn")
}

// Exams 11 and 12: a rubric in an `answer-box`'s `solution:`, solutions
// shown and hidden: the question's either way.
#for shown in (true, false) {
  rule[A rubric in an answer box's `solution:`, solutions #if shown [shown] else [hidden]]
  [#show: e.set_(config, show-solutions: shown, show-rubrics: true)
    #exam(questions: [#question[Find $x$. #answer-box(width: 100%, height: 1cm, solution: [$x = 2$#rubric(points: 1)[Correct $x$]])[]]])]
}
#context for n in (11, 12) {
  assert.eq(summary(n), (("Question 1", (("item", 1),)),), message: "exam " + str(n))
}

// Exam 13: at the `"end"`, the rubric of a question given a `height` is
// drawn after its block, taking room of its own, not inside the block,
// where it would squeeze the `1fr` box out and run over the next question.
#rule[At the `"end"`: the rubric of a question with a `height` after its block]
#[
  #show: e.set_(config, show-solutions: true, show-rubrics: true, rubric-position: "end")
  #let five = range(5).map(i => rubric(points: 1)[Item #(i + 1)]).join()
  #exam(questions: [
    #question(height: 3cm, rubric: five)[Fixed#metadata("fixed")<fixed>. #answer-box(width: 100%, height: 1fr)[#place(bottom, [#metadata("box")<fixed>])]]
    #question[Next#metadata("next")<fixed>.]
  ])
]
#context {
  let at = query(<fixed>).map(m => (m.value, m.location().position().y)).to-dict()
  let card = query(AREA).map(m => m.value).filter(a => a.side == "end" and a.id.exam == 13)
  assert.eq(card.len(), 1)
  let top = query(AREA).filter(m => m.value.side == "end" and m.value.id.exam == 13).first().location().position().y
  // The box's bottom, near the block's.
  assert(at.box - at.fixed > 2cm, message: "the 1fr box keeps its room: " + repr(at))
  assert(top > at.fixed + 2.5cm, message: "the card is after the 3cm block")
  assert(at.next > top, message: "the next question is after the card")
}

// Exams 14 to 16: points badges in the margin a rubric is drawn in, at the
// "start" (in the text), and in the other margin. Badges and rubrics in one
// margin are stacked: the rubric starts below the badges on its first line,
// also when a question shares its line with a part, and a badge below a
// rubric that reaches down to it; elsewhere a rubric is level with its line.
#let BADGED = [
  #question(points: 2, rubric: [#rubric(points: 2)[Right]])[A question.]
  #question(rubric: [#rubric(points: 1)[Whole]])[#part(points: 3, rubric: [#rubric(points: 3)[Part]])[A part on its line.]]
]
#for pos in ("margin-right", "start", "margin-left") {
  pagebreak(weak: true)
  rule[Points badges #if pos == "start" [at the start] else [in the #pos], rubrics in the margin-right]
  [#show: e.set_(config, show-rubrics: true, points-position: pos)
    #exam(questions: BADGED)]
}
#context {
  let areas(n) = query(AREA).map(m => m.value).filter(a => a.id.exam == n)
  let cards(n) = areas(n).filter(a => a.id.address != none).map(a => a.top)
  let (badged, start, other) = (14, 15, 16).map(cards)
  assert.eq(badged.len(), 3)
  // Below the badge, about a line.
  for (a, b) in badged.zip(start) { assert(a - b > 8pt, message: "below the badge: " + repr((badged, start))) }
  // Badges and rubrics in one margin never overlap: each starts below the
  // one before it.
  let all = areas(14)
  assert.eq(all.len(), 5, message: "two lines of badges, three rubrics")
  for (a, b) in all.zip(all.slice(1)) { assert(a.top + a.h <= b.top + .01pt, message: repr((a, b))) }
  // A badge in the other margin is out of the way.
  for (a, b) in other.zip(start) { assert(calc.abs((a - b) / 1pt) < .01, message: repr((other, start))) }
}

// The export keeps escapes, shorthands, and symbols.
#let SYMBOLS = (
  ([5 \* 3 \_ x #sym.arrow a\#b], "5 * 3 _ x → a#b"),
  ([It's "quoted" -- \$5], "It's \"quoted\" – $5"),
)
#for (c, expected) in SYMBOLS { assert.eq(markdown(c), expected) }
#rule[Export: escapes, shorthands, and symbols as Markdown]
#cases(([Typst], [Markdown]), ..SYMBOLS.map(((c, md)) => (c, raw(md))))

// The rubrics on their own, and as data.
#pagebreak()
#rule[`rubric-list`: every rubric of the last exam]
#rubric-list()
#context {
  let exports = query(<examy-rubric>).map(m => m.value)
  // One per exam with rubrics, whether they are shown or not (exam 7 has
  // none); of those so far.
  assert.eq(exports.map(x => x.exam).filter(n => n <= 12), range(1, 7) + range(8, 13))
  // Exam 6: question 1 has no rubric of its own; its part has one.
  let six = exports.find(x => x.exam == 6)
  assert.eq(six.questions.map(q => (q.number, q.title, q.points)), (("1.1", "Question 1\u{2009}(a)", 2),))
  assert.eq(six.questions.first().rubric, ((type: "item", points: 2, description: "Right", annotation: none),))
}
#rule[The rubric data of the last exam, as `query(<examy-rubric>)` reads it]
#context data(query(<examy-rubric>).last().value)

// The width of the margin a card goes in, however the margin is given.
#import "/src/rubric.typ": _margin
#let MARGINS = (
  ((left: 1cm, right: 3cm), "margin-right", 3cm),
  ((x: 2cm), "margin-left", 2cm),
  // Bound on the left, the inside is the left of an odd page.
  ((inside: 1cm, outside: 4cm), "margin-right", page => if calc.odd(page) { 4cm } else { 1cm }),
  (5%, "margin-right", 5% * 7in),
  // On a page of `auto` width, as Typst has it: a ratio is of nothing, and
  // `auto` of A4's width, the height being `auto` too.
  ((right: 10% + 1cm, rest: .3in), "margin-right", 1cm, auto),
  (auto, "margin-right", 2.5 / 21 * 21cm, auto),
)
#for (m, side, expected, ..width) in MARGINS {
  let width = width.at(0, default: 7in)
  page(margin: m, width: width, height: auto, context {
    let w = _margin(side)
    let expected = if type(expected) == function { expected(here().page()) } else { expected }
    assert(calc.abs((w - expected).to-absolute() / 1pt) < .01, message: repr((m, w, expected)))
    [Margin #repr(m) (page width #repr(width)): the #side is #w.]
  })
}

// An exam with rubrics in the margin of a page of `auto` width.
#page(width: auto, height: auto, margin: (right: 2in, rest: .3in))[
  #show: e.set_(config, show-rubrics: true)
  #rule[A rubric in the margin of a page of `auto` width]
  #exam(questions: [#question(rubric: [#rubric(points: 1)[Given]])[A question on a page of `auto` width.]])
]

// Exams 18 and 19: rubrics in a run of solutions in an answer box with no
// height, which the first of the run draws (see `widen_par_solutions`):
// those of the rest of the run are found too, solutions shown and hidden.
#for shown in (true, false) {
  rule[Rubrics in a run of solutions in an answer box with no height, solutions #if shown [shown] else [hidden]]
  [#show: e.set_(config, show-solutions: shown, show-rubrics: true)
    #exam(questions: [#question[Two steps. #answer-box(width: 100%)[
          #solution[First step#rubric(points: 1)[Step one]]

          #solution[Second step#rubric(points: 2)[Step two]]
        ]]])]
}
#context for n in (18, 19) {
  assert.eq(summary(n), (("Question 1", (("item", 1), ("item", 2))),), message: "exam " + str(n))
}

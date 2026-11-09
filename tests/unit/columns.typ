// Questions, parts, and subparts inside `columns`: numbered, and given their
// points, as anywhere, and drawn in columns; what is outside the `columns` in
// the same question stays across the page. Column breaks are in or out of them
// as written (see columns-split.typ for page breaks), and `fr` heights share
// what is left of a column. Points and rubrics in a margin go to the page's
// margin from any column, and are stacked there, not drawn over the next column.
#import "/src/lib.typ": *
#import "/src/rubric.typ": AREA, leaders_anchor, row_label
#import "/tests/record.typ": cases, rule

#let (W, H, M) = (6.5in, 4.5in, .6in)
#set page(width: W, height: H, margin: M)
#set text(size: 9pt)
#show: e.prepare()

#let TEXT = [Where is the nearest grocery store from the train station?]
/// A marker to read a position from, in a box of its own to report the
/// baseline of its line, wherever it is in the line.
#let mark(name) = box[#metadata(name)#label(name)]
#let at(name) = query(label(name)).first().location().position()
/// Whether two lengths are the same, but for rounding.
#let near(a, b) = calc.abs((a - b) / 1pt) < .5
/// Whether a marker is in the first column, of those of this file's pages.
#let first_col(name) = at(name).x < W / 2
#let close_to_each(desc, ..xs) = assert(xs.pos().all(x => near(x, xs.pos().first())), message: desc + ": " + repr(xs.pos()))

// ---------------------------------------------------------------------------
// In the flow
// ---------------------------------------------------------------------------

#rule[Whole questions in `columns`, with text between them, and text and a question across the page around them]
#exam[
  Answer every question.#mark("intro")
  #columns(2)[
    #question(points: 2)[#mark("q1")#TEXT]
    #question[
      #mark("q2")#TEXT
      #part(points: 1)[#mark("q2a")In kilometres.]
      #part(points: 2)[In miles.]
    ]
    #colbreak()
    Answer in full sentences.#mark("between")
    #question(points: 1)[#mark("q3")#TEXT]
  ]
  Across the page again.#mark("after")
  #question(points: 4)[#mark("q4")#TEXT #TEXT]
  #context assert.eq(num-points(), 10)
]
#context {
  assert(first_col("q1") and first_col("q2a"))
  assert(not first_col("between") and not first_col("q3"))
  assert(at("q2").y > at("q1").y)
  close_to_each("the top of the second column", at("between").y, at("q1").y)
  assert(at("after").y > at("q2a").y, message: "below the columns, not beside them")
  assert(first_col("after") and first_col("q4"))
}

#pagebreak()
#rule[Parts in `columns` under a prompt across the page, with a part across the page after them: the spacing is the usual, and they are numbered on through it]
#exam[
  #question[
    Prompt, across the page. #mark("prompt")
    #columns(2)[
      #part(points: 1)[#mark("a")#TEXT #answer-box(height: 1cm)[]]
      #part[#mark("b")With subparts.
        #subpart(points: 1)[#mark("bi")One.]
        #subpart(points: 1)[Two.]
      ]
      #colbreak()
      #part(points: 1)[#mark("c")#TEXT]
    ]
    #part(points: 1)[#mark("d")Across the page: #TEXT #TEXT]
  ]
  #question[
    The same, with no `columns`. #mark("prompt2")
    #part(points: 1)[#mark("a2")#TEXT]
  ]
  #context assert.eq(num-points(), 6)
]
#context {
  assert(first_col("a") and first_col("b") and first_col("bi") and not first_col("c"))
  close_to_each("level with one another", at("a").y, at("c").y)
  close_to_each("below the prompt, as with no `columns`", at("a").y - at("prompt").y, at("a2").y - at("prompt2").y)
}

#pagebreak()
#rule[The question's own text inside the `columns`, before and between its parts: its number rides the first line; after them, its text is across the page]
#exam[
  #question[
    #columns(2)[
      #mark("own1")#TEXT
      #part(points: 1)[#mark("own-a")#TEXT]
      More of the question's text.#mark("own2")
      #part(points: 1)[#mark("own-b")#TEXT]
      #colbreak()
      Its text in the second column.#mark("own3")
      #part(points: 1)[#mark("own-c")#TEXT]
    ]
    Its text after them, across the page, ending in a long sentence to show that it is. #TEXT#mark("own4")
  ]
]
#context {
  assert(first_col("own1") and first_col("own2") and not first_col("own3"))
  assert(at("own-a").y > at("own1").y and at("own2").y > at("own-a").y and at("own-b").y > at("own2").y)
  close_to_each("the top of the second column", at("own3").y, at("own1").y)
  assert(at("own4").y > at("own-b").y)
}

#pagebreak()
#rule[A question that starts with `columns`, whose number shares a line with its first part; `columns` of a `#set columns(..)`, and two of them, of different counts, one after the other]
#exam[
  #question[
    #{
      set columns(gutter: 3em)
      columns(3)[
        #part(points: 1)[#mark("m1")First.]
        #colbreak()
        #part(points: 1)[#mark("m2")Second.]
        #colbreak()
        #part(points: 1)[#mark("m3")Third.]
      ]
    }
    #columns[
      #part(points: 1)[#mark("m4")Fourth.]
      #colbreak()
      #part(points: 1)[#mark("m5")Fifth.]
    ]
  ]
  #question[
    #columns(2)[
      #set text(fill: blue)
      #part(points: 1)[#mark("r1")A rule in the `columns`.]
      #set text(fill: red)
      #part(points: 1)[#mark("r2")Another.]
      #colbreak()
      #show: e.set_(config, points-position: "end")
      #part(points: 1, height: 2cm)[#mark("r3")A height, and a `config` rule. #answer-box(height: 1fr)[]]
    ]
  ]
]
#context {
  let third = (W - 2 * M - 2 * 3em.to-absolute()) / 3 + 3em.to-absolute()
  close_to_each("the gutter of a set rule", at("m2").x - at("m1").x, at("m3").x - at("m2").x, third)
  close_to_each("a line across", at("m1").y, at("m2").y, at("m3").y)
  // Two columns by default, with Typst's default gutter.
  let text_width = W - 2 * M
  close_to_each("two columns", at("m5").x - at("m4").x, (text_width + 4% * text_width) / 2)
  assert(at("m4").y > at("m1").y)
  assert(first_col("r1") and first_col("r2") and not first_col("r3"))
}

#pagebreak()
#rule[A column break right after the `columns` is not theirs: on this page of one column, it starts the next]
#exam[
  #question[
    #columns(2)[
      #part(points: 1)[#mark("b1")In the first column.]
      #colbreak()
      #part(points: 1)[#mark("b2")In the second.]
    ]
    #colbreak()
    #part(points: 1)[#mark("b3")On the next page, across it.]
  ]
]
#context {
  assert(not first_col("b2"))
  assert.eq(at("b2").page, at("b1").page)
  assert.eq(at("b3").page, at("b1").page + 1)
}

#pagebreak()
#rule[Many parts: the `columns` go on to the next page by themselves]
#exam[
  #question[
    A long question.
    #columns(2)[
      #for i in range(1, 15) [
        #part(points: 1)[#mark("long" + str(i))#TEXT #TEXT]
      ]
    ]
  ]
]
#context {
  assert.eq(at("long1").page + 1, at("long14").page)
  assert(first_col("long1"))
  assert(range(1, 15).any(i => not first_col("long" + str(i))))
}

#pagebreak()
#rule[A `colbreak` that stays in a `columns` inside a question with a `height`, with parts in them and with none: the block is still its height]
#exam[
  #question(height: 2cm)[
    #mark("h0")Prompt.
    #columns(2)[
      #part(points: 1)[#mark("h1")In the first column.]
      #colbreak()
      #part(points: 1)[#mark("h2")In the second.]
    ]
  ]
  #question(points: 1, height: 1.5cm)[
    #columns(2)[#mark("h3")No parts here. #colbreak() #mark("h4")Nor here.]
  ]
  #question(points: 1)[#mark("h5")After them.]
]
#context {
  assert(first_col("h1") and not first_col("h2"))
  close_to_each("level", at("h1").y, at("h2").y)
  assert(first_col("h3") and not first_col("h4"))
  assert(at("h5").y - at("h0").y >= 3.5cm.to-absolute(), message: repr((at("h0"), at("h5"))))
}

#pagebreak()
#rule[A label on a `columns` holding parts stays on them]
#exam[
  #question[
    Prompt.
    #columns(2)[#part(points: 1)[#TEXT]] <labelled>
  ]
]
#context {
  let found = query(<labelled>)
  assert.eq(found.len(), 1)
  assert.eq(found.first().func(), columns)
}

// ---------------------------------------------------------------------------
// `fr` heights
// ---------------------------------------------------------------------------

#pagebreak()
#rule[`fr` answer boxes share what is left of their own column, in the ratio of their heights, to the bottom of the page (their regions in the data the exam embeds)]
#exam(embed-metadata: "question-regions")[
  #question[
    Sketch these.
    #columns(2)[
      #part(points: 1)[A. #answer-box(height: 1fr)[]]
      #part(points: 1)[B. #answer-box(height: 2fr)[]]
      #colbreak()
      #part(points: 1)[C. #answer-box(height: 1fr)[]]
    ]
  ]
]
#context {
  let rows = query(selector(<examy-regions>).before(here())).last().value.question-regions
  let (a, b, c) = rows.slice(1).map(r => r.answer-boxes.first())
  let high(x) = x.bottom.y - x.top.y
  assert(calc.abs(high(b) / high(a) - 2) < .1, message: "1fr to 2fr: " + repr((high(a), high(b))))
  // All the way down, in both columns, as tall as the page's text goes.
  let bottom = (H - M) / 1pt
  assert(calc.abs(b.bottom.y - bottom) < 2 and calc.abs(c.bottom.y - bottom) < 2, message: repr((b, c, bottom)))
  assert(a.top.x == b.top.x and c.top.x > b.top.x, message: repr((a, b, c)))
}
#pagebreak()
#rule[An `fr` box takes the rest of the page, so that a question after the `columns` starts the next]
#exam[
  #question[
    #columns(2)[
      #part(points: 1)[#mark("fr1")A. #answer-box(height: 1fr)[]]
      #colbreak()
      #part(points: 1)[B. #answer-box(height: 1fr)[]]
    ]
  ]
  #question(points: 1)[#mark("fr2")After them.]
]
#context assert.eq(at("fr2").page, at("fr1").page + 1)

/// The answer boxes of the rows of the last exam before here to leave regions:
/// each row's, as `(height, page, bottom)`.
#let frs() = {
  let rows = query(selector(<examy-regions>).before(here())).last().value.question-regions
  rows.map(r => r.answer-boxes.map(x => (high: x.bottom.y - x.top.y, page: x.top.page, x: x.top.x, bottom: x.bottom.y)))
}
#let reaches_bottom(x) = calc.abs(x.bottom - (H - M) / 1pt) < 2

#pagebreak()
#rule[With no parts: one `fr` box in each column is 1fr in each, not 2fr between them, to the bottom of the page; the question after them starts the next, and its own `fr` box has it all]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[
      #answer-box(height: 1fr)[]
      #colbreak()
      #answer-box(height: 1fr)[]
    ]
  ]
  #question[#answer-box(height: 1fr)[]]
]
#context {
  let (q1, q2) = frs()
  let (a, b) = q1
  assert(a.x < b.x and a.page == b.page, message: repr(q1))
  assert(reaches_bottom(a) and reaches_bottom(b), message: repr(q1))
  assert.eq(q2.first().page, a.page + 1)
  assert(q2.first().high > 100 and reaches_bottom(q2.first()), message: repr(q2))
}

#pagebreak()
#rule[An `fr` box of the question's own after `columns` holding one starts the next page, and gets all of it, not a sliver below the `columns`]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[#part(points: 1)[#answer-box(height: 1fr)[]]]
    #answer-box(height: 1fr)[]
  ]
]
#context {
  let (own, part) = frs()
  assert.eq(own.first().page, part.first().page + 1)
  assert(part.first().high > 100 and own.first().high > 100, message: repr((part, own)))
}

#pagebreak()
#rule[So does `columns` holding an `fr` box after a question's own `fr` box, which is then not squeezed out by them]
#exam(embed-metadata: "question-regions")[
  #question[#answer-box(height: 1fr)[]]
  #question[#columns(2)[#part(points: 1)[#answer-box(height: 1fr)[]]]]
]
#context {
  let (q1, _, a) = frs()
  assert.eq(a.first().page, q1.first().page + 1)
  assert(q1.first().high > 100 and a.first().high > 100, message: repr((q1, a)))
}

#pagebreak()
#rule[Text after `columns` holding an `fr` box goes on to the next page by itself, and an `fr` box after that text has what is left of that page; a page break there adds no blank page]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[#part(points: 1)[#mark("fi1")#answer-box(height: 1fr)[]]]
    #mark("fi2")Text after them.
    #answer-box(height: 1fr)[]
  ]
  #question[
    #columns(2)[#part(points: 1)[#mark("fi3")#answer-box(height: 1fr)[]]]
    #pagebreak()
    #mark("fi4")On the next page.
  ]
]
#context {
  assert.eq(at("fi2").page, at("fi1").page + 1)
  let own = frs().first().first()
  assert.eq(own.page, at("fi2").page)
  assert(reaches_bottom(own), message: repr(own))
  assert.eq(at("fi4").page, at("fi3").page + 1)
}

#pagebreak()
#rule[In a block of a `height`, an `fr` box in `columns` shares the block's height with the other column's, with no page to move on to]
#exam(embed-metadata: "question-regions")[
  #question(height: 3cm)[
    #mark("hf0")
    #columns(2)[
      #part(points: 1)[#answer-box(height: 1fr)[]]
      #colbreak()
      #part(points: 1)[#answer-box(height: 1fr)[]]
    ]
  ]
  #question(points: 1)[#mark("hf1")Just below it.]
]
#context {
  let (_, a, b, _) = frs()
  assert.eq(at("hf0").page, at("hf1").page)
  assert(a.first().high < 3cm / 1pt and calc.abs(a.first().high - b.first().high) < 1, message: repr((a, b)))
  assert(a.first().x < b.first().x)
}

// ---------------------------------------------------------------------------
// In the margins, and at the end
// ---------------------------------------------------------------------------

#let LEFT_RIGHT = (left: 1.6in, right: 2.2in, y: .5in)
#let badge(p) = [#metadata(p)<badge>(#p p)]
/// The badges from page `n`.
#let badges(n) = query(<badge>).filter(m => m.location().page() == n).map(m => m.location().position())
#let areas(n, side) = query(AREA).map(m => m.value).filter(a => a.page == n and a.side == side)
/// The boxes of the rubrics on page `n`, of a rubric's left edges.
#let rubric_rows(n) = query(selector.or(..range(40).map(k => row_label(k, "left")))).filter(m => m.location().page() == n).map(m => m.location().position())
#let clear_of_each(items) = {
  for (a, b) in items.sorted(key: a => a.top).windows(2) {
    assert(a.top + a.h <= b.top + .01pt, message: "overlap: " + repr((a, b)))
  }
}

#set page(margin: LEFT_RIGHT)

#pagebreak()
#rule[Points in the right margin, from every column, stacked: those level with one another are not drawn over each other, nor over the next column]
#exam(points-position: "margin-right", points-format: badge)[
  #question[
    Prompt.
    #columns(2)[
      #part(points: 1)[#TEXT]
      #part(points: 2)[#TEXT]
      #colbreak()
      #part(points: 3)[#TEXT]
      #part(points: 4)[#TEXT]
    ]
  ]
]
#context {
  let n = here().page()
  let edge = W - LEFT_RIGHT.right
  let drawn = badges(n)
  assert.eq(drawn.len(), 4)
  assert(drawn.all(p => p.x >= edge), message: repr(drawn))
  clear_of_each(areas(n, "margin-right"))
}

#pagebreak()
#rule[Points in the left margin, from every column]
#exam(points-position: "margin-left", points-format: badge)[
  #columns(2)[
    #question(points: 1)[#TEXT]
    #colbreak()
    #question(points: 2)[#TEXT]
  ]
]
#context {
  let n = here().page()
  let drawn = badges(n)
  assert.eq(drawn.len(), 2)
  assert(drawn.all(p => p.x <= LEFT_RIGHT.left), message: repr(drawn))
  clear_of_each(areas(n, "margin-left"))
}

#pagebreak()
#rule[Points in the margin from the `columns` and from after them, in the same exam, are stacked together]
#exam(points-position: "margin-right", points-format: badge)[
  #question[
    #columns(3)[
      #part(points: 1)[A]
      #colbreak()
      #part(points: 2)[B]
      #colbreak()
      #part(points: 3)[C]
    ]
    #part(points: 4)[Across the page.]
  ]
]
#context {
  let n = here().page()
  assert.eq(badges(n).len(), 4)
  assert.eq(areas(n, "margin-right").len(), 4)
  clear_of_each(areas(n, "margin-right"))
}

#pagebreak()
#rule[Each stays level with its question if it can: the third question's points go in the room between those of the first two, so they do not read in the order of the questions]
#exam(points-position: "margin-right", points-format: badge)[
  #columns(2)[
    #question(points: 1)[First.]
    #v(1in)
    #question(points: 2)[Second.]
    #colbreak()
    #question(points: 3)[Third.]
  ]
]
#context {
  let (first, second, third) = areas(here().page(), "margin-right")
  assert(first.top < third.top and third.top < second.top, message: repr((first, second, third)))
  assert(near(second.top, second.y), message: "the second has not moved: " + repr(second))
}

#pagebreak()
#rule[Rubrics in the right margin, from every column, stacked with the points there, their leaders running to them]
#exam(show-solutions: true, show-rubrics: true, points-position: "margin-right", points-format: badge)[
  #columns(2)[
    #question(points: 2)[
      #TEXT
      #solution[By the rule,#rubric(points: 1)[Uses the rule] and so on.#rubric(points: 1)[Finishes]]
    ]
    #colbreak()
    #question(points: 1, rubric: [#rubric(points: 1)[Right]])[#TEXT]
  ]
]
#context {
  let n = here().page()
  clear_of_each(areas(n, "margin-right"))
  assert.eq(areas(n, "margin-right").len(), 4)
  // Those written in its text: the one given as `rubric:` has no leader.
  let rows = rubric_rows(n)
  assert.eq(rows.len(), 2)
  let edge = W - LEFT_RIGHT.right
  assert(rows.all(p => p.x >= edge), message: repr(rows))
}

#pagebreak()
#rule[A question that runs on into the next column: the leader of the rubric there starts at the rubric, as it is drawn from the top of the block in that column, not from the question's start]
#exam(show-solutions: true, show-rubrics: true)[
  #columns(2)[
    #question(points: 2)[
      #mark("run1")#lorem(70)
      #solution[#mark("run2")By the rule,#rubric(points: 2)[Uses the rule] and so on.]
    ]
  ]
]
#context {
  let n = here().page()
  assert(first_col("run1"))
  assert.eq(at("run1").page, at("run2").page)
  let text_width = W - LEFT_RIGHT.left - LEFT_RIGHT.right
  let second = LEFT_RIGHT.left + (text_width + 4% * text_width) / 2
  assert(at("run2").x >= second, message: repr(at("run2")))
  // From the question's own start, what is measured from the second column
  // would land a column to the right. It is drawn from where this is.
  let anchors = range(40).map(leaders_anchor).map(l => query(l)).flatten().filter(m => m.location().page() == n)
  assert.eq(anchors.len(), 1)
  let from = anchors.first().location().position()
  assert(from.x >= second and from.x < second + 1in, message: repr(from))
  // At the top of the column, level with the question's first line.
  assert(from.y <= at("run1").y and from.y >= at("run1").y - 12pt, message: repr((from, at("run1"))))
}

#pagebreak()
#rule[A column break at the end of `columns` in a question not all in them: the rubric at the `"end"` is after them, across the page, and the `columns` are drawn just once]
#exam(show-rubrics: true, rubric-position: "end")[
  #question(rubric: [#rubric(points: 1)[The whole question]])[
    #columns(2)[#part(points: 1)[#mark("tr1")#TEXT] #colbreak()]<trailing>
  ]
  #question(points: 1)[#mark("tr2")#TEXT]
]
#context {
  assert.eq(query(<trailing>).len(), 1)
  let ends = query(AREA).filter(m => m.value.side == "end" and m.location().page() == here().page()).map(m => m.location().position())
  assert.eq(ends.len(), 1)
  assert(near(ends.first().x, W - LEFT_RIGHT.right), message: "across the page: " + repr(ends))
  assert(at("tr2").y > ends.first().y, message: repr((ends, at("tr2"))))
}

#pagebreak()
#rule[A column break at the start of `columns` after a part: the part's rubric at the `"end"` stays before them, and the next part is in the second column]
#exam(show-rubrics: true, rubric-position: "end")[
  #question[
    Prompt.
    #part(points: 1)[#mark("lead1")#TEXT #rubric(points: 1)[Right]]
    #columns(2)[#colbreak()#part(points: 1)[#mark("lead2")#TEXT]]<leading>
  ]
]
#context {
  assert.eq(query(<leading>).len(), 1)
  assert(not first_col("lead2"), message: repr(at("lead2")))
  let ends = query(AREA).filter(m => m.value.side == "end" and m.location().page() == here().page()).map(m => m.location().position())
  assert.eq(ends.len(), 1)
  assert(ends.first().y > at("lead1").y and ends.first().y < at("lead2").y, message: repr((ends, at("lead2"))))
}

#pagebreak()
#rule[The same at a page break: the rubric ends the question on its page, and the `columns` draw nothing after it]
#exam(show-rubrics: true, rubric-position: "end")[
  #question(rubric: [#rubric(points: 1)[The whole question]])[
    #columns(2)[#part(points: 1)[#mark("tr3")#TEXT] #pagebreak()]
  ]
  #question(points: 1)[#mark("tr4")#TEXT]
]
#context {
  let p = at("tr3").page
  assert.eq(at("tr4").page, p + 1)
  assert(query(AREA).any(m => m.value.side == "end" and m.location().page() == p))
}

#pagebreak()
#rule[Rubrics at the `"end"` stay in their column, as do points there]
#exam(show-solutions: true, show-rubrics: true, rubric-position: "end", points-position: "end")[
  #question[
    Prompt.
    #columns(2)[
      #part(points: 2)[#mark("end1")#TEXT #rubric(points: 2)[Right]]
      #colbreak()
      #part(points: 2)[#mark("end2")#TEXT #rubric(points: 2)[Right]]
    ]
    Text after them.#mark("end3")
  ]
]
#context {
  assert(at("end2").x > at("end1").x)
  close_to_each("level", at("end1").y, at("end2").y)
  assert(at("end3").y > at("end1").y)
  // A rubric at the `"end"` records its right edge.
  let ends = query(AREA).filter(m => m.value.side == "end" and m.location().page() == here().page()).map(m => m.location().position())
  assert.eq(ends.len(), 2)
  close_to_each("each in its column", ends.first().y, ends.last().y)
  assert(ends.first().x < W / 2 and ends.last().x > W / 2, message: repr(ends))
}

#pagebreak()
#rule[The rubric at the `"end"` of a question that ends in `columns`, not all in them, goes after them, across the page; that of one all in them, in its column]
#exam(show-solutions: true, show-rubrics: true, rubric-position: "end")[
  #question(rubric: [#rubric(points: 2)[The whole question]])[
    Prompt.
    #columns(2)[
      #part(points: 1)[#TEXT]
      #colbreak()
      #part(points: 1)[#mark("whole")#TEXT]
    ]
  ]
  #columns(2)[
    #question(rubric: [#rubric(points: 2)[In the column]], points: 2)[#TEXT]
  ]
]
#context {
  let ends = query(AREA).filter(m => m.value.side == "end" and m.location().page() == here().page()).map(m => m.location().position())
  assert.eq(ends.len(), 2)
  let (whole, in_column) = ends
  assert(near(whole.x, W - LEFT_RIGHT.right), message: "across the page: " + repr(whole))
  assert(whole.y > at("whole").y)
  assert(in_column.x < W - LEFT_RIGHT.right - 100pt and in_column.y > whole.y, message: "in its column: " + repr(in_column))
}

// On a sideways page, and one with mirrored margins.
#set page(width: 4.5in, height: 8in, flipped: true, margin: (left: .6in, right: 1.7in, y: .4in))
#pagebreak()
#rule[On a page turned sideways, the right margin is that of the page as it is turned]
#exam(show-solutions: true, show-rubrics: true)[
  #columns(2)[
    #question(points: 1)[#TEXT #rubric(points: 1)[Right]]
    #colbreak()
    #question(points: 1)[#TEXT #rubric(points: 1)[Right]]
  ]
]
#context {
  let n = here().page()
  let rows = rubric_rows(n)
  assert.eq(rows.len(), 2)
  assert(rows.all(p => p.x >= 8in - 1.7in), message: repr(rows))
}

#set page(margin: 20%)
#pagebreak()
#rule[On a page turned sideways with a margin in percent, the margin is a share of the page's width as it is turned]
#exam(points-position: "margin-right", points-format: badge)[
  #columns(2)[
    #question(points: 1)[#TEXT]
    #colbreak()
    #question(points: 2)[#TEXT]
  ]
]
#context {
  let drawn = badges(here().page())
  assert.eq(drawn.len(), 2)
  let edge = 80% * 8in
  assert(drawn.all(p => near(p.x, edge + 1em.to-absolute())), message: repr((edge, drawn)))
}

#set page(width: W, height: 4in, flipped: false, margin: (inside: .5in, outside: 2in, y: .4in))
#pagebreak()
#rule[With mirrored margins, the margin that is on that side of this page: here, the wide outside margin]
#exam(show-solutions: true, show-rubrics: true, rubric-position: "margin-right")[
  #columns(2)[
    #question(points: 1)[#TEXT #rubric(points: 1)[Right]]
    #colbreak()
    #question(points: 1)[#TEXT #rubric(points: 1)[Right]]
  ]
]
#context {
  let n = here().page()
  let rows = rubric_rows(n)
  assert.eq(rows.len(), 2)
  let margin = if calc.odd(n) { 2in } else { .5in }
  assert(rows.all(p => p.x >= W - margin), message: repr(rows))
}

// The columns of the page itself: Typst's, not a `columns` in the exam.
#set page(width: 6.5in, height: 3in, margin: (x: 1.3in, y: .4in), columns: 2, flipped: false)
#let edge_right = 6.5in - 1.3in
#pagebreak()
#rule[In a page's own columns too, points in the right margin go in the page's margin from the first column, not over the second's text; those level with each other are stacked]
#exam(points-position: "margin-right", points-format: badge)[
  #question(points: 1)[#TEXT]
  #colbreak()
  #question(points: 2)[#TEXT]
]
#context {
  let drawn = badges(here().page())
  assert.eq(drawn.len(), 2)
  assert(drawn.all(p => p.x >= edge_right), message: repr(drawn))
  clear_of_each(areas(here().page(), "margin-right"))
}

#pagebreak()
#rule[In a page's own columns, points in the left margin from the second column; and rubrics in the right margin from the first]
#exam(show-rubrics: true, show-solutions: true, points-position: "margin-left", points-format: badge)[
  #question(points: 1)[#TEXT #rubric(points: 1)[Right]]
  #colbreak()
  #question(points: 2)[#TEXT #rubric(points: 2)[Right]]
]
#context {
  let n = here().page()
  // Those in the rubrics' cards are in the other margin.
  let drawn = badges(n)
  assert.eq(drawn.filter(p => p.x <= 1.3in).len(), 2, message: repr(drawn))
  let rows = rubric_rows(n)
  assert.eq(rows.len(), 2)
  assert(rows.all(p => p.x >= edge_right), message: repr(rows))
}

#pagebreak()
#rule[In a page's own columns, an `fr` box after `columns` holding one starts the page's next column, not its next page]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[#part(points: 1)[#answer-box(height: 1fr)[]]]
    #answer-box(height: 1fr)[]
  ]
]
#context {
  let (own, part) = frs()
  assert.eq(own.first().page, part.first().page)
  assert(own.first().x > part.first().x and own.first().high > 50 and part.first().high > 50, message: repr((part, own)))
}

// Back to a page of one column: an exam with `columns` on one page only.
#set page(width: W, height: 3in, margin: (left: .6in, right: 1.6in, y: .4in), columns: 1)
#let TALL = (p) => [#metadata(p)<badge>#box(height: 30pt)[#p p]]
#pagebreak()
#rule[Points in a margin are only stacked on a page with `columns`: here, each tall badge stays level with its question, as in an exam with no `columns`, and those on the next page are stacked with those from `columns`]
#exam(points-position: "margin-right", points-format: TALL)[
  #question(points: 1)[#mark("tall1")First.]
  #question(points: 2)[#mark("tall2")Second, which is drawn level with its own first line.]
  #pagebreak()
  #question(points: 3)[#mark("tall3")#TEXT]
  #columns(2)[
    #question(points: 4)[#mark("tall4")#TEXT]
    #colbreak()
    #question(points: 5)[#mark("tall5")#TEXT]
  ]
]
#context {
  let first = at("tall1").page
  let second = first + 1
  assert.eq(at("tall3").page, second)
  assert.eq(areas(first, "margin-right").len(), 0, message: "the first page has none stacked")
  let drawn = badges(first)
  assert.eq(drawn.len(), 2)
  assert(drawn.at(1).y - drawn.at(0).y < 30pt, message: "not moved: " + repr(drawn))
  // All of the next page's: those from before the `columns` too.
  assert.eq(areas(second, "margin-right").len(), 3)
  clear_of_each(areas(second, "margin-right"))
}

// A `#pagebreak()` in a `columns` splits it where it is written: the page break
// is lifted out of the `columns`, and what comes after it in them is drawn in
// another `columns` with the same arguments, on the next page. It starts again
// in the first column.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#let (W, H, M) = (6.5in, 3.5in, .6in)
#set page(width: W, height: H, margin: M)
#set text(size: 9pt)
#show: e.prepare()

#let TEXT = [Where is the nearest grocery store from the train station?]
#let mark(name) = box[#metadata(name)#label(name)]
#let at(name) = query(label(name)).first().location().position()
#let near(a, b) = calc.abs((a - b) / 1pt) < .5
#let first_col(name) = at(name).x < W / 2
/// The page of a marker, from that of the first in a test.
#let pages(..names) = names.pos().map(n => at(n).page)

#rule[Between questions: the second half starts on the next page, back in the first column, and a column break still moves on to the next column there; what is after the `columns` is below them]
#exam[
  #columns(2)[
    #question(points: 1)[#mark("a1")#TEXT]
    #question(points: 2)[#mark("a2")#TEXT]
    #pagebreak()
    #question(points: 3)[#mark("a3")#TEXT]
    #colbreak()
    #question(points: 4)[#mark("a4")#TEXT]
  ]
  #question(points: 5)[#mark("a5")Across the page: #TEXT #TEXT]
  #context assert.eq(num-points(), 15)
]
#context {
  let (p, ..rest) = pages("a1", "a2", "a3", "a4", "a5")
  assert.eq(rest, (p, p + 1, p + 1, p + 1))
  assert(first_col("a3") and not first_col("a4"))
  assert(near(at("a3").y, at("a4").y) and at("a5").y > at("a3").y)
}

#pagebreak()
#rule[Between parts under a prompt across the page, and with text across the page after them; in the middle of a part's text, which goes on at its indent]
#exam[
  #question[
    Prompt, across the page. #mark("b0")
    #columns(2)[
      #part(points: 1)[#mark("b1")#TEXT]
      #pagebreak()
      #part(points: 1)[#mark("b2")The next page. #pagebreak() #mark("b3")And the one after that.]
      #colbreak()
      #part(points: 1)[#mark("b4")Its second column.]
    ]
    After them, across the page, and on past the middle of it.#mark("b5")
  ]
]
#context {
  let (p, ..rest) = pages("b1", "b2", "b3", "b4", "b5")
  assert.eq(rest, (p + 1, p + 2, p + 2, p + 2))
  assert(first_col("b1") and first_col("b2") and first_col("b3") and not first_col("b4"))
  assert(near(at("b1").x, at("b2").x), message: "the same indent")
  assert(at("b3").x < at("b2").x + 1pt, message: repr((at("b2"), at("b3"))))
  assert(at("b5").x > W / 2, message: "across the page: " + repr(at("b5")))
}

#pagebreak()
#rule[The same arguments, and a `#set columns(..)`, on both pages: three columns with a wide gutter; and what the rules inside them set goes on after the break]
#exam[
  #{
    set columns(gutter: 3em)
    columns(3)[
      #set text(fill: blue)
      #question(points: 1)[#mark("c1")One.]
      #colbreak()
      #question(points: 1)[#mark("c2")Two.]
      #pagebreak()
      #question(points: 1)[#mark("c3")Three.]
      #colbreak()
      #question(points: 1)[#mark("c4")#context assert.eq(text.fill, blue)Four.]
    ]
  }
]
#context {
  let (p, ..rest) = pages("c1", "c2", "c3", "c4")
  assert.eq(rest, (p, p + 1, p + 1))
  assert(near(at("c2").x - at("c1").x, at("c4").x - at("c3").x), message: "the same columns")
  assert(near(at("c1").x, at("c3").x))
}

#pagebreak(to: "odd")
#rule[A `#set pagebreak(..)` inside the `columns` applies to the page break in them: from this odd page, to the next odd one, past an empty page]
#exam[
  #question(points: 2)[
    #columns(2)[
      #set pagebreak(to: "odd")
      #part(points: 1)[#mark("g1")#TEXT]
      #pagebreak()
      #part(points: 1)[#mark("g2")#TEXT]
    ]
  ]
]
#context {
  let (p, ..rest) = pages("g1", "g2")
  assert(calc.odd(p))
  assert.eq(rest, (p + 2,))
}

#pagebreak()
#rule[No questions or parts in them: `columns` holding only text are split too, in a question, in a container of their own, and at the top of the exam]
#exam[
  #question(points: 1)[
    #mark("d0")Prompt.
    #columns(2)[#mark("d1")Before. #pagebreak() #mark("d2")After. #colbreak() #mark("d3")Beside.]
  ]
  #[#columns(2)[#mark("d4")Before. #pagebreak() #mark("d5")After.]]
  #columns(2)[#set text(fill: blue); #[#mark("d6")Before. #pagebreak() #mark("d7")After.]]
]
#context {
  let (p, ..rest) = pages("d1", "d2", "d3", "d4", "d5", "d6", "d7")
  assert.eq(rest, (p + 1, p + 1, p + 1, p + 2, p + 2, p + 3))
  assert(first_col("d2") and not first_col("d3") and first_col("d5"))
}

#pagebreak()
#rule[A weak page break does nothing at the top of a page, and one at the very start draws no empty `columns` above the first question; and nothing left in the `columns` after a page break, even space, draws none there]
#exam[
  #columns(2)[
    #pagebreak(weak: true)
    #question(points: 1)[#mark("e1")First.]
    #pagebreak()
    #pagebreak(weak: true)
    #question(points: 1)[#mark("e2")Second.]
    #pagebreak()
  ]
  #question(points: 1)[#mark("e3")At the top of the next page.]
]
#context {
  let (p, ..rest) = pages("e1", "e2", "e3")
  assert.eq(rest, (p + 1, p + 2))
  // At the top of the page, with no empty `columns` above it.
  assert(near(at("e3").y, at("e2").y), message: repr((at("e2"), at("e3"))))
}

#pagebreak()
#rule[In `columns` in `columns`: both are left, and both are drawn again]
#exam[
  #columns(2)[
    #mark("f0")The outer.
    #columns(2)[
      #question(points: 1)[#mark("f1")One.]
      #pagebreak()
      #question(points: 1)[#mark("f2")Two.]
      #colbreak()
      #question(points: 1)[#mark("f3")Three.]
    ]
    #colbreak()
    #question(points: 1)[#mark("f4")In the outer's next column.]
  ]
]
#context {
  let (p, ..rest) = pages("f0", "f1", "f2", "f3", "f4")
  assert.eq(rest, (p, p + 1, p + 1, p + 1))
  assert(near(at("f1").x, at("f2").x))
  assert(first_col("f2") and first_col("f3"), message: "inside the outer's first column")
  assert(at("f3").x > at("f2").x)
  assert(not first_col("f4"), message: repr(at("f4")))
}

#pagebreak()
#rule[`fr` answer boxes share each page's column of their own, on either side of the break]
#exam(embed-metadata: "question-regions")[
  #question[
    #columns(2)[
      #part(points: 1)[A. #answer-box(height: 1fr)[]]
      #colbreak()
      #part(points: 1)[B. #answer-box(height: 1fr)[]]
      #pagebreak()
      #part(points: 1)[C. #answer-box(height: 1fr)[]]
    ]
  ]
]
#context {
  let rows = query(selector(<examy-regions>).before(here())).last().value.question-regions
  let (a, b, c) = rows.slice(1).map(r => r.answer-boxes.first())
  let bottom = (H - M) / 1pt
  assert(a.top.page == b.top.page and c.top.page == a.top.page + 1, message: repr((a, b, c)))
  assert(a.top.x == c.top.x and b.top.x > a.top.x, message: repr((a, b, c)))
  for x in (a, b, c) { assert(calc.abs(x.bottom.y - bottom) < 2, message: repr(x)) }
}

// `config`'s `embed-metadata`: an exam with `true` or "question-regions"
// leaves its regions as `<examy-regions>` (and attaches them to the PDF):
// where each question, part, and subpart starts and ends, its answer boxes
// (also one that draws itself, in an `align`), the name block's lines, and
// each page's size and margins. One with "rubric" attaches its rubrics only,
// and one with `false`, nothing. The regions are drawn over the pages they are
// on, in red: each box's outline, each division's start, and each name line;
// and in blue, each division's extent, from its start to its end, a page at a
// time.
#import "/src/lib.typ": *
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: 5in, margin: .5in, foreground: context {
  for m in query(<examy-regions>) {
    let data = m.value
    let mark(at, body) = if at.page == here().page() { place(top + left, dx: at.x * 1pt, dy: at.y * 1pt, body) }
    let outline(a, b, paint: red) = rect(width: (b.x - a.x) * 1pt, height: (b.y - a.y) * 1pt, stroke: 1.5pt + paint.transparentize(40%))
    for row in data.question-regions {
      // Its extent on this page: from its start, or the top of the text, to
      // its end, or the bottom of the text.
      let (s, e, p) = (row.start, row.end, here().page())
      let page = data.pages.find(q => q.page == p)
      if page != none and s.page <= p and p <= e.page {
        let top = if s.page == p { s } else { (page: p, x: s.x, y: page.margin.top) }
        let bottom = if e.page == p { e } else { (page: p, x: e.x, y: page.height - page.margin.bottom) }
        mark(top, outline(top, bottom, paint: blue))
      }
      mark(row.start, place(dx: -3pt, dy: -3pt, circle(radius: 3pt, fill: red)))
      for b in row.answer-boxes { mark(b.top, outline(b.top, b.bottom)) }
    }
    for n in data.name-block-regions { mark(n.start, outline(n.start, n.end)) }
  }
})
#set text(size: 10pt)
#show: e.prepare()

#rule[An exam with `embed-metadata: true`, its regions in red: its name block's lines; each answer box (one in an `align`, one with an `outset`) to the outside of its outline, under the question or part whose text it is in (the last after question 2's parts is question 2's; the one between questions is none's); and where each part and question starts, at its label, above a tall box on its first line. In blue, each one's extent: to the right of the text, and past the boxes in it (question 2's, past the outset of its last), its parts' too]
#name-block()
#exam(embed-metadata: true)[
  #question(points: 2, rubric: [#rubric(points: 2)[Right]])[
    Inline: #answer-box(width: 3cm, height: 2cm)[]
  ]
  #question[
    #part(points: 1)[Centered: #align(center, answer-box(width: 4cm, height: 1.5cm)[])]
    #part(points: 3)[No box.]
    Now summarize: #answer-box(width: 2cm, height: 1cm, outset: 4pt, stroke: 2pt)[]
  ]
  Between questions: #answer-box(width: 2cm, height: .5cm)[]
  #pagebreak()
  #question(points: 1)[On the next page. #answer-box(width: 100%, height: 1cm)[]]
]

#rule[An exam with `embed-metadata: "rubric"`, and one with `false`: no regions]
#exam(embed-metadata: "rubric")[
  #question(points: 1, rubric: [#rubric(points: 1)[Right]])[One #answer-box(width: 2cm, height: 1cm)[]]
]
#exam[
  #question(points: 1, rubric: [#rubric(points: 1)[Right]])[One #answer-box(width: 2cm, height: 1cm)[]]
]

#rule[An exam's extents, in blue: a question with a `height` to the bottom of it, its part inside it; and two questions side by side in `columns`, each in its own column. Their points as given: the part's for practice, none; the left question's `0`; the right's a bonus]
#exam(embed-metadata: true)[
  #question(points: 2, height: 3cm)[Fixed height. #part(points: 1, intent: "practice")[A part, for practice.]]
  #columns(2)[
    #question(points: 0)[Left. #answer-box(width: 100%, height: 1cm)[]]
    #colbreak()
    #question(points: 2, intent: "bonus")[Right, a bonus.]
  ]
]

#set page(margin: (inside: 1in, outside: .5in, y: .5in))
#rule[An exam of its own pages, its margins mirrored (`inside: 1in, outside: .5in`): its regions list only its pages, the left margin 1in on odd pages and .5in on even ones, also on its last, where no question starts]
#exam(embed-metadata: true)[
  #question(points: 1)[First. #answer-box(width: 2cm, height: 1cm)[]]
  #pagebreak()
  #question(points: 1)[Second. #pagebreak() Still the second, on a page of its own.]
]

#context {
  let found = query(<examy-regions>)
  assert.eq(found.len(), 3, message: "only the exams with question-regions leave regions")
  let data = found.first().value
  assert.eq(data.format, "examy-regions")
  let rows = data.question-regions
  assert.eq(rows.map(r => r.address), ((0,), (1,), (1, 0), (1, 1), (2,)))
  // Each one's own points, not its parts': question 2 has none of its own.
  assert.eq(rows.map(r => r.points), (2, none, 1, 3, 1))
  assert(rows.all(r => r.bonus-points == none))
  assert.eq(rows.map(r => r.answer-boxes.len()), (1, 1, 1, 0, 1))
  assert.eq(rows.map(r => r.start.page), (1, 1, 1, 1, 3))
  assert.eq(rows.map(r => r.end.page), (1, 2, 1, 1, 3))
  // A box's outline is as large as it is drawn: its size, and its outset
  // and half its stroke (.5pt by default) on every side; to a tenth of a
  // point at each corner.
  let near(a, b) = calc.abs(a - b) <= .11
  let fits(b, w, h, grow: .5) = (
    near(b.bottom.x - b.top.x, w * 1cm / 1pt + grow) and near(b.bottom.y - b.top.y, h * 1cm / 1pt + grow)
  )
  assert(fits(rows.at(0).answer-boxes.first(), 3, 2))
  assert(fits(rows.at(2).answer-boxes.first(), 4, 1.5))
  assert(fits(rows.at(1).answer-boxes.first(), 2, 1, grow: 10))
  // A question starts at the top of the tall box on its first line, which
  // only half the box's stroke is above.
  assert(rows.at(0).start.y <= rows.at(0).answer-boxes.first().top.y + .3)
  // A full-width box spans the text, less the question's indent, and half
  // its stroke past it.
  let wide = rows.at(4).answer-boxes.first()
  assert(near(wide.bottom.x, 6 * 72 - 36 + .25))
  // Each extent starts at its label, the left of its indent, and ends at the
  // right of the text, or past a box that is, as question 3's full-width box.
  assert.eq(rows.map(r => r.start.x), (36.0, 36.0, 51.0, 51.0, 36.0))
  assert.eq(rows.map(r => r.end.x), (396.0, 396.0, 396.0, 396.0, wide.bottom.x))
  // A question's takes in its parts', and what follows them, to the outset
  // of its last box; and the box on its first line, to half its stroke.
  let (q, a, b) = rows.slice(1, 4)
  assert(q.start.y == a.start.y and a.end.y < b.start.y and b.end.page < q.end.page)
  assert.eq(q.end.y, q.answer-boxes.first().bottom.y)
  assert.eq(rows.first().end.y, rows.first().answer-boxes.first().bottom.y)
  // Each page's size and margins, in pt.
  let margin = (top: 36.0, bottom: 36.0, left: 36.0, right: 36.0)
  assert.eq(data.pages, range(1, 4).map(p => (page: p, width: 432.0, height: 360.0, margin: margin)))
  // The name block's lines, labelled, each from its start to the end of the
  // text.
  assert.eq(data.name-block-regions.map(n => n.display-name), ("Name:", "Student ID:"))
  assert(data.name-block-regions.all(n => n.end.x == 6 * 72 - 36 and n.start.x < n.end.x and n.start.y < n.end.y))
  // Rubrics are left as data by every exam with them, whatever it embeds.
  assert.eq(query(<examy-rubric>).len(), 3)
  // The rubric data says what the regions do of a question.
  let rubrics = query(<examy-rubric>).first().value
  assert.eq((rubrics.format, rubrics.exam-name), ("examy-rubric", none))
  let shared = ("address", "display-name", "level", "points", "bonus-points")
  assert.eq(rubrics.rubrics.map(q => shared.map(k => q.at(k))), (shared.map(k => rows.first().at(k)),))

  // A question with a `height` ends at the bottom of it, past its part;
  // questions in columns, at the right of their own column.
  let (fixed, part, left, right) = found.at(1).value.question-regions
  assert(near(fixed.end.y - fixed.start.y, 3 * 1cm / 1pt) and part.end.y < fixed.end.y)
  assert(left.start.y == right.start.y and left.end.x < right.start.x)
  assert.eq((left.start.x, right.end.x), (36.0, 396.0))
  // The gutter is 4% of the text, 360pt wide.
  assert(near(right.start.x, 36 + (360 + .04 * 360) / 2))
  // Points as given: practice points are neither points nor a bonus, and
  // `points: 0` is given.
  assert.eq((fixed, part, left, right).map(r => (r.points, r.bonus-points)), ((2, none), (none, none), (0, none), (none, 2)))

  // The mirrored exam: its own pages, from its first question's to its end.
  let mirrored = found.last().value
  let first = mirrored.question-regions.first().start.page
  assert.eq(mirrored.pages.map(p => p.page), range(first, first + 3))
  assert(mirrored.pages.all(p => p.margin.left == if calc.odd(p.page) { 72.0 } else { 36.0 }))
  assert(mirrored.pages.all(p => p.margin.left + p.margin.right == 108.0))
  // Its second question ends on the page after it starts.
  assert.eq(mirrored.question-regions.map(r => r.end.page), (first, first + 2))

}

// Drawn apart from the checks above: from the regions as they are once
// laid out, none before then (which would keep the document from settling).
#rule[The first exam's divisions, and the mirrored exam's pages, as their regions give them]
#context {
  let found = query(<examy-regions>)
  if found.len() < 3 { return }
  let rows = found.first().value.question-regions
  let mirrored = found.last().value
  cases(
    ([Division], [Points], [Starts on page], [Ends on page], [Boxes]),
    ..rows.map(r => ([#r.display-name], [#r.points], [#r.start.page], [#r.end.page], [#r.answer-boxes.len()])),
  )
  cases(
    ([Page], [Left margin], [Right margin]),
    ..mirrored.pages.map(p => ([#p.page], [#p.margin.left], [#p.margin.right])),
  )
}

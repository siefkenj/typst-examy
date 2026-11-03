// `config`'s `embed-metadata`: an exam with `true` or "question-extents"
// leaves its regions as `<examy-regions>` (and attaches them to the PDF):
// where each question, part, and subpart starts, its answer boxes (also one
// that draws itself, in an `align`), the name block's lines, and each page's
// size and margins. One with "rubric" attaches its rubrics only, and one with
// `false`, nothing. The regions are drawn over the pages they are on, in red:
// each box's outline, each division's start, and each name line.
#import "/src/lib.typ": *
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: 5in, margin: .5in, foreground: context {
  for m in query(<examy-regions>) {
    let data = m.value
    let mark(at, body) = if at.page == here().page() { place(top + left, dx: at.x * 1pt, dy: at.y * 1pt, body) }
    let outline(a, b) = rect(width: (b.x - a.x) * 1pt, height: (b.y - a.y) * 1pt, stroke: 1.5pt + red.transparentize(40%))
    for row in data.exams.first() {
      mark(row.start, place(dx: -3pt, dy: -3pt, circle(radius: 3pt, fill: red)))
      for b in row.boxes { mark(b.top, outline(b.top, b.bottom)) }
    }
    for n in data.names { mark(n.start, outline(n.start, n.end)) }
  }
})
#set text(size: 10pt)
#show: e.prepare()

#rule[An exam with `embed-metadata: true`, its regions in red: its name block's lines; each answer box (one in an `align`, one with an `outset`) to the outside of its outline, under the question or part whose text it is in (the last after question 2's parts is question 2's; the one between questions is none's); and where each part and question starts, above a tall box on its first line]
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

#set page(margin: (inside: 1in, outside: .5in, y: .5in))
#rule[An exam of its own pages, its margins mirrored (`inside: 1in, outside: .5in`): its regions list only its pages, the left margin 1in on odd pages and .5in on even ones, also on its last, where no question starts]
#exam(embed-metadata: true)[
  #question(points: 1)[First. #answer-box(width: 2cm, height: 1cm)[]]
  #pagebreak()
  #question(points: 1)[Second. #pagebreak() Still the second, on a page of its own.]
]

#context {
  let found = query(<examy-regions>)
  assert.eq(found.len(), 2, message: "only the exams with question-extents leave regions")
  let data = found.first().value
  assert.eq((data.format, data.version), ("examy-gradescope-regions", 1))
  assert.eq(data.exams.len(), 1)
  let rows = data.exams.first()
  assert.eq(rows.map(r => r.number), ("1", "2", "2.1", "2.2", "3"))
  assert.eq(rows.map(r => r.points), (2, 4, 1, 3, 1))
  assert.eq(rows.map(r => r.boxes.len()), (1, 1, 1, 0, 1))
  assert.eq(rows.map(r => r.start.page), (1, 1, 1, 1, 3))
  // A box's outline is as large as it is drawn: its size, and its outset
  // and half its stroke (.5pt by default) on every side; to a tenth of a
  // point at each corner.
  let near(a, b) = calc.abs(a - b) <= .11
  let fits(b, w, h, grow: .5) = (
    near(b.bottom.x - b.top.x, w * 1cm / 1pt + grow) and near(b.bottom.y - b.top.y, h * 1cm / 1pt + grow)
  )
  assert(fits(rows.at(0).boxes.first(), 3, 2))
  assert(fits(rows.at(2).boxes.first(), 4, 1.5))
  assert(fits(rows.at(1).boxes.first(), 2, 1, grow: 10))
  // A question starts at the top of the tall box on its first line, which
  // only half the box's stroke is above.
  assert(rows.at(0).start.y <= rows.at(0).boxes.first().top.y + .3)
  // A full-width box spans the text, less the question's indent, and half
  // its stroke past it.
  let wide = rows.at(4).boxes.first()
  assert(near(wide.bottom.x, 6 * 72 - 36 + .25))
  // Each page's size and margins, in pt.
  let margin = (top: 36.0, bottom: 36.0, left: 36.0, right: 36.0)
  assert.eq(data.pages, range(1, 4).map(p => (page: p, width: 432.0, height: 360.0, margin: margin)))
  // The name block's lines, labelled, each from its start to the end of the
  // text.
  assert.eq(data.names.map(n => n.label), ("Name:", "Student ID:"))
  assert(data.names.all(n => n.end.x == 6 * 72 - 36 and n.start.x < n.end.x and n.start.y < n.end.y))
  assert.eq(data.ends.map(at => at.page), (3,))
  // Rubrics are left as data by every exam with them, whatever it embeds.
  assert.eq(query(<examy-rubric>).len(), 3)

  // The mirrored exam: its own pages, from its first question's to its end.
  let mirrored = found.last().value
  let first = mirrored.exams.first().first().start.page
  assert.eq(mirrored.pages.map(p => p.page), range(first, first + 3))
  assert(mirrored.pages.all(p => p.margin.left == if calc.odd(p.page) { 72.0 } else { 36.0 }))
  assert(mirrored.pages.all(p => p.margin.left + p.margin.right == 108.0))

}

// Drawn apart from the checks above: from the regions as they are once
// laid out, none before then (which would keep the document from settling).
#rule[The first exam's divisions, and the mirrored exam's pages, as their regions give them]
#context {
  let found = query(<examy-regions>)
  if found.len() < 2 { return }
  let rows = found.first().value.exams.first()
  let mirrored = found.last().value
  cases(
    ([Division], [Points], [Starts on page], [Boxes]),
    ..rows.map(r => ([#r.label], [#r.points], [#r.start.page], [#r.boxes.len()])),
  )
  cases(
    ([Page], [Left margin], [Right margin]),
    ..mirrored.pages.map(p => ([#p.page], [#p.margin.left], [#p.margin.right])),
  )
}

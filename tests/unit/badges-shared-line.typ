// A question and the part it starts with share a first line, and their
// badges in the margin are drawn there together, once each. Whether they
// are stacked with the rubrics in that margin is the exam's to say, not each
// division's, so that the two agree even when their rubrics are drawn in
// different places (`rubric-position`).
#import "/src/lib.typ": *
#import "/src/rubric.typ": AREA
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (left: .5in, right: 2.5in, y: .5in))
#set text(size: 10pt)
#show: e.prepare()

#rule[Points and rubrics in the right margin; question 1's first part at the `"end"`, and question 2 at the
  `"end"` with its first part in the margin.]
#block(stroke: .3pt + gray, inset: 6pt, exam(
  questions: [
    #question(points: 3, rubric: rubric[One.])[
      #part(points: 4, rubric-position: "end", rubric: rubric[Its part.])[A part.] #part(points: 1)[Another.]
    ]
    #question(points: 5, rubric-position: "end", rubric: rubric[Two.])[
      #part(points: 6, rubric-position: "margin-right", rubric: rubric[Its part.])[A part.]
      #part(points: 2)[Another.]
    ]
  ],
  show-rubrics: true,
  points-position: "margin-right",
  rubric-position: "margin-right",
  points-format: p => [#metadata(p)<badge-points>(#p)],
))

#context {
  let drawn = query(<badge-points>).map(m => m.value)
  // A badge for each, and a heading for each with a rubric.
  for (p, n) in ((1, 1), (2, 1), (3, 2), (4, 2), (5, 2), (6, 2)) {
    assert.eq(drawn.filter(x => x == p).len(), n, message: "points " + str(p) + " drawn in " + repr(drawn))
  }
  // Stacked with the rubrics in the right margin, the badges are recorded
  // there with them, as one area for each line of badges (address `none`).
  let badges = query(AREA).map(m => m.value).filter(a => a.id.address == none)
  assert.eq(badges.len(), 4, message: "every line of badges is stacked: " + repr(badges))
}

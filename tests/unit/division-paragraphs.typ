// The text of every question, part, and subpart is a paragraph (`par`), in
// the PDF's tags and for `par` rules, whatever is around it: Typst makes text
// alone in a block no paragraph, but text beside a `place` one, so that
// without examy's own, whether it was one went by what the exam drew in the
// margin (rubrics, points) and whether it attached its regions. Each case's
// paragraphs are drawn in blue, and each word below is checked to be in one.
#import "/src/lib.typ": *
#import "/tests/record.typ": cases, rule

#set page(width: 5in, height: auto, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()

/// The words of the questions, parts, and subpart, one in each's text.
#let WORDS = ("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel")

#let questions = [
  #question(points: 1, rubric: rubric(points: 1)[Right])[Alpha question.]
  #question[
    Bravo intro.
    #part(points: 1)[Charlie part.]
    #part(points: 1)[Delta part. #answer-box(width: 100%, height: 1cm)[]]
  ]
  #question[
    Echo intro, split by a page break, so drawn in segments.
    #part(points: 1)[Foxtrot part.]
    #pagebreak()
    #part[#subpart(points: 1)[Golf subpart.]]
  ]
  #question(points: 1, height: 2cm)[Hotel question, given a height.]
]

#let CASES = (
  ("defaults", (:)),
  ("show-rubrics", (show-rubrics: true)),
  ("points in the margin", (points-position: "margin-left")),
  ("regions attached", (embed-metadata: "question-regions")),
)

#for (name, opts) in CASES {
  rule[#name: each text a paragraph, in blue]
  {
    show par: it => [#metadata((name, repr(it.body)))<par-body>] + it
    show par: set text(fill: blue)
    exam(..opts, questions)
  }
}

#context {
  let found = query(<par-body>).map(m => m.value)
  let rows = CASES.map(((name, _)) => {
    let bodies = found.filter(((n, _)) => n == name).map(((_, b)) => b)
    (name, WORDS.map(w => bodies.filter(b => b.contains(w)).len()))
  })
  cases(([Case], ..WORDS.map(w => [#w])), ..rows.map(((name, counts)) => ([#name], ..counts.map(c => [#c]))))
  for (name, counts) in rows {
    assert.eq(counts, WORDS.map(_ => 1), message: name + ": a text is not one paragraph: " + repr(counts))
  }
}

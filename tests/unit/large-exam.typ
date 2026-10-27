// A long exam: the walks over content go round once per piece of it, and
// Typst ends a `while` loop after 10,000 rounds, taking it for an infinite
// one. Each walk runs its loop in batches (see `BATCH`), so its length is
// not limited. Checked on each walk alone, given more pieces than that, and
// on an exam whose walks go round more often too, with what each walk
// meets: math, parts, answer boxes (one inside an `align`, which draws
// itself), and rubrics in solutions and in the text. Each case is only a
// little past the limit, as the walks take time in proportion to their
// length: every one of them fails with the loops unbatched (`BATCH` set to
// 20000), the exam from some 65 questions on.
#import "/src/lib.typ": *
#import "/src/scan.typ": _find, glue_rubrics, rubric_markers, scan
#import "/src/tokenize.typ": tokenize
#import "/src/elements/answer-box.typ": drawn
#import "/src/points.typ": exam_points_data
#import "/tests/record.typ": cases, rule

#set page(width: 7in, height: 9in, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()

/// Content of `n` pieces side by side, in one sequence, then `last`.
#let flat(n, last: none) = (range(n).map(i => [#i]) + (last,)).join()

#let N = 10500
#let WALKS = (
  ("_find, looking at every piece", () => _find(flat(N), x => false).len(), 0),
  ("scan, finding a page break at the end", () => scan(flat(N, last: pagebreak())).has_break, true),
  ("tokenize, a division at the end", () => tokenize(flat(N, last: question[Q])).filter(t => t.kind == "begin").len(), 1),
  ("tokenize, no division: one chunk", () => tokenize(flat(N)).len(), 1),
  ("rubric_markers, a rubric at the end", () => rubric_markers(flat(N, last: rubric(points: 1)[R])).len(), 1),
  ("glue_rubrics, a rubric after the text", () => glue_rubrics(flat(N, last: rubric(points: 1)[R])).children.len(), N + 2),
  ("resolve_boxes, a box at the end", () => drawn(flat(N, last: answer-box[])).children.len(), N + 1),
  ("resolve_boxes, a box at the end of an align", () => drawn(align(center, flat(N, last: answer-box(height: 1cm)[]))).func() == align, true),
)
#let RESULTS = WALKS.map(((desc, f, expected)) => {
  let got = f()
  assert.eq(got, expected, message: desc)
  (desc, expected, got)
})

#rule[Each walk given #N pieces in one sequence: more rounds than Typst lets a loop run at once]
#cases(([Walk], [Expected], [Got]), ..RESULTS.map(((desc, expected, got)) => (desc, repr(expected), repr(got))))

// The exam: `Q` questions of two parts each, each part 2 points. Its rubrics
// are exported, not drawn, which would take as long again.
#let Q = 90
#rule[An exam of #Q questions, with math, parts, answer boxes, and rubrics; its counts, then the exam, in small type]
#context {
  let data = exam_points_data()
  let rubrics = query(<examy-rubric>).first().value.questions
  let items = rubrics.map(q => q.rubric.len()).sum()
  assert.eq(data.len(), Q, message: "questions")
  assert.eq(data.map(q => q.total_points).sum(), 4 * Q, message: "points")
  assert.eq(rubrics.len(), 3 * Q, message: "divisions with a rubric")
  assert.eq(items, 3 * Q, message: "rubric items")
  cases(
    ([Count], [Expected], [Got]),
    ([Questions], [#Q], [#data.len()]),
    ([Points], [#(4 * Q)], [#data.map(q => q.total_points).sum()]),
    ([Divisions with a rubric], [#(3 * Q)], [#rubrics.len()]),
    ([Rubric items], [#(3 * Q)], [#items]),
  )
}
#pagebreak()
#set page(columns: 3)
#set text(size: 6pt)
#show: exam.with(show-solutions: true)
#for i in range(Q) [
  #question[
    Let $f(x) = x^2 + #i x - 4$ and $g(x) = sqrt(x + 1) / (x - 2)$, on $[0, 1]$. Find where
    $f compose g$ is defined, for $x != 2$, and write it out#rubric(points: 1)[Domain stated]
    in full.
    #part(points: 2)[Find $f'(x)$. #answer-box(width: 100%, height: 1cm)[#solution[$f'(x) = 2x + #i$#rubric(points: 2)[Derivative]]]]
    #part(points: 2)[Evaluate $integral_0^1 f(x) dif x$.
      #align(center)[#answer-box(width: 50%)[#solution[$#i / 2 - 11 / 3$#rubric(points: 2)[Integral]]]]]
  ]
]

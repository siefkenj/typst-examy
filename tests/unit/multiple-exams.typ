// A document holding several exams (a bundle of the exam and its key, or a
// page of examples): each of `num-points`, `num-questions`, and
// `points-table` is about the exam it is in, else the next exam, else the
// last one.
#import "/src/lib.typ": *
#import "/src/points.typ": exam_points_data
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()

/// Record which exam a lookup here is about, by its total, and show what the
/// reader sees.
#let probe(where) = {
  context {
    let data = exam_points_data()
    let total = if data == none { none } else { data.map(q => q.total_points).sum(default: 0) }
    [#metadata((where: where, total: total))<probe>]
  }
  [_#where:_ #num-questions questions, #num-points points.]
}

#rule[Before the first exam: about the first (3 points).]
#probe("before first")
#align(center, points-table)

#exam(questions: [
  #question(points: 1)[One point. #probe("inside first")]
  #question(points: 2)[Two points.]
])

#rule[Between the exams: about the second, the next (10 points).]
#probe("between")
#align(center, points-table)

#exam(questions: [
  #question(points: 4)[Four points. #probe("inside second")]
  #question(points: 6)[Six points.]
  #question(points: 0)[No points.]
])

#rule[After the last exam: about the last (10 points).]
#probe("after last")

#context {
  let got = query(<probe>).map(m => m.value)
  let expected = (
    "before first": 3,
    "inside first": 3,
    "between": 10,
    "inside second": 10,
    "after last": 10,
  )
  for (where, total) in expected {
    let found = got.find(v => v.where == where)
    assert(found != none and found.total == total, message: where + ": " + repr(found))
  }
}

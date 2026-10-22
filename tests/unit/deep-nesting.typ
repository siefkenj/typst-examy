// A document nested deep: each set or show rule wraps the rest of its scope
// one level deeper, and a document made the exam by `#show: exam` has all
// of its rules inside the exam. The exam must find its questions however
// many rules there are (before them, between them, inside them, and after
// them), deeper than Typst lets functions recurse, with rubrics in them too.
#import "/src/lib.typ": *
#import "/src/rubric.typ": RECORD
#import "/src/points.typ": exam_points_data
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (left: .4in, right: 2in, y: .3in))
#set text(size: 10pt)

/// `n` rules, each with a line under it: nested `n` levels deep.
#let RULES(n, tag) = range(n).map(i => "#set text(size: " + str(10 + calc.rem(i, 3) * .2) + "pt)\n" + tag + " " + str(i + 1) + ". ").join("\n")

/// Markup as content, so that its rules nest as they would in a document.
#let doc(src) = eval(src, mode: "markup", scope: (question: question, part: part, solution: solution, rubric: rubric))

#let CASES = (
  ("Sixty rules before the questions", RULES(60, "Cover") + "\n\n#question(points: 1)[One.]\n#question(points: 2)[Two.]"),
  ("Sixty rules after them", "#question(points: 1)[One.]\n#question(points: 2)[Two.]\n\n" + RULES(60, "After")),
  ("Fifteen between each question", "#question(points: 1)[One.]\n" + RULES(15, "Between") + "\n#question(points: 2)[Two.]\n" + RULES(15, "After")),
  (
    "Sixty inside a question, before its part, and in a solution with rubrics",
    "#question(points: 1)[One. " + RULES(60, "In") + " Text.#rubric(points: 1)[Glued] #part(points: 2)[Two. #solution[" + RULES(60, "Sol") + " x#rubric(points: 2)[Last]]]]",
  ),
)
#for (n, (desc, src)) in CASES.enumerate() {
  rule[#desc]
  [
    #show: exam.with(show-solutions: true, show-rubrics: true)
    #doc(src)
    #context {
      let data = exam_points_data()
      [#metadata((case: n, questions: data.len(), points: data.map(q => q.total_points).sum()))<count>]
      [_Found:_ #data.len() questions, #data.map(q => q.total_points).sum() points.]
    }
  ]
}

#context {
  let counts = query(<count>).map(m => m.value)
  assert.eq(counts.len(), CASES.len())
  for c in counts {
    assert.eq((c.questions, c.points), (if c.case == 3 { 1 } else { 2 }, 3), message: "case " + str(c.case))
  }
  // The rubrics of the last case, each its division's.
  let records = query(RECORD).map(m => m.value)
  assert.eq(records.map(r => (r.address.len(), r.nodes.len())), ((1, 1), (2, 1)))
}

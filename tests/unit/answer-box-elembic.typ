// Answer boxes in an exam, drawn by the exam (see `resolve_boxes`), as
// elembic would draw them outside one:
// - Their `stroke`, `radius`, and `outset` fold, set rule into set rule and
//   call into set rules, as elembic folds them: `stroke: (top: ..)` on a call
//   keeps the `(bottom: ..)` a set rule gives.
// - A box joined to the end of other content (`[Write: ] + answer-box(..)`)
//   is drawn in its place, the content before it kept.
// - A box whose body holds only a rubric, given `solution:`, keeps the rubric.
// - A rule before the exam that is no longer in force (revoked, or undone by
//   `e.reset`) is no error, nor is a `revoke` of a rule that set nothing on
//   the boxes.
// The rules the exam cannot follow are errors (see tests/fail/answer-box-*).
#import "/src/lib.typ": *
#import "/src/elements/answer-box.typ": _given, answer_box, drawn
#import "/src/scan.typ": has_any_rubric
#import "/tests/record.typ": cases, rule

#show: e.prepare()
#set page(width: 12cm, height: auto, margin: .8cm)
#set text(size: 10pt)

// Folding: what the exam works out (`_given`, over `get(answer_box)`), and
// what elembic gives the same box outside an exam, read by a show rule.
#let FOLDS = (
  ("stroke, two sides", (stroke: (bottom: 1pt + blue)), (stroke: (top: 2pt + red))),
  ("stroke, thickness then paint", (stroke: stroke(thickness: 2pt)), (stroke: stroke(paint: red))),
  ("radius, two corners", (radius: (top-left: 4pt)), (radius: (bottom-right: 8pt))),
  ("outset, two sides", (outset: (x: 2pt)), (outset: (y: 3pt))),
  ("stroke, a length over a dictionary: replaced", (stroke: (bottom: 1pt)), (stroke: 2pt)),
)
#for (i, (desc, given, call)) in FOLDS.enumerate() {
  [
    #show: e.set_(answer-box, ..given)
    #show: e.show_(answer-box, it => [#metadata((i: i, fields: e.fields(it)))<elembic>])
    #e.get(get => [#metadata((i: i, fields: _given(get(answer_box), call)))<exam>])
    #answer-box(height: 1cm, ..call)[]
  ]
}
#context {
  let elembic = query(<elembic>).map(m => m.value)
  let exam = query(<exam>).map(m => m.value)
  for (i, (desc, given, call)) in FOLDS.enumerate() {
    let name = call.keys().first()
    let ours = exam.find(m => m.i == i).fields.at(name)
    let theirs = elembic.find(m => m.i == i).fields.at(name)
    assert.eq(ours, theirs, message: desc)
  }
}

#rule[Folded fields: a set rule, then the call, outside an exam and in one (they match)]
#cases(
  ([Case], [Set rule], [Call]),
  ..FOLDS.map(((desc, given, call)) => (desc, raw(repr(given)), raw(repr(call)))),
)
#grid(
  columns: (1fr, 1fr),
  row-gutter: 6pt,
  [_Outside an exam_], [_In one_],
  ..FOLDS
    .map(((desc, given, call)) => {
      let one = answer-box(width: 3cm, height: 1cm, ..call)[]
      (
        { show: e.set_(answer-box, ..given); one },
        { show: e.set_(answer-box, ..given); exam[#question[#one]] },
      )
    })
    .flatten(),
)

// A box joined to the end of other content: the content before it kept.
#let joined = [Write: ] + answer-box(width: 3cm, height: 1cm, stroke: red)[]
#assert.eq(drawn(joined).func(), [].func(), message: "the joined content is a sequence still")
#assert(drawn(joined).children.first() == [Write], message: "the text before the box is kept")

#rule[A box joined to the end of other content: "Write:" before it, in an exam too]
#joined
#exam[#question[#joined and then more.]]

// A body of only a rubric, given `solution:`: the rubric is kept.
#let rubric_only = answer-box(solution: [42])[#rubric(points: 1)[setup]]
#assert(has_any_rubric(drawn(rubric_only)), message: "the rubric is lost")

#rule[`solution:` with a body of only a rubric: the rubric kept (drawn at the end)]
#exam(show-solutions: true, show-rubrics: true, rubric-position: "end")[
  #question[Q #answer-box(width: 100%, solution: [42])[#rubric(points: 1)[setup]]]
]

// Rules before the exam no longer in force, and a `revoke` of a rule that
// set nothing on the boxes: no errors.
#rule[A named `show_` on boxes, revoked before the exam: no error, a plain box]
#[
  #show: e.named("s", e.show_(answer-box, it => [Replaced]))
  #show: e.revoke("s")
  #exam[#question[Q #answer-box(width: 100%, height: 1cm)[]]]
]

#rule[A `show_` and a `cond-set` on boxes, undone by `e.reset` before the exam: no error]
#[
  #show: e.show_(answer-box, it => [Replaced])
  #show: e.cond-set(answer-box.with(height: 1cm), fill: red)
  #show: e.reset(answer-box)
  #exam[#question[Q #answer-box(width: 100%, height: 1cm)[]]]
]

#rule[With a set rule on boxes, a `revoke` of a `config` rule in the exam: no error]
#[
  #show: e.set_(answer-box, stroke: 1pt)
  #show: e.named("maroon", e.set_(config, solution-color: maroon))
  #exam(show-solutions: true)[
    #question[A maroon solution. #answer-box(width: 100%, height: 1cm)[#solution[Maroon.]]]
    #[
      #show: e.revoke("maroon")
      #question[The default color again. #answer-box(width: 100%, height: 1cm)[#solution[Blue.]]]
    ]
  ]
]

// `e.selector(answer-box)` finds the boxes the exam draws too: a native
// show rule on it applies to them, and a `query` counts them.
#rule[`show e.selector(answer-box): set text(red)`: red in the boxes outside the exam and in it]
#metadata(none)<selector-start>
#[
  #show e.selector(answer-box): set text(red)
  Outside: #answer-box(width: 3cm, height: 1cm)[x]
  #exam[#question[Inside: #answer-box(width: 3cm, height: 1cm)[x] #answer-box(width: 100%, height: 1cm)[y]]]
]
#metadata(none)<selector-end>
#context {
  // The boxes `e.selector` finds between the two marks: all three.
  let from = query(<selector-start>).first().location()
  let to = query(<selector-end>).first().location()
  let found = query(selector(e.selector(answer-box)).after(from).before(to))
  assert.eq(found.len(), 3, message: "e.selector should find the box outside the exam and both in it")
}

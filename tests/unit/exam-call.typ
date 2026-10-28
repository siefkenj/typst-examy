// How `exam` is called: its questions positionally or as `questions:`, as
// a show rule (`#show: exam`, `#show: exam.with(..)`), and with `config`
// options of its own, which apply to everything in the exam (a cover page
// before its first question included) and to nothing after it. The exam
// applies `e.prepare()` itself: this file never does, and its references
// still resolve.
#import "/src/lib.typ": *
#import "/src/elements/exam.typ": parse_exam_args
#import "/src/points.typ": exam_points_data
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt)

/// Record an option's value where it is read, and show it.
#let probe(where) = e.get(get => {
  let c = get(config)
  [#metadata((where: where, position: c.points-position, name: c.exam-name))<probe>]
  text(8pt, fill: gray)[[#where: #c.points-position]]
})

// The arguments, parsed.
#let ok(..args) = parse_exam_args(args)
#let error(..args) = {
  let (ok, message) = parse_exam_args(args)
  assert(not ok, message: "expected an error")
  message
}
#let Q = [#question[A]]
#assert(ok(Q).first())
#assert.eq(ok(Q).last().options, (:))
#assert(ok(questions: Q).first())
#assert(ok(x => Q).first())
#assert.eq(ok(Q, points-position: "end").last().options, (points-position: "end"))
#let ERRORS = (
  ("exam()", error(), "missing the questions"),
  ("exam(Q, questions: Q)", error(Q, questions: Q), "given twice"),
  ("exam(Q, Q)", error(Q, Q), "one positional argument"),
  ("exam(1)", error(1), "`questions` must be content | function"),
  ("exam(Q, show-solution: true)", error(Q, show-solution: true), "unknown argument `show-solution`"),
  ("exam(Q, points-position: \"top\")", error(Q, points-position: "top"), "`points-position` must be"),
  ("exam(Q, _exam-view: true)", error(Q, _exam-view: true), "unknown argument `_exam-view`"),
)
#for (call, message, expected) in ERRORS {
  assert(message.contains(expected), message: call + ": " + message)
}

#rule[The arguments: each mistake, and the message it gets]
#cases(([Call], [Message]), ..ERRORS.map(((call, message, _)) => (raw(call), text(8pt, message))))

#rule[`#exam[..]` and `#exam(questions: [..])` lay out the same, and a reference resolves with no `e.prepare()` in the document]
#grid(
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  exam[#question(points: 1, label: <pos>)[Positional.] #question[See @pos.]],
  exam(questions: [#question(points: 1, label: <named>)[Named.] #question[See @named.]]),
)

#rule[Options on `exam` apply inside it only]
#probe("before")
#exam(points-position: "end")[
  #question(points: 2)[Badge at the end. #probe("inside")]
]
#probe("after")

#rule[`#show: exam.with(..)`: the rest of its scope is the exam, a title block before the first question included]
#[
  #show: exam.with(exam-name: [Midterm], points-position: "end")
  #maketitle()
  #probe("cover")
  #question(points: 3, label: <shown>)[In the exam. #probe("question")]
  #question[See @shown.]
]
#probe("after show rule")

#rule[An exam around another (`#show: exam.with(..)` above an `#exam(..)`) steps aside: its options reach the exam inside, whose points the cover counts]
#[
  #show: exam.with(points-position: "end")
  #probe("outer cover")
  #context [#metadata(exam_points_data())<outer-cover>]
  _Cover:_ #context num-questions() questions, #context num-points() points.
  #exam[
    #question(points: 2)[First. #probe("inner")]
    #question(points: 3)[Second.]
  ]
]

#context {
  let got = query(<probe>).map(m => m.value)
  let at(where) = got.find(p => p.where == where)
  assert.eq(at("before").position, "start")
  assert.eq(at("inside").position, "end")
  assert.eq(at("after").position, "start")
  assert.eq(at("cover").position, "end")
  assert.eq(at("cover").name, [Midterm])
  assert.eq(at("question").position, "end")
  assert.eq(at("after show rule").position, "start")
  assert.eq(at("after show rule").name, none)
  assert.eq(at("outer cover").position, "end")
  assert.eq(at("inner").position, "end")
  let cover = query(<outer-cover>).first().value
  assert.eq(cover.map(q => q.total_points), (2, 3), message: "the cover counts the exam inside")
}

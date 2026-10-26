// `config` rules inside an exam, around some of its questions: the options
// the exam applies question by question (`SCOPED_OPTIONS`) hold for the
// questions, parts, and subparts in the rule's scope, and those after it
// keep the exam's. A question's own arguments win over a rule around it,
// and a rule inside a question over the question's own arguments, for its
// parts. Checked by what is drawn, and where. (`numbering` is read once,
// and its rule is an error: see tests/unit/rules-after-exam.typ.)
#import "/src/lib.typ": *
#import "/src/rubric.typ": AREA
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (x: 1.2in, y: .5in))
#set text(size: 10pt)
#show: e.prepare()

/// `body` as an exam given `options`, under its description, with the text
/// it draws recorded under `name` (see `texts`).
#let probed(name, desc, body, ..options) = {
  rule(desc)
  show text: it => context {
    let t = it.text
    state("probe-" + name, ()).update(p => p + (t,))
    it
  }
  block(stroke: .3pt + gray, inset: 6pt, exam(questions: body, ..options))
}
#let texts(name) = state("probe-" + name, ()).final()

/// A spot's left edge and top, recorded under `name` where it is written.
#let at(name) = context [#metadata(here().position())#label("at-" + name)]
#let pos(name) = query(label("at-" + name)).first().value

// --- `points-format`: from the rule on, and only in its scope ---
#probed(
  "format",
  [`points-format: p => [[#p pts]]` after question 1, in a block around question 2; question 3 after
    the block.],
  [
    #question(points: 1)[One.]
    #[
      #show: e.set_(config, points-format: p => [[#p pts]])
      #question(points: 2)[Two.]
    ]
    #question(points: 3)[Three.]
  ],
)
#context {
  // The text drawn, without the spaces, which are no text of their own.
  let t = texts("format").join()
  assert(t.contains("(1point)"), message: t)
  assert(t.contains("[2pts]"), message: t)
  assert(t.contains("(3points)"), message: "the rule ends with its block: " + t)
}

// --- `points-position`: a badge in the margin from the rule on ---
#probed(
  "position",
  [`points-position: "margin-right"` after question 1.],
  [
    #question(points: 1)[#at("q1")One.]
    #show: e.set_(config, points-position: "margin-right")
    #question(points: 2)[#at("q2")Two.]
  ],
)
#context {
  // At the start, the badge comes before the text; in the margin, it takes
  // no room, so the text starts at the number's gap.
  assert(pos("q1").x > pos("q2").x, message: repr((pos("q1"), pos("q2"))))
}

// --- a rule inside a question: for its parts, not for the question ---
#probed(
  "inside",
  [`points-format` set inside question 1, before its part.],
  [
    #question(points: 1)[
      One.
      #show: e.set_(config, points-format: p => [<#p>])
      #part(points: 2)[A part.]
    ]
  ],
  points-show-totals: false,
)
#context {
  let t = texts("inside").join()
  assert(t.contains("(1point)"), message: "the question's own badge comes before the rule: " + t)
  assert(t.contains("<2>"), message: t)
}

// --- a question's own argument over a rule around it, and a rule inside it
// over its argument, for its parts ---
#probed(
  "rubrics",
  [`rubric-position: "margin-left"` around question 1, which gives `"end"`; its second part after a
    rule inside it setting `"margin-left"` again.],
  [
    #show: e.set_(config, rubric-position: "margin-left")
    #question(rubric-position: "end", rubric: rubric(points: 1)[One.])[
      #part(rubric: rubric(points: 1)[First part.])[A part.]
      #show: e.set_(config, rubric-position: "margin-right")
      #part(rubric: rubric(points: 1)[Second part.])[Another.]
    ]
    #question(rubric: rubric(points: 1)[Two.])[Two.]
  ],
  show-rubrics: true,
)
#context {
  let sides = query(AREA).map(m => m.value).map(a => (a.id.address, a.side))
  assert.eq(
    sides.sorted(key: s => repr(s.first())),
    (((0,), "end"), ((0, 0), "end"), ((0, 1), "margin-right"), ((1,), "margin-left")).sorted(key: s => repr(s.first())),
    message: repr(sides),
  )
}

// --- `indent`: of every division in the rule's scope ---
#rule[`indent: 3em` around question 2's part; question 1's keeps the exam's `1.5em`.]
#block(stroke: .3pt + gray, inset: 6pt, exam[
  #question[#at("i1")One. #part[#at("i1a")A part.]]
  #show: e.set_(config, indent: 3em)
  #question[#at("i2")Two. #part[#at("i2a")A part.]]
])
#context {
  assert.eq(pos("i1a").x - pos("i1").x, 1.5em.to-absolute())
  assert.eq(pos("i2a").x - pos("i2").x, 3em.to-absolute())
}

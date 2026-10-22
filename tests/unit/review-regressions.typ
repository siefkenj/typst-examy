// Regressions from review: gutter labels sharing a line (also below a
// labelled division), badges at the `"end"` of a split question, totals in
// the margin, and widening a solution with an `otherwise`.
#import "/src/lib.typ": *
#import "/src/config.typ": default_points_format
#import "/tests/record.typ": rule

#set page(width: 5in, height: auto, margin: (x: 1.25in, y: .5in))
#set text(size: 10pt)
#show: e.prepare()

// Every gutter label marks where it is drawn, under its exam's name and its
// level, and the text of a body marks its first line under the same names.
#let marked(name) = (
  n => [#metadata((name, 1))<gutter>#n.],
  n => [#metadata((name, 2))<gutter>(#numbering("a", n))],
  n => [#metadata((name, 3))<gutter>#numbering("i", n).],
)
#let line(name, level) = [#metadata((name, level))<line>]
#let at(lbl, name, level) = query(lbl).find(m => m.value == (name, level)).location().position()
// How far a label is drawn from the line it labels, which in plain text is
// the same for every label.
#let offset(name, level) = at(<gutter>, name, level).y - at(<line>, name, level).y
#let near(a, b) = calc.abs((a - b).pt()) < 0.5

#rule[Plain text, for the label offset the others are compared with.]
#{
  show: e.set_(config, numbering: marked("plain"))
  exam(questions: [#question[A#line("plain", 1) question.]])
}

// --- a question sharing its first line with a part that starts with a box
// has its label level with the part's: both on the box's first line ---
#rule[A question starting with a part that starts with a box: 1. and (a) on the box's first line.]
#{
  show: e.set_(config, numbering: marked("box"))
  exam(questions: [
    #question[#part[#answer-box(width: 100%)[F#line("box", 1)irst line #linebreak() second]]]
  ])
}
#context {
  let (q, p) = (at(<gutter>, "box", 1).y, at(<gutter>, "box", 2).y)
  assert(near(q, p), message: "question label at " + repr(q) + ", part label at " + repr(p))
  assert(near(offset("box", 1), offset("plain", 1)), message: repr((offset("box", 1), offset("plain", 1))))
}

// --- a labelled part starting with a subpart shares its first line with it:
// the label's anchor makes no empty line of its own ---
#rule[A labelled part starting with a subpart: (a) and i. on one line, and the reference resolves.]
#{
  show: e.set_(config, numbering: marked("labelled"))
  exam(questions: [
    #question[#part(label: <labelled>)[#subpart[L#line("labelled", 3)abelled.]]]
    #question[See @labelled.]
  ])
}
#context {
  let (p, s) = (at(<gutter>, "labelled", 2).y, at(<gutter>, "labelled", 3).y)
  assert(near(p, s), message: "part label at " + repr(p) + ", subpart label at " + repr(s))
  assert(near(offset("labelled", 3), offset("plain", 1)), message: repr((offset("labelled", 3), offset("plain", 1))))
}

// --- with points at the `"end"`, a question split at a page break that
// starts with a part puts its badge on a line of its own, and the part's
// label stays on the part's text ---
#rule[`"end"`, split at a page break: the question's badge on its own line, then (a) beside its text.]
#{
  show: e.set_(
    config,
    numbering: marked("end"),
    points-position: "end",
    points-format: p => [#metadata(p)<end-badge>#default_points_format(p)],
  )
  exam(questions: [
    #question(points: 3)[
      #part[P#line("end", 2)art one.]
      #pagebreak()
      #part[Part two.]
    ]
  ])
}
#context {
  assert(near(offset("end", 2), offset("plain", 1)), message: repr((offset("end", 2), offset("plain", 1))))
  let badge = query(<end-badge>)
  assert(badge.len() == 1, message: "the question's badge is drawn once, found " + str(badge.len()))
  let (b, part) = (badge.first().location().position().y, at(<line>, "end", 2).y)
  assert(b < part - 5pt, message: "badge at " + repr(b) + ", part at " + repr(part))
}

// --- in the margin, a question's total is left out only when a part sharing
// its line shows a badge: here part (a) has none, so the total stays ---
#rule[Totals in the margin: part (a) has no badge, so the question keeps its total of 5.]
#{
  show: e.set_(
    config,
    points-position: "margin-left",
    points-show-totals: true,
    points-format: p => [#metadata(p)<margin>#default_points_format(p)],
  )
  exam(questions: [#question[#part[No points.] #part(points: 5)[Some.]]])
}
#context {
  let drawn = query(<margin>).map(m => m.value)
  assert(drawn == (5, 5), message: repr(drawn))
}

// --- in a box of set height, a solution with an `otherwise` fills the box on
// the key, like one without ---
#rule[A solution with `otherwise` in a box of set height (bottom) fills the box, like one without (top).]
#{
  show: e.set_(config, show-solutions: true)
  for (name, sol) in (
    ("plain", solution[An answer.#place(right)[#metadata("plain")<sol-end>]]),
    ("otherwise", solution(otherwise: [blank])[An answer.#place(right)[#metadata("otherwise")<sol-end>]]),
  ) {
    answer-box(width: 100%, height: 2cm, sol)
  }
}
#context {
  let x(name) = query(<sol-end>).find(m => m.value == name).location().position().x
  assert(near(x("plain"), x("otherwise")), message: repr((x("plain"), x("otherwise"))))
}

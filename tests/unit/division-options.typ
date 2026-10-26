// The options a question, part, or subpart takes for itself, beside the
// exam's: `numbering`, `rubric-position`, `rubric-trace` and `rubric-width`,
// for itself and the divisions in it unless they give their own, and
// `indent`, for itself, `config`'s `indent` where it gives none.
#import "/src/lib.typ": *
#import "/src/points.typ": _exam_rows
#import "/src/rubric.typ": AREA
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (x: 1.5in, y: .5in))
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

/// Content as plain text, for comparing.
#let plain(c) = if type(c) == str { c } else if c.has("text") { c.text } else if c.has("children") {
  c.children.map(plain).join()
} else if c.has("body") { plain(c.body) } else { "" }

/// A division's left edge, recorded under `name` where it is written.
#let at(name) = context [#metadata(here().position().x)#label("x-" + name)]
#let x(name) = query(label("x-" + name)).first().value

// --- `numbering`: of a question and the parts in it ---
// The points table labels the part as a reference reads. (Read before the
// exam, which a reader before any exam is about.)
#context {
  let labels = _exam_rows().last().map(r => plain(r.label).replace(sym.space.thin, " "))
  assert.eq(labels.slice(0, 4), ("1", "Bonus 2", "Bonus 2 1)", "Bonus 2 2)"), message: repr(labels))
}
#probed(
  "numbering",
  [`question(numbering: ("Bonus 1.", "1)"))` between two questions as the exam numbers them; a reference to its part
    after them.],
  [
    #question[First.]
    #question(numbering: ("Bonus 1.", "1)"))[
      Second. #part(label: <bonus-part>, points: 1)[Its part.] #part(points: 1)[Another.]
    ]
    #question[Third. #part[A part, as the exam numbers it.]]
    #question[See @bonus-part.]
  ],
)
#context {
  let t = texts("numbering")
  for label in ("1.", "Bonus 2.", "1)", "2)", "3.", "(a)", "4.") {
    assert(label in t, message: "numbering: " + repr(label) + " is not drawn in " + repr(t))
  }
  assert("2." not in t, message: "the question's own numbering replaces the exam's")
  // The reference reads as the part is numbered: "Bonus 2", then "1)"
  // (only a trailing "." is dropped).
  let i = t.position(s => s == "See")
  assert.eq(t.slice(i + 1, i + 4), ("Bonus 2", "\u{2009}", "1)"), message: repr(t.slice(i)))
}

// --- `numbering`: of a part, under a question the exam numbers ---
// The question's number stays the exam's, in a reference to the part from
// outside it, in the points table, and in the part's full number.
#let THIN = "\u{2009}"
#for full in (false, true) {
  let name = "part-numbering-" + repr(full)
  context {
    let labels = _exam_rows().last().map(r => plain(r.label))
    let expected = ("1", "1" + THIN + "A", "1" + THIN + "A" + THIN + "A", "1" + THIN + "(b)", "2")
    assert.eq(labels, expected, message: name + ": " + repr(labels))
  }
  probed(
    name,
    [`part(numbering: "A.")` in question 1, its subpart numbered so too, with `numbering-full: #full`;
      references to them from question 2.],
    [
      #question[One. #part(numbering: "A.", label: <own-part>, points: 1)[Its part.
          #subpart(label: <own-subpart>, points: 1)[Its subpart.]]
        #part(points: 1)[As the exam numbers it.]]
      #question(points: 1)[See @own-part and @own-subpart.]
    ],
    numbering-full: full,
  )
  context {
    let t = texts(name)
    let i = t.position(s => s == "See")
    let (part, subpart) = if full { ("1" + THIN + "A", "1" + THIN + "A" + THIN + "A") } else { ("1", "1") }
    if full {
      assert.eq(t.slice(i + 1, i + 5), (part, "and", subpart, "."), message: name + ": " + repr(t.slice(i)))
      for label in ("1.", part + ".", subpart + ".", "1" + THIN + "(b)") {
        assert(label in t, message: name + ": " + repr(label) + " is not drawn in " + repr(t))
      }
    } else {
      assert.eq(
        t.slice(i + 1, i + 10),
        ("1", THIN, "A", "and", "1", THIN, "A", THIN, "A"),
        message: name + ": " + repr(t.slice(i)),
      )
      for label in ("1.", "A.", "(b)") {
        assert(label in t, message: name + ": " + repr(label) + " is not drawn in " + repr(t))
      }
    }
  }
}

// --- rubric options: a question's, and its parts' ---
#probed(
  "rubrics",
  [`rubric-position: "end"` on question 2, its part's rubric too; question 3's part in the left margin, by its own
    option.],
  [
    #question(rubric: rubric(points: 1)[First.])[One.]
    #question(rubric-position: "end", rubric: rubric(points: 1)[Second.])[
      Two. #part(rubric: rubric(points: 1)[Its part.])[A part.]
    ]
    #question(rubric: rubric(points: 1)[Third.])[
      Three. #part(rubric-position: "margin-left", rubric-width: 2cm, rubric: rubric(points: 1)[Left.])[A part.]
    ]
  ],
  show-rubrics: true,
  rubric-position: "margin-right",
)
#context {
  let exam = query(AREA).map(m => m.value.id.exam).dedup()
  assert.eq(exam.len(), 1, message: "one exam has rubrics")
  let sides = query(AREA).map(m => m.value).map(a => (a.id.address, a.side))
  assert.eq(
    sides.sorted(key: s => repr(s.first())),
    (
      ((0,), "margin-right"),
      ((1,), "end"),
      ((1, 0), "end"),
      ((2,), "margin-right"),
      ((2, 0), "margin-left"),
    ).sorted(key: s => repr(s.first())),
    message: repr(sides),
  )
}

// --- `indent`: `config`'s, and a division's own ---
#rule[`config`'s `indent: 3em`; question 2's part given `indent: 1em`.]
#block(stroke: .3pt + gray, inset: 6pt, {
  show: e.set_(config, indent: 3em)
  exam[
    #question[#at("q1")One. #part[#at("q1a")A part.]]
    #question[#at("q2")Two. #part(indent: 1em)[#at("q2a")A part.]]
  ]
})
#context {
  assert.eq(x("q1a") - x("q1"), 3em.to-absolute(), message: "config's indent indents a part")
  assert.eq(x("q2a") - x("q2"), 1em.to-absolute(), message: "a part's own indent wins")
}

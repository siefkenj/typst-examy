// `config` rules setting `numbering` inside an exam: the questions, parts,
// and subparts after a rule, in its scope, are numbered by it, and those
// after its scope as the exam numbers them. Its left-most pattern numbers
// the questions even inside a question, so a rule around a part leaves its
// question's number as the exam's. References, the points table, the
// rubrics' cards and full numbers (`numbering-full`) read the numbers as
// drawn.
#import "/src/lib.typ": *
#import "/src/points.typ": _exam_rows
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (left: 1.2in, right: 2in, y: .5in))
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

#let THIN = "\u{2009}"

/// The pieces of text drawn after the first `word` in `t`, `n` of them.
#let after(t, word, n) = {
  let i = t.position(s => s == word)
  assert(i != none, message: repr(word) + " is not drawn in " + repr(t))
  t.slice(i + 1, i + 1 + n)
}

// --- a rule around a question: it and its parts ---
// The points table labels the parts as a reference reads. (Read before the
// exam, which a reader before any exam is about.)
#context {
  let labels = _exam_rows().last().map(r => plain(r.label).replace(THIN, " "))
  assert.eq(labels.slice(0, 4), ("1", "Bonus 2", "Bonus 2 1)", "Bonus 2 2)"), message: repr(labels))
}
#probed(
  "question",
  [`numbering: ("Bonus 1.", "1)")` around question 2, between two questions the exam numbers; a
    reference to its part after them, and its part's rubric card.],
  [
    #question[First.]
    #[
      #show: e.set_(config, numbering: ("Bonus 1.", "1)"))
      #question[
        Second. #part(label: <bonus-part>, points: 1, rubric: rubric(points: 1)[Its rubric.])[Its part.]
        #part(points: 1)[Another.]
      ]
    ]
    #question[Third. #part[A part, as the exam numbers it.]]
    #question[See @bonus-part.]
  ],
  show-rubrics: true,
)
#context {
  let t = texts("question")
  for label in ("1.", "Bonus 2.", "1)", "2)", "3.", "(a)", "4.") {
    assert(label in t, message: repr(label) + " is not drawn in " + repr(t))
  }
  assert("2." not in t, message: "the rule's numbering replaces the exam's")
  // The reference reads as the part is numbered: "Bonus 2", then "1)"
  // (only a trailing "." is dropped).
  assert.eq(after(t, "See", 3), ("Bonus 2", THIN, "1)"), message: repr(t))
  // So does its rubric's card.
  assert.eq(after(t, "Question", 3), ("Bonus 2", THIN, "1)"), message: repr(t))
}

// --- a rule around a part: the part and its subpart, not its question ---
// The question's number stays the exam's, in a reference to the part from
// outside it, in the points table, and in the part's full number.
#for full in (false, true) {
  let name = "part-" + repr(full)
  context {
    let labels = _exam_rows().last().map(r => plain(r.label))
    let expected = ("1", "1" + THIN + "A", "1" + THIN + "A" + THIN + "A", "1" + THIN + "(b)", "2")
    assert.eq(labels, expected, message: name + ": " + repr(labels))
  }
  probed(
    name,
    [`numbering: "A."` around question 1's first part, its subpart numbered so too, with
      #raw("numbering-full: " + repr(full)); references to them from question 2.],
    [
      #question[One.
        #[
          #show: e.set_(config, numbering: "A.")
          #part(label: <own-part>, points: 1)[Its part.
            #subpart(label: <own-subpart>, points: 1)[Its subpart.]]
        ]
        #part(points: 1)[As the exam numbers it.]]
      #question(points: 1)[See @own-part and @own-subpart.]
    ],
    numbering-full: full,
  )
  context {
    let t = texts(name)
    let (part, subpart) = if full { ("1" + THIN + "A", "1" + THIN + "A" + THIN + "A") } else { ("1", "1") }
    if full {
      assert.eq(after(t, "See", 4), (part, "and", subpart, "."), message: name + ": " + repr(t))
      for label in ("1.", part + ".", subpart + ".", "1" + THIN + "(b)") {
        assert(label in t, message: name + ": " + repr(label) + " is not drawn in " + repr(t))
      }
    } else {
      assert.eq(
        after(t, "See", 9),
        ("1", THIN, "A", "and", "1", THIN, "A", THIN, "A"),
        message: name + ": " + repr(t),
      )
      for label in ("1.", "A.", "(b)") {
        assert(label in t, message: name + ": " + repr(label) + " is not drawn in " + repr(t))
      }
    }
  }
}

// --- a rule inside a question, between its parts; and one with no block
// around it, for the rest of the exam ---
#probed(
  "between",
  [`numbering: ("1.", "i.")` inside question 1 after its first part; then `numbering: ("Q1:", "[a]")`
    before question 3, for the rest of the exam. A reference from question 3 to question 1's second
    part.],
  [
    #question[One.
      #part[First.]
      #show: e.set_(config, numbering: ("1.", "i."))
      #part(label: <second>)[Second.]
    ]
    #question[Two. #part[As the exam numbers it.]]
    #show: e.set_(config, numbering: ("Q1:", "[a]"))
    #question[Three, see @second. #part[Its part.]]
  ],
)
#context {
  let t = texts("between")
  for label in ("1.", "(a)", "ii.", "2.", "Q3:", "[a]") {
    assert(label in t, message: repr(label) + " is not drawn in " + repr(t))
  }
  assert("(b)" not in t, message: "the rule numbers question 1's second part: " + repr(t))
  assert("3." not in t, message: "the rule numbers question 3: " + repr(t))
  // The part's own label, as drawn ("ii"), after its question's.
  assert.eq(after(t, "Three, see", 3), ("1", THIN, "ii"), message: repr(t))
}

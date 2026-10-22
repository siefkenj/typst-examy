// The check every question, part, and subpart carries that an exam lays it
// out (see `outside_check` in src/markers.typ): placed beside its begin
// marker, and dropped by the exam that reads the markers, so that it is
// never drawn in an exam. Drawn, it shows a warning in red and leaves
// `metadata` labelled `<examy-warning>`; tests/run.sh also compiles the
// documents in tests/not-laid-out/ with each `--input _debug_panic=..`: `panic`
// turns it into a failed compile, and `none` leaves it out.
#import "/src/lib.typ": *
#import "/src/markers.typ": is_outside_check
#import "/src/tokenize.typ": tokenize
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt)

/// The checks in content, however deep.
#let checks(c) = {
  if is_outside_check(c) { return 1 }
  if type(c) != content { return 0 }
  if c.has("children") { return c.children.map(checks).sum(default: 0) }
  if c.has("body") { return checks(c.body) }
  if c.has("child") { return checks(c.child) }
  0
}

#let CASES = (
  ("A question", question[A], 1),
  ("A question with two parts, one with a subpart", question[A #part[B #subpart[C]] #part[D]], 4),
)
#for (desc, c, n) in CASES {
  // Each division carries one, and the exam's tokens hold none.
  assert.eq(checks(c), n, message: desc)
  assert(tokenize(c).all(t => t.kind != "chunk" or checks(t.body) == 0), message: desc)
}

#rule[Each division carries a check, and the exam reads none of them]
#cases(
  ([Divisions], [Checks carried], [Checks in the exam's tokens]),
  ..CASES.map(((desc, c, n)) => (desc, str(checks(c)), str(tokenize(c).filter(t => t.kind == "chunk").map(t => checks(t.body)).sum(default: 0)))),
)

#rule[Laid out by an exam, a question draws no check]
#exam[#question(points: 1)[A question #part[with a part.]]]

#rule[Outside an exam, a part draws the warning in its place, before its plain text]
#part(points: 1)[A part outside any exam, with $x^2$ in it.]

#rule[Outside an exam, a question with parts draws one warning, its own, for all of them]
#question(points: 1)[A question #part[with a part #subpart[and a subpart.]] #part[And another part.]]

#context {
  let warnings = query(<examy-warning>).map(m => m.value)
  assert.eq(warnings.map(w => w.kind), ("not-laid-out",) * 2)
  assert.eq(warnings.map(w => w.name), ("part", "question"))
  assert.eq(warnings.first().words, "A part outside any exam, with $…$ in it.")
  assert.eq(warnings.last().words, "A question with a part and a subpart. An…")
}

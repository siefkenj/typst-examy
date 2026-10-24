// `points-table(by: "part")` and `by: "subpart"`: which columns the table
// has (`table_columns`). A division at the table's level has a column of its
// points and its parts'; one above it, a column of its own points, if it has
// any; a question with no column among its divisions, one of its own. Every
// point is in one column, so the total is the same at every level. A column
// is labelled exactly as a reference to its division reads ("??" where it
// is unnumbered), and links to it.
#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/points.typ": DIVISION_MARKER, compute_points_data, table_columns
#import "/src/markers.typ": excerpt
#import "/src/divisions.typ": part, question, subpart
#import "/src/lib.typ": config, e, exam, points-table
#import "/tests/record.typ": rule

#set page(width: 16cm, height: auto, margin: (x: 1cm, y: .8cm))
#set text(size: 10pt)
#show: e.prepare()

/// The columns of `body`'s table at `level`, as `(label, points, bonus)`,
/// each label as plain text.
#let columns(body, level, ..options) = table_columns(compute_points_data(parse(tokenize(body)), ..options), level).map(
  c => (excerpt(c.label, 30).replace(sym.space.thin, " "), c.points, c.bonus),
)

/// The example of the documentation: points on a question, on a part, and
/// on both.
#let EXAMPLE = [
  #question(points: 2)[A]
  #question[#part(points: 3)[B]]
  #question(points: 4)[C #part(points: 5)[D]]
]

// --- by question, today's table: each question's total ---
#assert.eq(columns(EXAMPLE, 1), (("1", 2, none), ("2", 3, none), ("3", 9, none)))
// --- by part: a question's own points in a column of their own, before its
// parts' ---
#assert.eq(columns(EXAMPLE, 2), (("1", 2, none), ("2 (a)", 3, none), ("3", 4, none), ("3 (a)", 5, none)))
// --- by subpart: parts with no subparts fall back to their own points ---
#assert.eq(columns(EXAMPLE, 3), columns(EXAMPLE, 2))

#let MIXED = [
  #question[
    #part(points: 1)[A part with points of its own and on its subparts.
      #subpart(points: 2)[i]
      #subpart(points: 3)[ii]
    ]
    #part[No points.]
    #part(points: 2, intent: "bonus")[Bonus only.]
    #part(points: 4, intent: "practice")[Practice only.]
  ]
  #question[No points at all.]
  #question(number: none)[#part(points: 1)[In an unnumbered question.]]
]

// --- by part: a part's subparts roll up into it; a part with no points has
// no column, a bonus-only part one of 0 points; practice points count
// nowhere; a question with no points has a column of 0; a part of an
// unnumbered question is labelled as a reference to it reads ---
#assert.eq(columns(MIXED, 2), (
  ("1 (a)", 6, none),
  ("1 (c)", 0, 2),
  ("2", 0, none),
  ("?? (a)", 1, none),
))
// --- by subpart: a part with points of its own has a column of them ---
#assert.eq(columns(MIXED, 3), (
  ("1 (a)", 1, none),
  ("1 (a) i", 2, none),
  ("1 (a) ii", 3, none),
  ("1 (c)", 0, 2),
  ("2", 0, none),
  ("?? (a)", 1, none),
))
// --- the total is the same at every level ---
#for body in (EXAMPLE, MIXED) {
  let totals = (1, 2, 3).map(level => columns(body, level).map(c => c.at(1)).sum())
  assert(totals.dedup().len() == 1, message: repr(totals))
}
// --- with `numbering-full`, labels read as full references do ---
#assert.eq(columns(EXAMPLE, 2, full: true).map(c => c.first()), ("1", "2 (a)", "3", "3 (a)"))

// A visual record: the tables at each level, above the exam they are of.
#for (body, desc) in ((EXAMPLE, [The example]), (MIXED, [Mixed points])) {
  rule[#desc: by question, by part, by subpart (with a Bonus row). Each label links to its division.]
  exam[
    #for by in ("question", "part", "subpart") {
      align(center, points-table(by: by, bonus: true))
      v(4pt)
    }
    #body
  ]
}

// --- every label links to where its division starts, as its marker
// records ---
#context {
  let links = query(link)
  // The example's 3 + 4 + 4 columns, and the mixed points' 3 + 4 + 6.
  assert.eq(links.len(), 24)
  let starts = query(DIVISION_MARKER).map(m => m.location().position())
  for l in links {
    assert(type(l.dest) == location, message: repr(l.dest))
    assert(l.dest.position() in starts, message: "a link to " + repr(l.dest.position()))
  }
}

// Where the points badge is drawn for each `points-position`, numbering
// with words in the gutter, and every layout of the points table.
#import "/src/lib.typ": *
#import "/src/config.typ": default_points_format
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (x: 1.5in, y: .5in))
#set text(size: 10pt)
#show: e.prepare()

#let LEFT = 1.5in
#let RIGHT = 4.5in

// Each badge marks where it starts, under the name of its position.
#rule[The badge at the start, in the left margin, in the right margin, and at the end.]
#for position in ("start", "margin-left", "margin-right", "end") {
  show: e.set_(config, points-position: position, points-format: p => [#metadata(position)<badge>#default_points_format(p)])
  exam(questions: [
    #question(points: 2)[A#metadata(position)<text> question.]
  ])
}

#context {
  let at(lbl, position) = query(lbl).filter(m => m.value == position).first().location().position()
  for position in ("start", "margin-left", "margin-right", "end") {
    let badge = at(<badge>, position)
    let text = at(<text>, position)
    let msg = position + ": badge at " + repr(badge) + ", text at " + repr(text)
    if position == "start" {
      assert(badge.x < text.x, message: msg)
    } else if position == "margin-left" {
      assert(badge.x < LEFT, message: msg)
    } else if position == "margin-right" {
      assert(badge.x > RIGHT, message: msg)
    } else {
      // Flush right on the text's own line, which is short.
      assert(badge.x > text.x + 2in and badge.x < RIGHT, message: msg)
    }
    // On the first line of the body, level with a badge at the start.
    let start = at(<badge>, "start").y - at(<text>, "start").y
    assert(calc.abs((badge.y - text.y - start).pt()) < 0.5, message: msg)
  }
}

// --- a long gutter label runs out to the left instead of wrapping ---
#rule[A label wider than the gutter runs out to the left, on one line.]
#{
  show: e.set_(config, numbering: ("Problem 1.",))
  exam(questions: [#question[A question.]])
}
#context {
  // The question is one line tall: the label did not wrap.
  let height = measure(block(width: 3in, {
    show: e.set_(config, numbering: ("Problem 1.",))
    exam(questions: [#question[A question.]])
  })).height
  let one_line = measure(block(width: 3in, exam(questions: [#question[A question.]]))).height
  assert(calc.abs((height - one_line).pt()) < 0.5, message: repr((height, one_line)))
}

#rule[Every layout of the points table, counting the exam at the very end.]
// --- every layout of the points table compiles and draws a table ---
#for direction in ("horizontal", "vertical") {
  for by in ("question", "page") {
    for (score, bonus, max) in ((false, false, none), (true, true, 2)) {
      show: e.set_(
        config,
        points-table-direction: direction,
        points-table-by: by,
        points-table-score: score,
        points-table-bonus: bonus,
        points-table-max-columns: max,
        strings: (total: [Sum]),
      )
      rule[#direction, by #by#if score [, with a score row and a bonus row#if direction == "horizontal" [, at most 2 columns wide]]. ]
      points-table()
    }
  }
}
#context {
  let tables = query(table)
  assert(tables.len() >= 8, message: "expected the points tables, found " + str(tables.len()))
}

// --- an argument wins over `config`'s option; `auto` takes the option ---
#rule[Arguments over `config`: vertical by `config`, then `direction: "horizontal"`; at most 2 columns by `config`, then `max-columns: none`.]
#[
  #show: e.set_(config, points-table-direction: "vertical", points-table-max-columns: 2)
  #let marked(name, t) = [#metadata(name)<table-case> #t]
  #marked("config", points-table())
  #marked("direction", points-table(direction: "horizontal"))
  #marked("max-columns", points-table(direction: "horizontal", max-columns: none))
  #marked("max-columns auto", points-table(direction: "horizontal"))
  // The exam they are about: the next one.
  #exam(questions: range(4).map(i => question(points: 1)[Q.]).join())
]
#context {
  // The tables after each mark, up to the next: their column counts.
  let marks = query(<table-case>)
  let columns = marks.enumerate().map(((i, m)) => {
    let sel = selector(table).after(m.location())
    if i + 1 < marks.len() { sel = sel.before(marks.at(i + 1).location()) }
    query(sel).map(t => if type(t.columns) == int { t.columns } else { t.columns.len() })
  })
  // The exam after them has 4 questions: vertical, 2 columns (question,
  // points); horizontal, a column per question and the total, one more for
  // the headings, or at most 2 of them per table.
  assert.eq(columns.at(0), (2,), message: repr(columns))
  assert.eq(columns.at(1), (3, 3, 2), message: repr(columns))
  assert.eq(columns.at(2), (6,), message: repr(columns))
  assert.eq(columns.at(3), (3, 3, 2), message: repr(columns))
}

// --- in the margin, a question starting with a part shares its line, where
// the question's total is left out, but not points of its own ---
#rule[In the margin, a question starting with a part: its total left out (top), its own points kept (bottom).]
#for (totals, body) in (
  (true, [#question[#part(points: 2)[a] #part(points: 3)[b]]]),
  (false, [#question(points: 1)[#part(points: 2)[a]]]),
) {
  show: e.set_(
    config,
    points-position: "margin-right",
    points-show-totals: totals,
    points-format: p => [#metadata((totals, p))<shared>#default_points_format(p)],
  )
  exam(questions: body)
}
#context {
  let drawn(totals) = query(<shared>).map(m => m.value).filter(v => v.first() == totals).map(v => v.last())
  assert(drawn(true) == (2, 3), message: repr(drawn(true)))
  assert(drawn(false) == (1, 2), message: repr(drawn(false)))
}

// The exam the points tables count (they read the last exam's points): three
// questions, one with a bonus part, so that the tables show their bonus row
// and split at 2 columns.
#rule[The exam the tables count: 2, 3 with a bonus of 1, and 4.]
#exam(questions: [
  #question(points: 2)[First.]
  #question[#part(points: 3)[Second.] #part(points: 1, intent: "bonus")[Bonus.]]
  #question(points: 4)[Third.]
])

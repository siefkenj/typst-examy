// Gutter labels on a shared line: a question whose body starts with a part
// draws "1." on the part's first line, left of its "(a)". Each label ends
// `LABEL_GAP` short of its own division's text, so with a small indent the
// two would be drawn over each other. The first label of a line never
// moves, so the questions' labels stay in line; a label after it moves right
// only as far as it must to start `LABEL_SEP` after the one before it, and
// the line's text with it (a part starting with a box, which cannot move,
// has its labels on a line of their own above the box, on the box's page,
// the badges in the margin with them, however far down the box's text is).
// Every other label, "(b)" say, is in line with the labels of its level.
// With an indent wider than the labels, none moves. The lines after the
// first of the paragraph that moved wrap back under the line's first label,
// but never into the margin, where the badges and rubrics there are: with no
// indent, they start at the text's edge. Not when that paragraph holds a
// box, as an inline solution is, which is only as wide as the paragraph:
// then its lines start at the text, as any other's. The badges in the left
// margin keep clear of the labels at the text size they are drawn at, not
// the one the exam starts at, all in line, but not of a label so wide that
// they would leave the page: the page they are on, whose margin may not be
// the one the exam starts on.
//
// Each label is drawn by a numbering function that leaves a probe at its
// start and at its end, and each division's text starts with a probe (`T`),
// for the positions checked below.
#import "/src/lib.typ": *
#import "/src/render.typ": LABEL_GAP, LABEL_SEP
#import "/src/config.typ": default_points_format
#import "/tests/record.typ": cases

/// A caption for a case, as `rule` in record.typ draws one, with 1em more
/// space above its line and the description at the left.
#let rule(desc) = {
  block(above: 14pt + 1em, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  block(emph(text(9pt, desc)))
}

/// The left edge of the text.
#let EDGE = 2in

#set page(width: 6.1in, height: auto, margin: (x: EDGE, y: .3in))
#set text(size: 10pt)

/// A probe, in a box: a bare `metadata` in a line is found at the line's
/// start.
#let probe(value, lbl) = box[#metadata(value)#lbl]

/// The numbering of case `case`, its probes telling the case, the level,
/// and the number.
#let probed(case) = range(3).map(level => n => {
  let at(edge) = probe((case: case, level: level + 1, n: n, edge: edge), <label-edge>)
  at("start") + numbering(("1.", "(a)", "i.").at(level), n) + at("end")
})

/// Where the text of the `n`th division of `level` starts, in case `case`.
#let T(case, level, n) = probe((case: case, level: level, n: n), <text-start>)

/// Where the second line of the first paragraph of the `n`th division of
/// `level` starts, after a line break, in case `case`.
#let W(case, level, n) = [#linebreak()#probe((case: case, level: level, n: n), <wrap-start>)]

/// The points badges of case `case` as they are drawn by default, "(4
/// points)", probed at their start and end.
#let probed_points(case) = p => {
  probe((case: case, edge: "start"), <badge-edge>) + default_points_format(p) + probe((case: case, edge: "end"), <badge-edge>)
}

/// A question with points, starting with a part with points, and another
/// question: for each `points-position`, with no indent.
#let POINTED = c => [
  #question(points: 4)[#part(points: 2)[A part, long enough to wrap onto a second line.] #part(points: 2)[Another.]]
  #question(points: 1)[A question with text first.]
]

/// The case of a label wider than the left margin.
#let WIDE = "No indent, points-position \"margin-left\", a label wider than the margin: the badges clear the others' labels, all in line, on the page; the wide one's is drawn over it"

/// `(description, exam options, questions as a function of the case,
/// whether the indent leaves room for every label)`: two labels of each
/// level at least, to tell whether they stay in line.
#let CASES = (
  (
    "Default indent: nothing moves",
    (:),
    c => [
      #question[#part[#T(c, 2, 1)A part on the question's line.#W(c, 2, 1)Its second line.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first. #part[#T(c, 2, 1)Its part.]]
    ],
    true,
  ),
  (
    "No indent: \"(a)\" moves right of \"1.\", and its line's text with it; \"(b)\" and \"2.\" stay in line with \"1.\"",
    (indent: 0pt),
    c => [
      #question[#part[#T(c, 2, 1)A part on the question's line.#W(c, 2, 1)Its second line, at the text's edge, long enough to wrap onto a third.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, three levels: \"(a)\" moves right of \"1.\", and \"i.\" right of \"(a)\"",
    (indent: 0pt),
    c => [
      #question[#part[#subpart[#T(c, 3, 1)A subpart on the line.#W(c, 3, 1)Its second line.] #subpart[#T(c, 3, 2)Another.]] #part[#T(c, 2, 2)A part.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, the part split by a column break (laid out in pieces)",
    (indent: 0pt),
    c => [
      #question[#part[#T(c, 2, 1)Before the break. #colbreak() After it.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, the part starting with a box: the labels on a line of their own, above it",
    (indent: 0pt),
    c => [
      #question[#part[#answer-box(width: 100%, height: .8cm)[#probe((case: c), <box-top>)]] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "A wide indent: nothing moves, and every level stays in line",
    (indent: 3em),
    c => [
      #question[#part[#T(c, 2, 1)A part on the question's line.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first. #part[#T(c, 2, 1)Its part.]]
    ],
    true,
  ),
  (
    "Questions indented, parts not: the second line of \"(a)\" under the \"1.\", in the text",
    (:),
    c => [
      #question[#part(indent: 0pt)[#T(c, 2, 1)A part on the question's line.#W(c, 2, 1)Its second line, under the "1.", long enough to wrap onto a third.] #part(indent: 0pt)[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, points-position \"margin-left\", the text set larger inside the exam: the badges clear the labels",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #set text(size: 18pt)
      #POINTED(c)
    ],
    false,
  ),
  ..("start", "margin-right", "margin-left", "end").map(pos => (
    "No indent, with points on the question and its parts, points-position \"" + pos + "\"",
    (indent: 0pt, points-position: pos),
    POINTED,
    false,
  )),
  (
    "No indent, a block that a context makes, and a list, in the part after its first line: both kept",
    (indent: 0pt),
    c => [
      #question[#part[#T(c, 2, 1)Text before a block #context block(probe((case: c), <kept>) + [made by a `context`]) and a list.
        - #probe((case: c), <kept>)An item.
      ] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    WIDE,
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #question(points: 4)[#T(c, 1, 1)A question.]
      #[
        #show: e.set_(config, numbering: n => [The widest label of this exam, #n:])
        #question(points: 1)[A label wider than the margin.]
      ]
      #question(points: 10)[#T(c, 1, 3)Another question.]
    ],
    false,
  ),
  (
    "No indent, points-position \"end\": the badge of the part on the question's line ends its text's last line",
    (indent: 0pt, points-position: "end"),
    c => [
      #question[#part(points: 3)[#T(c, 2, 1)The part's text.#probe((case: c), <text-end>) #subpart[#T(c, 3, 1)A subpart.] #subpart[#T(c, 3, 2)Another.]] #part[#T(c, 2, 2)Another part.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "Indent 1.2em, points-position \"margin-left\", the part starting with a box with an inset: its labels and the badges on a line of their own above it",
    (indent: 1.2em, points-position: "margin-left"),
    c => [
      #question(points: 4)[#part(points: 2)[#box(width: 100%, inset: 12pt, stroke: .5pt)[#probe((case: c), <box-top>)Body]] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "Questions indented, parts not, a solution in the first paragraph of \"(a)\": its second line at the text, and the text after the solution below it",
    (show-solutions: true),
    c => [
      #question[#part(indent: 0pt)[#T(c, 2, 1)A part on the question's line, long enough to wrap #solution[a solution long enough to wrap around its line, yes] #probe((case: c), <after-solution>)more.] #part(indent: 0pt)[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, points-position \"margin-left\", an unnumbered subpart on the part's line: its text moves right of \"(a)\", its second line wraps back to the text's edge, and the badges stay on its line",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #question(points: 2)[#part(points: 2)[#subpart(number: none)[#probe((case: c), <badge-line>)#T(c, 2, 1)A subpart with no number.#W(c, 2, 1)Its second line, at the text's edge.]] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "The same, the subpart holding an `fr` answer box (laid out in pieces)",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #question(points: 2)[#part(points: 2)[#subpart(number: none)[#probe((case: c), <badge-line>)#T(c, 2, 1)A subpart with no number.#W(c, 2, 1)Its second line, at the text's edge. #answer-box(height: 1fr)[]]] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, points-position \"margin-left\", an unnumbered subpart starting with a box: the labels and the badges on a line of their own above it",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #question(points: 2)[#part(points: 2)[#subpart(number: none)[#answer-box(width: 100%, height: .8cm)[#probe((case: c), <box-top>)]]] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "Indent 1.6em, a wider font set inside the exam, points-position \"margin-left\": the labels measured in it, \"(a)\" clear of \"1.\", and the badges clear of both",
    (indent: 1.6em, points-position: "margin-left"),
    c => [
      #set text(font: "DejaVu Sans Mono")
      #question(points: 2)[#part(points: 2)[#T(c, 2, 1)A part on the question's line.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, `show text: upper` inside the exam, points-position \"margin-left\": the labels measured in capitals, as they are drawn, \"(A)\" clear of \"1.\", and the badges clear of both",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #show text: upper
      #question(points: 2)[#part(points: 2)[#T(c, 2, 1)A part on the question's line.] #part[#T(c, 2, 2)Another.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "No indent, a wider font set inside the question, before an unnumbered part, points-position \"margin-left\": \"1.\" measured in it, as it is drawn on the part's line, and the badge clear of it",
    (indent: 0pt, points-position: "margin-left"),
    c => [
      #question[#set text(font: "DejaVu Sans Mono"); #part(number: none, points: 2)[A part on the question's line.]]
      #question[#T(c, 1, 2)A question with text first.]
    ],
    false,
  ),
  (
    "Default indent, a large word on the line \"1.\" and \"(a)\" share: both on its baseline",
    (:),
    c => [
      #question[#part[#probe((case: c), <baseline>)#text(20pt)[Big] text on the question's line.]]
      #question[#T(c, 1, 2)A question with text first. #part[#T(c, 2, 1)Its part.]]
    ],
    true,
  ),
  (
    "Default indent, a solution on the line \"1.\" and \"(a)\" share: both on its baseline",
    (show-solutions: true),
    c => [
      #question[#part[#probe((case: c), <baseline>)Text #solution[an inline solution] more.]]
      #question[#T(c, 1, 2)A question with text first. #part[#T(c, 2, 1)Its part.]]
    ],
    true,
  ),
)

#for (i, (desc, options, body, _)) in CASES.enumerate() {
  rule[Case #(i + 1): #desc]
  exam(numbering: probed(i), points-format: probed_points(i), ..options, body(i))
}

// A part starting with a table where only its labels fit on the page: they
// are on a line of their own above it, which goes to the next page with it.
#page(height: 2.5in)[
  #rule[No indent, a part starting with a table, where only its labels fit on the page: they go to the next page with it]
  #v(70pt)
  #exam(numbering: probed("kept"), indent: 0pt)[
    #question[#part[#table(columns: 2, probe((case: "kept"), <table-top>) + [a], [b], [c], [d])]]
  ]
]

// An exam over two pages whose left margins differ (`inside`, `outside`):
// one wide, and one as wide as a badge with no room to move. Each badge
// clears the labels as far as it stays on its own page.
#context page(
  margin: (inside: EDGE, outside: measure(default_points_format(3)).width + 1em.to-absolute() + 2pt, y: .3in),
  height: 1.6in,
)[
  #rule[No indent, points-position "margin-left", pages whose left margins differ: on the wide one the badge clears the "1.", on the narrow one it stays on the page, drawn over the "2."]
  #exam(numbering: probed("pages"), points-format: probed_points("pages"), indent: 0pt, points-position: "margin-left")[
    #question(points: 3)[A question.]
    #pagebreak()
    #question(points: 3)[Another, on the next page.]
  ]
]

#context {
  let (sep, gap) = (LABEL_SEP.to-absolute(), LABEL_GAP.to-absolute())
  let close(a, b) = calc.abs((a - b) / 1pt) < .01
  let rows = ()
  for (i, (desc, _, _, room)) in CASES.enumerate() {
    let probes = query(<label-edge>).filter(m => m.value.case == i)
    // Each label's probes, at its start and its end, one after the other.
    let labels = probes
      .chunks(2)
      .map(((s, e)) => (level: s.value.level, n: s.value.n, start: s.location().position(), end: e.location().position()))
    let same_line(a, b) = a.page == b.page and calc.abs((a.y - b.y) / 1pt) < 4
    // Those on a line before `l`, which it may have moved right of.
    let before(l) = labels.filter(o => o.level < l.level and same_line(o.end, l.start))
    // Labels on one line keep `LABEL_SEP` apart at least.
    let gaps = ()
    for l in labels {
      for o in before(l) {
        let g = l.start.x - o.end.x
        assert(g >= sep - .01pt, message: "case " + str(i + 1) + ": " + repr((o.level, o.n)) + " and " + repr((l.level, l.n)) + " are " + repr(g) + " apart")
        gaps.push(g)
      }
    }
    // The labels of a level first on their line all end at one x; one after
    // another on its line ends there too when there is room, and otherwise
    // right of it.
    let ends = (:)
    for level in labels.map(l => l.level).dedup().sorted() {
      let firsts = labels.filter(l => l.level == level and before(l) == ()).map(l => l.end.x)
      assert(firsts.len() > 0, message: "case " + str(i + 1) + ": no label of level " + str(level) + " first on its line")
      for x in firsts {
        assert(close(x, firsts.first()), message: "case " + str(i + 1) + ", level " + str(level) + ": " + repr(firsts))
      }
      for l in labels.filter(l => l.level == level and before(l) != ()) {
        if room {
          assert(close(l.end.x, firsts.first()), message: "case " + str(i + 1) + ": " + repr((l.level, l.n)) + " moved")
        } else {
          assert(l.end.x > firsts.first(), message: "case " + str(i + 1) + ": " + repr((l.level, l.n)) + " did not move")
        }
      }
      ends.insert(str(level), firsts.first())
    }
    // Each text starts `LABEL_GAP` after its label, or farther where the
    // label moved: never on it.
    for t in query(<text-start>).filter(m => m.value.case == i) {
      let tp = t.location().position()
      let ls = labels.filter(l => l.level == t.value.level and l.n == t.value.n)
      if ls == () { continue }
      let l = ls.find(l => same_line(l.end, tp))
      assert(l != none, message: "case " + str(i + 1) + ": the text of " + repr((t.value.level, t.value.n)) + " is not on its label's line")
      assert(tp.x - l.end.x >= gap - .01pt, message: "case " + str(i + 1) + ": the text of " + repr((l.level, l.n)) + " starts on its label")
      if before(l) == () {
        assert(close(tp.x - l.end.x, gap), message: "case " + str(i + 1) + ": the text of " + repr((l.level, l.n)) + " moved")
      }
    }
    // The lines after the first of a paragraph whose label moved start
    // under the first label of its line, or at the text's edge if that is
    // in the margin; those of any other, at its text.
    for w in query(<wrap-start>).filter(m => m.value.case == i) {
      let wp = w.location().position()
      let l = labels.find(l => l.level == w.value.level and l.n == w.value.n)
      let t = query(<text-start>).find(m => m.value == w.value).location().position()
      let moved = before(l) != () and not room
      let expected = if moved { calc.max(EDGE, calc.min(..before(l).map(o => o.start.x))) } else { t.x }
      assert(close(wp.x, expected), message: "case " + str(i + 1) + ": the second line of " + repr((l.level, l.n)) + " starts at " + repr(wp.x) + ", not " + repr(expected))
    }
    // A points badge on a label's line, in the margin or in the text, is
    // clear of it.
    let edges = query(<badge-edge>).filter(m => m.value.case == i).map(m => m.location().position())
    for (a, b) in edges.chunks(2).map(((a, b)) => (a, b)) {
      for l in labels.filter(l => same_line(l.end, a)) {
        assert(b.x <= l.start.x + .01pt or a.x >= l.end.x - .01pt, message: "case " + str(i + 1) + ": a badge is drawn on " + repr((l.level, l.n)))
      }
    }
    // A badge at the "end" is on the last line of the text it follows.
    for t in query(<text-end>).filter(m => m.value.case == i) {
      let tp = t.location().position()
      assert(edges.len() > 0 and same_line(edges.first(), tp), message: "case " + str(i + 1) + ": the badge is not on the line its text ends on")
    }
    // A box that a moved label would be drawn on starts below its labels.
    for b in query(<box-top>).filter(m => m.value.case == i) {
      let top = b.location().position()
      let line = labels.filter(l => l.end.page == top.page and l.level == 2 and before(l) != ())
      assert(line.len() > 0 and line.all(l => l.end.y < top.y), message: "case " + str(i + 1) + ": the box starts beside its labels")
      // The badges in the margin are on their line, not the box's.
      assert(edges.all(e => same_line(e, line.first().end)), message: "case " + str(i + 1) + ": a badge is not on its labels' line")
    }
    // The badges in the margin of a line whose text is unnumbered are on it.
    for t in query(<badge-line>).filter(m => m.value.case == i) {
      let tp = t.location().position()
      assert(edges.len() > 0 and edges.all(e => same_line(e, tp)), message: "case " + str(i + 1) + ": a badge is not on its text's line")
    }
    // The labels of a line taller than usual are on its baseline, all of
    // them: the first "1." and "(a)".
    for b in query(<baseline>).filter(m => m.value.case == i) {
      let y = b.location().position().y
      for (level, n) in ((1, 1), (2, 1)) {
        let l = labels.find(l => l.level == level and l.n == n)
        assert(calc.abs((l.start.y - y) / 1pt) < .5, message: "case " + str(i + 1) + ": " + repr((level, n)) + " is at " + repr(l.start.y) + ", the line's baseline at " + repr(y))
      }
    }
    // The text after a solution in a first paragraph not hung starts a line
    // of its own at the part's text.
    for t in query(<after-solution>).filter(m => m.value.case == i) {
      let x = t.location().position().x
      assert(close(x, EDGE + 1.5em.to-absolute()), message: "case " + str(i + 1) + ": the text after the solution starts at " + repr(x))
    }
    rows.push((
      [#(i + 1). #desc],
      if gaps == () [none] else [#calc.round(calc.min(..gaps) / 1pt, digits: 2)pt],
      ends.pairs().map(((l, x)) => [level #l at #calc.round(x / 1pt, digits: 1)pt]).join([, ]),
    ))
  }
  // Content in the first paragraph of a part whose label moved is all drawn,
  // blocks in it too: the two probes of case 11, one in a block a `context`
  // makes and one in a list item.
  let kept = query(<kept>).len()
  assert(kept == 2, message: "case 11: " + str(2 - kept) + " of the blocks after the part's first line not drawn")
  // The badges in the left margin do not clear a label wider than the
  // margin, but stay in line, on the page.
  let i = CASES.position(c => c.first() == WIDE)
  let badges = query(<badge-edge>).filter(m => m.value.case == i).map(m => m.location().position()).chunks(2)
  assert(badges.len() == 3 and badges.all(((a, _)) => a.x >= 0pt), message: "case " + str(i + 1) + ": " + repr(badges))
  assert(badges.all(((_, b)) => close(b.x, badges.first().last().x)), message: "case " + str(i + 1) + ": " + repr(badges))
  // The labels above a table go to its page.
  let top = query(<table-top>).first().location().position()
  let labels = query(<label-edge>).filter(m => m.value.case == "kept").map(m => m.location().position())
  assert(labels.len() == 4 and labels.all(l => l.page == top.page and l.y < top.y), message: repr((labels, top)))
  // Over pages whose left margins differ, each badge clears the label beside
  // it on the page whose margin is wide (on the left, the inside of an odd
  // page), and stays on the narrow one.
  let badges = query(<badge-edge>).filter(m => m.value.case == "pages").map(m => m.location().position()).chunks(2)
  let starts = query(<label-edge>).filter(m => m.value.case == "pages" and m.value.edge == "start").map(m => m.location().position())
  assert(badges.len() == 2 and badges.first().first().page != badges.last().first().page, message: repr(badges))
  for (a, b) in badges {
    assert(a.x >= 0pt, message: "pages: a badge off page " + str(a.page) + ": " + repr(a))
    if calc.odd(a.page) {
      let l = starts.find(l => l.page == a.page)
      assert(b.x <= l.x + .01pt, message: "pages: the badge on page " + str(a.page) + " is drawn on its label")
    }
  }
  rule[The labels measured: the least gap between two on a line (at least #LABEL_SEP, #calc.round(sep / 1pt, digits: 2)pt), and where the labels of each level first on their line end]
  cases(([Case], [Least gap], [Where each level ends]), ..rows)
}

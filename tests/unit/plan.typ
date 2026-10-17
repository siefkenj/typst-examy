// Phase D (src/plan.typ): how each question is laid out. One with no page
// break and no fr height is drawn as nested blocks ("nested"); one with
// either is split into peer segments ("segment"), with breaks between them,
// and an fr chunk hoisted into a segment of its own.
//
// Each case is written as markup source, evaluated for the check, so that
// the visual record beside it can show it as written, drawn as an exam
// where it can be, and the instructions the planner made of it.
#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/plan.typ": cumulative_indent, needs_split, plan
#import "/src/points.typ": assign_badges
#import "/src/divisions.typ": part, question, subpart
#import "/src/lib.typ": e
#import "/tests/record.typ": cases, pair, preview, rule

#set page(width: 6.5in, height: auto, margin: .5in)
#show: e.prepare()

#let SCOPE = (question: question, part: part, subpart: subpart)

#let pipeline(src) = {
  let items = assign_badges(parse(tokenize(eval(src, mode: "markup", scope: SCOPE))))
  (items, plan(items))
}
#let shape(instructions) = instructions.map(i => i.kind)

/// What an instruction carries, for the record.
#let detail(items, i) = {
  let name(d) = ("question", "part", "subpart").at(items.at(d).level - 1, default: "division")
  let parts = if i.kind == "segment" {
    (name(i.division) + if i.first { ", first" } else { ", continued" },)
    if i.label_divisions.len() > 0 { ("labels: " + i.label_divisions.map(name).join(" + "),) }
    if i.fr != none { ("fr: " + repr(i.fr),) }
    if i.hoisted { ("hoisted",) }
    if i.sticky { ("sticky",) }
    if i.has_inner_break { ("has_inner_break",) }
  } else if i.kind == "break" {
    (i.target + if i.weak { ", weak" } else { "" },)
  } else if i.kind == "nested" {
    (name(i.root),)
  } else { () }
  raw(parts.join(", ", default: ""))
}

/// Plan `src`, run `check` on the items and the instructions, and draw the
/// case: the source and the exam it draws (when it has no break, which
/// cannot be drawn in a frame), beside the instructions.
#let case(desc, src, check) = {
  let (items, instr) = pipeline(src)
  check(items, instr)
  rule(desc)
  pair(
    {
      raw(src, lang: "typ", block: true)
      if not src.contains("break(") { preview(eval(src, mode: "markup", scope: SCOPE)) }
    },
    cases(([Instruction], [Carries]), ..instr.map(i => (raw(i.kind), detail(items, i)))),
  )
}

#case([No break anywhere: nested blocks, and top-level prose kept as it is.], "intro prose\n#question[\n  a question\n  #part[with a part]\n]", (items, instr) => {
  assert(shape(instr).contains("nested"), message: repr(shape(instr)))
  assert(not shape(instr).contains("segment"))
  assert(shape(instr).at(0) == "verbatim")
})

#case([A page break splits that question only.], "#question[q1 #pagebreak() q1 continued]\n#question[q2, no breaks]", (items, instr) => {
  assert(shape(instr).contains("segment"))
  assert(shape(instr).contains("break"))
  assert(shape(instr).contains("nested"))
})

#case(
  [An fr height splits the question too, and is hoisted to a peer of its own: the prose keeps the label and is glued to it.],
  "#question[fill the page #v(1fr)]",
  (items, instr) => {
    assert(shape(instr) == ("segment", "segment"), message: repr(shape(instr)))
    let (prose, fill) = (instr.at(0), instr.at(1))
    assert(prose.fr == none and prose.hoisted == false)
    assert(prose.sticky == true)
    assert(prose.label_divisions.len() == 1)
    // The fr peer carries the height alone, so it negotiates against the
    // page rather than against whatever the prose left over.
    assert(fill.fr == 1fr and fill.hoisted == true, message: repr(fill))
    assert(fill.sticky == false)
    assert(fill.items.len() == 1)
  },
)

#case([An explicitly sized box needs no negotiation: no split at all.], "#question[prompt #block(height: 2in)[]]", (items, instr) => {
  assert(shape(instr) == ("nested",), message: repr(shape(instr)))
})

#case([Content after the fr box becomes a further peer.], "#question[before #v(1fr) after]", (items, instr) => {
  assert(shape(instr) == ("segment", "segment", "segment"), message: repr(shape(instr)))
  assert(instr.map(s => s.hoisted) == (false, true, false))
  // Only the segment feeding the fr peer is sticky.
  assert(instr.map(s => s.sticky) == (true, false, false))
})

#case(
  [A body that is only an fr box: the label rides the hoisted segment, as there is no prose to hold it.],
  "#question[#v(1fr)]",
  (items, instr) => {
    assert(shape(instr) == ("segment",), message: repr(shape(instr)))
    assert(instr.at(0).hoisted == true)
    assert(instr.at(0).label_divisions.len() == 1, message: repr(instr.at(0)))
  },
)

#case(
  [... but a points badge takes a line, so it is kept out of the hoisted segment, where it would be paid for out of the box's share.],
  "#question(points: 2)[#v(1fr)]",
  (items, instr) => {
    assert(shape(instr) == ("segment", "segment"), message: repr(shape(instr)))
    let (head, fill) = (instr.at(0), instr.at(1))
    assert(head.label_divisions.len() == 1 and head.sticky == true, message: repr(head))
    assert(head.fr == none and head.hoisted == false)
    assert(fill.hoisted == true and fill.label_divisions.len() == 0)
  },
)

#case([Sibling questions each get an fr peer of their own.], "#question[short #v(1fr)]\n#question[a much longer prompt #v(1fr)]", (items, instr) => {
  let frs = instr.filter(i => i.kind == "segment" and i.hoisted)
  assert(frs.len() == 2, message: repr(shape(instr)))
  assert(frs.all(s => s.fr == 1fr))
})

#case([A chunk with a break inside keeps its auto height, so it is not hoisted.], "#question[p #block(height: 1fr)[x #colbreak() y]]", (items, instr) => {
  let segs = instr.filter(i => i.kind == "segment")
  assert(segs.all(s => not s.hoisted), message: repr(segs.map(s => s.hoisted)))
})

#case([Segments around a break: the label on the first only.], "#question[before #pagebreak() after]", (items, instr) => {
  assert(shape(instr) == ("segment", "break", "segment"), message: repr(shape(instr)))
  let (s1, brk, s2) = (instr.at(0), instr.at(1), instr.at(2))
  assert(s1.first == true)
  assert(s1.label_divisions.len() == 1)
  assert(brk.target == "page")
  assert(s2.first == false)
  assert(s2.label_divisions.len() == 0)
})

#case(
  [A break inside a subpart: the continuation belongs to the subpart, at its cumulative indent.],
  "#question[\n  q intro\n  #part[\n    p intro\n    #subpart[deep #pagebreak() continued]\n  ]\n]",
  (items, instr) => {
    let brk_pos = instr.position(i => i.kind == "break")
    let cont = instr.at(brk_pos + 1)
    assert(cont.kind == "segment" and cont.first == false)
    let sp = items.position(it => it.kind == "division" and it.level == 3)
    assert(cont.division == sp)
    assert(cont.indent == cumulative_indent(items, sp))
    assert(cumulative_indent(items, sp) == 4.5em, message: repr(cumulative_indent(items, sp)))
  },
)

#case(
  [A question starting with a part shares its first line: both labels ride the part's first segment.],
  "#question[\n  #part[body #pagebreak() more]\n]",
  (items, instr) => {
    let first_seg = instr.find(i => i.kind == "segment")
    assert(first_seg.label_divisions.len() == 2, message: repr(first_seg.label_divisions))
  },
)

#case([Consecutive breaks.], "#question[a #pagebreak() #pagebreak() b]", (items, instr) => {
  assert(shape(instr) == ("segment", "break", "break", "segment"), message: repr(shape(instr)))
})

#case(
  [A continuation of only whitespace is dropped: after the part, the question makes no segment.],
  "#question[\n  #part[content #pagebreak() tail]\n]",
  (items, instr) => {
    let last = instr.at(-1)
    assert(last.kind == "segment")
    assert(last.division == items.position(it => it.kind == "division" and it.level == 2))
  },
)

#case(
  [An empty trailing part still gets a segment, so its label shows (ISSUES regression #1, split).],
  "#question[\n  some text with a fill #v(1fr)\n  #part[]\n]",
  (items, instr) => {
    let segs = instr.filter(i => i.kind == "segment")
    let p = items.position(it => it.kind == "division" and it.level == 2)
    assert(segs.find(s => s.label_divisions.contains(p)) != none, message: repr(segs))
  },
)

#case([A chunk with a break inside is flagged.], "#question[#block[x #colbreak() y]]", (items, instr) => {
  let seg = instr.find(i => i.kind == "segment")
  assert(seg.has_inner_break == true)
})

// --- cumulative indent sums ancestors; needs_split ---
#let INDENTS = {
  let (items, _) = pipeline("#question[#part[#subpart[x]]]")
  let at(level) = items.position(it => it.kind == "division" and it.level == level)
  (1, 2, 3).map(level => (level, cumulative_indent(items, at(level))))
}
#assert(INDENTS.map(x => x.last()) == (1.5em, 3em, 4.5em), message: repr(INDENTS))

#let SPLITS = (
  ("#question[plain]", false),
  ("#question[#v(1fr)]", true),
  ("#question[#part[#pagebreak()]]", true),
)
#for (src, expected) in SPLITS {
  let (items, _) = pipeline(src)
  assert(needs_split(items, 0) == expected, message: src)
}

#rule[`cumulative_indent`: each level's indent added to its ancestors'.]
#cases(([Level], [Cumulative indent]), ..INDENTS.map(((level, indent)) => ([#level], raw(repr(indent)))))
#rule[`needs_split`: whether a question must be split into segments.]
#cases(
  ([Source], [Needs split]),
  ..SPLITS.map(((src, expected)) => (raw(src, lang: "typ"), raw(repr(needs_split(pipeline(src).first(), 0))))),
)

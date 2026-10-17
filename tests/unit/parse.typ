// Phase C (src/parse.typ): the token stream parsed into a tree of items,
// with every division's level, number, address, and point totals resolved.
//
// Each case is written as markup source, evaluated for the check, so that
// the visual record beside it can show it as written, drawn as an exam, and
// the divisions the parser made of it.
#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/divisions.typ": part, question, subpart
#import "/src/lib.typ": e
#import "/tests/record.typ": cases, pair, preview, rule

#set page(width: 6.5in, height: auto, margin: .5in)
#show: e.prepare()

#let SCOPE = (question: question, part: part, subpart: subpart)

#let divisions(items) = items.filter(it => it.kind == "division")

/// Parse `src`, run `check` on the items, and draw the case: the source and
/// the exam it draws (unless `draw` is false, for source an exam cannot be
/// drawn from in a frame, such as a page break), beside the divisions.
#let case(desc, src, check, draw: true) = {
  let body = eval(src, mode: "markup", scope: SCOPE)
  let items = parse(tokenize(body))
  check(items)
  rule(desc)
  pair(
    {
      raw(src, lang: "typ", block: true)
      if draw { preview(body) }
    },
    cases(
      ([Level], [Number], [Address], [Points], [Total], [Bonus]),
      ..divisions(items).map(d => (
        [#d.level],
        raw(repr(d.number)),
        raw(repr(d.address)),
        raw(repr(d.fields.points)),
        [#d.total_points],
        raw(repr(d.total_bonus_points)),
      )),
    ),
  )
}

#case([A single question.], "#question[body]", items => {
  let divs = divisions(items)
  assert(divs.len() == 1)
  assert(divs.at(0).level == 1)
  assert(divs.at(0).number == 0)
  assert(divs.at(0).address == (0,))
  assert(divs.at(0).parent == none)
})

#case(
  [Levels come from nesting depth, not constructor names.],
  "#question[\n  q body\n  #part[\n    p body\n    #subpart[sp body]\n  ]\n]",
  items => {
    let divs = divisions(items)
    assert(divs.map(d => d.level) == (1, 2, 3), message: repr(divs.map(d => d.level)))
    assert(divs.at(2).address == (0, 0, 0))
  },
)

#case(
  [Automatic numbering, reset in each question.],
  "#question[\n  #part[a]\n  #part[b]\n]\n#question[\n  #part[c]\n]",
  items => {
    let divs = divisions(items)
    let got = divs.map(d => (d.level, d.number))
    assert(got == ((1, 0), (2, 0), (2, 1), (1, 1), (2, 0)), message: repr(got))
    assert(divs.map(d => d.address) == ((0,), (0, 0), (0, 1), (1,), (1, 0)))
  },
)

#case(
  [An explicit number is the one displayed (1-based); later ones continue from it.],
  "#question[a]\n#question(number: 5)[b]\n#question[c]",
  items => {
    let nums = divisions(items).map(d => d.number)
    assert(nums == (0, 4, 5), message: repr(nums))
  },
)

#case(
  [Content as the number is shown verbatim; the counter is untouched.],
  "#question[a]\n#question(number: \"XX\")[b]\n#question[c]",
  items => {
    let nums = divisions(items).map(d => d.number)
    assert(nums.at(0) == 0)
    assert(nums.at(1) == "XX")
    assert(nums.at(2) == 1, message: repr(nums))
  },
)

#case(
  [`number: none` is unnumbered; the counter is untouched.],
  "#question[a]\n#question(number: none)[b]\n#question[c]",
  items => {
    let nums = divisions(items).map(d => d.number)
    assert(nums == (0, none, 1), message: repr(nums))
  },
)

#case([Children link chunks and parts to their question.], "#question[intro #part[p] outro]", items => {
  let q = items.at(0)
  assert(q.kind == "division")
  let child_kinds = q.children.map(i => items.at(i).kind)
  assert(child_kinds.contains("division"))
  assert(child_kinds.contains("chunk"))
  let p = items.find(it => it.kind == "division" and it.level == 2)
  assert(p.parent == 0)
})

#case(
  [Points roll up to the question.],
  "#question(points: 1)[\n  #part(points: 2)[a]\n  #part(points: 4)[\n    #subpart(points: 1)[s]\n  ]\n]\n#question[b]\n#question(points: 3)[c]",
  items => {
    let qs = divisions(items).filter(d => d.level == 1)
    assert(qs.map(q => q.total_points) == (8, 0, 3), message: repr(qs.map(q => q.total_points)))
  },
)

#case(
  [Bonus and practice points are left out of the regular total; bonus is totalled apart.],
  "#question(points: 2)[\n  #part(points: 3, intent: \"bonus\")[b]\n  #part(points: 5, intent: \"practice\")[p]\n  #part(points: 1)[r]\n]",
  items => {
    let q = divisions(items).at(0)
    assert(q.total_points == 3, message: repr(q.total_points))
    assert(q.total_bonus_points == 3)
  },
)
#case([With no bonus points, the bonus total is none.], "#question(points: 2)[plain]", items => {
  assert(divisions(items).at(0).total_bonus_points == none)
})

#case([An empty part is still a real division (ISSUES regression #1).], "#question[#part[]]", items => {
  let divs = divisions(items)
  assert(divs.len() == 2)
  assert(divs.at(1).level == 2)
  assert(divs.at(1).number == 0)
})

#case(
  [A part after a markup enum is found (ISSUES regression #2).],
  "#question[\n  hi\n  + list\n  + list 2\n\n  #part[foo]\n]",
  items => {
    let divs = divisions(items)
    assert(divs.len() == 2, message: repr(divs.len()))
    assert(divs.at(1).level == 2)
  },
)

#case(
  [A break, and the prose around a question, keep their parent links.],
  "prose before\n#question[a #pagebreak() b]\nprose after",
  items => {
    let brk = items.find(it => it.kind == "break")
    assert(brk.parent == items.position(it => it.kind == "division"))
    let top_chunks = items.filter(it => it.kind == "chunk" and it.parent == none)
    assert(top_chunks.len() > 0)
  },
  // A page break cannot be drawn inside the frame.
  draw: false,
)

#case([A label is recorded, and the other fields kept.], "#question(points: 3, label: <q1>)[x]", items => {
  let q = divisions(items).at(0)
  assert(q.fields.label == <q1>)
  assert(q.fields.points == 3)
})

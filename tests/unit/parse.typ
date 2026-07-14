#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/divisions.typ": part, question, subpart

#let divisions(items) = items.filter(it => it.kind == "division")

// --- single question ---
#{
  let items = parse(tokenize(question[body]))
  let divs = divisions(items)
  assert(divs.len() == 1)
  assert(divs.at(0).level == 1)
  assert(divs.at(0).number == 0)
  assert(divs.at(0).address == (0,))
  assert(divs.at(0).parent == none)
}

// --- levels come from nesting depth, not constructor names ---
#{
  let items = parse(tokenize(question[
    q body
    #part[
      p body
      #subpart[sp body]
    ]
  ]))
  let divs = divisions(items)
  assert(divs.map(d => d.level) == (1, 2, 3), message: repr(divs.map(d => d.level)))
  assert(divs.at(2).address == (0, 0, 0))
}

// --- auto numbering with resets ---
#{
  let items = parse(tokenize([
    #question[
      #part[a]
      #part[b]
    ]
    #question[
      #part[c]
    ]
  ]))
  let divs = divisions(items)
  // (level, number) sequence
  let got = divs.map(d => (d.level, d.number))
  assert(
    got == ((1, 0), (2, 0), (2, 1), (1, 1), (2, 0)),
    message: repr(got),
  )
  // addresses
  assert(divs.map(d => d.address) == ((0,), (0, 0), (0, 1), (1,), (1, 0)))
}

// --- explicit int numbering is the displayed (1-based) number, and later
//     divisions continue from it ---
#{
  let items = parse(tokenize([
    #question[a]
    #question(number: 5)[b] // displays "5."
    #question[c] // displays "6."
  ]))
  let nums = divisions(items).map(d => d.number)
  assert(nums == (0, 4, 5), message: repr(nums))
}

// --- content numbering is verbatim; counters untouched ---
#{
  let items = parse(tokenize([
    #question[a]
    #question(number: "XX")[b]
    #question[c]
  ]))
  let nums = divisions(items).map(d => d.number)
  assert(nums.at(0) == 0)
  assert(nums.at(1) == "XX")
  assert(nums.at(2) == 1, message: repr(nums))
}

// --- number: none is unnumbered; counters untouched ---
#{
  let items = parse(tokenize([
    #question[a]
    #question(number: none)[b]
    #question[c]
  ]))
  let nums = divisions(items).map(d => d.number)
  assert(nums == (0, none, 1), message: repr(nums))
}

// --- children links ---
#{
  let items = parse(tokenize(question[intro #part[p] outro]))
  let q = items.at(0)
  assert(q.kind == "division")
  // the question's children include chunks and the part
  let child_kinds = q.children.map(i => items.at(i).kind)
  assert(child_kinds.contains("division"))
  assert(child_kinds.contains("chunk"))
  // the part's parent is the question
  let p = items.find(it => it.kind == "division" and it.level == 2)
  assert(p.parent == 0)
}

// --- points rollup ---
#{
  let items = parse(tokenize([
    #question(points: 1)[
      #part(points: 2)[a]
      #part(points: 4)[
        #subpart(points: 1)[s]
      ]
    ]
    #question[b]
    #question(points: 3)[c]
  ]))
  let qs = divisions(items).filter(d => d.level == 1)
  assert(qs.map(q => q.total_points) == (8, 0, 3), message: repr(qs.map(q => q.total_points)))
}

// --- bonus and practice points are excluded from regular totals ---
#{
  let items = parse(tokenize([
    #question(points: 2)[
      #part(points: 3, intent: "bonus")[b]
      #part(points: 5, intent: "practice")[p]
      #part(points: 1)[r]
    ]
  ]))
  let q = divisions(items).at(0)
  assert(q.total_points == 3, message: repr(q.total_points))
  assert(q.total_bonus_points == 3)
}
#{
  let items = parse(tokenize(question(points: 2)[plain]))
  assert(divisions(items).at(0).total_bonus_points == none)
}

// --- empty part is still a real division (ISSUES regression #1) ---
#{
  let items = parse(tokenize(question[#part[]]))
  let divs = divisions(items)
  assert(divs.len() == 2)
  assert(divs.at(1).level == 2)
  assert(divs.at(1).number == 0)
}

// --- part after a markup enum (ISSUES regression #2) ---
#{
  let items = parse(tokenize(question[
    hi
    + list
    + list 2

    #part[foo]
  ]))
  let divs = divisions(items)
  assert(divs.len() == 2, message: repr(divs.len()))
  assert(divs.at(1).level == 2)
}

// --- breaks and top-level chunks keep their parent link ---
#{
  let items = parse(tokenize([
    prose before
    #question[a #pagebreak() b]
    prose after
  ]))
  let brk = items.find(it => it.kind == "break")
  assert(brk.parent == items.position(it => it.kind == "division"))
  let top_chunks = items.filter(it => it.kind == "chunk" and it.parent == none)
  assert(top_chunks.len() > 0)
}

// --- labels recorded; fields preserved ---
#{
  let items = parse(tokenize(question(points: 3, label: <q1>)[x]))
  let q = divisions(items).at(0)
  assert(q.fields.label == <q1>)
  assert(q.fields.points == 3)
}

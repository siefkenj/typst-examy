#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/plan.typ": cumulative_indent, needs_split, plan
#import "/src/divisions.typ": part, question, subpart

#let pipeline(c) = {
  let items = parse(tokenize(c))
  (items, plan(items))
}
#let shape(instructions) = instructions.map(i => i.kind)

// --- no breaks anywhere: nested mode ---
#{
  let (items, instr) = pipeline([
    intro prose
    #question[
      a question
      #part[with a part]
    ]
  ])
  assert(shape(instr).contains("nested"), message: repr(shape(instr)))
  assert(not shape(instr).contains("segment"))
  // top-level prose is verbatim
  assert(shape(instr).at(0) == "verbatim")
}

// --- a pagebreak forces split mode for that question only ---
#{
  let (items, instr) = pipeline([
    #question[q1 #pagebreak() q1 continued]
    #question[q2, no breaks]
  ])
  assert(shape(instr).contains("segment"))
  assert(shape(instr).contains("break"))
  assert(shape(instr).contains("nested")) // q2 stays nested
}

// --- fr heights force split mode ---
#{
  let (items, instr) = pipeline(question[fill the page #v(1fr)])
  assert(shape(instr) == ("segment",), message: repr(shape(instr)))
  assert(instr.at(0).fr == 1fr)
}

// --- segments around a break: label only on the first ---
#{
  let (items, instr) = pipeline(question[before #pagebreak() after])
  assert(shape(instr) == ("segment", "break", "segment"), message: repr(shape(instr)))
  let (s1, brk, s2) = (instr.at(0), instr.at(1), instr.at(2))
  assert(s1.first == true)
  assert(s1.label_divisions.len() == 1)
  assert(brk.target == "page")
  assert(s2.first == false)
  assert(s2.label_divisions.len() == 0)
}

// --- break inside a subpart: continuation carries cumulative indent ---
#{
  let (items, instr) = pipeline(question[
    q intro
    #part[
      p intro
      #subpart[deep #pagebreak() continued]
    ]
  ])
  let segs = instr.filter(i => i.kind == "segment")
  // the continuation after the break belongs to the subpart
  let brk_pos = instr.position(i => i.kind == "break")
  let cont = instr.at(brk_pos + 1)
  assert(cont.kind == "segment" and cont.first == false)
  let sp = items.position(it => it.kind == "division" and it.level == 3)
  assert(cont.division == sp)
  assert(cont.indent == cumulative_indent(items, sp))
  assert(cumulative_indent(items, sp) == 4.5em, message: repr(cumulative_indent(items, sp)))
}

// --- a division starting directly with a child shares the first line:
//     its label rides on the child's first segment ---
#{
  let (items, instr) = pipeline(question[
    #part[body #pagebreak() more]
  ])
  let first_seg = instr.find(i => i.kind == "segment")
  // both the question's and the part's label are on the first segment
  assert(first_seg.label_divisions.len() == 2, message: repr(first_seg.label_divisions))
}

// --- consecutive breaks ---
#{
  let (items, instr) = pipeline(question[a #pagebreak() #pagebreak() b])
  let sh = shape(instr)
  assert(sh == ("segment", "break", "break", "segment"), message: repr(sh))
}

// --- whitespace-only continuations are dropped ---
#{
  let (items, instr) = pipeline(question[
    #part[content #pagebreak() tail]
  ])
  // after the part closes, the question's trailing whitespace continuation
  // must not produce a segment
  let last = instr.at(-1)
  assert(last.kind == "segment")
  assert(last.division == items.position(it => it.kind == "division" and it.level == 2))
}

// --- empty trailing part still gets a segment so its label shows
//     (ISSUES regression #1, split mode) ---
#{
  let (items, instr) = pipeline(question[
    some text with a fill #v(1fr)
    #part[]
  ])
  let segs = instr.filter(i => i.kind == "segment")
  let p = items.position(it => it.kind == "division" and it.level == 2)
  let p_seg = segs.find(s => s.label_divisions.contains(p))
  assert(p_seg != none, message: repr(segs))
}

// --- chunk with an inner break keeps auto height (flagged) ---
#{
  let (items, instr) = pipeline(question[#block[x #colbreak() y]])
  let seg = instr.find(i => i.kind == "segment")
  assert(seg.has_inner_break == true)
}

// --- solution tail is attached to the division's last segment ---
#{
  let (items, instr) = pipeline(
    question(solution: [the answer], points: 2)[q #pagebreak() end],
  )
  let segs = instr.filter(i => i.kind == "segment")
  let q = items.position(it => it.kind == "division")
  assert(segs.at(-1).tail == q, message: repr(segs.map(s => s.tail)))
  assert(segs.at(0).tail == none)
}

// --- cumulative indent sums ancestors ---
#{
  let (items, _) = pipeline(question[#part[#subpart[x]]])
  let q = 0
  let p = items.position(it => it.kind == "division" and it.level == 2)
  let sp = items.position(it => it.kind == "division" and it.level == 3)
  assert(cumulative_indent(items, q) == 1.5em)
  assert(cumulative_indent(items, p) == 3em)
  assert(cumulative_indent(items, sp) == 4.5em)
}

// --- needs_split ---
#{
  let (items, _) = pipeline(question[plain])
  assert(not needs_split(items, 0))
}
#{
  let (items, _) = pipeline(question[#v(1fr)])
  assert(needs_split(items, 0))
}
#{
  let (items, _) = pipeline(question[#part[#pagebreak()]])
  assert(needs_split(items, 0))
}

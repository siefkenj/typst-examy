#import "/src/tokenize.typ": apply_styles, tokenize
#import "/src/divisions.typ": part, question, subpart
#import "/src/markers.typ": height_hint

#let kinds(tokens) = tokens.map(t => t.kind)

/// Token kinds with runs of consecutive "chunk"s collapsed to one.
#let shape(tokens) = {
  let ret = ()
  for k in kinds(tokens) {
    if k == "chunk" and ret.at(-1, default: none) == "chunk" { continue }
    ret.push(k)
  }
  ret
}

// --- plain content stays opaque ---
#{
  let toks = tokenize([just some text])
  assert(kinds(toks) == ("chunk",), message: repr(kinds(toks)))
}

// Nested sequences without structure stay as ONE chunk (never destructured)
#{
  let toks = tokenize([hi #[there #[nested]]])
  assert(toks.len() == 1, message: repr(kinds(toks)))
  assert(toks.at(0).kind == "chunk")
}

// --- a simple question ---
#{
  let toks = tokenize(question[body text])
  assert(kinds(toks) == ("begin", "chunk", "end"), message: repr(kinds(toks)))
  assert(toks.at(0).fields.name == "question")
}

// --- nested divisions unwrap positionally ---
#{
  let toks = tokenize(question[intro #part[part body] outro])
  assert(
    shape(toks)
      == (
        "begin", // question
        "chunk", // "intro "
        "begin", // part
        "chunk", // "part body"
        "end",
        "chunk", // " outro"
        "end",
      ),
    message: repr(kinds(toks)),
  )
}

// --- multiple questions side by side ---
#{
  let toks = tokenize([#question[a] #question[b]])
  assert(kinds(toks).filter(k => k == "begin").len() == 2)
  assert(kinds(toks).filter(k => k == "end").len() == 2)
}

// --- breaks become break tokens ---
#{
  let toks = tokenize(question[before #pagebreak() after])
  assert(shape(toks) == ("begin", "chunk", "break", "chunk", "end"), message: repr(kinds(toks)))
  let brk = toks.find(t => t.kind == "break")
  assert(brk.target == "page")
  assert(brk.weak == false)
}
#{
  let toks = tokenize(question[a #colbreak() b])
  assert(toks.find(t => t.kind == "break").target == "col")
}
#{
  let toks = tokenize(question[a #pagebreak(weak: true) b])
  assert(toks.find(t => t.kind == "break").weak == true)
}

// --- content WITHOUT structure containing a pagebreak deep inside a block
//     stays an opaque chunk, flagged has_inner_break ---
#{
  let toks = tokenize([#block[x #colbreak() y]])
  assert(kinds(toks) == ("chunk",))
  assert(toks.at(0).has_inner_break == true)
}

// --- fr heights are recorded on chunks ---
#{
  let toks = tokenize(question[text #v(1fr)])
  let frs = toks.filter(t => t.kind == "chunk").map(t => t.fr).filter(f => f != none)
  assert(frs == (1fr,), message: repr(frs))
}
#{
  let toks = tokenize(question[#height_hint(2fr) box-stand-in])
  let frs = toks.filter(t => t.kind == "chunk").map(t => t.fr).filter(f => f != none)
  assert(frs == (2fr,), message: repr(frs))
}

// --- enum items stay opaque; a part AFTER a markup enum is still found
//     (ISSUES regression #2) ---
#{
  let toks = tokenize(question[
    hi
    + list
    + list 2

    #part[foo]
  ])
  let begins = toks.filter(t => t.kind == "begin")
  assert(begins.len() == 2, message: repr(kinds(toks)))
  assert(begins.at(1).fields.name == "part")
}

// --- empty part produces adjacent begin/end (ISSUES regression #1) ---
#{
  let toks = tokenize(question[#part[]])
  let names = toks.filter(t => t.kind == "begin").map(t => t.fields.name)
  assert(names == ("question", "part"), message: repr(names))
}

// --- styled wrappers are unwrapped with styles recorded ---
#{
  let toks = tokenize({
    set text(fill: red)
    question[hello]
  })
  assert(kinds(toks) == ("begin", "chunk", "end"), message: repr(kinds(toks)))
  assert(toks.at(0).styles.len() == 1)
  assert(toks.at(1).styles.len() == 1)
}

// styled content with NO markers inside stays opaque
#{
  let toks = tokenize([a #text(fill: red)[red] b])
  assert(toks.len() == 1, message: repr(kinds(toks)))
}

// apply_styles round-trips
#{
  let styled = {
    set text(fill: red)
    [hello]
  }
  let toks = tokenize({
    set text(fill: red)
    question[hello]
  })
  let rebuilt = apply_styles(toks.at(1).body, toks.at(1).styles)
  assert(type(rebuilt) == content)
}

// --- a marker buried inside an opaque container panics with a diagnostic ---
// (Cannot assert a panic directly in typst; this is verified manually and by
// the fact that the message construction is exercised in dev. Skipped here.)

// --- division fields travel on the begin token ---
#{
  let toks = tokenize(question(points: 3, label: <q1>)[body])
  let f = toks.at(0).fields
  assert(f.points == 3)
  assert(f.label == <q1>)
  assert(f.number == auto)
}

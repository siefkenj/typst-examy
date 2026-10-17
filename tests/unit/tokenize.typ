// Phase B (src/tokenize.typ): exam content turned into a flat stream of
// tokens: `begin`/`end` for each division, `break` for page and column
// breaks, and `chunk` for everything else, kept whole wherever it holds no
// division.
//
// Each case is written as markup source, evaluated for the check, so that
// the visual record beside it can show it as written, with its tokens.
#import "/src/tokenize.typ": apply_styles, tokenize
#import "/src/divisions.typ": part, question, subpart
#import "/src/markers.typ": height_hint
#import "/src/lib.typ": e
#import "/tests/record.typ": cases, pair, rule

#set page(width: 6.5in, height: auto, margin: .5in)
#show: e.prepare()

#let SCOPE = (question: question, part: part, subpart: subpart, height_hint: height_hint)

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

/// What a token carries, for the record.
#let detail(t) = {
  let short(s) = if s.len() > 48 { s.slice(0, 45) + "..." } else { s }
  let parts = if t.kind == "begin" {
    (t.fields.name,)
    let set_fields = ("points", "label").filter(k => t.fields.at(k) != none)
    set_fields.map(k => k + ": " + repr(t.fields.at(k)))
  } else if t.kind == "break" {
    (t.target + if t.weak { ", weak" } else { "" },)
  } else if t.kind == "chunk" {
    (short(repr(t.body)),)
    if t.fr != none { ("fr: " + repr(t.fr),) }
    if t.has_inner_break { ("has_inner_break",) }
  } else { () }
  let styles = t.at("styles", default: ())
  if styles.len() > 0 { parts.push(str(styles.len()) + " style(s)") }
  raw(parts.join(", ", default: ""))
}

/// Tokenize `src`, run `check` on the tokens, and draw the case: the source,
/// beside its tokens.
#let case(desc, src, check) = {
  let toks = tokenize(eval(src, mode: "markup", scope: SCOPE))
  check(toks)
  rule(desc)
  pair(
    raw(src, lang: "typ", block: true),
    cases(([Token], [Carries]), ..toks.map(t => (raw(t.kind), detail(t)))),
  )
}

#case([Plain content stays opaque.], "just some text", toks => {
  assert(kinds(toks) == ("chunk",), message: repr(kinds(toks)))
})

#case([Nested sequences without structure stay one chunk, never destructured.], "hi #[there #[nested]]", toks => {
  assert(toks.len() == 1, message: repr(kinds(toks)))
  assert(toks.at(0).kind == "chunk")
})

#case([A simple question.], "#question[body text]", toks => {
  assert(kinds(toks) == ("begin", "chunk", "end"), message: repr(kinds(toks)))
  assert(toks.at(0).fields.name == "question")
})

#case([Nested divisions unwrap positionally.], "#question[intro #part[part body] outro]", toks => {
  assert(
    shape(toks) == ("begin", "chunk", "begin", "chunk", "end", "chunk", "end"),
    message: repr(kinds(toks)),
  )
})

#case([Questions side by side.], "#question[a] #question[b]", toks => {
  assert(kinds(toks).filter(k => k == "begin").len() == 2)
  assert(kinds(toks).filter(k => k == "end").len() == 2)
})

#case([A page break becomes a break token.], "#question[before #pagebreak() after]", toks => {
  assert(shape(toks) == ("begin", "chunk", "break", "chunk", "end"), message: repr(kinds(toks)))
  let brk = toks.find(t => t.kind == "break")
  assert(brk.target == "page")
  assert(brk.weak == false)
})
#case([A column break.], "#question[a #colbreak() b]", toks => {
  assert(toks.find(t => t.kind == "break").target == "col")
})
#case([A weak break stays weak.], "#question[a #pagebreak(weak: true) b]", toks => {
  assert(toks.find(t => t.kind == "break").weak == true)
})

#case(
  [A break deep inside a block, with no division around it, stays in an opaque chunk, flagged.],
  "#block[x #colbreak() y]",
  toks => {
    assert(kinds(toks) == ("chunk",))
    assert(toks.at(0).has_inner_break == true)
  },
)

#case([An fr height is recorded on its chunk.], "#question[text #v(1fr)]", toks => {
  let frs = toks.filter(t => t.kind == "chunk").map(t => t.fr).filter(f => f != none)
  assert(frs == (1fr,), message: repr(frs))
})
#case([So is a height hint's.], "#question[#height_hint(2fr) box-stand-in]", toks => {
  let frs = toks.filter(t => t.kind == "chunk").map(t => t.fr).filter(f => f != none)
  assert(frs == (2fr,), message: repr(frs))
})

#case(
  [Enum items stay opaque; a part after a markup enum is still found (ISSUES regression #2).],
  "#question[\n  hi\n  + list\n  + list 2\n\n  #part[foo]\n]",
  toks => {
    let begins = toks.filter(t => t.kind == "begin")
    assert(begins.len() == 2, message: repr(kinds(toks)))
    assert(begins.at(1).fields.name == "part")
  },
)

#case([An empty part gives adjacent begin and end (ISSUES regression #1).], "#question[#part[]]", toks => {
  let names = toks.filter(t => t.kind == "begin").map(t => t.fields.name)
  assert(names == ("question", "part"), message: repr(names))
})

#case(
  [A styled wrapper is unwrapped, its styles recorded on each token inside.],
  "#set text(fill: red)\n#question[hello]",
  toks => {
    assert(kinds(toks) == ("begin", "chunk", "end"), message: repr(kinds(toks)))
    assert(toks.at(0).styles.len() == 1)
    assert(toks.at(1).styles.len() == 1)
    // Re-applying the styles gives content back.
    assert(type(apply_styles(toks.at(1).body, toks.at(1).styles)) == content)
  },
)

#case([Styled content with no division inside stays opaque.], "a #text(fill: red)[red] b", toks => {
  assert(toks.len() == 1, message: repr(kinds(toks)))
})

#case([A division's fields travel on its begin token.], "#question(points: 3, label: <q1>)[body]", toks => {
  let f = toks.at(0).fields
  assert(f.points == 3)
  assert(f.label == <q1>)
  assert(f.number == auto)
})

// A marker buried inside an opaque container panics with a diagnostic. (A
// panic cannot be asserted in Typst, so this is verified by hand.)

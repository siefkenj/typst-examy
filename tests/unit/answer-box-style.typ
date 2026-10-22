// `answer-box`'s look, passed to the box it draws as `box` takes it:
// `fill`, `radius`, `outset`, and `clip`. None of them moves the layout: an
// outset reaches out past the box without taking room.
#import "/src/lib.typ": *
#import "/src/elements/answer-box.typ": drawn as ab_drawn
#import "/tests/record.typ": rule

#set page(width: 5in, height: auto, margin: .4in)
#set text(size: 10pt)

#let probe(name) = [#metadata(name)<after>]

// Each case: what it is given, which the drawn box should have as it is.
#let CASES = ((fill: luma(235)), (radius: 4pt), (outset: 3pt), (clip: true), (radius: (top: 6pt), fill: yellow.lighten(80%)))

#rule[Each argument, on a full-width box with a solution]
#show: exam.with(show-solutions: true)
#for (i, args) in CASES.enumerate() {
  question[
    #raw(repr(args)):
    #answer-box(width: 100%, height: 1cm, ..args)[#solution[An answer.]]
    #probe(i)
  ]
}
#rule[The same boxes with nothing given, for the layout]
#for (i, _) in CASES.enumerate() {
  question[
    #raw("(:)"):
    #answer-box(width: 100%, height: 1cm)[#solution[An answer.]]
    #probe(i)
  ]
}

// The box `answer-box` draws: the first one with an outline in what it
// returns (the wrapper of an inline box has none).
#let drawn(c) = {
  let stack = (c,)
  while stack.len() > 0 {
    let c = stack.pop()
    if type(c) == array { stack += c.rev(); continue }
    if type(c) != content { continue }
    if c.func() == box and c.at("stroke", default: none) != none { return c }
    stack += c.fields().values().rev()
  }
}
// (A dictionary of sides or corners the box expands, so the last case is
// only drawn.)
#for args in CASES.slice(0, 4) {
  let b = drawn(ab_drawn(answer-box(width: 100%, height: 1cm, ..args)[]))
  for (key, value) in args {
    assert.eq(b.at(key, default: none), value, message: repr((args, key)))
  }
}

#context {
  // The layout is the same with each argument as without.
  let after = query(<after>).map(m => m.location().position())
  let n = CASES.len()
  for i in range(n) {
    let (a, b) = (after.at(i), after.at(i + n))
    assert.eq(a.x, b.x, message: "moved: case " + str(i))
  }
  // Each case takes as much room as its twin with nothing given.
  let ys = after.map(p => p.y)
  for i in range(n - 1) {
    let (a, b) = (ys.at(i + 1) - ys.at(i), ys.at(n + i + 1) - ys.at(n + i))
    assert(calc.abs((a - b) / 1pt) < .01, message: "case " + str(i) + " takes " + repr(a) + ", not " + repr(b))
  }
}

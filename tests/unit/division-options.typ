// The option a question, part, or subpart takes for itself, beside the
// exam's: `indent`, for itself, `config`'s `indent` where it gives none.
// (A `config` rule around them sets the others: see
// tests/unit/scoped-config.typ and tests/unit/scoped-numbering.typ.)
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (x: 1.5in, y: .5in))
#set text(size: 10pt)
#show: e.prepare()

/// A division's left edge, recorded under `name` where it is written.
#let at(name) = context [#metadata(here().position().x)#label("x-" + name)]
#let x(name) = query(label("x-" + name)).first().value

// --- `indent`: `config`'s, and a division's own ---
#rule[`config`'s `indent: 3em`; question 2's part given `indent: 1em`.]
#block(stroke: .3pt + gray, inset: 6pt, {
  show: e.set_(config, indent: 3em)
  exam[
    #question[#at("q1")One. #part[#at("q1a")A part.]]
    #question[#at("q2")Two. #part(indent: 1em)[#at("q2a")A part.]]
  ]
})
#context {
  assert.eq(x("q1a") - x("q1"), 3em.to-absolute(), message: "config's indent indents a part")
  assert.eq(x("q2a") - x("q2"), 1em.to-absolute(), message: "a part's own indent wins")
}

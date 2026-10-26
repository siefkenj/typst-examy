// `config`'s options that take an array are set as a whole by a rule
// inside another, as `numbering` is: elembic's default folding of arrays
// would append the inner rule's to the outer's.
#import "/src/lib.typ": *
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()

#let OUTER = (
  numbering: ("A.", "(i)"),
  choices-enumerate: ("p", "q"),
  bubble-label-font: ("Libertinus Serif",),
)
#let INNER = (
  numbering: ("1.",),
  choices-enumerate: ("x", "y", "z"),
  bubble-label-font: ("DejaVu Sans Mono",),
)

#show: e.set_(config, ..OUTER)
#show: e.set_(config, ..INNER)

#e.get(get => {
  for (name, inner) in INNER {
    assert.eq(get(config).at(name), inner, message: name + ": the inner rule's array replaces the outer's")
  }
})

#rule[An array option set by a rule inside another: the inner rule's is the one in force.]
#e.get(get => cases(
  ([Option], [Outer rule], [Inner rule], [In force]),
  ..INNER
    .keys()
    .map(name => (
      raw(name),
      raw(repr(OUTER.at(name))),
      raw(repr(INNER.at(name))),
      raw(repr(get(config).at(name))),
    )),
))

// End to end: the choices are labelled by the inner rule's array, and a
// correct choice named by its label is the one so labelled.
#rule[`choices` under both rules, `correct: "y"` on the key: labelled x, y, z, the second filled in.]
#{
  show: e.set_(config, show-solutions: true)
  choices(correct: "y")[
    - First
    - Second
    - Third
  ]
}

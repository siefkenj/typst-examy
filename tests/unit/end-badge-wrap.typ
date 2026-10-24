// With `points-position: "end"`, a badge that does not fit on the line after
// the text before it wraps to a line of its own, still flush right: after a
// full-width box of fixed height in the line, say, it used to wrap to the
// left edge. Every badge's right edge must be at the text's right edge, and
// one that wraps must be below the box before it.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: 16cm, margin: (x: 1.5cm, y: 1cm))
#set text(size: 10pt)
#show: e.prepare()

/// The right edge of the text.
#let RIGHT = 10cm - 1.5cm

/// A badge's text. The exam boxes the badge, and an element in a box is
/// located at the box's start: a badge ends that far, plus its width.
#let badge(p) = [(#p points)]

#rule[Every badge flush right, those after a full-width box on a line of their own below it.]
#exam(points-position: "end", points-format: p => [#metadata(p)<badge>#badge(p)])[
  #question(points: 1)[Short.]
  #question(points: 2)[Fill: #answer-box(width: 100%, height: 1.5cm)[]#metadata(2)<box-end>]
  #question(points: 3)[
    Explain why.
    #answer-box(width: 100%, height: 1.5cm)[]#metadata(3)<box-end>
  ]
  #question(points: 4)[#lorem(24)]
  #question(points: 5)[An inline #answer-box[] box.]
  #question(points: 6)[#answer-box(width: 100%, height: 1cm)[]#metadata(6)<box-end>]
]

#context {
  let badges = query(<badge>)
  assert.eq(badges.map(b => b.value), (1, 2, 3, 4, 5, 6))
  for b in badges {
    let x = b.location().position().x + measure(badge(b.value)).width
    assert(calc.abs((x - RIGHT).to-absolute().pt()) < .5, message: "badge " + str(b.value) + " ends at " + repr(x))
  }
  for m in query(<box-end>) {
    let badge = badges.find(b => b.value == m.value).location().position().y
    assert(badge > m.location().position().y, message: "badge " + str(m.value) + " should be below its box")
  }
}

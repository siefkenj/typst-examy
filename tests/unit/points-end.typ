// A badge at the `"end"` follows all of a division's own text before its
// first part, also when the division is split into peer segments at an `fr`
// box or a page break: after an `fr` box, the box gives a line up to it, so
// the badge overlaps nothing that follows.
#import "/src/lib.typ": *
#import "/src/config.typ": default_points_format

#set page(width: 5in, height: 4in, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()
#show: e.set_(config, points-position: "end", points-format: p => [#metadata(p)<badge>#default_points_format(p)])

#exam(questions: [
  #question(points: 4)[
    A prompt over an `fr` box.
    #answer-box(width: 100%, height: 1fr)[#place(bottom)[#metadata(none)<box-bottom>]]
  ]
  #question(points: 2)[N#metadata(none)<next>ext question, on the same page.]
  #pagebreak()
  #question(points: 3)[
    Text before a page break.
    #pagebreak()
    Text af#metadata(none)<after>ter it.
    #part(points: 1)[A part.]
  ]
])

#context {
  let at(lbl) = query(lbl).first().location().position()
  let badge(p) = query(<badge>).find(m => m.value == p).location().position()
  // Below the `fr` box, and above the question after it.
  let four = badge(4)
  assert(four.y > at(<box-bottom>).y, message: repr((four, at(<box-bottom>))))
  assert(four.y < at(<next>).y - 5pt, message: repr((four, at(<next>))))
  // After the text on the page after the break, not before the break.
  let three = badge(3)
  assert(three.page == at(<after>).page, message: repr((three, at(<after>))))
  assert(calc.abs((three.y - at(<after>).y).pt()) < 8, message: repr((three, at(<after>))))
}

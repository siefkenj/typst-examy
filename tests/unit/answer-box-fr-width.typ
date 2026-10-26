// An answer box with a fractional width (`1fr`) fills the rest of its line,
// shared proportionally with the line's other fractional widths, as `box`
// does, and stays in the line, on its baseline like any small box. Given by
// `config`'s `answer-box-width`, it lays out the same. A box with a
// fractional height is a block, which a fractional width makes full width.
// Marks before and after each box record where it starts and ends.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 10cm, height: auto, margin: (x: 1.8cm, y: .8cm))
#set text(size: 10pt)

/// A mark recording where it is under `name`.
#let mark(name) = [#metadata(name)<mark>]
/// A mark, and a period after it to keep it in its line: a mark with
/// nothing after it at the end of a question goes to the next line.
#let end(name) = [#mark(name).]

#rule[One box: it reaches the end of the line, past the text before it.]
#exam[
  #question[Critical points: #mark("one-start")#answer-box(width: 1fr)[]#end("one-end")]
]

#rule[Two boxes, `1fr` and `2fr`: the second is twice the first.]
#exam[
  #question[
    $x =$ #mark("a-start")#answer-box(width: 1fr)[]#end("a-end") and
    $y =$ #mark("b-start")#answer-box(width: 2fr)[]#end("b-end")
  ]
]

#rule[From `config`'s `answer-box-width`, and from the call: alike.]
#exam(answer-box-width: 1fr)[
  #question[Critical points: #mark("config-start")#answer-box[]#end("config-end")]
]
#exam[
  #question[Critical points: #mark("call-start")#answer-box(width: 1fr)[]#end("call-end")]
]

#rule[With a fractional height: a block, full width.]
#exam[
  #question(height: 4cm)[
    #mark("text-start")Find the critical points.
    #mark("block-start")#answer-box(height: 1fr, width: 1fr)[
      Critical points: #mark("in-start")#answer-box(width: 1fr)[]#end("in-end")
    ]
  ]
]

#context {
  let at(name) = query(<mark>).find(m => m.value == name).location().position()
  // Where a box ends: its mark, the period after it hanging into the margin
  // (`par`'s `overhang`).
  let end(name) = at(name + "-end").x
  let width(name) = at(name + "-end").x - at(name + "-start").x
  let right = page.width - 1.8cm
  let close(a, b) = calc.abs((a - b).to-absolute().pt()) < .5

  // Each box takes the rest of its line, with only the period after it.
  for name in ("one", "b", "config", "call") {
    assert(close(end(name), right), message: name + " ends at " + repr(end(name)))
    assert(close(at(name + "-end").y, at(name + "-start").y), message: name + " wrapped")
  }
  assert(width("one") > 3cm, message: "the box is " + repr(width("one")))
  // In proportion to their fractions.
  assert(close(width("b"), 2 * width("a")), message: repr((width("a"), width("b"))))
  assert(close(at("a-end").y, at("b-start").y), message: "the two boxes are on different lines")
  // From config as from the call.
  assert(close(width("config"), width("call")), message: repr((width("config"), width("call"))))
  // The block with a fractional height is as wide as the question, from its
  // left to the margin: the box in it, filling its line, ends its inset
  // and stroke short of the margin.
  assert(close(at("block-start").x, at("text-start").x), message: repr(at("block-start")))
  assert(right - end("in") > 0pt and right - end("in") < 12pt, message: "the inner box ends at " + repr(end("in")))
}

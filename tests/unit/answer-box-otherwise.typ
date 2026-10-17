// A solution with `otherwise` shows it on the exam; on the key, in an answer
// box with no height, the solution is drawn over it, so that the box is the
// same height on both. Also: `answer-box`'s `stroke`.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: .25in)
#set text(size: 10pt)
#show: e.prepare()

#let COLUMN = 5.5in
#let near(a, b) = calc.abs((a - b).pt()) < 0.01
#let height(b) = measure(b, width: COLUMN).height

#let lines = block(width: 100%, for _ in range(3) { v(1.5em); line(length: 100%) })
#let blank = box(width: 3cm, stroke: (bottom: .5pt))

#let boxes = (
  // Lines to write on, in place of a solution of its own paragraph.
  lines: answer-box(width: 100%, stroke: none)[
    #solution(otherwise: lines)[A long answer, long enough that it is longer than a line of text in this box, so it wraps.]
  ],
  // A blank within a line of text.
  blank: answer-box(width: 100%)[The capital is #solution(otherwise: blank)[Ottawa], of course.],
)

// Measured in a context of each setting, since `height` needs one.
#for key in (false, true) {
  show: e.set_(config, show-solutions: key)
  context {
    for (name, b) in boxes {
      [#metadata((key: key, name: name, height: height(b)))<h>]
    }
  }
}
#context {
  let got = query(<h>).map(m => m.value)
  for name in boxes.keys() {
    let (exam, key) = (false, true).map(k => got.find(v => v.key == k and v.name == name).height)
    assert(near(exam, key), message: name + ": the exam's box is " + repr(exam) + ", the key's " + repr(key))
  }
  // The lines take their own height: the box is not `default_height`.
  let lines = got.find(v => v.name == "lines").height
  assert(lines > 4.5em.to-absolute(), message: repr(lines))
}

// On the exam, `otherwise` is shown; on the key, the solution.
#rule[On the exam (left), `otherwise` is shown; on the key (right), the solution.]
#grid(
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  {
    show: e.set_(config, show-solutions: false)
    solution(otherwise: [#metadata(none)<shown-otherwise>The `otherwise`.])[#metadata(none)<shown-solution>The solution.]
  },
  {
    show: e.set_(config, show-solutions: true)
    solution(otherwise: [#metadata(none)<hidden-otherwise>The `otherwise`.])[#metadata(none)<shown-key>The solution.]
  },
)
#context {
  assert(query(<shown-otherwise>).len() == 1)
  assert(query(<shown-solution>).len() == 0)
  assert(query(<hidden-otherwise>).len() == 0)
  assert(query(<shown-key>).len() == 1)
}

// --- stroke ---
// Any stroke `box` takes, and no outline at all: the box keeps its size.
#context {
  let plain = height(answer-box(width: 100%)[])
  for stroke in (none, 1pt, red, (bottom: .5pt), (x: none, rest: 1pt + blue)) {
    let h = height(answer-box(width: 100%, stroke: stroke)[])
    assert(near(h, plain), message: repr(stroke) + ": " + repr(h))
  }
}

// A visual record of each case above: the exam on the left, the key on the
// right, each with the height it was measured at.
#let side_by_side(b) = grid(
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  ..(false, true).map(key => {
    show: e.set_(config, show-solutions: key)
    block(text(8pt, strong(if key [Key] else [Exam])))
    context {
      block(b)
      block(text(8pt)[Height: #calc.round(height(b).pt(), digits: 1)pt])
    }
  }),
)
#rule[Lines to write on: the key draws the answer over them, and the box keeps its height.]
#side_by_side(boxes.lines)
#rule[A blank within a line: the answer sits on it, and the line keeps its height.]
#side_by_side(boxes.blank)
#rule[Outside a box: the key replaces the blank with the answer.]
#side_by_side[Fill in: #solution(otherwise: blank)[42].]
#rule[`stroke`: `.5pt` (the default), `none`, `1pt`, `red`, `(bottom: .5pt)`, `(x: none, rest: 1pt + blue)`.]
#grid(
  columns: 3,
  gutter: 8pt,
  ..(.5pt, none, 1pt, red, (bottom: .5pt), (x: none, rest: 1pt + blue)).map(stroke => (
    answer-box(width: 100%, height: 1cm, stroke: stroke)[#text(8pt, raw(repr(stroke)))]
  )),
)

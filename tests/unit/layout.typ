// End-to-end geometry: `1fr` answer boxes are peers in the page's space
// negotiation, so two `1fr` boxes come out the same height even when their
// prompts differ in length. While an fr box shared a segment with its
// division's prose, it resolved against what that prose left over inside the
// segment, and the box under the three-line prompt came out about two lines
// shorter than the box under the one-line prompt.
#import "/src/lib.typ": *

#set page(paper: "us-letter", margin: 1in)
#show: e.prepare()
#show: e.set_(config, show-solutions: false)

#exam(
  questions: [
    #question[
      A one-line prompt.
      #answer-box(height: 1fr)[
        #metadata(none)<top-a>
        #place(bottom)[#metadata(none)<bot-a>]
      ]
    ]
    #question[
      A prompt long enough to wrap onto a second and then a third line, so that
      it takes visibly more vertical space above its answer box than the short
      one-line prompt of the question before it does above its own box.
      #answer-box(height: 1fr)[
        #metadata(none)<top-b>
        #place(bottom)[#metadata(none)<bot-b>]
      ]
    ]
  ],
)

#context {
  let y(l) = query(l).first().location().position().y
  let (ha, hb) = (y(<bot-a>) - y(<top-a>), y(<bot-b>) - y(<top-b>))
  assert(
    calc.abs(ha.pt() - hb.pt()) < 1,
    message: "1fr answer boxes should be equal, got " + repr(ha) + " vs " + repr(hb),
  )
  // Guard against both collapsing to nothing, which would satisfy the above.
  assert(ha > 2in, message: "answer boxes collapsed: " + repr(ha))
}

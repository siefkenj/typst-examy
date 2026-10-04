// A small inline `answer-box` is centered on the text line via its
// `baseline` shift. That shift is measured from the box's bottom edge, but a
// box inherits the baseline of its contents' last line, so a box holding any
// content at all (a prompt, a `solution`) used to be positioned by that line
// instead and ended up dropped a half-box-height below the text. An empty
// box was unaffected, so the two must agree.
#import "/src/lib.typ": *
#import "/src/scan.typ": starts_inline

#set page(paper: "us-letter", margin: 1in)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

// Zero-width, zero-height marker: sits at the line's baseline.
#let here(l) = box(width: 0pt, [#metadata(none)#l])

Empty: #here(<base-a>)#answer-box(height: 1in, width: 1in)[
  #place(top)[#metadata(none)<top-a>]
]

Prompt: #here(<base-b>)#answer-box(height: 1in, width: 1in)[
  #place(top)[#metadata(none)<top-b>]
  A prompt.
]

Solution: #here(<base-c>)#answer-box(height: 1in, width: 1in)[
  #place(top)[#metadata(none)<top-c>]
  #solution[42]
]

#context {
  let y(l) = query(l).first().location().position().y
  // Offset of the box's top edge from the baseline of the line it sits on.
  let offset(base, top) = (y(top) - y(base)).pt()
  let empty = offset(<base-a>, <top-a>)
  for (name, base, top) in (("a prompt", <base-b>, <top-b>), ("a solution", <base-c>, <top-c>)) {
    let got = offset(base, top)
    assert(
      calc.abs(got - empty) < 1,
      message: "answer box with "
        + name
        + " is not on the same baseline as an empty one: top edge at "
        + repr(got)
        + "pt from the baseline vs "
        + repr(empty)
        + "pt",
    )
  }
  // The box straddles the line: roughly half of it above the baseline.
  assert(empty < -0.4 * 72, message: "inline answer box is not centered on the line: " + repr(empty))
}

// The baseline wrapper must still read as a sized box: a division body that
// opens with a fixed-height answer box gets its gutter label at the top of
// the box, not riding the box's (centered) baseline.
#assert(
  starts_inline(answer-box(height: 1in, width: 1in)[]) == false,
  message: "a fixed-height inline answer box is classified as text-like",
)

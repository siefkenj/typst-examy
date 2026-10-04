// `bubble` / `square-bubble`: which bubbles are filled in, the colors they
// are filled in with, the solution color their content picks up, and the
// geometry of the drawn bubble (its default size per shape, the `size`
// argument, and how far it hangs below the baseline).
//
// The rule that matters most is that a bubble is filled in only when
// solutions are shown: an exam compiled without them must not leak its
// answers through the bubbles.
#import "/src/lib.typ": *
#import "/src/elements/bubble.typ": (
  _BUBBLE_SIZE, _OUTSET, _SQUARE_SIZE, _STROKE, bubble_drop, bubble_style, cap_center, check_mark,
  is_filled, resolve_sides, round_shape,
)
#import "/src/config.typ": resolve_solution_colors, solution_colors

#set page(width: 6in, height: auto, margin: .25in)
#set text(size: 10pt)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

// Each case is printed under its description, so the rendered test reads as
// its own documentation: a rule separates the cases and the description sits
// against the right margin, clear of the sample. The body goes in a block of
// its own, which keeps it out of the next case's paragraph, so a pair of
// measuring markers can never be split across a line break.
#let case(desc, body) = {
  block(above: 12pt, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  align(right, emph(desc))
  block(body)
}

// --- which bubbles are filled in ---
#e.get(get => {
  assert(is_filled(true, get), message: "a correct bubble fills in on the answer key")
  assert(not is_filled(false, get), message: "a wrong choice is never filled in")
})
#[
  #show: e.set_(config, show-solutions: false)
  #e.get(get => {
    assert(
      not is_filled(true, get),
      message: "a correct bubble stays empty when solutions are off",
    )
    assert(not is_filled(false, get), message: "a wrong choice is never filled in")
  })
]

// --- the colors a filled-in bubble is drawn with ---
// A filled-in bubble is drawn with the same pair as a solution: the
// solution color outlining the solution background.
#let _colors = (color: blue, background: aqua)
#assert.eq(bubble_style(true, _colors).stroke, _STROKE + blue)
#assert.eq(bubble_style(true, _colors).fill, aqua)
// An empty bubble is a plain outline, in no particular color.
#assert.eq(bubble_style(false, _colors).stroke, _STROKE)
#assert.eq(bubble_style(false, _colors).fill, none)

// --- the color a bubble's content is set in ---
// A probe reporting the text color in force where the bubble's content sits.
#let fill_probe(name) = context [#metadata(text.fill)#label("fill-" + name)]

#case(
  [The content of a correct bubble is set in the solution color.],
  bubble(correct: true)[#fill_probe("correct") correct],
)
#case(
  [The content of a wrong choice keeps the surrounding text color.],
  bubble[#fill_probe("wrong") wrong],
)
#case(
  [A square bubble colors its content the same way.],
  square-bubble(correct: true)[#fill_probe("square-correct") correct],
)
#case(
  [With solutions off, a correct bubble's content is not colored either.],
  [
    #show: e.set_(config, show-solutions: false)
    #bubble(correct: true)[#fill_probe("correct-no-solutions") correct]
  ],
)
#case(
  [The color comes from the config, not from a hard-coded blue.],
  [
    #show: e.set_(config, solution-color: olive)
    #bubble(correct: true)[#fill_probe("recolored") correct]
  ],
)

#e.get(get => {
  let solution-color = solution_colors(get).color
  context {
    let fill_of(name) = query(label("fill-" + name)).first().value
    let fill_is(name, expected) = assert.eq(
      fill_of(name),
      expected,
      message: name + ": wrong text color",
    )

    fill_is("correct", solution-color)
    fill_is("square-correct", solution-color)
    // `black` is the page's text color, which the bubble must leave alone.
    fill_is("wrong", black)
    fill_is("correct-no-solutions", black)
    fill_is("recolored", olive)
  }
})

// --- how far a bubble hangs below the baseline ---
// A bubble is centered on the center line of a capital letter, so what is
// left of it below the baseline depends on its radius.
#let drop_is(size, center, expected) = {
  let got = bubble_drop(size, center)
  assert(
    calc.abs(got.em - expected.em) < 1e-9 and calc.abs((got.abs - expected.abs).pt()) < 1e-9,
    message: "a " + repr(size) + " bubble should drop " + repr(expected) + ", got " + repr(got),
  )
}
// Half of the bubble, less the center line it is raised onto. The center
// lines here are round numbers chosen to make the arithmetic plain — what
// the real one is gets checked below, against the font.
#drop_is(_BUBBLE_SIZE, .25em, _BUBBLE_SIZE / 2 - .25em)
// A bigger bubble drops further.
#drop_is(_BUBBLE_SIZE * 2, .25em, _BUBBLE_SIZE - .25em)
// One exactly twice the center line sits on the baseline.
#drop_is(.5em, .25em, 0em)
// A smaller one has to clear the baseline to stay centered on the text.
#assert(
  bubble_drop(.49em, .25em).em < 0,
  message: "a tiny bubble should sit above the baseline",
)

// The center line is half the *cap* height of the font in use, so a bubble
// and a capital X are centered on each other. Measured from the font rather
// than guessed, and emphatically not the x-height, which would sit a bubble
// low beside capitals and digits.
#context {
  let edge_to_edge(top, bottom, glyph) = {
    measure(
      text(top-edge: top, bottom-edge: bottom, glyph),
    ).height
  }
  let cap = edge_to_edge("cap-height", "baseline")[X]
  let x_height = edge_to_edge("x-height", "baseline")[x]
  // A capital X spans the baseline to the cap height, and the bubble is
  // centered on `cap_center()` above the baseline, so the two share a center
  // exactly when that is half the cap height.
  assert.eq(
    cap_center(),
    cap / 2,
    message: "a bubble and a capital X are not centered on each other",
  )
  assert(
    cap_center() > x_height / 2,
    message: "the center line follows the cap height, not the x-height",
  )
  // The drop assumes the drawn shape is exactly `size` tall: were the stroke
  // to inflate it, the bubble would be centered on the wrong line. Measured
  // on the shape rather than on a whole bubble, because measuring the latter
  // also takes in the baseline it is shifted off — which, for a bubble small
  // enough to clear the baseline entirely, reports more than its own height.
  assert.eq(
    measure(round_shape(_BUBBLE_SIZE, stroke: _STROKE)).height,
    _BUBBLE_SIZE.to-absolute(),
    message: "a bubble is not _BUBBLE_SIZE tall",
  )
}

// --- geometry ---
// Zero-width markers pinned to either side of a bubble: the distance between
// them is what the bubble (plus its gap and content) advances the line by.
#let probe(name) = [#box(width: 0pt, metadata(none))#label(name)]
#let measured(name, desc, body) = case(
  desc,
  probe("l-" + name) + body + probe("r-" + name),
)

#measured(
  "round",
  [A round bubble is #raw(repr(_BUBBLE_SIZE)) across.],
  bubble(),
)
#measured(
  "square",
  [A square bubble is drawn at #raw(repr(_SQUARE_SIZE)).],
  square-bubble(),
)
// Outsets other than the default, to check the argument is honored.
#let NO_OUTSET = 0pt
#let WIDE_OUTSET = (x: 1em)
#measured("no-outset", [`outset: 0pt` leaves the bubble bare.], bubble(outset: NO_OUTSET))
#measured(
  "wide-outset",
  [An outset on both sides parts it from whatever is either way.],
  bubble(outset: WIDE_OUTSET),
)
// A dictionary changes only the sides it names: a space before the bubble
// keeps the default gap after it.
#let LEFT_OUTSET = (left: 1em)
#measured(
  "left-outset",
  [Space before a bubble keeps the gap after it.],
  bubble(outset: LEFT_OUTSET),
)
// A bare length is the gap after the bubble.
#let GAP_OUTSET = .8em
#measured("gap-outset", [A length widens the gap after the bubble.], bubble(outset: GAP_OUTSET))

// An explicit size, to check that an argument overrides the default.
#let OVERRIDE_SIZE = 2em
#measured(
  "sized",
  [`size` sets the bubble's width.],
  bubble(size: OVERRIDE_SIZE),
)
#measured(
  "sized",
  [Large bubbles have their check marks drawn centered],
  bubble(size: OVERRIDE_SIZE, correct: true),
)
#measured("round-correct", [Filling a bubble in does not resize it.], bubble(correct: true))
// The sample the cases below put after a bubble — any content, changed here
// and nowhere else. The width measured for it on its own is subtracted from
// the widths of the cases that pair it with a bubble, so a copy left behind
// in one case would silently compare two different samples.
#let SAMPLE = [X]

// Normalized to content, so a bare string works as well: a string cannot be
// concatenated with the measuring markers.
#let sample = if type(SAMPLE) == str { text(SAMPLE) } else { SAMPLE }

// The markers only bracket a width while what is between them sits on one
// line, so a sample wider than the text column cannot be measured at all:
// it wraps, and the markers then report the width of its last line. Say so
// here, rather than letting it surface later as a baffling width mismatch.
#context layout(size => {
  let needed = measure(bubble(sample)).width
  assert(
    needed <= size.width,
    message: "SAMPLE is too wide to measure: a bubble and it need "
      + repr(needed)
      + " but the text column is only "
      + repr(size.width)
      + " — use a narrower sample, or widen the page",
  )
})

#measured("sample", [The content on its own, to subtract from the cases below.], sample)
#measured(
  "bubble-sample",
  [Content follows the bubble, parted from it by its outset.],
  bubble(sample),
)
#[
  // The exam and its answer key must lay out identically.
  #show: e.set_(config, show-solutions: false)
  #measured(
    "round-correct-no-solutions",
    [A correct bubble takes the same space with solutions off.],
    bubble(correct: true),
  )
  #measured(
    "bubble-sample-correct-no-solutions",
    [and so does one with content.],
    bubble(sample, correct: true),
  )
]

#context {
  let width(name) = {
    // Named `edge`, not `x`: `x` is both a coordinate and (by default) the
    // sample here, and editing the sample should not touch the code.
    let edge(side) = query(label(side + "-" + name)).first().location().position().x
    edge("r") - edge("l")
  }
  let width_is(name, expected) = assert(
    calc.abs(width(name).pt() - expected.pt()) < 0.01,
    message: name + ": expected " + repr(expected) + ", got " + repr(width(name)),
  )

  // The sizes are declared in `em`; `to-absolute` resolves them against the
  // font size in force here, so these follow the constants in the module
  // rather than restating them — what is under test is that the declared
  // size is what actually reaches the page.
  let em_pt(len) = len.to-absolute()
  // A bubble occupies its shape plus the space it keeps around itself, so
  // that is what it advances the line by.
  let sides = resolve_sides(_OUTSET)
  let advance(size) = em_pt(size) + em_pt(sides.left) + em_pt(sides.right)

  width_is("round", advance(_BUBBLE_SIZE))
  width_is("square", advance(_SQUARE_SIZE))
  width_is("sized", advance(OVERRIDE_SIZE))
  width_is("round-correct", advance(_BUBBLE_SIZE))

  let sample_width = width("sample")
  let with_sample = advance(_BUBBLE_SIZE) + sample_width
  width_is("bubble-sample", with_sample)

  width_is("round-correct-no-solutions", advance(_BUBBLE_SIZE))

  // An outset argument changes the sides it names, and the others keep
  // their defaults.
  let advance_with(size, outset) = {
    let s = resolve_sides(outset, base: sides)
    em_pt(size) + em_pt(s.left) + em_pt(s.right)
  }
  width_is("no-outset", advance_with(_BUBBLE_SIZE, NO_OUTSET))
  width_is("wide-outset", advance_with(_BUBBLE_SIZE, WIDE_OUTSET))
  width_is("left-outset", advance_with(_BUBBLE_SIZE, LEFT_OUTSET))
  width_is("left-outset", em_pt(1em) + advance(_BUBBLE_SIZE))
  width_is("gap-outset", em_pt(_BUBBLE_SIZE) + em_pt(GAP_OUTSET))
  width_is("bubble-sample-correct-no-solutions", with_sample)

  // A square bubble's side is a fixed proportion of the round one's diameter,
  // so the two read as the same control at any size. Equal area — the two
  // covering the same ink — puts that proportion at √π/2 ≈ 0.89, and the
  // module may draw the square a little heavier than that on purpose, so the
  // bound is loose. What it does catch is a square whose size compounds with
  // `_BUBBLE_SIZE` instead of scaling with it, which stays plausible at one
  // particular size and runs away at every other.
  let ratio = _SQUARE_SIZE / _BUBBLE_SIZE
  assert(
    0.75 < ratio and ratio < 1.25,
    message: "a square bubble should be about as big as a round one, got "
      + repr(ratio)
      + " times its diameter",
  )
}

// --- a bubble beside an answer box ---
// A question often puts a small answer box next to a bubble, so the two have
// to sit on the same center line. The bubble's center is `cap_center()` above
// the baseline by construction: it is raised onto that line and its box is
// exactly `size` tall, so half of it lies either side. The box is centered by
// its own `baseline` shift, which approximates the same line with a constant
// — it cannot measure the font without a `context`, which would hide it from
// the exam pipeline's content scans — so the two agree closely rather than
// exactly.
#let baseline_marker(name) = box(width: 0pt, [#metadata(none)#label("base-" + name)])
#let box_edges(name) = [
  #place(top)[#metadata(none)#label("top-" + name)]
  #place(bottom)[#metadata(none)#label("bot-" + name)]
]

#case(
  [A bubble and a small answer box beside it share a center line.],
  [#baseline_marker("square-box")#bubble()#answer-box(
      width: 1cm,
      height: 1cm,
    )[#box_edges("square-box")]],
)
#case(
  [The box's shape does not matter: a wide, short one lines up too.],
  [#baseline_marker("wide-box")#bubble()#answer-box(
      width: 3cm,
      height: .5cm,
    )[#box_edges("wide-box")]],
)
// Filling a bubble in draws a stroke in the solution color over a filled
// shape. That must not resize it or shift its center, or the answer key
// would sit differently on the line from the exam it is printed beside.
#case(
  [A filled-in bubble sits exactly where an empty one does.],
  [#baseline_marker("correct-box")#bubble(correct: true)#answer-box(
      width: 1cm,
      height: 1cm,
    )[#box_edges("correct-box")]],
)
// The answer key as a question actually sets it: a filled-in bubble beside a
// box holding its solution. A box takes the baseline of its contents' last
// line unless something stops it, so content in the box is what would move
// it off the bubble's center line.
#case(
  [And it lines up with a box holding a solution.],
  [#baseline_marker("correct-solution-box")#bubble(correct: true)#answer-box(
      width: 2cm,
      height: 1cm,
      solution: [42],
    )[#box_edges("correct-solution-box")]],
)

#context {
  // The edge markers sit inside the box's inset, but a symmetric inset
  // cancels in the midpoint, so this is the box's own center — no need to
  // know what the inset is.
  let box_center(name) = {
    let y(prefix) = query(label(prefix + "-" + name)).first().location().position().y
    y("base") - (y("top") + y("bot")) / 2
  }
  // A hundredth of an em: far below anything the page can show, but tight
  // enough to catch a box centered on the x-height or on the baseline.
  let tolerance = .01em.to-absolute()
  for name in ("square-box", "wide-box", "correct-box", "correct-solution-box") {
    let off = box_center(name) - cap_center()
    assert(
      calc.abs(off.pt()) < tolerance.pt(),
      message: name
        + ": an answer box and a bubble do not share a center line, off by "
        + repr(off),
    )
  }

  // The cases above pin the box's side of the alignment. This pins the
  // bubble's: filling one in must not move or resize it, or the answer key
  // would not sit on the line the way the exam does.
  let same(what, a, b) = assert.eq(
    a,
    b,
    message: "filling a bubble in changed its " + what,
  )
  same("width", measure(bubble(correct: true)).width, measure(bubble()).width)
  same("height", measure(bubble(correct: true)).height, measure(bubble()).height)
  // At a size small enough to clear the baseline entirely, `measure` takes in
  // the gap down to the baseline as well, so the height it reports moves with
  // the baseline shift — which is what makes this sensitive to a filled-in
  // bubble being nudged off the line rather than merely resized.
  let small = 2 * cap_center() * 0.6
  same(
    "position on the line",
    measure(bubble(size: small, correct: true)).height,
    measure(bubble(size: small)).height,
  )
}

// --- the outset ---
// A dictionary names sides the way Typst's own `inset` does; a bare length
// is the gap after the bubble, since that is the side an author means.
#assert.eq(
  resolve_sides(.5em),
  (left: 0pt, right: .5em, top: 0pt, bottom: 0pt),
  message: "a bare length should set only the gap after the bubble",
)
#assert.eq(
  resolve_sides((rest: 1pt, y: 2pt, top: 3pt)),
  (left: 1pt, right: 1pt, top: 3pt, bottom: 2pt),
  message: "a side should win over `y`, which should win over `rest`",
)
#assert.eq(
  resolve_sides((x: 1pt)),
  (left: 1pt, right: 1pt, top: 0pt, bottom: 0pt),
  message: "an unnamed side should fall back to nothing",
)
// Against a base, the sides a dictionary does not name keep the base's.
#let BASE = (left: 1pt, right: 2pt, top: 3pt, bottom: 4pt)
#assert.eq(
  resolve_sides((left: 9pt), base: BASE),
  (left: 9pt, right: 2pt, top: 3pt, bottom: 4pt),
  message: "an unnamed side should keep its base value",
)
#assert.eq(
  resolve_sides((x: 9pt), base: BASE),
  (left: 9pt, right: 9pt, top: 3pt, bottom: 4pt),
  message: "`x` should set both horizontal sides, over the base",
)
#assert.eq(
  resolve_sides(9pt, base: BASE),
  (left: 1pt, right: 9pt, top: 3pt, bottom: 4pt),
  message: "a bare length should set only the right side, over the base",
)

// Widening the gap with a bare length must not open up the line: the bubble
// is exactly as tall as with the default outset.
#context assert.eq(
  measure(bubble(outset: 1em)).height,
  measure(bubble()).height,
  message: "a bare-length outset should not change the bubble's height",
)

#context {
  // A vertical outset moves the box's bottom edge, and the baseline shift has
  // to follow it, or the shape itself would be pushed off the center line.
  // Choosing a bottom outset that exactly cancels a small bubble's (negative)
  // drop puts the box's bottom edge on the baseline, so there is no gap down
  // to it for `measure` to take in, and the height it reports is just the box.
  let small = 2 * cap_center() * 0.6
  let bottom = -bubble_drop(small, cap_center())
  assert(bottom.to-absolute() > 0pt, message: "the sample bubble should clear the baseline")
  assert.eq(
    measure(bubble(size: small, outset: (bottom: bottom))).height,
    (small + bottom).to-absolute(),
    message: "a bottom outset should move the box without moving the shape off the center line",
  )
}

// --- the check mark ---
// A filled-in bubble is checked as well, so the answer still shows in a
// grayscale print, where the pale fill does not. The check is a glyph from
// whatever font provides it, so this pins that it fits inside the bubble —
// clear of the outline — at either shape's size, and at a size other than
// the default.
#context for size in (_BUBBLE_SIZE, _SQUARE_SIZE, 2em, 0.6em) {
  let mark = measure(check_mark(size, black))
  let room = size.to-absolute() - 2 * _STROKE.to-absolute()
  assert(
    mark.width < room and mark.height < room,
    message: "the check mark should fit inside a "
      + repr(size)
      + " bubble's outline, but is "
      + repr(mark.width)
      + " by "
      + repr(mark.height),
  )
  assert(mark.width > 0pt and mark.height > 0pt, message: "the check mark should draw something")
}

// --- `choice`, and the two bubbles made from it ---
// `bubble` and `square-bubble` are `choice` with its shape fixed, so each
// must draw exactly what `choice` draws with that shape: the same size by
// default, filled in alike, and with content alike.
#context {
  let same(what, a, b) = assert.eq(measure(a), measure(b), message: what)
  same("`choice` is round by default", choice(), bubble())
  same("bubble is choice with a circle", choice(bubble: "circle"), bubble())
  same("square-bubble is choice with a square", choice(bubble: "square"), square-bubble())
  same("Typst's own `square` names the shape too", choice(bubble: square), square-bubble())
  same("a correct choice matches a correct bubble", choice(correct: true)[X], bubble(correct: true)[X])
  // `size: auto` follows the shape; a size given explicitly wins.
  assert.eq(
    measure(choice(bubble: "square", outset: 0pt)).width,
    _SQUARE_SIZE.to-absolute(),
    message: "a square choice is drawn at the square's own size",
  )
  same("an explicit size wins over the shape's", choice(bubble: "square", size: 2em), square-bubble(size: 2em))
  // The shape fixed by `bubble`/`square-bubble` can still be overridden.
  same("`bubble(bubble: \"square\")` is square", bubble(bubble: "square"), square-bubble())
}

// --- an empty choice ---
// `#choice[]` is a bare bubble, exactly as `#choice()` is: nothing follows
// it, so it takes the same space, on the exam and on the answer key alike.
// Content of nothing but spaces counts as empty too, rather than leaving a
// stray space after the bubble. Each case is followed by text, so a space
// there could not be trimmed away as the end of a line would trim it.
#let BLANKS = (
  ("none", none),
  ("empty", []),
  ("space", [ ]),
  ("spaces", [ #[ ] ]),
)
#case([`#choice[]`, or content of only spaces, is a bare bubble, exactly as `#choice()` is.], {
  for (name, body) in BLANKS {
    for correct in (false, true) {
      for shape in ("circle", "square") {
        let id = name + "-" + shape + "-" + repr(correct)
        let args = if body == none { () } else { (body,) }
        [#probe("l-blank-" + id)#choice(..args, bubble: shape, correct: correct)#probe("r-blank-" + id)X ]
      }
    }
  }
})
#context {
  let width(id) = {
    let edge(side) = query(label(side + "-blank-" + id)).first().location().position().x
    edge("r") - edge("l")
  }
  for (name, _) in BLANKS {
    for correct in (false, true) {
      for shape in ("circle", "square") {
        let id = name + "-" + shape + "-" + repr(correct)
        assert(
          calc.abs((width(id) - width("none-" + shape + "-false")).pt()) < 0.01,
          message: "a choice with " + name + " content should take the space of a bare " + shape
            + " bubble, got " + repr(width(id)) + " (correct: " + repr(correct) + ")",
        )
      }
    }
  }
}

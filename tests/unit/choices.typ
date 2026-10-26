// `choices`: which choices it reads from a list or an array, which of them
// are correct (a `+` item, an index in `correct`, or both), the bubble drawn
// for each `bubble:` option, the solution color a correct choice's content
// picks up, the three layouts — one choice per line, in `columns`, or
// `inline` — and the `gap` between choices in each.
//
// As for `bubble`, the rule that matters most is that a correct choice is
// filled in only when solutions are shown, and that the exam and its key
// lay out identically.
#import "/src/lib.typ": *
#import "/src/elements/bubble.typ": (
  _LABEL_MIN, _RING_GAP, bubble as round-bubble, choice_label, label_mark, ring_geometry, square_bubble,
)
#import "/src/elements/choices.typ": choices_shape, correct_indices, parse_choices, resolve_choices
#import "/src/config.typ": DEFAULT_BUBBLE_LABEL_FONT, solution_colors

#set page(width: 6in, height: auto, margin: .25in)
#set text(size: 10pt)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

// Each case is printed under its description, so the rendered test reads as
// its own documentation: a rule separates the cases and the description sits
// against the right margin, clear of the sample.
#let case(desc, body) = {
  block(above: 12pt, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  align(right, emph(desc))
  block(body)
}

// The flags of a resolved or parsed list of choices, in order: what most of
// the cases below compare, since content equality is exact but verbose.
#let correct_of(cs) = cs.map(c => c.correct)
#let marked_of(cs) = cs.map(c => c.marked)

// --- reading the choices from a list ---
#let listed = parse_choices[
  - Toronto
  + Ottawa
  - Montreal
]
#assert.eq(listed.map(c => c.body), ([Toronto], [Ottawa], [Montreal]))
// `+` marks a choice, `-` does not, however the two are interleaved.
#assert.eq(marked_of(listed), (false, true, false))
#assert.eq(
  marked_of(parse_choices[
    + a
    + b
    - c
    + d
  ]),
  (true, true, false, true),
)
// Blank lines between the items are not choices.
#assert.eq(
  parse_choices[
    - a

    - b
  ].len(),
  2,
)
// A block holding a single item is that item rather than a sequence of
// one, and still reads as one choice.
#assert.eq(parse_choices[- only].map(c => c.body), ([only],))
// An item keeps all of its content, math and all.
#assert.eq(
  parse_choices[
    - $x^2$ and more
  ].first().body,
  [$x^2$ and more],
)

// Items produced by code — a `for` loop, or a nested `#[..]` — arrive in
// sequences of their own, and are read through.
#assert.eq(
  parse_choices[#for x in (1, 2, 3) [- #x
    ]].len(),
  3,
)
#assert.eq(
  marked_of(parse_choices[
    - a
    #[
      + b
      - c
    ]
  ]),
  (false, true, false),
)

// --- reading the choices from an array ---
#let arrayed = parse_choices(([Toronto], [Ottawa]))
#assert.eq(arrayed.map(c => c.body), ([Toronto], [Ottawa]))
// An array marks nothing: its correct choices are named by `correct`.
#assert.eq(marked_of(arrayed), (false, false))
// Strings and numbers are made content, so `(9, 11, 15)` works.
#assert.eq(parse_choices(("a", 11)).map(c => c.body), ([a], [11]))

// --- which choices are correct ---
#let abc = ([a], [b], [c])
#assert.eq(correct_of(resolve_choices(abc)), (false, false, false))
// Indices count from 0, like Typst's own arrays.
#assert.eq(correct_of(resolve_choices(abc, correct: 0)), (true, false, false))
#assert.eq(correct_of(resolve_choices(abc, correct: (0, 2))), (true, false, true))
// `correct` adds to the choices marked with `+`, rather than replacing them.
#assert.eq(
  correct_of(resolve_choices(
    correct: 2,
  )[
    + a
    - b
    - c
  ]),
  (true, false, true),
)
// `correct_indices` normalizes the three forms `correct` can take.
#assert.eq(correct_indices(none, 3), ())
#assert.eq(correct_indices(1, 3), (1,))
#assert.eq(correct_indices((0, 2), 3), (0, 2))
// Negative indices count from the last choice, as in a Typst array.
#assert.eq(correct_indices(-1, 3), (2,))
#assert.eq(correct_indices((-3, 1), 3), (0, 1))
#assert.eq(correct_of(resolve_choices(abc, correct: -1)), (false, false, true))
#assert.eq(correct_of(resolve_choices(abc, correct: (0, -3))), (true, false, false))

// --- the bubble drawn for each `bubble:` option ---
// By name, or by Typst's own shape function of that name.
#assert.eq(choices_shape("circle"), "circle")
#assert.eq(choices_shape(circle), "circle")
#assert.eq(choices_shape("square"), "square")
#assert.eq(choices_shape(square), "square")
// Or by examy's own bubble functions, which an author may well pass.
#assert.eq(choices_shape(round-bubble), "circle")
#assert.eq(choices_shape(square-bubble), "square")

// --- the color a choice's content is set in ---
// A probe reporting the text color in force where a choice's content sits.
#let fill_probe(name) = context [#metadata(text.fill)#label("fill-" + name)]

#case(
  [The content of a correct choice is set in the solution color; a wrong one keeps the text color.],
  choices[
    - #fill_probe("wrong") wrong
    + #fill_probe("plus") marked with `+`
  ],
)
#case(
  [So is one named by `correct`, from an array.],
  choices(correct: 1, ([#fill_probe("array-wrong") wrong], [#fill_probe("index") by index])),
)
#case(
  [Inline, and with square bubbles, the content is colored the same way.],
  choices(inline: true, bubble: "square")[
    - #fill_probe("inline-wrong") wrong
    + #fill_probe("inline") right
  ],
)
#case(
  [With solutions off, a correct choice's content is not colored.],
  [
    #show: e.set_(config, show-solutions: false)
    #choices[
      + #fill_probe("no-solutions") right
    ]
    #choices(inline: true)[
      + #fill_probe("inline-no-solutions") right
    ]
  ],
)
#case(
  [In `columns`, the content is colored the same way.],
  choices(columns: 2)[
    - #fill_probe("columns-wrong") wrong
    + #fill_probe("columns") right
  ],
)
#case(
  [The color comes from the config, not from a hard-coded blue.],
  [
    #show: e.set_(config, solution-color: olive)
    #choices[
      + #fill_probe("recolored") right
    ]
  ],
)

#e.get(get => {
  let solution-color = solution_colors(get).color
  context {
    let fill_is(name, expected) = assert.eq(
      query(label("fill-" + name)).first().value,
      expected,
      message: name + ": wrong text color",
    )

    fill_is("plus", solution-color)
    fill_is("index", solution-color)
    fill_is("inline", solution-color)
    fill_is("columns", solution-color)
    // `black` is the page's text color, which a wrong choice must leave alone.
    fill_is("wrong", black)
    fill_is("array-wrong", black)
    fill_is("inline-wrong", black)
    fill_is("columns-wrong", black)
    fill_is("no-solutions", black)
    fill_is("inline-no-solutions", black)
    fill_is("recolored", olive)
  }
})

// --- layout ---
// Zero-width markers whose positions are compared: a choice's content is
// located by a probe at its start.
#let probe(name) = [#box(width: 0pt, metadata(none))#label(name)]
#let pos(name) = query(label(name)).first().location().position()

// The layouts are drawn once with solutions on and once with them off, under
// a prefix, so the two can be compared: the exam and its key must match.
#let layouts(prefix) = {
  case(
    [One choice per line: each choice's content starts after its bubble.],
    [
      #probe(prefix + "left")
      #choices[
        - #probe(prefix + "a")a
        + #probe(prefix + "b")b
        - #probe(prefix + "c")c
      ]
    ],
  )
  // The probes follow an `X` on each line rather than starting it: a marker
  // at the very start of a line after a break is located at the end of the
  // line before. Both lines carry the same `X`, so it cancels out.
  case(
    [A choice that wraps hangs its second line under its content, not under its bubble.],
    choices[
      + X#probe(prefix + "first") first line \ X#probe(prefix + "second") second line
    ],
  )
  case(
    [Inline, the choices share a line.],
    choices(inline: true, bubble: square)[
      - #probe(prefix + "x")x
      + #probe(prefix + "y")y
      - #probe(prefix + "z")z
    ],
  )
  // Every layout keeps a choice whole: its bubble on its first line, and its
  // further lines hanging under its content, not under its bubble.
  case(
    [In `columns`, a choice that wraps hangs under its content.],
    choices(columns: 2)[
      - a
      - X#probe(prefix + "col-first") first \ X#probe(prefix + "col-second") second
    ],
  )
  case(
    [Inline, a choice that wraps hangs under its content.],
    choices(inline: true)[
      - a
      - X#probe(prefix + "inl-first") first \ X#probe(prefix + "inl-second") second
    ],
  )
  case(
    [A bare `choice` that wraps hangs under its content.],
    [#probe(prefix + "bare-left")#choice(correct: true)[X#probe(prefix + "bare-first") first \ X#probe(prefix + "bare-second") second]],
  )
  case(
    [A bare `choice` in a sentence sits on the sentence's baseline.],
    [The answer is#probe(prefix + "sent-before") #choice(correct: true)[#probe(prefix + "sent-in")Paris] or
      #square-bubble[Lyon]#probe(prefix + "sent-after").],
  )
  case(
    [In `columns`, the choices fill each row in turn; a short last row starts at the left.],
    choices(columns: 2)[
      - #probe(prefix + "p")p
      + #probe(prefix + "q")q
      - #probe(prefix + "r")r
    ],
  )
}

#layouts("key-")
#[
  #show: e.set_(config, show-solutions: false)
  #layouts("exam-")
]

#context {
  let near(a, b) = calc.abs((a - b).pt()) < 0.01
  let check(cond, message) = assert(cond, message: message)

  for prefix in ("key-", "exam-") {
    let p(name) = pos(prefix + name)
    // Measured rather than hard-coded, so the expectation follows the
    // bubble's size, and the space it keeps after itself (its outset).
    let indent = measure(round-bubble()).width

    check(
      near(p("a").x - p("left").x, indent),
      prefix + "content should start a bubble and a gap from the left edge, expected "
        + repr(indent)
        + ", got "
        + repr(p("a").x - p("left").x),
    )
    // One per line: the choices line up, each below the last.
    check(near(p("a").x, p("b").x) and near(p("b").x, p("c").x), prefix + "the choices should line up")
    check(p("a").y < p("b").y and p("b").y < p("c").y, prefix + "each choice should be below the last")
    // Wrapped: the second line starts where the first line's content does.
    check(near(p("first").x, p("second").x), prefix + "a wrapped choice should hang under its content")
    check(p("first").y < p("second").y, prefix + "the wrapped choice should span two lines")
    // The same in the other layouts: the second line under the first line's
    // content, which starts a bubble and a gap in from the choice's left edge.
    for (layout, left) in (("col", none), ("inl", none), ("bare", "bare-left")) {
      let first = p(layout + "-first")
      let second = p(layout + "-second")
      check(first.y < second.y, prefix + layout + ": the wrapped choice should span two lines")
      check(
        near(first.x, second.x),
        prefix + layout + ": a wrapped choice should hang under its content, not its bubble, got lines at "
          + repr(first.x) + " and " + repr(second.x),
      )
      if left != none {
        // The probe follows the line's `X`.
        let expected = indent + measure[X].width
        check(
          near(first.x - p(left).x, expected),
          prefix + layout + ": content should start a bubble and a gap in, expected " + repr(expected) + ", got "
            + repr(first.x - p(left).x),
        )
      }
    }
    // A choice in a sentence keeps the sentence's baseline.
    check(
      near(p("sent-before").y, p("sent-in").y) and near(p("sent-in").y, p("sent-after").y),
      prefix + "a choice in a sentence should sit on its baseline, got "
        + ("sent-before", "sent-in", "sent-after").map(n => repr(p(n).y)).join(", "),
    )
    // Inline: one line, left to right.
    check(near(p("x").y, p("y").y) and near(p("y").y, p("z").y), prefix + "inline choices should share a line")
    check(p("x").x < p("y").x and p("y").x < p("z").x, prefix + "inline choices should run left to right")
    // Columns: across the first row, then down to the second, back at the left.
    check(near(p("p").y, p("q").y), prefix + "the first row of columns should share a line")
    check(near(p("r").x, p("p").x) and p("r").y > p("p").y, prefix + "the third choice should start the second row")
    // The columns are equal, `gap` apart: one column and one gap from the
    // first to the second. The text is 396pt wide (a 6in page less two
    // .25in margins) and the default gap 15pt (1.5em at 10pt), so each
    // column is (396pt - 15pt) / 2 wide.
    let step = p("q").x - p("p").x
    check(near(step, (396pt + 15pt) / 2), prefix + "expected columns 205.5pt apart, got " + repr(step))
  }

  // The exam and its key lay out identically: every spacing within a case
  // matches. (The cases themselves sit at different heights on the page.)
  for (a, b) in (("left", "a"), ("a", "b"), ("b", "c"), ("first", "second"), ("x", "y"), ("y", "z"), ("p", "q"), ("p", "r")) {
    let delta(prefix) = {
      let (pa, pb) = (pos(prefix + a), pos(prefix + b))
      (pb.x - pa.x, pb.y - pa.y)
    }
    let (kx, ky) = delta("key-")
    let (ex, ey) = delta("exam-")
    check(
      near(kx, ex) and near(ky, ey),
      a + " to " + b + ": the exam and its key should lay out the same",
    )
  }
}

// --- inside a question ---
// `choices` is block content inside a division's body; it must come through
// the exam's tokenizing and layout like any other.
#case(
  [In a question, the choices sit in the question's body.],
  exam(questions: [
    #question(points: 1)[
      Which is the capital of Canada?
      #choices[
        - Toronto
        + #probe("in-question")Ottawa
      ]
    ]
  ]),
)
#context assert.eq(query(<in-question>).len(), 1, message: "the choices in a question were lost")

// --- the gap between inline choices ---
// The distance from one inline choice's content to the next's is the
// content, the next bubble and its own gap, plus `gap`. Everything but `gap`
// is the same from one case to the next, so the difference between two
// cases is the difference between their gaps.
#let gapped(name, desc, ..gap) = case(
  desc,
  choices(inline: true, ..gap.named())[
    - #probe(name + "-1")a
    - #probe(name + "-2")a
  ],
)
#gapped("gap-1em", [`gap` sets the space between inline choices: `1em`,], gap: 1em)
#gapped("gap-3em", [`3em`,], gap: 3em)
#gapped("gap-default", [and `1.5em` by default.])
#gapped("gap-fr", [A fraction spreads the choices across the line.], gap: 1fr)

#context {
  let step(name) = pos(name + "-2").x - pos(name + "-1").x
  let near(a, b) = calc.abs((a - b).pt()) < 0.01
  let step_is(name, expected) = assert(
    near(step(name) - step("gap-1em"), expected),
    message: name + ": expected a gap " + repr(expected) + " wider than `1em`'s, got "
      + repr(step(name) - step("gap-1em")),
  )
  // `em`, so these follow the 10pt font size set above.
  step_is("gap-3em", 20pt)
  step_is("gap-default", 5pt)
  // `1fr` takes up what the line has left: the second choice ends up far
  // further along than any of the fixed gaps put it.
  assert(
    step("gap-fr") > step("gap-3em") + 100pt,
    message: "a `1fr` gap should spread the choices across the line",
  )
}

// In `columns`, `gap` is the space between the columns: doubling it from the
// default 15pt to 30pt (3em) narrows each column by 7.5pt and widens the
// gap by 15pt, moving the second column 7.5pt further along.
#case(
  [In `columns`, `gap` sets the space between the columns.],
  choices(columns: 2, gap: 3em)[
    - #probe("col-gap-1")a
    - #probe("col-gap-2")a
  ],
)
#context {
  let step = pos("col-gap-2").x - pos("col-gap-1").x
  assert(
    calc.abs((step - (396pt + 30pt) / 2).pt()) < 0.01,
    message: "expected columns 213pt apart with a 3em gap, got " + repr(step),
  )
}

// --- the gap between choices one per line ---
// One per line, `gap` is the space from one choice to the next below it.
// Every choice is one line of the same height, so the step from one to the
// next is that height plus the gap, and the difference between two cases'
// steps is the difference between their gaps.
#let stacked(name, desc, ..gap) = case(
  desc,
  choices(..gap.named())[
    - #probe(name + "-1")a
    + #probe(name + "-2")a
  ],
)
#stacked("vgap-0", [One per line, `gap` sets the space between choices: `0pt`,], gap: 0pt)
#stacked("vgap-2em", [`2em`,], gap: 2em)
#stacked("vgap-default", [and as close as the lines of a paragraph by default.])
// A choice of two paragraphs keeps them as far apart as the choices are, but
// an equation inside a choice keeps its own spacing.
#case(
  [A choice's own paragraphs are `gap` apart too.],
  choices(gap: 2em)[
    - #probe("vgap-par-1")first paragraph

      #probe("vgap-par-2")second paragraph
  ],
)
#case(
  [The same paragraphs outside `choices`, `2em` apart, for reference.],
  [
    #set par(spacing: 2em)
    #probe("vgap-ref-1")first paragraph

    #probe("vgap-ref-2")second paragraph
  ],
)

#context {
  let step(name) = pos(name + "-2").y - pos(name + "-1").y
  let near(a, b) = calc.abs((a - b).pt()) < 0.01
  let step_is(name, expected) = assert(
    near(step(name) - step("vgap-0"), expected),
    message: name + ": expected a gap " + repr(expected) + " wider than `0pt`'s, got "
      + repr(step(name) - step("vgap-0")),
  )
  step_is("vgap-2em", 20pt)
  // The default is the paragraph's line spacing: the choices sit as close as
  // the lines of a tight list.
  step_is("vgap-default", par.leading.to-absolute())
  assert(
    near(step("vgap-par"), step("vgap-ref")),
    message: "a choice's paragraphs should be `gap` apart, got " + repr(step("vgap-par")),
  )
}

// --- inline choices start a paragraph of their own ---
// Written on the line after a question's text, as the other layouts are,
// inline choices start below that text rather than running on from it.
#case(
  [Inline choices after a question start on a line of their own.],
  [
    #probe("before-inline")Which is prime?
    #choices(inline: true)[
      - #probe("after-inline")9
      + 11
    ]
  ],
)
#context {
  let (q, c) = (pos("before-inline"), pos("after-inline"))
  assert(c.y > q.y, message: "inline choices should start below the question, not run on from it")
  assert(
    calc.abs((c.x - q.x - measure(round-bubble()).width).pt()) < 0.01,
    message: "inline choices should start at the left margin",
  )
}

// --- labels inside the bubbles: `enumerate` ---
// `enumerate` numbers the bubbles as `enum`'s `numbering` would: `false` for
// none, `true` for the default "A", or a pattern or a function.
#assert.eq(choice_label(false, 0), none)
#assert.eq(choice_label(true, 0), [A])
#assert.eq(choice_label(true, 2), [C])
#assert.eq(choice_label("a", 2), [c])
#assert.eq(choice_label("1", 9), [10])
#assert.eq(choice_label("(i)", 3), [(iv)])
#assert.eq(choice_label(n => [#(n * 10)], 1), [20])

// A label takes no space, so it is observed directly: the numbering
// function below draws each number with a marker under the case's label, so
// the labels drawn, and their numbers, can be read back.
#let probing(name) = n => [#metadata(n)#label("enum-" + name)#n]
#let numbers(name) = query(label("enum-" + name)).map(m => m.value)
#let three = [
  - a
  + b
  - c
]

#case([`enumerate` labels each bubble, one per line,], choices(enumerate: probing("lines"), three))
#case([inline,], choices(enumerate: probing("inline"), inline: true, three))
#case([in columns,], choices(enumerate: probing("columns"), columns: 3, three))
#case([and square.], choices(enumerate: probing("square"), bubble: "square", three))
#case([Without `enumerate`, there are no labels.], [
  #show "x": it => [#metadata(none)<enum-stray>#it]
  #choices[- y
    - z]
])
#[
  // The global setting labels every `choices`, unless it says otherwise.
  #show: e.set_(config, choices-enumerate: probing("global"))
  #case([`config`'s `choices-enumerate` labels a `choices` given no `enumerate`;], choices(three))
  #case([`enumerate: false` turns it off for one;], choices(enumerate: false, [- p
    - q]))
  #case([and `enumerate` of its own replaces it.], choices(enumerate: probing("own"), three))
]
#context {
  for name in ("lines", "inline", "columns", "square", "global", "own") {
    assert.eq(numbers(name), (1, 2, 3), message: name + ": the bubbles should be labelled 1, 2, 3")
  }
  assert.eq(query(<enum-stray>).len(), 0, message: "no labels should be drawn without `enumerate`")
}
#context {
  // `true`, set globally, is the default pattern.
  let a = measure([#show: e.set_(config, choices-enumerate: true); #choices(inline: true, three)])
  let b = measure(choices(inline: true, enumerate: "A", three))
  assert.eq(a, b, message: "`choices-enumerate: true` should label as \"A\" does")
}

// Labels take no space: a labelled list lays out exactly as an unlabelled
// one, in every layout, on the exam and on the key.
#for show-sol in (false, true) [
  #show: e.set_(config, show-solutions: show-sol)
  #context for (layout, args) in (
    ("one per line", (:)),
    ("inline", (inline: true)),
    ("columns", (columns: 2)),
  ) {
    assert.eq(
      measure(choices(enumerate: "(iii)", ..args, three), width: 5in),
      measure(choices(..args, three), width: 5in),
      message: layout + ": labels should not change the layout (solutions " + repr(show-sol) + ")",
    )
  }
]

// A label fits inside the ring a correct bubble gets on the key: its corners
// clear the inside of a round ring, the tightest fit. A long one is set
// smaller until they do. It is sized to fit the ring on the exam too, where
// no ring is drawn, so it is the same size on both. And the ring itself sits
// inside the bubble's outline, clear of it.
#context {
  let size = 1em.to-absolute()
  let thickness = .1em.to-absolute()
  let ring = ring_geometry(size, thickness)
  // The ring's outer edge stays inside the outline's inner edge.
  assert(
    ring.size / 2 + ring.thickness / 2 < size / 2 - thickness / 2,
    message: "the ring should sit inside the outline, clear of it",
  )
  // Fitted to the room inside the ring, a label's corners clear it.
  for label in ([A], [W], [g], [12], [(a)], [(viii)], [MMXXVI]) {
    let m = measure(label_mark(1em, ring.room, label, auto))
    let reach = calc.sqrt(calc.pow(m.width.pt() / 2, 2) + calc.pow(m.height.pt() / 2, 2))
    assert(
      reach <= ring.room.pt() / 2 + 0.01,
      message: "the label " + repr(label) + " should fit inside the ring, but its corners reach "
        + repr(reach) + "pt from its center, past " + repr(ring.room.pt() / 2) + "pt",
    )
  }
  // Given a `limit` (as a bubble gives it, the inside of its outline), a
  // label that would be set below the smallest legible size grows toward it,
  // reaching past the ring if it must, but never past `limit`: it ends up at
  // that size, or as large as `limit` allows.
  let limit = size * (1 - 2 * _RING_GAP) - thickness
  for label in ([A], [W], [g], [12], [(a)], [(viii)], [MMXXVI]) {
    let m = measure(label_mark(1em, ring.room, label, auto, limit: limit))
    let reach = calc.sqrt(calc.pow(m.width.pt() / 2, 2) + calc.pow(m.height.pt() / 2, 2))
    assert(
      reach <= limit.pt() / 2 + 0.01,
      message: "the label " + repr(label) + " should stay inside the outline, but its corners reach "
        + repr(reach) + "pt from its center, past " + repr(limit.pt() / 2) + "pt",
    )
    let least = measure(text(
      size: _LABEL_MIN * size,
      font: DEFAULT_BUBBLE_LABEL_FONT,
      top-edge: "bounds",
      bottom-edge: "bounds",
      label,
    ))
    assert(
      m.height >= least.height - 0.01pt or reach >= limit.pt() / 2 - 0.01,
      message: "the label " + repr(label) + " should be at least " + repr(least.height)
        + " tall, or reach the outline, got " + repr(m.height) + " reaching " + repr(reach) + "pt",
    )
  }
}

// On the key, a correct labelled bubble is filled in like any other —
// outlined in the solution color over the solution background — with its
// label, in the solution color, in place of the check mark, and a thinner
// ring inside the outline; an unlabelled one is checked. Every label is
// regular weight, in the label font, and only a correct one on the key is
// ringed, so on the exam every label reads alike: the numbering function
// below reads back the text style each label is set in, and a show rule
// records the shapes drawn — a ring is told from a bubble by being unfilled
// and drawn in the solution color.
#let style_probe(name) = n => [#context [#metadata((
      fill: text.fill,
      weight: text.weight,
      font: text.font,
    ))#label("style-of-" + name)]#n]
#let font_names(f) = (if type(f) == str { (f,) } else { f }).map(lower)
#let is_ring(shape, colors) = shape.fill == none and stroke(shape.stroke).paint == colors.color
#for show-sol in (false, true) [
  #show: e.set_(config, show-solutions: show-sol)
  #let mode = if show-sol { "key" } else { "exam" }
  #let drawn_of(name, body) = {
    show circle: it => [#metadata((fill: it.fill, stroke: it.stroke))#label("drawn-of-" + name)#it]
    show "✓": it => [#metadata(none)#label("check-of-" + name)#it]
    body
  }
  #case(
    [The #mode, labelled: a correct bubble is filled in and ringed, its label in place of the check mark;],
    drawn_of(mode + "-labelled", choices(enumerate: style_probe(mode), three)),
  )
  #case(
    [the #mode, unlabelled: a correct bubble is checked.],
    drawn_of(mode + "-plain", choices(three)),
  )
  #e.get(get => context {
    let colors = solution_colors(get)
    let shapes(name) = query(label("drawn-of-" + mode + "-" + name)).map(m => m.value)
    let rings(name) = shapes(name).filter(d => is_ring(d, colors))
    let drawn(name) = shapes(name).filter(d => not is_ring(d, colors))
    let paints(name) = drawn(name).map(d => stroke(d.stroke).paint)
    let checks(name) = query(label("check-of-" + mode + "-" + name)).len()
    let styles = query(label("style-of-" + mode)).map(m => m.value)
    if show-sol {
      // Only the second choice, `+ b`, is correct.
      for name in ("labelled", "plain") {
        assert.eq(
          drawn(name).map(d => d.fill),
          (none, colors.background, none),
          message: mode + ", " + name + ": only the correct bubble should be filled in, over the solution background",
        )
        assert.eq(
          paints(name).at(1),
          colors.color,
          message: mode + ", " + name + ": a correct bubble should be outlined in the solution color",
        )
      }
      assert.eq(checks("labelled"), 0, message: "a labelled bubble should have no check mark")
      assert.eq(checks("plain"), 1, message: "an unlabelled correct bubble should be checked")
      assert.eq(
        styles.map(s => s.fill),
        (black, colors.color, black),
        message: "a correct bubble's label should be in the solution color, the others in the text's",
      )
      assert.eq(rings("labelled").len(), 1, message: "only the correct labelled bubble should be ringed")
      // Thinner than the outline it sits inside.
      assert(
        stroke(rings("labelled").first().stroke).thickness.to-absolute()
          < stroke(drawn("labelled").at(1).stroke).thickness.to-absolute(),
        message: "the ring should be thinner than the outline",
      )
    } else {
      // On the exam nothing is filled in, checked, colored, or ringed.
      for name in ("labelled", "plain") {
        assert.eq(drawn(name).map(d => d.fill), (none, none, none), message: mode + ": no bubble should be filled in")
      }
      assert.eq(checks("plain"), 0, message: "the exam should show no check mark")
      assert.eq(styles.map(s => s.fill), (black, black, black), message: "the exam's labels are all in the text color")
      assert.eq(rings("labelled").len(), 0, message: "the exam should ring no bubble")
    }
    assert.eq(rings("plain").len(), 0, message: mode + ": an unlabelled bubble is checked, not ringed")
    for s in styles {
      assert(
        s.weight in ("regular", 400),
        message: mode + ": every label should be regular weight, got " + repr(s.weight),
      )
      assert(
        "dejavu sans mono" in font_names(s.font),
        message: mode + ": a label should be set in the bundled mono font by default, got " + repr(s.font),
      )
    }
  })
]

// The ring takes no space, so a labelled list lays out the same on the exam
// and on the key.
#context {
  let at(show-sol) = measure([
    #show: e.set_(config, show-solutions: show-sol)
    #choices(enumerate: true, inline: true, three)
  ])
  assert.eq(at(true), at(false), message: "ringing a correct bubble should not change the layout")
}

// `config`'s `bubble-label-font` sets the font every label is set in.
#[
  #show: e.set_(config, bubble-label-font: "Libertinus Mono")
  #case(
    [`bubble-label-font: "Libertinus Mono"` sets the labels in it.],
    choices(enumerate: style_probe("own-font"), inline: true, three),
  )
]
#context {
  let fonts = query(<style-of-own-font>).map(m => m.value.font)
  assert.eq(fonts.len(), 3, message: "expected three labels")
  for f in fonts {
    assert(
      "libertinus mono" in font_names(f),
      message: "a label should be set in `bubble-label-font`, got " + repr(f),
    )
  }
}

// --- what `enumerate` draws, setting by setting ---
// The choices below are left empty, so the only text in each list is its
// labels: a show rule records every piece of text drawn, in order, and that
// is compared with what the setting should number the bubbles with.
#let EMPTY = ([], [], [], [])
#let labels_drawn(name, body) = {
  show regex("\S+"): it => [#metadata(it.text)#label("labels-" + name)#it]
  body
}
#let labels_of(name) = query(label("labels-" + name)).map(m => m.value)
#let ENUMERATE_CASES = (
  // (name, description, `enumerate`, the labels expected)
  ("true", [`true`: capital letters], true, ("A", "B", "C", "D")),
  ("a", [`"a"`: lowercase letters], "a", ("a", "b", "c", "d")),
  ("1", [`"1"`: numbers], "1", ("1", "2", "3", "4")),
  ("i", [`"i"`: lowercase roman numerals], "i", ("i", "ii", "iii", "iv")),
  ("I.", [`"I."`: a pattern with a suffix], "I.", ("I.", "II.", "III.", "IV.")),
  ("(a)", [`"(a)"`: a pattern with a prefix and a suffix], "(a)", ("(a)", "(b)", "(c)", "(d)")),
  ("*", [`"*"`: symbols], "*", ("*", "†", "‡", "§")),
  ("times-ten", [A function: `n => str(10 * n)`], n => str(10 * n), ("10", "20", "30", "40")),
  (
    "paren",
    [A function built on `numbering`: `n => numbering("a", n) + ")"`],
    n => numbering("a", n) + ")",
    ("a)", "b)", "c)", "d)"),
  ),
  (
    "compass",
    [A function that labels by name: `n => ("N", "E", "S", "W").at(n - 1)`],
    n => ("N", "E", "S", "W").at(n - 1),
    ("N", "E", "S", "W"),
  ),
  ("array", [An array, one label per choice: `("N", "E", "S", "W")`], ("N", "E", "S", "W"), ("N", "E", "S", "W")),
  (
    "array-long",
    [An array longer than the choices, its extra labels unused: `("w", "x", "y", "z", "q")`],
    ("w", "x", "y", "z", "q"),
    ("w", "x", "y", "z"),
  ),
  ("array-content", [An array of content: `([α], [β], "c", [δ])`], ([α], [β], "c", [δ]), ("α", "β", "c", "δ")),
)
#for (name, desc, setting, _) in ENUMERATE_CASES {
  case(desc, labels_drawn(name, choices(enumerate: setting, inline: true, EMPTY)))
}
// Past nine, numbers take two digits, and are set smaller to fit.
#case(
  [`"1"` past nine: two digits, set smaller to fit.],
  labels_drawn("two-digit", choices(enumerate: "1", columns: 6, ([],) * 12)),
)
// A function from the global setting labels every list it reaches.
#[
  #show: e.set_(config, choices-enumerate: n => str(n * n))
  #case(
    [A function set globally: `choices-enumerate: n => str(n * n)`.],
    labels_drawn("global-fn", choices(inline: true, EMPTY)),
  )
]
// A function's labels are the same on the exam and the key, where the
// correct ones are also ringed.
#[
  #show: e.set_(config, show-solutions: true)
  #case(
    [A function on the key: the correct bubbles (20 and 40) are ringed.],
    {
      // A ring is the one shape drawn unfilled in a color of its own.
      show circle: it => if it.fill == none and stroke(it.stroke).paint != auto [#metadata(none)<fn-key-ring>#it] else { it }
      labels_drawn("fn-key", choices(enumerate: n => str(10 * n), inline: true, EMPTY, correct: (1, 3)))
    },
  )
]
// A function may return content, not only a string: here a letter set in
// italics.
#case(
  [A function returning content: `n => emph(numbering("A", n))`.],
  labels_drawn("content-fn", choices(enumerate: n => emph(numbering("A", n)), inline: true, EMPTY)),
)
// A function may leave some bubbles without a label, by giving empty
// content: they are drawn bare, on the exam and on the key, where an empty
// label has nothing to be fitted to.
#for key in (false, true) {
  show: e.set_(config, show-solutions: key)
  case(
    [A function giving empty labels for the odd choices#if key [, on the key].],
    choices(enumerate: n => if calc.odd(n) [] else { str(n) }, inline: true, EMPTY, correct: 0),
  )
}

#context {
  for (name, _, _, expected) in ENUMERATE_CASES {
    assert.eq(labels_of(name), expected, message: "`enumerate` " + name + ": wrong labels drawn")
  }
  assert.eq(
    labels_of("two-digit"),
    range(1, 13).map(str),
    message: "`\"1\"` should number twelve bubbles 1 to 12",
  )
  assert.eq(labels_of("global-fn"), ("1", "4", "9", "16"), message: "a global function should label the bubbles")
  assert.eq(labels_of("fn-key"), ("10", "20", "30", "40"), message: "a function's labels should be drawn on the key too")
  assert.eq(query(<fn-key-ring>).len(), 2, message: "the two correct bubbles should be ringed on the key")
  assert.eq(labels_of("content-fn"), ("A", "B", "C", "D"), message: "a function returning content should be drawn")
}

// --- labels in columns run left to right, then top to bottom ---
// Each label drawn is recorded where it lands. In `columns: n`, the label at
// index `i` (A, B, C, …) must sit in row `i / n` and column `i mod n`: the
// labels in a row share a line and run left to right, and the next row
// starts back under the first column. Seven choices leave a short last row.
#let placed_labels(name, body) = {
  show regex("\S+"): it => [#metadata(it.text)#label("placed-" + name)#it]
  body
}
#for n in (2, 3) {
  case(
    [`columns: #n`: the labels run left to right along each row, then on to the next.],
    placed_labels("columns-" + str(n), choices(enumerate: true, columns: n, ([],) * 7)),
  )
}
#context for n in (2, 3) {
  let found = query(label("placed-columns-" + str(n)))
  let letters = found.map(m => m.value)
  assert.eq(letters, ("A", "B", "C", "D", "E", "F", "G"), message: str(n) + " columns: wrong labels")
  let pos = found.map(m => m.location().position())
  // Each label is centered on its own ink, so its text starts a hair off
  // from its neighbors' (a round `C` reaches a little higher and wider than
  // an `A`): within half a point, against rows some 18pt and columns some
  // 200pt apart.
  let near(a, b) = calc.abs((a - b).pt()) < 0.5
  for (i, p) in pos.enumerate() {
    let (row, col) = (calc.quo(i, n), calc.rem(i, n))
    let first = pos.at(row * n)
    let above = pos.at(col)
    assert(
      near(p.y, first.y),
      message: str(n) + " columns: " + letters.at(i) + " should share row " + str(row + 1) + " with " + letters.at(row * n),
    )
    assert(
      near(p.x, above.x),
      message: str(n) + " columns: " + letters.at(i) + " should sit in column " + str(col + 1) + ", under " + letters.at(col),
    )
    if col > 0 {
      assert(
        p.x > pos.at(i - 1).x,
        message: str(n) + " columns: " + letters.at(i) + " should be to the right of " + letters.at(i - 1),
      )
    } else if row > 0 {
      assert(
        p.y > pos.at(i - n).y,
        message: str(n) + " columns: " + letters.at(i) + " should start a row below " + letters.at(i - n),
      )
    }
  }
}

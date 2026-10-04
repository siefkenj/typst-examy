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
#import "/src/elements/bubble.typ": bubble as round-bubble, square_bubble
#import "/src/elements/choices.typ": choices_shape, correct_indices, parse_choices, resolve_choices
#import "/src/config.typ": solution_colors

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

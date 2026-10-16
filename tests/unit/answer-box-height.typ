// `answer-box` height when none is given: a box with something in it — a
// prompt, a list of choices — grows to fit it, while a box that is blank on
// the exam (empty, or holding only its solution) takes `default_height`, so
// the student has room to write. Also: the `solution:` argument appears only
// on the answer key; with no height given, solutions take no height, so the
// key lays out exactly like the exam; and any explicit height, even `auto`,
// opts out of that, so the box holds its solutions.
//
// Every box checked is also drawn, under a description of what is expected
// of it, so the rendered test reads as its own documentation: the exam
// (solutions off) first, then the answer key (solutions on).
#import "/src/lib.typ": *

#set page(width: 6in, height: auto, margin: .25in)
#set text(size: 10pt)
#show: e.prepare()

// The text column: 6in less two .25in margins.
#let COLUMN = 5.5in
#let DEFAULT = 2cm
// `DEFAULT` as the descriptions print it (`repr` would give it in points).
#let DEFAULT_TEXT = "2cm"
#let near(a, b) = calc.abs((a - b).pt()) < 0.01

// Each case is printed under its description: a rule separates the cases
// and the description sits against the right margin, clear of the sample.
#let case(desc, body) = {
  block(above: 12pt, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  align(right, emph(desc))
  block(body)
}

// Draw the box `b` under `desc` — `inline` sets it in a sentence, as a blank
// is — and check its height: exactly `equals`, or under `under`, or over
// `over`. Each is a length, or a function giving one, for an expectation
// that has to be measured itself. The box is measured as drawn, in the
// column it is drawn in, and with whatever show-solutions setting is in
// force there.
#let check(desc, b, inline: false, equals: none, under: none, over: none) = {
  case(desc, if inline [The answer is #b here.] else { b })
  context {
    let h = measure(b, width: COLUMN).height
    let resolve(x) = (if type(x) == function { x() } else { x }).to-absolute()
    let say(expected) = desc + ": expected " + expected + ", got " + repr(h)
    if equals != none { assert(near(h, resolve(equals)), message: say(repr(resolve(equals)))) }
    if under != none { assert(h < resolve(under), message: say("under " + repr(resolve(under)))) }
    if over != none { assert(h > resolve(over), message: say("over " + repr(resolve(over)))) }
  }
}

// The height of a box exactly fitting `body`: the body, plus the box's own
// 5pt padding above and below. Measured, so it needs context.
#let fitting(body) = () => measure(block(width: COLUMN - 10pt, body)).height + 10pt

#let five_choices = choices(bubble: "square")[
  + $NN$
  + $ZZ$
  + $RR$
  - ${1, 2, 3}$
  - None of these
]

// The bodies that leave a box blank on the exam, so it takes the default
// height for the student to write in.
#let BLANKS = (
  ("Empty", []),
  ("Only whitespace", [ ]),
  (
    "Only blank lines",
    [

    ],
  ),
  ("Only a solution", [#solution[An answer.]]),
  (
    "Only a solution, set off by blank lines",
    [

      #solution[An answer.]

    ],
  ),
  ("Only a styled solution", [#set text(red); #solution[An answer.]]),
)

// Every case, under the show-solutions setting in force: what makes a box
// blank or not is what the exam shows, so the exam and the key must agree.
#let cases(mode) = {
  heading(level: 2, mode)

  // --- blank on the exam: the fixed default height ---
  // Each blank body in the three shapes a box comes in: full width (a block
  // on its own), inline at the default width (a blank in a sentence), and
  // inline at a width of its own.
  for (desc, body) in BLANKS {
    check(
      desc + ", full width: " + DEFAULT_TEXT + " tall.",
      answer-box(width: 100%, body),
      equals: DEFAULT,
    )
    check(
      desc + ", inline: " + DEFAULT_TEXT + " tall.",
      answer-box(body),
      inline: true,
      equals: DEFAULT,
    )
    check(
      desc + ", inline at 3cm wide: " + DEFAULT_TEXT + " tall.",
      answer-box(width: 3cm, body),
      inline: true,
      equals: DEFAULT,
    )
  }
  // A long solution does not stretch the box: it keeps its height, so the
  // key matches the exam, and the solution runs past it.
  check(
    "Only a solution longer than the box: still " + DEFAULT_TEXT + " tall.",
    answer-box(width: 100%)[#solution[#lorem(90)]],
    equals: DEFAULT,
  )
  v(1.2cm)
  // `default_height` is honored for a blank box.
  check(
    "Empty, with `default_height: 3cm`: 3cm tall.",
    answer-box(width: 100%, default_height: 3cm)[],
    equals: 3cm,
  )

  // --- with content: sized to fit it ---
  check(
    "Five choices: grows past " + DEFAULT_TEXT + " to fit them.",
    answer-box(width: 100%, five_choices),
    equals: fitting(five_choices),
  )
  // Every layout of `choices` is a block the box can see, so a short list in
  // columns fits too, rather than taking the default height.
  let two_columns = choices(columns: 2)[- a
    - b]
  check(
    "Two choices in columns: fits them, under " + DEFAULT_TEXT + ".",
    answer-box(width: 100%, two_columns),
    equals: fitting(two_columns),
  )
  // A short prompt makes a short box, not a default-height one, whatever
  // its shape.
  check(
    "A line of text, full width: one line tall.",
    answer-box(width: 100%)[Some words.],
    under: DEFAULT,
  )
  check("A formula, inline: one line tall.", answer-box[$x$], inline: true, under: DEFAULT)
  check(
    "A formula, inline at 3cm wide: one line tall.",
    answer-box(width: 3cm)[$x$],
    inline: true,
    under: DEFAULT,
  )
  // A block-level prompt is content too, as is one in a paragraph after a
  // solution's.
  check(
    "A centered prompt: one line tall.",
    answer-box(width: 100%)[#align(center)[Some words.]],
    under: DEFAULT,
  )
  // A solution wrapped in another element cannot be seen through, so it
  // counts as content: the box fits it rather than taking the default.
  check(
    "A centered solution: sized to fit, not " + DEFAULT_TEXT + ".",
    answer-box(width: 100%)[#align(center)[#solution[42]]],
    under: DEFAULT,
  )
  check(
    "A solution, then a list: sized to fit the list.",
    answer-box(width: 100%)[#solution[An answer.]

      - An item.
    ],
    under: DEFAULT,
  )
  // A prompt beside a solution is content: the box fits the prompt.
  check(
    "A prompt with a solution: sized to fit.",
    answer-box(width: 100%)[$x =$ #solution[4]],
    under: DEFAULT,
  )

  // --- a height given explicitly is used as given ---
  check(
    "Five choices, `height: 3cm`: 3cm tall.",
    answer-box(width: 100%, height: 3cm, five_choices),
    equals: 3cm,
  )
  // `auto` always fits the content, even none.
  check("Empty, `height: auto`: fits nothing.", answer-box(width: 100%, height: auto)[], under: 1cm)
  check(
    "Five choices, `height: auto`: fits them.",
    answer-box(width: 100%, height: auto, five_choices),
    equals: fitting(five_choices),
  )
}

#[
  #show: e.set_(config, show-solutions: false)
  #cases[Exam (solutions off)]
]
#pagebreak()
#[
  #show: e.set_(config, show-solutions: true)
  #cases[Answer key (solutions on)]
]

// --- the `solution:` argument ---
#heading(level: 2)[The `solution:` argument]
// Shown only on the answer key: with solutions off it must not reach the
// page at all.
#[
  #show: e.set_(config, show-solutions: false)
  #check(
    "Solutions off: the `solution:` argument (42) is not shown.",
    answer-box(width: 100%, solution: [#metadata(none)<leaked-solution>42])[$x =$],
  )
]
#context assert.eq(
  query(<leaked-solution>).len(),
  0,
  message: "the `solution:` argument must not appear with solutions off",
)
#[
  #show: e.set_(config, show-solutions: true)
  #let without = answer-box(width: 100%)[$x =$]
  #check("Solutions on, without a `solution:` argument, for comparison.", without)
  // With no height given, it takes none: the box keeps the exam's height.
  #check(
    "Solutions on: the `solution:` argument (42) is shown, and the box keeps its height.",
    answer-box(width: 100%, solution: [#metadata(none)<shown-solution>42])[$x =$],
    equals: () => measure(without, width: COLUMN).height,
  )
  // With `height: auto`, the box grows to hold it.
  #check(
    "Solutions on, `height: auto`: the box grows to hold the `solution:` argument.",
    answer-box(width: 100%, height: auto, solution: [42])[$x =$],
    over: () => measure(without, width: COLUMN).height + 5pt,
  )
  // In a box of fixed height, it fills the rest, and the box keeps its height.
  #check(
    "Solutions on, `height: 3cm`: the `solution:` argument fills the rest; 3cm tall.",
    answer-box(width: 100%, height: 3cm, solution: [42])[$x =$],
    equals: 3cm,
  )
]
#context assert.eq(
  query(<shown-solution>).len(),
  1,
  message: "the `solution:` argument should appear on the key",
)

// --- with no height given, solutions take no height ---
#pagebreak()
#heading(level: 2)[With no height given, the a solutions key should have the same layout as when
  solutions aren't shown.]
// Each box is drawn twice, the exam on the left and the key on the right,
// and the two must be the same height: a solution takes no height, whatever
// the box holds and wherever the solution sits in it. An explicit height,
// even `auto`, opts out: then the key's box grows to hold its solutions.
#let HALF = (COLUMN - 12pt) / 2
#let in_mode(key, b) = {
  show: e.set_(config, show-solutions: key)
  b
}
#let exam_and_key(desc, b, same: true) = {
  case(desc, grid(
    columns: (HALF, HALF),
    column-gutter: 12pt,
    in_mode(false, b), in_mode(true, b),
  ))
  context {
    let (exam, key) = (false, true).map(k => measure(in_mode(k, b), width: HALF).height)
    let say(expected) = (
      desc + ": expected the key " + expected + ", got exam " + repr(exam) + ", key " + repr(key)
    )
    if same { assert(near(exam, key), message: say("as tall as the exam")) } else {
      assert(key > exam + 1pt, message: say("taller than the exam"))
    }
  }
}

#exam_and_key(
  "A prompt and a short `solution:` argument.",
  answer-box(width: 100%, solution: [$x = 4$])[Solve $2x = 8$.],
)
#exam_and_key(
  "A prompt and a long `solution:` argument: it hangs out of the box on the key.",
  answer-box(width: 100%, solution: lorem(30))[Explain your answer.],
)
#v(2.4cm)
#exam_and_key(
  "A prompt, then a solution in its own paragraph.",
  answer-box(width: 100%)[Why does it converge?

    #solution[By the ratio test.]
  ],
)
#v(.6cm)
#exam_and_key(
  "A solution between two prompts: drawn over the prompt after it.",
  answer-box(width: 100%)[(i) Find $f'(x)$.

    #solution[$f'(x) = 2x$]

    (ii) Is $f$ increasing?
  ],
)
#exam_and_key("An inline solution at the end of a prompt.", answer-box(width: 100%)[$x =$
  #solution[4]])
// Its padding takes no height. (Content taller than the text still raises
// its line, as it would anywhere: even an inline equation does, slightly,
// in a line of plain text.)
#exam_and_key(
  "An inline solution mid-sentence does not make its line taller.",
  answer-box(width: 100%)[The capital is #solution[Paris], of course.],
)
// Written inline after a label, but of several paragraphs: drawn as a block,
// so it takes no height either.
#exam_and_key(
  "A label, then a solution of two paragraphs on the next line.",
  answer-box(width: 100%)[*Proof:*
    #solution[Notice that $-1 in A$.

      But $-1 in.not B$.]
  ],
)
#v(1cm)
#exam_and_key(
  "A label, then a solution holding a display equation.",
  answer-box(width: 100%)[*Proof:* #solution[We have
      $ x = 4. $]],
)
#v(1cm)
// The words of a long inline solution have to go somewhere: they wrap with
// the text around them, so the paragraph gets longer, though no line gets
// taller.
#exam_and_key(
  "A long inline solution wraps with the prompt, so the key is longer.",
  answer-box(width: 100%)[The limit is #solution[#lorem(12)], so it converges.],
  same: false,
)
// An explicit height opts out.
#exam_and_key(
  "`height: auto`: the box grows to hold the `solution:` argument.",
  answer-box(width: 100%, height: auto, solution: [$x = 4$])[Solve $2x = 8$.],
  same: false,
)
#exam_and_key(
  "`height: auto`: the box grows to hold a solution in its own paragraph.",
  answer-box(width: 100%, height: auto)[Why does it converge?

    #solution[By the ratio test.]
  ],
  same: false,
)
// A width of its own does not lift a solution mid-sentence out of its line:
// it stays a box in the line, which it makes no taller.
#exam_and_key(
  "An inline solution with a width of its own stays in its line.",
  answer-box(width: 100%)[The capital is #solution(width: 1.5cm)[Paris], of course.],
)
#exam_and_key(
  "An unboxed solution in its own paragraph takes no height either.",
  answer-box(width: 100%)[Prompt.

    #solution(boxed: false)[An answer.

      Second para.]
  ],
)
#v(1.2cm)
#exam_and_key(
  "An unboxed solution mid-sentence.",
  answer-box(width: 100%)[The capital is #solution(boxed: false)[Paris], of course.],
)
// Inside an `align` the box cannot see the solution, but a display equation
// sets it apart all the same: it is placed, and keeps its fill.
#exam_and_key(
  "A display-equation solution inside `align`.",
  answer-box(width: 100%)[Prompt. #align(center)[#solution[$ x = 4 $]] Then more.],
)
#v(.6cm)
#[
  #show: e.set_(config, show-solutions: true)
  #let fills = state("fills", ())
  #show block: it => {
    if it.fill != none { fills.update(f => f + (it.fill,)) }
    it
  }
  #answer-box(width: 100%)[Prompt. #align(center)[#solution[$ x = 4 $]] Then more.]
  #context assert(
    fills.get().len() > 0,
    message: "a display-equation solution inside `align` should be drawn with its background fill",
  )
]
#v(.6cm)
// A `context` expression may show nothing on the exam (a solution only the
// key shows, through `e.get`), so the box keeps `default_height` at least,
// and grows only for more than that.
#for key in (false, true) {
  show: e.set_(config, show-solutions: key)
  check(
    "Only an `e.get` showing a solution on the key: " + DEFAULT_TEXT + ", exam and key alike.",
    answer-box(width: 100%)[#e.get(get => if show-solutions(get) [The answer.])],
    equals: DEFAULT,
  )
}
#check(
  "Only a `context` showing more than fits in " + DEFAULT_TEXT + ": grows to fit it.",
  answer-box(width: 100%)[#context lorem(120)],
  over: DEFAULT + 1cm,
)
// A box decides for its own solutions, whatever box it sits in.
#exam_and_key(
  "A `height: auto` box inside a box with no height holds its solution.",
  answer-box(width: 100%)[Outer prompt. #answer-box(width: 100%, height: auto)[Inner.

      #solution[Grows.]
    ]],
  same: false,
)

// --- where a solution that takes no height is drawn ---
// It is drawn exactly where it would be if it took space. Each row is one box
// drawn twice, both on the answer key: on the left with no height given, so
// its solution takes none; on the right with `height: auto`, so its solution
// takes space as usual, which is the reference. The solution must start the
// same distance below the top of the box on both sides; all that differs is
// that the left box does not grow, and what follows the solution moves up
// under it. Typst spaces a solution differently depending on what is around
// it, so there is a row for each case. Pinned by a marker at the top of each
// box and one at the start of each solution.
#let drawn_at(name, height, body, sol) = answer-box(width: 100%, height: height)[
  #metadata(none)#label("top-" + name)#body(solution[#metadata(none)#label("sol-" + name)#sol])
]
#let arg_at(name, height) = answer-box(
  width: 100%,
  height: height,
  solution: [#metadata(none)#label("sol-arg-" + name)$x = 4$],
)[#metadata(none)#label("top-arg-" + name)Solve $2x = 8$.]
#let POSITIONS = (
  (
    name: "last",
    desc: [Last in the box, after text],
    box: h => drawn_at(
      "last-" + h,
      if h == "none" { none } else { auto },
      p => [Why does it converge?

        #p
      ],
      [By the ratio test.],
    ),
  ),
  (
    name: "middle",
    desc: [Between two prompts: on the left, (ii) moves up under it],
    box: h => drawn_at(
      "middle-" + h,
      if h == "none" { none } else { auto },
      p => [(i) Find $f'(x)$.

        #p

        (ii) Is $f$ increasing?
      ],
      [$f'(x) = 2x$],
    ),
  ),
  (
    name: "after-list",
    desc: [Last in the box, after a list (a block, which is spaced differently from text)],
    box: h => drawn_at(
      "after-list-" + h,
      if h == "none" { none } else { auto },
      p => [
        - An item.

        #p
      ],
      [An answer.],
    ),
  ),
  (
    name: "after-block",
    desc: [Last in the box, after a block (spaced by the document's block spacing)],
    box: h => drawn_at(
      "after-block-" + h,
      if h == "none" { none } else { auto },
      p => [
        #block(width: 100%, height: 5mm, stroke: .5pt + gray)

        #p
      ],
      [An answer.],
    ),
  ),
  (
    name: "arg",
    desc: [The `solution:` argument],
    box: h => arg_at(h, if h == "none" { none } else { auto }),
  ),
)
#pagebreak()
#heading(level: 2)[Setting height to auto will cause solutions to take up space]
#[
  #show: e.set_(config, show-solutions: true)
  #grid(
    columns: (HALF, HALF),
    column-gutter: 12pt,
    row-gutter: 6pt,
    strong[No height given: \ the solution takes none],
    strong[`height: auto`: \ the solution takes space (reference)],
    ..POSITIONS
      .map(p => (
        grid.cell(
          colspan: 2,
          block(above: 10pt, line(length: 100%, stroke: .5pt + gray)) + emph(p.desc),
        ),
        (p.box)("none"),
        (p.box)("auto"),
        // Room for a solution that hangs out of the box on the left.
        grid.cell(colspan: 2, v(.8cm)),
      ))
      .flatten(),
  )
]
#context for name in ("last", "middle", "after-list", "after-block", "arg") {
  let offset(h) = {
    let y(which) = query(label(which + "-" + name + "-" + h)).first().location().position().y
    y("sol") - y("top")
  }
  assert(
    calc.abs((offset("none") - offset("auto")).pt()) < 0.5,
    message: name
      + ": a solution taking no height should be drawn "
      + repr(offset("auto"))
      + " below the start of its box, as with `height: auto`, got "
      + repr(offset("none")),
  )
}

// Outside an answer box, a solution is drawn as always, and takes space.
#[
  #show: e.set_(config, show-solutions: true)
  #context assert(
    measure(solution[An answer.]).height > measure[An answer.].height + 5pt,
    message: "a solution outside an answer box should be boxed, and take its padding's height",
  )
]

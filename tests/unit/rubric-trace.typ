// A rubric item's `trace`: `auto` follows `config`'s `rubric-trace` (whose
// `auto` traces the rubrics in a margin and not those at the `"end"`);
// `true` or `false` decides for that item alone. An item given `trace: true`
// is traced even where its question's other rubrics are not, so its
// division sets up its leaders (`opts_of`), from what `mark_rubrics` finds.
// A `config` rule inside the exam sets `rubric-trace` for the questions in
// its scope alone.
#import "/src/lib.typ": *
#import "/src/rubric.typ": is_traced
#import "/src/render.typ": mark_rubrics, opts_of
#import "/src/config.typ": DEFAULT_EXAM_OPTIONS
#import "/tests/record.typ": cases, rule

#set page(width: 7in, height: auto, margin: (left: .5in, right: 2.2in, y: .4in))
#set text(size: 10pt)
#show: e.prepare()

// --- an item's own `trace` over its division's ---
#let ITEMS = (
  (auto, true, true),
  (auto, false, false),
  (true, false, true),
  (true, true, true),
  (false, true, false),
  (false, false, false),
)
#for (own, division, traced) in ITEMS {
  assert.eq(is_traced((trace: own), division), traced, message: repr((own, division)))
}
// A rubric marker from before `trace` (no key) follows its division.
#assert.eq(is_traced((:), true), true)
#assert.eq(is_traced((:), false), false)

#rule[An item's `trace`, and its division's: whether the item is traced]
#cases(
  ([item's `trace`], [division's], [traced]),
  ..ITEMS.map(((o, d, t)) => (raw(repr(o)), raw(repr(d)), raw(repr(t)))),
)

// --- `trace: true` in a division's text marks the division ---
#let items(body) = (
  (kind: "division", address: (0,), parent: none, fields: (rubric: none)),
  (kind: "chunk", body: body, parent: 0),
)
#let marked(body) = mark_rubrics(items(body)).first().first().at("rubric_trace", default: false)
#assert.eq(marked[Text #rubric(points: 1)[A]], false)
#assert.eq(marked[Text #rubric(points: 1, trace: false)[A]], false)
#assert.eq(marked[Text #rubric(points: 1)[A] #rubric(points: 1, trace: true)[B]], true)
#assert.eq(
  marked[#solution[Text #rubric(points: 1, trace: true)[A]]],
  true,
  message: "in a solution",
)

// --- and that division sets its leaders up, whatever its rubrics are ---
#{
  let opts = DEFAULT_EXAM_OPTIONS
  opts.rubric.drawn = true
  opts.rubric.trace = false
  assert.eq(opts_of((own: none), opts).rubric.traced, false)
  assert.eq(opts_of((rubric_trace: true), opts).rubric.traced, true)
  assert.eq(opts_of((own: (rubric-position: "end"), rubric_trace: true), opts).rubric.traced, true)
  // A `config` rule around the division (in its `own`, see `localize`).
  opts.rubric.trace = true
  assert.eq(opts_of((own: (rubric-trace: false)), opts).rubric.traced, false)
  assert.eq(opts_of((own: (rubric-trace: false), rubric_trace: true), opts).rubric.traced, true)
  // Not when rubrics are not drawn.
  opts.rubric.drawn = false
  assert.eq(opts_of((rubric_trace: true), opts).rubric.traced, false)
}

// --- laid out ---
#rule[In the margin (traced by default): the second item `trace: false`, no line from it.]
#exam(show-rubrics: true)[
  #question(points: 3)[
    Find $f'(x)$ #rubric(points: 1)[Derivative] and simplify it#rubric(
      points: 2,
      trace: false,
    )[Simplified].
  ]
]

#rule[`config`'s `rubric-trace: false`: only the item given `trace: true` has a line.]
#exam(show-rubrics: true, rubric-trace: false)[
  #question(points: 3)[
    Find $f'(x)$ #rubric(points: 1)[Derivative] and simplify it#rubric(
      points: 2,
      trace: true,
    )[Simplified].
  ]
]

#rule[At the `"end"` (not traced by default): the first item `trace: true`, a line down to the
  card.]
#exam(show-rubrics: true, rubric-position: "end")[
  #question(points: 3)[
    Find $f'(x)$ #rubric(points: 1, trace: true)[Derivative] and simplify it#rubric(
      points: 2,
    )[Simplified].
  ]
]

#rule[A `config` rule inside the exam turns traces off for question 2 alone; its second item asks
  for its line back with `trace: true`.]
#exam(show-rubrics: true)[
  #question(points: 1)[Traced, as usual #rubric(points: 1)[One].]
  #[
    #show: e.set_(config, rubric-trace: false)
    #question(points: 3)[
      Not traced #rubric(points: 1)[Two] but this one is#rubric(points: 2)[Three].
    ]
    #question(points: 1)[Traced explicitly#rubric(points: 1, trace: true)[Four].]
  ]
]
// Room for the last card, in the margin below the page's content.
#v(2.5cm)

// A question's rubric written before its first part, in a question split at
// a page break, is drawn on the part's first line: still traced as the
// question's rubrics are, not as the part's.
#rule[Split at a page break, `config`'s `rubric-trace: false`: question 1's item `trace: true`,
  drawn on part (a)'s line, has a line; part (a)'s item has none.]
#exam(show-rubrics: true, rubric-trace: false)[
  #question[#rubric(points: 1, trace: true)[Setup]
    #part(points: 1)[Solve it #rubric(points: 1)[Solved].]
    #part(points: 1)[Before the break. #pagebreak() After the break.]
  ]
]
#v(1.5cm)

#rule[Split at a page break: question 1's rubric at the `"end"` (not traced), drawn on part (a)'s
  line, has no line; part (a)'s, in the margin, has one.]
#exam(show-rubrics: true)[
  #show: e.set_(config, rubric-position: "end")
  #question[#rubric(points: 1)[Setup]
    #show: e.set_(config, rubric-position: "margin-right")
    #part(points: 1)[Solve it #rubric(points: 1)[Solved].]
    #part(points: 1)[Before the break. #pagebreak() After the break.]
  ]
]

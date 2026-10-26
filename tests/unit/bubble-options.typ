// The options a bubble, `choices`, `points-table`, and `page-score-box` take
// for themselves, beside `config`'s of the same kind: each `config` option is
// what the call's own is when it is left out, and the call's own wins over
// it. Checked by what is drawn (the bubbles' outlines and fills, the labels'
// font and color, recorded by show rules) and by laying a call out against
// the same call given the option itself, which must come out the same size.
#import "/src/lib.typ": *
#import "/src/elements/bubble.typ": _SQUARE_SIZE
#import "/src/config.typ": resolve_solution_colors
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

/// `body`, drawn under its description, with what it draws recorded under
/// `name`: each circle's (a bubble's, or the ring in a labelled one) `fill`
/// and `stroke`, and each piece of text's `font` and `fill`, in order.
#let probed(name, desc, body) = {
  rule(desc)
  let record(x) = state("probe-" + name, ()).update(p => p + (x,))
  show circle: it => record((fill: it.fill, stroke: it.stroke)) + it
  show text: it => context {
    let (font, fill) = (text.font, text.fill)
    record((font: font, text: it.text, fill: fill))
    it
  }
  block(body)
}

/// What `probed` recorded under `name`: its circles, or its text.
#let circles(name) = state("probe-" + name, ()).final().filter(x => "stroke" in x)
#let texts(name) = state("probe-" + name, ()).final().filter(x => "font" in x)

/// `a` and `b` laid out the same size, and drawn under the description.
#let alike(desc, a, b) = {
  rule(desc)
  block(a)
  context assert.eq(measure(a), measure(b), message: "not alike: " + repr(desc))
}

#let three = [- one
  - two
  + three]
#let MAROON = resolve_solution_colors(maroon, auto)

// --- the solution colors of a correct bubble ---
#probed("choice-color", [`choice(correct: true, color: maroon)`.], choice(correct: true, color: maroon)[answer])
#probed(
  "choice-background",
  [`bubble(correct: true, background-color: aqua)`, under `solution-color: olive`.],
  {
    show: e.set_(config, solution-color: olive)
    bubble(correct: true, background-color: aqua)[answer]
  },
)
#probed("choices-color", [`choices(color: maroon)`: only the correct one in it.], choices(color: maroon, three))
#context {
  let c = circles("choice-color").first()
  assert.eq(c.fill, MAROON.background, message: "choice's color: the fill follows it")
  assert.eq(c.stroke.paint, maroon, message: "choice's color outlines it")
  assert.eq(texts("choice-color").first().fill, maroon, message: "choice's color sets its content")

  let c = circles("choice-background").first()
  assert.eq(c.fill, aqua, message: "bubble's background-color fills it")
  assert.eq(c.stroke.paint, olive, message: "and the configured color stays")

  let cs = circles("choices-color")
  assert.eq(cs.map(c => c.fill), (none, none, MAROON.background), message: "choices' color: the correct one only")
  assert.eq(cs.last().stroke.paint, maroon)
}

// --- the outline: `stroke`, over `bubble-stroke` ---
#probed("strokes", [`bubble-stroke: .05em`; then `stroke: .15em` given to `choice` and to `choices`.], {
  show: e.set_(config, bubble-stroke: .05em)
  bubble[configured]
  h(1em)
  bubble(stroke: .15em)[its own]
  choices(stroke: .15em, inline: true, ([a], [b]))
})
#context {
  let widths = circles("strokes").map(c => c.stroke.thickness)
  assert.eq(widths, (.5pt, 1.5pt, 1.5pt, 1.5pt), message: "stroke wins over bubble-stroke: " + repr(widths))
}

// --- the labels' font: `label-font`, over `bubble-label-font` ---
#probed("fonts", [`bubble-label-font: "DejaVu Sans"`; then `choices(label-font: "Libertinus Serif")`.], {
  show: e.set_(config, bubble-label-font: "DejaVu Sans")
  choices(enumerate: true, inline: true, ([a], [b]))
  choices(enumerate: true, inline: true, label-font: "Libertinus Serif", ([a], [b]))
})
#context {
  // Each label, then its choice's content, which keeps the text's font.
  let fonts = texts("fonts").filter(t => t.text in ("A", "B")).map(t => t.font)
  assert.eq(
    fonts,
    ("dejavu sans",) * 2 + ("libertinus serif",) * 2,
    message: "label-font wins over bubble-label-font: " + repr(fonts),
  )
}

// --- `bubble-size`: the round bubble's diameter, a square one's in proportion ---
#alike(
  [`bubble-size: 1.6em` sizes a round bubble as `size: 1.6em` does;],
  { show: e.set_(config, bubble-size: 1.6em); bubble[round] },
  bubble(size: 1.6em)[round],
)
#alike(
  [a square one as much smaller across as by default;],
  { show: e.set_(config, bubble-size: 1.6em); square-bubble[square] },
  square-bubble(size: _SQUARE_SIZE * 1.6)[square],
)
#alike(
  [and a bubble's own `size` wins over it.],
  { show: e.set_(config, bubble-size: 1.6em); bubble(size: .8em)[small] },
  bubble(size: .8em)[small],
)
#context assert.ne(measure(bubble(size: 1.6em)), measure(bubble()), message: "a 1.6em bubble is bigger")

// --- `bubble-outset`: the sides a bubble's own `outset` does not name ---
#alike(
  [`bubble-outset: (left: 1em)` is `outset: (left: 1em)`, the gap after it kept;],
  { show: e.set_(config, bubble-outset: (left: 1em)); bubble[spaced] },
  bubble(outset: (left: 1em))[spaced],
)
#alike(
  [a bubble's own `outset: 1em` (the gap after it) keeps the configured left.],
  { show: e.set_(config, bubble-outset: (left: 1em)); bubble(outset: 1em)[spaced] },
  bubble(outset: (left: 1em, right: 1em))[spaced],
)
#context assert.ne(
  measure(bubble(outset: (left: 1em))[x]),
  measure(bubble[x]),
  message: "an outset on the left widens a bubble",
)

// --- `choices`' layout: its own, or `config`'s ---
#alike(
  [`choices-columns: 2` lays out as `columns: 2`;],
  { show: e.set_(config, choices-columns: 2); choices(three) },
  choices(columns: 2, three),
)
#alike(
  [`choices-inline: true` as `inline: true`;],
  { show: e.set_(config, choices-inline: true); choices(three) },
  choices(inline: true, three),
)
#alike(
  [a call's `inline: false` sets them one per line, whatever `config` says;],
  { show: e.set_(config, choices-columns: 2); choices(inline: false, three) },
  { show: e.set_(config, choices-columns: none); choices(three) },
)
#alike(
  [a call's `inline: true` wins over `choices-columns`;],
  { show: e.set_(config, choices-columns: 2); choices(inline: true, three) },
  choices(inline: true, three),
)
#alike(
  [`choices-gap: 1em` is `gap: 1em`;],
  { show: e.set_(config, choices-gap: 1em); choices(three) },
  choices(gap: 1em, three),
)
#alike(
  [and a call's `gap: auto` wins over it.],
  { show: e.set_(config, choices-gap: 1em); choices(gap: auto, three) },
  choices(three),
)
#context assert.ne(measure(choices(gap: 1em, three)), measure(choices(three)), message: "a gap spaces them")

// --- `strings` of a points table and a page's score box ---
#show: exam
#question(points: 2)[A question.]
#question(points: 3)[Another.]
#alike(
  [`points-table(strings: (total: [Gesamtpunktzahl]))` is as with `config`'s `strings`.],
  points-table(strings: (total: [Gesamtpunktzahl])),
  { show: e.set_(config, strings: (total: [Gesamtpunktzahl])); points-table() },
)
#context assert.ne(
  measure(points-table(strings: (total: [Gesamtpunktzahl]))),
  measure(points-table()),
  message: "the word changes the table",
)
#alike(
  [`page-score-box(strings: (score: [Erreichte Punkte]))` likewise.],
  page-score-box(strings: (score: [Erreichte Punkte])),
  { show: e.set_(config, strings: (score: [Erreichte Punkte])); page-score-box() },
)

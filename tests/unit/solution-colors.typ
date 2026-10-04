// `resolve_solution_colors` (src/config.typ): the pair of colors every
// solution-colored thing — a solution's text and highlight, a filled-in
// bubble's outline and fill — is drawn with.
//
// Either half may be configured on its own, and the other is then derived
// from it, so a document can be re-tinted by setting one option.
#import "/src/lib.typ": *
#import "/src/config.typ": (
  DEFAULT_SOLUTION_COLOR, resolve_solution_colors, solution_colors,
)

#set page(width: 6in, height: auto, margin: 1in)
#show: e.prepare()

// --- neither configured: the package default, with a wash derived from it ---
#let both_auto = resolve_solution_colors(auto, auto)
#assert.eq(both_auto.color, DEFAULT_SOLUTION_COLOR)
#assert.eq(both_auto.background, DEFAULT_SOLUTION_COLOR.lighten(90%))

// --- both configured: both used as given ---
#let both_set = resolve_solution_colors(red, aqua)
#assert.eq(both_set.color, red)
#assert.eq(both_set.background, aqua)

// --- only the color: the background is a lightened wash of it ---
#let color_only = resolve_solution_colors(maroon, auto)
#assert.eq(color_only.color, maroon)
#assert.eq(color_only.background, maroon.lighten(90%))

// --- only the background: the color is rebuilt from it ---
// Darkening a pale wash would give gray, so the derived color must keep the
// background's hue and come back saturated and dark enough to read as text.
#let bg_only = resolve_solution_colors(auto, maroon.lighten(90%))
#assert.eq(bg_only.background, maroon.lighten(90%))
#let (l, chroma, hue, ..) = oklch(bg_only.color).components()
#let (_, _, bg_hue, ..) = oklch(maroon.lighten(90%)).components()
#assert.eq(hue, bg_hue, message: "the derived color keeps the background's hue")
#assert(l < 60%, message: "the derived color is dark enough to read: " + repr(l))
#assert(chroma > 0.05, message: "the derived color is not washed out: " + repr(chroma))

// A neutral background has no hue to restore, so it must not acquire one —
// saturating a gray would otherwise swing it to red.
#let from_gray = resolve_solution_colors(auto, rgb(gray).lighten(90%))
#let (_, gray_chroma, ..) = oklch(from_gray.color).components()
#assert(
  gray_chroma < 0.01,
  message: "a gray background stays neutral, got chroma " + repr(gray_chroma),
)

// --- read through the config ---
#e.get(get => {
  let colors = solution_colors(get)
  assert.eq(colors.color, DEFAULT_SOLUTION_COLOR, message: "unset config uses the default")
  assert.eq(colors.background, DEFAULT_SOLUTION_COLOR.lighten(90%))
})
#[
  #show: e.set_(config, solution-color: olive)
  #e.get(get => {
    let colors = solution_colors(get)
    assert.eq(colors.color, olive, message: "solution-color is used as given")
    assert.eq(
      colors.background,
      olive.lighten(90%),
      message: "and the background follows it",
    )
  })
]
#[
  #show: e.set_(config, solution-background-color: olive.lighten(90%))
  #e.get(get => {
    let colors = solution_colors(get)
    assert.eq(colors.background, olive.lighten(90%), message: "the background is used as given")
    assert(
      colors.color != DEFAULT_SOLUTION_COLOR,
      message: "and the color follows it rather than staying blue",
    )
  })
]

// --- the deprecated `solution-text-color` (regression) ---
// 0.3 named the solution color `solution-text-color`. A document written for
// it must still compile, and still be drawn in the color it asked for.
#[
  #show: e.set_(config, solution-text-color: maroon)
  #e.get(get => {
    let colors = solution_colors(get)
    assert.eq(colors.color, maroon, message: "solution-text-color still sets the solution color")
    assert.eq(colors.background, maroon.lighten(90%), message: "and the background follows it")
  })
  // Rendered too, so the old name is checked all the way to a solution.
  #solution[old name]
]
#[
  // 0.3 documents commonly set both of the old options together.
  #show: e.set_(config, solution-text-color: maroon, solution-background-color: aqua)
  #e.get(get => {
    let colors = solution_colors(get)
    assert.eq(colors.color, maroon)
    assert.eq(colors.background, aqua)
  })
]
#[
  // Given both names, the new one wins.
  #show: e.set_(config, solution-text-color: maroon, solution-color: olive)
  #e.get(get => {
    assert.eq(solution_colors(get).color, olive, message: "solution-color wins over solution-text-color")
  })
]

// A visual record of each case, for eyeballing the derived colors.
#let swatch(desc, colors) = {
  block(above: 12pt, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  align(right, emph(desc))
  block(
    box(fill: colors.background, inset: 4pt, text(fill: colors.color)[solution text])
      + h(.5em)
      + box(baseline: 50% - .3em, circle(radius: .45em, stroke: .5pt + colors.color, fill: colors.background)),
  )
}
#swatch([Neither configured.], both_auto)
#swatch([`solution-color: maroon`.], color_only)
#swatch([`solution-background-color: maroon.lighten(90%)`.], bg_only)
#swatch([A neutral background stays neutral.], from_gray)

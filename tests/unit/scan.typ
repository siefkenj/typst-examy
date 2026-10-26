// The content scans the exam pipeline runs before layout (src/scan.typ):
// what is a break, what height a chunk asks for, what a scan finds (markers,
// breaks, fr heights), where the rubrics are, how a body begins, and what
// counts as whitespace.
//
// Each case is written as markup source, evaluated for the check, so that
// the visual record at the end can show it as written.
#import "/src/scan.typ": (
  extract_height, has_rubric, is_break, is_whitespace_content, rubric_markers, scan,
  starts_inline, trim_leading_space,
)
#import "/src/markers.typ": begin_marker, end_marker, height_hint
#import "/src/divisions.typ": part, question
#import "/src/lib.typ": config, e, rubric, solution
#import "/tests/record.typ": cases, rule

#set page(width: 6.5in, height: auto, margin: .5in)
#show: e.prepare()

#let SCOPE = (
  begin_marker: begin_marker,
  end_marker: end_marker,
  height_hint: height_hint,
  question: question,
  part: part,
  rubric: rubric,
  solution: solution,
  e: e,
  config: config,
)
#let ev(src) = eval(src, mode: "markup", scope: SCOPE)

/// Check `f` on each `(source, expected)` case, and return the cases for the
/// record.
#let check(name, f, cases) = {
  for (src, expected) in cases {
    let got = f(ev(src))
    assert(got == expected, message: name + "(" + src + "): expected " + repr(expected) + ", got " + repr(got))
  }
  cases
}

#let IS_BREAK = check("is_break", is_break, (
  ("#pagebreak()", true),
  ("#colbreak()", true),
  ("hello", false),
))
// A string is never a break either.
#assert(not is_break("hello"))

#let EXTRACT_HEIGHT = check("extract_height", extract_height, (
  ("#v(2fr)", 2fr),
  ("#box(height: 3cm)[x]", 3cm),
  ("#block(height: 4cm)", 4cm),
  ("#box[x]", none),
  ("#height_hint(1fr)", 1fr),
  ("plain", none),
))

#let SCAN_MARKERS = check("scan(..).has_marker", c => scan(c).has_marker, (
  ("plain text", false),
  ("#begin_marker((name: \"part\"))", true),
  ("#end_marker()", true),
  // A marker nested in a sequence, or inside a block.
  ("a #begin_marker((name: \"question\")) b", true),
  ("#block[#begin_marker((name: \"part\"))]", true),
  // A marker inside styled content.
  ("#set text(fill: red)\n#question[hi]", true),
))
#let SCAN_NAMES = check("scan(..).marker_names", c => scan(c).marker_names, (
  ("#begin_marker((name: \"part\"))", ("part",)),
  // A whole division reports the markers it emits.
  ("#question[hi]", ("question",)),
))

#let SCAN_BREAKS = check("scan(..).has_break", c => scan(c).has_break, (
  ("a #pagebreak() b", true),
  ("a b", false),
  ("#block[#colbreak()]", true),
  // Before a rule spliced into the same sequence (see `RUBRIC_CASES`).
  ("#([a #pagebreak()] + { show: e.set_(config, indent: 1em); [b] })", true),
))

#let SCAN_FR = check("scan(..).fr", c => scan(c).fr, (
  ("#v(1fr)", 1fr),
  ("#v(1fr) #v(2fr)", 3fr),
  ("#block(height: 1fr)[x]", 1fr),
  ("#height_hint(2fr) some box", 2fr),
  // An fr inside an explicitly-sized container does not propagate...
  ("#block(height: 2cm)[#v(1fr)]", none),
  // ...but the sized container's own fr height counts.
  ("#block(height: 1fr)[#v(1fr)]", 1fr),
  // Non-fr heights don't contribute.
  ("#v(1cm)", none),
))

#let STARTS_INLINE = check("starts_inline", starts_inline, (
  // Inline starts.
  ("plain text", true),
  ("#box[x] more", true),
  ("*bold* start", true),
  ("$x + y$ inline math", true),
  ("#link(\"https://x.test\")[a link]", true),
  // A leading space is transparent; the text after decides.
  (" text after a space", true),
  // An explicitly-sized box fills its line past the baseline: not text-like.
  ("#box(height: 2cm, width: 100%)[] text", false),
  // Block-level starts.
  ("#block[a block]", false),
  ("#block[a block] then text", false),
  ("$ x + y $", false),
  ("+ an enum item", false),
  ("#figure([x])", false),
  // A leading parbreak means the first text is a fresh paragraph.
  ("#parbreak()text", false),
  // Invisible content is transparent.
  (" ", none),
  ("#metadata(\"x\")", none),
  ("#metadata(\"x\") text", true),
  // Styled wrappers are transparent.
  ("#set text(fill: red)\nstyled text", true),
))

// --- trim_leading_space: each case's result as Typst prints it ---
#let TRIM = check("trim_leading_space", c => repr(trim_leading_space(c)), (
  // A body written on its own markup line loses its leading space (the
  // trailing space is untouched: only the leading one matters).
  (" leading space", repr([leading space])),
  ("\n  own line body\n", repr([own line body ])),
  // Leading parbreaks are stripped too.
  ("#parbreak()after break", repr([after break])),
  // Interior spaces are untouched.
  ("a b", repr([a b])),
  // Pure whitespace trims to nothing.
  (" ", repr(none)),
))
// Styled wrappers are preserved around the trimmed content.
#{
  let trimmed = trim_leading_space(ev("#set text(fill: red)\n padded"))
  assert(repr(trimmed.func()) == "styled")
}

#let WHITESPACE = check("is_whitespace_content", is_whitespace_content, (
  (" ", true),
  ("#parbreak()", true),
  ("\n  #parbreak()\n", true),
  ("#metadata(\"x\")", true),
  ("hi", false),
  (" x ", false),
))

// Rubrics are found inside other elements, and behind a set rule of
// elembic's, which keeps what it applies to in its tag.
#let RUBRIC_CASES = (
  ("plain text", 0),
  ("#rubric(points: 1)[A]", 1),
  ("a #box[#rubric(points: 1)[A]] b #rubric(points: 2)[B]", 2),
  ("#show: e.set_(config, show-rubrics: true)\nb #rubric(points: 1)[A]", 1),
  // A rule joined to content before it is spliced into the same sequence,
  // which ends in the rule's tag but is not the rule: what comes before it
  // is found too.
  ("#([#rubric(points: 1)[A] ] + { show: e.set_(config, indent: 1em); [b #rubric(points: 2)[B]] })", 2),
)
#let RUBRIC_MARKERS = check("rubric_markers(..).len()", c => rubric_markers(c).len(), RUBRIC_CASES)

// With `kept`, rubrics are found in the fields of elements, which elembic
// keeps in metadata: in a solution, which a hidden one leaves in its place,
// each once, also behind a set rule.
#let KEPT_CASES = (
  ("#solution[x #rubric(points: 1)[A]]", 0, 1),
  ("#{ show: e.set_(solution, boxed: false); solution[x #rubric(points: 1)[A]] }", 0, 1),
  ("#solution[x #rubric(points: 1)[A]] #parbreak() #solution[y #rubric(points: 2)[B]]", 0, 2),
)
#for (src, default, kept) in KEPT_CASES {
  assert.eq(rubric_markers(ev(src)).len(), default, message: "rubric_markers(" + src + ")")
  assert.eq(rubric_markers(ev(src), kept: true).len(), kept, message: "rubric_markers(" + src + ", kept: true)")
}
#let HAS_RUBRIC = check(
  "has_rubric",
  has_rubric,
  RUBRIC_CASES.map(((src, n)) => (src, n > 0)),
)

// A visual record of each case above: the source, and what came of it.
#let record(desc, f, rows, fmt: repr) = {
  rule(desc)
  cases(
    ([Source], [Expected], [Got]),
    ..rows.map(((src, expected)) => (
      // Line breaks shown as ⏎, and a source of only spaces as ␣.
      raw(if src.trim() == "" { src.replace(" ", "␣").replace("\n", "⏎") } else { src.replace("\n", "⏎") }, lang: "typ"),
      raw(fmt(expected)),
      raw(fmt(f(ev(src)))),
    )),
  )
}
#record([`is_break`: a page or column break.], is_break, IS_BREAK)
#record([`extract_height`: the height a chunk asks for.], extract_height, EXTRACT_HEIGHT)
#record([`scan(..).has_marker`: a division's marker anywhere inside.], c => scan(c).has_marker, SCAN_MARKERS)
#record([`scan(..).marker_names`: which markers.], c => scan(c).marker_names, SCAN_NAMES)
#record([`scan(..).has_break`: a break anywhere inside.], c => scan(c).has_break, SCAN_BREAKS)
#record([`scan(..).fr`: the fr height a chunk negotiates with.], c => scan(c).fr, SCAN_FR)
#record([`rubric_markers(..).len()`: how many rubrics are inside.], c => rubric_markers(c).len(), RUBRIC_MARKERS)
#record([`has_rubric`: a rubric anywhere inside.], has_rubric, HAS_RUBRIC)
#rule[`rubric_markers(.., kept: true)`: also in the fields elembic keeps, each once]
#cases(
  ([Source], [Default], [Kept]),
  ..KEPT_CASES.map(((src, ..)) => (
    raw(src, lang: "typ"),
    raw(repr(rubric_markers(ev(src)).len())),
    raw(repr(rubric_markers(ev(src), kept: true).len())),
  )),
)
#record([`starts_inline`: whether a body begins inline (`none`: invisible).], starts_inline, STARTS_INLINE)
#record([`trim_leading_space`: the body with its leading space removed.], c => repr(trim_leading_space(c)), TRIM, fmt: x => x)
#record([`is_whitespace_content`: nothing visible.], is_whitespace_content, WHITESPACE)

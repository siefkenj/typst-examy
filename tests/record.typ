// Helpers for the visual record every test in tests/unit/ draws of the cases
// it checks, so that a compiled test can be inspected by eye. Kept out of
// tests/unit/ so that tests/run.sh does not compile it as a test of its own.
// A test using them needs `#show: e.prepare()`.
#import "/src/lib.typ": exam

/// A caption for a case: a gray rule with the description below it, at the
/// right.
#let rule(desc) = {
  block(above: 14pt, below: 6pt, line(length: 100%, stroke: .5pt + gray))
  align(right, emph(text(9pt, desc)))
}

/// A value as Typst prints it, small and wrapped to the column.
#let data(value) = block(width: 100%, breakable: true, text(7.5pt, raw(repr(value), lang: "typc")))

/// `body` drawn as an exam draws it, in a light frame.
#let preview(body) = block(width: 100%, stroke: .3pt + gray, inset: 6pt, exam(questions: body))

/// Two things side by side, each in half the width: what was given, and what
/// came of it.
#let pair(left, right) = grid(columns: (1fr, 1fr), column-gutter: 10pt, left, right)

/// A small table, with a header row.
#let cases(header, ..rows) = text(8pt, table(
  columns: header.len(),
  stroke: .3pt + gray,
  inset: 4pt,
  align: left + horizon,
  ..header.map(h => strong(h)),
  ..rows.pos().flatten(),
))

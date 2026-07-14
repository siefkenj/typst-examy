// Demonstrates `name-block`: the default rows and fully custom fields.
// Uses a small auto-height page so the render is easy to read in the
// README.
//
// Compile: typst compile --root .. name-blocks.typ
#import "../src/lib.typ": *

#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()

// The default block: a Name row and a Student ID row.
#name-block()

#v(1.5em)

// Custom rows: a `(prefix: .., suffix: ..)` entry draws an underline from
// the prefix to the end of the line, with the suffix sitting on the line;
// plain content is rendered verbatim as its own row.
#name-block(fields: (
  (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
  (prefix: [Email address:], suffix: [`@university.edu`]),
  (prefix: [Student ID:]),
  {
    set align(center)
    text(size: .85em)[_Write legibly and darkly._]
  },
))

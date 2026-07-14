// Demonstrates cross-references: `@name` adapts to where the reference
// appears. Uses a small auto-height page so the render is easy to read in
// the README.
//
// Compile: typst compile --root .. cross-references.typ
#import "../src/lib.typ": *

#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()
#show link: set text(fill: blue)

#exam(questions: [
  #question[
    #part(points: 2, label: <continuity>)[Show that $f$ is continuous at $0$.]
    #part[From a sibling part, @continuity displays as its short name.]
  ]
  #question[From another question, @continuity displays with its question number.]
])

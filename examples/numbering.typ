// Demonstrates the `number:` argument of question/part/subpart. Uses a
// small auto-height page so the render is easy to read in the README.
//
// Compile: typst compile --root .. numbering.typ
#import "../src/lib.typ": *

#set page(width: 11cm, height: auto, margin: 6mm)
#show: e.prepare()

#exam(questions: [
  #question[An automatically numbered question.]
  #question[Another one.]
  #question(number: 10)[An integer sets the number.]
  #question[...and numbering continues from it.]
  #question(number: "★")[Content is shown verbatim.]
  #question(number: none)[An unnumbered question.]
  #question[The automatic counter ignores the previous two.]
])

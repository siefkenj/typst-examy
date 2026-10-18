// A question, part, or subpart given a `height` is laid out as one block of
// that height (a "frame"): `fr` answer boxes inside it share what its text
// leaves of it, the exam lays it out whole, and a page or column break
// inside it is an error, as a block cannot break across pages.
#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": build_items, fixed_height_break_error, parse
#import "/src/plan.typ": plan
#import "/src/points.typ": assign_badges
#import "/src/divisions.typ": part, question, subpart
#import "/src/lib.typ": answer-box, e, exam
#import "/tests/record.typ": cases, data, rule

#set page(width: 5in, height: 8in, margin: .4in)
#set text(size: 10pt)
#show: e.prepare()

#let SCOPE = (question: question, part: part, subpart: subpart, answer-box: answer-box)
#let content(src) = eval(src, mode: "markup", scope: SCOPE)
#let kinds(src) = plan(assign_badges(parse(tokenize(content(src))))).map(i => i.kind)

// The planner: a top-level division with a height is a frame; one inside a
// question makes the question split around it, the frame a peer of its own.
// A question whose body starts with the frame has its number on the frame's
// first line, so no segment of its own before it.
#let PLANS = (
  ("#question(height: 3cm)[A.]", ("frame",)),
  ("#question[#part(height: 2cm)[A.] #part[B.]]", ("frame", "segment")),
  ("#question[Text. #part(height: 2cm)[A.] #part[B.]]", ("segment", "frame", "segment")),
  // A frame that starts with a frame: the question's and the part's numbers
  // are passed down to the subpart's first line.
  ("#question[#part(height: 3cm)[#subpart(height: 1cm)[A.]]]", ("frame",)),
  ("#question[#part[A.]]", ("nested",)),
)
#for (src, expected) in PLANS {
  assert.eq(kinds(src), expected, message: "plan of " + src)
}

// A break inside a division with a height is an error; one outside it is
// not. The error names the division with the height, however deep the break.
#let BREAKS = (
  ("#question(height: 3cm)[A. #pagebreak() B.]", true),
  ("#question(height: 3cm)[#part[A. #colbreak() B.]]", true),
  ("#question[#part(height: 2cm)[A.] #pagebreak() #part[B.]]", false),
  ("#question[A. #pagebreak() B.]", false),
)
#for (src, fails) in BREAKS {
  let error = fixed_height_break_error(build_items(tokenize(content(src))))
  assert.eq(error != none, fails, message: "break check of " + src + ": " + repr(error))
  if fails { assert(error.contains("`question` with a `height`"), message: error) }
}

#rule[What the planner makes of a division with a height, and which breaks are errors.]
#cases(
  ([Source], [Plan / error]),
  ..PLANS.map(((src, expected)) => (raw(src, lang: "typ"), raw(expected.join(", ")))),
  ..BREAKS.map(((src, fails)) => (raw(src, lang: "typ"), if fails [error] else [fine])),
)

// The frame is exactly its height. A mark on a question's first line sits
// at its top, so from one in the framed question to one in the next is the
// frame's height and the gap between questions; between two questions with
// no height, it is one line and the same gap.
#let mark(name) = [#metadata(name)#label(name)]
#let y(name) = locate(label(name)).position().y

#rule[A question 4cm tall, its two boxes sharing what its text leaves of it 1 : 2, then one with no height.]
#block(stroke: .3pt + gray, inset: 6pt, exam(questions: [
  #question(height: 4cm)[
    Text.#mark("framed")
    #answer-box(width: 100%, height: 1fr)[#mark("box-1")]
    #answer-box(width: 100%, height: 2fr)[#mark("box-2")]
  ]
  #question[After.#mark("after-framed")]
]))

#exam(questions: [
  #question[Before.#mark("plain")]
  #question[After.#mark("after-plain")]
])

#context {
  // So the two differ by the frame's height less one line (under 14pt).
  let difference = (y("after-framed") - y("framed")) - (y("after-plain") - y("plain"))
  let frame = 4cm.to-absolute()
  assert(
    difference > frame - 14pt and difference <= frame + .5pt,
    message: "the frame is not 4cm tall: the distances differ by " + repr(difference),
  )
  // The first box got its share: the second starts well below it.
  assert(y("box-2") - y("box-1") > 1cm.to-absolute(), message: "the first box took no share")
}

// On a page of its own: `height: 1fr` takes what is left of it.
#pagebreak()
#rule[A part 2cm tall that starts with a subpart 1cm tall: all three numbers on the subpart's first line.]
#block(stroke: .3pt + gray, inset: 6pt, exam(questions: [
  #question[#part(height: 2cm)[#subpart(height: 1cm)[A subpart.] #subpart[Another.]]]
]))

#rule[A part 2cm tall inside an ordinary question, and a question with `height: 1fr`, filling the rest of the page.]
#block(stroke: .3pt + gray, inset: 6pt, height: 1fr, exam(questions: [
  #question[
    #part(height: 2cm)[A part. #answer-box(width: 100%, height: 1fr)[]]
    #part[An ordinary part after it.]
  ]
  #question(height: 1fr)[
    The rest.
    #part[A part. #answer-box(width: 100%, height: 1fr)[]]
    #part[Another. #answer-box(width: 100%, height: 1fr)[]]
  ]
]))

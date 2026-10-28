// A reference reads from where it is made (see `relative_components`), and
// the text of a division after one of its parts is the division's own
// again: a reference there reads as it does from the division's text before
// the part, not from inside the part. So too text between questions, and
// after the exam, which is no question's. Both ways a division is drawn: in
// one piece, and split into segments at a page break.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()

/// Content's text, as a string.
#let plain(c) = if c.has("text") { c.text } else if c.has("children") { c.children.map(plain).join() } else if c.has(
  "body",
) { plain(c.body) } else { "" }

// Every reference links to the division it refers to: record what each
// reads.
#show link: it => [#metadata(plain(it.body))<ref-link>#it]

#let thin = str(sym.space.thin)

// Each case: where the reference is made, and what it reads, in order.
#let CASES = (
  ([question 1's text, before its parts], "(a)" + thin + "i"),
  ([inside subpart (a) ii], "i"),
  ([question 1's text, between parts (a) and (b)], "(a)" + thin + "i"),
  ([inside part (b)], "(a)" + thin + "i"),
  ([question 2's text, after its part, drawn split at a page break], "(a)"),
  ([between questions 2 and 3], "2" + thin + "(a)"),
  ([after the exam, which ends with a question], "3" + thin + "(a)"),
)

#rule[Each reference reads as from where it is: question 1's text between its parts is question 1's,
  and text between questions, or after the exam, is no question's.]
#exam(questions: [
  #question[
    Before its parts: @sa1.
    #part(label: <pa>)[Part a.
      #subpart(label: <sa1>)[First.]
      #subpart[Second, after @sa1.]
    ]
    Between its parts: @sa1.
    #part[Part b, after @sa1.]
  ]
  #question[
    #part(label: <qb>)[A part, then a page break.]
    #pagebreak()
    Back in question 2's text, after the break: @qb.
  ]
  Between questions 2 and 3: @qb.
  #question[
    #part(label: <q3a>)[Its part.]
  ]
])
After the exam: @q3a.

#context {
  let got = query(<ref-link>).map(m => m.value)
  let expected = CASES.map(c => c.last())
  assert(got == expected, message: "expected " + repr(expected) + ", got " + repr(got))
}

#rule[What each reference above reads, where it is made.]
#context table(
  columns: 3,
  stroke: .3pt + gray,
  inset: 4pt,
  [*Where*], [*Expected*], [*Reads*],
  ..CASES.zip(query(<ref-link>).map(m => m.value)).map(((c, got)) => (c.first(), c.last(), got)).flatten(),
)

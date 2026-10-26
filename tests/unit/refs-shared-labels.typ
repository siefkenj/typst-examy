// A label that two exams' divisions carry, as a bundle's exam and its key
// made from the same questions do (labels are global to a document, and to
// a bundle): a reference refers to the division in its own exam, reads as
// that exam numbers it, and links to it there. Typst alone finds the label
// ambiguous. The second exam is numbered differently, after a question of
// its own, so that a reference to the first exam's division would read
// differently.
#import "/src/lib.typ": *
#import "/src/points.typ": exam_index
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()

/// Content's text, as a string.
#let plain(c) = if c.has("text") { c.text } else if c.has("children") { c.children.map(plain).join() } else if c.has(
  "body",
) { plain(c.body) } else { "" }

// Every reference links to the division it refers to: record where each
// reference is, what it reads, and where it links to.
#show link: it => [#metadata((dest: it.dest, body: plain(it.body)))<ref-link>#it]

#let QUESTIONS = [
  #question[See @later and @sub.]
  #question(label: <later>)[The labelled question.
    #part(label: <sub>)[Its labelled part. Back to @later.]
  ]
]

#rule[The first exam: the labelled question is question 2.]
#exam(questions: QUESTIONS)

#rule[The second, with the same questions after one of its own, numbered "Problem 1.": the labelled
  question is Problem 3, and the references here read so.]
#exam(numbering: ("Problem 1.", "(A)"), questions: [
  #question[A question of the second exam's own.]
  #QUESTIONS
])

#context {
  let thin = str(sym.space.thin)
  let links = query(<ref-link>).map(m => (
    exam: exam_index(m.location()),
    target: exam_index(m.value.dest),
    body: m.value.body,
  ))
  for l in links {
    assert(l.target == l.exam, message: "a reference links into another exam: " + repr(l))
  }
  let expected = (
    (exam: 0, bodies: ("2", "2" + thin + "(a)", "2")),
    (exam: 1, bodies: ("Problem 3", "Problem 3" + thin + "(A)", "Problem 3")),
  )
  for (exam, bodies) in expected {
    let got = links.filter(l => l.exam == exam).map(l => l.body)
    assert(got == bodies, message: "exam " + str(exam) + ": " + repr(got))
  }
}

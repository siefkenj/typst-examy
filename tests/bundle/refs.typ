// The exam and its key from one compile, as a bundle (as the guide's
// Solutions page shows): the same questions in two documents, so their
// labels are in both, and labels are global to a bundle. Each document's
// references must refer to the divisions in its own exam (see
// tests/unit/refs-shared-labels.typ, which checks how they read).
#import "/src/lib.typ": *
#import "/src/points.typ": exam_index

#show link: it => [#metadata(it.dest)<ref-link>#it]

#let quiz = [
  #show: exam
  #question(points: 2)[See @later and @sub.]
  #question(points: 3, label: <later>)[Second.
    #part(label: <sub>)[A part. Back to @later. #solution[42]]
  ]
  #context {
    let links = query(<ref-link>)
    assert(links.len() == 6, message: "expected 3 references in each document, got " + str(links.len()))
    for m in links {
      assert(exam_index(m.value) == exam_index(m.location()), message: "a reference links into the other document")
    }
  }
]

#document("exam.pdf", {
  show: e.set_(config, show-solutions: false)
  quiz
})
#document("key.pdf", {
  show: e.set_(config, show-solutions: true)
  quiz
})

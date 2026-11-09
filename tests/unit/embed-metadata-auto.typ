// `config`'s `embed-metadata: auto`: an exam attaches its regions always, and
// its rubrics only when solutions are shown; here they are not. What the PDF
// attaches is checked by tests/run.sh, which compiles this with the command
// line's `show-solutions` and `embed-metadata` too: the regions are left as
// `<examy-regions>` whatever is attached, and the rubrics as `<examy-rubric>`.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 5in, height: auto, margin: .5in)
#set text(size: 10pt)
#show: e.prepare()

#rule[An exam with `embed-metadata: auto` and `show-solutions: false`: without solutions, it attaches `examy-regions.json` and not `examy-rubric.json`]
#exam(embed-metadata: auto, show-solutions: false)[
  #question(points: 2, rubric: rubric(points: 2)[Factors it])[
    Factor $x^2 - 1$. #solution[$(x - 1)(x + 1)$]
  ]
]

#context {
  // With no command line, as the loop in tests/run.sh compiles it.
  if sys.inputs.at("embed-metadata", default: none) == none {
    assert.eq(query(<examy-regions>).len(), 1, message: "auto leaves the regions")
  }
  assert.eq(query(<examy-rubric>).len(), 1, message: "the rubrics are left as data, whatever is attached")
}

// The regions of a page turned sideways give its size as it is turned, and its
// margins in percent as a share of that: its own width and height, not the ones
// it was given. Drawn over the page, in red.
#import "/src/lib.typ": *
#import "/src/regions.typ": PAGE_MARK
#import "/tests/record.typ": cases, rule

#set page(width: 4in, height: 6in, flipped: true, margin: (left: 25%, right: 10%, y: 10%))
#set text(size: 10pt)
#show: e.prepare()

#rule[A page 4in × 6in turned sideways: 6in wide, its left margin 25% of that]
#exam(embed-metadata: "question-regions")[
  #question(points: 1)[Where is the nearest grocery store from the train station?]
]
#context {
  let found = query(PAGE_MARK)
  if found.len() == 0 { return }
  let p = found.first().value
  cases(
    ([Width], [Height], [Left], [Right], [Top]),
    ([#p.width], [#p.height], [#p.margin.left], [#p.margin.right], [#p.margin.top]),
  )
  place(top + left, dx: -p.margin.left * 1pt, dy: -p.margin.top * 1pt, rect(width: p.width * 1pt, height: p.height * 1pt, stroke: red))
  assert.eq((p.width, p.height), (432.0, 288.0))
  assert.eq((p.margin.left, p.margin.right, p.margin.top, p.margin.bottom), (108.0, 43.2, 28.8, 28.8))
}

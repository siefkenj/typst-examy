// expect: an `fr` height in a `columns` inside a `part` with a `height`
// An `fr` height before `columns` holding one is squeezed out by them, in a block
// with nowhere else to go.
#import "/src/lib.typ": *

#show: exam

#question[
  #part(height: 5cm)[
    #answer-box(height: 1fr)[]
    #columns(2)[#answer-box(height: 1fr)[]]
  ]
]

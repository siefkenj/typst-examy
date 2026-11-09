// expect: an `fr` height in a `columns` inside a `question` with a `height`
// An `fr` height in `columns` takes all of a block's height, and what is after them
// has no page to move on to: it would be drawn out of the block.
#import "/src/lib.typ": *

#show: exam

#question(height: 5cm)[
  Q.
  #columns(2)[#answer-box(height: 1fr)[]]
  Text after.
]
#question[Next]

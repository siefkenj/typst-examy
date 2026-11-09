// expect: an `fr` height in a `columns` inside a `question` with a `height`
// In `columns` in `columns`, they are full too, and a part after them has no room.
#import "/src/lib.typ": *

#show: exam

#question(height: 5cm)[
  #columns(2)[#columns(2)[#answer-box(height: 1fr)[]]]
  #part[After.]
]

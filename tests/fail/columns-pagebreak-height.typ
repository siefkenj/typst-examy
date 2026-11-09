// expect: inside a `question` with a `height`
// A page break in `columns` would leave the block of a question given a `height`,
// as a column break in them would not.
#import "/src/lib.typ": *

#show: exam

#question(height: 4cm)[
  #columns(2)[#part[Before.] #pagebreak() #part[After.]]
]

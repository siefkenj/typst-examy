// expect: choices: `stroke` must not be negative
#import "/src/lib.typ": *

#choices(stroke: -1pt)[- a
  - b]

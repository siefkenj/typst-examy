// expect: config: `choices-columns` must be a number of columns
#import "/src/lib.typ": *

#show: e.set_(config, choices-columns: 0)
#choices[- a
  - b]

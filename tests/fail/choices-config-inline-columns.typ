// expect: config: `choices-inline` and `choices-columns` are two different layouts
// `config`'s two layouts set together, for a `choices` given neither.
#import "/src/lib.typ": *

#show: e.set_(config, choices-inline: true, choices-columns: 2)
#choices[- a
  - b]

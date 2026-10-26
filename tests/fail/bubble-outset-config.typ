// expect: config: `bubble-outset` has no side `middle`
#import "/src/lib.typ": *

#show: e.set_(config, bubble-outset: (middle: 1em))
#bubble[a]

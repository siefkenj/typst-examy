// expect: sets `points-position`, which is read once for the whole exam
// A `config` rule after `#show: exam`, around its questions, setting an
// option the exam reads once: an error, as it would change nothing.
#import "/src/lib.typ": *

#show: exam
#show: e.set_(config, points-position: "end")
#question(points: 2)[A question.]

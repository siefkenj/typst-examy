// expect: exam: `strings` must be dictionary(content)
// `strings` takes words, and the functions of `points-format` and
// `bonus-points-format`, which an author easily puts there; a function
// under any other key is still an error.
#import "/src/lib.typ": *

#show: exam.with(strings: (total: p => [Summe]))
#question(points: 1)[A]

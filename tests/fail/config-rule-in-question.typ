// expect: sets `strings`, which is read once for the whole exam
// A `config` rule inside a question, around its parts, setting an option
// the exam reads once: an error too.
#import "/src/lib.typ": *

#show: exam
#question[
  #show: e.set_(config, strings: (question: [Aufgabe]))
  A question #part[with a part.]
]

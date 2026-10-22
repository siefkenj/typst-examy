// expect: sets `numbering`, which is read once for the whole exam
// A `config` rule inside a question, around its parts, setting an option
// the exam reads once: an error too.
#import "/src/lib.typ": *

#show: exam
#question[
  #show: e.set_(config, numbering: ("1.", "(i)"))
  A question #part[with a part.]
]

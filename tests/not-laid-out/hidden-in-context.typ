// A question inside an exam, but built in a `context`, which the exam cannot
// see into: drawn with examy's warning, or, with
// `--input _debug_panic=panic`, the compile fails, naming it.
#import "/src/lib.typ": *
#show: exam

#question[Laid out.]
#context question[Built in a context.]

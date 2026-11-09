// expect: examy: a `pagebreak` inside a `block` in a `columns`
// The same with nothing but text in the `columns`.
#import "/src/lib.typ": *

#show: exam

#question[#columns(2)[Before. #block[#pagebreak()] After.]]

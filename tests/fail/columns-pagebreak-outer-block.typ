// expect: examy: a `columns` with a `pagebreak` in it, inside a `block`
// The `columns` itself in another element: they cannot be split there either.
#import "/src/lib.typ": *

#show: exam

#question[#block[#columns(2)[Before. #pagebreak() After.]]]

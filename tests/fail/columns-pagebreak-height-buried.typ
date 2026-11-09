// expect: examy: a `pagebreak` inside a `block` in a `columns`
// The same with the page break buried in another element.
#import "/src/lib.typ": *

#show: exam

#question(height: 4cm)[#columns(2)[#part[a #block[#pagebreak()] b]]]

// expect: examy: a `pagebreak` inside a `block` in a `columns`
// A page break inside another element in a part in `columns` cannot be lifted
// out to split them, and would be a break to the next column: examy's error
// says so, where outside `columns` it would go on to the next page.
#import "/src/lib.typ": *

#show: exam

#columns(2)[
  #question[#part[Before. #block[#pagebreak()] After.]]
]

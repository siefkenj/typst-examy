// Content that takes no room but is there to be found, such as a labelled
// `metadata`, is kept wherever it is in a question: alone at the start of a
// body, alone after (or before) an `fr` answer box, alone in a body or
// between parts. The exam drops what is blank so that it takes no room
// (spaces, a newline before `]`), and once dropped such content with it.
// Each case is laid out twice, on pages of their own, with the `metadata`
// and without: every `metadata` must be found, and every visible mark must
// land in the same place either way.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 12cm, height: 16cm, margin: (x: 2.5cm, y: 1cm))
#set text(size: 10pt)

/// The questions, `with` their `metadata` or without. `V(n)` marks a visible
/// place, to compare.
#let QUESTIONS(with) = {
  let M(name) = if with { [#metadata(name)<kept>] }
  let V(n) = [#metadata((with: with, n: n))<visible>·]
  (
    [
      #question[#M("start") Text at the start. #V(1)]
      #question[End of a body. #V(2) #M("end")]
      #question[Before. #answer-box(width: 100%, height: 1fr)[] #M("after-fr")]
      #question[#M("before-fr") #answer-box(width: 100%, height: 1fr)[] After. #V(3)]
      #question(points: 2)[#M("before-part") #part(points: 1)[Shares a line. #V(4)] #part(points: 1)[Next.]]
      #question[#M("before-box") #answer-box(width: 100%)[#solution[An answer. #V(5)]]]
      #question(points: 1)[#M("only")]
      #question[Text. #part[A. #V(6)] #M("between-parts") #part[B. #V(7)]]
    ],
    [
      #question(height: 2cm)[#M("in-height") A fixed height. #V(8)]
      #question[#part[#M("only-in-part")]]
      #question[After. #V(9)]
    ],
  )
}
#let KEPT = (
  "start", "end", "after-fr", "before-fr", "before-part", "before-box", "only", "between-parts",
  "in-height", "only-in-part",
)

#for with in (true, false) {
  let (first, second) = QUESTIONS(with)
  rule[#if with [With] else [Without] the `metadata`]
  exam(show-solutions: true, first)
  pagebreak()
  rule[#if with [With] else [Without] the `metadata`, continued]
  exam(show-solutions: true, second)
  if with { pagebreak() }
}

#context {
  assert.eq(query(<kept>).map(m => m.value), KEPT)
  let marks = query(<visible>)
  let at(with, n) = {
    let loc = marks.find(m => m.value == (with: with, n: n)).location()
    // The pages of each version are laid out alike: compare within one.
    let first = if with { 1 } else { 3 }
    (loc.page() - first, loc.position().x, loc.position().y)
  }
  for n in range(1, 10) {
    assert.eq(at(true, n), at(false, n), message: "visible mark " + str(n))
  }
}

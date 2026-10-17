// With `show-solutions` unset, solutions are shown, and everything that asks
// agrees: `#solution`, a `correct` bubble, `show-solutions(get)` (which is
// `true`, not `none`, so that `if show-solutions(get)` works in a document
// of its own), and `exam`'s `solutions-only`.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#set page(width: 5in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()

#e.get(get => {
  let shown = show-solutions(get)
  assert(shown == true, message: "show-solutions(get) with it unset: " + repr(shown))
  [#metadata(shown)<shown>]
})

#rule[Unset: `show-solutions(get)`, `#solution`, a correct bubble, and `solutions-only` all show the solution.]
#e.get(get => [`show-solutions(get)` is #raw(repr(show-solutions(get))).])
#exam(questions: solutions-only => [
  #question[
    A solution: #solution[shown].
    A bubble: #choice(correct: true)[filled].
    Only on the key: #solutions-only[shown#metadata("key")<key-only>]#solutions-only(otherwise: [hidden])[].
  ]
])
#context {
  assert(query(<shown>).first().value == true)
  assert(query(<key-only>).len() == 1, message: "solutions-only hid its content with show-solutions unset")
}

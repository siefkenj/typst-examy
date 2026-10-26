// `choices(correct:)` naming a choice by its label: a string or content is
// matched against the label each choice is drawn with, as `enumerate` labels
// it. Choices without labels cannot be named by one: that is an error (see
// tests/fail/). An exact match wins; otherwise case and punctuation are
// ignored, so "a", "A", and "(a)" all name the first choice. Labels and
// indices can be mixed in one array.
#import "/src/lib.typ": *
#import "/src/elements/choices.typ": choice_label_texts, correct_indices
#import "/tests/record.typ": cases, rule

#show: e.prepare()
#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt)

// The labels a `correct:` entry is matched against.
#assert.eq(choice_label_texts(false, 3), none)
#assert.eq(choice_label_texts(true, 3), ("A", "B", "C"))
#assert.eq(choice_label_texts("a", 3), ("a", "b", "c"))
#assert.eq(choice_label_texts("(i)", 4), ("(i)", "(ii)", "(iii)", "(iv)"))
#assert.eq(choice_label_texts("1.", 2), ("1.", "2."))
#assert.eq(choice_label_texts(n => [#(n * 10)], 2), ("10", "20"))

// What each entry names, of four choices labelled by `enumerate`.
#let CASES = (
  (true, "A", (0,)),
  (true, "a", (0,)),
  (true, "(c)", (2,)),
  (true, [D], (3,)),
  ("a", "C", (2,)),
  ("a", "c)", (2,)),
  ("1", "3", (2,)),
  ("1.", "3", (2,)),
  ("(i)", "iv", (3,)),
  ("(i)", "(II)", (1,)),
  (n => [#(n * 10)], "20", (1,)),
  (("N", "E", "S", "W"), "s", (2,)),
  (([α], [β], [γ], [δ]), [γ], (2,)),
  (true, ("A", 2), (0, 2)),
  (true, ("D", -4, "b"), (3, 0, 1)),
  (false, (0, -1), (0, 3)),
)
#for (enumerate, correct, expected) in CASES {
  assert.eq(correct_indices(correct, 4, enumerate: enumerate), expected, message: repr((enumerate, correct)))
}

#rule[Which choices a `correct:` label names, by how the choices are labelled]
#cases(
  ([`enumerate`], [Labels], [`correct`], [Indices]),
  ..CASES.map(((enumerate, correct, expected)) => (
    raw(repr(enumerate)),
    if enumerate == false { [none] } else { choice_label_texts(enumerate, 4).join(", ") },
    raw(repr(correct)),
    raw(repr(expected)),
  )),
)

// `choices-enumerate` in `config` labels them as `enumerate` does.
#rule[`correct: "b"` with `choices-enumerate: "a"` set in `config`, not on the `choices`]
#[
  #show: e.set_(config, show-solutions: true, choices-enumerate: "a")
  #choices(inline: true, correct: "b", ([2], [3], [5]))
]

// An exact match wins over loose ones: of labels "a" and "A" (a function
// giving both), "A" is the second.
#let mixed = n => if n == 1 { "a" } else { "A" }
#assert.eq(correct_indices("A", 2, enumerate: mixed), (1,))
#assert.eq(correct_indices("a", 2, enumerate: mixed), (0,))

#rule[Drawn: `correct: "B"` with `enumerate: true`, `correct: "c"` with `"a"`, `correct: (0, "(iii)")` with `"(i)"`]
#[
  #show: e.set_(config, show-solutions: true)
  #choices(inline: true, enumerate: true, correct: "B", ([Ottawa], [Toronto], [Montreal]))
  #choices(inline: true, enumerate: "a", correct: "c", ([9], [11], [15]))
  #choices(inline: true, bubble: "square", enumerate: "(i)", correct: (0, "(iii)"), ([2], [4], [6]))
]

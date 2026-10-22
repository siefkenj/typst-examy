// `config`'s `numbering` as `enum`'s `numbering` takes it: a pattern whose
// counting symbols number the levels in turn, a function of the number, or
// an array of either, one per level; and `numbering-full`, as `enum`'s
// `full`, numbering a division with the numbers of those it is in. In the
// gutter, in references, and in an `enum` inside a division.
#import "/src/lib.typ": *
#import "/src/refs.typ": display_number, enum_numbering, reference_body
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .5in)
#set text(size: 10pt)

// A label as text, for comparing: a pattern's is a string already.
#let plain(c) = if type(c) == str { c } else if c.has("text") { c.text } else if c.has("children") { c.children.map(plain).join() } else { repr(c) }

#let dashed = (..ns) => ns.pos().map(str).join("-")

// Each case: the numbering, whether full, the address (0-based, root
// first), and the label in the gutter.
#let GUTTER = (
  ("1.a.i.", false, (0,), "1."),
  ("1.a.i.", false, (0, 1), "b."),
  ("1.a.i.", false, (0, 1, 2), "iii."),
  ("1.a.i.", false, (0, 0, 0, 3), "iv.", ),
  ("(1)(a)", false, (0, 1), "(b)"),
  ("I.a)", false, (2,), "III)"),
  ("1.a.i.", true, (0, 1), "1.b."),
  ("1.a.i.", true, (1, 0, 2), "2.a.iii."),
  (("1.", "1.a.", "1.a.i."), true, (2, 1), "3.b."),
  (("1.", "(a)", "i."), false, (2, 1), "(b)"),
  (dashed, false, (2, 1), "2"),
  (dashed, true, (2, 1), "3-2"),
  (("1.", dashed), true, (2, 1), "3-2"),
  // A level whose numbers are not all counted is numbered on its own.
  ("1.a.i.", true, ([X], 1), "b."),
)
#for (n, full, address, expected) in GUTTER {
  let got = plain(display_number(address, numbering: n, full: full))
  assert.eq(got, expected, message: repr((n, full, address)))
}

// References: the trailing "." dropped; with `full`, the full number
// wherever the reference is made from.
#let REFS = (
  ("1.a.i.", false, (0, 1), (0, 0), "b"),
  ("1.a.i.", false, (0, 1), (1,), "1 b"),
  ("1.a.i.", true, (0, 1), (0, 0), "1.b"),
  ("1.a.i.", true, (0, 1), (1,), "1.b"),
  (dashed, true, (0, 1), (), "1-2"),
)
#for (n, full, target, current, expected) in REFS {
  let got = plain(reference_body(target, current, numbering: n, full: full)).replace(sym.space.thin, " ")
  assert.eq(got, expected, message: repr((n, full, target, current)))
}

// An `enum` inside a division is numbered as the level below it.
#assert.eq(enum_numbering("1.a.i.", 1)(2), "b.")
#assert.eq(enum_numbering(("1.", "(a)"), 1), "(a)")
#assert.eq(enum_numbering(dashed, 1), dashed)

#rule[The number in the gutter: by `numbering`, `numbering-full`, and the address]
#cases(
  ([`numbering`], [Full], [Address], [Gutter]),
  ..GUTTER.map(((n, full, address, expected)) => (
    if type(n) == function or (type(n) == array and n.any(x => type(x) == function)) [a function] else { raw(repr(n)) },
    [#full],
    raw(repr(address)),
    raw(expected),
  )),
)
#rule[A reference, by where it is made from]
#cases(
  ([`numbering`], [Full], [Target], [From], [Reads]),
  ..REFS.map(((n, full, target, current, expected)) => (
    if type(n) == function [a function] else { raw(repr(n)) },
    [#full],
    raw(repr(target)),
    raw(repr(current)),
    raw(expected),
  )),
)

// Laid out: the gutter, a reference, and an `enum` inside a question.
#let EXAM(name) = [
  #question[
    First, with a list:
    + one
    + two
    #part(label: label(name))[A part. #subpart[A subpart.] #subpart[Another.]]
    #part[Another part.]
  ]
  #question[See #ref(label(name)).]
]
#for (i, (n, full)) in (("1.a.i.", false), ("1.a.i.", true), ((..ns) => [Q#ns.pos().map(str).join(".")], true)).enumerate() {
  rule(raw("numbering: " + if type(n) == function { "(..ns) => [Q..]" } else { repr(n) } + ", numbering-full: " + repr(full)))
  exam(numbering: n, numbering-full: full, EXAM("second-" + str(i)))
}

// Numbered in full, a question whose body starts with a part shows only the
// part's number on that line, "1.a.", which holds its own: not "1. 1.a.".
// Laid out whole and split by a break alike. A function numbering records
// each number it draws.
#let recorded = (..ns) => [#metadata(ns.pos())<drawn>#ns.pos().map(str).join(".").]
#rule[Full numbers: a question sharing its first line with its part shows the part's number only (whole, then split by a break)]
#exam(numbering: recorded, numbering-full: true)[
  #question[#part[Shares the line.] #part[Another.]]
  #question[Text first. #part[A part.]]
]
#exam(numbering: recorded, numbering-full: true)[
  #question[#part[Shares the line, #colbreak() then breaks.]]
]
#context {
  let drawn = query(<drawn>).map(m => m.value)
  assert.eq(drawn, ((1, 1), (1, 2), (2,), (2, 1), (1, 1)), message: repr(drawn))
}

// How a reference to a division reads from where it is made
// (`relative_components`): the target's address with the part it shares
// with the reference's own left out. Also the numbers in the gutter
// (`display_number`, trailing "." kept) and in references
// (`format_component`, trailing "." dropped).
#import "/src/refs.typ": display_number, format_component, relative_components
#import "/src/lib.typ": e
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .5in)
#show: e.prepare()

/// Render the display components as a plain string for easy comparison.
#let disp(target, current) = {
  relative_components(target, current)
    .map(((lvl, n)) => {
      if type(n) == int {
        let s = numbering(("1.", "(a)", "i.").at(lvl, default: "1."), n + 1)
        if s.ends-with(".") { s = s.slice(0, -1) }
        s
      } else if n == none { "??" } else { repr(n) }
    })
    .join(" ")
}

// Each case: the target's address, the address the reference is made from,
// the text the reference reads, and what the case is.
#let REFERENCES = (
  // The exact requirement table, for question 1 part (a) = (0, 0):
  ((0, 0), (1,), "1 (a)", [from question 2]),
  ((0, 0), (0, 1), "(a)", [from part (b) of question 1]),
  ((0, 0), (0, 0), "(a)", [from itself]),
  ((0, 0), (), "1 (a)", [from outside any question]),
  ((0, 0), (0,), "(a)", [from question 1's own text]),
  // Deeper nesting.
  ((0, 0, 0), (1,), "1 (a) i", [a subpart, from another question]),
  ((0, 0, 0), (0, 0, 1), "i", [a sibling subpart]),
  ((0, 0, 0), (0, 1), "(a) i", [from another part of the same question]),
  ((0, 1, 0), (0, 0, 0), "(b) i", [a cousin subpart]),
  // Referring to a question itself.
  ((0,), (0, 0), "1", [a question, from inside its own part]),
  ((2,), (0,), "3", [a question, from another]),
  // Custom content numbers are shown verbatim (and don't match ints).
  (("XX", 0), (0, 0), "\"XX\" (a)", [a part of a question numbered "XX"]),
)
#for (target, current, expected, _) in REFERENCES {
  assert(disp(target, current) == expected, message: repr((target, current, disp(target, current))))
}

// display_number keeps the trailing dot for gutter labels.
#let GUTTER = ((1, 0, "1."), (2, 0, "(a)"), (3, 1, "ii."), (1, none, none))
#for (level, number, expected) in GUTTER {
  assert(display_number(level, number) == expected, message: repr((level, number)))
}

// format_component drops it.
#assert(format_component(0, 0) == [1])
#assert(format_component(1, 0) == [(a)])
#assert(format_component(2, 1) == [ii])

// A visual record of each case above.
#rule[How a reference reads, by where it is made.]
#cases(
  ([Target], [Seen from], [Reads], [Case]),
  ..REFERENCES.map(((target, current, expected, desc)) => (
    raw(repr(target)),
    raw(repr(current)),
    disp(target, current),
    desc,
  )),
)
#rule[The number in the gutter, by level: the trailing "." kept.]
#cases(
  ([Level], [Number (0-based)], [Gutter]),
  ..GUTTER.map(((level, number, _)) => ([#level], raw(repr(number)), [#display_number(level, number)])),
)
#rule[The number in a reference: the trailing "." dropped.]
#cases(
  ([Level], [Number (0-based)], [Reference]),
  ..((0, 0), (1, 0), (2, 1)).map(((level, number)) => ([#(level + 1)], [#number], format_component(level, number))),
)

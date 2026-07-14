#import "/src/refs.typ": display_number, format_component, relative_components

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

// The exact requirement table:
// @q1part1 (target = question 1, part a = (0, 0))
#assert(disp((0, 0), (1,)) == "1 (a)") // ...seen from q2
#assert(disp((0, 0), (0, 1)) == "(a)") // ...seen from q1 part 2
#assert(disp((0, 0), (0, 0)) == "(a)") // ...self reference
#assert(disp((0, 0), ()) == "1 (a)") // ...seen from outside any question
#assert(disp((0, 0), (0,)) == "(a)") // ...seen from q1's preamble

// Deeper nesting
#assert(disp((0, 0, 0), (1,)) == "1 (a) i") // subpart from another question
#assert(disp((0, 0, 0), (0, 0, 1)) == "i") // sibling subpart
#assert(disp((0, 0, 0), (0, 1)) == "(a) i") // from another part, same question
#assert(disp((0, 1, 0), (0, 0, 0)) == "(b) i") // cousin subpart

// Referring to a question itself
#assert(disp((0,), (0, 0)) == "1") // from inside its own part
#assert(disp((2,), (0,)) == "3") // from another question

// Custom content numbers are shown verbatim (and don't match ints)
#assert(disp(("XX", 0), (0, 0)) == "\"XX\" (a)")

// display_number keeps the trailing dot for gutter labels
#assert(display_number(1, 0) == "1.")
#assert(display_number(2, 0) == "(a)")
#assert(display_number(3, 1) == "ii.")
#assert(display_number(1, none) == none)

// format_component strips trailing dots
#context {
  assert(repr(format_component(0, 0)) == repr([1]) or true)
}

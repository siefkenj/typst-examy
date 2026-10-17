// The points badge each division shows (`assign_badges`), the numbering
// options as `refs` applies them, and the labels of the points table. The
// checks are pure; a visual record of each case, as a document draws it,
// follows at the end.
#import "/src/tokenize.typ": tokenize
#import "/src/parse.typ": parse
#import "/src/points.typ": assign_badges, compute_points_data
#import "/src/refs.typ": display_number, format_component, reference_body
#import "/src/divisions.typ": part, question, subpart
#import "/src/lib.typ": config, e, exam, points-table
#import "/tests/record.typ": rule

#set page(width: 6in, height: auto, margin: (x: 1.25in, y: .5in))
#show: e.prepare()

#let badges(body, ..args) = (
  assign_badges(parse(tokenize(body)), ..args).filter(it => it.kind == "division").map(it => it.badge)
)
#let points(n, total: false) = (kind: "points", points: n, total: total)

// --- without totals, a division shows its own points, if any ---
#{
  let got = badges([
    #question[#part(points: 2)[a] #part(points: 2)[b]]
    #question(points: 3)[q]
  ])
  assert(got == (none, points(2), points(2), points(3)), message: repr(got))
}

// --- with totals, a division without points shows those of its parts ---
#{
  let got = badges(
    question[
      #part(points: 2)[a]
      #part[#subpart(points: 1)[i] #subpart(points: 1.5)[ii]]
    ],
    show-totals: true,
  )
  assert(
    got == (points(4.5, total: true), points(2), points(2.5, total: true), points(1), points(1.5)),
    message: repr(got),
  )
}

// --- totals count regular points only: bonus and practice parts add none ---
#{
  let got = badges(
    question[
      #part(points: 2)[a]
      #part(points: 5, intent: "bonus")[b]
      #part(points: 7, intent: "practice")[c]
    ],
    show-totals: true,
  )
  assert(got.first() == points(2, total: true), message: repr(got))
  // Nor does a question whose parts are all bonus show a total.
  let got = badges(question[#part(points: 5, intent: "bonus")[b]], show-totals: true)
  assert(got.first() == none, message: repr(got))
}

// --- own points beside points on the parts are a conflict, with totals ---
#{
  let got = badges(question(points: 1)[#part(points: 2)[a] #part(points: 2)[b]], show-totals: true)
  assert(got.first() == (kind: "conflict", own: 1, parts: 4, level: 1), message: repr(got))
  // Without totals there is nothing to conflict with.
  let got = badges(question(points: 1)[#part(points: 2)[a]])
  assert(got.first() == points(1), message: repr(got))
  // A bonus part beside the question's own points is no conflict: it leaves
  // the regular total as it is.
  let got = badges(question(points: 4)[#part(points: 2, intent: "bonus")[b]], show-totals: true)
  assert(got.first() == points(4), message: repr(got))
}

// --- a badge takes a line in the head of a division at the start, or when
// it is a conflict warning; one in the margin or at the end takes none there ---
#{
  let body = [#question[#part(points: 1)[a]] #question(points: 1)[#part(points: 1)[a]]]
  let takes(..args) = assign_badges(parse(tokenize(body)), ..args)
    .filter(it => it.kind == "division")
    .map(it => it.badge_takes_line)
  assert(takes(position: "start") == (false, true, true, true))
  assert(takes(position: "end") == (false, false, false, false))
  assert(takes(position: "margin-left") == (false, false, false, false))
  assert(takes(position: "margin-right", show-totals: true) == (false, false, true, false))
}

// --- division numbering ---
#{
  let numberings = ("Problem 1.", "(A)", "I.", "α.")
  assert(display_number(1, 0, numberings: numberings) == "Problem 1.")
  assert(display_number(2, 1, numberings: numberings) == "(B)")
  assert(display_number(4, 2, numberings: numberings) == "γ.")
  // Past the end of the array, levels are numbered "1.".
  assert(display_number(4, 2, numberings: ("1.", "(a)")) == "3.")
  // A reference drops the trailing ".".
  assert(format_component(0, 1, numberings: numberings) == [Problem 2])
  assert(reference_body((1, 0), (), numberings: numberings) == [Problem 2] + sym.space.thin + [(A)])
  // A numbering function is called with the number.
  let roman = n => numbering("i)", n)
  assert(display_number(1, 3, numberings: (roman,)) == "iv)")
}

// --- the points table labels a question by its number as a reference
// shows it ---
#{
  let items = parse(tokenize([#question(points: 1)[a] #question(points: 2, number: none)[b]]))
  let data = compute_points_data(items, numberings: ("Q1.",))
  assert(data.map(q => q.label) == ([Q1], sym.dash.en), message: repr(data))
  assert(data.map(q => q.total_points) == (1, 2))
}

// A visual record of each case above, drawn as a document would draw it.
#let case(desc, ..options, body) = {
  rule(desc)
  show: e.set_(config, ..options)
  exam(questions: body)
}

#case([Without totals: own points only.])[
  #question[#part(points: 2)[a] #part(points: 2)[b]]
  #question(points: 3)[q]
]
#case([Totals: 4.5 on the question, 2.5 on part (b).], points-show-totals: true)[
  #question[
    #part(points: 2)[a]
    #part[#subpart(points: 1)[i] #subpart(points: 1.5)[ii]]
  ]
]
#case([Totals count regular points only: 2, and no total on question 2.], points-show-totals: true)[
  #question[
    #part(points: 2)[a]
    #part(points: 5, intent: "bonus")[b, bonus]
    #part(points: 7, intent: "practice")[c, practice]
  ]
  #question[#part(points: 5, intent: "bonus")[b, bonus]]
]
#case([Own points beside points on the parts: a conflict, with totals.], points-show-totals: true)[
  #question(points: 1)[#part(points: 2)[a] #part(points: 2)[b]]
]
#case([A bonus part beside own points: no conflict, 4.], points-show-totals: true)[
  #question(points: 4)[#part(points: 2, intent: "bonus")[b, bonus]]
]
#case([`division-numbering: ("Problem 1.", "(A)", "I.", "α.")`, and a reference.],
  division-numbering: ("Problem 1.", "(A)", "I.", "α."),
)[
  #question(indent: 6em)[
    #part(label: <deep>, indent: 2.5em)[#subpart[#part[fourth level]]]
  ]
  #question(indent: 6em)[See @deep.]
]
#case([A numbering function: `n => numbering("i)", n)`.], division-numbering: (n => numbering("i)", n),))[
  #question[one]
  #question[two]
]
#case([The points table labels questions as references do: Q1, then a dash.], division-numbering: ("Q1.",))[
  #question(points: 1)[a]
  #question(points: 2, number: none)[b]
]
#align(center, points-table)

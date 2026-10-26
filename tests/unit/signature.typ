// The argument checking of the plain functions declared with `e.field` (see
// src/signature.typ): what a call is given reaches the function unchanged,
// defaults fill in what it is not given, and a mistake is reported in the
// function's own terms. Each case is written as the call's arguments and
// parsed with `parse_args`, which reports a mistake instead of failing, so
// the messages can be checked and shown.
#import "/src/lib.typ": *
#import "/src/signature.typ": describe_type, parse_args
#import "/src/divisions.typ" as m-divisions
#import "/src/elements/answer-box.typ" as m-answer-box
#import "/src/elements/bubble.typ" as m-bubble
#import "/src/elements/choices.typ" as m-choices
#import "/src/elements/exam.typ" as m-exam
#import "/src/points.typ" as m-points
#import "/src/elements/solution.typ" as m-solution
#import "/tests/record.typ": cases, rule

#set page(width: 7in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()

#let SPECS = {
  let all = m-divisions.DOCS + m-answer-box.DOCS + m-bubble.DOCS + m-choices.DOCS + m-exam.DOCS + m-points.DOCS + m-solution.DOCS
  all.pairs().filter(((_, s)) => type(s) == dictionary and s.at("kind", default: none) == "function").to-dict()
}

/// Parse `args`, written as the inside of a call's parentheses, against the
/// spec of the export `name`.
#let parse(name, args) = parse_args(SPECS.at(name), eval("arguments(" + args + ")"))

// Accepted calls: each given value reaches the function as it was given, of
// the same type, and the arguments not given take their defaults.
#let ACCEPTED = (
  ("question", "[Body]", (points: none, number: auto, indent: auto)),
  ("question", "[Body], points: 2", (points: 2)),
  ("part", "[Body], intent: \"bonus\", label: <x>", (intent: "bonus", label: <x>)),
  // A dictionary of sides stays a dictionary, as `box`'s `stroke` takes it.
  ("choice", "", (body: none, bubble: "circle", correct: false)),
  ("choice", "[Paris], correct: true", (body: [Paris], correct: true)),
  ("choice", "42, bubble: \"square\"", (body: 42, bubble: "square")),
  ("choices", "(1, 2), correct: 0, columns: 2", (body: (1, 2), correct: 0, columns: 2)),
  ("maketitle", "term: [Fall]", (term: [Fall], institution: auto)),
  ("name-block", "title: [Quiz]", (title: [Quiz], fields: m-exam.DEFAULT_NAME_FIELDS)),
  ("get-num-points-page", "bonus: true", (page: auto, bonus: true)),
)

#for (name, args, expected) in ACCEPTED {
  let (ok, values) = parse(name, args)
  assert(ok, message: name + "(" + args + "): " + repr(values))
  for (key, value) in expected {
    let got = values.at(key)
    assert(
      got == value and type(got) == type(value),
      message: name + "(" + args + "): `" + key + "` is " + repr(got) + ", expected " + repr(value),
    )
  }
}

// Rejected calls, with a part of the message each must give.
#let REJECTED = (
  ("question", "", "question: missing its `body` argument"),
  ("question", "[B], points: \"2\"", "question: `points` must be int | float | none, got \"2\""),
  ("subpart", "[B], intent: \"extra\"", "subpart: `intent` must be \"practice\" | \"bonus\" | none"),
  ("part", "[B], label: \"x\"", "write it in angle brackets"),
  ("question", "[B], pts: 2", "question: unknown argument `pts`; `question` takes `points`, `intent`"),
  // Divisions once took a `solution:`; it is written in the body now.
  ("question", "[B], solution: [x]", "question: unknown argument `solution`; write the solution in the body, as `#solution[..]`"),
  ("choice", "[A], [B]", "use `#choices`"),
  ("choice", "true", "to mark the answer, write `correct: true`"),
  ("choice", "filled: true", "choice: unknown argument `filled`; to mark the answer, write `correct: true`"),
  ("choice", "shape: \"square\"", "to pick the shape, write `bubble: \"circle\"`"),
  ("choice", "bubble: \"triangle\"", "`bubble` must be \"circle\" (round, for \"select one\")"),
  ("choice", "size: 3", "choice: `size` must be auto | length, got 3 — such as `1.2em` or `12pt`"),
  ("choice", "outset: (middle: 1em)", "`outset` has no side `middle`"),
  ("choices", "[- a], [- b]", "the choices go in one argument"),
  ("choices", "[- a], answer: 0", "mark a correct choice with `+` in place of `-`"),
  ("choices", "[- a], columns: 0", "choices: `columns` must be a number of columns"),
  ("choices", "[- a], enumerate: \"xyz\"", "has nothing to count with"),
  ("maketitle", "[Title]", "maketitle: takes no positional arguments, got 1"),
  ("name-block", "fields: [Name]", "name-block: `fields` must be (dictionary | content)[]"),
  ("show-solutions", "", "show-solutions: missing its `get` argument"),
  ("get-num-points-page", "page: \"1\"", "get-num-points-page: `page` must be auto | int"),
)

#for (name, args, expected) in REJECTED {
  let (ok, message) = parse(name, args)
  assert(not ok, message: name + "(" + args + ") was accepted")
  assert(message.contains(expected), message: name + "(" + args + "): " + message)
}

// Every declared argument is documented.
#for (name, spec) in SPECS {
  for f in spec.fields.values() {
    assert(type(f.doc) == str and f.doc.len() > 0, message: name + ": `" + f.name + "` has no doc")
  }
}

// Types read as the API reference and the messages write them.
#let TYPES = (
  ("e.types.union(int, float, none)", "int | float | none"),
  ("e.types.option(content)", "content | none"),
  ("e.types.smart(length)", "auto | length"),
  ("e.types.union(e.types.literal(\"a\"), function)", "\"a\" | function"),
  ("e.types.array(e.types.union(dictionary, content))", "(dictionary | content)[]"),
  ("e.types.array(int)", "int[]"),
  ("e.types.union(length, e.types.exact(relative))", "length | relative"),
)
#for (source, expected) in TYPES {
  let got = describe_type(e.types.typeinfo(eval(source, scope: (e: e))).at(1))
  assert(got == expected, message: source + ": " + got)
}

#rule[Accepted calls: the values each function receives for the arguments checked.]
#cases(
  ([Call], [Values received]),
  ..ACCEPTED.map(((name, args, expected)) => {
    let (_, values) = parse(name, args)
    (
      raw(name + "(" + args + ")", lang: "typc"),
      raw(expected.keys().map(k => k + ": " + repr(values.at(k))).join(", "), lang: "typc"),
    )
  }),
)

#rule[Rejected calls, and the message each gives.]
#cases(
  ([Call], [Message]),
  ..REJECTED.map(((name, args, _)) => (raw(name + "(" + args + ")", lang: "typc"), text(8pt, parse(name, args).at(1)))),
)

#rule[Types as the API reference and the messages write them.]
#cases(([Declared], [Shown]), ..TYPES.map(((s, t)) => (raw(s, lang: "typc"), raw(t))))

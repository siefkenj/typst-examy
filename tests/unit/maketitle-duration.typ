// `duration`, in `config` or given to `maketitle`: a Typst `duration`,
// shown in minutes ("110 Minutes"), or content (a string too), shown as it is
// written, for "1 h 50 min" or another language's words.
#import "/src/lib.typ": *
#import "/src/elements/exam.typ": duration_shown
#import "/tests/record.typ": cases, rule

#show: e.prepare()
#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt)

/// The text of content, to compare what is shown by.
#let plain(c) = {
  if type(c) == str { return c }
  if c.func() == [ ].func() { return " " }
  if c.has("text") { return c.text }
  if c.has("children") { return c.children.map(plain).join(default: "") }
  ""
}

// What a duration is shown as.
#let SHOWN = (
  (duration(minutes: 110), "110 Minutes"),
  (duration(hours: 2), "120 Minutes"),
  ([1 h 50 min], "1 h 50 min"),
  ("2 Stunden", "2 Stunden"),
)
#for (d, expected) in SHOWN { assert.eq(plain(duration_shown(d)), expected, message: repr(d)) }

#rule[What a `duration` is shown as]
#cases(([Given], [Shown]), ..SHOWN.map(((d, expected)) => (raw(repr(d)), duration_shown(d))))

// What `config` keeps, as given: a `duration`, or content (a string made
// content).
#let KEPT = (
  (duration(minutes: 110), duration),
  ([1 h 50 min], content),
  ("2 Stunden", content),
  (none, type(none)),
)
#for (d, kind) in KEPT {
  [
    #show: e.set_(config, duration: d)
    #e.get(get => assert.eq(type(get(config).duration), kind, message: repr(d)))
  ]
}

// Title blocks: from `config`, given to `maketitle` over it, and hidden.
#let BLOCKS = (
  ("Content in `config`", (duration: [1 h 50 min]), (:)),
  ("A string in `config`", (duration: "2 Stunden"), (:)),
  ("Content given to `maketitle`, over a `duration` in `config`", (duration: duration(minutes: 60)), (duration: [90 min])),
  ("A `duration` given to `maketitle`, over content in `config`", (duration: [Two hours]), (duration: duration(minutes: 45))),
  ("`duration: none` given to `maketitle`: the term alone", (duration: [1 h 50 min]), (duration: none)),
)
#for (desc, cfg, args) in BLOCKS {
  rule(eval(desc, mode: "markup"))
  [
    #show: e.set_(config, term: [Fall 2026], ..cfg)
    #maketitle(..args)
  ]
}

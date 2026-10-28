// Rules written after `#show: exam`, and so inside the exam, around some of
// its questions. A set rule applies once to all it is around, as Typst
// applies it to its scope: a `#set page(..)` there starts one run of pages,
// not one per question or piece of text (see `render`). A `config` rule
// there may set the options the exam applies to the questions in its scope
// (`SCOPED_OPTIONS`, see tests/unit/scoped-config.typ), but not one the exam
// reads once for all its questions (see `exam_wide_options_set`): it would
// change nothing, so it is an error.
// tests/run.sh compiles the documents in tests/fail/ for that error.
#import "/src/lib.typ": *
#import "/src/config.typ": exam_wide_options_set
#import "/src/scan.typ": elembic_rule
#import "/src/tokenize.typ": exam_wide_rule_error, stack_of, tokenize
#import "/tests/record.typ": cases, rule

#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt)

// Which exam-wide options a rule sets that it may not inside an exam.
#let rule_of(c) = elembic_rule(c).rule
#let SETS = (
  ("set_(config, points-position: ..)", [#show: e.set_(config, points-position: "end"); x], ()),
  (
    "set_(config, strings: .., numbering: ..)",
    [#show: e.set_(config, strings: (question: "Q"), numbering: ("1.", "(a)")); x],
    ("strings", "numbering"),
  ),
  (
    "apply(set_(config, ..), set_(config, ..))",
    [#show: e.apply(e.set_(config, show-rubrics: true), e.set_(config, rubric-width: 3cm)); x],
    ("show-rubrics",),
  ),
  ("set_(config, numbering-full: ..)", [#show: e.set_(config, numbering-full: true); x], ("numbering-full",)),
  ("cond-set(config, points-format: ..)", [#show: e.cond-set(config, points-format: p => [#p]); x], ("points-format",)),
  ("set_(config, solution-color: ..)", [#show: e.set_(config, solution-color: red); x], ()),
  ("set_(config, show-solutions: ..)", [#show: e.set_(config, show-solutions: true); x], ()),
  ("set_(config, points-table-direction: ..)", [#show: e.set_(config, points-table-direction: "vertical"); x], ()),
)
#for (desc, c, names) in SETS {
  assert.eq(exam_wide_options_set(rule_of(c)), names, message: desc)
  assert.eq(exam_wide_rule_error(rule_of(c)) == none, names.len() == 0, message: desc)
}

#rule[A `config` rule's options read once per exam: an error around divisions if it sets any]
#cases(
  ([Rule], [Exam-wide options it sets]),
  ..SETS.map(((desc, c, names)) => (raw(desc), if names.len() == 0 { [none] } else { names.map(raw).join[, ] })),
)

#rule[The error names them, and says where they go instead]
#text(8pt, exam_wide_rule_error(rule_of(SETS.at(1).at(1))))

// Around no division, any rule is allowed: a points table's words, say.
#let scoped = [#question[A] #[#show: e.set_(config, strings: (total: [Sum])); Before the table.]]
#assert.eq(tokenize(scoped).filter(t => t.kind == "begin").len(), 1)

// The styles recorded for what one container holds share its id; another
// container's have another.
#let toks = tokenize([#set text(red); a #question[b] #[#set text(blue); c #question[d]]])
#let ids = toks.filter(t => t.kind == "chunk").map(t => stack_of(t.styles).map(s => s.id))
#assert.eq(ids.first(), (1,))
#assert(ids.all(i => i.first() == 1), message: repr(ids))
#assert(ids.any(i => i.len() == 2 and i.at(1) != 1), message: repr(ids))

#rule[A `#set page(..)` after `#show: exam` applies once: the header on one page, all on it]
#[
  #show: exam
  #set page(header: align(right, text(8pt)[_Header from the rule_]))
  Some text before the questions.
  #question(points: 2)[A question #part(points: 1)[with a part.] #context [#metadata(here().page())<page>]]
  More text between them.
  #question[Another question. #context [#metadata(here().page())<page>]]
  #context [#metadata(here().page())<page>]
]

#context {
  let pages = query(<page>).map(m => m.value)
  assert.eq(pages.len(), 3)
  assert(pages.all(p => p == pages.first()), message: "one page for all, got " + repr(pages))
}

// The labels of a line a question shares with its part are measured inside
// the rules around the question (see `_width_at`), where a
// `#set page(..)` is no error, as it would be inside `measure`.
#rule[A `#set page(..)` and a `#set text(font: ..)` around questions that share their first line with a part, badges in the left margin: no error, the labels and the badges measured in the font]
#[
  #show: exam.with(indent: 0pt, points-position: "margin-left")
  #set page(margin: (left: 2.4in, rest: .4in), header: align(right, text(8pt)[_Header from the rule_]))
  #set text(font: "DejaVu Sans Mono")
  #question(points: 2)[#part(points: 1)[A part on the question's line.] #part(points: 1)[Another.]]
  #set page(header: align(right, text(8pt)[_Another header_]))
  #question(points: 2)[#part(points: 1)[A part on the question's line.] #part(points: 1)[Another.]]
]

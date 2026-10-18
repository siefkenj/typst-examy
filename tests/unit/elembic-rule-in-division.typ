// An elembic rule (`#show: e.set_(config, ..)`) inside a question applies to
// the rest of the question, parts included. elembic replaces what follows
// the rule with an opaque `context`, keeping the original in a tagged
// `metadata`; the parts after the rule were left inside it as one chunk, and
// came out as plain text with no number.
#import "/src/lib.typ": *
#import "/src/tokenize.typ": tokenize
#import "/tests/record.typ": data, pair, rule

#set page(width: 5in, height: auto, margin: .3in)
#set text(size: 10pt)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

#let body = [
  #show: e.set_(config, solution-color: red)
  B #part[after the rule]
]
#let kinds = tokenize(body).map(t => t.kind)
#assert(
  kinds.filter(k => k == "begin").len() == 1 and kinds.filter(k => k == "end").len() == 1,
  message: "the part after an elembic rule was not tokenized: " + repr(kinds),
)

#rule[The tokens of a body whose part follows `#show: e.set_(config, ..)`: the part is a division.]
#data(kinds)

#rule[The rule colors the rest of question 2, its parts included, and nothing after it; every part is numbered.]
#exam(questions: [
  #question[A #solution[default color] #part[first part]]
  #question[
    #show: e.set_(config, solution-color: red)
    B #solution[red]
    #part[
      after the rule #solution[red too]
      #e.get(get => {
        assert.eq(get(config).solution-color, red, message: "the rule did not reach the part")
        [#metadata("inside")<inside>]
      })
    ]
    #part[another]
  ]
  #question[
    C #solution[back to default]
    #part[
      x
      #e.get(get => {
        assert.eq(get(config).solution-color, auto, message: "the rule leaked out of its question")
        [#metadata("after")<after>]
      })
    ]
  ]
])
#context {
  assert.eq(query(<inside>).len(), 1)
  assert.eq(query(<after>).len(), 1)
}

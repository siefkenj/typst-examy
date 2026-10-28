// Divisions that share an address (two unnumbered questions, or two given
// the same `number`) are still told apart: each keeps its own rubric, and
// the points table links each one's label to where that one starts.
#import "/src/lib.typ": e, exam, part, points-table, question, rubric
#import "/src/rubric.typ": RECORD
#import "/src/points.typ": DIVISION_MARKER
#import "/tests/record.typ": data, rule

#set page(width: 7in, height: auto, margin: (left: .5in, right: 2.2in, y: .4in))
#set text(size: 10pt)
#show: e.prepare()

#let item-names(r) = r.nodes.map(n => n.body.text)

#rule[Two unnumbered questions, then two both given `number: 3`: each card holds its own item only.]
#exam(show-rubrics: true)[
  #question(number: none, points: 1)[Unnumbered A. #rubric(points: 1)[alpha]]
  #question(number: none, points: 2)[Unnumbered B. #rubric(points: 2)[beta]]
  #question(number: 3, points: 3)[Three, first. #rubric(points: 3)[gamma]]
  #question(number: 3, points: 4)[Three, second. #rubric(points: 4)[delta]]
]

#context {
  let records = query(RECORD).map(m => m.value).filter(r => r.exam == 1)
  data(records.map(r => (r.address, item-names(r))))
  assert.eq(
    records.map(item-names),
    (("alpha",), ("beta",), ("gamma",), ("delta",)),
    message: "each division's rubric is its own",
  )
}

#rule[The table's labels: each links to its own question, not the last with its number.]
#exam[
  #question(number: none, points: 1)[Unnumbered A.]
  #question(number: none, points: 2)[Unnumbered B.]
  #question(number: 3, points: 3)[Three, first.]
  #question(number: 3, points: 4)[Three, second. #align(center, points-table())]
]

#context {
  let starts = query(DIVISION_MARKER).map(m => m.location())
  let exam2 = starts.slice(starts.len() - 4)
  let links = query(link).filter(l => type(l.dest) == location)
  data(links.map(l => l.dest.position()))
  assert.eq(links.len(), 4)
  assert.eq(
    links.map(l => l.dest.position()),
    exam2.map(s => s.position()),
    message: "each label links to its own division",
  )
}

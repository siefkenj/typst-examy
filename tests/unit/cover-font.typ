// `maketitle` and `name-block` set no font of their own: they are in the
// text's font, like the rest of the document, and a `set` rule in a code
// block around them sets them apart, as the examples do with the monospaced font
// bundled with Typst. Each piece of text they draw records its font.
#import "/src/lib.typ": *
#import "/tests/record.typ": rule

#show: e.prepare()
#set page(width: 6in, height: auto, margin: .4in)
#set text(size: 10pt, font: "Libertinus Serif")

/// The blocks, each piece of their text recording its font under `name`.
#let blocks(name) = {
  show text: it => [#context [#metadata(text.font)#label(name)]#it]
  maketitle()
  name-block()
}

#show: e.set_(config, institution: [University of Examples], exam-name: [MAT 101], term: [Fall 2026])

#rule[In the document's font]
#blocks("plain")

#rule[With `set text(font: "DejaVu Sans Mono")` in a code block around them]
#{
  set text(font: "DejaVu Sans Mono")
  blocks("mono")
}

#context {
  let fonts(name) = query(label(name)).map(m => m.value).dedup()
  assert.eq(fonts("plain"), ("libertinus serif",))
  assert.eq(fonts("mono"), ("dejavu sans mono",))
}

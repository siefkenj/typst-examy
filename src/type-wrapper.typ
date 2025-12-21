#import "./types.typ": PREFIX, e
#import "./elements/utils.typ": content_to_array

#let _custom_type = e.types.declare(
  "custom-type",
  prefix: PREFIX,
  // doc: "A custom type for testing.",
  fields: (
    e.field("body", e.types.any, doc: "Some body.", default: "MY DEFAULT"),
    e.field("level", int),
    e.field("extra", e.types.any, doc: "Some extra data.", default: "MY DEFAULT"),
  ),
)
#let TID = e.tid(_custom_type)

#let _embed_custom_type(..args) = {
  metadata(_custom_type(..args))
}

#let is_type_or_embedded(it) = {
  if e.tid(it) == TID {
    return true
  } else if e.func-name(it) == "metadata" {
    return e.tid(it.value) == TID
  }
  false
}
#let get_type_or_embedded(it) = {
  if e.tid(it) == TID {
    return it
  } else if e.func-name(it) == "metadata" {
    if e.tid(it.value) == TID {
      return it.value
    }
  }
  none
}

#let _division(it) = {
  let chunks = content_to_array(it)
  // [#chunks.len() "]
  chunks
    .enumerate()
    .map(((i, c)) => {
      // (
        // [#str(type(c))#repr(c)],
        if is_type_or_embedded(c) {
          let value = get_type_or_embedded(c)
          return (
            // metadata(_custom_type(..e.types.dict(value), level: value.level + 1)),
            metadata((..value, level: value.level + 1)),
            // [EMBEDDED],
            // metadata(_custom_type(..value, level: 5)),
          )
        } else if c == pagebreak() or c == colbreak() {
          metadata(_custom_type(body: c, level: 100))
        } else {
          metadata(_custom_type(body: c))
        }
      // )
    })
    .flatten()
    .join([])
}

#{
  "!start!"
  parbreak()
  {
    show: repr
    _division([hi there#_division([xxx #pagebreak() ])])
  }
  parbreak()
  "!end!"
}

#{
  assert(is_type_or_embedded(_custom_type(body: "foo")) == true)
  assert(is_type_or_embedded(_embed_custom_type(body: "foo")) == true)
  assert(is_type_or_embedded([hi]) == false)
  assert(is_type_or_embedded([#_embed_custom_type(body: "foo")]) == true)
  // Directly including a custom type in content turns it into a `repr` representation.
  assert(is_type_or_embedded([#_custom_type(body: "foo")]) == false)
}

#{
  ["#e.tid(_custom_type(body: "foo"))"]
  ["#e.tid(_custom_type)"]
  ["#e.tid(str)"]
  v(2em)
  show: repr
  [hi there #_embed_custom_type(body: "foo")]
}

#import "./types.typ": *
#import "./elements/utils.typ": content_to_array

/// Labelling for `question`, `part`, and `subpart`.
#let LABELLING = ("1.", "(a)", "i.")

/// Fields common to question, part, and subpart elements.
#let _COMMON_FIELDS = (
  e.field("body", content, doc: "The content of the question", required: true),
  e.field(
    "indent",
    length,
    doc: "The amount of indentation for the question body",
    default: 1.5em,
  ),
  e.field(
    "points",
    e.types.option(e.types.union(float, int)),
    doc: "The number of points for the question",
  ),
  e.field(
    "intent",
    e.types.option(e.types.union("practice", "bonus")),
    doc: "The intent of the question, leave as `none` for a regular question. Set as `practice` for a question that should be boxed and labeled as practice. In such a case, it doesn't get a label.",
  ),
  // e.field(
  //   "comments",
  //   e.types.option(content, e.types.array(content)),
  //   doc: "Some comments about the question",
  // ),
  e.field(
    "solution",
    e.types.option(content),
    doc: "The solution to the question, if provided",
  ),
  e.field(
    "rubric",
    e.types.option(content),
    doc: "A rubric for the question, if provided",
  ),
  e.field(
    "number",
    e.types.union(int, none, auto, content),
    doc: "The item number of the question/part/subpart. Leaving as `auto` will automatically number the items. Setting to an integer will number the item with that integer and continue numbering from there. Setting to `none` will omit the number entirely. Setting to `content` will use a custom label consisting of the content.",
    default: auto,
  ),
)

/// A type to keep track of data for each division (question/part/subpart). This is for internal use to allow a flattened structure split at pagebreaks.
#let _division_meta_type = e.types.declare(
  "division-metadata",
  prefix: PREFIX,
  doc: "Meta type for questions, parts, and subparts. This is to be used internally to keep track of document structure before final rendering.",
  fields: (
    .._COMMON_FIELDS,
    e.field(
      "level",
      int,
      doc: "The level of the division",
    ),
    e.field(
      "continuation",
      bool,
      doc: "Whether this is a continuation from a previous division of the same level (and therefore should not get its own number",
      default: false,
    ),
    e.field(
      "is_break",
      bool,
      doc: "Whether this represents a break (pagebreak/colbreak) in the division",
    ),
    e.field(
      "label",
      e.types.option(label),
      doc: "The label for the division",
    ),
    e.field(
      "_DEBUG",
      e.types.any,
      doc: "A field only used for debugging purposes",
      default: none,
    ),
  ),
)

#let DIVISION_TID = e.tid(_division_meta_type)

/// `true` if `it` is `_division_meta_type` or a metadata object wrapping one.
#let is_division_meta_type(it) = {
  e.tid(it) == DIVISION_TID or (e.func-name(it) == "metadata" and e.tid(it.value) == DIVISION_TID)
}

/// Extract the `_division_meta_type` from `it`, whether it is directly of that type or wrapped in metadata.
#let get_division_meta_type(it) = {
  if is_division_meta_type(it) {
    if e.func-name(it) == "metadata" {
      it.value
    } else {
      it
    }
  } else {
    none
  }
}

/// Takes content and wraps it in `metadata(_division_meta_type(...))` but keeps a parallel structure.
/// That is, if come children are already a `_division_meta_type`, they are separately wrapped with their level incremented.
#let _division(body, ..args) = {
  let initialized_args = _division_meta_type([], ..args)
  let chunks = content_to_array(body)
  chunks
    .enumerate()
    .map(((i, c)) => {
      let is_first_item = i == 0
      let is_continuation = not is_first_item
      let ret = ()
      // The first item is handled specially. If we immediately encounter another division, we must insert an empty one right before.
      // Otherwise `_division[#_division[...]]` and `_division[Foo #_division[...]]` wouldn't be equivalent.
      if is_first_item and is_division_meta_type(c) {
        ret.push(metadata(_division_meta_type([], ..args)))
      }
      // ret.push(metadata(_division_meta_type(
      //   [], level: 1000, _DEBUG: c
      // )))
      // An existing division is kept in place
      if is_division_meta_type(c) {
        let value = get_division_meta_type(c)
        // Any subdivisions get their level incremented by 1
        // and the current indent gets added to their indent
        ret.push(metadata((
          ..value,
          level: value.level + 1,
          indent: value.indent + initialized_args.indent,
        )))
      } else if c == pagebreak() or c == colbreak() {
        // Breaks are isolated into their type
        ret.push(metadata(_division_meta_type(
          c,
          is_break: true,
          continuation: is_continuation,
        )))
      } else {
        // Regular content is wrapped in a new division
        ret.push(metadata(_division_meta_type(c, ..args, continuation: is_continuation)))
      }
      ret
    })
    .flatten()
    .join([])
}

/// Take content sequence and turn it into an array of `_division_meta_type` objects.
#let divisions_to_array(it) = {
  let chunks = content_to_array(it)
  chunks.map(c => get_division_meta_type(c)).filter(d => d != none)
}

/// If a division is a continuation of the previous one and it is _not_ a break, merge its body into the previous division.
#let merge_duplicate_divisions(divs) = {
  if divs.len() == 0 {
    return ()
  }

  let ret = ()
  for d in divs {
    if ret.len() == 0 {
      ret.push(d)
      continue
    }
    let last = ret.at(ret.len() - 1)
    if d.level == last.level and d.continuation and not d.is_break {
      // Merge bodies
      let new_body = last.body + d.body
      // If we assigned to `last.body` the assignment would not mutate `ret`
      ret.at(ret.len() - 1).body = new_body
    } else {
      ret.push(d)
    }
  }
  ret
}

/// Postprocess an array of `_division_meta_type` objects to assign numbers and handle continuations.
#let postprocess_divisions(divs) = {
  let ret = ()
  // Initialize all counters to -1 so that the first increment sets them to 0
  let counters = (-1,) * calc.max(..divs.map(d => d.level + 1), 1)
  for d in divs {
    // Figure out what the number should be.
    // - If it is a continuation, the number is `none`
    // - If it is `auto`, we use the next number in the counter for that level
    // - If it is an int, we use it and set the counter to that int
    // - If it is anything else, it is preserved and no counter is updated
    if d.continuation {
      ret.push((..d, number: none))
    } else {
      if d.number == auto {
        counters.at(d.level) += 1
      }
      if type(d.number) == int {
        counters.at(d.level) = d.number
      }
      if d.number == auto or type(d.number) == int {
        ret.push((..d, number: counters.at(d.level)))
      } else {
        // Preserve custom content or `none`
        ret.push(d)
      }
    }
  }
  merge_duplicate_divisions(ret)
}


// TESTING
#{
  set page(width: 10in)
  let simplify_division(it) = {
    let chunks = content_to_array(it)
    chunks
      .map(get_division_meta_type)
      .map(d => {
        let ret = (
          level: d.level,
          // is_break: d.is_break,
          continuation: d.continuation,
          number: d.number,
          // indent: d.indent,
        )
        if d._DEBUG != none {
          ret._DEBUG = d._DEBUG
        }
        ret
      })
  }

  [#{
    let body = _division([
      A b c
    ])
    let body = postprocess_divisions(divisions_to_array(body))

    simplify_division(body)
  }]
  [
    #parbreak()
    unfiltered
    #{
      let body = _division([

        hi there#_division([xxx#pagebreak()])#_division(
          [xxx#pagebreak()],
        )zzz#_division([xxx#_division([xxx#pagebreak()])])])

      simplify_division(body)
      ("______________",)
      // simplify_division(
      // merge_duplicate_divisions(divisions_to_array(body))
      //  )
    }]
}

#{
  "!start!"
  parbreak()
  {
    show: repr
    [
      A bar c
    ]
    // _division([hi there#_division([xxx #pagebreak() ])])
  }
  parbreak()
  "!end!"
}

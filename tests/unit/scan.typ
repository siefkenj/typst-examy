#import "/src/scan.typ": (
  extract_height, is_break, is_whitespace_content, scan, starts_inline,
  trim_leading_space,
)
#import "/src/markers.typ": begin_marker, end_marker, height_hint
#import "/src/divisions.typ": part, question

// --- is_break ---
#assert(is_break(pagebreak()))
#assert(is_break(colbreak()))
#assert(not is_break([hello]))
#assert(not is_break("hello"))

// --- extract_height ---
#assert(extract_height(v(2fr)) == 2fr)
#assert(extract_height(box(height: 3cm)[x]) == 3cm)
#assert(extract_height(block(height: 4cm)) == 4cm)
#assert(extract_height(box[x]) == none)
#assert(extract_height(height_hint(1fr)) == 1fr)
#assert(extract_height([plain]) == none)

// --- scan: markers ---
#assert(scan([plain text]).has_marker == false)
#assert(scan(begin_marker((name: "part"))).has_marker == true)
#assert(scan(begin_marker((name: "part"))).marker_names == ("part",))
#assert(scan(end_marker()).has_marker == true)
// marker nested in a sequence
#assert(scan([a #begin_marker((name: "question")) b]).has_marker == true)
// marker nested inside a block
#assert(scan(block[#begin_marker((name: "part"))]).has_marker == true)
// full division emits found markers
#assert(scan([#question[hi]]).marker_names == ("question",))
// marker inside styled content is found
#assert(
  scan({
    set text(fill: red)
    question[hi]
  }).has_marker
    == true,
)

// --- scan: breaks ---
#assert(scan([a #pagebreak() b]).has_break == true)
#assert(scan([a b]).has_break == false)
#assert(scan(block[#colbreak()]).has_break == true)

// --- scan: fr heights ---
#assert(scan([#v(1fr)]).fr == 1fr)
#assert(scan([#v(1fr) #v(2fr)]).fr == 3fr)
#assert(scan([#block(height: 1fr)[x]]).fr == 1fr)
#assert(scan([#height_hint(2fr) some box]).fr == 2fr)
// fr inside an explicitly-sized container does not propagate
#assert(scan([#block(height: 2cm)[#v(1fr)]]).fr == none)
// ...but the sized container's own fr height counts
#assert(scan([#block(height: 1fr)[#v(1fr)]]).fr == 1fr)
// non-fr heights don't contribute
#assert(scan([#v(1cm)]).fr == none)

// --- starts_inline ---
// inline starts
#assert(starts_inline([plain text]) == true)
#assert(starts_inline([#box[x] more]) == true)
#assert(starts_inline([*bold* start]) == true)
#assert(starts_inline([$x + y$ inline math]) == true)
#assert(starts_inline([#link("https://x.test")[a link]]) == true)
// leading space is transparent; the text after decides
#assert(starts_inline([ text after a space]) == true)
// block-level starts
#assert(starts_inline(block[a block]) == false)
#assert(starts_inline([#block[a block] then text]) == false)
#assert(starts_inline([$ x + y $]) == false) // block equation
#assert(starts_inline([
  + an enum item
]) == false)
#assert(starts_inline(figure([x])) == false)
// a leading parbreak means the first text is a fresh paragraph
#assert(starts_inline([#parbreak()text]) == false)
// invisible content is transparent
#assert(starts_inline([ ]) == none)
#assert(starts_inline([#metadata("x")]) == none)
#assert(starts_inline([#metadata("x") text]) == true)
// styled wrappers are transparent
#assert(
  starts_inline({
    set text(fill: red)
    [styled text]
  })
    == true,
)

// --- trim_leading_space ---
// a body written on its own markup line loses its leading space
#assert(trim_leading_space([ leading space]) == [leading space])
// (the trailing space is untouched — only the leading one matters)
#assert(trim_leading_space([
  own line body
]) == [own line body ])
// leading parbreaks are stripped too
#assert(trim_leading_space([#parbreak()after break]) == [after break])
// interior spaces untouched
#assert(trim_leading_space([a b]) == [a b])
// pure whitespace trims to nothing
#assert(trim_leading_space([ ]) == none)
// styled wrappers are preserved around the trimmed content
#{
  let styled = {
    set text(fill: red)
    [ padded]
  }
  let trimmed = trim_leading_space(styled)
  assert(repr(trimmed.func()) == "styled")
}

// --- is_whitespace_content ---
#assert(is_whitespace_content([ ]))
#assert(is_whitespace_content(parbreak()))
#assert(is_whitespace_content([
  #parbreak()
]))
#assert(is_whitespace_content([#metadata("x")]))
#assert(not is_whitespace_content([hi]))
#assert(not is_whitespace_content([ x ]))

/// Read-only recursive scans over content. Used by the tokenizer to decide
/// whether a piece of content must be unwrapped (it contains division
/// markers) and by the planner to detect page-breaking/fr-height elements.

#import "markers.typ": marker_value

/// The internal `sequence` and `styled` element functions.
#let SEQUENCE_FUNC = [#none#none].func()
#let STYLED_FUNC = {
  set text(fill: red)
  [x]
}.func()

/// Whether `c` is a `pagebreak()` or `colbreak()` element.
#let is_break(c) = {
  type(c) == content and (c.func() == pagebreak or c.func() == colbreak)
}

/// Extract the explicitly-set height of elements that can carry one
/// (including examy height hints). Returns `none` if no height is set.
#let extract_height(c) = {
  if type(c) != content { return none }
  let f = c.func()
  if f == v { return c.at("amount", default: none) }
  if f == box or f == block or f == image { return c.at("height", default: none) }
  let m = marker_value(c)
  if m != none and m.kind == "height" { return m.height }
  none
}

/// The labels elembic (1.1.1, pinned in prelude.typ) tags a rule with. A
/// `#show: e.set_(..)` rule turns the rest of its scope into
/// `[#context { .. doc .. }#metadata((doc: doc, rule: rule, ..))<tag>]`: the
/// `context` is opaque, but the metadata keeps the original `doc`, so the
/// divisions inside it can still be found.
#let _ELEMBIC_RULE_TAGS = (<__elembic_element_rule_v2>, <__elembic_element_rule>)

/// The `(doc, rule)` an elembic rule (see `_ELEMBIC_RULE_TAGS`) was applied
/// to, if `c` is the content such a rule left in its place; else `none`.
#let elembic_rule(c) = {
  if type(c) != content or c.func() != SEQUENCE_FUNC or c.children.len() < 2 { return none }
  let tag = c.children.last()
  if tag.func() != metadata or tag.at("label", default: none) not in _ELEMBIC_RULE_TAGS { return none }
  let v = tag.value
  if type(v) != dictionary or "doc" not in v or "rule" not in v { return none }
  (doc: v.doc, rule: v.rule)
}

#let EMPTY_SCAN = (has_marker: false, has_break: false, fr: none, marker_names: ())

#let _merge_scans(a, b) = (
  has_marker: a.has_marker or b.has_marker,
  has_break: a.has_break or b.has_break,
  fr: if a.fr == none { b.fr } else if b.fr == none { a.fr } else { a.fr + b.fr },
  marker_names: a.marker_names + b.marker_names,
)

/// Recursively scan `c` (content, array, or anything else) and report:
/// - `has_marker`: a division begin/end marker occurs somewhere inside
/// - `has_break`: a pagebreak/colbreak occurs somewhere inside
/// - `fr`: the summed `fraction` heights of children (heights inside
///   explicitly-sized containers do not propagate past their container)
/// - `marker_names`: constructor names of found markers (for diagnostics)
#let scan(c) = {
  if type(c) == array {
    return c.fold(EMPTY_SCAN, (acc, x) => _merge_scans(acc, scan(x)))
  }
  if type(c) != content { return EMPTY_SCAN }

  let m = marker_value(c)
  if m != none {
    if m.kind == "begin" {
      return EMPTY_SCAN + (has_marker: true, marker_names: (m.fields.name,))
    }
    if m.kind == "end" {
      return EMPTY_SCAN + (has_marker: true)
    }
    if m.kind == "height" {
      let h = m.height
      return EMPTY_SCAN + (fr: if type(h) == fraction { h } else { none })
    }
    return EMPTY_SCAN
  }
  if is_break(c) { return EMPTY_SCAN + (has_break: true) }
  // An elembic rule: what it applies to is in its tag, not in its fields.
  let rule = elembic_rule(c)
  if rule != none { return scan(rule.doc) }

  // Scan all content-valued fields (children, child, body, caption, ...).
  let inner = EMPTY_SCAN
  for (name, value) in c.fields() {
    if type(value) == content or type(value) == array {
      inner = _merge_scans(inner, scan(value))
    }
  }

  let h = extract_height(c)
  if h != none and h != auto {
    // Explicitly sized: inner fr heights resolve inside this container and
    // must not propagate; markers/breaks inside are still reported.
    return (
      has_marker: inner.has_marker,
      has_break: inner.has_break,
      fr: if type(h) == fraction { h } else { none },
      marker_names: inner.marker_names,
    )
  }
  inner
}

/// Element functions whose content participates in inline (paragraph)
/// layout. Used to decide whether a gutter label can ride the first line.
#let _INLINE_FUNCS = (
  text,
  box,
  h,
  linebreak,
  strong,
  emph,
  link,
  ref,
  sub,
  super,
  underline,
  overline,
  strike,
  highlight,
  smallcaps,
  footnote,
)

/// How `c` begins, for placing a gutter label beside its first line:
/// `none` when `c` is invisible/transparent (spaces, metadata; keep looking),
/// otherwise `(inline: bool, inset: length)`.
/// - `inline`: whether the first visible leaf is inline (text, an inline
///   box, ...), so a label can ride its baseline; `false` for a block-level
///   one (a block, enum, figure, ...), a parbreak, or something unknown
///   (unknown defaults to block-level — the safe case).
/// - `inset`: how far below the top of `c` its first line of text starts,
///   when `c` begins with a box sized to its content (the space inside the
///   box above that content: its top inset), so that a label placed at the
///   top can be moved down to that line; `0pt` otherwise.
#let leading(c) = {
  let inline = (inline: true, inset: 0pt)
  let block_level = (inline: false, inset: 0pt)
  if type(c) == str { return if c.trim() == "" { none } else { inline } }
  if type(c) != content { return inline }
  let f = c.func()
  if f == parbreak { return block_level }
  if ([ ].func(), metadata).contains(f) { return none }
  if f == SEQUENCE_FUNC {
    for child in c.children {
      let r = leading(child)
      if r != none { return r }
    }
    return none
  }
  if f == STYLED_FUNC { return leading(c.at("child")) }
  // Equations, raw, and quotes are inline unless their `block` flag is set.
  if (math.equation, raw, quote).contains(f) {
    return if c.at("block", default: false) { block_level } else { inline }
  }
  if f == box {
    // A box with an explicit height (e.g. a fixed-height answer box) fills
    // its line well past the text baseline; a gutter label must not ride that
    // baseline. Only content-sized boxes count as text-like. A full-width
    // one does not either: it stands on a line of its own however many lines
    // it holds (`answer-box(width: 100%)[..]`), and the label would ride the
    // baseline of its last. A content-sized box's first line starts its top
    // inset below its top.
    let width = c.at("width", default: auto)
    let full = type(width) in (ratio, relative) and width == 100%
    if c.at("height", default: auto) != auto { return block_level }
    let inset = c.at("inset", default: 0pt)
    let top = if type(inset) == dictionary {
      inset.at("top", default: inset.at("y", default: inset.at("rest", default: 0pt)))
    } else { inset }
    return (inline: not full, inset: top)
  }
  if _INLINE_FUNCS.contains(f) { return inline }
  block_level
}

/// Tri-state: does `c` *begin* with inline-level content? `none` when it is
/// invisible (see `leading`).
#let starts_inline(c) = {
  let r = leading(c)
  if r == none { none } else { r.inline }
}

/// How far below the top of `c` its first line of text starts (see
/// `leading`); `none` when it is invisible.
#let leading_inset(c) = {
  let r = leading(c)
  if r == none { none } else { r.inset }
}

/// Strip leading space/parbreak elements from content (looking through
/// sequences and styled wrappers). Used so a division body written on its
/// own markup line does not render a visible space after an inline gutter
/// label.
#let trim_leading_space(c) = {
  if type(c) != content { return c }
  let f = c.func()
  if ([ ].func(), parbreak().func()).contains(f) { return none }
  if f == SEQUENCE_FUNC {
    let kids = c.children
    let i = 0
    while i < kids.len() {
      let trimmed = trim_leading_space(kids.at(i))
      if trimmed == none {
        i += 1
      } else if trimmed != kids.at(i) {
        return (trimmed, ..kids.slice(i + 1)).join()
      } else {
        break
      }
    }
    return kids.slice(i).join()
  }
  if f == STYLED_FUNC {
    let trimmed = trim_leading_space(c.at("child"))
    if trimmed == none { return none }
    return STYLED_FUNC(trimmed, c.at("styles"))
  }
  c
}

/// Whether content consists only of whitespace (spaces, parbreaks, metadata).
#let is_whitespace_content(it) = {
  if it == none { return true }
  if type(it) == str { return it.trim() == "" }
  if type(it) != content { return false }
  if ([ ].func(), parbreak().func(), metadata).contains(it.func()) {
    return true
  }
  if it.has("text") { return it.at("text").trim() == "" }
  if it.has("children") {
    return it.at("children").all(is_whitespace_content)
  }
  false
}

/// Elements that are always block-level, and so end the paragraph before
/// them and start a fresh one after. Anything not listed counts as inline:
/// mistaking a block for inline content merely leaves a solution
/// shrink-wrapped, whereas the reverse widens a solution in the middle of a
/// sentence and breaks the line apart.
#let _BLOCK_FUNCS = (
  parbreak,
  block,
  table,
  grid,
  figure,
  list,
  enum,
  terms,
  heading,
  image,
  align,
  pad,
  stack,
  columns,
  colbreak,
  pagebreak,
  v,
  rect,
  square,
  circle,
  ellipse,
  polygon,
  line,
  outline,
  bibliography,
)

/// Whether `c` is block-level, ending the paragraph before it.
#let ends_par(c) = {
  let f = c.func()
  if _BLOCK_FUNCS.contains(f) { return true }
  // Inline unless their `block` flag is set.
  if (math.equation, raw, quote).contains(f) { return c.at("block", default: false) }
  false
}

/// Whether `c` runs over more than one paragraph: it holds a paragraph break
/// or a block-level element, looking through `styled` and `sequence`.
#let is_multi_par(c) = {
  if type(c) != content { return false }
  if ends_par(c) { return true }
  let f = c.func()
  if f == STYLED_FUNC { return is_multi_par(c.child) }
  if f == SEQUENCE_FUNC { return c.children.any(is_multi_par) }
  false
}

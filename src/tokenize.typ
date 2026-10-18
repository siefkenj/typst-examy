/// Phase B: turn a content stream containing division markers into a flat
/// array of tokens. Unwrapping is conservative: a child is only descended
/// into when it actually contains a marker, and only `sequence` and `styled`
/// containers and elembic rules (`#show: e.set_(..)`) can be unwrapped
/// (their styles and rules are recorded on a stack and re-applied at render
/// time). Everything else stays an opaque `chunk`.
///
/// Token kinds (plain dictionaries):
/// - (kind: "begin", fields: (..), styles: (..))
/// - (kind: "end")
/// - (kind: "break", target: "page" | "col", weak: bool, styles: (..))
/// - (kind: "chunk", body: content, styles: (..), has_inner_break: bool,
///    fr: fraction | none)

#import "prelude.typ": e
#import "markers.typ": marker_value
#import "scan.typ": SEQUENCE_FUNC, STYLED_FUNC, elembic_rule, is_break, scan

/// Re-apply a recorded style stack to content: each entry is the `styles`
/// of a `styled` element, or a function, the show rule of an elembic rule.
#let apply_styles(body, styles) = {
  let ret = body
  for s in styles.rev() {
    ret = if type(s) == function { s(ret) } else { STYLED_FUNC(ret, s) }
  }
  ret
}

/// The show rule applying an elembic rule again, from the rule's data as
/// its tag keeps it (see `elembic_rule`). `e.apply` takes rules as functions
/// and reads each one's data from the tag it leaves; this one leaves just
/// that.
#let _elembic_show(rule) = e.apply(_ => [#metadata(none)#metadata((rule: rule))])

#let _chunk(c, styles, info) = (
  kind: "chunk",
  body: c,
  styles: styles,
  has_inner_break: info.has_break,
  fr: info.fr,
)

#let _tokenize_impl(c, styles) = {
  if type(c) == array {
    return c.map(x => _tokenize_impl(x, styles)).flatten()
  }
  if type(c) != content {
    return (_chunk([#c], styles, scan(c)),)
  }

  let m = marker_value(c)
  if m != none {
    if m.kind == "begin" {
      return ((kind: "begin", fields: m.fields, styles: styles),)
    }
    if m.kind == "end" {
      return ((kind: "end"),)
    }
    // Other marker kinds (e.g. height hints) travel as ordinary chunks.
    return (_chunk(c, styles, scan(c)),)
  }
  if is_break(c) {
    return (
      (
        kind: "break",
        target: if c.func() == pagebreak { "page" } else { "col" },
        weak: c.at("weak", default: false),
        styles: styles,
      ),
    )
  }

  let info = scan(c)
  if not info.has_marker {
    // No structure inside: keep as one opaque chunk. Never destructured.
    return (_chunk(c, styles, info),)
  }

  // Contains markers: must unwrap. Only sequences, styled wrappers, and
  // elembic rules can be unwrapped without losing information.
  let rule = elembic_rule(c)
  if rule != none {
    return _tokenize_impl(rule.doc, styles + (_elembic_show(rule.rule),))
  }
  if c.func() == SEQUENCE_FUNC {
    return c.children.map(x => _tokenize_impl(x, styles)).flatten()
  }
  if c.func() == STYLED_FUNC {
    return _tokenize_impl(c.at("child"), styles + (c.at("styles"),))
  }
  let names = info.marker_names.dedup()
  if names.len() == 0 { names = ("division",) }
  panic(
    "examy: a `"
      + names.join("`/`")
      + "` was found inside a `"
      + repr(c.func())
      + "` element. Questions, parts, and subparts may only appear at the "
      + "top level of their parent's body (not inside list items, blocks, "
      + "boxes, figures, tables, etc.). Move it out of the `"
      + repr(c.func())
      + "`.",
  )
}

/// Tokenize `content` into a flat array of tokens.
#let tokenize(c) = _tokenize_impl(c, ())

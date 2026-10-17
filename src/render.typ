/// Phase E: turn plan instructions into actual layout.

#import "prelude.typ": *
#import "scan.typ": is_whitespace_content, leading
#import "tokenize.typ": apply_styles
#import "plan.typ": cumulative_indent
#import "config.typ": DEFAULT_EXAM_OPTIONS
#import "points.typ": conflict_warning, points_marker
#import "refs.typ": display_number, division_anchor, update_current_address
#import "elements/solution.typ": solution

/// Half-em gap between a gutter label and the body text.
#let LABEL_GAP = .5em

/// The gap between a points badge in the margin and the text.
#let MARGIN_GAP = 1em

/// The width of the box a gutter label or a badge in the margin is set
/// in, against its edge nearest the text: wider than any of them, so that
/// one wider than the space it is given runs out over the margin instead of
/// wrapping onto a second line.
#let _OVERFLOW = 20cm

/// The badge a division shows (see `assign_badges`).
#let _badge(d) = d.badge

/// Where a division's badge is drawn: `none` when it has none, otherwise
/// `config`'s `points-position`, except that a conflict warning is always
/// drawn at the start, in the flow, where it is seen.
#let _badge_position(d, opts) = {
  let badge = _badge(d)
  if badge == none { none } else if badge.kind == "conflict" { "start" } else { opts.points-position }
}

/// The points badge of a division, as drawn by `points-format`, or the
/// conflict warning in its place.
///
/// The badge is boxed so it acts as a single atomic inline unit: it never
/// breaks across lines, and its inner space is not stretched by paragraph
/// justification. Without the box, a body that starts with a full-width
/// inline element (e.g. `answer-box(width: 100%)`) pushes that element onto
/// the next line, which makes the badge's line a non-final — and therefore
/// justified — line, spreading "(1 point)" across the full measure.
#let _badge_body(d, opts) = {
  let badge = _badge(d)
  if badge == none { return none }
  if badge.kind == "conflict" { return conflict_warning(badge) }
  box((opts.points-format)(badge.points))
}

/// The badges of `d_idxs` that go in the margin, placed in the margin level
/// with the top of the block they are drawn in, whose content starts
/// `indent` right of the text's left edge. Several share a first line when a
/// question starts with a part (`d_idxs` lists them outermost first). There,
/// an outer division's total (see `points-show-totals`) is left out when a
/// division inside it shows a badge, which would read as the outer one's
/// points; the rest are set side by side, the outermost first, rather than
/// drawn over each other.
#let _margin_badges(items, d_idxs, indent, opts, dy: 0pt) = {
  let shown = d_idxs.filter(i => _badge_position(items.at(i), opts) in ("margin-left", "margin-right"))
  let innermost = shown.at(-1, default: none)
  let badges = shown
    .filter(i => i == innermost or not _badge(items.at(i)).total)
    .map(i => _badge_body(items.at(i), opts))
  if badges.len() == 0 { return none }
  let in_right = opts.points-position == "margin-right"
  let side = if in_right { left } else { right }
  // Set against the text in a box wider than any badge, so that it neither
  // wraps nor needs measuring (a `context` here would break the paragraph
  // the badge is placed in).
  let body = box(width: _OVERFLOW, align(side, stack(dir: ltr, spacing: .5em, ..badges)))
  // Anchored to the block, not to the line: since Typst 0.15 a `place`
  // with no alignment inside a paragraph anchors at the line's baseline.
  if in_right {
    place(top + right, dx: MARGIN_GAP + _OVERFLOW, dy: dy, body)
  } else {
    place(top + left, dx: -indent - MARGIN_GAP - _OVERFLOW, dy: dy, body)
  }
}

/// A badge drawn at the `"end"`: flush right after the text before it, on
/// the same line when there is room for it. After a block, such as an `fr`
/// answer box, it takes a line of its own, which in a segment of fixed
/// (`fr`) height the box gives up to it.
#let _end_badge(d, opts) = {
  if _badge_position(d, opts) != "end" { return none }
  h(.5em, weak: true) + h(1fr) + _badge_body(d, opts)
}

/// The gutter label for a division, placed to the left of the body.
/// `indent` is the inset of the block the label is placed inside (placement
/// is relative to that block's content origin) and `width` is the gutter
/// width the label may occupy: the division's own indent for nested blocks,
/// its cumulative indent for top-level peer segments.
///
/// When the body starts with inline content, pass `inline: true`: the label
/// is emitted as a zero-width inline box that participates in the first
/// line's layout, so it stays on the baseline even when the line is taller
/// than usual (e.g. a boxed solution on the first line). When the body
/// starts with a block-level element (or is empty), the label is `place`d at
/// the block top instead, which is where the block's first content sits.
/// (The zero-width trick assumes LTR text.)
#let _gutter_label(items, d_idx, indent, width, opts, inline: false, dy: 0pt) = {
  let d = items.at(d_idx)
  let disp = display_number(d.level, d.number, numberings: opts.numbering)
  if disp == none { return none }
  // Right-aligned in a box ending `LABEL_GAP` short of the text, and wider
  // than the gutter, so that a label too long for it (`"Problem 1."`) runs
  // out to the left rather than wrapping.
  let dx = -indent + width - LABEL_GAP - _OVERFLOW
  let label = box(width: _OVERFLOW, align(right, disp))
  if inline {
    box(width: 0pt, h(dx) + label)
  } else {
    // Anchor to the block region explicitly: since Typst 0.15 an
    // alignment-less `place` inside a paragraph anchors at the line's
    // baseline, which for a line containing a tall inline box is its bottom.
    // `dy` moves it down to the first line of a box the body starts with.
    place(top + left, dx: dx, dy: dy, label)
  }
}

/// Whether a body (a list of item indices, in order) starts with a child
/// division. Invisible chunks are skipped.
#let _body_starts_with_division(items, idxs) = {
  for i in idxs {
    let it = items.at(i)
    if it.kind == "chunk" and is_whitespace_content(it.body) { continue }
    return it.kind == "division"
  }
  false
}

/// Whether division `idx` shares its first line with a part its body starts
/// with: unless a badge in the flow (at the `"start"`, or the `"end"` of no
/// text) takes that line first.
#let _shares_first_line(items, idx, opts) = (
  _body_starts_with_division(items, items.at(idx).children)
    and _badge_position(items.at(idx), opts) not in ("start", "end")
)

/// How the first line of a run of chunks (item indices, in order) sits, for
/// a gutter label: `inline`, whether the label rides that line's baseline;
/// and otherwise `dy`, how far below the top of the run the line starts (see
/// `leading`). Invisible chunks are skipped; anything but a chunk ends the
/// run.
#let _chunks_lead(items, idxs) = {
  for i in idxs {
    let it = items.at(i)
    if it.kind != "chunk" { break }
    let r = leading(it.body)
    if r != none { return (inline: r.inline, dy: if r.inline { 0pt } else { r.inset }) }
  }
  (inline: false, dy: 0pt)
}

/// `_chunks_lead` for the body of division `idx`. A body that shares its
/// first line with a part it starts with has its label level with the
/// part's; one whose badge takes that line has its label at the top.
#let _label_lead(items, idx, opts) = {
  let children = items.at(idx).children
  if not _body_starts_with_division(items, children) { return _chunks_lead(items, children) }
  if not _shares_first_line(items, idx, opts) { return (inline: false, dy: 0pt) }
  let first = children.find(i => items.at(i).kind == "division")
  (inline: false, dy: _label_lead(items, first, opts).dy)
}

/// Anchor, points marker, and (at the `"start"`) points badge emitted at
/// the start of a division's body. `inline` is whether the body starts with
/// inline content, a paragraph the head can join.
#let _division_head(items, d_idx, opts, inline: true) = {
  let d = items.at(d_idx)
  let anchor = division_anchor(
    label_name: d.fields.label,
    full_address: d.address,
    numberings: opts.numbering,
    label: d.fields.label,
  )
  if d.fields.label == none {
    // Realizes to pure invisible tags; safe to leave bare in the flow.
    anchor
  } else if inline or _badge_position(d, opts) == "start" {
    // A *labeled* elembic element realizes inside a block-level wrapper,
    // which would break the division's first line; an inline box keeps it in
    // the paragraph (references still resolve to it).
    box(anchor)
  } else {
    // With no paragraph to join (the body starts with a part or a block),
    // a box would make one, an empty line of its own: placed, it takes no
    // room.
    place(anchor)
  }
  // Where `page-points` finds the division's points.
  if d.fields.points != none { points_marker(d.fields.points, d.fields.intent) }
  if _badge_position(d, opts) == "start" { _badge_body(d, opts) + h(.5em) }
}

/// Join a run of chunk items back into content, re-applying recorded styles.
/// Consecutive chunks with the same style stack are joined first so spacing
/// is preserved, then wrapped once. `base` styles (already applied by an
/// enclosing block) are skipped.
#let render_chunks(items, idxs, base: 0) = {
  let groups = ()
  for i in idxs {
    let c = items.at(i)
    let styles = c.styles.slice(calc.min(base, c.styles.len()))
    if groups.len() > 0 and groups.at(-1).styles == styles {
      groups.at(-1).bodies.push(c.body)
    } else {
      groups.push((styles: styles, bodies: (c.body,)))
    }
  }
  groups.map(g => apply_styles(g.bodies.join(), g.styles)).join()
}

/// Render a division subtree as ordinary nested blocks (used when the
/// subtree contains no page breaks or fr heights). `carry` are ancestors
/// that share this division's first line, and whose badges in the margin
/// this division draws with its own.
#let render_nested(items, idx, opts, base_styles: 0, carry: ()) = {
  let it = items.at(idx)
  let indent = it.fields.indent
  let own_styles = it.styles.slice(calc.min(base_styles, it.styles.len()))

  // Whether the gutter label rides the first line, and otherwise how far down
  // to move it, and a badge in the margin, to that line.
  let (inline: inline_label, dy: dy) = _label_lead(items, idx, opts)
  // A body sharing its first line with a part it starts with has its badge
  // in the margin drawn by the part, with the part's own.
  let shares_line = _shares_first_line(items, idx, opts)
  let body = {
    // First, before the paragraph it is level with: a `place` aligned to the
    // block in the middle of a paragraph would break it in two.
    if not shares_line { _margin_badges(items, carry + (idx,), cumulative_indent(items, idx), opts, dy: dy) }
    _gutter_label(items, idx, indent, indent, opts, inline: inline_label, dy: dy)
    _division_head(items, idx, opts, inline: inline_label)
    let carry = if shares_line { carry + (idx,) } else { () }
    // Children in document order: runs of chunks joined, child divisions
    // rendered recursively. A badge at the `"end"` follows the division's
    // own text, before its first part.
    let end_badge = _end_badge(it, opts)
    let chunk_run = ()
    for c_idx in it.children {
      let child = items.at(c_idx)
      if child.kind == "chunk" {
        chunk_run.push(c_idx)
      } else {
        render_chunks(items, chunk_run, base: it.styles.len())
        end_badge
        end_badge = none
        chunk_run = ()
        render_nested(items, c_idx, opts, base_styles: it.styles.len(), carry: carry)
        carry = ()
      }
    }
    render_chunks(items, chunk_run, base: it.styles.len())
    end_badge
    if it.fields.solution != none {
      solution(it.fields.solution)
    }
  }

  apply_styles(
    block(width: 100%, inset: (left: indent), {
      set enum(numbering: opts.numbering.at(it.level, default: "(a)"))
      body
    }),
    own_styles,
  )
}

/// Render one peer segment (produced by splitting a subtree at breaks).
#let render_segment(items, seg, opts, ends: (:), n: none) = {
  let owner = items.at(seg.division)
  let height = if seg.has_inner_break or seg.fr == none { auto } else { seg.fr }
  let own_styles = owner.styles
  // A hoisted segment is a bare wrapper sitting exactly where its one chunk
  // used to sit, so it takes over that chunk's `above` spacing instead of the
  // default gap between peer blocks (`answer-box` sets a tight one).
  let above = if seg.hoisted {
    items.at(seg.items.at(0)).body.at("above", default: auto)
  } else { auto }

  let body = {
    let (inline: inline_label, dy: dy) = _chunks_lead(items, seg.items)
    // First, before the paragraph it is level with (see `render_nested`).
    if seg.label_divisions.len() > 0 { _margin_badges(items, seg.label_divisions, seg.indent, opts, dy: dy) }
    // Gutter labels: possibly several divisions share this segment's first
    // line (e.g. a question whose body starts with a part).
    for d_idx in seg.label_divisions {
      _gutter_label(
        items,
        d_idx,
        seg.indent,
        cumulative_indent(items, d_idx),
        opts,
        inline: inline_label,
        dy: dy,
      )
    }
    if seg.label_divisions.len() > 0 {
      for d_idx in seg.label_divisions {
        _division_head(items, d_idx, opts, inline: inline_label)
      }
    } else {
      // Continuation: no label, but references inside still belong here.
      update_current_address(owner.address)
    }
    render_chunks(items, seg.items, base: owner.styles.len())
    if ends.at(str(seg.division), default: none) == n { _end_badge(owner, opts) }
    if seg.tail != none {
      let d = items.at(seg.tail)
      if d.fields.solution != none {
        solution(d.fields.solution)
      }
    }
  }

  apply_styles(
    block(width: 100%, inset: (left: seg.indent), height: height, sticky: seg.sticky, above: above, {
      // A pagebreak buried inside an opaque chunk cannot break out of this
      // block; degrade it to a column break like the old implementation.
      show pagebreak: it => colbreak(weak: it.weak)
      set enum(numbering: opts.numbering.at(owner.level, default: "(a)"))
      body
    }),
    own_styles,
  )
}

/// For each division with a badge at the `"end"`, the index of the segment
/// that ends its own text: the last of its own segments before the first of
/// one of its parts, as the badge follows all its own text before its first
/// part when it is drawn in one piece (`render_nested`). Keyed by the
/// division's index, as a string. (`plan` gives each such division a segment
/// of its own before its parts, even with no text in it, for the badge.)
#let _end_segments(items, instructions, opts) = {
  let ends = (:)
  let closed = (:)
  for (n, instr) in instructions.enumerate() {
    if instr.kind != "segment" { continue }
    let owner = instr.division
    let ancestor = items.at(owner).parent
    while ancestor != none {
      closed.insert(str(ancestor), true)
      ancestor = items.at(ancestor).parent
    }
    if str(owner) not in closed and _badge_position(items.at(owner), opts) == "end" {
      ends.insert(str(owner), n)
    }
  }
  ends
}

/// Render a full instruction list. `opts` are the layout options resolved
/// from `config` (see `exam_options`).
#let render(items, instructions, opts: DEFAULT_EXAM_OPTIONS) = {
  let ends = _end_segments(items, instructions, opts)
  for (n, instr) in instructions.enumerate() {
    if instr.kind == "verbatim" {
      let it = items.at(instr.item)
      apply_styles(it.body, it.styles)
    } else if instr.kind == "break" {
      if instr.target == "page" {
        pagebreak(weak: instr.weak)
      } else {
        colbreak(weak: instr.weak)
      }
    } else if instr.kind == "nested" {
      render_nested(items, instr.root, opts)
    } else if instr.kind == "segment" {
      render_segment(items, instr, opts, ends: ends, n: n)
    } else {
      panic("examy: unknown render instruction: " + repr(instr.kind))
    }
  }
}

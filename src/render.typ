/// Phase E: turn plan instructions into actual layout.

#import "prelude.typ": *
#import "scan.typ": _find, glue_rubrics, has_any_rubric, is_whitespace_content, leading, rubric_markers
#import "tokenize.typ": apply_styles, stack_of
#import "plan.typ": cumulative_indent, frame_plan, hold, items_of
#import "config.typ": DEFAULT_EXAM_OPTIONS
#import "points.typ": conflict_warning, division_marker, points_marker
#import "refs.typ": display_number, division_anchor, enum_numbering, reference_body, update_current_address
#import "rubric.typ": owner_update, rubric_area, rubric_end_area, rubric_head, rubric_leaders, stacked_badges

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

/// The points badge of a division, as drawn by `points-format` (or
/// `bonus-points-format`, for bonus points), or the conflict warning in its
/// place.
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
  let format = if badge.bonus { opts.bonus-points-format } else { opts.points-format }
  box(format(badge.points))
}

/// The badges of `d_idxs` that go in the margin, as they are drawn there
/// (see `_margin_badges`), or `none`. Several share a first line when a
/// question starts with a part (`d_idxs` lists them outermost first). There,
/// an outer division's total (see `points-show-totals`) is left out when a
/// division inside it shows a badge, which would read as the outer one's
/// points; the rest are set side by side, the outermost first, rather than
/// drawn over each other.
#let _margin_badge_body(items, d_idxs, opts) = {
  let shown = d_idxs.filter(i => _badge_position(items_of(items).at(i), opts) in ("margin-left", "margin-right"))
  let innermost = shown.at(-1, default: none)
  let badges = shown
    .filter(i => i == innermost or not _badge(items_of(items).at(i)).total)
    .map(i => _badge_body(items_of(items).at(i), opts))
  if badges.len() == 0 { return none }
  let side = if opts.points-position == "margin-right" { left } else { right }
  // Set against the text in a box wider than any badge, so that it neither
  // wraps nor needs measuring (a `context` here would break the paragraph
  // the badge is placed in).
  box(width: _OVERFLOW, align(side, stack(dir: ltr, spacing: .5em, ..badges)))
}

/// Whether points badges in the margin are stacked with the rubrics drawn in
/// the same margin (see `stacked_badges`).
#let _badges_stacked(opts) = opts.rubric.drawn and opts.points-position == opts.rubric.position

/// The badges of `d_idxs` that go in the margin (see `_margin_badge_body`),
/// placed in the margin level with the top of the block they are drawn in,
/// whose content starts `indent` right of the text's left edge; or, in the
/// margin rubrics are drawn in, stacked with them.
#let _margin_badges(items, d_idxs, indent, opts, dy: 0pt) = {
  let body = _margin_badge_body(items, d_idxs, opts)
  if body == none { return none }
  let in_right = opts.points-position == "margin-right"
  let placed(dy) = if in_right {
    place(top + right, dx: MARGIN_GAP + _OVERFLOW, dy: dy, body)
  } else {
    place(top + left, dx: -indent - MARGIN_GAP - _OVERFLOW, dy: dy, body)
  }
  if _badges_stacked(opts) { return stacked_badges(body, opts.points-position, placed, dy: dy) }
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
///
/// When the line is too full for it, as after a full-width box in the line,
/// it wraps, still flush right: the line may break only before the space
/// that pushes it right (at the zero-width space), never between the two
/// (the word joiner), and the empty box keeps that space from being dropped
/// as the start of the new line.
#let _end_badge(d, opts) = {
  if _badge_position(d, opts) != "end" { return none }
  [#h(.5em, weak: true)#sym.zws#box()#h(1fr)#sym.wj#_badge_body(d, opts)]
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
  let d = items_of(items).at(d_idx)
  let disp = display_number(d.address, numbering: opts.numbering, full: opts.numbering-full)
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

/// Whether a division's address is counted at every level, so that its
/// full number (see `numbering-full`) holds those of the divisions it is in.
#let _counted(d) = d.address.all(n => type(n) == int)

/// Whether, with `numbering-full`, division `idx`'s number is left out of
/// the gutter: a division in it, numbered in full, shares its first line
/// and shows its number already ("1.a." for "1." and "(a)"). `line` lists
/// the divisions on that line, outermost first.
#let _covered(items, idx, line, opts) = {
  if not opts.numbering-full { return false }
  let i = line.position(d => d == idx)
  i != none and line.slice(i + 1).any(d => _counted(items_of(items).at(d)))
}

/// Whether a body (a list of item indices, in order) starts with a child
/// division. Invisible chunks are skipped.
#let _body_starts_with_division(items, idxs) = {
  for i in idxs {
    let it = items_of(items).at(i)
    if it.kind == "chunk" and is_whitespace_content(it.body) { continue }
    return it.kind == "division"
  }
  false
}

/// Whether division `idx` shares its first line with a part its body starts
/// with: unless a badge in the flow (at the `"start"`, or the `"end"` of no
/// text) takes that line first.
#let _shares_first_line(items, idx, opts) = {
  let it = items_of(items).at(idx)
  _body_starts_with_division(items, it.children) and _badge_position(it, opts) not in ("start", "end")
}

/// How the first line of a run of chunks (item indices, in order) sits, for
/// a gutter label: `inline`, whether the label rides that line's baseline;
/// and otherwise `dy`, how far below the top of the run the line starts (see
/// `leading`). Invisible chunks are skipped; anything but a chunk ends the
/// run.
#let _chunks_lead(items, idxs) = {
  for i in idxs {
    let it = items_of(items).at(i)
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
  let children = items_of(items).at(idx).children
  if not _body_starts_with_division(items, children) { return _chunks_lead(items, children) }
  if not _shares_first_line(items, idx, opts) { return (inline: false, dy: 0pt) }
  let first = children.find(i => items_of(items).at(i).kind == "division")
  (inline: false, dy: _label_lead(items, first, opts).dy)
}

/// Anchor, points marker, and (at the `"start"`) points badge emitted at
/// the start of a division's body. `inline` is whether the body starts with
/// inline content, a paragraph the head can join.
#let _division_head(items, d_idx, opts, inline: true) = {
  let d = items_of(items).at(d_idx)
  let anchor = division_anchor(
    label_name: d.fields.label,
    full_address: d.address,
    numbering: opts.numbering,
    full: opts.numbering-full,
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
  // Where `get-num-points-page` finds the division's points, and where the
  // points table links its label to.
  if d.fields.points != none { points_marker(d.fields.points, d.fields.intent) }
  division_marker(d.address)
  if _badge_position(d, opts) == "start" { _badge_body(d, opts) + h(.5em) }
}

/// Mark the chunks that hold rubrics, anywhere inside them (`rubric:
/// true`, and `owner`: the address of their division, or `none`), and the
/// divisions that have a rubric (`rubric: true`): in their `rubric:` field,
/// or in their own text (then also `rubric_text: true`). Returns the items
/// and whether any are marked. What is not marked is rendered as if there
/// were no rubrics.
#let mark_rubrics(items) = {
  let any = false
  for (i, it) in items.enumerate() {
    if it.kind == "chunk" and has_any_rubric(it.body) {
      items.at(i).insert("rubric", true)
      items.at(i).insert("owner", if it.parent != none { items.at(it.parent).address })
      if it.parent != none {
        items.at(it.parent).insert("rubric", true)
        items.at(it.parent).insert("rubric_text", true)
      }
      any = true
    } else if it.kind == "division" and it.fields.rubric != none {
      items.at(i).insert("rubric", true)
      any = true
    }
  }
  (items, any)
}

// Every call is memoized, its arguments hashed, and `items` takes long to
// hash: what follows is called only where there are rubrics, which the
// callers check first (`opts.rubric.drawn`, `opts.rubric.traced`, and the
// marks of `mark_rubrics`), so that an exam with none, or whose rubrics are
// not shown, pays (almost) nothing for them.

/// `body` marked as division `address`'s, for the rubrics in it (see
/// `OWNER`): no division's again after it.
#let _owned(address, body) = owner_update(address) + body + owner_update(none)

/// The `metadata` of chunks `chunks` (items) that a segment takes in (see
/// plan.typ), alone: their rubrics, their division's, and any other
/// `metadata` (with its label), all invisible.
#let _carried_rubrics(chunks) = for c in chunks {
  _owned(c.at("owner", default: none), _find(c.body, x => type(x) == content and x.func() == metadata).join())
}

/// Join a run of chunk items back into content, re-applying recorded styles.
/// Consecutive chunks with the same style stack are joined first so spacing
/// is preserved, then wrapped once. `base` styles (already applied by an
/// enclosing block) are skipped.
#let render_chunks(items, idxs, opts, base: 0) = {
  let groups = ()
  // The division of those holding rubrics (all are its), if any do.
  let marked = false
  let owner = none
  for i in idxs {
    let c = items_of(items).at(i)
    if c.at("rubric", default: false) { (marked, owner) = (true, c.owner) }
    let styles = stack_of(c.styles)
    let styles = styles.slice(calc.min(base, styles.len()))
    if groups.len() > 0 and groups.at(-1).styles.map(s => s.id) == styles.map(s => s.id) {
      groups.at(-1).bodies.push(c.body)
    } else {
      groups.push((styles: styles, bodies: (c.body,)))
    }
  }
  if not marked { return groups.map(g => apply_styles(g.bodies.join(), g.styles)).join() }
  // The rubrics in them are their division's. A rubric whose leader is
  // drawn stays with the text beside it (see `glue_rubrics`).
  let glue = if opts.rubric.traced { glue_rubrics } else { c => c }
  _owned(owner, groups.map(g => apply_styles(glue(g.bodies.join()), g.styles)).join())
}

/// What division `d`'s rubric is headed by, and its points (or its parts'),
/// for the export (see `rubric_area`).
#let rubric_info(d, opts) = {
  let weight = if d.fields.points != none { d.fields.points } else if d.total_points > 0 { d.total_points }
  (
    heading: (
      title: [#opts.strings.question #reference_body(d.address, (), numbering: opts.numbering, full: opts.numbering-full)],
      points: if weight == none { none } else if d.fields.points != none and d.fields.intent == "bonus" {
        (opts.bonus-points-format)(weight)
      } else {
        (opts.points-format)(weight)
      },
    ),
    points: weight,
  )
}

/// Whether division `d` (an item) has a rubric drawn (see `mark_rubrics`).
#let _drawn(d, opts) = opts.rubric.drawn and d.at("rubric", default: false)

/// Division `d`'s rubric in the margin, at the start of its block (see
/// `rubric_area`). Only for a division with a rubric drawn there.
#let _rubric_margin(d, opts, indent, dy) = {
  rubric_area(d.address, d.fields.rubric, rubric_info(d, opts), opts, indent: indent, dy: dy)
}

/// Division `d`'s rubric at its `"end"` (see `rubric_end_area`). Only for a
/// division with a rubric drawn there.
#let _rubric_end(d, opts) = rubric_end_area(d.address, d.fields.rubric, rubric_info(d, opts), opts)

/// Render a division subtree as ordinary nested blocks (used when the
/// subtree contains no page breaks or fr heights). `carry` are ancestors
/// that share this division's first line, and whose badges in the margin
/// this division draws with its own. `end` is whether it draws its rubric at
/// the `"end"`: not when it is given a `height`, which `render` draws after
/// it (see `_rubric_ends`).
#let render_nested(items, idx, opts, base_styles: 0, carry: (), end: true) = {
  let it = items_of(items).at(idx)
  let indent = it.fields.indent
  let it_styles = stack_of(it.styles)
  let own_styles = it_styles.slice(calc.min(base_styles, it_styles.len()))

  // Whether the gutter label rides the first line, and otherwise how far down
  // to move it, and a badge in the margin, to that line.
  let (inline: inline_label, dy: dy) = _label_lead(items, idx, opts)
  // A body sharing its first line with a part it starts with has its badge
  // in the margin drawn by the part, with the part's own.
  let shares_line = _shares_first_line(items, idx, opts)
  // Whether it has rubrics written in its own text, whose leaders it draws.
  let traced = opts.rubric.traced and it.at("rubric_text", default: false)
  let margin = opts.rubric.position != "end" and _drawn(it, opts)
  let body = {
    // First, before the paragraph it is level with: a `place` aligned to the
    // block in the middle of a paragraph would break it in two.
    if _badges_stacked(opts) {
      // Stacked with the rubrics, the badges of a first line come before
      // them all: drawn by the outermost division whose number is on it,
      // for those of the divisions it shares it with.
      if carry.len() == 0 {
        let line = (idx,)
        let cur = idx
        while _shares_first_line(items, cur, opts) {
          cur = items_of(items).at(cur).children.find(i => items_of(items).at(i).kind == "division")
          line.push(cur)
        }
        _margin_badges(items, line, cumulative_indent(items, idx), opts, dy: dy)
      }
    } else if not shares_line {
      _margin_badges(items, carry + (idx,), cumulative_indent(items, idx), opts, dy: dy)
    }
    if traced { rubric_head(it.address) }
    if margin { _rubric_margin(it, opts, cumulative_indent(items, idx), dy) }
    // Numbered in full, the parts it shares its first line with show its
    // number (see `_covered`).
    let covered = if opts.numbering-full and shares_line {
      let line = (idx,)
      let cur = idx
      while _shares_first_line(items, cur, opts) {
        cur = items_of(items).at(cur).children.find(i => items_of(items).at(i).kind == "division")
        line.push(cur)
      }
      _covered(items, idx, line, opts)
    } else { false }
    if not covered { _gutter_label(items, idx, indent, indent, opts, inline: inline_label, dy: dy) }
    _division_head(items, idx, opts, inline: inline_label)
    let carry = if shares_line { carry + (idx,) } else { () }
    // Children in document order: runs of chunks joined, child divisions
    // rendered recursively. A badge at the `"end"` follows the division's
    // own text, before its first part.
    let end_badge = _end_badge(it, opts)
    let chunk_run = ()
    for c_idx in it.children {
      let child = items_of(items).at(c_idx)
      if child.kind == "chunk" {
        chunk_run.push(c_idx)
      } else {
        render_chunks(items, chunk_run, opts, base: it_styles.len())
        end_badge
        end_badge = none
        chunk_run = ()
        render_nested(items, c_idx, opts, base_styles: it_styles.len(), carry: carry)
        carry = ()
      }
    }
    render_chunks(items, chunk_run, opts, base: it_styles.len())
    end_badge
    if end and opts.rubric.position == "end" and _drawn(it, opts) { _rubric_end(it, opts) }
    if traced { rubric_leaders(it.address, (it.address,), opts.rubric.position) }
  }

  apply_styles(
    block(width: 100%, inset: (left: indent), {
      set enum(numbering: enum_numbering(opts.numbering, it.level))
      body
    }),
    own_styles,
  )
}

/// The height an exam lays out `h`, a division's own `height`, at: a
/// fraction as `opts.fr-unit` says (see `exam_options`), anything else as it
/// is. (A segment of `fr` boxes is sized in `render_segment`.)
#let fr_height(h, opts) = {
  if type(h) != fraction or opts.fr-unit == none { h } else if opts.fr-unit == auto { auto } else {
    h / 1fr * opts.fr-unit
  }
}

/// Render one peer segment (produced by splitting a subtree at breaks).
/// `base` styles (already applied around it, see `render`) are skipped.
#let render_segment(items, seg, opts, ends: (:), n: none, base: 0) = {
  let owner = items_of(items).at(seg.division)
  let height = if seg.has_inner_break or seg.fr == none { auto } else { seg.fr }
  let owner_styles = stack_of(owner.styles)
  let own_styles = owner_styles.slice(calc.min(base, owner_styles.len()))
  // A hoisted segment is a bare wrapper sitting exactly where its one chunk
  // used to sit, so it takes over that chunk's `above` spacing instead of the
  // default gap between peer blocks (`answer-box` sets a tight one).
  let above = if seg.hoisted {
    items_of(items).at(seg.items.at(0)).body.at("above", default: auto)
  } else { auto }
  // The rubrics it takes in from segments dropped before it (see plan.typ),
  // and the divisions of those in it, whose leaders it draws.
  let carried = seg.at("rubrics", default: ()).map(i => items_of(items).at(i))
  let owners = ()
  if opts.rubric.traced {
    for i in seg.items {
      if items_of(items).at(i).at("rubric", default: false) { owners.push(owner.address) }
    }
    owners = (owners + carried.map(c => c.owner)).dedup()
  }

  let body = {
    let (inline: inline_label, dy: dy) = _chunks_lead(items, seg.items)
    // First, before the paragraph it is level with (see `render_nested`).
    if seg.label_divisions.len() > 0 { _margin_badges(items, seg.label_divisions, seg.indent, opts, dy: dy) }
    if owners.len() > 0 { rubric_head(owner.address) }
    if opts.rubric.drawn and opts.rubric.position != "end" {
      for d_idx in seg.label_divisions {
        if _drawn(items_of(items).at(d_idx), opts) { _rubric_margin(items_of(items).at(d_idx), opts, seg.indent, dy) }
      }
    }
    // Gutter labels: possibly several divisions share this segment's first
    // line (e.g. a question whose body starts with a part).
    for d_idx in seg.label_divisions {
      if _covered(items, d_idx, seg.label_divisions, opts) { continue }
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
    if carried.len() > 0 { _carried_rubrics(carried) }
    render_chunks(items, seg.items, opts, base: owner_styles.len())
    if ends.at(str(seg.division), default: none) == n { _end_badge(owner, opts) }
    if owners.len() > 0 { rubric_leaders(owner.address, owners, opts.rubric.position) }
  }

  let segment(height, above) = block(width: 100%, inset: (left: seg.indent), height: height, sticky: seg.sticky, above: above, {
    // A pagebreak buried inside an opaque chunk cannot break out of this
    // block; degrade it to a column break like the old implementation.
    show pagebreak: it => colbreak(weak: it.weak)
    set enum(numbering: enum_numbering(opts.numbering, owner.level))
    body
  })
  let unit = opts.fr-unit
  apply_styles(
    if type(height) != fraction or unit == none {
      segment(height, above)
    } else if unit == auto {
      // Where a share of the page comes to nothing (see `exam_options`): as
      // tall as what it holds, its `fr` boxes nothing, so that what follows
      // them (a badge at the `"end"`) stays in the flow.
      segment(auto, above)
    } else {
      // Each `1fr` as `unit` (see `exam_options`): what the segment holds
      // besides its `fr` boxes, which come to nothing measured, and `unit`
      // times its `fr`s on top, which its `fr` boxes share, so that a box of
      // `height: 2fr` is `2 * unit` tall.
      block(width: 100%, sticky: seg.sticky, above: above, layout(size => {
        let rest = measure(segment(auto, auto), width: size.width).height
        segment(rest + height / 1fr * unit, auto)
      }))
    },
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
    // A frame (a part with a `height`) closes its parent's text, as one of
    // its segments would.
    if instr.kind not in ("segment", "frame") { continue }
    let owner = instr.division
    let ancestor = items_of(items).at(owner).parent
    while ancestor != none {
      closed.insert(str(ancestor), true)
      ancestor = items_of(items).at(ancestor).parent
    }
    if instr.kind == "segment" and str(owner) not in closed and _badge_position(items_of(items).at(owner), opts) == "end" {
      ends.insert(str(owner), n)
    }
  }
  ends
}

/// For rubrics at the `"end"` of divisions split into segments, or given a
/// `height`: for each instruction (its index, as a string), the divisions
/// whose rubric follows it, as it ends all they hold, innermost first. Only
/// the divisions these instructions draw are counted: those of their
/// segments, and of their frames, with those whose number shares a frame's
/// first line; strictly within `root` when it is given (the division a
/// frame's instructions are inside, whose rubric is drawn after the frame,
/// out of its height, as it takes room of its own).
#let _rubric_ends(items, instructions, opts, root: none) = {
  let within(d) = {
    if root == none { return true }
    let a = items_of(items).at(d).parent
    while a != none {
      if a == root { return true }
      a = items_of(items).at(a).parent
    }
    false
  }
  let drawn = (:)
  for instr in instructions {
    // A frame draws the rubrics of the divisions inside it; its own, and
    // those whose number shares its first line, are drawn here, after it.
    let ds = if instr.kind == "segment" {
      (instr.division, ..instr.label_divisions)
    } else if instr.kind == "frame" { (instr.division, ..instr.labels) } else { () }
    for d in ds {
      if within(d) and _drawn(items_of(items).at(d), opts) { drawn.insert(str(d), true) }
    }
  }
  let last = (:)
  for (n, instr) in instructions.enumerate() {
    if instr.kind not in ("segment", "frame") { continue }
    let d = instr.division
    while d != none {
      if str(d) in drawn { last.insert(str(d), n) }
      d = items_of(items).at(d).parent
    }
  }
  let at = (:)
  for (d, n) in last {
    at.insert(str(n), at.at(str(n), default: ()) + (int(d),))
  }
  for (n, ds) in at {
    at.insert(n, ds.sorted(key: d => -items_of(items).at(d).level))
  }
  at
}

/// The styles instruction `instr` is drawn with (see `render`): those of
/// the item or division it draws, or a top-level break's own; `none` for
/// one drawn with whatever styles are around it.
#let _instruction_styles(items, instr) = {
  let kind = instr.kind
  let styles = if kind == "verbatim" { items_of(items).at(instr.item).styles } else if kind == "nested" {
    items_of(items).at(instr.root).styles
  } else if kind in ("segment", "frame") { items_of(items).at(instr.division).styles } else if kind == "break" {
    instr.at("styles", default: none)
  }
  if styles != none { stack_of(styles) }
}

/// Render a full instruction list. `opts` are the layout options resolved
/// from `config` (see `exam_options`). `root` is the division a frame's
/// instructions are inside (see `_rubric_ends`). `base` styles are already
/// applied around them.
///
/// Each style is applied once around the run of instructions it is the
/// same for, as Typst would apply the rule it comes from to its scope, not
/// to each instruction alone: a `#set page(..)` before some questions (with
/// `#show: exam`, inside the exam) starts one run of pages for them all, not
/// one per question. The runs are kept open on a stack, not by recursing,
/// as a document may have more rules than Typst lets functions recurse.
#let render(items, instructions, opts: DEFAULT_EXAM_OPTIONS, root: none, base: 0) = {
  let items = hold(items)
  let ends = _end_segments(items, instructions, opts)
  let rubric_ends = if opts.rubric.drawn and opts.rubric.position == "end" {
    _rubric_ends(items, instructions, opts, root: root)
  } else { (:) }
  // Instruction `n`, drawn inside styles `depth` deep.
  let one(n, depth) = {
    let instr = instructions.at(n)
    if instr.kind == "verbatim" {
      // Between divisions: a rubric here is no division's (see `OWNER`).
      let it = items_of(items).at(instr.item)
      let styles = stack_of(it.styles)
      apply_styles(it.body, styles.slice(calc.min(depth, styles.len())))
    } else if instr.kind == "rubrics" {
      _carried_rubrics(instr.items.map(i => items_of(items).at(i)))
    } else if instr.kind == "break" {
      if instr.target == "page" {
        pagebreak(weak: instr.weak)
      } else {
        colbreak(weak: instr.weak)
      }
    } else if instr.kind == "nested" {
      render_nested(items, instr.root, opts, base_styles: depth, end: instr.root != root)
    } else if instr.kind == "segment" {
      render_segment(items, instr, opts, ends: ends, n: n, base: depth)
    } else if instr.kind == "frame" {
      // A division with a `height`: one block of that height, which cannot
      // break across pages (see `fixed_height_break_error`), with what it
      // holds planned and rendered inside it, so that `fr` answer boxes in
      // it share its height.
      let inner = frame_plan(items, instr.division, labels: instr.labels, rubrics: instr.at("rubrics", default: ()))
      let height = fr_height(items_of(items).at(instr.division).fields.height, opts)
      // In a block of fixed height, `fr` heights are shares of it again.
      let inner_opts = if height == auto { opts } else { (..opts, fr-unit: none) }
      block(width: 100%, height: height, breakable: false, render(
        items,
        inner,
        opts: inner_opts,
        root: instr.division,
        base: depth,
      ))
    } else {
      panic("examy: unknown render instruction: " + repr(instr.kind))
    }
    for d in rubric_ends.at(str(n), default: ()) {
      block(width: 100%, inset: (left: cumulative_indent(items, d)), _rubric_end(items_of(items).at(d), opts))
    }
  }
  // The styles open, outermost first, each with what is drawn in it so far;
  // the first, of none, holds what is drawn with only `base` styles.
  let open = ((style: none, parts: ()),)
  // Close the innermost open style: what it holds, styled, goes into the
  // one around it.
  let close(open) = {
    let o = open.pop()
    open.at(-1).parts.push(apply_styles(o.parts.join(), (o.style,)))
    open
  }
  for (n, instr) in instructions.enumerate() {
    let styles = _instruction_styles(items, instr)
    if styles != none {
      // Keep the open styles it starts with, close the others, and open
      // the rest of its own.
      let keep = 1
      while keep < open.len() and base + keep - 1 < styles.len() and styles.at(base + keep - 1).id == open.at(keep).style.id {
        keep += 1
      }
      while open.len() > keep { open = close(open) }
      for s in styles.slice(calc.min(base + keep - 1, styles.len())) { open.push((style: s, parts: ())) }
    }
    let depth = base + open.len() - 1
    open.at(-1).parts.push(one(n, depth))
  }
  while open.len() > 1 { open = close(open) }
  open.first().parts.join()
}

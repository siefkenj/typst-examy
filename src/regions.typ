/// Where things are on the page, as data: each division's start, its answer
/// boxes, the name block's lines, and the pages' sizes and margins (the
/// "regions"), for a grading tool such as Gradescope to mark out each
/// question's part of the page. With `config`'s `embed-metadata`, an exam
/// leaves them in the document as `metadata` labelled `<examy-regions>`,
/// and attaches them to its PDF as `examy-regions.json` (see
/// `regions_export`). Positions are in pt from the page's top left.

#import "prelude.typ": *
#import "points.typ": PAGES, PAGES_START
#import "export.typ": attached_name, division_number, markdown

/// The labels of the markers the regions are read from: a division's start,
/// and where its own text goes on after its parts (or the exam's, after a
/// question); an answer box's corners; a name block's labels and lines; and
/// a page's size and margins.
#let START_MARK = label(PREFIX + "/region-start")
#let RESUME_MARK = label(PREFIX + "/region-resume")
#let BOX_MARK = label(PREFIX + "/region-box")
#let NAME_MARK = label(PREFIX + "/region-name")
#let PAGE_MARK = label(PREFIX + "/region-page")

/// What `config`'s `embed-metadata` embeds, given `value`: `(rubric,
/// extents)`, whether the rubrics and the regions.
#let embedded(value) = (rubric: value in (true, "rubric"), extents: value in (true, "question-extents"))

/// Whether an exam of options `opts` (see `exam_options`) leaves its
/// regions.
#let _extents(opts) = embedded(opts.at("embed-metadata", default: false)).extents

/// A length in pt, rounded to tenths: finer than a grading tool needs, and
/// short in the JSON.
#let _pt(l) = calc.round(l / 1pt, digits: 1)

/// Content as text, as the rubrics' export writes it (see `markdown`), or
/// `none`.
#let plain(c) = if c != none { markdown(c) }

/// A box's `outset` or `stroke`, `v`, side by side, as Typst reads it: one
/// value for all four sides, or a dictionary of `left`, `top`, ..., `x`, `y`,
/// and `rest`; a side it leaves out is `none`.
#let _sides(v) = {
  if type(v) != dictionary or not v.keys().any(k => k in ("left", "right", "top", "bottom", "x", "y", "rest")) {
    return (left: v, right: v, top: v, bottom: v)
  }
  let rest = v.at("rest", default: none)
  let x = v.at("x", default: rest)
  let y = v.at("y", default: rest)
  (left: v.at("left", default: x), right: v.at("right", default: x), top: v.at("top", default: y), bottom: v.at("bottom", default: y))
}

/// An answer box's outer corners, drawn with `inset`, `outset`, and the
/// `stroke` of its outline: placed from its content's corners out past its
/// inset and outset, and half its outline, which is drawn centred on its
/// edge. To go first in what the box holds, where they take no room.
#let box_marks(inset, outset, outline) = {
  let (o, s) = (_sides(outset), _sides(outline))
  let grow(side) = {
    let out = if o.at(side) == none { 0pt } else { o.at(side) }
    // A stroke of no thickness is 1pt thick.
    let t = if s.at(side) == none { 0pt } else { stroke(s.at(side)).thickness }
    inset + out + if t == auto { .5pt } else { t / 2 }
  }
  place(top + left, dx: -grow("left"), dy: -grow("top"), [#metadata((edge: "top"))#BOX_MARK])
  place(bottom + right, dx: grow("right"), dy: grow("bottom"), [#metadata((edge: "bottom"))#BOX_MARK])
}

/// A name block's row: `label`, its prefix, as text; and its line's
/// corners, its box's top left and bottom right, the right end of the line,
/// to go first in what the box holds, which is inset by `inset` (a box's
/// `inset`, of `x` and `bottom`).
#let name_label_mark(label) = [#metadata((kind: "label", text: plain(label)))#NAME_MARK]
#let name_line_marks(inset) = (
  place(top + left, dx: -inset.x, [#metadata((kind: "start"))#NAME_MARK])
    + place(bottom + right, dx: inset.x, dy: inset.bottom, [#metadata((kind: "end"))#NAME_MARK])
)

/// The languages Typst writes right to left, whose pages are bound on the
/// right (see `page`'s `binding`).
#let _RTL = ("ar", "dv", "fa", "he", "ks", "pa", "ps", "sd", "ug", "ur", "yi")

/// The page's margins, in pt, however they were set; and whether they are
/// mirrored, set as `inside` and `outside`, which swap on every other page.
/// Needs context.
#let _margins() = {
  let (w, h) = (page.width, page.height)
  let m = page.margin
  let all(v) = (top: v, bottom: v, left: v, right: v)
  let mirrored = type(m) == dictionary and ("inside" in m or "outside" in m)
  let sides = if m == auto {
    all(auto)
  } else if type(m) != dictionary {
    all(m)
  } else {
    let rest = m.at("rest", default: auto)
    let x = m.at("x", default: rest)
    let y = m.at("y", default: rest)
    let (l, r) = if mirrored {
      // The inside is the binding's side, which is the left of an odd
      // page (counted as printed, whatever its number says) when the binding
      // is on the left.
      let binding = if page.binding != auto { page.binding } else if (
        text.dir == rtl or (text.dir == auto and text.lang in _RTL)
      ) { right } else { left }
      let (inside, outside) = (m.at("inside", default: x), m.at("outside", default: x))
      if (calc.odd(here().page())) == (binding == left) { (inside, outside) } else { (outside, inside) }
    } else { (m.at("left", default: x), m.at("right", default: x)) }
    (top: m.at("top", default: y), bottom: m.at("bottom", default: y), left: l, right: r)
  }
  // Typst's default margin: 2.5/21 of the page's shorter side.
  let resolve(v, size) = if v == auto { 2.5 / 21 * calc.min(w, h) } else if type(v) == ratio {
    v * size
  } else if type(v) == relative { v.ratio * size + v.length.to-absolute() } else { v.to-absolute() }
  (
    margin: (
      top: _pt(resolve(sides.top, h)),
      bottom: _pt(resolve(sides.bottom, h)),
      left: _pt(resolve(sides.left, w)),
      right: _pt(resolve(sides.right, w)),
    ),
    mirrored: mirrored,
  )
}

/// The page's size and margins where it is, for the page it is on to be
/// told by: left at the start of the exam and of each division, so that
/// every page with something on it has one. Invisible. On a page of no fixed
/// size, nothing.
#let page_mark = context if type(page.width) == length and type(page.height) == length {
  [#metadata((width: _pt(page.width), height: _pt(page.height), .._margins()))#PAGE_MARK]
}

/// Where division `id` starts, at the top of its block, above all on its
/// first line, with the page's size and margins: placed first in the block,
/// where it takes no room. Only in an exam of options `opts` that leaves its
/// regions.
#let start_mark(id, opts) = if _extents(opts) { place(top + left, [#metadata(id)#START_MARK#page_mark]) }

/// Where the text of division `id` goes on, after one of its parts (or the
/// exam's, `none`, after a question): the answer boxes that follow are its.
/// Only in an exam of options `opts` that leaves its regions.
#let resume_mark(id, opts) = if _extents(opts) [#metadata(id)#RESUME_MARK]

/// The regions of the exam that ends at `here()`, from its point data
/// `rows` (see `compute_points_data`) and the markers it left, as
/// `regions_export` describes them. `name`: the exam's name, as text.
/// Needs context.
#let regions_data(rows, name) = {
  let at(loc) = {
    let p = loc.position()
    (page: p.page, x: _pt(p.x), y: _pt(p.y))
  }
  // The exam's own markers: its divisions' ids are its own, counted from 0
  // as another exam's are. And those since the exam before it ended: a name
  // block above an `exam(..)` is the exam's.
  let start = query(selector(PAGES_START).before(here())).last().location()
  let end = query(selector(PAGES).before(here())).last().location()
  let mine(s) = selector(s).after(start).before(end)
  let before = query(selector(PAGES).before(start)).at(-1, default: none)
  let since(s) = if before == none { selector(s) } else { selector(s).after(before.location()) }

  // Where each division starts, and each answer box, its outer corners,
  // under the division whose own text it is in. A box in a box is the
  // division's too.
  let starts = (:)
  let boxes = (:)
  let division = none
  let tops = ()
  for m in query(mine(selector(START_MARK).or(RESUME_MARK).or(BOX_MARK))) {
    if m.label == START_MARK {
      division = str(m.value)
      starts.insert(division, at(m.location()))
    } else if m.label == RESUME_MARK {
      division = if m.value != none { str(m.value) }
    } else if m.value.edge == "top" {
      tops.push((at: at(m.location()), division: division))
    } else if tops.len() > 0 {
      let top = tops.pop()
      if top.division != none {
        boxes.insert(top.division, boxes.at(top.division, default: ()) + ((top: top.at, bottom: at(m.location())),))
      }
    }
  }

  // The name block's lines, each with its label.
  let names = ()
  let prefix = none
  let line = none
  for m in query(since(NAME_MARK).before(end)) {
    if m.value.kind == "label" {
      prefix = m.value.text
    } else if m.value.kind == "start" {
      line = at(m.location())
    } else if line != none {
      names.push((label: prefix, start: line, end: at(m.location())))
      (prefix, line) = (none, none)
    }
  }

  // Each page from the exam's first (or its name block's) to its last, by
  // the size and margins of the last page before it that has them, swapped
  // on every other page when they are mirrored; those before the first, by
  // the first's.
  let marks = query(since(PAGE_MARK).before(end))
  let known = (:)
  for m in marks { known.insert(str(m.location().page()), (page: m.location().page(), ..m.value)) }
  let pages = ()
  let last = if marks.len() > 0 { (page: marks.first().location().page(), ..marks.first().value) }
  for p in range(calc.min(start.page(), ..names.map(n => n.start.page)), end.page() + 1) {
    last = known.at(str(p), default: last)
    if last == none { continue }
    let (page: from, width: width, height: height, margin: margin, mirrored: mirrored) = last
    if mirrored and calc.odd(p - from) { (margin.left, margin.right) = (margin.right, margin.left) }
    pages.push((page: p, width: width, height: height, margin: margin))
  }

  (
    format: "examy-gradescope-regions",
    version: 1,
    exam: name,
    pages: pages,
    names: names,
    ends: (at(end),),
    exams: (
      rows.map(r => (
        number: division_number(r.address),
        label: plain(r.label),
        level: r.level,
        points: r.total_points,
        bonus: r.total_bonus_points,
        start: starts.at(str(r.id), default: none),
        boxes: boxes.at(str(r.id), default: ()),
      )),
    ),
  )
}

/// The regions of the exam that ends here (see `regions_data`), as
/// `metadata` labelled `<examy-regions>`, and attached to its PDF as
/// `examy-regions.json`. Emitted at the end of an exam with
/// `embed-metadata` set to `true` or `"question-extents"`, after its record
/// of points by page (see `pages_record`). The data:
///
///   (format: "examy-gradescope-regions", version: 1, exam, pages, names,
///    ends, exams: (rows,))
///
/// `exam` the exam's name; `pages` each page's `(page, width, height,
/// margin)`; `names` the name block's lines, `(label, start, end)`; `ends`
/// where the exam's questions end; and `rows` a row per question, part, and
/// subpart: `(number, label, level, points, bonus, start, boxes)`, `start`
/// the top left of its first line, and each box `(top, bottom)`, the top
/// left and bottom right of its outline as drawn. A position is `(page, x,
/// y)`, in pt to a tenth.
#let regions_export(rows, name) = context {
  let data = regions_data(rows, name)
  [#metadata(data)<examy-regions>]
  if target() == "paged" {
    pdf.attach(
      attached_name("/examy-regions", ".json"),
      bytes(json.encode(data, pretty: false)),
      mime-type: "application/json",
      description: "Where the exam's questions and answer boxes are on its pages, for a grading tool",
    )
  }
}

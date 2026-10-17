#import "../prelude.typ": *
#import "../tokenize.typ": tokenize
#import "../parse.typ": parse
#import "../plan.typ": plan
#import "../render.typ": render
#import "../points.typ": EXAMS_ENDED, EXAMS_STARTED, assign_badges, compute_points_data, points_data_state
#import "../config.typ": config, exam_options
#import "./solution.typ": show_solutions
#import "../signature.typ": declare_function, define

/// The exam title block (in the spirit of LaTeX's `\maketitle`): the
/// institution, term, duration, and exam name, laid out as the head of a
/// cover page. Each value is taken from `config` unless overridden here
/// (pass `none` to suppress a configured value). Renders nothing if no
/// value is set at all.
///
/// ```typst
/// #show: e.set_(config, institution: [...], exam-name: [...],
///   term: [...], duration: duration(minutes: 110))
/// #maketitle()
/// // or, overriding the configured term:
/// #maketitle(term: [Summer 2026])
/// ```
#let _MAKETITLE = declare_function(
  "maketitle",
  doc: "The exam title block (in the spirit of LaTeX's `\\maketitle`). Renders nothing if all four values resolve to `none`.",
  fields: (
    e.field(
      "institution",
      e.types.union(auto, content, none),
      doc: "The institution name; `auto` takes `config`'s value, `none` suppresses it.",
      default: auto,
    ),
    e.field(
      "exam-name",
      e.types.union(auto, content, none),
      doc: "The exam name, shown bold; `auto` takes `config`'s value, `none` suppresses it.",
      default: auto,
    ),
    e.field(
      "term",
      e.types.union(auto, content, none),
      doc: "The term (e.g. Fall 2026); `auto` takes `config`'s value, `none` suppresses it.",
      default: auto,
    ),
    e.field(
      "duration",
      e.types.union(auto, duration, none),
      doc: "The exam length, shown under the term; `auto` takes `config`'s value, `none` suppresses it.",
      default: auto,
    ),
  ),
)

#let maketitle = define(_MAKETITLE, it => e.get(get => {
  let c = get(config)
  // Each value is `config`'s unless given here.
  let pick(key) = if it.at(key) == auto { c.at(key) } else { it.at(key) }
  let institution = pick("institution")
  let exam_name = pick("exam-name")
  let term = pick("term")
  let duration = pick("duration")
  if (institution, exam_name, term, duration).all(t => t == none) {
    return none
  }
  set text(font: "DejaVu Sans Mono")
  grid(
    columns: (1fr, 1fr),
    row-gutter: 1em,
    {
      set align(center)
      institution
    },
    {
      set align(center)
      term
      if duration != none {
        [\ ]
        text(size: .9em)[#duration.minutes() Minutes]
      }
    },

    {
      set align(center)
      text(weight: "bold", size: 1.2em)[#exam_name]
    },
  )
}))

/// The default rows for a name block.
#let DEFAULT_NAME_FIELDS = ((prefix: [Name:]), (prefix: [Student ID:]))

/// Render one entry of `name_fields` as grid cells. A dictionary entry
/// `(prefix: ..., suffix: ...)` (both optional) becomes a fill-in row:
/// the prefix, then an underline extending to the end of the line, with the
/// suffix sitting on the line at its right end. Any other entry is content
/// rendered verbatim, spanning the full block width.
#let _name_field_row(entry) = {
  if type(entry) != dictionary {
    return (grid.cell(colspan: 2, entry),)
  }
  let prefix = entry.at("prefix", default: none)
  let suffix = entry.at("suffix", default: none)
  (
    align(right + bottom, box(inset: (bottom: .35em), prefix)),
    align(bottom, box(
      width: 100%,
      stroke: (bottom: 1pt),
      inset: (bottom: .35em, x: .2em),
      {
        h(1fr)
        // An invisible character keeps empty lines the same height as ones
        // with a suffix.
        if suffix == none { hide[X] } else { suffix }
      },
    )),
  )
}

/// A block of fill-in rows (name, student ID, ...) for an exam cover or
/// quiz header. Place it on a cover page, at the top of a quiz, or anywhere
/// else in the document.
///
/// `fields` entries are either a `(prefix: ..., suffix: ...)` dictionary
/// (both keys optional), rendered as the prefix, an underline extending to
/// the end of the line, and the suffix sitting on the line at its right
/// end — or arbitrary content, rendered verbatim as its own row.
#let _NAME_BLOCK = declare_function(
  "name-block",
  doc: "A block of fill-in rows for a cover page or quiz header.",
  fields: (
    e.field(
      "title",
      e.types.option(content),
      doc: "A heading shown centered above the block.",
      default: none,
    ),
    e.field(
      "fields",
      e.types.array(e.types.union(dictionary, content)),
      doc: "One entry per row. A `(prefix: .., suffix: ..)` dictionary (both keys optional) renders the prefix, an underline extending to the end of the line, and the suffix sitting on the line at its right end; any other entry is content rendered verbatim as its own row.",
      default: DEFAULT_NAME_FIELDS,
      meta: (default-shown: "((prefix: [Name:]), (prefix: [Student ID:]))"),
    ),
  ),
)

#let name_block = define(_NAME_BLOCK, it => {
  let (title, fields) = (it.title, it.fields)
  set text(font: "DejaVu Sans Mono")
  if title != none and title != "" {
    set align(center)
    set text(size: .9em)
    title
    v(-.7em)
  }

  grid(
    columns: (auto, 1fr),
    row-gutter: 1em,
    column-gutter: .3em,
    ..fields.map(_name_field_row).flatten()
  )
})

/// API documentation for this module's exports, consumed by docs/api.typ
/// (keyed by export name). `exam` needs no argument docs here: elembic
/// elements are introspected.
#let DOCS = (exam: (kind: "element"), maketitle: _MAKETITLE, "name-block": _NAME_BLOCK)

/// Run the questions content through the full pipeline:
/// tokenize → parse → badges → plan → render (+ record point totals).
/// `opts` are the layout options resolved from `config` (see
/// `exam_options`).
#let process_questions(questions, opts) = {
  let items = assign_badges(
    parse(tokenize(questions)),
    show-totals: opts.points-show-totals,
    position: opts.points-position,
  )
  let data = compute_points_data(items, numberings: opts.numbering)
  // Each exam keeps its own data, and marks where it starts and ends, so
  // that a reader can tell which exam it is about (see `exam_points_data`).
  EXAMS_STARTED.step()
  points_data_state.update(all => all + (data,))
  render(items, plan(items), opts: opts)
  EXAMS_ENDED.step()
}

/// Start an exam or homework list.
#let exam = e.element.declare(
  "exam",
  prefix: PREFIX,
  doc: "Declare an exam",
  display: it => {
    // If `questions` is a function, call it with a `solutions_only` helper
    // that shows its argument only when solutions are enabled.
    e.get(get => {
      let opts = exam_options(get)
      if type(it.questions) == function {
        let solutions_only(content, otherwise: none) = {
          if show_solutions(get) == true {
            content
          } else {
            otherwise
          }
        }
        process_questions((it.questions)(solutions_only), opts)
      } else {
        process_questions(it.questions, opts)
      }
    })
  },
  fields: (
    e.field(
      "questions",
      e.types.union(content, function),
      doc: "The questions in the exam or a function that accepts a `solutions_only` function and returns the exam questions",
      required: true,
      named: true,
    ),
  ),
)

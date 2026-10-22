#import "../prelude.typ": *
#import "answer-box.typ": answer_box, config_options, resolve_boxes, rules_before
#import "../tokenize.typ": tokenize
#import "../parse.typ": parse
#import "../plan.typ": hold, plan
#import "../render.typ": mark_rubrics, render, rubric_info
#import "../points.typ": EXAMS_ENDED, EXAMS_STARTED, assign_badges, compute_points_data, points_data_state
#import "../config.typ": config, exam_options, exam_wide_names
#import "./solution.typ": show_rubrics, show_solutions
#import "../scan.typ": _find, rubric_markers
#import "../markers.typ": exam_marker, marker_value
#import "../rubric.typ": exam_end, exam_start
#import "../export.typ": rubric_export
#import "../signature.typ": declare_function, define, parse_args

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
  doc: "The exam title block (in the spirit of LaTeX's `\\maketitle`). Exam information is read from the global `config`. Renders nothing if all four values resolve to `none`. It is set in the text's font, like the rest of the document; set it apart with a `set` rule in a code block around it, e.g. `#{ set text(font: \"DejaVu Sans Mono\"); maketitle() }`.",
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
      e.types.union(auto, none, duration, content),
      doc: "The exam length, shown under the term: a `duration`, shown in minutes (`duration(minutes: 110)` as \"110 Minutes\"), or content, shown as it is (`[1 h 50 min]`). `auto` takes `config`'s value, `none` suppresses it.",
      default: auto,
    ),
  ),
)

/// What `maketitle` shows for a `duration`: a Typst `duration` in minutes,
/// content (or a string) as it is written.
#let duration_shown(d) = if type(d) == duration [#d.minutes() Minutes] else [#d]

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
        text(size: .9em, duration_shown(duration))
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

/// Render one entry of a name block's `fields` as grid cells. A dictionary entry
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
  doc: "A block of fill-in rows for a student to write their name. It is set in the text's font, like the rest of the document; set it apart with a `set` rule in a code block around it, e.g. `#{ set text(font: \"DejaVu Sans Mono\"); name-block() }`.",
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

/// Run the questions content through the full pipeline:
/// tokenize → parse → badges → plan → render (+ record point totals).
/// `opts` are the layout options resolved from `config` (see
/// `exam_options`).
#let process_questions(questions, opts) = {
  let items = assign_badges(
    parse(tokenize(questions, wide_names: opts.at("wide-names", default: ()))),
    show-totals: opts.points-show-totals,
    position: opts.points-position,
  )
  // Where its rubrics are, if it has any: an exam with none emits nothing
  // for them (see `mark_rubrics`).
  let (items, present) = mark_rubrics(items)
  let opts = opts
  opts.rubric.present = present
  opts.rubric.drawn = present and opts.rubric.shown
  opts.rubric.traced = opts.rubric.drawn and opts.rubric.trace
  let data = compute_points_data(items, numbering: opts.numbering)
  // Each exam keeps its own data, and marks where it starts and ends, so
  // that a reader can tell which exam it is about (see `exam_points_data`).
  EXAMS_STARTED.step()
  points_data_state.update(all => all + (data,))
  if present { exam_start }
  let held = hold(items)
  render(held, plan(held), opts: opts)
  // Its rubrics recorded, and as data for the command line (see export.typ).
  if present {
    let divisions = range(items.len())
      .filter(i => items.at(i).kind == "division" and items.at(i).at("rubric", default: false))
      .map(i => (address: items.at(i).address, field: items.at(i).fields.rubric, info: rubric_info(items.at(i), opts)))
    rubric_export(divisions)
    exam_end
  }
  EXAMS_ENDED.step()
}

/// The questions with the `solutions-only` helper, if they are a function
/// of it, laid out (see `process_questions`). Reads `config` where it is.
///
/// It reads elembic's record of the rules in force (`e.internal.debug-get`,
/// in the elembic pinned in prelude.typ), not only their values (`e.get`),
/// for the rules on its answer boxes (see `rules_before`).
#let _exam_body(questions) = e.internal.debug-get(data => {
  let get = data.ctx.get
  // The answer boxes' fields here, `config`'s options for them, and the
  // rules on them here, from which the exam draws them (see `resolve_boxes`).
  let boxes = (get(answer_box), config_options(get))
  let before = rules_before(data)
  // The rules before the exam on the options it reads once, which a `revoke`
  // in it may not undo (see `exam_wide_rule_error`).
  let wide_names = exam_wide_names(data)
  let opts = exam_options(get)
  opts.rubric.shown = show_rubrics(get)
  opts.insert("wide-names", wide_names)
  if type(questions) == function {
    // A function of a helper that shows its argument only on the key.
    let solutions_only(content, otherwise: none) = {
      if show_solutions(get) == true {
        content
      } else if type(content) == content and (otherwise == none or type(otherwise) == content) {
        // Like a hidden `solution`, it leaves the rubrics in what it
        // hides where it stands.
        rubric_markers(content).join() + otherwise
      } else {
        otherwise
      }
    }
    process_questions(resolve_boxes(questions(solutions_only), ..boxes, before: before), opts)
  } else {
    process_questions(resolve_boxes(questions, ..boxes, before: before), opts)
  }
})

/// `config`'s options, by name, that `exam` takes: all but the internal
/// ones.
#let _OPTIONS = {
  let fields = e.data(config).at("user-fields")
  let out = (:)
  for (name, f) in fields { if not f.internal { out.insert(name, f) } }
  out
}

#let _EXAM = declare_function(
  "exam",
  doc: "Lay out an exam: number its questions, parts, and subparts, draw them, and total their points for `points-table` and the other point counts. Written as a show rule, `#show: exam` (or `#show: exam.with(..)`, with options), it makes the rest of the document the exam.\n\nIt also applies `e.prepare()`, which the exam's references need.",
  fields: (
    e.field(
      "questions",
      e.types.union(content, function),
      doc: "The questions: content holding `question`s (with their `part`s and `subpart`s, and anything else between them).\n\nOr a function that returns them, for an answer key that differs from the exam in what it holds, not only in its solutions. The function is called with one argument, a function of its own, conventionally named `solutions-only`: `questions: solutions-only => [..]`. Within the questions, `solutions-only(x)` is `x` on the answer key and `none` on the exam, and `solutions-only(x, otherwise: y)` is `y` on the exam.\n\nUnlike `solution`, it draws what it is given as it is, not as a solution, and that can be any part of the questions: a part of its own on the key, a different `height` for an answer box (`height: solutions-only(auto, otherwise: 3cm)`), a whole question. A question only on the key renumbers the questions after it; to avoid that, give it `number: none`, or put what the key adds in a part.\n\nThe key is told from the exam as `show-solutions` tells it: by `config`'s `show-solutions`, unless the `--input show-solutions=..` command-line option overrides it.\n\nAlso accepted by name, `questions: [..]`, as in examy 0.4 and earlier.",
      required: true,
      named: false,
    ),
  ),
  rest: (
    name: "options",
    doc: "Any of `config`'s options, by name, e.g. `#show: exam.with(show-solutions: false, points-position: \"end\")`. They apply to everything inside the exam: its questions, and whatever comes before them in it, such as a cover page or a points table. Each is checked as `config` checks it; see `config` for every option and its default.",
    fields: _OPTIONS,
  ),
)

/// What `exam`'s arguments are checked against: its questions, and its
/// `rest`, `config`'s options.
#let _EXAM_ARGS = declare_function(
  "exam",
  fields: (_EXAM.fields.questions, .._EXAM.rest.fields.values()),
  positional-error: n => "exam: takes one positional argument, the questions, got " + str(n),
  takes: "its questions and `config`'s options",
)

/// `exam`'s arguments parsed: `(true, (questions, options))`, `options`
/// the `config` options given, or `(false, message)`. Pure.
#let parse_exam_args(args) = {
  let pos = args.pos()
  let named = args.named()
  // The questions, also accepted by name (see `_EXAM`).
  if "questions" in named {
    if pos.len() > 0 {
      return (false, "exam: the questions are given twice; write `exam[..]` or `exam(questions: [..])`, not both")
    }
    pos.push(named.remove("questions"))
  }
  if pos.len() == 0 {
    return (false, "exam: missing the questions, e.g. `#exam[#question[..]]` or `#show: exam`")
  }
  let (ok, values) = parse_args(_EXAM_ARGS, arguments(..pos, ..named))
  if not ok { return (false, values) }
  let options = (:)
  for name in named.keys() { options.insert(name, values.at(name)) }
  (true, (questions: values.questions, options: options))
}

/// Lay out an exam (see DOCS): `exam[..]`, `exam(questions: [..])`, or as
/// a show rule, `#show: exam.with(..)`. Every named argument but
/// `questions` is a `config` option, set for this exam only.
///
/// An exam around another one (`#show: exam.with(..)` above an
/// `#exam(questions: ..)`, say) steps aside: it only sets its options for
/// what it holds, and the exam inside lays out the questions. Questions of
/// its own beside it would be in neither, and are an error.
#let exam(..args) = {
  let (ok, result) = parse_exam_args(args)
  assert(ok, message: if ok { "" } else { result })
  let (questions, options) = result
  // Looked for with an early exit, not by a full `scan`: `tokenize` walks
  // the questions once more anyway, if this exam lays them out.
  let kind_in(x, kinds) = {
    let m = marker_value(x)
    m != none and m.kind in kinds
  }
  let inner = type(questions) == content and _find(questions, x => kind_in(x, ("exam",)), first: true).len() > 0
  if inner and _find(questions, x => kind_in(x, ("begin", "end")), first: true).len() > 0 {
    panic(
      "examy: an `exam` holds both questions of its own and another `exam`; "
        + "put all the questions in one of them (with `#show: exam`, the rest "
        + "of the document is the exam, so an `#exam(..)` below it is inside it)",
    )
  }
  // Where an exam is, for one around it to find (see above).
  exam_marker
  // What the exam's references need, whether or not the document has it.
  show: e.prepare()
  show: if options.len() > 0 { e.set_(config, ..options) } else { it => it }
  if inner { questions } else { _exam_body(questions) }
}

/// API documentation for this module's exports, consumed by docs/api.typ
/// (keyed by export name).
#let DOCS = (exam: _EXAM, maketitle: _MAKETITLE, "name-block": _NAME_BLOCK)

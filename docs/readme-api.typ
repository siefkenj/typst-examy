// The README's basic API reference, as a Markdown string, exposed via
// `#metadata(..) <api>` so that make_docs.sh can extract it with
// `typst eval` and splice it into README.md. The full reference, with every
// export and argument, is on the documentation site (see site.typ).
//
// Which exports the table shows, how they are grouped, and what each row
// says are written here, in `ROWS`: it is a short, hand-picked overview, not
// a list of everything. The exports it leaves out are listed in `OMITTED`.
// Every export must be in exactly one of the two, so that one added to the
// package later fails the build until it is given a row or left out on
// purpose. Each name's link and signature come from api.typ, which reads
// the package's declarations, so they cannot fall out of date.

#import "/src/lib.typ"
#import "api.typ": ENTRIES, IMPORT, entry, page_path

#let HOMEPAGE = toml("/typst.toml").package.homepage

/// The rows of the table: the exports each shows, and what it says of them.
#let ROWS = (
  (("answer-box",), "A box for students to write answers in."),
  (("choice",), "A round or square bubble (used for multiple-choice questions) followed by the choice it labels."),
  (
    ("choices",),
    "An enumerate environment for multiple-choice answers. Every list item gets turned into a `#choice`, with a round/square bubble as its list marker.",
  ),
  (
    ("config",),
    "Global configuration of package options. Give options to the exam, e.g. `#show: exam.with(show-solutions: true)`, or set them with `#show: e.set_(config, show-solutions: true)`.",
  ),
  (("e",), "A re-export of [elembic](https://typst.app/universe/package/elembic), used mainly for `e.set_`."),
  (("exam",), "Lays out an exam. Start one with `#show: exam` (or `#show: exam.with(..)`, with `config` options)."),
  (
    ("maketitle",),
    "The exam title block (in the spirit of LaTeX's `\\maketitle`). Exam information is read from the global `config`.",
  ),
  (("name-block",), "A block of fill-in rows for a student to write their name."),
  (("points-table", "num-points", "num-questions"), "Display a scoring table and other information about the exam."),
  (("question", "part", "subpart"), "Declare a question, part, or subpart — numbered `1.`, `(a)`, or `i.` respectively."),
  (
    ("rubric", "rubric-list"),
    "Grading rubric items for a question, part, or subpart, drawn on the graders' copy, and every rubric of the exam as a list.",
  ),
  (
    ("solution",),
    "Declare a solution to a question, part, or subpart; this is only rendered if the config option to show solutions is enabled.",
  ),
)

/// The exports the table leaves out, on purpose: they are in the full
/// reference on the site.
#let OMITTED = (
  "bubble",
  "square-bubble",
  "num-points-page",
  "page-score-box",
  "presets",
  "show-solutions",
)

// Every export in exactly one of `ROWS` and `OMITTED`, and nothing else in
// either.
#{
  let exports = ENTRIES.map(x => x.names).flatten()
  let shown = ROWS.map(((names, _)) => names).flatten()
  let fail(message) = panic("readme-api.typ: " + message)
  for n in shown + OMITTED {
    if n not in exports { fail("`" + n + "` is not an export of examy") }
  }
  for n in shown.dedup() {
    if shown.filter(m => m == n).len() > 1 { fail("`" + n + "` is in more than one row of ROWS") }
    if n in OMITTED { fail("`" + n + "` is both in ROWS and in OMITTED") }
  }
  let missing = exports.filter(n => n not in shown and n not in OMITTED)
  if missing.len() > 0 {
    fail(
      "the README's API table does not say what to do with "
        + missing.map(n => "`" + n + "`").join(", ")
        + ": add each to a row of ROWS, or to OMITTED",
    )
  }
}

/// The site's page for an export. A group, such as `question`/`part`/
/// `subpart`, shares one, with an anchor for each name after the first (see
/// `entry_page` in site/template.typ).
#let link_to(name) = {
  let x = entry(name)
  HOMEPAGE + page_path(x) + if name != x.names.first() { "#api-" + name } else { "" }
}

/// How an export is written in a document, bare of its arguments:
/// `#name[..]` for one that takes content, `#name(..)` for one called with
/// arguments only, `#name()` for one that takes none, `#name` for a value
/// that is content, and `name` for
/// anything used in code (`config`, `e`, `presets`, or a function such as
/// `show-solutions(get)`, which is given something other than content).
#let bare_signature(name) = {
  let x = entry(name)
  if x.kind in ("function", "element") and x.show-signature {
    let positional = x.args.filter(a => not a.named)
    if x.args.len() == 0 {
      "#" + name + "()"
    } else if positional.len() == 0 {
      "#" + name + "(..)"
    } else if positional.first().type.contains("content") {
      "#" + name + "[..]"
    } else {
      name + "(" + positional.map(a => a.name).join(", ") + ")"
    }
  } else if type(dictionary(lib).at(name)) == content {
    "#" + name
  } else {
    name
  }
}

/// One table row: its exports, each linked, and what it says of them.
#let row((names, what)) = {
  let shown = names.map(n => "[`" + bare_signature(n) + "`](" + link_to(n) + ")").join(", ")
  "| " + shown + " | " + what.replace("|", "\\|") + " |"
}

#let md = (
  (
    "All names below are exported by `" + IMPORT + "`. "
      + "See the [full reference](" + HOMEPAGE + "reference.html) for all arguments.",
    "",
    "| Export | |",
    "| --- | --- |",
  )
    + ROWS.map(row)
).join("\n")

#metadata(md) <api>

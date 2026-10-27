#import "../prelude.typ": *
#import "../config.typ": DEFAULT_BUBBLE_LABEL_FONT, DEFAULT_BUBBLE_STROKE, config
#import "bubble.typ": (
  bubble, check_enumerate, choice_label, draw_choice, enumerate_count_error, enumerate_error, shape_error, shape_name,
  square_bubble,
)
#import "../signature.typ": UNSET, declare_function, define, unset_or
#import "../markers.typ": excerpt

/// The default space between two choices side by side, inline or in columns
/// (see `gap`). One per line, the default is the text's own line spacing.
#let _SIDE_BY_SIDE_GAP = 1.5em

/// Names an author might reach for in place of `correct`.
#let _CORRECT_ALIASES = ("answer", "answers", "solution", "solutions", "correct-answer", "key", "right")

/// The shape named by a `bubble:` option: whatever `choice` takes for its
/// own `bubble:` (see `shape_name`), or one of examy's own bubble functions,
/// which an author may well pass here.
#let choices_shape(value) = {
  if value == bubble { return "circle" }
  if value == square_bubble { return "square" }
  shape_name(value, "choices")
}

/// What is wrong with a `bubble:` option of `choices`, or `none`.
#let _choices_shape_error(value) = if value not in (bubble, square_bubble) { shape_error(value, "choices") }

/// A short, readable excerpt of `c` for an error message: its text where it
/// has any, else the name of the element it is.
#let _excerpt(c) = {
  let s = excerpt(c, 30)
  if s == "" { return "`" + repr(c.func()) + "`" }
  "`" + s + "`"
}

/// Why `c`, found among the choices, is not one: the message for an author
/// who wrote it there, naming the likely mistake where one is recognizable.
#let _not_a_choice(c) = {
  let how = "Start each choice on its own line with `- ` (or `+ ` for a correct one)."
  let f = c.func()
  let why = if f == strong {
    "found bold text " + _excerpt(c) + ". A line starting with `*` is bold text in Typst, not a list item. " + how
  } else if f == terms.item {
    "found a term-list item (`/ term: ..`), which is not a choice. " + how
  } else if f == [#set text(red)].func() {
    "found a `#set` or `#show` rule among the choices. Move it out of `#choices[..]`, before it or into a block around it."
  } else if f in (text, emph, math.equation, smartquote, raw, ref, link) {
    "found " + _excerpt(c) + " outside any choice. " + how + " Text that introduces the choices goes before `#choices`."
  } else {
    "found " + _excerpt(c) + ", which is not a choice. " + how
  }
  "choices: " + why
}

/// The children of `body`, with nested sequences (as a `for` loop or a
/// `#[..]` block produces) spread out into their own children.
#let _flat_children(body) = {
  if body.func() != [].func() { return (body,) }
  body.children.map(_flat_children).flatten()
}

/// The choices in `body`, in order, each as `(body: content, marked: bool)`.
///
/// An array is taken as the choices themselves, none of them marked; its
/// entries are made content, so a bare string or number works as well. A
/// content block is expected to hold a list: each `- ..` item is a choice,
/// and each `+ ..` item a choice marked correct. Typst parses the two as
/// `list.item` and `enum.item`, which sit side by side in the block's
/// children (they are only grouped into lists later, at layout), so they can
/// be read off in order however they are interleaved.
#let parse_choices(body) = {
  if type(body) == array {
    return body.map(b => (body: [#b], marked: false))
  }
  assert(
    type(body) == content,
    message: "choices: expected the choices as a list, one `- ..` item per choice (`+ ..` for a correct one), or as an array such as `(\"a\", \"b\")`; got "
      + str(type(body))
      + " "
      + repr(body),
  )
  _flat_children(body)
    .filter(c => c.func() not in ([ ].func(), parbreak))
    .map(c => {
      if c.func() == list.item {
        (body: c.body, marked: false)
      } else if c.func() == enum.item {
        // `1.` is an enum item too; taking it as a correct answer would be a
        // surprise, so it is refused rather than read as a `+`.
        if c.has("number") {
          panic(
            "choices: mark a correct choice with `+`, not a numbered item (`"
              + str(c.number)
              + ".`); start the other choices with `- `",
          )
        }
        (body: c.body, marked: true)
      } else {
        panic(_not_a_choice(c))
      }
    })
}

/// The text of a label, or of a `correct:` entry naming one: a string as it
/// is, the text in content gathered.
#let _text(x) = {
  if type(x) == str { return x }
  if type(x) != content { return repr(x) }
  if x.func() == [ ].func() { return " " }
  if x.has("text") and type(x.text) == str { return x.text }
  if x.has("children") { return x.children.map(_text).join(default: "") }
  if x.has("body") { return _text(x.body) }
  if x.has("child") { return _text(x.child) }
  ""
}

/// A label as `correct:` matches it loosely: in lower case, with only its
/// letters and digits, so that `"a"`, `"A"`, and `"(a)"` all name the
/// choice labelled "A".
#let _loose(label) = lower(label).replace(regex("[^\\p{L}\\p{N}]"), "")

/// The texts of the labels of `count` choices, as `enumerate` (resolved, not
/// `auto`) labels them, which a `correct:` entry names a choice by; `none`
/// when `enumerate` is `false`, and they have none.
#let choice_label_texts(enumerate, count) = {
  if enumerate == false { return none }
  range(count).map(i => _text(choice_label(enumerate, i)).trim())
}

/// The index of the choice a label names, of those labelled `labels`: the
/// one it is, exactly, or else the one it is loosely (see `_loose`). Choices
/// without labels (`labels` is `none`) cannot be named by one.
#let _label_index(entry, labels) = {
  assert(
    labels != none,
    message: "choices: `correct: "
      + repr(entry)
      + "` names a choice by its label, but these choices have none; label them with `enumerate` "
      + "(`enumerate: true` for A, B, C), or name the choice by its index (`correct: 0` for the first)",
  )
  let text = _text(entry).trim()
  let named = labels.enumerate().filter(((i, l)) => l == text).map(((i, l)) => i)
  if named.len() == 0 {
    named = labels.enumerate().filter(((i, l)) => _loose(l) != "" and _loose(l) == _loose(text)).map(((i, l)) => i)
  }
  assert(
    named.len() > 0,
    message: "choices: `correct: "
      + repr(entry)
      + "` names no choice: they are labelled "
      + labels.join(", ", last: " and ")
      + if text.clusters().len() > calc.max(..labels.map(l => l.clusters().len()), 1) {
        ". To mark a choice by its content, start it with `+` instead of `-`"
      } else { "" },
  )
  assert(
    named.len() == 1,
    message: "choices: `correct: "
      + repr(entry)
      + "` names several choices ("
      + named.map(i => labels.at(i)).join(", ", last: " and ")
      + "); write the label exactly as it is drawn",
  )
  named.first()
}

/// The indices named by a `correct:` option, checked against the `count`
/// choices there are and made non-negative: `none` names none, an integer
/// or a label one, an array several. Indices count the way Typst's own
/// arrays do: from 0 at the first choice, or from -1 at the last. A label,
/// a string or content, is matched against what `enumerate` labels the
/// choices with (see `choice_label_texts`).
#let correct_indices(correct, count, enumerate: false) = {
  let entries = if correct == none { () } else if type(correct) == array { correct } else { (correct,) }
  // Worked out only if some entry is a label.
  let labels = if entries.any(i => type(i) in (str, content)) { choice_label_texts(enumerate, count) }
  entries.map(i => {
    if type(i) in (str, content) { return _label_index(i, labels) }
    assert(
      type(i) == int,
      message: "choices: `correct` names choices by their index (`correct: 1` for the second) or label "
        + "(`correct: \"B\"`), or several of them in an array (`correct: (0, 2)`), got "
        + repr(i),
    )
    assert(
      -count <= i and i < count,
      message: "choices: `correct` names choices by index, 0 to "
        + str(count - 1)
        + " counting from the first or -1 to -"
        + str(count)
        + " from the last, but there "
        + if count == 1 { "is 1 choice" } else { "are " + str(count) + " choices" }
        + ", so "
        + repr(i)
        + " names none of them",
    )
    if i < 0 { i + count } else { i }
  })
}

/// The choices in `body`, each as `(body: content, correct: bool)`: correct
/// if it is a `+` item *or* named by `correct`, so the two ways of marking
/// an answer can be mixed. `enumerate` is what labels the choices, for a
/// `correct` naming them by label; `source` is the function and option it
/// came from, which an error about it names.
#let resolve_choices(body, correct: none, enumerate: false, source: ("choices", "enumerate")) = {
  let choices = parse_choices(body)
  let message = enumerate_count_error(enumerate, choices.len(), source.at(0), name: source.at(1))
  if message != none { assert(false, message: message) }
  let indices = correct_indices(correct, choices.len(), enumerate: enumerate)
  choices.enumerate().map(((i, c)) => (body: c.body, correct: c.marked or i in indices))
}

#let _CHOICES = declare_function(
  "choices",
  doc: "Used for creating multiple-choice questions. Accepts a list, with each list item becoming a `#choice[..]` with a bubble. Correct choice use `+` and incorrect choices use `-` as their list item designator.
  
  For example, to specify a list of choices, `a`, `b`, `c`, with `c` being the correct choice, use:
  ```
  #choices[
   - a
   - b
   + c
  ]
  ```
  
  When solutions are shown, the correct choices are filled in and checked.",
  fields: (
    e.field(
      "body",
      e.types.union(content, array),
      doc: "The choices, as a list (one `- ..` item per choice, or `+ ..` for a correct one) or the choices as an array of content.",
      required: true,
      meta: (hint: "give the choices as a list, one `- ..` item per choice (`+ ..` for a correct one), or as an array such as `(\"a\", \"b\")`"),
    ),
    e.field(
      "correct",
      e.types.union(none, int, str, content, array),
      doc: "The correct choice, by index (`0`-indexed) or by label if `enumerate: true` is set (e.g. `\"A\"` for `enumerate: true`), or an array of indices/labels. Additive with choices marked with `+`.",
      default: none,
      meta: (hint: "name choices by their index (`correct: 1` for the second) or label (`correct: \"B\"`), several in an array (`correct: (0, 2)`), or start a correct choice with `+` instead of `-`"),
    ),
    e.field(
      "bubble",
      e.types.union(e.types.literal("circle"), e.types.literal("square"), function),
      doc: "The shape of the bubbles: `\"circle\"` for \"select one\", `\"square\"` for \"select all that apply\".",
      default: "circle",
      // Typst's own `circle` and `square` are taken too, and examy's
      // `bubble` and `square-bubble`, but not documented.
      meta: (check: _choices_shape_error, type-shown: "\"circle\" | \"square\""),
    ),
    e.field(
      "inline",
      e.types.union(auto, bool),
      doc: "Show the choices inline in a paragraph. If you would like a grid of choices, consider using `columns` instead.",
      default: auto,
      meta: (hint: "write `true` or `false`"),
    ),
    e.field(
      "columns",
      unset_or(int, none),
      doc: "Split the choices into the specified number of columns. Setting to `none` results in a single column (i.e., each choice on its own line). Cannot be combined with `inline`.",
      default: UNSET,
      meta: (
        hint: "give a number of columns, such as `columns: 2`",
        check: v => if type(v) == int and v < 1 {
          "choices: `columns` must be a number of columns, such as `columns: 2`, got " + repr(v)
        },
        default-shown: "none",
      ),
    ),
    e.field(
      "gap",
      unset_or(auto, length, fraction),
      doc: "The space between the choices. Setting to `auto` uses the usual line spacing for choices on separate lines, and `1.5em` for choices side by side. A fraction (e.g. `1fr`) spreads side-by-side choices across the line.",
      default: UNSET,
      meta: (hint: "give a length, such as `1em`", default-shown: "auto"),
    ),
    e.field(
      "stroke",
      e.types.smart(length),
      doc: "The outline thickness of the bubbles. Setting to `auto` uses `config`'s `bubble-stroke`.",
      default: auto,
    ),
    e.field(
      "label-font",
      e.types.union(auto, str, array),
      doc: "The font of the labels inside the bubbles, relevant when `enumerate: true` is set.",
      default: auto,
    ),
    e.field(
      "solution-color",
      e.types.union(auto, color),
      doc: "The primary color for the correct bubbles; i.e., the color of their outlines, check marks, and text when filled in. Setting to `auto` uses `config`'s `solution-color`.",
      default: auto,
    ),
    e.field(
      "solution-background-color",
      e.types.union(auto, color),
      doc: "The background color for the correct bubbles when filled in. Setting to `auto` uses `config`'s `solution-background-color`.",
      default: auto,
    ),
    e.field(
      "enumerate",
      e.types.union(auto, bool, str, function, array),
      doc: "Determines how the bubbles are labelled. Setting to `false` results in no labels; `true` results in A, B, C, …. A numbering pattern, function, or array of labels can be used (e.g., `\"a\"` or `(\"x\", \"y\", \"z\")`). Setting to `auto` uses `config`'s `choices-enumerate`.",
      default: auto,
      meta: (check: v => enumerate_error(v, "choices", allow-auto: true)),
    ),
  ),
  aliases: _CORRECT_ALIASES
    .map(k => (k, "mark a correct choice with `+` in place of `-`, or name it by index or label with `correct:`"))
    .to-dict(),
  positional-error: n => (
    "choices: the choices go in one argument — a list, one `- ..` item per choice, or an array such as `(\"a\", \"b\")` — but got "
      + str(n)
      + " separate arguments"
  ),
)

/// A multiple-choice answer: a bubble for each choice, filled in and
/// checked on the answer key for the correct ones.
///
/// Laid out one choice per line by default, `gap` apart — as close as the
/// lines of a paragraph unless `gap` says otherwise. `columns: n` sets them
/// in `n` equal columns instead, filled across each row in turn, so they
/// read in the order they were written; each choice is drawn as on a line of
/// its own, so a long one wraps within its column. `inline: true` runs them
/// together side by side in a paragraph of their own, each kept whole unless
/// it is longer than a line. In both, `gap` is the space between two choices
/// side by side; inline it is weak, so a choice that wraps to the start of a
/// line is not indented by it.
#let choices = define(_CHOICES, it => {
  let enumerate = it.enumerate
  let shape = choices_shape(it.bubble)
  // Every layout is a block — a paragraph of its own, so that choices
  // written on the line after a question start below it rather than running
  // on from its text, and one an answer box can see, so that it fits them
  // rather than taking them for a bare `context`.
  block(e.get(get => {
    let cfg = get(config)
    // The layout, as the call gives it, or else as `config` does: the two
    // options together, as they cannot be combined.
    let given = it.inline != auto or it.columns != UNSET
    let (inline, columns) = if given {
      (it.inline == true, if it.columns == UNSET { none } else { it.columns })
    } else { (cfg.choices-inline, cfg.choices-columns) }
    let layout = if given { "choices: `inline` and `columns`" } else { "config: `choices-inline` and `choices-columns`" }
    assert(
      not (inline and columns != none),
      message: layout + " are two different layouts; use one or the other",
    )
    assert(
      columns == none or columns >= 1,
      message: "config: `choices-columns` must be a number of columns, such as `choices-columns: 2`, got "
        + repr(columns),
    )
    let (gap, gap_name) = if it.gap == UNSET { (cfg.choices-gap, "config: a fractional `choices-gap`") } else {
      (it.gap, "choices: a fractional `gap`")
    }
    assert(
      type(gap) != fraction or inline or columns != none,
      message: gap_name
        + " spreads choices across a line, so it needs `inline: true` or `columns`; one choice per line, give a length such as `1em`",
    )
    let side_gap = if gap == auto { _SIDE_BY_SIDE_GAP } else { gap }
    // `auto` follows `config`, read and checked once for the whole list.
    let source = if enumerate == auto { ("config", "choices-enumerate") } else { ("choices", "enumerate") }
    let enumerate = if enumerate == auto {
      let configured = get(config).choices-enumerate
      check_enumerate(configured, "config", name: "choices-enumerate")
      configured
    } else { enumerate }
    // Here, where the labels are known, for a `correct` naming them.
    let resolved = resolve_choices(it.body, correct: it.correct, enumerate: enumerate, source: source)
    // Each choice drawn as one unit (see `draw_choice`): boxed, to sit in a
    // line beside the others, or as a block of its own.
    let drawn = resolved
      .enumerate()
      .map(((i, c)) => draw_choice(
        c.body,
        shape: shape,
        correct: c.correct,
        enumerate: enumerate,
        index: i,
        inline: inline,
        stroke: it.stroke,
        label-font: it.label-font,
        color: it.solution-color,
        background: it.solution-background-color,
        caller: "choices",
      ))
    if inline {
      drawn.join(h(side_gap, weak: true))
    } else if columns != none {
      // Rows are spaced like the choices of the one-per-line layout.
      grid(columns: (1fr,) * columns, column-gutter: side_gap, row-gutter: par.leading, ..drawn)
    } else {
      // Each choice is a list of its own (see `draw_choice`), and Typst
      // spaces two lists in a row by the paragraph spacing, so setting that
      // spaces the choices. It also spaces the paragraphs of a choice that
      // has several, which keeps them as apart as the choices are; unlike
      // setting the block spacing, it leaves alone the space around an
      // equation or other block inside a choice.
      set par(spacing: if gap == auto { par.leading } else { gap })
      drawn.join()
    }
  }))
})

/// API documentation for this module's exports, consumed by docs/api.typ
/// (keyed by export name).
#let DOCS = (choices: _CHOICES)

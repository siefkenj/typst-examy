// A `solution` standing alone in a paragraph of an answer box fills the
// box's width; one sharing its paragraph with other content stays inline and
// shrink-wrapped, so it does not break up the sentence around it.
#import "/src/lib.typ": *

#set page(width: 8.5in, height: auto, margin: 1in)
#show: e.prepare()
#show: e.set_(config, show-solutions: true)

// Markers pinned to the left and right edges of the solution's own box. The
// right one is `place`d, so it is out of flow and cannot itself stretch a
// shrink-wrapped box: the distance between the two *is* the rendered width.
#let probe(name) = {
  [#box(width: 0pt, metadata(none))#label("l-" + name)]
  [ok]
  place(right, [#box(width: 0pt, metadata(none))#label("r-" + name)])
}

#let _default_height = 1in

// --- alone in a paragraph: fills the box ---
_A solution in its own paragraph after a prompt fills the box._
#answer-box(height: _default_height, width: 100%)[
  Show your work.

  #solution[#probe("own-par")]
]
_A solution that is the box's only content fills the box._
#answer-box(height: _default_height, width: 100%)[#solution[#probe("sole")]]
_A solution after a set rule fills the box._
#answer-box(height: _default_height, width: 100%)[
  #set text(size: 9pt)
  #solution[#probe("after-set")]
]
_A solution in its own paragraph after a prompt and a set rule fills the box._
#answer-box(height: _default_height, width: 100%)[
  Prompt. #set text(size: 9pt)

  #solution[#probe("after-prose-and-set")]
]
// A block-level sibling starts a new paragraph without emitting a parbreak.
_A solution right after a table fills the box, because the table ends the paragraph._
#answer-box(height: _default_height, width: 100%)[#table(columns: 1)[x] #solution[#probe(
    "after-block",
  )]]
_Two solutions in separate paragraphs each fill the box._
#answer-box(height: _default_height, width: 100%)[
  #solution[#probe("first-of-two")]

  #solution[#probe("second-of-two")]
]

// --- sharing a paragraph: stays inline ---
_A solution in the middle of a sentence stays inline._
#answer-box(height: _default_height, width: 100%)[We look at #solution[#probe("mid-sentence")] for
  an answer.]
_A solution at the end of a sentence stays inline._
#answer-box(height: _default_height, width: 100%)[We look at #solution[#probe("trailing")]]
_Two solutions sharing a paragraph both stay inline._
#answer-box(height: _default_height, width: 100%)[#solution[#probe("shared-a")] and
  #solution[#probe("shared-b")]]
_A solution after a set rule, in the same paragraph as a prompt, stays inline._
#answer-box(height: _default_height, width: 100%)[
  Prompt. #set text(size: 9pt)
  #solution[#probe("continuing-after-set")]
]
// The paragraph continues past the end of a set rule's scope or a content
// block, the mirror image of the case above.
_A solution followed by a set rule and more text stays inline._
#answer-box(height: _default_height, width: 100%)[
  #solution[#probe("before-set")] #set text(size: 9pt); and more text.
]
_A solution at the end of a content block that is followed by more text stays inline._
#answer-box(height: _default_height, width: 100%)[#[#set text(size: 9pt); #solution[#probe(
      "end-of-content-block",
    )]] and more text.]
// Smart quotes are inline, not paragraph boundaries.
_A solution in quotation marks stays inline._
#answer-box(height: _default_height, width: 100%)[Is it "#solution[#probe("quoted")]" or not?]

// --- a paragraph inside a content block can still be alone ---
_A solution alone in its paragraph inside a content block fills the box._
#answer-box(height: _default_height, width: 100%)[
  Prompt.

  #[#set text(size: 9pt)
    #solution[#probe("own-par-in-content-block")]]
]

// --- nested answer boxes: each box widens only its own paragraphs ---
// The inner box's solution fills the inner box; the outer box's own
// solution, in a paragraph of its own after it, fills the outer box; and one
// beside a small inline box shares its line, so it stays inline.
_Each lone solution fills its own box, and one beside a small box stays inline._
#answer-box(height: 3 * _default_height, width: 100%)[
  #answer-box(height: _default_height, width: 100%)[#solution[#probe("nested-inner")]]

  #solution[#probe("nested-outer")]

  #answer-box(height: 1cm, width: 2cm)[] #solution[#probe("nested-beside")]
]

// --- an explicit width always wins over the widening ---
// `width` defaults to `none`, meaning "the context chooses". Any other value
// is a deliberate choice and is kept, including `auto`, and including when it
// comes from a set rule rather than an argument.
_A solution with `width: auto` stays inline._
#answer-box(height: _default_height, width: 100%)[
  #solution(width: auto)[#probe("arg-auto")]
]
_A solution with `width: 3cm` is 3cm wide._
#answer-box(height: _default_height, width: 100%)[
  #solution(width: 3cm)[#probe("arg-3cm")]
]
#[
  _Set width to auto for all solutions._
  #show: e.set_(solution, width: auto)
  #answer-box(height: _default_height, width: 100%)[
    #solution[#probe("set-rule-auto")]
  ]
]

// --- left alone elsewhere ---
_Solution inside table doesn't automatically expand._
#answer-box(height: _default_height, width: 100%)[
  #table(columns: (4cm, 4cm))[#solution[#probe(
    "in-cell",
  )]]]
_Outside an answer box solutions don't expand_: #solution[#probe("outside")]

#context {
  let rendered(name) = {
    let x(p) = query(label(p + "-" + name)).first().location().position().x
    x("r") - x("l")
  }
  // The answer boxes are 6.5in wide, less 5pt of answer-box inset and 3pt of
  // solution inset on each side.
  let full = 6.5in - 10pt - 6pt
  let width_is(name, expected) = assert(
    calc.abs(rendered(name).pt() - expected.pt()) < 1,
    message: name
      + ": expected a rendered width of "
      + repr(expected)
      + ", got "
      + repr(rendered(name)),
  )
  // A shrink-wrapped box is as wide as the word "ok"; anything under an inch
  // is unambiguously not filling a 6.5in box.
  let narrow(name) = assert(
    rendered(name) < 1in,
    message: name + ": expected the solution to shrink-wrap, got " + repr(rendered(name)),
  )

  width_is("own-par", full)
  width_is("sole", full)
  width_is("after-set", full)
  width_is("after-prose-and-set", full)
  width_is("after-block", full)
  width_is("first-of-two", full)
  width_is("second-of-two", full)

  narrow("mid-sentence")
  narrow("trailing")
  narrow("shared-a")
  narrow("shared-b")
  narrow("continuing-after-set")
  narrow("before-set")
  narrow("end-of-content-block")
  narrow("quoted")
  width_is("own-par-in-content-block", full)
  // The inner box is as wide as the outer box's content, so it loses another
  // 5pt of answer-box inset on each side.
  width_is("nested-inner", full - 10pt)
  width_is("nested-outer", full)
  narrow("nested-beside")

  // Only the answer box's own paragraphs are considered, so a solution inside
  // a container keeps its default.
  narrow("in-cell")
  // An explicit width is kept (less the solution box's own 3pt inset),
  // whether it came from an argument or a set rule.
  narrow("arg-auto")
  narrow("set-rule-auto")
  width_is("arg-3cm", 3cm - 6pt)
  narrow("outside")
}

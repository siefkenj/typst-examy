#import "../template.typ": *

examy is a #link("https://typst.app")[Typst] package for writing exams,
quizzes, and homework with automatically numbered questions, answer boxes,
points accounting, smart cross-references, and solutions that can be toggled
on and off. This package follows the spirit of the
#link("https://ctan.org/pkg/exam")[exam class for LaTeX].

#screenshots(
  screenshot("quiz.png", "A quiz with empty answer boxes and multiple-choice bubbles", caption: [A quiz…]),
  screenshot("quiz-solutions.png", "The same quiz compiled with solutions shown", caption: […and its answer key, from the same source.]),
)

== Installation

Start a new exam from the template, a cover page with a points table followed
by questions with answer boxes, parts, and multiple choice:

```bash
typst init @preview/examy
```

or choose examy under _Start from template_ in the Typst web app. To use
examy in a document of your own, import it:

#raw(IMPORT, lang: "typ", block: true)

== A first exam

A minimal document. Every example in these docs is rendered by examy itself
from the code shown with it, here both as the exam and as its answer key:

#example(
  ```typ
  #import "@preview/examy:1.0.0": *

  #show: e.prepare()
  #show: e.set_(config, show-solutions: false)

  // A fill-in block (Name / Student ID) at the top of the page
  #name-block()

  #exam(
    questions: [
      #question(points: 2)[
        State the definition of a _continuous function_.
        #answer-box(width: 100%, height: 1fr)[
          #solution[A function $f$ is continuous at $a$ if
            $lim_(x -> a) f(x) = f(a)$.]
        ]
      ]
      #question(points: 3)[
        Give an example of a continuous function that is not differentiable.
        #answer-box(width: 100%, height: 2fr)[
          #solution[$f(x) = |x|$, at $x = 0$.]
        ]
      ]
    ],
  )
  ```,
  height: 12cm,
)

The two `#show` lines are required: `e.prepare()` enables
#link("https://typst.app/universe/package/elembic")[elembic] elements and
references, which examy is built on, and `e.set_(config, ..)` sets the
package's options (see #page-link("configuration.html")[Configuration]).

== What's in the box

#features(
  ("questions.html", [Questions and numbering], [Questions, parts, and subparts, numbered your way, with page breaks inside them.]),
  ("points.html", [Points], [Point badges, totals, bonus points, a points table, and points per page.]),
  ("answer-boxes.html", [Answer boxes], [Boxes of a set size, or ones that share the rest of the page.]),
  ("solutions.html", [Solutions], [One source for the exam and its answer key, with the key laid out like the exam.]),
  ("choices.html", [Multiple choice], [Bubbles for "select one" and "select all that apply", lettered or not.]),
  ("cross-references.html", [Cross-references], [`@labels` that read "(a)" or "1 (a)" depending on where they are.]),
  ("cover-pages.html", [Cover pages], [A title block, name fields, and institution presets.]),
  ("configuration.html", [Configuration], [Every package option, by topic, and how to set them.]),
  ("reference.html", [Reference], [Every function and option, generated from the package itself.]),
)

== How examy works

A straightforward implementation of examy would wrap each
question/part/subpart in a box and apply an appropriate inset. Unfortunately,
`#pagebreak()` cannot work inside a box and, worse still, boxes can only
negotiate fractional units if they are peers of each other. So, the box
approach would make it impossible to have a part and a subpart both share the
remaining space on the page.

Instead, examy flattens all question/part/subpart contents and tags the start
and end of each block with `metadata`. The flat stream is then parsed,
indentation level is tracked, and peer boxes are produced, so that
`#pagebreak()` and `fr` units can negotiate space.

The downside of this parsing is that "click back" in tools like
#link("https://github.com/Myriad-Dreamin/tinymist")[tinymist] can be broken.
(Usually it works to click a sub-boxed item, like an equation.)

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

A quick-start template is available by choosing examy under _Start from
template_ in the Typst web app or in the command line by running

```bash
typst init @preview/examy
```

To use examy in a document of your own, import it:

#raw(IMPORT, lang: "typ", block: true)

== A first exam

A basic document looks like this. Every example in these docs is rendered by
examy itself from the code shown with it, here both as the exam and as its
answer key:

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
  ("questions.html", [Questions and numbering], [Questions, parts, and subparts, numbered automatically.]),
  ("points.html", [Points], [Points listed on a per-question basis as well as points tables and points per page displays.]),
  ("answer-boxes.html", [Answer boxes], [Providing a student with space to write. These can have a fixed size or can use available space via fractional units (e.g. `height: 1fr`).]),
  ("solutions.html", [Solutions], [Written solutions can be globally toggled as visible/invisible to make a key/blank versions of a test.]),
  ("choices.html", [Multiple choice], [With round or square bubbles, optionally enumerated.]),
  ("cross-references.html", [Smart cross-references], [A `@name` reference to a question will show a minimal string that uniquely identifies the question/part/subpart.]),
  ("cover-pages.html", [Cover pages], [Basic commands for creating name/exam info areas.]),
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

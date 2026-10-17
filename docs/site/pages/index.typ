#import "../template.typ": *

examy is a #link("https://typst.app")[Typst] package for writing exams,
quizzes, and homework. Questions, parts, and subparts are numbered for you;
points are added up into a points table; answer boxes stretch to fill the
page; references to other questions read naturally; and every solution is
written next to its question, so that one source gives both the exam and its
answer key. It follows the spirit of the
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

A minimal document. Every example on this site is rendered by examy itself
from the code shown beside it, here both as the exam and as its answer key:

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
package's options (see #api("config") for all of them).

== What's in the box

#html.elem("div", attrs: (class: "features"), {
  let card(path, title, text) = html.elem("a", attrs: (class: "feature", href: path), {
    html.elem("strong", title)
    html.elem("span", text)
  })
  card("questions.html", [Questions and numbering], [Questions, parts, and subparts, numbered your way, with page breaks inside them.])
  card("points.html", [Points], [Point badges, totals, bonus points, a points table, and points per page.])
  card("answer-boxes.html", [Answer boxes], [Boxes of a set size, or ones that share the rest of the page.])
  card("solutions.html", [Solutions], [One source for the exam and its answer key, with the key laid out like the exam.])
  card("choices.html", [Multiple choice], [Bubbles for "select one" and "select all that apply", lettered or not.])
  card("cross-references.html", [Cross-references], [`@labels` that read "(a)" or "1 (a)" depending on where they are.])
  card("cover-pages.html", [Cover pages], [A title block, name fields, and institution presets.])
  card("reference.html", [Reference], [Every function and option, generated from the package itself.])
})

== How examy works

A straightforward implementation would wrap each question, part, and subpart
in a box and indent it. Unfortunately, `#pagebreak()` cannot work inside a box
and, worse still, boxes can only share fractional space (`1fr`) if they are
peers of each other: a part and a subpart could not both share the space left
on a page.

Instead, examy flattens the contents of every question, part, and subpart and
marks where each starts and ends with `metadata`. The flat stream is then
parsed, the nesting tracked, and peer blocks produced, so that `#pagebreak()`
and `fr` units can negotiate space.

The downside of this parsing is that "click back" in tools like
#link("https://github.com/Myriad-Dreamin/tinymist")[tinymist] can be broken.
(Clicking an item boxed of its own, like an equation, usually works.)

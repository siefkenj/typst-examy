// A full-featured exam: cover page with a points table, questions with
// parts and subparts, fill-the-page answer boxes, cross-references,
// questions that continue across page breaks, and a bonus part.
//
// Compile:                  typst compile --root .. final-exam.typ
// Compile with solutions:   typst compile --root .. --input show-solutions=true final-exam.typ
#import "../src/lib.typ": *

#set page(paper: "us-letter", margin: (x: .75in, bottom: .75in, top: 1in))
#show: e.prepare()
#show: e.set_(config, show-solutions: false)
#show: e.set_(
  config,
  institution: [University of Examples],
  exam-name: [MAT 101 Final Exam],
  term: [Winter 2026],
  duration: duration(minutes: 150),
)

// `maketitle` renders the institution, exam name, term, and duration
// configured above.
#maketitle()

// Rows of the fill-in name block. A `(prefix: ..., suffix: ...)` entry
// draws an underline between the two; plain content is shown verbatim.
#name-block(fields: (
  (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
  (prefix: [Email address:], suffix: [`@university.edu`]),
  (prefix: [Student ID:]),
  {
    set align(center)
    text(size: .85em)[_Write legibly and darkly._]
  },
))

#underline[_Instructions:_]
- Fill out your name and student information at the top of this page.
- Answer each question in the box provided; work outside the boxes will
  not be graded.
- The back of each page may be used for scratch work.
- No calculators or other aids are permitted.

#v(1fr)
#{
  set align(center)
  points-table
}
#pagebreak()

#exam(
  questions: [
    #question(points: 3)[
      Define what it means for a sequence $(a_n)$ to _converge_ to a limit
      $L$, and use your definition to show that the sequence $a_n = 1/n$
      converges to $0$.
      #answer-box(width: 100%, height: 1fr)[
        #solution[
          $(a_n)$ converges to $L$ if for every $epsilon > 0$ there exists an
          $N in NN$ such that $|a_n - L| < epsilon$ for all $n > N$.

          For $a_n = 1/n$: fix $epsilon > 0$ and choose $N > 1/epsilon$.
          Then for all $n > N$ we have $|1/n - 0| = 1/n < 1/N < epsilon$.
        ]
      ]
    ]

    #pagebreak()

    #question[
      Let $f(x) = x^2 sin(1/x)$ for $x != 0$ and let $f(0) = 0$.
      #part(points: 2, label: <continuity>)[
        Show that $f$ is continuous at $x = 0$.
        #answer-box(width: 100%, height: 1fr)[
          #solution[
            Since $|sin(1/x)| <= 1$, we have $|f(x)| <= x^2$. As
            $x -> 0$, $x^2 -> 0$, so by the squeeze theorem
            $lim_(x -> 0) f(x) = 0 = f(0)$.
          ]
        ]
      ]
      #part(points: 3)[
        Is $f$ differentiable at $x = 0$? Justify your answer. (You may use
        your result from @continuity.)
        #answer-box(width: 100%, height: 1fr)[
          #solution[
            Yes. The difference quotient is
            $ (f(h) - f(0)) / h = h sin(1/h), $
            which tends to $0$ as $h -> 0$ (again by squeezing). Hence
            $f'(0) = 0$.
          ]
        ]
      ]
    ]

    #pagebreak()

    #question[
      Consider the series $sum_(n = 1)^oo 1/n^2$.
      #part(points: 2)[
        State the integral test for convergence of a series.
        #subpart[
          What hypotheses must the function in the integral test satisfy?
          #answer-box(width: 100%, height: 1fr)[
            #solution[
              The function must be positive, continuous, and decreasing on
              $[1, oo)$.
            ]
          ]
        ]
        #subpart[
          State the conclusion of the test.
          #answer-box(width: 100%, height: 1fr)[
            #solution[
              $sum_(n = 1)^oo f(n)$ converges if and only if
              $integral_1^oo f(x) dif x$ converges.
            ]
          ]
        ]
      ]
      #pagebreak()
      #part(points: 3)[
        Use the integral test to decide whether $sum_(n = 1)^oo 1/n^2$
        converges.
        #answer-box(width: 100%, height: 1fr)[
          #solution[
            $f(x) = 1/x^2$ is positive, continuous, and decreasing on
            $[1, oo)$, and
            $ integral_1^oo x^(-2) dif x
              = lim_(t -> oo) (1 - 1/t) = 1 < oo, $
            so the series converges.
          ]
        ]
      ]
      #part(points: 1, intent: "bonus")[
        *Bonus:* What is the exact value of $sum_(n = 1)^oo 1/n^2$?
        #answer-box(width: 100%, height: 4cm)[
          #solution[$pi^2/6$ (the Basel problem).]
        ]
      ]
    ]
  ],
)

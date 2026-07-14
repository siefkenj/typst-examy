// An exam using the University of Toronto cover-page preset: the name block
// has NAME / Email address (with the @mail.utoronto.ca suffix) / UTORid
// rows, provided by `presets.utoronto`.
//
// Compile:                  typst compile --root .. utoronto-exam.typ
// Compile with solutions:   typst compile --root .. --input show-solutions=true utoronto-exam.typ
#import "../src/lib.typ": *

#set page(paper: "us-letter", margin: (x: .75in, bottom: .75in, top: 1in))
#show: e.prepare()
#show: e.set_(config, show-solutions: false)

#exam(
  ..presets.utoronto,
  name_list: (none,),
  institution: [University of Toronto Faculty of Arts & Science],
  exam_name: [MAT244H1S Midterm],
  term: [Fall 2026],
  duration: duration(minutes: 110),
  exam_instructions: [
    #underline[_Exam Reminders:_]
    - Fill out the name, UTORid, and email address at the top of this page.
    - Do not begin writing the exam until instructed to do so.
    - Turn off and store all cell phones, smart watches, and other
      electronic devices.

    #v(1fr)
    #align(center, points-table)
  ],
  questions: [
    #question(points: 4)[
      Solve the initial value problem
      $ y' = 2 x y, quad y(0) = 3. $
      #answer-box(width: 100%, height: 1fr)[
        #solution[
          Separating variables, $(dif y)/y = 2 x dif x$, so
          $ln|y| = x^2 + C$ and $y = A e^(x^2)$. The initial condition gives
          $A = 3$, so $y = 3 e^(x^2)$.
        ]
      ]
    ]

    #pagebreak()

    #question[
      Consider the differential equation $y'' + 4 y = 0$.
      #part(points: 2)[
        Find the general solution.
        #answer-box(width: 100%, height: 1fr)[
          #solution[
            The characteristic equation $r^2 + 4 = 0$ has roots
            $r = plus.minus 2 i$, so
            $y = c_1 cos(2 x) + c_2 sin(2 x)$.
          ]
        ]
      ]
      #part(points: 2)[
        Find the solution satisfying $y(0) = 1$ and $y'(0) = 0$.
        #answer-box(width: 100%, height: 1fr)[
          #solution[
            $y(0) = c_1 = 1$ and $y'(0) = 2 c_2 = 0$, so $y = cos(2 x)$.
          ]
        ]
      ]
    ]
  ],
)

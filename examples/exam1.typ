#import "@preview/elembic:1.1.1" as e
#import "../src/lib.typ": *

#show: e.set_(config, show-solutions: true)

#show: e.prepare()

#exam(
  questions: [
    #question(points: 2, solution: [Interesting solution])[The first question.]
    #question[
      #part[
        Let me know what you think.
        #answer-box(height: 1fr)[_Your thoughts_:]
      ]
      #part(points: 3)[The second part.
        #answer-box(height: 1fr)[_Your thoughts_:]
      ]
      #part(points: 5, label: <foo>)[The third part, labelled "@foo".

        #answer-box(height: 2in, width: 100%, solution: [I know what you're thinking.])[]

        #{
          stack(
            dir: ltr,
            answer-box(height: 1in, width: 50%)[
              #solution[
                This is a solution in a box with half the width of the page.
              ]
            ],
            [foo and #solution[XXX]],
          )
        }
      ]

    ]
  ],
)

XX #(1fr + 2fr)

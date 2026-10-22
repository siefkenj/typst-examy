// expect: undoes `late`, a `config` rule before the exam that sets options read once
// An `e.revoke` inside an exam of a `config` rule before it that set an
// option the exam reads once for all its questions: it would change nothing.
#import "/src/lib.typ": *

#show: e.named("late", e.set_(config, points-position: "end"))
#show: exam
#question(points: 1)[A question.]
#[
  #show: e.revoke("late")
  #question(points: 1)[Another.]
]

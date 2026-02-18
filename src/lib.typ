// #import "elements/answer-box.typ": answer-box
#import "elements/other-answer-box.typ": other-answer-box as answer-box
// #import "elements/questions.typ": part, question, subpart
#let (part, question, subpart) = {
  import "elements/division.typ": _division
  (_division, _division, _division)
}
#import "elements/solution.typ": solution
#import "elements/exam-new.typ": exam, points_table as points-table
#import "config.typ": config
#import "reference-functions.typ": (
  num_points as num-points, num_questions as num-questions, //points_table as points-table,
)
#import "types.typ": e

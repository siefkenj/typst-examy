// expect: config: `choices-enumerate` gives 2 labels, but there are 3 choices
// An array of labels set in `config` that is too short for a list it
// reaches: the error names `config`, where the array was given.
#import "/src/lib.typ": *

#show: e.set_(config, choices-enumerate: ("x", "y"))
#choices(([Ottawa], [Toronto], [Montreal]))

// expect: choices: `enumerate` gives 2 labels, but there are 3 choices
// An array of labels with fewer labels than there are choices: an error,
// rather than a choice drawn without one.
#import "/src/lib.typ": *

#choices(enumerate: ("x", "y"), ([Ottawa], [Toronto], [Montreal]))

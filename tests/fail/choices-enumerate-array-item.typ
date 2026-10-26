// expect: `enumerate` labels must be strings or content, but label 2 is 2
// An array of labels holding something that is not a label.
#import "/src/lib.typ": *

#choices(enumerate: ("x", 2, "z"), ([Ottawa], [Toronto], [Montreal]))

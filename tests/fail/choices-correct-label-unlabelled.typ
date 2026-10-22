// expect: names a choice by its label, but these choices have none
// `correct:` naming a choice by label, of choices drawn without labels: an
// error, rather than a guess at what the label would be.
#import "/src/lib.typ": *

#choices(correct: "B", ([Ottawa], [Toronto], [Montreal]))

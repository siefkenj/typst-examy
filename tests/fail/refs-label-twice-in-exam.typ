// expect: duplicate label <twice> on two different questions/parts
// A label on two divisions of one exam is an error, references or not. Only
// a label that several exams share is allowed, and a reference to it refers
// to the division in its own exam (see tests/unit/refs-shared-labels.typ).
#import "/src/lib.typ": *

#show: exam

#question(label: <twice>)[One.]
#question(label: <twice>)[Two.]
#question[See @twice.]

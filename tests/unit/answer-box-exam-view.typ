// An answer box holding only a `context` decides whether it is blank on the
// exam by laying its body out as the exam shows it. That must hold whatever
// shows the key: `config`, and the `--input show-solutions=..` command-line
// override, which wins over `config`. tests/run.sh compiles this file with
// no input and with each value of the override.
#import "/src/lib.typ": *

#set page(width: 6in, height: auto, margin: .25in)
#set text(size: 10pt)
#show: e.prepare()

#let COLUMN = 5.5in
#let near(a, b) = calc.abs((a - b).pt()) < 0.01
#let height(b) = measure(b, width: COLUMN).height

// Shown only on the key: blank on the exam, so `default-height` tall.
#let key_only = answer-box(width: 100%)[#e.get(get => if show-solutions(get) [The answer.])]
// Shown on both: a short prompt, so as tall as the prompt.
#let prompt = answer-box(width: 100%)[#context [A short prompt.]]
#let plain = answer-box(width: 100%)[A short prompt.]

#for key in (false, true) {
  show: e.set_(config, show-solutions: key)
  key_only
  prompt
  context {
    let mode = "show-solutions " + repr(key) + ", --input " + repr(sys.inputs.at("show-solutions", default: none))
    assert(
      near(height(key_only), 2cm),
      message: mode + ": a box showing a `context` only on the key should be 2cm, got " + repr(height(key_only)),
    )
    assert(
      near(height(prompt), height(plain)),
      message: mode + ": a box showing a `context` prompt should fit it, got " + repr(height(prompt)),
    )
  }
}

// `strings` takes every `config` option that draws words, a `..-format`,
// as an author easily puts one there (`strings: (points-format: ..)`); it
// is not documented. So that a `..-format` added to `config` later is not
// forgotten here, each is found by its name, and must be:
// - listed in `_STRINGS_FORMATS`, which `strings`' type accepts;
// - accepted by `strings`' type, as a function, and kept as it is;
// - used by the exam (`exam_options`) when the option itself is not set,
//   and not when it is: the option wins.
#import "/src/lib.typ": config, e
#import "/src/config.typ": _STRINGS_FORMATS, exam_options
#import "/tests/record.typ": cases, rule

#set page(width: 14cm, height: auto, margin: 1cm)
#set text(size: 10pt)

#let FIELDS = e.data(config).at("user-fields")

/// Every `..-format` option of `config`.
#let FORMATS = FIELDS.keys().filter(k => k.ends-with("-format"))
#assert(FORMATS.len() > 0)

/// `config`'s options with nothing set, as `get(config)` gives them.
#let DEFAULTS = FIELDS.values().filter(f => not f.required).map(f => (f.name, f.default)).to-dict()

// --- every `..-format` is listed ---
#for name in FORMATS {
  assert(name in _STRINGS_FORMATS, message: "`" + name + "` is a `..-format` option: add it to `_STRINGS_FORMATS`, and use it in `exam_options`")
}
#for name in _STRINGS_FORMATS {
  assert(name in FORMATS, message: "`_STRINGS_FORMATS` lists `" + name + "`, which is not a `..-format` option of `config`")
}

/// The functions the checks put in `strings`, and give as the option.
#let IN_STRINGS = p => [in strings]
#let OWN = p => [own]

#rule[Each `..-format` option of `config`, put in `strings`: taken, used by the exam, and beaten by the option itself.]
#context {
  let opts(cfg) = exam_options(_ => cfg)
  let results = FORMATS.map(name => {
    let strings = DEFAULTS.strings + ((name): IN_STRINGS)
    let (taken, cast) = e.types.cast(strings, FIELDS.strings.typeinfo)
    (
      name: name,
      taken: taken and cast.at(name, default: none) == IN_STRINGS,
      used: opts(DEFAULTS + (strings: strings)).at(name, default: none) == IN_STRINGS,
      wins: opts(DEFAULTS + (strings: strings, (name): OWN)).at(name, default: none) == OWN,
    )
  })
  cases(
    ([Option], [Taken by `strings`], [Used from `strings`], [The option wins]),
    ..results.map(r => (raw(r.name), [#r.taken], [#r.used], [#r.wins])),
  )
  for r in results {
    assert(r.taken, message: "`strings` does not take `" + r.name + "`: add it to `_STRINGS_FORMATS`")
    assert(r.used, message: "the exam does not use `" + r.name + "` from `strings`: see `exam_options`")
    assert(r.wins, message: "`" + r.name + "` given as an option should win over `strings`")
  }
}

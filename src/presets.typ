/// Ready-made argument sets for `exam` for specific institutions.
/// Spread one into an exam call:
///
/// ```typst
/// #exam(..presets.utoronto, questions: [...])
/// ```
#let presets = (
  utoronto: (
    name_fields: (
      (prefix: [#text(size: .85em)[(Given then Family)] \ NAME:]),
      (prefix: [Email address:], suffix: [`@mail.utoronto.ca`]),
      (prefix: [UTORid:]),
    ),
  ),
)

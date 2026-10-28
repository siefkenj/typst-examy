#import "../template.typ": IMPORT, api, default-badge, note, reference_index

To import all examy functions, use

#raw(IMPORT, lang: "typ", block: true)

A complete list is documented below.

The default value of each argument is shown in a blue box (e.g. #default-badge("false")). Many
arguments take their default from the global #api("config"). Their box also shows a gear and the
name of the `config` option they inherit from (e.g. #default-badge("auto", option: "bubble-size")).
Setting such an argument to `auto` uses the value of that `config` option, so changing the option
changes the default everywhere.

#note[_Note_. Many arguments on individual elements can be set on the global #api("config") instead
  of specifying them on the element.]

#reference_index()

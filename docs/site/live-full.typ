// The whole document of an example, for the live editor (live.ts): the
// edited code, in /example.typ, as `full_source` in render.typ writes it,
// exposed as `#metadata(..) <full-source>` for typst.ts to query. The site's
// build writes the same for the code as it stands (see `example` in
// template.typ), so the two agree.

#import "render.typ": full_source

#let input(name, default) = eval(sys.inputs.at(name, default: default))

#metadata(full_source(
  read("/example.typ"),
  toml("/typst.toml").package.version,
  wrap: input("wrap", "auto"),
)) <full-source>

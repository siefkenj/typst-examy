// The README's index of the package's exports, as a Markdown string, exposed
// via `#metadata(..) <api>` so that make_docs.sh can extract it with
// `typst eval` and splice it into README.md. The full reference, with every
// argument, is on the documentation site (see site.typ); this lists each
// export once, with its one-line summary and a link to its entry there.
//
// Everything comes from api.typ, which reads the elembic declarations and
// function specs, so nothing here repeats a name, a type, or a description.

#import "api.typ": ENTRIES, IMPORT, alias_code, entry, page_path, summary

#let HOMEPAGE = toml("/typst.toml").package.homepage

/// The site's page for an export. A group, such as `question`/`part`/
/// `subpart`, shares one, with an anchor for each name after the first (see
/// `entry_page` in site/template.typ).
#let link_to(name) = {
  let x = entry(name)
  HOMEPAGE + page_path(x) + if name != x.names.first() { "#api-" + name } else { "" }
}

/// One table row: the export's names, each linked, and what it is.
#let row(entry) = {
  let names = entry.names.map(n => "[`" + n + "`](" + link_to(n) + ")").join(", ")
  let what = if entry.kind == "alias" {
    summary(entry.desc) + " Same as `" + alias_code(entry) + "`."
  } else {
    summary(entry.desc)
  }
  "| " + names + " | " + what.replace("|", "\\|") + " |"
}

#let md = (
  (
    "All names below are exported by `" + IMPORT + "`. "
      + "See the [full reference](" + HOMEPAGE + "reference.html) for every argument.",
    "",
    "| Export | |",
    "| --- | --- |",
  )
    + ENTRIES.map(row)
).join("\n")

#metadata(md) <api>

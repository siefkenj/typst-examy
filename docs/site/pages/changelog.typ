#import "../template.typ": *

// The changelog, from CHANGELOG.md, so that it is written once. Only the
// Markdown that file uses is read: `##` headings for the versions, `###`
// for the kinds of change in one (Breaking changes, Added, ..), `- ` items
// (their further lines indented), paragraphs, and, inline, `code`,
// **bold**, and <https://..> links. Its `# Changelog` title is the page's.

/// A line of Markdown text as content.
#let _inline(s) = {
  let out = ()
  let pos = 0
  for m in s.matches(regex("`([^`]+)`|\*\*(.+?)\*\*|<(https?://[^>]+)>")) {
    if m.start > pos { out.push([#s.slice(pos, m.start)]) }
    let (code, bold, url) = m.captures
    out.push(if code != none { raw(code, lang: markdown_code_lang(code)) } else if bold != none {
      strong(_inline(bold))
    } else { link(url) })
    pos = m.end
  }
  out.push([#s.slice(pos)])
  out.join()
}

/// The blocks of a Markdown text: `(kind: "heading" | "item" | "par", text)`,
/// each item's or paragraph's lines joined, and a heading's `level` (2 for
/// `##`).
#let _blocks(md) = {
  let out = ()
  for line in md.split("\n") {
    if line.trim() == "" {
      out.push((kind: "blank"))
    } else if line.starts-with("### ") {
      out.push((kind: "heading", level: 3, text: line.slice(4).trim()))
    } else if line.starts-with("## ") {
      out.push((kind: "heading", level: 2, text: line.slice(3).trim()))
    } else if line.starts-with("# ") {
      // The page's own title.
    } else if line.starts-with("- ") {
      out.push((kind: "item", text: line.slice(2).trim()))
    } else if out.len() > 0 and out.last().kind in ("item", "par") {
      out.last().text += " " + line.trim()
    } else {
      out.push((kind: "par", text: line.trim()))
    }
  }
  out.filter(b => b.kind != "blank")
}

#let _changelog(md) = {
  let items = ()
  for b in _blocks(md) + ((kind: "end"),) {
    if b.kind == "item" {
      items.push(_inline(b.text))
      continue
    }
    if items.len() > 0 { list(..items) }
    items = ()
    if b.kind == "heading" { heading(level: b.level, _inline(b.text)) } else if b.kind == "par" {
      par(_inline(b.text))
    }
  }
}

What has changed in each version of examy, newest first. Before updating, read the version's
breaking changes: they can make an exam written for an earlier version look different or fail to
compile.

#_changelog(read("/CHANGELOG.md"))

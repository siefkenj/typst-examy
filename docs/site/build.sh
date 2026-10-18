#!/usr/bin/env bash
# Build the documentation site's pages into _site/ (or the directory given,
# relative to the repository's root). `npm run build` runs this, then adds the
# live editor (live.ts, bundled by Vite); `npm run dev` serves the site and
# rebuilds it on change.
#
# docs/site.typ is compiled with Typst's bundle and HTML export, which are
# experimental, into a static site: the guide pages, the reference
# (generated from the package's own declarations, see docs/api.typ), the
# stylesheet, and the screenshots. Every example on it is rendered by the
# package from the code it shows. The same pages are also compiled into one
# PDF (docs/manual.typ), published beside them as examy-manual.pdf. Open
# _site/index.html to view it, or, after `npm run build`, serve it with
# `npm run preview`.
set -euo pipefail
# From the repository's root, two levels up.
cd "$(dirname "$0")/../.."

out="${1:-_site}"
rm -rf "$out"
# The package's files, for the live editor (see docs/site.typ).
live_files=$(find src -name '*.typ' | sort | paste -sd, -)
typst compile --root . --features bundle,html -f bundle --input "live-files=$live_files" docs/site.typ "$out" 2>&1 \
    | grep -v -e 'warning: bundle export is experimental' -e 'warning: html export is experimental' \
        -e 'hint: its behaviour may change at any time' -e 'hint: do not rely on this feature for production use cases' -e '^$' \
    || true
[ -f "$out/index.html" ] || { echo "error: the site did not build" >&2; exit 1; }
# The PDF the pages link to (see MANUAL_PDF in docs/site/template.typ).
typst compile --root . docs/manual.typ "$out/examy-manual.pdf"
echo "Built the documentation site in $out/ ($(find "$out" -type f | wc -l) files)"

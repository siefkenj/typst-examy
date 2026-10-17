#!/usr/bin/env bash
# Build the documentation site's pages into _site/ (or the directory given).
# `npm run build` runs this, then adds the live editor (docs/site/live.ts,
# bundled by Vite); `npm run dev` serves the site and rebuilds it on change.
#
# docs/site.typ is compiled with Typst's bundle and HTML export, which are
# experimental, into a static site: the guide pages, the reference
# (generated from the package's own declarations, see docs/api.typ), the
# stylesheet, and the screenshots. Every example on it is rendered by the
# package from the code it shows. Open _site/index.html to view it, or, after
# `npm run build`, serve it with `npm run preview`.
set -euo pipefail
cd "$(dirname "$0")"

out="${1:-_site}"
rm -rf "$out"
# The package's files, for the live editor (see docs/site.typ).
live_files=$(find src -name '*.typ' | sort | paste -sd, -)
typst compile --root . --features bundle,html -f bundle --input "live-files=$live_files" docs/site.typ "$out" 2>&1 \
    | grep -v -e 'warning: bundle export is experimental' -e 'warning: html export is experimental' \
        -e 'hint: its behaviour may change at any time' -e 'hint: do not rely on this feature for production use cases' -e '^$' \
    || true
[ -f "$out/index.html" ] || { echo "error: the site did not build" >&2; exit 1; }
echo "Built the documentation site in $out/ ($(find "$out" -type f | wc -l) files)"

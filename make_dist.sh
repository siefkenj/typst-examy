#!/usr/bin/env bash
# Build a clean, up-to-date distribution of the examy package in
# dist/examy/<version>/ — the folder that gets copied into the
# typst/packages repository (under packages/preview/) to publish
# @preview/examy. To import the vendored package locally, point
# TYPST_PACKAGE_PATH at a directory whose `preview/` entry links to dist/
# (see the validation step below).
#
# Steps:
#   1. run the test suite
#   2. compile every example (with and without solutions) as validation
#   3. regenerate the README screenshots from the examples
#   4. assemble the package; example imports are rewritten from the local
#      `../src/lib.typ` to `@preview/examy:<version>`
#   5. compile the packaged examples against the vendored package
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep -m1 '^version' typst.toml | sed 's/.*"\(.*\)"/\1/')
PKG="dist/examy/$VERSION"
echo "==> examy $VERSION"

echo "==> Running tests"
./tests/run.sh

echo "==> Compiling examples"
for f in examples/*.typ; do
    # bundle.typ constructs `document` elements, which only the bundle
    # target supports; it is compiled separately below.
    case "$f" in *bundle*) continue ;; esac
    typst compile --root . -f pdf "$f" /dev/null
    typst compile --root . -f pdf --input show-solutions=true "$f" /dev/null
done
bundletmp=$(mktemp -d)
typst compile --root . --features bundle -f bundle examples/bundle.typ "$bundletmp"
rm -rf "$bundletmp"

echo "==> Regenerating API.md"
./make_docs.sh

echo "==> Rendering README screenshots"
# Student-version screenshots pass `--input show-solutions=false` explicitly
# so they stay solution-free no matter what the example file's own
# `show-solutions` config says.
typst compile --root . -f png --ppi 110 --pages 1 --input show-solutions=false examples/final-exam.typ examples/images/cover.png
typst compile --root . -f png --ppi 110 --pages 3 --input show-solutions=false examples/final-exam.typ examples/images/question-page.png
typst compile --root . -f png --ppi 110 --input show-solutions=false examples/quiz.typ examples/images/quiz.png
typst compile --root . -f png --ppi 110 --input show-solutions=true examples/quiz.typ examples/images/quiz-solutions.png
typst compile --root . -f png --ppi 140 examples/numbering.typ examples/images/numbering.png
typst compile --root . -f png --ppi 140 examples/points.typ examples/images/points.png
typst compile --root . -f png --ppi 140 --input show-solutions=false examples/solutions.typ examples/images/solutions.png
typst compile --root . -f png --ppi 140 --input show-solutions=true examples/solutions.typ examples/images/solutions-key.png
typst compile --root . -f png --ppi 140 examples/cross-references.typ examples/images/cross-references.png
typst compile --root . -f png --ppi 140 examples/name-blocks.typ examples/images/name-blocks.png

echo "==> Assembling $PKG/"
rm -rf dist
mkdir -p "$PKG/examples/images"
cp typst.toml LICENSE API.md "$PKG/"
# The published README keeps user documentation only: strip the Development
# section (everything from "## Development" up to the next "## " heading).
awk '/^## Development$/ { skip = 1; next } skip && /^## / { skip = 0 } !skip' \
    README.md >"$PKG/README.md"
cp -r src "$PKG/src"
cp examples/images/*.png "$PKG/examples/images/"
for f in examples/*.typ; do
    # Published examples import the package instead of the local sources.
    sed -e "s|#import \"../src/lib.typ\": \*|#import \"@preview/examy:$VERSION\": *|" \
        -e "s|typst compile --root \.\. |typst compile |g" \
        "$f" >"$PKG/examples/$(basename "$f")"
done

echo "==> Validating the vendored package as @preview/examy:$VERSION"
# Typst resolves `@preview/...` from `$TYPST_PACKAGE_PATH/preview/...`, so
# expose dist/ under a `preview` symlink and compile the packaged examples
# against it — exactly how users will consume the package.
pkgroot=$(mktemp -d)
trap 'rm -rf "$pkgroot"' EXIT
ln -s "$PWD/dist" "$pkgroot/preview"
for f in "$PKG"/examples/*.typ; do
    case "$f" in *bundle*) continue ;; esac
    TYPST_PACKAGE_PATH="$pkgroot" typst compile -f pdf "$f" /dev/null
    TYPST_PACKAGE_PATH="$pkgroot" typst compile -f pdf --input show-solutions=true "$f" /dev/null
done
bundletmp=$(mktemp -d)
TYPST_PACKAGE_PATH="$pkgroot" typst compile --features bundle -f bundle "$PKG/examples/bundle.typ" "$bundletmp"
rm -rf "$bundletmp"

echo "==> Done: $PKG/ ($(du -sh dist | cut -f1))"
find dist -type f | sort

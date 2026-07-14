#!/usr/bin/env bash
# Build a clean, up-to-date distribution of the examy package in
# dist/examy/<version>/ — the folder that gets copied into the
# typst/packages repository (under packages/preview/) to publish
# @preview/examy. To import the vendored package locally, point
# TYPST_PACKAGE_PATH at a directory whose `preview/` entry links to dist/
# (see the validation step below).
#
# Usage:
#   ./make_dist.sh --tag=<TAG>   e.g. ./make_dist.sh --tag=v0.2.0
#   ./make_dist.sh --no-tag
#
# Steps:
#   1. run the test suite
#   2. compile every example (with and without solutions) as validation
#   3. regenerate the README screenshots from the examples
#   4. assemble the package (typst.toml, LICENSE, README.md, src/ — no
#      examples/, matching `exclude` in typst.toml); the README's relative
#      links/images (which only work when browsing this repo on GitHub) are
#      rewritten to absolute permalinks against `repository` in typst.toml,
#      pinned at --tag/--no-tag (see below), so the published README is
#      portable to Typst Universe / typst/packages
#   5. compile the examples (import rewritten to `@preview/examy:<version>`
#      in a scratch copy — they aren't part of the published package) against
#      the vendored package, to validate it works as advertised
set -euo pipefail
cd "$(dirname "$0")"

usage() {
    cat >&2 <<'EOF'
usage: ./make_dist.sh (--tag=<TAG> | --no-tag)

This script rewrites README.md's repo-relative links (example files,
screenshots) into absolute GitHub permalinks, since the published package
does not ship the examples/ directory itself. A permalink must be pinned to
something — a release tag or a commit — so you must say which:

  --tag=<TAG>   Pin the links to the given git tag, e.g. --tag=v0.2.0. Use
                this for an actual release: create and push the tag first
                    git tag v0.2.0 && git push origin v0.2.0
                then pass that same tag here, so the published README reads
                nicely and links stay valid for that release forever.

  --no-tag      Pin the links to the current commit (git rev-parse HEAD)
                instead of a tag. Use this for a local/test build of dist/
                when you don't want to create a release tag yet.

Exactly one of these is required — there is no default, because silently
falling back to one could point a real release at an untagged commit, or
force a test build to fail for lacking a tag.
EOF
}

TAG_MODE=""
RELEASE_TAG=""
for arg in "$@"; do
    case "$arg" in
        --tag=*)
            TAG_MODE="tag"
            RELEASE_TAG="${arg#--tag=}"
            ;;
        --no-tag)
            TAG_MODE="no-tag"
            ;;
        *)
            echo "error: unknown argument '$arg'" >&2
            echo >&2
            usage
            exit 1
            ;;
    esac
done
if [ -z "$TAG_MODE" ]; then
    echo "error: --tag=<TAG> or --no-tag is required" >&2
    echo >&2
    usage
    exit 1
fi
if [ "$TAG_MODE" = "tag" ] && [ -z "$RELEASE_TAG" ]; then
    echo "error: --tag= was given an empty tag name" >&2
    echo >&2
    usage
    exit 1
fi

VERSION=$(grep -m1 '^version' typst.toml | sed 's/.*"\(.*\)"/\1/')
PKG="dist/examy/$VERSION"
echo "==> examy $VERSION"

# Base URLs for rewriting the README's repo-relative links (see step 4).
# Pinned to a permalink (a tag or a commit, never a branch name), so the
# links keep pointing at the exact files this version of the package
# shipped with — the typst/packages checker flags branch-relative links
# ("GitHub URL links to default branch") and recommends this instead.
REPO_URL=$(grep -m1 '^repository' typst.toml | sed 's/.*"\(.*\)"/\1/')
if [ "$TAG_MODE" = "tag" ]; then
    if ! git rev-parse --verify --quiet "refs/tags/$RELEASE_TAG" >/dev/null; then
        echo "error: git tag '$RELEASE_TAG' does not exist in this repository." >&2
        echo >&2
        echo "  --tag=$RELEASE_TAG was given, but that tag hasn't been created." >&2
        echo "  Create and push it first:" >&2
        echo >&2
        echo "    git tag $RELEASE_TAG" >&2
        echo "    git push origin $RELEASE_TAG" >&2
        echo >&2
        echo "  ...then re-run this script." >&2
        exit 1
    fi
    GITHUB_REF="$RELEASE_TAG"
    if [ "$(git rev-parse "$RELEASE_TAG")" != "$(git rev-parse HEAD)" ]; then
        echo "warning: tag '$RELEASE_TAG' does not point at the current commit (HEAD)." >&2
        echo "         The README will link to tag '$RELEASE_TAG', but the examples and" >&2
        echo "         screenshots used to build this dist/ come from the current" >&2
        echo "         working tree, which may not match what that tag contains." >&2
    fi
else
    GITHUB_REF=$(git rev-parse HEAD)
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "warning: working tree has uncommitted changes; README links will point at" >&2
    echo "         $GITHUB_REF, which may not match what's on GitHub yet." >&2
    echo "         Commit and push before running this for a release." >&2
fi
BLOB_BASE="$REPO_URL/blob/$GITHUB_REF"
TREE_BASE="$REPO_URL/tree/$GITHUB_REF"
RAW_BASE="https://raw.githubusercontent.com/${REPO_URL#https://github.com/}/$GITHUB_REF"

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

echo "==> Regenerating the API reference in README.md"
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
mkdir -p "$PKG"
cp typst.toml LICENSE "$PKG/"
# The published README keeps user documentation only: strip the Development
# section (everything from "## Development" up to the next "## " heading).
# Then rewrite repo-relative links so the README is portable outside GitHub:
# markdown links `](path)` and `<a href="path">` become blob links (or tree
# links for directory paths ending in `/`), and `<img src="path">` becomes a
# raw.githubusercontent.com link. Absolute (`http...`), anchor (`#...`), and
# `mailto:` targets are left untouched.
awk '/^## Development$/ { skip = 1; next } skip && /^## / { skip = 0 } !skip' \
    README.md \
    | BLOB_BASE="$BLOB_BASE" TREE_BASE="$TREE_BASE" RAW_BASE="$RAW_BASE" perl -pe '
        s{\]\(([^)]+)\)}{
            my $p = $1;
            $p =~ m{^(?:https?:|#|mailto:)} ? "](" . $p . ")"
            : $p =~ m{/$} ? "](" . $ENV{TREE_BASE} . "/" . $p . ")"
            : "](" . $ENV{BLOB_BASE} . "/" . $p . ")"
        }ge;
        s{(<img\b[^>]*\bsrc=")([^"]+)(")}{
            $2 =~ m{^https?:} ? "$1$2$3" : "$1" . $ENV{RAW_BASE} . "/$2" . "$3"
        }ge;
        s{(<a\b[^>]*\bhref=")([^"]+)(")}{
            $2 =~ m{^https?:} ? "$1$2$3" : "$1" . $ENV{BLOB_BASE} . "/$2" . "$3"
        }ge;
    ' >"$PKG/README.md"
cp -r src "$PKG/src"

echo "==> Validating the vendored package as @preview/examy:$VERSION"
# Typst resolves `@preview/...` from `$TYPST_PACKAGE_PATH/preview/...`, so
# expose dist/ under a `preview` symlink and compile the examples against it
# — exactly how users will consume the package. The examples aren't part of
# the published package (see step 4); a scratch copy with the import
# rewritten to `@preview/examy:<version>` is used here only for validation.
pkgroot=$(mktemp -d)
trap 'rm -rf "$pkgroot"' EXIT
ln -s "$PWD/dist" "$pkgroot/preview"
validation_examples=$(mktemp -d)
for f in examples/*.typ; do
    sed "s|#import \"../src/lib.typ\": \*|#import \"@preview/examy:$VERSION\": *|" \
        "$f" >"$validation_examples/$(basename "$f")"
done
for f in "$validation_examples"/*.typ; do
    case "$f" in *bundle*) continue ;; esac
    TYPST_PACKAGE_PATH="$pkgroot" typst compile -f pdf "$f" /dev/null
    TYPST_PACKAGE_PATH="$pkgroot" typst compile -f pdf --input show-solutions=true "$f" /dev/null
done
bundletmp=$(mktemp -d)
TYPST_PACKAGE_PATH="$pkgroot" typst compile --features bundle -f bundle "$validation_examples/bundle.typ" "$bundletmp"
rm -rf "$bundletmp" "$validation_examples"

echo "==> Done: $PKG/ ($(du -sh dist | cut -f1))"
find dist -type f | sort

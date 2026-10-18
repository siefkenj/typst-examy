#!/usr/bin/env bash
# Regenerate the Basic API Reference inside README.md.
#
# docs/readme-api.typ builds it as a Markdown string — its hand-picked rows,
# with each export's link and signature from the package's own declarations
# (see docs/api.typ) — and exposes it as `#metadata(..) <api>`. This script extracts it with
# `typst eval`, JSON-decodes the result, and splices it into README.md
# between the `API-DOCS-START`/`API-DOCS-END` markers. The full reference is
# on the documentation site (see docs/site/build.sh).
set -euo pipefail
cd "$(dirname "$0")"

api_tmp=$(mktemp)
trap 'rm -f "$api_tmp"' EXIT

typst eval 'query(<api>).first().value' --in docs/readme-api.typ --root . \
    | perl -MJSON::PP -0777 -ne 'print JSON::PP->new->decode($_)' \
    >"$api_tmp"

API_FILE="$api_tmp" perl -0pi -e '
    BEGIN {
        local $/;
        open my $f, "<", $ENV{API_FILE} or die $!;
        $api = <$f>;
    }
    s/(<!-- API-DOCS-START[^\n]*-->\n).*?(<!-- API-DOCS-END -->)/$1$api\n$2/s
        or die "API-DOCS-START\/END markers not found in README.md\n";
' README.md

echo "Updated the API index in README.md ($(wc -l <"$api_tmp") lines)"

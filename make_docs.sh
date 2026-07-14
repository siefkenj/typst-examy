#!/usr/bin/env bash
# Regenerate the API reference inside README.md.
#
# docs/generate-api.typ builds the reference as a Markdown string —
# introspecting the elembic element declarations for their docs, argument
# types, defaults, and required flags — and exposes it as
# `#metadata(..) <api>`. This script extracts it with `typst eval`,
# JSON-decodes the result, and splices it into README.md between the
# `API-DOCS-START`/`API-DOCS-END` markers.
set -euo pipefail
cd "$(dirname "$0")"

api_tmp=$(mktemp)
trap 'rm -f "$api_tmp"' EXIT

typst eval 'query(<api>).first().value' --in docs/generate-api.typ --root . \
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

echo "Updated the API reference in README.md ($(wc -l <"$api_tmp") lines)"

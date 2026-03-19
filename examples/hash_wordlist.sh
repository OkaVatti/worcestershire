#!/usr/bin/env bash
# examples/hash_wordlist.sh
#
# Demonstrates all eight encoding and hashing modes supported by
# worcestershire.  For each mode a small wordlist is generated and the
# first three lines of output are printed so the transformation is visible.
#
# Modes:
#   base64, base32, url, hex, md5, sha1, sha256, sha512
#
# Usage:
#   bash examples/hash_wordlist.sh

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"
WORDS="password admin letmein"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

run_encoding() {
	local mode="$1"
	local out="encoded_${mode}.lst"

	printf '%-10s -> ' "$mode"

	"$BIN" \
		--words "$WORDS" \
		--encode "$mode" \
		--output "$out" \
		--force \
		--quiet

	# Show the first three output lines on one line for readability.
	head -3 "$out" | paste -sd '  |  ' -
}

echo "==> Encoding modes comparison"
echo "    Input words: $WORDS"
echo ""
printf '%-10s    %-s\n' "Mode" "First 3 encoded entries"
printf '%-10s    %-s\n' "----------" "------------------------------------"

for mode in base64 base32 url hex md5 sha1 sha256 sha512; do
	run_encoding "$mode"
done

echo ""
echo "==> Individual output files: encoded_<mode>.lst"

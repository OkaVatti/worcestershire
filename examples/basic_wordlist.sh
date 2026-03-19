#!/usr/bin/env bash
# examples/basic_wordlist.sh
#
# Demonstrates the simplest possible worcestershire run:
# take two words, apply Word Mix (type 1) and Case Alternate (type 2),
# and write the result to a plain-text file.
#
# Expected output file: basic.lst
# Expected entry count: varies based on word length but is small enough
#                       to inspect by eye.
#
# Usage:
#   bash examples/basic_wordlist.sh

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

OUTPUT="basic.lst"

echo "==> Generating basic wordlist ..."
"$BIN" \
	--words "pass word" \
	--combination "1 2" \
	--depth 2 \
	--min 4 \
	--max 20 \
	--output "$OUTPUT" \
	--force

LINE_COUNT=$(wc -l <"$OUTPUT")
echo "==> Done. $LINE_COUNT lines written to $OUTPUT."
echo ""
echo "First 20 entries:"
head -20 "$OUTPUT"

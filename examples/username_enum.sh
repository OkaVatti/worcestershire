#!/usr/bin/env bash
# examples/username_enum.sh
#
# Generates username variations suitable for enumeration or brute-force
# testing of authentication endpoints.
#
# Applied combination types:
#   2 - Case Alternate  (Admin, ADMIN, admin, aDmIn, ...)
#   4 - Reverser        (nimda)
#   7 - Separator Insert (first-last, first_last, first.last)
#
# The username-enum preset caps output at 1,000,000 entries and keeps
# word length between 4 and 20 characters.
#
# Usage:
#   bash examples/username_enum.sh [INPUT_FILE]
#
# Arguments:
#   INPUT_FILE  Path to a file of base usernames/names, one per line.
#               Default: names.txt

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"
INPUT="${1:-names.txt}"
OUTPUT="usernames.lst"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

if [[ ! -f "$INPUT" ]]; then
	echo "Input file '$INPUT' not found. Creating a sample file ..." >&2
	printf 'alice\nbob\ncharlie\nadmin\nroot\n' >"$INPUT"
	echo "Created $INPUT with sample entries."
fi

echo "==> Generating username variations from $INPUT ..."
"$BIN" \
	--input "$INPUT" \
	--preset username-enum \
	--output "$OUTPUT" \
	--force

LINE_COUNT=$(wc -l <"$OUTPUT")
echo "==> Done. $LINE_COUNT usernames written to $OUTPUT."
echo ""
echo "Sample entries (first 30):"
head -30 "$OUTPUT"

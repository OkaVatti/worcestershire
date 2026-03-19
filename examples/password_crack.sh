#!/usr/bin/env bash
# examples/password_cracking.sh
#
# Full offline-cracking pipeline using the password-cracking preset.
#
# Steps:
#   1. Build the wordlist using the preset (all 8 combination types,
#      depth 4, length 8-32, gzip-compressed, 10M combination limit).
#   2. (Optional) Pipe the compressed list directly into hashcat via
#      process substitution if HASH_FILE is set.
#
# Usage:
#   bash examples/password_cracking.sh [HASH_FILE]
#
# Arguments:
#   HASH_FILE  (optional) Path to a file of hashes to crack.
#              If provided, hashcat is invoked automatically.

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"
HASH_FILE="${1:-}"
INPUT="${INPUT:-words.txt}"
OUTPUT="crack.lst.gz"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

if [[ ! -f "$INPUT" ]]; then
	echo "Input file '$INPUT' not found." >&2
	echo "Set INPUT=/path/to/your/words.txt or create words.txt in the" >&2
	echo "current directory, then re-run." >&2
	exit 1
fi

echo "==> Generating cracking wordlist from $INPUT ..."
"$BIN" \
	--input "$INPUT" \
	--preset password-cracking \
	--output "$OUTPUT" \
	--force \
	--log-level info

echo "==> Wordlist written to $OUTPUT."

if [[ -n "$HASH_FILE" ]]; then
	if ! command -v hashcat >/dev/null 2>&1; then
		echo "hashcat not found in PATH; skipping crack step." >&2
		exit 0
	fi
	echo "==> Launching hashcat ..."
	# -a 0  = dictionary attack
	# -m 0  = MD5 (change to match your hash type)
	# Pass the gzip file; hashcat decompresses it automatically.
	hashcat -a 0 -m 0 "$HASH_FILE" "$OUTPUT"
fi

#!/usr/bin/env bash
# examples/with_rules.sh
#
# Demonstrates the JTR-style rule engine.
#
# Supported rule commands:
#   l   lowercase the word
#   u   uppercase the word
#   c   capitalise (first char upper, rest lower)
#   r   reverse the word
#   d   duplicate the word (passpass)
#   $   append !
#   ^   prepend !
#
# Each line in the rule file is one independent rule.  A rule may combine
# multiple commands: "lr" lowercases then reverses.  The original word is
# always included in the output alongside all rule-derived variants.
#
# Usage:
#   bash examples/with_rules.sh [INPUT_FILE]

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"
INPUT="${1:-words.txt}"
OUTPUT="rules_output.lst"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

if [[ ! -f "$INPUT" ]]; then
	echo "Input file '$INPUT' not found. Creating a sample file ..." >&2
	printf 'Password\nSecurity\nSecret\n' >"$INPUT"
	echo "Created $INPUT."
fi

# ---------------------------------------------------------------------------
# Write a rule file demonstrating each supported command.
# ---------------------------------------------------------------------------

RULE_FILE=$(mktemp /tmp/wor_rules.XXXXXX)

cat >"$RULE_FILE" <<'EOF'
# Lowercase
l
# Uppercase
u
# Capitalise
c
# Reverse
r
# Lowercase then reverse
lr
# Duplicate
d
# Append !
$
# Prepend !
^
# Uppercase then append !
u$
EOF

cleanup() { rm -f "$RULE_FILE"; }
trap cleanup EXIT

echo "==> Rule file contents:"
grep -v '^#' "$RULE_FILE" | grep -v '^$' | nl -ba
echo ""

echo "==> Running worcestershire with rules ..."
"$BIN" \
	--input "$INPUT" \
	--rules "$RULE_FILE" \
	--output "$OUTPUT" \
	--force \
	--quiet

LINE_COUNT=$(wc -l <"$OUTPUT")
echo "==> Done. $LINE_COUNT lines written to $OUTPUT."
echo ""

echo "Transformation samples:"
echo "  Original  ->  Derived"
echo "  --------      -------"
# Print original and up to 9 derived forms side by side for the first word.
FIRST_WORD=$(head -1 "$INPUT")
grep -i "^${FIRST_WORD}" "$OUTPUT" | head -10 | while read -r line; do
	printf '  %-12s  %s\n' "$FIRST_WORD" "$line"
done

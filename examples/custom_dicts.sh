#!/usr/bin/env bash
# examples/custom_dicts.sh
#
# Demonstrates overriding all four built-in dictionaries with custom files:
#
#   --homograph-dict  Character look-alike substitutions (for type 3)
#   --leet-dict       Leet-speak substitutions (for type 6)
#   --salt-dict       Prefix/suffix salts (for type 5)
#   --affix-dict      Affix values (for type 8)
#
# This is useful when targeting a specific character set, language, or
# when you want to reduce output size by narrowing the substitution space.
#
# Usage:
#   bash examples/custom_dicts.sh

set -euo pipefail

BIN="${BIN:-bin/worcestershire}"
OUTPUT="custom_dict.lst"
WORDS="secret"

if [[ ! -x "$BIN" ]]; then
	echo "Binary not found at $BIN. Run 'shards build --release' first." >&2
	exit 1
fi

# ---------------------------------------------------------------------------
# Write temporary custom dictionaries.
# ---------------------------------------------------------------------------

HOMOGRAPH_FILE=$(mktemp /tmp/homograph.XXXXXX)
LEET_FILE=$(mktemp /tmp/leet.XXXXXX)
SALT_FILE=$(mktemp /tmp/salt.XXXXXX)
AFFIX_FILE=$(mktemp /tmp/affix.XXXXXX)

# Homograph: only substitute 'e' and 's'.
cat >"$HOMOGRAPH_FILE" <<'EOF'
e->3,€
s->$,5
EOF

# Leet: only 'e', 'o', 'a'.
cat >"$LEET_FILE" <<'EOF'
e->3
o->0
a->@,4
EOF

# Salts: a short, targeted list.
cat >"$SALT_FILE" <<'EOF'
!
2024
123
EOF

# Affixes: common prefix/suffix characters for this target.
cat >"$AFFIX_FILE" <<'EOF'
!
?
#
EOF

# Cleanup on exit.
cleanup() {
	rm -f "$HOMOGRAPH_FILE" "$LEET_FILE" "$SALT_FILE" "$AFFIX_FILE"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Run worcestershire with all custom dictionaries.
# ---------------------------------------------------------------------------

echo "==> Generating with custom dictionaries for word: $WORDS"
echo ""

"$BIN" \
	--words "$WORDS" \
	--combination "3 5 6 8" \
	--homograph-dict "$HOMOGRAPH_FILE" \
	--leet-dict "$LEET_FILE" \
	--salt-dict "$SALT_FILE" \
	--affix-dict "$AFFIX_FILE" \
	--output "$OUTPUT" \
	--force \
	--quiet

LINE_COUNT=$(wc -l <"$OUTPUT")
echo "    $LINE_COUNT entries written to $OUTPUT."
echo ""
echo "All entries:"
cat "$OUTPUT"

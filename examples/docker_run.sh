#!/usr/bin/env bash
# examples/docker_run.sh
#
# Shows how to use worcestershire via the official Docker image without
# installing Crystal or any dependencies on the host.
#
# The current directory is mounted at /data inside the container so that
# input files can be read and output files can be written to the host.
#
# Prerequisites:
#   docker (or podman -- set DOCKER=podman)
#
# Usage:
#   bash examples/docker_run.sh [INPUT_FILE]
#
# Arguments:
#   INPUT_FILE  Path to a wordlist on the host.
#               Default: words.txt in the current directory.

set -euo pipefail

DOCKER="${DOCKER:-docker}"
IMAGE="${IMAGE:-worcestershire:latest}"
INPUT_HOST="${1:-words.txt}"
OUTPUT_HOST="docker_output.lst"

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------

if ! command -v "$DOCKER" >/dev/null 2>&1; then
	echo "Docker (or \$DOCKER) not found in PATH." >&2
	exit 1
fi

# Build the image if it does not exist locally.
if ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
	echo "==> Image '$IMAGE' not found locally. Building ..."
	"$DOCKER" build -t "$IMAGE" .
fi

if [[ ! -f "$INPUT_HOST" ]]; then
	echo "Input file '$INPUT_HOST' not found. Creating a sample file ..." >&2
	printf 'docker\ncontainer\nalpine\n' >"$INPUT_HOST"
	echo "Created $INPUT_HOST."
fi

# ---------------------------------------------------------------------------
# Derive the container-side paths from the host paths.
# ---------------------------------------------------------------------------

INPUT_CONTAINER="/data/$(basename "$INPUT_HOST")"
OUTPUT_CONTAINER="/data/$(basename "$OUTPUT_HOST")"

echo "==> Running worcestershire in Docker ..."
echo "    Image:  $IMAGE"
echo "    Input:  $INPUT_HOST -> $INPUT_CONTAINER"
echo "    Output: $OUTPUT_CONTAINER -> $OUTPUT_HOST"
echo ""

"$DOCKER" run --rm \
	-v "$(pwd):/data" \
	"$IMAGE" \
	--input "$INPUT_CONTAINER" \
	--combination "1 2 3" \
	--depth 2 \
	--output "$OUTPUT_CONTAINER" \
	--force \
	--no-color \
	--quiet

LINE_COUNT=$(wc -l <"$OUTPUT_HOST")
echo "==> Done. $LINE_COUNT lines written to $OUTPUT_HOST."
echo ""
echo "First 15 entries:"
head -15 "$OUTPUT_HOST"

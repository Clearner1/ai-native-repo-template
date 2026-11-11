#!/usr/bin/env bash
# Scaffolds a conflict-free per-PR changeset fragment under change-logs/unreleased/changesets/

set -euo pipefail

SLUG="${1:-}"
SUMMARY="${2:-Describe the user-visible or operational outcome in one sentence.}"
CHANGE_TYPE="${3:-added}"

if [ -z "$SLUG" ]; then
  printf '❌ Error: Missing changeset SLUG.\n' >&2
  printf '   Next action: make new-changeset SLUG=short-feature-name SUMMARY="One-sentence outcome"\n' >&2
  exit 1
fi

CLEAN_SLUG="$(printf '%s' "$SLUG" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-_')"
if [ -z "$CLEAN_SLUG" ]; then
  printf '❌ Error: SLUG "%s" contains no valid alphanumeric characters.\n' "$SLUG" >&2
  printf '   Next action: make new-changeset SLUG=valid-kebab-slug SUMMARY="One-sentence outcome"\n' >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_DIR="$ROOT_DIR/change-logs/unreleased/changesets"
mkdir -p "$TARGET_DIR"

STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT_FILE="$TARGET_DIR/${STAMP}-${CLEAN_SLUG}.md"

cat > "$OUT_FILE" <<EOF
---
type: ${CHANGE_TYPE}
summary: "${SUMMARY}"
---
EOF

printf '✅ Created changeset fragment: %s\n' "${OUT_FILE#"$ROOT_DIR"/}"
printf '   Next action: edit %s if needed, then run: make gate\n' "${OUT_FILE#"$ROOT_DIR"/}"

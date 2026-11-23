#!/usr/bin/env bash
# guard_agents_md_size.sh — Enforce AGENTS.md byte-budget ceiling.
#
# Basis: AGENTS.md §1 preamble
#   "Keep this root index concise (< 16 KB, enforced by `make gate`)."
#
# Why a standalone guard in addition to repo-gate.sh?
#   repo-gate.sh checks structural governance as a whole. This guard runs
#   AGENTS.md size as an isolated, nameable, RED/GREEN-provable check that
#   CI can report on its own line, and that a co-located subsystem's guard
#   runner can import independently.
#
# RED proof (must exit 1):
#   dd if=/dev/urandom bs=1 count=20000 2>/dev/null | base64 >> /tmp/AGENTS_big.md
#   bash tests/guards/guard_agents_md_size.sh /tmp/AGENTS_big.md
# GREEN proof (must exit 0):
#   bash tests/guards/guard_agents_md_size.sh AGENTS.md

set -uo pipefail

RULE_NAME="guard_agents_md_size"
MAX_BYTES=16384

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

# Accept an optional explicit file argument (for RED/GREEN proof runs).
TARGET="${1:-AGENTS.md}"

if [ ! -f "$TARGET" ]; then
  printf '⚠️  %s: target not found: %s (skipping)\n' "$RULE_NAME" "$TARGET"
  exit 0
fi

SIZE="$(wc -c < "$TARGET" | tr -d ' ')"

if [ "$SIZE" -gt "$MAX_BYTES" ]; then
  printf '❌ %s: %s is %d bytes (ceiling: %d bytes).\n' "$RULE_NAME" "$TARGET" "$SIZE" "$MAX_BYTES" >&2
  printf '   Oversized root instructions dilute critical invariants and exceed\n' >&2
  printf '   the agent context budget.\n' >&2
  printf '   Next action: move detailed workflow prose into .agents/skills/<name>/SKILL.md\n' >&2
  printf '   and keep only a one-line pointer in AGENTS.md. Then re-run: make guards\n' >&2
  exit 1
fi

printf '✅ %s: %s is %d bytes (ceiling: %d bytes).\n' "$RULE_NAME" "$TARGET" "$SIZE" "$MAX_BYTES"

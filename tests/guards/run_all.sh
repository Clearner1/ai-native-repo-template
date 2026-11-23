#!/usr/bin/env bash
# run_all.sh — CI entry-point for all guard tests.
# Discovers and runs every guard_*.sh in this directory.
# Output contract: every failure prints file:line context + one "Next action:" command.
# Exit: 0 when all guards pass, 1 when any fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))"
cd "$ROOT_DIR"

TOTAL=0
FAILED=0
FAILED_NAMES=()

for guard in "$SCRIPT_DIR"/guard_*.sh; do
  [ -f "$guard" ] || continue
  name="$(basename "$guard")"
  TOTAL=$((TOTAL + 1))
  printf '── %s\n' "$name"
  if bash "$guard"; then
    : # guard printed its own ✅
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES+=("$name")
  fi
  printf '\n'
done

printf '══════════════════════════════════════════\n'
if [ "$FAILED" -eq 0 ]; then
  printf '✅ All %d guard(s) passed.\n' "$TOTAL"
  exit 0
else
  printf '❌ %d of %d guard(s) failed:\n' "$FAILED" "$TOTAL"
  for n in "${FAILED_NAMES[@]}"; do
    printf '   • %s\n' "$n"
  done
  printf '\nNext action: fix the violations above, then re-run: make guards\n'
  exit 1
fi

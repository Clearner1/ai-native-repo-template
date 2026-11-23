#!/usr/bin/env bash
# guard_template.sh — Copy this file to write a new guard.
#
# INSTRUCTIONS:
#   1. cp guard_template.sh guard_<your-rule>.sh
#   2. Fill in RULE_NAME, RULE_BASIS, and the grep PATTERNS below.
#   3. Set SCAN_TEST_FILES_ONLY=true if the rule applies only to test files.
#   4. Add testdata/should_fail/<fixture> that MUST trigger this guard (RED proof).
#   5. Add testdata/should_pass/<fixture> that must NOT trigger this guard (GREEN proof).
#   6. Record RED + GREEN outputs in your PR body under §4 Reverse Verification.
#
# Output contract:
#   - Every violation: print "❌ file:line: reason" + "   Next action: <command>"
#   - On clean:  print "✅ <RULE_NAME>: <what was checked>."
#   - Exit 0 on clean, exit 1 on any violation.

set -uo pipefail

# ── Configuration ────────────────────────────────────────────────────────────

RULE_NAME="guard_template"           # e.g. "guard_no_sleep"
RULE_BASIS="AGENTS.md §N"           # cite the Iron Rule or standard this enforces
SCAN_TEST_FILES_ONLY=false          # true → only scan files matching TEST_GLOBS

# Patterns that constitute a violation (ERE, one per line).
# Tip: be specific enough to avoid false positives; tune per project language.
PATTERNS=(
  # 'your_pattern_here'
)

# File-name globs to scan. When SCAN_TEST_FILES_ONLY=false, all source files
# matching these globs are scanned. Add or remove globs for your language.
SOURCE_GLOBS=(
  '*.go' '*.py' '*.ts' '*.js' '*.java' '*.kt' '*.rs' '*.rb' '*.cs' '*.cpp' '*.c'
)

# Test-file globs (used when SCAN_TEST_FILES_ONLY=true).
TEST_GLOBS=(
  '*_test.go' 'test_*.py' '*_test.py'
  '*.test.ts' '*.test.js' '*.spec.ts' '*.spec.js'
  '*Test.java' '*Tests.java' '*Spec.scala' '*_spec.rb'
)

# Directories/paths to skip (passed to find's -prune).
SKIP_PATHS=(
  '.git' 'node_modules' 'vendor' 'third_party' 'site' 'dist' 'build' '.agents'
)

# ── Scan target override: accept an optional directory argument ───────────────
# Allows: ./guard_template.sh tests/guards/testdata/should_fail/
SCAN_ROOT="${1:-}"

# ── Helpers ──────────────────────────────────────────────────────────────────

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

SCAN_FROM="${SCAN_ROOT:-$ROOT_DIR}"

FAILURES=0

prune_args=()
for skip in "${SKIP_PATHS[@]}"; do
  prune_args+=(-path "*/$skip" -prune -o)
done

if [ "${SCAN_TEST_FILES_ONLY}" = "true" ]; then
  ACTIVE_GLOBS=("${TEST_GLOBS[@]}")
else
  ACTIVE_GLOBS=("${SOURCE_GLOBS[@]}")
fi

if [ "${#PATTERNS[@]}" -eq 0 ]; then
  printf '⚠️  %s: no PATTERNS defined — guard does nothing.\n' "$RULE_NAME" >&2
  exit 0
fi

# Build a combined grep pattern (alternation).
combined_pattern="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"

for glob in "${ACTIVE_GLOBS[@]}"; do
  while IFS= read -r -d '' file; do
    hits="$(grep -nE "$combined_pattern" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      printf '❌ %s\n' "$file" >&2
      while IFS= read -r line; do
        printf '   %s\n' "$line" >&2
      done <<< "$hits"
      # TODO: replace the message below with a specific remediation command.
      printf '   Next action: fix the violation above and re-run: bash tests/guards/%s.sh\n\n' "$RULE_NAME" >&2
      FAILURES=$((FAILURES + 1))
    fi
  done < <(find "$SCAN_FROM" "${prune_args[@]}" -name "$glob" -print0 2>/dev/null)
done

if [ "$FAILURES" -gt 0 ]; then
  printf '❌ %s: %d violation(s) found. Basis: %s\n' "$RULE_NAME" "$FAILURES" "$RULE_BASIS" >&2
  exit 1
fi

printf '✅ %s: no violations found.\n' "$RULE_NAME"

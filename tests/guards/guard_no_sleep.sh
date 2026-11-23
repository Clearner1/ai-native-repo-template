#!/usr/bin/env bash
# guard_no_sleep.sh — No wall-clock sleeps in test files.
#
# Basis: AGENTS.md §2 "No Wall-Clock Sleeps"
#   "Never use sleep() or assert elapsed wall-clock milliseconds in async tests.
#    Inject virtual clocks or deterministic latches so tests never flake under load."
#
# What this catches:
#   Go:     time.Sleep(
#   Python: time.sleep( | asyncio.sleep(
#   JS/TS:  setTimeout(   (bare sleep idiom; tune if setTimeout has legitimate uses)
#   Java:   Thread.sleep(
#   Rust:   thread::sleep(
#   Ruby:   sleep(
#
# Co-location note: This guard scans all test files project-wide.
# If a subsystem has its own testenv, add a package-local guard there too.
#
# RED proof (must exit 1):
#   bash tests/guards/guard_no_sleep.sh tests/guards/testdata/should_fail/
# GREEN proof (must exit 0):
#   bash tests/guards/guard_no_sleep.sh tests/guards/testdata/should_pass/

set -uo pipefail

RULE_NAME="guard_no_sleep"
SCAN_ROOT="${1:-}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"
SCAN_FROM="${SCAN_ROOT:-$ROOT_DIR}"

# Test-file name globs. Add patterns for your language.
TEST_GLOBS=(
  '*_test.go'
  'test_*.py' '*_test.py'
  '*.test.ts' '*.test.js'
  '*.spec.ts' '*.spec.js'
  '*Test.java' '*Tests.java' '*Spec.java'
  '*_spec.rb'
  '*_test.rs'
)

# Violation patterns (ERE). Language-qualified to minimise false positives.
PATTERNS=(
  'time\.Sleep\('          # Go
  'time\.sleep\('          # Python (qualified)
  'asyncio\.sleep\('       # Python async
  'Thread\.sleep\('        # Java / Kotlin
  'thread::sleep\('        # Rust
  '\bsleep\s*\([0-9]'      # C / shell / Ruby bare sleep with a numeric arg
)

SKIP_PATHS=('.git' 'node_modules' 'vendor' 'third_party' 'site' 'dist' 'build' '.agents' 'testdata')

prune_args=()
for skip in "${SKIP_PATHS[@]}"; do
  prune_args+=(-path "*/$skip" -prune -o)
done

combined="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"
FAILURES=0

for glob in "${TEST_GLOBS[@]}"; do
  while IFS= read -r -d '' file; do
    hits="$(grep -nEP "$combined" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      printf '❌ %s: wall-clock sleep in test file\n' "$file" >&2
      while IFS= read -r line; do
        printf '   %s\n' "$line" >&2
      done <<< "$hits"
      printf '   Next action: replace with a virtual clock, channel latch, or\n' >&2
      printf '   deterministic condition. See AGENTS.md §2.\n\n' >&2
      FAILURES=$((FAILURES + 1))
    fi
  done < <(find "$SCAN_FROM" "${prune_args[@]}" -name "$glob" -print0 2>/dev/null)
done

if [ "$FAILURES" -gt 0 ]; then
  printf '❌ %s: %d test file(s) contain wall-clock sleeps.\n' "$RULE_NAME" "$FAILURES" >&2
  exit 1
fi
printf '✅ %s: no wall-clock sleeps in test files.\n' "$RULE_NAME"

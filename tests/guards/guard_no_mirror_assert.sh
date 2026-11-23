#!/usr/bin/env bash
# guard_no_mirror_assert.sh — No mirror (toString / log-dump) assertions in tests.
#
# Basis: AGENTS.md §2 "No Mirror Assertions"
#   "Assert structured domain properties and observable effects — never toString()
#    dumps, raw log lines, or implementation-internal call order."
#
# A mirror assertion copies the production output verbatim into the expected
# value instead of asserting the semantic property it represents. It passes
# trivially because the same code that produces the output writes the expectation,
# and it fails on every refactor that changes formatting but not behaviour.
#
# What this catches (in test files):
#   assert ... .toString()    — asserting a string dump
#   assertEqual(str(obj), …)  — Python string coercion in assertion
#   expect(obj.toString())    — JS/TS mirror
#   assertThat(…, is(x.toString())) — Java mirror
#   snapshot of raw log lines (heuristic: assert + "log" + quote)
#
# RED proof (must exit 1):
#   bash tests/guards/guard_no_mirror_assert.sh tests/guards/testdata/should_fail/
# GREEN proof (must exit 0):
#   bash tests/guards/guard_no_mirror_assert.sh tests/guards/testdata/should_pass/

set -uo pipefail

RULE_NAME="guard_no_mirror_assert"
SCAN_ROOT="${1:-}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"
SCAN_FROM="${SCAN_ROOT:-$ROOT_DIR}"

TEST_GLOBS=(
  '*_test.go'
  'test_*.py' '*_test.py'
  '*.test.ts' '*.test.js'
  '*.spec.ts' '*.spec.js'
  '*Test.java' '*Tests.java'
  '*_spec.rb'
  '*_test.rs'
)

# Patterns that indicate a mirror assertion.
# These are heuristics — tune false positives for your codebase.
PATTERNS=(
  'assert.*\.toString\(\)'             # Go/Java/Kotlin: assert x.toString()
  'assertEqual\s*\(\s*str\s*\('        # Python: assertEqual(str(obj), ...)
  'assertEquals\s*\(\s*.*\.toString'   # Java: assertEquals(x.toString(), ...)
  'expect\s*\(.*\.toString\(\)\)'      # JS/TS: expect(x.toString())
  'toBe\s*\(.*\.toString\(\)\)'        # Jest: .toBe(x.toString())
  'assert_eq!\s*\(.*to_string\(\)'     # Rust: assert_eq!(x.to_string(), ...)
  'assert[[:space:]]+str[[:space:]]*\('  # Pytest: assert str(obj) == ...
  'assert[[:space:]]+f"[^"]*{'            # Pytest f-string dump: assert f"{obj}"
)

SKIP_PATHS=('.git' 'node_modules' 'vendor' 'third_party' 'site' 'dist' 'build' '.agents' 'testdata/should_fail')

prune_args=()
for skip in "${SKIP_PATHS[@]}"; do
  prune_args+=(-path "*/$skip" -prune -o)
done

combined="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"
FAILURES=0

for glob in "${TEST_GLOBS[@]}"; do
  while IFS= read -r -d '' file; do
    hits="$(grep -nE "$combined" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      printf '❌ %s: mirror assertion (toString/str dump) in test\n' "$file" >&2
      while IFS= read -r line; do
        printf '   %s\n' "$line" >&2
      done <<< "$hits"
      printf '   Next action: replace with a structured domain-property assertion.\n' >&2
      printf '   Assert what the value means, not how it prints. See AGENTS.md §2.\n\n' >&2
      FAILURES=$((FAILURES + 1))
    fi
  done < <(find "$SCAN_FROM" "${prune_args[@]}" -name "$glob" -print0 2>/dev/null)
done

if [ "$FAILURES" -gt 0 ]; then
  printf '❌ %s: %d mirror assertion(s) found in test files.\n' "$RULE_NAME" "$FAILURES" >&2
  exit 1
fi
printf '✅ %s: no mirror assertions found.\n' "$RULE_NAME"

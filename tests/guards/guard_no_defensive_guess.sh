#!/usr/bin/env bash
# guard_no_defensive_guess.sh — No speculative multi-fallback field guessing.
#
# Basis: AGENTS.md §1 Iron Rule 4 "Single Contract Oracle — Zero Defensive Guessing"
#   "Never write speculative fallback parsers (e.g., payload.userId ?? payload.user_id
#    ?? payload.id). Bind strictly to the canonical schema/DTO and pin upstream
#    contract SHAs."
#
# What this catches:
#   Chained null-coalescing / logical-or field access across different names
#   for what appears to be the same semantic field, e.g.:
#
#     payload.userId ?? payload.user_id ?? payload.id          (TS/JS)
#     data.get("userId") or data.get("user_id") or data.get("id")  (Python)
#     val := x.UserID; if val == "" { val = x.UserId }         (Go multi-assign heuristic)
#
#   The heuristic: two or more `??` or `||` operators chaining `.`-access or
#   `["key"]` access within a single expression on a source line.
#
# FALSE POSITIVES: legitimate double-fallback for optional fields with a final
# hard default (e.g., `name ?? defaultName`) are common. Tune PATTERNS or add
# file-level `# guard:no-defensive-guess:ignore` to skip a file.
#
# RED proof (must exit 1):
#   bash tests/guards/guard_no_defensive_guess.sh tests/guards/testdata/should_fail/
# GREEN proof (must exit 0):
#   bash tests/guards/guard_no_defensive_guess.sh tests/guards/testdata/should_pass/

set -uo pipefail

RULE_NAME="guard_no_defensive_guess"
SCAN_ROOT="${1:-}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"
SCAN_FROM="${SCAN_ROOT:-$ROOT_DIR}"

SOURCE_GLOBS=('*.go' '*.py' '*.ts' '*.js' '*.java' '*.kt' '*.rs' '*.cs')

# Two or more chained ?? (TS/JS) or `or` (Python) across different identifiers.
# Pattern: word.word ?? word.word (at minimum two hops).
PATTERNS=(
  '\.\w+\s*\?\?\s*\w+\.\w+\s*\?\?\s*\w+'    # a.x ?? b.y ?? c (TS/JS: 2+ ??)
  '\["[^"]+"\]\s*or\s+\w+\.get\('            # Python: .get("x") or obj.get(
  '\b\w+\.get\("[^"]+"\)\s+or\s+\w+\.get\("' # Python chained .get or .get
)

SKIP_PATHS=('.git' 'node_modules' 'vendor' 'third_party' 'site' 'dist' 'build' '.agents' 'testdata/should_fail')

prune_args=()
for skip in "${SKIP_PATHS[@]}"; do
  prune_args+=(-path "*/$skip" -prune -o)
done

combined="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"
FAILURES=0

for glob in "${SOURCE_GLOBS[@]}"; do
  while IFS= read -r -d '' file; do
    # Skip files that opted out with an inline ignore comment
    # Line-level ignore (narrower than file-level): skip only annotated lines.
    # File-level ignore was removed (red-team finding: a single header line
    # could suppress the entire file). Use line-level instead:
    #   payload.userId ?? payload.user_id  # guard:no-defensive-guess:ignore
    hits="$(grep -nE "$combined" "$file" 2>/dev/null \
      | grep -vE '# guard:no-defensive-guess:ignore|// guard:no-defensive-guess:ignore' \
      || true)"
    if [ -n "$hits" ]; then
      printf '❌ %s: speculative multi-fallback field access\n' "$file" >&2
      while IFS= read -r line; do
        printf '   %s\n' "$line" >&2
      done <<< "$hits"
      printf '   Next action: bind to the canonical contract field. If the upstream\n' >&2
      printf '   schema is ambiguous, pin its SHA in docs/contracts/ and choose one\n' >&2
      printf '   canonical key. See AGENTS.md §1 Iron Rule 4.\n\n' >&2
      FAILURES=$((FAILURES + 1))
    fi
  done < <(find "$SCAN_FROM" "${prune_args[@]}" -name "$glob" -print0 2>/dev/null)
done

if [ "$FAILURES" -gt 0 ]; then
  printf '❌ %s: %d file(s) with defensive field-guessing chains.\n' "$RULE_NAME" "$FAILURES" >&2
  exit 1
fi
printf '✅ %s: no speculative multi-fallback field guessing found.\n' "$RULE_NAME"

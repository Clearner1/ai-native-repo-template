#!/usr/bin/env bash
# guard_no_catchall.sh — No silent catch-all defaults on exhaustive enums/variants.
#
# Basis: AGENTS.md §1 Iron Rule 5 "Compile-Time Exhaustiveness"
#   "Do not add catch-all default/else branches that silently swallow unhandled
#    enum variants, events, or states. Let the compiler fail loudly on every
#    call site when a new variant is added."
#
# What this catches:
#   A `default:` or `else:` branch that immediately returns, logs, or no-ops
#   without panicking — the tell-tale sign of swallowed unhandled variants.
#
#   Pattern: default: followed within 2 lines by return/log/pass/break with
#   no panic/throw/unreachable/fatalError.
#
# This guard uses a two-pass heuristic:
#   Pass 1 — find files that contain 'default:' or generic else after a switch/match.
#   Pass 2 — check those blocks for silent exits (return/pass/break without panic).
#
# Because static analysis in shell is limited, this guard is intentionally
# conservative: it flags candidates for human review. Wire a proper AST linter
# (go vet, pylint, clippy) for precise exhaustiveness checking.
#
# RED proof (must exit 1):
#   bash tests/guards/guard_no_catchall.sh tests/guards/testdata/should_fail/
# GREEN proof (must exit 0):
#   bash tests/guards/guard_no_catchall.sh tests/guards/testdata/should_pass/

set -uo pipefail

RULE_NAME="guard_no_catchall"
SCAN_ROOT="${1:-}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"
SCAN_FROM="${SCAN_ROOT:-$ROOT_DIR}"

SOURCE_GLOBS=('*.go' '*.py' '*.ts' '*.js' '*.java' '*.kt' '*.rs' '*.cs')

# Patterns that indicate a silent catch-all:
# A line with only 'default:' or 'else:' (after a switch/match context),
# followed by a silent exit, with no panic/raise/unreachable on that or
# the immediately following non-blank line.
#
# We detect the simpler sub-case: `default:` with a trailing comment
# "// ignore", "// never", "// noop", or a bare return/break/pass.
PATTERNS=(
  'default:\s*(//\s*(ignore|noop|never|todo|fixme|ok|fine|safe))'  # commented-away
  'default:\s*$'                                                     # bare default: (needs context check below)
  'case _:'                                                           # Go wildcard swallowing unknown
  '^\s*else:\s*$'                                                    # bare else: (Python)
  '^\s*else:\s*#\s*(ignore|noop|never|todo|fixme|ok|fine|safe)'    # commented-away Python else
)

SKIP_PATHS=('.git' 'node_modules' 'vendor' 'third_party' 'site' 'dist' 'build' '.agents' 'testdata')

prune_args=()
for skip in "${SKIP_PATHS[@]}"; do
  prune_args+=(-path "*/$skip" -prune -o)
done

combined="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"
FAILURES=0

for glob in "${SOURCE_GLOBS[@]}"; do
  while IFS= read -r -d '' file; do
    hits="$(grep -nE "$combined" "$file" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      # Second-pass: skip if the same block also contains panic/raise/unreachable
      # within 3 lines of the default. Use awk for context window.
      flagged="$(awk '
        /default:|case _:|^\s*else:\s*$/ {
          start = NR
          block[NR] = $0
          for (i = NR+1; i <= NR+3; i++) block_lines[i] = 1
        }
        (NR in block_lines) {
          block[NR] = $0
        }
        END {
          for (ln in block) {
            line = block[ln]
            if (line ~ /panic|raise|unreachable!|fatalError|throw |abort\(\)/) {
              delete block[ln]
            }
          }
          for (ln in block) {
            if (block[ln] ~ /default:|case _:|^\s*else:\s*$/) {
              print ln": "block[ln]
            }
          }
        }
      ' "$file" 2>/dev/null || true)"
      if [ -n "$flagged" ]; then
        printf '❌ %s: potential silent catch-all branch\n' "$file" >&2
        while IFS= read -r line; do
          printf '   %s\n' "$line" >&2
        done <<< "$flagged"
        printf '   Next action: replace silent default/else with panic!/unreachable!/raise,\n' >&2
        printf '   or remove the branch to let the compiler enforce exhaustiveness.\n' >&2
        printf '   See AGENTS.md §1 Iron Rule 5.\n\n' >&2
        FAILURES=$((FAILURES + 1))
      fi
    fi
  done < <(find "$SCAN_FROM" "${prune_args[@]}" -name "$glob" -print0 2>/dev/null)
done

if [ "$FAILURES" -gt 0 ]; then
  printf '❌ %s: %d file(s) with potential silent catch-all branches.\n' "$RULE_NAME" "$FAILURES" >&2
  exit 1
fi
printf '✅ %s: no silent catch-all defaults found.\n' "$RULE_NAME"

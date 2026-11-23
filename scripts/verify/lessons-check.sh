#!/usr/bin/env bash
# AX-Friendly LESSONS.md & Promotion Pipeline Gate
# Enforces cursor format, required sections, and the 3x promotion threshold.
# Output contract: every failure prints localized context + one explicit `Next action:` command.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/verify/lessons-check.sh [--file <path/to/LESSONS.md>]

Validates LESSONS.md structure and enforces the 3x promotion pipeline:
  1. Verifies line 1 has a valid `<!-- reviewed-through: ... -->` cursor.
  2. Verifies required sections (`## Review log`, `## Moved to the code standards`) exist.
  3. Fails if any active lesson (before `## Moved to the code standards`) has `- Seen N×` with N >= 3.
  4. Reports active lesson counts, lessons at `Seen 2×` (next sighting promotes), and commits pending review.
EOF
}

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd))"
LESSONS_FILE="${ROOT_DIR}/LESSONS.md"

while [ $# -gt 0 ]; do
  case "$1" in
    --file)
      if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
        printf '❌ Error: --file requires a path argument.\n' >&2
        printf '   Next action: ./scripts/verify/lessons-check.sh --file LESSONS.md\n' >&2
        exit 1
      fi
      LESSONS_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '❌ Error: Unknown argument "%s".\n' "$1" >&2
      printf '   Next action: ./scripts/verify/lessons-check.sh --help\n' >&2
      exit 1
      ;;
  esac
done

FAILURES=0

fail_with_next() {
  local message="$1"
  local next_cmd="$2"
  printf '❌ Error: %s\n   Next action: %s\n\n' "$message" "$next_cmd" >&2
  FAILURES=$((FAILURES + 1))
}

# 1. Verify LESSONS.md exists
if [ ! -f "$LESSONS_FILE" ]; then
  fail_with_next \
    "Missing lessons file '$LESSONS_FILE'." \
    "git checkout main -- LESSONS.md  # or create LESSONS.md following .agents/skills/lessons-retrospective/SKILL.md"
  exit 1
fi

# 2. Verify reviewed-through cursor on line 1
FIRST_LINE="$(head -n 1 "$LESSONS_FILE" | tr -d '\r')"
CURSOR_SHA=""
if printf '%s\n' "$FIRST_LINE" | grep -Eq '^<!-- reviewed-through: \(none yet\) -->$'; then
  CURSOR_SHA="INITIAL"
elif printf '%s\n' "$FIRST_LINE" | grep -Eq '^<!-- reviewed-through: [A-Za-z0-9._-]+ \([^)]+\) -->$'; then
  CURSOR_SHA="$(printf '%s\n' "$FIRST_LINE" | sed -E 's/^<!-- reviewed-through: ([A-Za-z0-9._-]+) \(.*/\1/')"
else
  fail_with_next \
    "Line 1 of '$LESSONS_FILE' is missing a valid cursor: expected '<!-- reviewed-through: <sha|INITIAL> (<timestamp>) -->', got '${FIRST_LINE}'." \
    "git log -1 --format='<!-- reviewed-through: %h (%ci) -->' HEAD  # place this on line 1 of $LESSONS_FILE"
fi

# 3. Verify required sections exist (case-insensitive check for Review log)
if ! grep -Eiq '^## Review log[[:space:]]*$' "$LESSONS_FILE"; then
  fail_with_next \
    "'$LESSONS_FILE' is missing required section '## Review log'." \
    "Add a '## Review log' section to '$LESSONS_FILE' and re-run: ./scripts/verify/lessons-check.sh"
fi

if ! grep -Eiq '^## Moved to the code standards[[:space:]]*$' "$LESSONS_FILE"; then
  fail_with_next \
    "'$LESSONS_FILE' is missing required archive section '## Moved to the code standards'." \
    "Add a '## Moved to the code standards' section at the end of '$LESSONS_FILE' and re-run: ./scripts/verify/lessons-check.sh"
fi

# 4. Scan active lessons (everything before `## Moved to the code standards`,
#    skipping HTML comments and fenced code blocks).
#    Enforce that no active lesson remains at Seen >= 3x.
SCAN_OUTPUT="$(awk '
  BEGIN {
    in_comment = 0
    in_fence = 0
    in_archive = 0
    active_total = 0
    seen2_count = 0
    promote_hits = 0
  }
  {
    sub(/\r$/, "")
    line = $0

    # Stop active scan once we hit the promoted archive section
    if (!in_comment && !in_fence && tolower(line) ~ /^## moved to the code standards[[:space:]]*$/) {
      in_archive = 1
    }
    if (in_archive) next

    # Track fenced code blocks (``` or ~~~)
    if (!in_comment && line ~ /^[[:space:]]*(```|~~~)/) {
      in_fence = !in_fence
      next
    }
    if (in_fence) next

    # Strip HTML comments (single-line and multi-line)
    while (1) {
      if (in_comment) {
        end_pos = index(line, "-->")
        if (end_pos > 0) {
          line = substr(line, end_pos + 3)
          in_comment = 0
        } else {
          line = ""
          break
        }
      } else {
        start_pos = index(line, "<!--")
        if (start_pos > 0) {
          before = substr(line, 1, start_pos - 1)
          after = substr(line, start_pos + 4)
          end_pos = index(after, "-->")
          if (end_pos > 0) {
            line = before substr(after, end_pos + 3)
          } else {
            line = before
            in_comment = 1
            break
          }
        } else {
          break
        }
      }
    }

    if (line ~ /^[[:space:]]*-[[:space:]]+.*Seen[[:space:]]+[0-9]+(×|x)/) {
      tmp = line
      sub(/^.*Seen[[:space:]]+/, "", tmp)
      sub(/(×|x).*$/, "", tmp)
      count = tmp + 0
      active_total++
      if (count >= 3) {
        promote_hits++
        printf("PROMOTE|%d|%d|%s\n", NR, count, line)
      } else if (count == 2) {
        seen2_count++
        printf("WATCH|%d|%d|%s\n", NR, count, line)
      }
    }
  }
  END {
    printf("SUMMARY|%d|%d|%d\n", active_total, seen2_count, promote_hits)
  }
' "$LESSONS_FILE")"

ACTIVE_TOTAL=0
SEEN2_COUNT=0
WATCH_LINES=""

while IFS='|' read -r kind line_no seen_n raw_text; do
  case "$kind" in
    PROMOTE)
      fail_with_next \
        "Active lesson at ${LESSONS_FILE}:${line_no} reached 'Seen ${seen_n}×' (threshold: 3×) and must be promoted out of active sections." \
        "Load .agents/skills/lessons-retrospective/SKILL.md, move the rule into docs/code-standards.md (and tests/guards/ if mechanically enforceable), archive it under '## Moved to the code standards', then re-run: ./scripts/verify/lessons-check.sh"
      ;;
    WATCH)
      WATCH_LINES="${WATCH_LINES}  - ${LESSONS_FILE}:${line_no} (Seen ${seen_n}× — next sighting promotes)\n"
      ;;
    SUMMARY)
      ACTIVE_TOTAL="$line_no"
      SEEN2_COUNT="$seen_n"
      ;;
  esac
done <<EOF
$SCAN_OUTPUT
EOF

if [ "$FAILURES" -gt 0 ]; then
  printf 'Lessons gate failed with %d issue(s). Fix the items above using each Next action command.\n' "$FAILURES" >&2
  exit 1
fi

# 5. Optional git pending-commit visibility when cursor points to a valid commit in this repo
PENDING_INFO="cursor=${CURSOR_SHA}"
if [ -n "$CURSOR_SHA" ] && [ "$CURSOR_SHA" != "INITIAL" ]; then
  if git -C "$ROOT_DIR" rev-parse --verify "${CURSOR_SHA}^{commit}" >/dev/null 2>&1; then
    PENDING_COMMITS="$(git -C "$ROOT_DIR" rev-list --count "${CURSOR_SHA}..HEAD" 2>/dev/null || echo "?")"
    PENDING_INFO="cursor=${CURSOR_SHA}, pending_commits=${PENDING_COMMITS}"
  fi
fi

printf '✅ Lessons pipeline check passed (%s, active=%d, near_promotion_2x=%d).\n' \
  "$PENDING_INFO" "$ACTIVE_TOTAL" "$SEEN2_COUNT"

if [ -n "$WATCH_LINES" ]; then
  printf 'ℹ️  Lessons one sighting away from promotion (Seen 2×):\n%b' "$WATCH_LINES"
fi

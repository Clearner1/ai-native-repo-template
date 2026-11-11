#!/usr/bin/env bash
# AX-Friendly Pull Request Contract Validator
# Validates PR description completeness, Risk Tier selection, Reverse Verification, and Changeset rules.

set -euo pipefail

if [ "${1:-}" = "" ] || [ ! -f "${1:-}" ]; then
  printf '❌ Error: Pull request body markdown file is required.\n' >&2
  printf '   Next action: ./scripts/verify/pr-contract-check.sh .github/pull_request_template.md\n' >&2
  exit 1
fi

PR_FILE="$1"
BASE_SHA="${2:-}"
HEAD_SHA="${3:-}"
FAILURES=0

fail_pr() {
  local msg="$1"
  local next_cmd="$2"
  printf '❌ Error: %s\n   Next action: %s\n\n' "$msg" "$next_cmd" >&2
  FAILURES=$((FAILURES + 1))
}

# Strip HTML comments using POSIX sed/awk (zero external runtime dependencies)
CLEAN_BODY="$(awk '{
  gsub(/<!--[^>]*-->/, "");
  if ($0 ~ /<!--/) { in_c=1; sub(/<!--.*/, ""); print; next }
  if (in_c && $0 ~ /-->/) { in_c=0; sub(/.*-->/, ""); print; next }
  if (!in_c) print
}' "$PR_FILE")"

# 1. Required headings
for heading in "## 1. Intent & Context" "## 2. Alternatives Considered & Rejected" "## 3. Risk Tier & Sensitive Paths" "## 4. Reverse Verification" "## 5. Observability & Changeset Square"; do
  if ! grep -Fq "$heading" "$PR_FILE"; then
    fail_pr \
      "PR description is missing required section '$heading'." \
      "cat .github/pull_request_template.md  # copy missing sections into '$PR_FILE'"
  fi
done

# 2. Check Problem/Goal and Rejected Alternative are actually filled in
if ! printf '%s\n' "$CLEAN_BODY" | grep -Eq 'Problem / Goal\*\*:[[:space:]]*[^[:space:]]+'; then
  fail_pr \
    "'- **Problem / Goal**:' is blank in '$PR_FILE'." \
    "Fill in '- **Problem / Goal**: <why this PR exists>' in '$PR_FILE' and re-run: make check-pr FILE='$PR_FILE'"
fi

if ! printf '%s\n' "$CLEAN_BODY" | grep -Eq 'Rejected Alternative\*\*:[[:space:]]*[^[:space:]]+'; then
  fail_pr \
    "'- **Rejected Alternative**:' is blank. Decision history requires at least one rejected option." \
    "Document one alternative you ruled out under '## 2. Alternatives Considered & Rejected' in '$PR_FILE'"
fi

# 3. Risk Tier checkbox must be selected
TIER1_CHECKED=0
TIER2_CHECKED=0
grep -Eq '^- \[[xX]\] \*\*Tier 1' "$PR_FILE" && TIER1_CHECKED=1 || true
grep -Eq '^- \[[xX]\] \*\*Tier 2' "$PR_FILE" && TIER2_CHECKED=1 || true

if [ "$TIER1_CHECKED" -eq 0 ] && [ "$TIER2_CHECKED" -eq 0 ]; then
  fail_pr \
    "Neither Tier 1 nor Tier 2 risk checkbox is marked '[x]' in '$PR_FILE'." \
    "Mark '- [x] **Tier 1**' or '- [x] **Tier 2**' under Section 3 of '$PR_FILE'"
fi

# 4. Reverse verification check
if printf '%s\n' "$CLEAN_BODY" | grep -Eqi 'Verification Mode\*\*:[[:space:]]*`?red-green`?'; then
  # Extract lines between RED and GREEN (stripping markdown code fences like ```text)
  RED_CONTENT="$(printf '%s\n' "$CLEAN_BODY" | awk '/- \*\*RED/{flag=1; next} /- \*\*GREEN/{flag=0} flag' | sed -E '/^[[:space:]]*```/d' | tr -d '[:space:]')"
  GREEN_CONTENT="$(printf '%s\n' "$CLEAN_BODY" | awk '/- \*\*GREEN/{flag=1; next} /^## 5\./{flag=0} flag' | sed -E '/^[[:space:]]*```/d' | tr -d '[:space:]')"
  if [ -z "$RED_CONTENT" ] || [ -z "$GREEN_CONTENT" ]; then
    fail_pr \
      "Verification Mode is 'red-green', but RED or GREEN evidence block is empty." \
      "Temporarily revert your fix, capture the failing output under RED, restore the fix, capture passing output under GREEN, then re-run: make check-pr FILE='$PR_FILE'"
  fi
elif printf '%s\n' "$CLEAN_BODY" | grep -Eqi 'Verification Mode\*\*:[[:space:]]*`?docs-only`?'; then
  : # Valid only when no scripts/code changed (checked below when git SHAs are provided)
else
  fail_pr \
    "Invalid or missing '- **Verification Mode**:' (expected 'red-green' or 'docs-only')." \
    "Set '- **Verification Mode**: \`red-green\`' (or \`docs-only\` if purely markdown) in '$PR_FILE'"
fi

# 5. Git diff cross-checks when BASE_SHA and HEAD_SHA are supplied (in CI)
if [ -n "$BASE_SHA" ] && [ -n "$HEAD_SHA" ]; then
  CHANGED_FILES="$(git diff --name-only "$BASE_SHA" "$HEAD_SHA")"

  if printf '%s\n' "$CHANGED_FILES" | grep -Eq '^(\.github/|AGENTS\.md$|CODEOWNERS$|scripts/verify/|docs/contracts/|(.*/)?migrations/|(.*/)?(auth|security)/)'; then
    if [ "$TIER2_CHECKED" -ne 1 ]; then
      fail_pr \
        "This PR modifies CODEOWNERS-protected sensitive paths, so Tier 2 must be checked." \
        "Mark '- [x] **Tier 2 (Human Gate Required)**' in your PR description and request human review."
    fi
  fi

  if printf '%s\n' "$CLEAN_BODY" | grep -Eqi 'Verification Mode\*\*:[[:space:]]*`?docs-only`?'; then
    if printf '%s\n' "$CHANGED_FILES" | grep -Evq '(\.md$|^LICENSE$|^\.gitignore$)'; then
      fail_pr \
        "Verification Mode is 'docs-only', but non-documentation files were modified." \
        "Switch Verification Mode to 'red-green' and attach RED and GREEN test/gate outputs."
    fi
  fi

  HAS_CHANGESET_DIFF=0
  printf '%s\n' "$CHANGED_FILES" | grep -Eq '^change-logs/unreleased/changesets/.*\.md$' && HAS_CHANGESET_DIFF=1 || true
  DECLARES_NONE=0
  printf '%s\n' "$CLEAN_BODY" | grep -Eqi 'Changeset Fragment\*\*:[[:space:]]*`?none' && DECLARES_NONE=1 || true

  if [ "$HAS_CHANGESET_DIFF" -eq 0 ] && [ "$DECLARES_NONE" -eq 0 ]; then
    fail_pr \
      "No new changeset fragment found under 'change-logs/unreleased/changesets/' and PR does not declare 'none'." \
      "make new-changeset SLUG=your-topic SUMMARY='User-visible summary'  # or set '- **Changeset Fragment**: none (internal-only)'"
  fi
fi

if [ "$FAILURES" -gt 0 ]; then
  printf 'PR contract validation failed with %d issue(s).\n' "$FAILURES" >&2
  exit 1
fi

printf '✅ PR contract check passed for %s.\n' "$PR_FILE"

#!/usr/bin/env bash
# AX-Friendly Repository Governance Gate
# Output contract: every failure prints localized context + one explicit `Next action:` command.

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd))"
cd "$ROOT_DIR"

FAILURES=0

fail_with_next() {
  local message="$1"
  local next_cmd="$2"
  printf '❌ Error: %s\n   Next action: %s\n\n' "$message" "$next_cmd" >&2
  FAILURES=$((FAILURES + 1))
}

# 1. Verify mandatory governance surfaces exist
REQUIRED_FILES=(
  "README.md"
  "AGENTS.md"
  "CODEOWNERS"
  ".github/AGENTS_GUIDE.md"
  ".github/pull_request_template.md"
  ".github/workflows/agent-governance-gate.yml"
  "docs/new-agent-landing.md"
  "docs/contracts/0001-facts-vs-whims.md"
  "docs/decisions/0000-template.md"
  "change-logs/README.md"
)

for req in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$req" ]; then
    fail_with_next \
      "Missing required governance file '$req'." \
      "git checkout main -- '$req'  # or restore '$req' before running make gate"
  fi
done

# 2. Enforce AGENTS.md context-budget ceiling (prevent root-index bloat / dilution)
if [ -f "AGENTS.md" ]; then
  AGENTS_BYTES="$(wc -c < "AGENTS.md" | tr -d ' ')"
  MAX_AGENTS_BYTES=16384
  if [ "$AGENTS_BYTES" -gt "$MAX_AGENTS_BYTES" ]; then
    fail_with_next \
      "AGENTS.md is ${AGENTS_BYTES} bytes (ceiling: ${MAX_AGENTS_BYTES} bytes). Oversized root instructions dilute critical invariants." \
      "Move detailed workflow prose into '.agents/skills/<name>/SKILL.md' and keep only a one-line pointer in AGENTS.md."
  fi
fi

# 3. Validate every .agents/skills/*/SKILL.md has YAML frontmatter & is indexed in AGENTS.md
shopt -s nullglob
SKILL_FILES=(.agents/skills/*/SKILL.md)
SKILL_COUNT=0
for skill_file in ${SKILL_FILES[@]+"${SKILL_FILES[@]}"}; do
  SKILL_COUNT=$((SKILL_COUNT + 1))
  skill_dir="$(basename "$(dirname "$skill_file")")"

  if ! head -n 1 "$skill_file" | grep -qx -- "---"; then
    fail_with_next \
      "Skill '$skill_file' is missing opening YAML frontmatter delimiter ('---' on line 1)." \
      "sed -n '1,10p' '$skill_file'  # add name & description YAML frontmatter per .agents/skills/README.md"
  else
    frontmatter="$(awk 'NR==1 && $0=="---" {in_fm=1; next} in_fm && $0=="---" {exit} in_fm {print}' "$skill_file")"
    if ! printf '%s\n' "$frontmatter" | grep -Eq '^name:[[:space:]]*[^[:space:]]+'; then
      fail_with_next \
        "Skill '$skill_file' frontmatter is missing 'name: <skill-name>'." \
        "sed -n '1,12p' '$skill_file'  # add 'name: $skill_dir' inside YAML frontmatter"
    fi
    if ! printf '%s\n' "$frontmatter" | grep -Eq '^description:[[:space:]]*.+'; then
      fail_with_next \
        "Skill '$skill_file' frontmatter is missing 'description: <trigger condition>'." \
        "sed -n '1,12p' '$skill_file'  # add a one-line trigger description inside YAML frontmatter"
    fi
  fi

  if [ -f "AGENTS.md" ] && ! grep -Fq "$skill_file" "AGENTS.md"; then
    fail_with_next \
      "Skill '$skill_file' exists on disk but is not registered in AGENTS.md." \
      "Add '- **$skill_dir** (\`$skill_file\`) — <when to load>' to Section 4 of AGENTS.md, then run: make gate"
  fi
done

# 4. Reject monolithic root CHANGELOG.md to prevent multi-agent merge collisions
if [ -f "CHANGELOG.md" ]; then
  fail_with_next \
    "Found monolithic root 'CHANGELOG.md', which causes merge collisions across parallel agents." \
    "git rm CHANGELOG.md && make new-changeset SLUG=your-topic SUMMARY='Your user-visible change'"
fi

# 5. Validate changeset fragments schema
CHANGESET_FILES=(change-logs/*/changesets/*.md)
CHANGESET_COUNT=0
for cs_file in ${CHANGESET_FILES[@]+"${CHANGESET_FILES[@]}"}; do
  CHANGESET_COUNT=$((CHANGESET_COUNT + 1))
  if ! head -n 1 "$cs_file" | grep -qx -- "---"; then
    fail_with_next \
      "Changeset '$cs_file' is missing YAML frontmatter." \
      "sed -n '1,10p' '$cs_file'  # compare with change-logs/README.md format"
    continue
  fi
  cs_fm="$(awk 'NR==1 && $0=="---" {in_fm=1; next} in_fm && $0=="---" {exit} in_fm {print}' "$cs_file")"
  if ! printf '%s\n' "$cs_fm" | grep -Eq '^type:[[:space:]]*(added|changed|fixed|security)[[:space:]]*$'; then
    fail_with_next \
      "Changeset '$cs_file' must declare 'type: added | changed | fixed | security'." \
      "sed -n '1,8p' '$cs_file'  # set valid type field and re-run: make gate"
  fi
  if ! printf '%s\n' "$cs_fm" | grep -Eq '^summary:[[:space:]]*.+'; then
    fail_with_next \
      "Changeset '$cs_file' must declare a non-empty 'summary:' line." \
      "sed -n '1,8p' '$cs_file'  # add summary: \"One-sentence outcome\" and re-run: make gate"
  fi
done

# 6. Enforce AX `Next action:` contract across all scripts in scripts/verify/
VERIFY_SCRIPTS=(scripts/verify/*.sh)
for script_path in ${VERIFY_SCRIPTS[@]+"${VERIFY_SCRIPTS[@]}"}; do
  if [ ! -x "$script_path" ]; then
    fail_with_next \
      "Verification script '$script_path' is not marked executable." \
      "chmod +x '$script_path' && make gate"
  fi
  if ! grep -Fq "Next action:" "$script_path"; then
    fail_with_next \
      "Script '$script_path' does not emit an AX 'Next action:' recovery handle on error paths." \
      "grep -n 'Error' '$script_path'  # append 'Next action: <exact command>' to failure outputs"
  fi
done

if [ "$FAILURES" -gt 0 ]; then
  printf 'Gate failed with %d issue(s). Fix the items above using each Next action command.\n' "$FAILURES" >&2
  exit 1
fi

printf '✅ Repository governance gate passed (%d skill(s), %d changeset(s), AGENTS.md=%sB).\n' \
  "$SKILL_COUNT" "$CHANGESET_COUNT" "${AGENTS_BYTES:-0}"

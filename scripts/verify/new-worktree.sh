#!/usr/bin/env bash
# Creates an isolated git worktree for an agent task sharing the local repository object store.

set -euo pipefail

AGENT_NAME="${1:-}"
TOPIC_SLUG="${2:-}"

if [ -z "$AGENT_NAME" ] || [ -z "$TOPIC_SLUG" ]; then
  printf '❌ Error: Both AGENT and TOPIC arguments are required to isolate agent worktrees.\n' >&2
  printf '   Next action: make worktree AGENT=james TOPIC=add-skills\n' >&2
  exit 1
fi

CLEAN_AGENT="$(printf '%s' "$AGENT_NAME" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-_')"
CLEAN_TOPIC="$(printf '%s' "$TOPIC_SLUG" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-_')"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

BRANCH_NAME="agent/${CLEAN_AGENT}/${CLEAN_TOPIC}"
WORKTREE_PATH="${ROOT_DIR}/.worktrees/${CLEAN_AGENT}-${CLEAN_TOPIC}"

if [ -d "$WORKTREE_PATH" ]; then
  printf '❌ Error: Worktree path "%s" already exists.\n' "$WORKTREE_PATH" >&2
  printf '   Next action: cd "%s"  # or remove stale worktree with: git worktree remove "%s"\n' "$WORKTREE_PATH" "$WORKTREE_PATH" >&2
  exit 1
fi

mkdir -p "${ROOT_DIR}/.worktrees"
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" HEAD

printf '✅ Created isolated worktree for @%s\n' "$CLEAN_AGENT"
printf '   Branch:   %s\n' "$BRANCH_NAME"
printf '   Worktree: %s\n' "$WORKTREE_PATH"
printf '   Next action: cd "%s" && make gate\n' "$WORKTREE_PATH"

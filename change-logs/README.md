# Conflict-Free Release Changesets (`change-logs/`)

When multiple agents land pull requests concurrently, editing a single `CHANGELOG.md` guarantees constant merge conflicts.

## How It Works

1. **During Feature / Bugfix PRs**:
   - Run `make new-changeset SLUG=<short-topic> SUMMARY="One-sentence user-facing summary."`
   - Commit the generated markdown fragment inside `change-logs/unreleased/changesets/`.
   - Never edit another PR's changeset file.
2. **At Release Time**:
   - The release owner (or Release Agent following `.agents/skills/release-changeset/SKILL.md`) moves `change-logs/unreleased/changesets/*.md` into `change-logs/<version>/changesets/` and compiles the versioned `RELEASE_NOTES.md`.

## Fragment Format

```markdown
---
type: added | changed | fixed | security
summary: "Short, user-legible outcome sentence (no internal jargon)."
---

Optional 1-2 sentences of migration or operational context if needed.
```

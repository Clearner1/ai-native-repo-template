# Agent Skills Directory (`.agents/skills/`)

Each subdirectory under `.agents/skills/<skill-name>/` contains a focused `SKILL.md` Standard Operating Procedure (SOP) loaded **on demand** so `AGENTS.md` stays compact and high-signal.

## Authoring Rules for Skills

1. **One Workflow per Skill**: Keep each `SKILL.md` scoped to one repeatable engineering motion (e.g., pre-code feature contracting, Red -> Green bugfix verification, peer review, changeset release, contract sync).
2. **YAML Frontmatter Required**:
   ```yaml
   ---
   name: <skill-name>
   description: <one-sentence trigger condition: when an agent must load this skill>
   ---
   ```
3. **Register in `AGENTS.md`**: Every `.agents/skills/<skill-name>/SKILL.md` must be listed in Section 4 of `AGENTS.md` (`make gate` enforces this invariant).
4. **Actionable Outputs**: Include exact commands and pass/fail checklists rather than vague prose.

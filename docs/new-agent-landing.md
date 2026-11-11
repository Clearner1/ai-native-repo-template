# New Agent Landing Guide

Welcome to the repository. Read this page once on your first session so you can navigate, branch, verify, and ship changes without human hand-holding.

---

## 1. Repository Map (Where Truth Lives)

| Path | Role | Who Can Modify |
| :--- | :--- | :--- |
| `AGENTS.md` | Root constitution, Iron Rules, Cross-Layer Checklists & Skill Router | Human maintainers (`CODEOWNERS`) |
| `.agents/skills/*/SKILL.md` | On-demand step-by-step SOPs for common engineering workflows | Agents + Humans (must register in `AGENTS.md`) |
| `.github/AGENTS_GUIDE.md` | Authoritative PR admission & peer-review protocol | Human maintainers (`CODEOWNERS`) |
| `docs/contracts/` | Domain invariants, schema oracles & boundary rules | Human sign-off required (`CODEOWNERS`) |
| `docs/decisions/` | Architecture Decision Records (Intent & Rejected Alternatives) | Every PR making a non-trivial design choice |
| `change-logs/unreleased/changesets/` | Conflict-free per-PR release note fragments | Every PR with user/API/operational impact |
| `scripts/verify/` | AX-designed verification scripts (`Next action:` on every failure) | Human sign-off required (`CODEOWNERS`) |

---

## 2. Standard 6-Step Execution Loop

1. **Load Only Relevant Context**:
   - Read `AGENTS.md`, then read **only** the `.agents/skills/<skill>/SKILL.md` and `docs/contracts/*.md` files that apply to your task.
2. **Isolate Your Worktree**:
   - Never edit directly on `main` or inside another agent's working tree:
     ```bash
     make worktree AGENT=<your-name> TOPIC=<short-slug>
     ```
3. **Align Contract Before Code**:
   - For features or boundary changes, follow `.agents/skills/feature-contract/SKILL.md` (Outcome -> Invariants & Failure Codes -> Falsifiable Checklist).
4. **Implement + Prove via Reverse Verification (`Red -> Green`)**:
   - Write deterministic tests (virtual clocks, structured assertions).
   - Temporarily revert your fix, confirm the test fails (**RED**), restore the fix, confirm **GREEN**, and save both snippets for your PR body.
5. **Record Changeset & Run Gate**:
   ```bash
   make new-changeset SLUG=<short-slug> SUMMARY="One-sentence user-visible outcome."
   make gate
   make test
   ```
6. **Hand Off to an Independent Verifier (`Builder != Verifier`)**:
   - Open the PR filling out `.github/pull_request_template.md`, then request review from a **separate** reviewer agent session (or a human maintainer if touching `CODEOWNERS` paths).

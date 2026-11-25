# Pull Request & Verification Guide (`AGENTS_GUIDE.md`)

> **Authority Rule**: Only the copy of this file on the default branch (`main`) governs pull request admission. A pull request cannot modify this file to relax gates for itself.

---

## 1. Before Opening a Pull Request

1. **Check Standards & Recent Lessons**:
   - Review [`docs/code-standards.md`](../docs/code-standards.md) (change rules, hard test standards, acceptance criteria, and commit discipline) and [`LESSONS.md`](../LESSONS.md) before coding and before pushing.
2. **Branch & Identity Hygiene**:
   - Work in an isolated `git worktree` on an identity-scoped branch: `agent/<agent-name>/<topic>` (or `feat/<human-name>/<topic>`).
   - Commit under your own distinct identity so commit and PR history clearly records authorship.
3. **Run Local Gates**:
   - Run `make gate`, `make guards`, and your project's `make test` suite locally at the exact pushed head; fix all failures before pushing.
4. **Add a Changeset Fragment (or Explicit Skip)**:
   - For any user-facing, API, or operational change, run `make new-changeset SLUG=<topic>` and commit the resulting file under `change-logs/unreleased/changesets/`.
   - Purely internal refactors/docs may mark `changeset: none` in the PR body with a one-line justification.

---

## 2. Mandatory PR Body Evidence

Every pull request must populate `.github/pull_request_template.md` completely and satisfy the acceptance criteria in [`docs/code-standards.md`](../docs/code-standards.md#acceptance-criteria) (explicitly listing any check not run as `Not run` / `Not tried`):

- **Intent & Problem Context**: *Why* this change exists and what contract/invariant it upholds.
- **Rejected Alternatives**: At least one alternative considered and why it was dropped (preserving decision history).
- **Reverse Verification (`Red -> Green`)**:
  - For bugfixes, behavioral changes, and validation gates: paste the exact failing test/command output with the fix temporarily reverted (**RED**), followed by the passing output with the fix restored (**GREEN**).
  - For pure documentation/template scaffolding: mark `N/A (docs-only)` and paste `make gate` output.
- **UI Screenshots**: For changes to a visible UI, embed screenshots of the affected screens and states in the PR body. Capture the running UI at the commit under review and identify the platform or viewport and commit SHA. Include before-and-after images for layout or appearance changes when the previous state exists. If a screen cannot be captured, state what is missing and why so the reviewer can decide whether to proceed. Use `N/A (no visible UI change)` for other PRs.
- **Observability / Trace Square**: Name the structured trace span, metric, or log event that proves this path works in production (or `N/A` if non-runtime).

---

## 3. Peer Review & Convergence Protocol

1. **Independent Verifier (`Builder != Verifier`)**:
   - Request review from a separate agent session with clean context (or a human maintainer).
   - Execute the technical review steps in [`docs/code-standards.md`](../docs/code-standards.md#reviewing-a-pr) and, for external/community PRs, run the harm scan in [`docs/contributors.md`](../docs/contributors.md) before executing any code.
2. **Risk Tiering**:
   - **Tier 1 (Routine / Scoped)**: Localized changes with hard tests + Red -> Green proof + green CI may be approved by an independent Verifier Agent and queued for merge.
   - **Tier 2 (High-Impact / Sensitive)**: Changes touching `CODEOWNERS` paths (`.github/`, `AGENTS.md`, `CODEOWNERS`, `scripts/verify/`, `docs/contracts/`, `migrations/`, `auth/`, `security/`) **require human review**.
3. **Commit-Bound Approvals**:
   - An approval applies strictly to the exact commit SHA reviewed. Pushing new commits invalidates prior approvals.
4. **3-Round Circuit Breaker**:
   - Agent-to-agent review is capped at **3 rounds**. If unresolved after 3 rounds, escalate immediately to a human decision-maker (or split non-blocking follow-ups into a separate issue) rather than churning commits.
5. **Bar for Blocking (`HOLD`)**:
   - A blocking comment must cite a **concrete broken behavior, violated contract, or missing safety invariant**. Style nitpicks or CI-toolchain gripes are non-blocking follow-ups.

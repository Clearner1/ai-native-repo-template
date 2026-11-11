## 1. Intent & Context
<!-- Why does this change exist? Link the task, issue, contract (`docs/contracts/`), or ADR (`docs/decisions/`). -->
- **Problem / Goal**:
- **Contract / ADR Reference**:

## 2. Alternatives Considered & Rejected
<!-- Preserve decision history: what approach did you decide NOT to take, and why? -->
- **Rejected Alternative**:

## 3. Risk Tier & Sensitive Paths
- [ ] **Tier 1 (Routine)**: Scoped change covered by deterministic tests; no sensitive paths touched.
- [ ] **Tier 2 (Human Gate Required)**: Touches `.github/`, `AGENTS.md`, `CODEOWNERS`, `scripts/verify/`, `docs/contracts/`, `migrations/`, or `auth/security`.

## 4. Reverse Verification (`Red -> Green` Evidence)
<!-- Prove your test/check actually catches the bug or invariant violation when the fix is absent. -->
- **Verification Mode**: `red-green` <!-- or `docs-only` ONLY when zero runtime/script logic changed -->
- **RED (fix temporarily reverted — paste failing test/gate snippet)**:
  ```text
  
  ```
- **GREEN (fix restored — paste passing test/gate snippet)**:
  ```text
  
  ```

## 5. Observability & Changeset Square
- **Trace / Telemetry Signal**: <!-- Span, metric, error code with trace_id, or `N/A (non-runtime)` -->
- **Changeset Fragment**: <!-- Path under `change-logs/unreleased/changesets/*.md` or `none (internal-only)` -->

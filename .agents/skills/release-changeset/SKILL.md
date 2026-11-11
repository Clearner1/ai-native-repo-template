---
name: release-changeset
description: Author conflict-free changeset fragments under change-logs/unreleased/changesets/, roll up versioned release notes, and execute T-30m / T+24h trace readback launch squares.
---

# Release & Changeset Skill (`release-changeset`)

Use this skill whenever a pull request introduces a user-visible, API, or operational change, or when preparing and verifying a versioned release.

---

## 1. Zero-Conflict Per-PR Changesets

When multiple agents push pull requests concurrently, editing a monolithic `CHANGELOG.md` guarantees merge collisions (`make gate` explicitly rejects root `CHANGELOG.md` files). Instead:

1. **Scaffold a Fragment**:
   ```bash
   make new-changeset SLUG=<short-topic> SUMMARY="One-sentence user-visible outcome."
   ```
2. **Fragment Schema (`change-logs/unreleased/changesets/<timestamp>-<slug>.md`)**:
   ```markdown
   ---
   type: added | changed | fixed | security
   summary: "Short, user-legible outcome sentence (no internal jargon)."
   ---

   Optional 1-2 sentences of migration or operational context if needed.
   ```
3. **Writing Rules**:
   - **User-Legible Outcomes Only**: State what users or callers can now do or observe, not internal class names or file paths.
   - **Never Touch Other Fragments**: Each PR owns only its own fragment file.
   - **Internal-Only Bypass**: Purely internal refactors or documentation fixes may omit a fragment by declaring `- **Changeset Fragment**: none (internal-only)` in the PR description.

---

## 2. Semantic Versioning & Release Rollup

At release cut time, the release owner or Release Agent determines the version bump deterministically:

- **Minor (`X.Y.0`)**: Cuts when `type: added` or `type: changed` fragments are present. Requires all CI gates green on `main` and staging smoke verification passing.
- **Patch (`X.Y.Z`)**: Strictly reserved for production regressions (`type: fixed` or `type: security`) cherry-picked onto a release branch. No new features may ride in a patch release.
- **Rollup Procedure**:
  1. Move all fragments from `change-logs/unreleased/changesets/*.md` into `change-logs/<version>/changesets/`.
  2. Compile `change-logs/<version>/RELEASE_NOTES.md` grouped by `added`, `changed`, `fixed`, and `security`.
  3. Run `make gate` to verify all moved fragments satisfy the schema check.

---

## 3. Launch Squares: T-30m Trace Gate & T+24h Trace Readback

Shipping a release is tracked in explicit verification squares, with **production ignition reserved exclusively for a human**:

| Window | Square | Owner | Verification Requirement |
| :--- | :--- | :--- | :--- |
| **T-30m** | **Trace Coverage Gate** | Observability / Verifier Agent | Confirm every new code path in the release emits structured trace spans/error codes (`X-Trace-Id`) on staging so post-launch behavior is observable. |
| **T-0** | **Production Ignition** | **Human Only** | Human maintainer triggers the external production deploy after all pre-launch squares are green. |
| **T+15m** | **Baseline & Smoke Walk** | SRE / QA Agent | Verify error rates, latency baselines, and core user journeys on the live production floor. |
| **T+24h** | **Production Trace Readback** | Observability Agent | Compare 24h production traces against staging baselines to detect silent path drift before users file bug reports. |

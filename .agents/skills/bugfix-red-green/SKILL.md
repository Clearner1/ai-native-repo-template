---
name: bugfix-red-green
description: Execute mandatory Red -> Green reverse verification, pin regressions with deterministic unit tests, and validate test strength via mutation testing.
---

# Bugfix & Red-Green Verification Skill (`bugfix-red-green`)

Use this skill whenever investigating a defect, fixing a regression, or adding behavioral test coverage. In an agent-native workflow, **"the tests pass" is not sufficient evidence**—you must prove the test fails when the fix is absent.

---

## 1. Mandatory Red -> Green Reverse Verification

Every bugfix or behavioral guard pull request must execute and record this exact sequence:

1. **Reproduce & Pin (RED)**:
   - Write or update a deterministic test (or gate check) that targets the broken behavior.
   - Run the check **without** your production fix (or with the fix temporarily reverted) and capture the exact failing output, exit code, or metric.
2. **Apply the Fix (GREEN)**:
   - Apply the minimal production change that resolves the root cause.
   - Re-run the exact same command and confirm it passes deterministically.
3. **Record Evidence in the PR Body**:
   - Set `- **Verification Mode**: red-green` in Section 4 of `.github/pull_request_template.md`, paste both the **RED** and **GREEN** snippets, and validate locally with:
     ```bash
     make check-pr FILE=path/to/pr_body.md
     ```

---

## 2. Unit Test Admission Bar (Iron Rules)

Every new or modified test case must satisfy these constraints:

- **Assert Substance**: Every test must assert a concrete domain state or observable output. Completing without a timeout is never a valid assertion.
- **No Wall-Clock Sleeps**:
  - Never use `sleep()` or assert elapsed wall-clock milliseconds in unit tests.
  - Inject virtual clocks or deterministic synchronization latches. If bounded polling is unavoidable in a device/integration harness, include a contextual failure message (`waited for X, last state=Y`) and justify in the PR why no deterministic hook exists.
- **No Mirror Assertions**:
  - Never assert entire serialized JSON strings, `toString()` dumps, or raw log lines (except for pinned wire-contract vectors with an explicit upstream SHA). Assert parsed, structured fields.
- **No Literal Clones**:
  - Parameterize cases that differ only in input literals instead of copy-pasting test methods.
- **Greppable Naming**:
  - Name test suites `<Subject><Facet>Test` and remove any temporary `*RedTest` names before merging.

---

## 3. Mutation Check & Upstream Input Tightening

1. **Verify the Test Suite with Mutation Testing (`make mutate`)**:
   - Passing tests can still leave behavior unpinned. On core domain modules, run mutation testing (`make mutate`) to flip conditions or delete branches and confirm no mutant survives silently.
2. **Trace the Failure Upstream**:
   - Treat every agent or runtime bug as diagnostic evidence of an unclean upstream input:
     - Replace catch-all `else` / `default` branches with **compile-time exhaustive matching**.
     - If the bug stemmed from a hidden cross-file coupling, add a row to **Section 3 (Cross-Layer Change Checklists)** in `AGENTS.md`.

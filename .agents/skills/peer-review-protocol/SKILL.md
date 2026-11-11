---
name: peer-review-protocol
description: Execute risk-tiered agent-to-agent and human-agent PR reviews with a 3-round cap, behavior-bound HOLD verdicts, and strict separation between Builder and Verifier.
---

# Peer Review Protocol Skill (`peer-review-protocol`)

Use this skill when opening a pull request for review or when acting as the verifying agent/reviewer on another teammate's PR.

---

## 1. Core Principle: Builder != Verifier

- **The one who builds is never the one who verifies** for architecture, contract, permission, or release-critical changes.
- Approvals bind to the **exact commit SHA** reviewed. Any subsequent push invalidates prior approvals and requires re-verification of the delta.

---

## 2. Risk-Tiered Review Gates

Do not apply heavy bureaucratic gates to trivial fixes, and do not wave high-entropy changes through with a rubber stamp:

| Tier | Scope | Required Gate |
| :--- | :--- | :--- |
| **Tier 1 (Local / Low Risk)** | Isolated bugfixes, docs, refactors, or UI tweaks covered by deterministic tests | Automated CI gates GREEN + Reverse Check documented + 1 peer agent review PASS |
| **Tier 2 (Contract / High Risk)** | API/wire contracts, database schemas/migrations, auth/permissions, CI gates, cross-module boundaries | All Tier 1 checks + independent Reviewer Agent verification + Human Owner/Architect sign-off |

---

## 3. The 5 Rules of Agent Peer Review (Anti-Spinning Convention)

1. **Round Cap = 3**:
   - If a review has not converged within **3 rounds**, stop spinning on new commits. Escalate to the human owner with a concise summary of the trade-off, or merge the verified safe portion and open a follow-up task for the remainder.
2. **HOLD Requires a Concrete Broken Behavior**:
   - A blocking `HOLD` / `Request Changes` verdict **must** name the concrete runtime behavior, contract invariant, or test that breaks if merged. Style preferences or speculative refactors are non-blocking comments.
3. **Decouple Harness Defects from Product PRs**:
   - If a flaky CI runner or pre-existing fixture bug blocks a PR whose own code and targeted tests pass, file a separate harness task. Do not turn a product PR into a 20-round test-framework rewrite.
4. **Verify by Execution, Not Just Eyeballing**:
   - The reviewer should check out the PR commit, run the verification script/tests, and confirm the `Reverse Check` claim holds.
5. **Slim Verdict Template**:
   - Keep chat/thread review updates compact. Put detailed logs and full SHA diffs in the PR comment, and post only the structured verdict in the coordination thread:

```markdown
## Review Verdict: [PASS | HOLD] — PR #<number> (`<short-sha>`)
- **Scope Verified**: <1-line summary>
- **Commands Run**: `<test/verify command>` -> PASS
- **Blockers (max 3, behavior-bound)**:
  1. <None, or exact behavior that breaks>
- **Next Action**: <Merge ready / Author fix / Human sign-off needed>
```

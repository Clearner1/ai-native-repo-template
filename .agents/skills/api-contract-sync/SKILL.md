---
name: api-contract-sync
description: Enforce single-source-of-truth wire contracts, upstream SHA pinning, exhaustive state handling, and AX-friendly CLI/script outputs.
---

# API Contract & AX Output Skill (`api-contract-sync`)

Use this skill when adding or modifying API endpoints, shared schemas/DTOs, cross-repository interfaces, or developer/agent CLI scripts.

---

## 1. Single Contract Oracle (No Defensive Field Guessing)

AI models often write "defensive" parsing code that guesses multiple field aliases (e.g., checking `user_id`, `userId`, and `id`) or invents mock payloads. This hides schema drift and increases system entropy.

### Iron Rules:
1. **Verify Against the Canonical Source**:
   - Before writing a client DTO or handler, read the canonical schema definition in the shared contract directory (or external source checkout).
   - If the contract lives in an external repository, **pin and record the exact upstream commit SHA** in your PR description and fixture headers.
2. **Strict Schema Modeling**:
   - Model the exact canonical field names and types. Never add speculative fallback keys, envelope sniffing, or untyped `Map<String, Any>` payloads for structured API data.
3. **Candidate Snapshot Validation**:
   - Route/launch parameters carry **identity and intent only**, never full mutable business state.
   - Cached data and realtime events are *candidate snapshots*: validate that their entity/route identity matches the active target before merging into canonical state.
4. **Exhaustive Matching Over Silent Defaults**:
   - When switching over event types, statuses, or protocol enums, omit catch-all `else`/`default` branches so the compiler or static checker forces every consumer to handle newly added variants explicitly.

---

## 2. Errors Carry Trace IDs

- Every user- or caller-visible error originating from a server or boundary call must preserve and surface the request's **Trace ID** (`X-Trace-Id` or equivalent) so failures can be correlated directly against logs without reproduction guesswork.
- Local-only validation failures that never reached a server must log a distinct, greppable `reason=<code_name>` token.

---

## 3. Agent Experience (AX) Output Standard for Scripts & Tools

Every script, linter, or CLI tool in `scripts/` is an interface consumed by agents operating under a strict token budget.

### The AX Output Contract (`Information + Explicit Next Action`):
1. **Bounded Context**: Never dump thousands of raw lines or bare IDs without context. Print the failing file/check and the local snippet around the issue.
2. **Action Explicitness**: Every non-zero exit message **must** end with a single copy-pasteable `Next action:` line telling the agent or developer how to inspect or fix the problem:

```text
Error: Missing Reverse Check section in PR description or verification log.
Code: MISSING_REVERSE_CHECK
Next action: Fill in the '## Reverse Check (Red -> Green)' section in .github/PULL_REQUEST_TEMPLATE.md and re-run: ./scripts/verify/check-repo.sh
```

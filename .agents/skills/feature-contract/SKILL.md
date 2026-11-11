---
name: feature-contract
description: Establish a shared PM -> Engineer -> Reviewer implementation contract before writing code, enforce Facts vs. Whims storage separation, and record architectural decisions (ADRs).
---

# Feature Contract Skill (`feature-contract`)

Use this skill **before** writing feature code. In an AI-native repository where implementation is cheap, most defects originate from ambiguous upstream contracts rather than coding syntax.

---

## 1. The Contract Triangle (PM -> Engineer -> Reviewer)

Before opening a pull request for a non-trivial feature, lock a three-part contract in the task thread or issue:

### Step 1 — PM Frame (User Outcome)
State the request in user-outcome language only (do not prescribe code details):
- **Outcome**: One sentence describing what a user or caller can now do.
- **Acceptance Criteria**: 2–3 verifiable criteria. Flag any criterion that cannot be tested deterministically.

### Step 2 — Engineer Contract (Invariants & Evidence)
Translate the outcome into a concrete technical contract:
- **Invariants**: What system properties must hold true before, during, and after the change?
- **Facts vs. Whims Separation**:
  - **Immutable Facts** (append-only events, commits, transactions) must be stored separately from **Mutable Whims** (mute states, UI pins, view filters, user preferences).
  - Serving/aggregation layers must be treated as **rebuildable caches**, never the sole source of truth.
- **Failure Modes & Error Codes**: Explicit failure states and trace ID propagation requirements.
- **Planned Test Evidence**: Exact test suites or verification scripts that will prove the change.

### Step 3 — Reviewer Gate (Falsifiable Checklist)
Before code review begins, define a small, falsifiable gate:
- Every checklist item must be provable or disprovable by **reading the diff** or **running a deterministic command** (no vague adjectives like "clean" or "fast").

---

## 2. Contract-First Template

Copy and fill out this block in your task thread or PR description:

```markdown
## Feature Contract
- **User Outcome**: <1-sentence user-visible behavior>
- **Acceptance Criteria**:
  1. <Criterion 1>
  2. <Criterion 2>
- **Invariants & State Classification**:
  - Facts touched: <append-only records / none>
  - Whims touched: <mutable preferences / read-time filters / none>
  - Invariant: <what must never drift>
- **Failure Modes**: <explicit error codes + trace ID surface>
- **Verification Gate**:
  - [ ] Command: `<exact test or check command>`
  - [ ] Reverse check: `<how the test fails when the implementation is removed>`
```

---

## 3. When to Record a Decision History Entry (`docs/decisions/`)

Commit history shows *what* mutated, not *why* alternatives were rejected. Create a short Architectural Decision Record (ADR) in `docs/decisions/NNNN-<slug>.md` whenever a change:
1. Introduces or alters a cross-module boundary or wire contract;
2. Chooses between two viable architectural patterns with non-obvious trade-offs;
3. Changes a repository-wide rule or verification gate.

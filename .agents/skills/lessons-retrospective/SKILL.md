---
name: lessons-retrospective
description: Run periodic post-merge commit retrospectives, update LESSONS.md with Seen N× counts, promote 3× patterns into docs/code-standards.md and mechanical guards, and advance the reviewed-through cursor.
---

# Lessons Retrospective & Promotion Pipeline (`lessons-retrospective`)

Use this skill during scheduled (e.g., nightly/weekly) or post-incident retrospectives to turn merged-work failures into permanent repository rules and mechanical guards—without letting `LESSONS.md` bloat into unread prose.

---

## 1. Read the Cursor & Collect the Review Window

1. Read line 1 of `LESSONS.md`:
   ```text
   <!-- reviewed-through: <cursor-sha> (YYYY-MM-DD HH:MM +0000) -->
   ```
2. Inspect all commits merged since `<cursor-sha>` (if `<cursor-sha>` is `INITIAL`, pick the starting commit for your first window):
   ```bash
   git log --oneline --stat <cursor-sha>..HEAD
   ```
3. Focus on **high-signal failure indicators**:
   - Reverts and follow-up fixes landed within 24 hours of a previous commit/release.
   - Commits that turned `main` CI red or were shipped past an existing red test.
   - Issues/PRs that were reopened or required multiple fix attempts for the same root cause.
   - Commits that touched unexpected files (`--stat` wider than the stated goal) or raised a budget/threshold without removing code.
   - Positive examples worth reinforcing (clean Red -> Green proof, deterministic race reproduction, sibling-wide fixes).

---

## 2. Classify Each Finding

For every failure pattern found in the window, take **one** of three paths:

| Case | Action |
| :--- | :--- |
| **Matches an active lesson in `LESSONS.md`** | Append a concise bullet with concrete evidence (`<sha>`, `#issue`, what broke). Increment `Seen N×` and append today's date **only if today's date is not already listed** (`Seen` counts distinct calendar days). |
| **Matches a rule already in `docs/code-standards.md`** | Do **not** re-add it as an active lesson. Record it under `## Moved to the code standards` -> `Criteria still missed`, and **escalate it to a mechanical guard** (`tests/guards/` or `scripts/verify/`) so CI catches it automatically. |
| **New recurring or high-impact pattern** | Add a new entry under the matching category in `LESSONS.md` with: (1) bold imperative **Rule**, (2) concrete **Evidence** (`<sha>` / `#issue`), and (3) `- Seen 1× (YYYY-MM-DD).` |

Also append a compact summary to `## Review Log` covering the window, what went wrong, any promotions, and 1–3 **"Done right"** citations.

---

## 3. Execute the `Seen 3×` Promotion Pipeline

Whenever any active lesson reaches **`Seen 3×`** (3 distinct calendar days), promote it in the **same PR/commit**—never leave a `Seen 3×` item sitting in active sections (`lessons-check.sh` blocks this):

1. **Promote the Rule**:
   - Add a crisp row to the appropriate table in `docs/code-standards.md` (Rule + What a reviewer looks at + sharpest evidence).
   - If the pattern reveals a hidden cross-file coupling, also add a row to **Section 3 (Cross-Layer Change Checklists)** in `AGENTS.md`.
2. **Evaluate Mechanical Guard Escalation**:
   Use the decision matrix below to decide whether prose is enough or a guard test is required:

   | Failure Nature | Target Surface |
   | :--- | :--- |
   | Mechanical invariant (forbidden API, missing registration, boundary import, size/file budget, schema parity) | Add a guard test in `tests/guards/` or check in `scripts/verify/` (preferred — AI cannot forget a failing CI check). |
   | Behavioral/verification discipline (reproducing on reporter's surface, real inputs, Red -> Green proof, reading full thread) | Promote to `docs/code-standards.md` + PR checklist / reviewer protocol. |
   | Hidden cross-file coupling ("when you change X, update Y") | Add to `AGENTS.md` Cross-Layer Change Checklists + add a parity guard if checkable from code. |

3. **Archive in `LESSONS.md`**:
   - Remove the full entry from its active section.
   - Add a compact record under `## Moved to the code standards` with the rule title, all 3 dates, destination (`docs/code-standards.md` and/or `tests/guards/<name>`), and the 3rd-sighting evidence.

---

## 4. Advance the Cursor & Verify

1. Update line 1 of `LESSONS.md` to the latest reviewed commit on `main` (never a commit ahead of what you actually read):
   ```bash
   git log -1 --format='<!-- reviewed-through: %h (%ci) -->' HEAD
   ```
2. Run the automated lessons gate and repository governance gate:
   ```bash
   ./scripts/verify/lessons-check.sh
   make gate
   ```

---

## 5. Pass / Fail Checklist

- [ ] Line 1 cursor matches the exact commit SHA audited through.
- [ ] Every new or updated lesson cites real evidence (commit SHA / PR / issue) — no generic advice.
- [ ] `Seen N×` counts distinct calendar days (no duplicate dates inflating a single day's count).
- [ ] Zero active lessons remain at `Seen 3×` or higher (all promoted to `docs/code-standards.md` and archived).
- [ ] Repeated misses of already-promoted rules are escalated to a mechanical guard task or guard test.
- [ ] `./scripts/verify/lessons-check.sh` and `make gate` both exit `0`.

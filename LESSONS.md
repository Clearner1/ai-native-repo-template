<!-- reviewed-through: INITIAL (YYYY-MM-DD HH:MM +0000) -->
# Lessons from merged work

This project's code is written and reviewed by both humans and agents. Each
review cycle examines recent commits for what had to be fixed again, what
shouldn't have merged, and what was verified too thinly. What we learned is
kept here.

**Read this before changing code.** Each lesson is a rule, then why, then the
evidence. `Seen` counts the separate review cycles/days that found it. A lesson
seen on **3 or more separate cycles** moves into
[`docs/code-standards.md`](docs/code-standards.md) (and, where mechanically
enforceable, into `tests/guards/` or `scripts/verify/`), and is archived under
[Moved to the code standards](#moved-to-the-code-standards).

---

## Promotion pipeline (how this file works)

1. **Record new lessons with real evidence**: Add an entry under the matching
   category below using this exact structure:
   ```markdown
   **Rule statement in bold.** Why it matters: the class of bug it prevents.
   - `<sha>` (`#issue`): concise account of what broke and how it was fixed.
   - Seen 1× (YYYY-MM-DD).
   ```
2. **Increment on recurrence**: When a later review cycle finds the same
   pattern, append the new evidence and increment `Seen N×` with the new date
   (multiple hits on the same day count as `1×`).
3. **Promote at `Seen 3×` (mechanically gated)**: Once an active lesson reaches
   `Seen 3×`, promote it in the same PR:
   - Move the rule and its sharpest evidence into [`docs/code-standards.md`](docs/code-standards.md).
   - If the rule is mechanically checkable (forbidden API, missing registration,
     boundary import, budget), add a guard in `tests/guards/` or `scripts/verify/`.
   - If it reveals hidden cross-file coupling, add a row to `AGENTS.md`
     (Cross-Layer Change Checklists).
   - Move a concise summary into [`## Moved to the code standards`](#moved-to-the-code-standards).
4. **Escalate repeated post-promotion misses**: If a rule *already* in
   `docs/code-standards.md` is missed again, do not re-add prose — log it under
   `Criteria still missed` and convert it into a **mechanical guard test** so CI
   catches it automatically.
5. **Run the retrospective SOP & gate**: Load
   `.agents/skills/lessons-retrospective/SKILL.md` to run a review cycle, update
   the line-1 `reviewed-through` cursor, and verify with
   `./scripts/verify/lessons-check.sh`.

---

## Review log

One short entry per review window: commit range, volume, what failed at the
edges, and which lessons incremented or promoted.

<!--
Example:
- **YYYY-MM-DD (`<from>`..`<to>`, N commits, M releases):** Two fixes missed
  sibling call sites; one PR ran only a single test file and broke a guard on
  `main`. 1 lesson reached `Seen 2×`; 0 promoted.
-->

---

## Reading the report

<!-- Lessons about reproducing the reporter's exact case on their surface,
     building fixtures from literal bytes, and reading threads to the last
     comment before starting. -->

---

## Fix the class, not the sample

<!-- Lessons about reaching every sibling of a bug, scoping vendor/edge rules
     narrowly, and re-deriving everything built on a changed formula or contract. -->

---

## Verification

<!-- Lessons about what "verified" actually means: Red -> Green on the old code,
     real inputs, no network/host leaks, and running the full suite at the exact
     head being pushed. -->

---

## Concurrency and tests

<!-- Lessons about test isolation, deterministic synchronization (no wall-clock
     sleeps), cleaning up spawned processes/timers on test exit, preserving
     user-set defaults, and meeting size/perf budgets instead of raising them. -->

---

## Red tests and releases

<!-- Lessons about fixing red tests on `main` immediately, reading an existing
     red's issue to its last comment, and waiting for a green run before tagging. -->

---

## Merging and closing

<!-- Lessons about one commit per goal, recording finished test runs in commit
     or PR bodies, checking `git diff --stat` for stale files, and keeping
     worktrees isolated per session. -->

---

## Done right

<!-- Record concrete examples of strong engineering each review cycle (clean
     Red -> Green proofs, sibling-wide audits, deterministic race fixes) to
     reinforce good patterns. -->

---

## Moved to the code standards

Lessons seen on **3 or more separate cycles** live here as an audit trail. Their
active rules reside in [`docs/code-standards.md`](docs/code-standards.md) (and,
where enforceable, in `tests/guards/`).

<!--
Example promoted entry:
- **<Promoted rule statement>** (YYYY-MM-DD, YYYY-MM-DD, YYYY-MM-DD) ->
  [`docs/code-standards.md`](docs/code-standards.md) | Guard: `tests/guards/<name>` (or `N/A — review check`).
  - *3rd sighting*: `<sha>` (`#456`) <one-sentence summary>.

Example post-promotion escalation:
- **YYYY-MM-DD, criteria still missed:**
  - *<Rule name>*: Missed again in `<sha>`. Prose is insufficient — added
    mechanical guard `tests/guards/<name>` in `<sha2>` to fail CI automatically.
-->

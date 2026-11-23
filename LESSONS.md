<!-- reviewed-through: (none yet) -->
# Lessons from merged work

This project's code is written and reviewed by both humans and agents. Each
review cycle examines recent commits for what had to be fixed again, what
shouldn't have merged, and what was verified too thinly. What we learned is
kept here.

**Read this before changing code.** Each lesson is a rule, then why, then the
evidence. "Seen" counts the separate review cycles that found it. A lesson
seen on **3 or more separate cycles** moves into
[docs/code-standards.md](docs/code-standards.md) and is listed under
[Moved to the code standards](#moved-to-the-code-standards).

---

## How to record a lesson

1. **After a review finds a repeated mistake**, add a new entry under the
   appropriate category below (or create a new category).
2. **Format each entry as:**
   ```
   **Rule statement in bold.** Why it matters: the class of bug it prevents.
   - Evidence: commit SHA, issue number, what happened. Seen 1×.
   ```
3. **When the same lesson appears again**, update the evidence and increment
   the "Seen N×" count.
4. **At Seen 3×**, promote the rule to `docs/code-standards.md` and move the
   entry to [Moved to the code standards](#moved-to-the-code-standards).
5. **Record "Done right" examples** to reinforce good patterns.

---

## Reading the report

<!-- Lessons about reproducing reported issues before calling them fixed. -->

## Fix the class, not the sample

<!-- Lessons about fixing all siblings of a bug, not just the reported case. -->

## Verification

<!-- Lessons about what "verified" actually means: running the full suite,
     testing on all platforms, using real inputs. -->

## Concurrency and tests

<!-- Lessons about test isolation, timing, and concurrent test runs. -->

## Red tests and releases

<!-- Lessons about handling failing tests and release discipline. -->

## Merging and closing

<!-- Lessons about merge discipline, evidence in commit bodies, and when
     issues are truly fixed. -->

---

## Done right

<!-- Record what went well each review cycle. Reinforces good patterns. -->

---

## Moved to the code standards

<!-- Index of lessons promoted to docs/code-standards.md after 3+ occurrences.
     Keep the original lesson text here for reference, with a link to its
     new home in code-standards.md. -->

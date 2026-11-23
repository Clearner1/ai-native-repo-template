# Code standards

These rules come from what PR reviews keep asking for. A reviewer checks
each one, and a PR that doesn't meet one gets a comment saying which. Rules
graduate here from [LESSONS.md](../LESSONS.md) after being seen on 3 or
more separate review cycles. How to describe and review a change to a
subsystem is in the [subsystem references](subsystems/README.md).

## What a change contains

| Rule | What a reviewer looks at |
| --- | --- |
| A change does only what its goal needs. | Every change in behavior has a reason. Unrelated refactors, extra features and policy changes go in a PR of their own. |
| A fix covers exactly the cases it means to. | Which cases change, and which neighboring ones stay the same. Different errors are not handled as one. |
| A fix reaches every sibling of the bug. | Grep for the same pattern: every handler, route, guard of the same shape gets the fix in the same change. |
| A change re-derives everything built on what it changes. | When a change alters a formula, a list, a layout breakpoint or timing, find every caller, saved copy and test that assumed the old meaning, and run it. |
| A failed read, parse or hash means "unknown". | It never means "empty", "none" or "equal". Keep what was read before, copy a file that doesn't parse aside before writing over it. A list that guards access fails closed when its file can't be read. |
| Checks cover the edges the change touches. | For numbers, check boundaries. For paths, check each platform. For concurrency, check races and stale state. |

<!-- Add rows as lessons graduate from LESSONS.md. Each row cites the
     evidence that promoted it. -->

## Tests

| Rule | What a reviewer looks at |
| --- | --- |
| A fix comes with a test that fails without it. | The reviewer puts the old code back and runs the test, and the test must fail. A PR description says what it failed with. |
| A test never reaches the network. | A vendor's page or API is served from a test double, built from bytes saved from the real one. Break the change and watch where the test's requests go. |
| Tests use real inputs. | Fixtures look like real requests, real serialized output and real files on disk. That includes missing fields, empty values and defaults. |
| Tests check behavior, not implementation. | Assert what the user or caller needs. Formatting changes and internal refactors shouldn't break a test, unless exact bytes are the requirement. |
| A test that fails on `main` is a bug to fix now. | "Fails the same on origin/main" is not a baseline. Fix it at its cause, or open an issue naming the cause, before shipping on top of it. |
| Tests stay out of the real machine. | Run them under a temp HOME with caches pinned. Never touch a real config directory. |
| Whatever a test starts ends when the test does. | A fake process, a goroutine or an async task a test sets going is stopped or waited for before the test returns. |

<!-- Add rows as lessons graduate from LESSONS.md. -->

## Acceptance criteria

A change is merged or released only when it shows each of the following.
Say which ones were run and what they printed. A check that wasn't run is
listed as not run, never left out.

1. **A test that fails without the change.** Put the old code back and run
   the new test. It must fail with a real failure that names the behavior.
   A compile error or a skipped test doesn't count.
2. **Tests in a sandbox.** Run tests under a temporary HOME with language
   caches pinned to avoid downloading the world into temp. Never read or
   write a live config.
3. **The build and the suite.** Run lint, type-check, build and test
   commands for every target platform. Run the whole suite, not just the
   packages you think you touched: guard tests live in packages a change
   doesn't touch. Set `set -o pipefail` in command chains.
4. **Real use where possible.** A change to an integration, API or external
   service is also checked against the real thing: a real account, the
   vendor's real reply. If a real check isn't possible, say so. What wasn't
   tried is not told to users as working.

<!-- Customize these for your language and toolchain. Add platform-specific
     criteria (e.g., GUI tests in multiple browsers/languages, cross-OS
     builds). -->

## Reviewing a PR

These patterns come from recent reviews. A reviewer checks each one that
applies:

- **Run it.** Pull the head, merge it onto current `main` and run the
  acceptance checks. Reading the diff alone isn't a review.
- **Break it on purpose.** Revert the fix, or break the code it guards in
  several ways, and check that the new tests catch each break.
- **Follow the whole path.** Check that a value is saved and read under the
  same key. Check that a button works on the thing that actually runs.
- **Classify narrowly.** A mark or error class covers only the case it
  describes.
- **A preview writes nothing.** A dry run, plan or preview has no side
  effects.
- **Don't reverse deliberate decisions.** Product decisions are the
  maintainer's to change.
- **Docs match the source.** A reference is checked against the code it
  links, and every link must resolve.
- **Keep the PR to its goal.** Unrelated tests and refactors go in a PR of
  their own.

## Commits

A commit message names the areas it changes, then says what the user now
sees, written as plain behavior. Give the issue number. The body says how
it was verified, and which test fails without the change.

One commit has one goal. Two reports fixed together are two commits,
each with its own record, so a revert takes back one and keeps the other.

A checkout and the logs in it belong to the session that made them.
Work in a worktree of your own, never commit from another session's.

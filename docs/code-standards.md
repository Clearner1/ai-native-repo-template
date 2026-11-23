# Code standards

These rules come from what PR reviews keep asking for. A reviewer checks
each one, and a PR that doesn't meet one gets a blocking comment naming
which rule failed and what concrete behavior breaks. Rules graduate here
from [LESSONS.md](../LESSONS.md) after being seen on 3 or more separate
review cycles; whenever a rule can be enforced mechanically, pair it with
an automated check in [guard tests](../tests/guards/README.md).

How this fits with neighboring governance docs:

- [AGENTS.md](../AGENTS.md) — root Iron Rules, cross-layer checklists, and skill router.
- [Subsystem references](subsystems/README.md) — how to maintain subsystem docs and describe/review semantic changes.
- [Community PR protocol](contributors.md) — harm scan, close-without-review criteria, and contributor lists for external PRs.
- [AGENTS_GUIDE.md](../.github/AGENTS_GUIDE.md) — PR admission gates, Tier-1 vs. Tier-2 risk routing, and PR template contract.

## What a change contains

| Rule | What a reviewer looks at |
| --- | --- |
| **A change does only what its goal needs.** | Every change in behavior has a reason tied to the stated goal. Unrelated refactors, extra features, and policy changes go in a PR of their own. |
| **A fix covers exactly the cases it means to.** | Name which cases change and which neighboring ones stay the same. Distinct error types, status codes, or failure causes are never collapsed into one branch. |
| **A change holds on the whole path.** | Trace from user/caller input through callers, state transitions, persistence keys, and side effects to the end result. One correct helper function does not make the whole operation correct. |
| **A fix reaches every sibling of the bug.** | Grep for the same pattern across the repo: every sibling handler, route, adapter, branch, error hint, and caller of a changed predicate gets the fix in the same change. Fix the *class*, not only the reported sample. |
| **A change re-derives everything built on what it changes.** | When altering a formula, schema, list, default, layout breakpoint, or async timing, find every caller, cached projection, doc, and test that assumed the old meaning, update it, and run it. |
| **A failed read, parse, or hash means "unknown".** | Never treat a read or parse error as "empty", "none", or "equal". Keep prior state, move an unparseable file aside before overwriting, and fix the shared reader rather than writing a stricter copy beside it. Any list or check that guards access (allowlists, quotas, auth) **fails closed** when its source cannot be read—and is tested with an unreadable input. |
| **External contracts come from the upstream source.** | When writing another app's file, calling a vendor API, or emitting a wire payload, take every field type, header, and error format from upstream specs, source, or real captured bytes—never guess from field names or add speculative fallback parsers (see [contracts](contracts/README.md)). |
| **Nothing that can block runs under a lock its reader needs.** | Never do I/O, network calls, channel sends, or blocking waits while holding a lock another thread/task must acquire. Publish shared state only after initialization, deep-copy mutable reference fields, guard mock/fake test servers against concurrent calls, and run race detectors whenever adding concurrency or timers. |
| **Defaults never override a value the user set.** | Before writing a default or running a config migration, list everywhere that setting is read and test with an explicit user-set value present. Migrations leave explicit user choices alone or state plainly in release notes why not. |
| **A budget is met, not silently raised.** | Size, bundle, latency, or context budgets (such as `AGENTS.md` size limits or core bundle budgets) are met by moving, lazy-loading, or removing code first. Raising a budget names explicit owner approval—never "nothing left to move" and never by deleting explanatory comments. Re-run budget guards after rebasing onto `main`. |
| **A preview or dry run writes nothing.** | Any dry-run, plan, lint, or preview mode has zero side effects on disk, databases, or external services. |
| **Checks cover the edges the change touches.** | Check numeric boundaries, empty/null inputs, cross-platform paths and OS error codes (macOS, Linux, Windows), and stale or concurrent states proportional to risk. |

<!-- Add rows as lessons graduate from LESSONS.md. Each row should state
     a falsifiable check and, in project repos, cite the evidence that promoted it. -->

## Tests

"The tests pass" is not sufficient evidence. A test counts as a **hard
test** only when it meets every rule below that applies.

| Rule | What a reviewer looks at |
| --- | --- |
| **A fix comes with a test that fails without it.** | Put the old code back (or break the guarded invariant by hand) and run the new test: it must fail with a real behavioral `FAIL` naming the broken guarantee. A compile error, skipped test, or unrelated timeout does not count. Record the failing output in the PR and commit body (see [bugfix-red-green](../.agents/skills/bugfix-red-green/SKILL.md)). |
| **Tests use real inputs and cover failure paths.** | Fixtures come from literal real requests, serialized outputs, and files on disk—including missing fields, empty values, defaults, malformed/unreadable files, and error responses. Happy-path synthetic toys are not enough. |
| **Tests check behavior, not implementation.** | Assert what the user or caller observes (domain state, return values, wire/CLI contracts, side effects). Internal refactors and formatting changes should not break tests unless exact bytes are the contract. No mirror assertions (`toString()` dumps or raw log lines). |
| **A test never reaches the live network.** | External APIs, registries, and web pages are served from local loopback test doubles fed with real captured bytes. Dependencies come from lockfiles, never live "latest" lookups. Break the endpoint and confirm no request leaves localhost. |
| **Tests stay out of the real machine.** | Run tests under an isolated temporary `HOME` / state directory with language/package caches pinned so runs stay offline and fast. Never read or write live user configs, credentials, or running services. |
| **Whatever a test starts ends when the test does.** | Every child process, background worker, server, timer, or async refresh started by a test is stopped and awaited before teardown, so it cannot write into the next test's directory or spin indefinitely. |
| **Timing tests leave room on both sides (no wall-clock sleeps).** | Never use `sleep()` or tight wall-clock bounds a loaded CI runner can exceed. Use virtual clocks, deterministic latches, or injected delays (a held write, a late first arrival) to reproduce timing bugs; keep threshold fixtures far from every boundary. |
| **A negative check looks past generated text.** | When asserting a secret, identifier, or removed string is gone, strip random IDs, ports, hashes, timestamps, and synthetic placeholders first—or use a distinctive sentinel token that generated output cannot accidentally spell. |
| **A test that fails on `main` is a bug to fix now.** | "Fails the same on `origin/main`" and "passes when run alone" are never baselines. Fix the root cause in its own commit, or open an issue naming the cause, before shipping on top of it. Re-run suspected flakes repeatedly under race detection before calling them flaky. |
| **A red's issue is read to its last comment, and a patch on it is taken first.** | Before filing, commenting "seen again", or writing a competing fix for a red test, search existing issues by test name and read every comment. Review and build on any existing patch before writing another. |
| **Run the full suite and all guard tests.** | Filtered runs (`-run`, `-k`, single-file runs) skip repo-wide guard tests in `tests/guards/` and cross-package invariants. Run the full suite (or every affected layer plus all guards) at the exact pushed head. |
| **One full suite runs on a machine at a time; records are written only after runs finish.** | Do not run competing full suites on the same host (which causes false timeouts and cache races). Never record "still running at push" or partial counts; wait until the run finishes and name an issue for every red. |

<!-- Add rows as lessons graduate from LESSONS.md. -->

## Acceptance criteria

A change is merged or released only when its PR and commit record show
each applicable item below. **State which checks were run and what they
printed; list any check that was not run as `Not run: <reason>`, never
leave it out.**

1. **A test that fails without the change (`Red -> Green`).** Put the old
   code back and run the new test. It must fail with a genuine behavioral
   `FAIL`, not a compile error or skip. Name the test and what it failed
   with, then restore the change and confirm it passes. Pure documentation
   changes may use `Verification Mode: docs-only` only when zero code,
   config, or script files changed, and must still pass `make gate`.
2. **Tests in a sandbox.** Run tests under a temporary `HOME` / workspace
   with language and package caches pinned so runs never download into temp
   or touch live user configs, credentials, or daemons. Clean up read-only
   cache files when tearing down temp directories.
3. **Formatter, static analysis, build, and full suite (at pushed head).**
   Run formatting checks, linters/static analyzers, builds for every target
   OS/architecture, `make gate`, and the full test suite including
   [guard tests](../tests/guards/README.md). Cross-OS builds often skip
   test files—run cross-OS static analysis or test compilation where
   supported. Use `set -o pipefail` in chained shell commands so piped
   failures never exit `0`. Re-run tests and budget guards **after**
   rebasing onto current `main`.
4. **Cross-surface, UI, and localization checks *(when applicable)*.** A
   change touching shared APIs, layouts, shared selectors/components, or
   user-facing strings runs the full cross-engine and multi-locale UI
   suite—not only the touched screen—including empty/zero-data states. When
   rewording text, grep UI tests for the old string first.
5. **Real use where possible.** A change to an external integration,
   vendor API, platform-specific path (macOS, Linux, Windows, WSL), or
   full request/security middleware stack is verified against the real
   target or full stack in a sandbox. If a real check is not possible,
   state `Not tried: <exact gap>` plainly. What was not tried is never
   built on or told to users as working.
6. **Commit-bound merge record.** Pull the PR head, merge or rebase it
   onto current `main`, and run the acceptance checks on the result before
   merging. Post the reviewed commit SHA and what was run on the PR
   **before** merging, and bind the merge to that exact commit
   (`gh pr merge --match-head-commit <reviewed-sha>`). Any push after
   review invalidates prior approval and requires re-review. Draft PRs
   cannot be merged.
7. **Release verification *(when cutting a release)*.** A tag is not a
   release. A release counts only when:
   - CI finished green on the tagged commit (or a later commit containing
     it)—a cancelled run is not a pass;
   - `git fetch --tags` confirms no duplicate tag exists and the tag sits
     on `main` (an ancestor of `origin/main`);
   - Every expected release binary, asset, or package registry version is
     verified published online before naming the version to anyone;
   - The highest version is marked `Latest`.
   - A PR that only adds tests does not get a release of its own.

## Reviewing a PR

Reviewers follow [peer-review-protocol](../.agents/skills/peer-review-protocol/SKILL.md)
(`Builder != Verifier`, Tier-1 vs. Tier-2 routing, 3-round circuit breaker,
and behavior-bound `HOLD` verdicts) and verify each item below that
applies:

1. **Harm scan first.** For external/community PRs, run the harm scan in
   [contributors.md](contributors.md) *before* executing any code (check
   `.github/`, `CODEOWNERS`, `scripts/`, network additions, credential
   reads, dependencies, binaries, or obfuscated blobs). Stop and escalate
   to a human maintainer if any trigger fires.
2. **Run it.** Pull the head, merge or rebase it onto current `main`
   (resolving conflicts if needed), and run the acceptance checks yourself.
   Reading the diff alone is not a review.
3. **Break it on purpose.** Revert the fix, or break the code it guards in
   several ways, and verify the new tests catch each break. Add a review
   test when an edge or failure path is unguarded.
4. **Check the upstream source, not the PR's account of it.** Read the
   upstream spec, source, or real captured fixtures for external behavior
   rather than trusting the PR summary.
5. **Follow the whole path and its siblings.** Trace callers, state
   transitions, persistence keys, and side effects end-to-end. Grep for
   sibling handlers, routes, adapters, and error messages that share the
   same bug class.
6. **Check platforms, architectures, and narrow classification.** Verify
   word-size conversions, cross-OS error codes and paths, concurrency
   safety, side-effect-free previews, and narrow error classification.
7. **Docs match the source and deliberate decisions stand.** Verify
   affected [subsystem references](subsystems/README.md),
   [contracts](contracts/README.md), and [ADRs](decisions/README.md) are
   updated and every link resolves. Never approve a PR that silently
   reverses a documented maintainer decision.
8. **Audit commit scope and tree cleanliness.** Check
   `git diff <base>..<head> --stat` against the PR goal: only intended
   files may change, with zero unrelated refactors, dropped tests, or
   stale-tree regressions.

## Commits

| Requirement | Standard |
| --- | --- |
| **Subject** | `<area>: <plain behavior the user or caller now sees>` (include the issue number or reporter when applicable). |
| **Body (self-contained record)** | Record *why* the change was made, *what commands ran* (with base/head SHA and pass/fail counts), *which test fails without the change*, and any *`Not tried:`* gaps. Put the record in the commit body—never only in chat or push notes, and grep out any unfilled template placeholders before pushing. |
| **One commit, one goal** | Two reports fixed together or an unrelated bug found on the way go in separate commits, each with its own verification record, so `git revert` and `git bisect` stay clean. |
| **Session-owned worktrees** | Every session works in its own isolated worktree (`make worktree AGENT=<name> TOPIC=<slug>`). Never check out, commit from, or clean another session's worktree or logs. |
| **Clean tree (`origin/main` + delta only)** | After committing, inspect `git show --stat HEAD` to verify only your files changed. Never `git reset --soft` an older worktree onto a newer base (which silently reverts teammates' commits); rebase or cherry-pick cleanly onto current `origin/main`. |

## Project-specific extensions

<!-- Customize this section after cloning the template without weakening
     Sections 1–5 above. -->

- **Language & toolchain rules**: *(e.g., forbidden stdlib calls replaced by internal wrappers, required static-analysis flags, dependency boundaries—pair each with a guard in `tests/guards/`).*
- **UI & design system rules**: *(e.g., mandatory i18n wrapper, forbidden native controls, layout/accessibility invariants, cross-browser visual tests).*
- **Release artifact checklist**: *(e.g., expected release asset count, package registry verification command, post-release smoke check).*

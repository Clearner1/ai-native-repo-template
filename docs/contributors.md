# Community PR review protocol

This protocol applies when reviewing pull requests from external
contributors (anyone not in `CODEOWNERS`). Read this before reviewing a
community PR.

## 1. Harm scan first

Before running any code from a community PR, check for:

- [ ] Workflow changes (`.github/workflows/`, `Makefile`, `scripts/`)
- [ ] Network additions (new outbound calls, DNS, webhooks)
- [ ] Credential reads (`~/.ssh`, `~/.config`, env vars with keys/tokens)
- [ ] New dependencies (check each one's reputation and scope)
- [ ] Encoded blobs (Base64, hex, compressed payloads in source)
- [ ] Removed or weakened security controls

If any are found, **stop the review** and escalate to a human maintainer.

## 2. Close-without-review criteria

Close without detailed review when a PR:

- Reverses a deliberate product or architecture decision
- Resubmits work that was previously rejected for the same reason
- Is one of a burst of low-effort PRs opened within a short window

Leave a one-line comment explaining why.

## 3. Credit

- Use `Co-authored-by:` trailers when incorporating community work.
- Merge community fork branches with original commits intact when
  practical, preserving their authorship.

## 4. Blocking criteria

An author may be blocked from future reviews when:

- 3+ low-value PRs with <30% merge rate
- Repeated resubmissions of rejected changes
- Deception (e.g., hiding harmful changes in large diffs)
- Automated burst-opening of PRs

Document evidence in this file when blocking.

## 5. Watched authors

<!-- Add entries when an author requires extra scrutiny. Format:
| Author | Reason | Date | Evidence |
| --- | --- | --- | --- |
-->

## 6. Extra care list

<!-- Authors not blocked but reviewed more strictly: every line, harm check
     on typo fixes, --match-head-commit on merge. Format:
| Author | Reason | Date |
| --- | --- | --- |
-->

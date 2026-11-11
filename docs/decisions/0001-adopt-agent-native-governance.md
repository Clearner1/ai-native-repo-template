# ADR 0001: Adopt Agent-Native Repository Governance

- **Date**: 2026-11-11
- **Status**: Accepted
- **Deciders**: @enaz-user, @CarbonACP, @James

## 1. Context & Problem Statement
When AI agents author the majority of code changes, traditional workflows break in four predictable ways:
1. Human line-by-line diff review becomes either a queue bottleneck or an unverified rubber stamp.
2. Monolithic `AGENTS.md` files bloat context windows while monolithic `CHANGELOG.md` files cause constant merge conflicts.
3. Passing test suites create false confidence when agents accidentally write tautological ("green-wired-to-nothing") assertions.
4. Raw CLI/test failures force agents to burn context guessing recovery commands.

## 2. Alternatives Considered & Rejected
1. **Human-Reviews-Every-Line Gate** — *Rejected because:* reading speed cannot match multi-agent writing speed; attention fatigue degrades safety on genuinely critical paths (`migrations/`, `auth/`, CI).
2. **Single Shared Memory / Giant Root Prompt** — *Rejected because:* dilutes critical invariants in large contexts and causes stale instructions to masquerade as active tasks in smaller contexts.
3. **Trusting Raw Line Coverage** — *Rejected because:* line execution does not prove behavioral assertions would turn red on a regression.

## 3. Decision
1. Keep `AGENTS.md` as a compact (< 16 KB) Iron-Rule index routing to on-demand `.agents/skills/*/SKILL.md` playbooks.
2. Enforce `Builder != Verifier` with mandatory **Red -> Green Reverse Verification** on PRs and `CODEOWNERS` human gates on sensitive paths.
3. Evaluate CI governance scripts from the default branch (`main`) so feature branches cannot weaken their own gates.
4. Require per-PR changeset fragments under `change-logs/unreleased/changesets/` and AX-formatted `Next action:` error outputs across `scripts/verify/`.

## 5. Verification & Rollback Signal
- Verified continuously by `.github/workflows/agent-governance-gate.yml` (`make gate` and `pr-contract-check.sh`).

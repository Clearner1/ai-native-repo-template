# AI-Native Software Repository Template

A language-agnostic GitHub repository template designed for **high-velocity human + multi-agent software engineering**.

Distilled from battle-tested practices where small human teams ship hundreds of pull requests per week alongside persistent AI agents—without letting codebase entropy, flaky tests, merge collisions, or rubber-stamp code reviews erode system predictability.

---

## Why This Template Exists

Traditional repository layouts assume a human at a keyboard writing a few branches a week and another human reading every line of every diff. Once AI agents write code 10x faster than humans can read it, **line-by-line human diff review either becomes a crippling bottleneck or degrades into fake confidence (rubber-stamping).**

This template shifts quality and trust upstream and into deterministic repository gates:

1. **Repo-as-Context (Progressive Disclosure)**: Instead of a bloated instruction file that burns context tokens, `AGENTS.md` holds only battle-scarred **Iron Rules**, cross-file checklists, and a router to on-demand `.agents/skills/*/SKILL.md` playbooks.
2. **Anti-Entropy Architecture Contracts (`docs/contracts/`)**: Enforces hard boundaries—such as separating **Immutable Facts** from **Mutable Whims** (with serving layers strictly treated as rebuildable caches), **Single Contract Oracles**, and **Compile-Time Exhaustiveness**.
3. **Intent & Decision History (`docs/decisions/`)**: Code mutations are cheap; *why* a design was chosen and *which alternatives were rejected* is the scarce context future humans and agents actually need.
4. **Builder != Verifier + Reverse Verification**: The session that writes a change never approves it. Every bugfix or behavior change requires a recorded **Red -> Green Reverse Check** (temporarily reverting the fix to prove the new test actually fails) plus periodic **Mutation Testing** on core modules.
5. **AX-Friendly Tooling (`scripts/verify/`)**: Every repository script is treated as a 1D Agent Experience (AX) surface—printing localized failure snippets and an explicit `Next action: <command>` handle instead of raw IDs or 5,000-line stack dumps.
6. **Zero-Conflict Concurrency (`change-logs/` + `git worktree`)**: Parallel agents work in isolated `git worktree` checkouts (`agent/<name>/<topic>`) sharing one object store, and drop per-PR fragments into `change-logs/unreleased/changesets/` instead of fighting over `CHANGELOG.md`.

---

## Repository Layout

```text
.
├── AGENTS.md                              # Root index: Iron Rules, cross-file checklists, test rules & skill router
├── CODEOWNERS                             # Hard human-approval gates on CI, migrations, contracts & security paths
├── Makefile                               # Standard AX-friendly entrypoints (`make gate`, `make new-changeset`, etc.)
├── .agents/
│   └── skills/                            # On-demand SOPs loaded only when performing that specific workflow
│       ├── feature-contract/SKILL.md      # Pre-code Triangle Contract (Outcome -> Invariants -> Falsifiable Gate)
│       ├── bugfix-red-green/SKILL.md      # Mandatory Red -> Green reverse verification & property pinning
│       ├── peer-review-protocol/SKILL.md  # Blind verifier checklist, 3-round circuit breaker & behavior-impact bar
│       ├── release-changeset/SKILL.md     # Conflict-free changeset fragments & automated release-note rollup
│       └── api-contract-sync/SKILL.md     # Cross-repo / schema oracle pinning & zero defensive field guessing
├── .github/
│   ├── AGENTS_GUIDE.md                    # PR admission rules (evaluated from default branch `main` in CI)
│   ├── pull_request_template.md           # Enforces Intent, Rejected Alternatives, Reverse Check & Trace Square
│   └── workflows/
│       └── agent-governance-gate.yml      # Automated CI gate for structure, PR contract & sensitive-path alerts
├── docs/
│   ├── new-agent-landing.md               # Day-1 onboarding map for a fresh human or agent teammate
│   ├── contracts/                         # Authoritative domain invariants & boundary contracts
│   │   ├── README.md
│   │   └── 0001-facts-vs-whims.md
│   └── decisions/                         # Lightweight ADRs preserving Intent & Decision History
│       ├── README.md
│       ├── 0000-template.md
│       └── 0001-adopt-agent-native-governance.md
├── change-logs/
│   ├── README.md                          # Conflict-free release note workflow
│   └── unreleased/changesets/             # One markdown file per user-facing PR
└── scripts/
    └── verify/                            # Zero-dependency POSIX/Bash governance & helper scripts
        ├── repo-gate.sh                   # Validates governance files, skill links, contracts & changesets
        ├── pr-contract-check.sh           # Validates PR body sections & reverse-verification evidence
        ├── new-changeset.sh               # Scaffolds a timestamped changeset fragment
        └── new-worktree.sh                # Creates an isolated `agent/<name>/<topic>` git worktree
```

---

## Quick Start

### 1. Create Your Repository from This Template
Click **Use this template** on GitHub, or run via GitHub CLI:

```bash
gh repo create my-org/my-system --template Clearner1/ai-native-repo-template --private --clone
cd my-system
```

### 2. Customize Placeholders for Your Team
1. Update **`CODEOWNERS`** with your human maintainers' GitHub handles (e.g., `@your-org/core-maintainers`).
2. Wire your language toolchain's build, lint, typecheck, test, and mutation-test commands into **`Makefile`** (`build`, `test`, `mutate`) and **`AGENTS.md`**.
3. Run the local governance gate to verify everything is wired cleanly:

```bash
make gate
```

### 3. Recommended GitHub Branch Protection Settings (`main`)
To ensure agents cannot weaken the rules they are graded against, configure these settings on `main`:
- **Require a pull request before merging**
  - Enable **Require review from Code Owners** (enforces human sign-off on `.github/`, `CODEOWNERS`, `scripts/verify/`, `docs/contracts/`, and `migrations/`).
  - Enable **Dismiss stale pull request approvals when new commits are pushed** (approvals bind strictly to a reviewed commit SHA).
- **Require status checks to pass before merging**: require `governance-gate`.
- **Require merge queue** (recommended once parallel agent throughput exceeds ~20 PRs/week).

---

## Human vs. Agent Division of Labor

| Responsibility | Primary Owner | Mechanism |
| :--- | :--- | :--- |
| **Problem Framing & Architecture Contracts** | **Human + Lead Agent** | Align on a Prompt Request / Triangle Contract before writing code; record tradeoffs in `docs/decisions/`. |
| **Implementation, Unit Tests & Reverse Check** | **Builder Agent** | Isolated `git worktree` (`agent/<name>/<topic>`), exhaustive matching, virtual clocks, Red -> Green proof. |
| **Routine PR Verification** | **Verifier Agent** | Fresh-context session (*Builder != Verifier*); capped at 3 review rounds before escalating to a human. |
| **Entropy Monitoring & Boundary Refactoring** | **Human** | Watch bug clusters, surviving mutants, and seam merge collisions; tighten types/contracts when agents stumble. |
| **Sensitive Paths & Production Ignition** | **Human Only** | `CODEOWNERS` gates schema migrations/CI/auth; production release button stays exclusively human-triggered. |

---

## License

Released under the [MIT License](LICENSE).

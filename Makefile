# AX-Friendly Repository Entrypoints
# Every command prints actionable errors with a `Next action:` recovery step.

.PHONY: help gate check-pr new-changeset worktree test mutate

help:
	@echo "Available targets:"
	@echo "  make gate                              Run repository structure, skill-index, contract & changeset checks"
	@echo "  make check-pr FILE=<pr-body.md>        Validate a PR description file against the PR contract"
	@echo "  make new-changeset SLUG=<short-topic>  Create a conflict-free changeset fragment under change-logs/unreleased/"
	@echo "  make worktree AGENT=<name> TOPIC=<t>   Create an isolated git worktree on branch agent/<name>/<t>"
	@echo "  make test                              Hook for your language test suite (replace in your project)"
	@echo "  make mutate                            Hook for your mutation testing runner (replace in your project)"

gate:
	@./scripts/verify/repo-gate.sh

check-pr:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: missing FILE=<path-to-pr-body.md>."; \
		echo "Next action: make check-pr FILE=.github/pull_request_template.md"; \
		exit 1; \
	fi
	@./scripts/verify/pr-contract-check.sh "$(FILE)"

new-changeset:
	@./scripts/verify/new-changeset.sh "$(SLUG)" "$(SUMMARY)"

worktree:
	@./scripts/verify/new-worktree.sh "$(AGENT)" "$(TOPIC)"

test:
	@echo "Info: no language test suite configured yet. Wire your test runner in Makefile (target: test) and AGENTS.md."
	@./scripts/verify/repo-gate.sh

mutate:
	@echo "Info: wire your mutation testing tool here (e.g., cargo-mutants, mutmut, Stryker, pitest) for core domain modules."

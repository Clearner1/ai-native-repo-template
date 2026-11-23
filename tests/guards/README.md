# Guard tests

Guard tests are automated tests that **read constraints from the actual
codebase**, not from hand-maintained lists. They enforce structural
invariants that text rules cannot: when a developer adds a new route,
agent, enum variant, or translation key, a guard test fails if the
corresponding registration, test, or documentation is missing.

## Why guard tests exist

Text rules in `AGENTS.md` and `docs/code-standards.md` tell agents what to
do, but agents forget or skip steps. Guard tests turn "you must also
update X" into a CI failure that blocks the merge.

## The guard colocation principle

When a guard test keeps being missed—agents run their own package's tests
but not the package where the guard lives—**move a copy of the guard into
the package where the work happens**. The progression:

1. **Central guard** in a shared test package → agents miss it.
2. **Collocated guard** duplicated into each package that triggers it →
   agents hit it on every `test ./...`.
3. **Build-time guard** using the language's type system (exhaustive
   switches, sealed interfaces) → impossible to miss.

Prefer build-time guarantees over test-time guards, and test-time guards
over documentation.

## Guard test patterns

### Registration guard
Ensures every X is registered in Y.

```
Example: TestEveryRouteHasACommand
  - Walk all HTTP routes defined in the router
  - Check each one appears in the CLI command registry
  - Fail with the unregistered route's name
```

### Translation guard
Ensures every user-facing string has translations.

```
Example: TestEveryFieldLabelHasTranslation
  - Walk all struct field labels/UI strings
  - Check each has entries in every locale file
  - Fail with the missing key and locale
```

### Dependency boundary guard
Ensures forbidden imports are not used.

```
Example: TestNoDirectExecCommand
  - Walk all source files with AST/regex
  - Check no file calls exec.Command directly (must use proc.Command)
  - Fail with the file and line number
```

### Budget guard
Ensures a file or bundle stays within a size limit.

```
Example: TestCoreScriptBudget
  - Measure the size of the core JS bundle
  - Compare against the budget constant
  - Fail if exceeded, naming what must be moved out
```

### Eager initialization guard
Ensures no package-level expensive operations.

```
Example: TestNoEagerPackageRegexps
  - Walk all source files
  - Check no package-level regexp.MustCompile (use lazy init)
  - Fail with the file and line number
```

## Adding a new guard

1. Identify the structural invariant (from `AGENTS.md`, `code-standards.md`,
   or a repeated lesson in `LESSONS.md`).
2. Write the test so it **reads the codebase** to find violations—do not
   maintain a hand-written list of "known good" items.
3. Place it in the package closest to where violations are introduced.
4. If violations keep appearing in other packages, collocate the guard.
5. Register the guard in this README with its purpose and location.

## Guard registry

<!-- Add guards as they are created. Format:
| Guard | Package/File | What it enforces |
| --- | --- | --- |
-->

## Test isolation (testenv pattern)

Guard tests and all other tests should run in an isolated environment:

- **Temporary HOME**: Prevents tests from reading/writing real user config.
- **Pinned caches**: Language package caches (`GOPATH`, `node_modules`,
  `.venv`, etc.) are pinned to avoid re-downloading on every run.
- **Process lifecycle**: Whatever a test starts, it stops before returning.
- **One suite at a time**: A full test suite on a machine waits for any
  other running suite to finish.

Provide a `testenv` helper or equivalent in your language that sets this up
in `TestMain` or the test framework's global setup.

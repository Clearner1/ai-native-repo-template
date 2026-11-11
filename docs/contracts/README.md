# Architectural Contracts (`docs/contracts/`)

Files in this directory are **executable design invariants**, not aspirational wiki pages. Every implementation PR must obey active contracts, and changing a contract requires Tier-2 human sign-off (`CODEOWNERS`).

## Core Principles

1. **Contract Oracle Over Defensive Guessing**:
   - Define exact field names, nullability, error codes, and state transitions in one authoritative schema/contract. Consumers must fail fast on malformed data rather than guessing alternate field names.
2. **Make Illegal States Unrepresentable**:
   - Prefer sum types / tagged unions and compile-time exhaustive matching over boolean flag combinations or stringly-typed status fields.
3. **Seam Collisions Signal Missing Contracts**:
   - When multiple agents repeatedly conflict on the same file or bugs cluster in one module, the module boundary is misleading its callers. Refactor the boundary and codify the new contract here.

## Active Contracts

- [`0001-facts-vs-whims.md`](0001-facts-vs-whims.md) — Strict separation of immutable domain facts, mutable user whims, and rebuildable serving caches.

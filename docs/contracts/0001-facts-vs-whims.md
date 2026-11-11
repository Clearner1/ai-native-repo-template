# Contract 0001: Facts Live Apart from Whims

- **Status**: Active (Enforced)
- **Scope**: All persistence schemas, state stores, event pipelines, and read-model caches

---

## 1. The Problem

When features ship rapidly, agents are tempted to satisfy new product switches (mute, pin, archive, hide, filter, read-cursor) by baking those flags directly into precomputed serving tables alongside immutable domain events. Every toggle flip then forces expensive state rebuilds, race conditions, and irreversible coupling.

## 2. Non-Negotiable Invariants

1. **Immutable Facts**:
   - Domain events that happened in the world (e.g., *message sent at `t`*, *commit pushed with `sha`*, *invoice issued*) are stored append-only and never mutated to reflect viewer preferences.
2. **Mutable Whims**:
   - Ephemeral or per-actor preferences (e.g., *channel muted*, *notification snoozed*, *panel collapsed*) live in separate, lightweight state tables keyed by actor and target.
3. **Serving Projections Are Rebuildable Caches**:
   - Materialized views, counters, and inbox summaries are strictly **rebuildable caches**, never the source of truth. Dropping and recomputing a serving projection from Facts + Whims must yield the exact same state.
4. **Filter at Read / Projection Boundary**:
   - Combine Facts and Whims at query or projection evaluation time rather than mutating historical Fact rows.

## 3. Falsifiable Review Check

A PR violates this contract if:
- Adding a user preference or visibility toggle mutates historical event/fact records; or
- A materialized cache table holds state that cannot be deterministically reconstructed if truncated.

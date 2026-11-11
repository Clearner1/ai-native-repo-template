# Intent & Decision History (`docs/decisions/`)

When code generation is cheap, a thousand code commits often carry less useful context than the single architectural argument that produced them.

Future humans and fresh-session agents rarely struggle to read *what* the code currently does—they struggle to know:
- **Why** does this boundary exist?
- **What constraints** were we operating under?
- **Which plausible alternatives** were already tried or rejected, and why?

## When to Add an ADR

Create a numbered file (`NNNN-short-slug.md`) from [`0000-template.md`](0000-template.md) whenever a change:
1. Introduces or alters a cross-module boundary, storage model, or external dependency;
2. Rejects an obvious-looking design that future agents might otherwise re-invent; or
3. Resolves a recurring bug cluster or multi-agent merge-collision seam.

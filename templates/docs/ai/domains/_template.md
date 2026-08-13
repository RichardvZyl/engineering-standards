# Domain — <AREA>

<!-- SEEDED ONCE from engineering-standards. Copy this file per bounded area, name it
     <area>.md, and add a row to the routing table in AGENTS.md. Delete this template
     itself once you have a real one — an unfilled template in a domains directory
     teaches the next reader that the directory is decorative. -->

> **Routed from:** `AGENTS.md` · **Governs:** `src/<Area>/**`
> **Last ruling:** <!-- YYYY-MM-DD -->

## What this area is responsible for

<!-- REPLACE: two or three sentences. The boundary, stated so that "does X belong here?"
     has an answer. -->

## Vocabulary

**One term, one meaning, inside this area.** Where a word means something different in another
area, say so explicitly in both — a term silently doing two jobs is the failure this document
exists to prevent.

| Term | Means here | Does *not* mean | Notes |
|---|---|---|---|
| <!-- Posting --> | <!-- an immutable ledger entry, already committed --> | <!-- a pending instruction — that is an Instruction --> | |

Rules for this table:

- Define a term the first time it appears in code, schema or conversation — not the third.
- **Record the term you rejected**, and why. The rejected name is what stops the discussion
  being reopened every quarter.
- If a term appears in the database schema, the type name and the column name use it identically.
  A domain word that changes spelling on the way to storage is two words.

## Invariants

What must always be true in this area. These are the things a change is checked against.

- <!-- e.g. "A posting is never updated or deleted; a correction is a new opposing posting." -->
- <!-- e.g. "The sum of postings for an account equals its balance row, after the fold." -->

State them as assertions, and state what enforces each one — a constraint, a trigger, a code
path, or nothing but discipline. **An invariant enforced by nothing is a wish**, and labelling it
as such is more useful than pretending otherwise.

## Boundaries

| Neighbour | What crosses | Shape |
|---|---|---|
| <!-- Billing --> | <!-- account identifiers only --> | <!-- published event --> |

What this area **does not** own is worth writing down; it is the question that actually causes
argument.

## Open questions

Terms or rules that are genuinely undecided. Keep them here rather than resolving them silently —
a contradiction recorded is information, and a contradiction resolved by assertion is a mapping
nobody can check.

- <!-- question · what depends on it · who decides -->

## Rulings

Decisions made about this vocabulary. Anything **hard to reverse** — a term that reaches the
schema, a public contract, or another area — is promoted to an ADR in `docs/adr/` and linked
here rather than living only in this file.

| Date | Ruling | ADR |
|---|---|---|
| | | |
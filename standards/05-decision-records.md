<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 05 — Decision records

## Location

**ADRs live in `docs/adr/`.** Not in an agent-state directory, not in a wiki, not in a ticket.
They are versioned with the code whose shape they explain, because that is the only place they
stay true to it.

Files are named `NNNN-kebab-case-title.md`, numbered sequentially from `0001`. The number is
permanent and follows the identifier rules in [`04`](./04-documentation-layout.md): never reused,
never renumbered, retained when superseded.

## When one is required

An ADR is required when the decision is **hard to reverse** or when a later reader would
otherwise have to re-derive it. Concretely:

- a public contract — API surface, message schema, stored procedure signature
- a persistence or tenancy shape
- a concurrency or isolation strategy
- adopting, replacing or removing a significant dependency
- a departure from these standards

The test is not importance; it is **cost to reverse**. A decision that is trivial to undo does not
need a record even if it was debated at length. A decision that quietly constrains everything
after it does, even if it took thirty seconds.

Stated against the scale below: **anything rated above `Reversible` needs a record.**

**Not every decision needs one.** A repository whose `docs/adr/` is full of records nobody
consults has trained its readers to skip the directory, which costs more than the missing records
would have.

## Cost to reverse

Every record carries a **`Cost to reverse`** field in its header, on this three-value scale, with
a clause naming what makes it that. The bare word is not the point; the clause is.

| Rating | Means | Undoing it costs |
|---|---|---|
| `Reversible` | A revert and a deploy. No migration, no data persisted in a shape the revert leaves behind, no contract anyone outside the repository has consumed. | Hours |
| `Costly` | Undoable, but the undo is a piece of work in its own right — a migration, a backfill, a coordinated deploy, a deprecation window for consumers. Bounded, plannable, and nothing is lost. | A planned change |
| `One-way` | Not undoable within reason. Data has been written in a shape that cannot be reconstructed, a contract is in third parties' hands, ledger entries exist under the new rule, or a vendor holds the data. Escaping means a migration that loses information, or a second decision living alongside the first. | A project, or never |

**Rate the shipped state, not the branch.** A change that is a clean revert today and a backfill
the moment it reaches production is `Costly`. The question the field answers is what undoing it
costs once it is real, because that is when someone will want to.

**The rating is of the chosen option, and it matches that option's row in Options considered.**
A header saying `Reversible` above a table saying the storage shape changes is wrong in one of the
two places, and a reader cannot tell which.

**A `One-way` record names the escape in its Consequences** — what would have to be built to get
out, and roughly what that costs. Not to plan it, but so the next reader inherits the exit rather
than rediscovering there is none.

**The rating is never edited to reflect the passage of time.** It records the cost as at the
`Date`. Costs rise as data accumulates; that is expected, and correcting the field would destroy
the evidence of what was known when the decision was taken. Where a decision has hardened past its
rating in a way that changes what should happen next, that is a new record citing this one.

## Format

```markdown
# NNNN — Title

- **Status:** Proposed | Accepted | Superseded by [NNNN](./NNNN-...md) | Deprecated
- **Date:** YYYY-MM-DD
- **Cost to reverse:** Reversible | Costly | One-way — <what makes it that>

## Context

What was true that forced a decision. Constraints, volumes, obligations, the deadline.
Written so it still makes sense to someone who was not there.

## Options considered

Every realistic option, including do-nothing. Per option: upside, downside, cost to reverse.

## Decision

What was chosen, in the present tense.

## Consequences

What this makes easy, what it makes hard, and what now has to be true elsewhere.
Include the consequences that are unwelcome — those are the ones worth recording.
```

**Options considered is not optional.** A record with one option is a note, not a decision. The
rejected options are the part a future reader needs, because their question is almost always
"why not the obvious thing?"

## Status and supersession

- A record is **never edited to reflect a new decision, and never deleted.** It is marked
  `Superseded by` and the new record is written. The old reasoning is evidence about what was
  known at the time.
- `Proposed` records are legitimate and useful. A decision under discussion is better recorded as
  proposed than held in a thread.
- **Contradictions between records are recorded, not silently resolved.** Where two accepted
  records disagree, say so in both and resolve it deliberately in a third.

## Index

`docs/adr/README.md` lists every record with its number, title, status and cost to reverse. It is
updated in the same commit that adds a record, and CI fails if a record is missing from it — an
index maintained by good intentions is an index that is wrong within a month.

Cost to reverse is in the index rather than only in the records because it is the column a reader
scans for. Someone arriving at a codebase wants the `One-way` rows first: they are the constraints
they are inheriting, and the rest of the directory is context they can read later.
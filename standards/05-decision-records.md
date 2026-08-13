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

**Not every decision needs one.** A repository whose `docs/adr/` is full of records nobody
consults has trained its readers to skip the directory, which costs more than the missing records
would have.

## Format

```markdown
# NNNN — Title

- **Status:** Proposed | Accepted | Superseded by [NNNN](./NNNN-...md) | Deprecated
- **Date:** YYYY-MM-DD

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

`docs/adr/README.md` lists every record with its number, title and status. It is updated in the
same commit that adds a record, and CI fails if a record is missing from it — an index maintained
by good intentions is an index that is wrong within a month.
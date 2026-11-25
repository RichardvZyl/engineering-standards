# 0001 — Example: use this file as the shape, then replace it

- **Status:** Accepted
- **Date:** 2026-01-01
- **Cost to reverse:** Costly — one backwards-compatible migration and a backfill of the folded
  totals; no ledger rows change and no published contract moves

<!-- SEEDED ONCE. Copy this file for a real decision, then delete it and its index row.
     It is written out in full rather than left as headings, because an empty template
     teaches the format but not the standard of evidence. -->

## Context

What was true that forced a decision — constraints, volumes, obligations, deadline. Write it so
it still makes sense to someone who was not in the room, and who is reading it two years from now
to work out whether it still applies.

State the numbers. "High volume" is not a constraint a later reader can test against; "peak 4,000
inserts per second against one table, growing 15% per quarter" is.

## Options considered

Every realistic option, **including do-nothing**. Cost to reverse is usually what decides it, and
it is the column most often left out.

| Option | Upside | Downside | Cost to reverse |
|---|---|---|---|
| Do nothing | No work; no new failure modes | The contention gets worse on its current curve | Reversible — none |
| Option B *(chosen)* | ... | ... | Costly — one backwards-compatible migration and a backfill |
| Option C | ... | ... | One-way — the storage shape changes and history is rewritten under it |

**The chosen row's rating is the one in the header.** If the two disagree, the record is wrong in
one of them and a reader cannot tell which.

## Decision

What was chosen, in the present tense: "Writes are appended to a per-account partition and folded
on a schedule." Not "we decided that we would probably..."

Name the one line of reasoning that actually settled it.

## Consequences

What this makes easy, what it makes hard, and what now has to be true elsewhere.

**Include the unwelcome consequences.** Those are the ones worth recording — a consequences
section listing only benefits is a sales pitch, and the next reader will discover the costs
anyway, without the warning.

- Reads of the running total now go through the fold, which is eventually consistent by up to
  <N> seconds. Anything requiring an exact instantaneous total must say so explicitly.
- The fold job is now on the critical path for month-end and needs monitoring.

<!-- If this record were rated One-way, the escape belongs here: what would have to be built to
     get out of it, and roughly what that costs. Not a plan — an inheritance, so the next reader
     does not have to discover for themselves that there isn't one. -->

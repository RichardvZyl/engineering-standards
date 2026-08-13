# Architecture decision records

Records are numbered sequentially and **never renumbered, reused or deleted**. A superseded
record stays, marked `Superseded by`, because the reasoning it captured is evidence about what
was known at the time.

Format and the "when is one required" test:
[`standards/05-decision-records.md`](../../standards/05-decision-records.md). The short version:
required when the decision is **hard to reverse**, not when it feels important.

**This index is updated in the same commit that adds a record.** CI fails if a record on disk is
missing a row here — an index maintained by good intentions is wrong within a month.

| # | Title | Status | Date |
|---|---|---|---|
| [0001](./0001-example.md) | Example — record the shape, then delete this row | Accepted | 2026-01-01 |

<!-- Add newest at the bottom. Status is one of:
     Proposed | Accepted | Superseded by NNNN | Deprecated -->

## Creating one

1. Copy `0001-example.md` to the next number.
2. Fill in Context, Options considered, Decision, Consequences.
3. Add the row above, in the same commit.

**Options considered is not optional.** A record with one option is a note. The rejected options
are what a future reader actually needs, because their question is almost always "why not the
obvious thing?"
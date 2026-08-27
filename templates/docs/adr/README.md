# Architecture decision records

Records are numbered sequentially and **never renumbered, reused or deleted**. A superseded
record stays, marked `Superseded by`, because the reasoning it captured is evidence about what
was known at the time.

Format and the "when is one required" test:
[`standards/05-decision-records.md`](../../standards/05-decision-records.md). The short version:
required when the decision is **hard to reverse**, not when it feels important — anything rated
above `Reversible` needs a record.

**This index is updated in the same commit that adds a record.** CI fails if a record on disk is
missing a row here — an index maintained by good intentions is wrong within a month.

| # | Title | Status | Cost to reverse | Date |
|---|---|---|---|---|
| [0001](./0001-example.md) | Example — record the shape, then delete this row | Accepted | Costly | 2026-01-01 |

<!-- Add newest at the bottom. Status is one of:
     Proposed | Accepted | Superseded by NNNN | Deprecated
     Cost to reverse is one of: Reversible | Costly | One-way — and must match the record's
     header. The scale is defined in standards/05-decision-records.md. -->

**Read the `One-way` rows first.** They are the constraints this codebase has already committed
to; the rest is context that can wait.

## Creating one

1. Copy `0001-example.md` to the next number.
2. Fill in Context, Options considered, Decision, Consequences.
3. Rate the cost to reverse of the option you chose, in the header, with a clause saying what
   makes it that — and check it against that option's row in the table.
4. Add the row above, in the same commit.

**Options considered is not optional.** A record with one option is a note. The rejected options
are what a future reader actually needs, because their question is almost always "why not the
obvious thing?"
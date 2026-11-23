<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 02 — Database standards

**This file owns the rule: what must be true.**

It does not own the review checklist. How to spot a breach of these rules in a diff lives in
[`reference/dotnet-sql-baseline.md`](./reference/dotnet-sql-baseline.md), which is vendored
alongside this file — so a rule and its detection procedure version together and arrive in the
same sync. Where a rule below needs a detection procedure, the baseline carries it rather than
this file restating it. Three copies of the same guidance is how two of them go stale.

Rules are stated in the present tense because they are not advice.

## Types

**Money is `decimal`. Never `float`, never `double`, never a floating-point type by another
name.** The precision and scale are chosen for the currency and stated in the schema, not left
to a default. A rounding rule that is applied in application code but not enforced in the schema
will be applied inconsistently the first time a second application writes to the table.

Dates and times carrying business meaning are stored with an explicit offset or in UTC with the
convention documented in the schema. "The server's local time" is not a time zone policy.

## Every query carries a tenant predicate

Restated from [`01`](./01-architecture-defaults.md) because this is where it is enforced. The
predicate is applied by a mechanism a developer cannot bypass by forgetting — a global filter, a
row-level security policy, a view. A convention that relies on every author remembering will be
breached, and the breach is a data-protection incident rather than a bug.

Ad-hoc scripts, reports, exports and backfills are queries. They are the usual site of the
breach, because they are written outside the application's access path.

## Isolation is stated, never assumed

**Every transaction's isolation level is a decision that was made.** Snapshot-based read
committed and serializable have different failure modes, and inheriting whichever the connection
happened to default to is not a choice.

- **Design to avoid deadlocks, not merely to catch them.** Consistent lock ordering across code
  paths is the primary tool; a retry loop is a mitigation for the residue, not a design.
- **A lost update is a correctness bug, not a race to be tolerated.** Where two writers can
  touch a row, guard it with optimistic concurrency and handle the conflict explicitly.
- **Long transactions are a defect.** A transaction held open across a network call, a user
  interaction, or an external service is a lock held for an unbounded time.
- Transaction boundaries are explicit and visible at the call site. A boundary implied by a
  framework's ambient behaviour is a boundary nobody reviews.

## Predicates are SARGable

A predicate that wraps the indexed column in a function or an implicit conversion cannot seek.

- No function application on the column side of a comparison.
- **Parameter types match column types.** An implicit conversion on a join or filter column
  silently discards an index and is invisible unless the plan is read.
- Correlated subqueries are rewritten as joins where the rewrite is equivalent; `EXISTS` is
  preferred to `IN` against a subquery.
- Scalar user-defined functions do not appear in hot paths.

## Indexing is deliberate

An index is chosen against a known access path and justified. Clustered key, covering columns and
filtered predicates are decisions with names, not defaults.

- **Watch last-page insert contention.** A monotonically increasing key on a high-insert table
  concentrates every insert on one page. Where insert rate makes this bite, use a non-sequential
  key, hash-partition the hot table, or tune fill factor — and record which, because the next
  reader will otherwise assume the key was chosen carelessly.
- Every index is a write cost. An index nobody's plan uses is pure overhead, and unused indexes
  are removed rather than kept for comfort.
- **Fragmentation and statistics are planned for**, not discovered during an incident.

## Scale

- **Partition by date or tenant** where volume warrants, chosen against the queries that
  actually run.
- **Cold data is archived progressively** to satisfy retention obligations without leaving the
  hot table carrying years of rows.
- Memory-optimised structures are considered for genuinely high-contention paths, and only after
  the contention is measured.

## Verify with the plan, not with intuition

**A performance claim is supported by the execution plan, logical reads, and wait statistics.**
Not by reasoning about what the engine ought to do. This applies to a claim that something is
fast as much as to a claim that something is slow.

A change to a hot query is accompanied by the before and after plan shape. "It looks better" is
not a measurement, and a plan that changed shape under a different parameter is the usual reason
a fix does not hold.

## Migrations

- A migration is **forward-only and idempotent**, and it is tested against a copy of realistic
  data volume — not an empty schema, where every migration is fast.
- A destructive change is a **two-phase deployment**: stop writing, then remove. A migration that
  drops a column the currently deployed application still writes is an outage.
- A backfill is **batched and resumable**, and it does not hold a single transaction over the
  whole table.

## Engine differences are load-bearing

Where more than one engine is in use, the differences are not cosmetic. A lost update that blocks
on one engine can complete silently on another; a retry that is unnecessary under one isolation
implementation is mandatory under a different one. Reasoning validated against one engine is not
evidence about the other — verify against the engine actually deployed.
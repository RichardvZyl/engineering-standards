<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# .NET / SQL review baseline

**This is the review checklist — how to spot a breach in a diff.** The rules themselves live in
[`02-database-standards.md`](../02-database-standards.md), which owns what must be true; this
file owns how to notice that it is not. It sits under `reference/` rather than taking a number
because it is not a peer of the numbered standards — it is the detection procedure for one of
them.

Covers **SQL Server and PostgreSQL**. Items marked *(SQL Server)* or *(Postgres)* apply to one
engine only — check which provider the diff uses before flagging them.

Every item is a **labelled heuristic** — "possible lost update" — not a hard violation. A
documented repo convention or an accepted ADR always overrides. Skip anything the analyzers
already enforce; where warnings-as-errors is applied, the build is the gate and re-flagging by
hand is noise.

Ordered by what a miss costs. Group A corrupts data, and is where review attention belongs.

---

## A. Correctness under concurrency

Failures here are invisible in test and appear under load, which is why they are worth a human's
attention and not a linter's.

- **Lost update** — entity read, mutated in memory, saved, with no concurrency token
  (SQL Server `rowversion`/`[Timestamp]`; Postgres `xmin` via `.UseXminAsConcurrencyToken()`; or a
  version column checked in the `WHERE`). Two writers, last one wins, silently — and on Postgres it
  happens **with no blocking at all**, so there is no symptom until the data is wrong. → Add the token and handle `DbUpdateConcurrencyException`. *Spot it:* a `SaveChanges`
  on an entity fetched earlier in the same method.
- **Check-then-act race** — `if (!exists) { insert }`, or read-then-decide across two statements
  without a transaction or a unique constraint. → Make it atomic: unique index plus catch, or a
  single upsert — `MERGE` on SQL Server, `INSERT … ON CONFLICT` on Postgres. *Spot it:* an `Any()`/`FirstOrDefault()` guarding a write.
- **Isolation level assumed, not stated** — code that only holds under `SERIALIZABLE` running at
  the default `READ COMMITTED`, or a `TransactionScope` with no explicit level. → State it, and say
  why in a comment. **Engine-dependent:** SQL Server `READ COMMITTED` is lock-based (unless RCSI is
  on); Postgres is an MVCC snapshot, so the same code behaves differently.
- **Postgres `SERIALIZABLE` with no retry loop** — SSI does not block, it raises `40001` at commit.
  Code ported from SQL Server sets the level expecting blocking and never handles the failure. →
  Retry on `SqlState` `40001` (serialization) and `40P01` (deadlock).
- **Sync-over-async** — `.Result`, `.Wait()`, `.GetAwaiter().GetResult()`. Deadlocks under a
  synchronization context and burns a thread-pool thread regardless. → `await`.
- **`async void`** outside an event handler — exceptions cannot be caught by the caller and become
  unhandled. → `async Task`.
- **Fire-and-forget** — a `Task` not awaited and not observed. Failures vanish. → Await, or hand it
  to a hosted service with logging.
- **`CancellationToken` dropped** — accepted at the boundary, not threaded through to the query or
  HTTP call. → Pass it down; an un-cancellable request outlives its caller.
- **Retry over a non-idempotent operation** — a retry policy or a queue redelivery wrapping a write
  with no idempotency key. → Key the operation, or make the write naturally idempotent.

## B. Tenant isolation and money

The domain invariants. Treat a breach as hard whenever an ADR or `docs/ai/` states the rule.

- **Query without a tenant predicate** — raw SQL, a `FromSqlRaw`, or an entity queried through a
  path where the global filter does not apply. → Filter, and prefer a global query filter so it
  cannot be forgotten.
- **`IgnoreQueryFilters()`** without a comment justifying it. Each use is a deliberate bypass of
  tenant isolation. → Justify at the call site or remove.
- **Tenant id from the payload** rather than the authenticated principal. → Take it from the
  principal; a client-supplied tenant id is an authorization hole.
- **Cross-tenant join** — a join whose predicate does not carry the tenant on both sides.
- **Money as `double` or `float`.** → `decimal`, with explicit precision and scale in the model
  configuration.
- **Mutating an append-only ledger** — `Update`/`Remove` against a table an ADR declares
  append-only. → Post a compensating entry.
- **PII in logs or exception messages** — tenant identifiers, account numbers, names.

## C. Data access and query cost

- **N+1** — a query inside a loop, or lazy loading crossing a navigation property per row. → One
  query with `Include`, or a projection.
- **Client-side evaluation** — `.ToList()`/`.AsEnumerable()` before `.Where()`. Pulls the table,
  filters in memory. → Filter in the query.
- **Read path without `AsNoTracking()`** — pays change-tracking cost, and risks stale tracked
  entities leaking into a later write.
- **Unbounded query** — no paging, no `Take`. Fine at test volume; not at production volume.
- **Entity projected where a DTO would do** — over-fetching columns, and leaking the model.
- **`IQueryable` escaping the repository** — the caller now controls the SQL, and the boundary is
  fiction.
- **New predicate or sort with no supporting index**, or a predicate that is not SARGable —
  a function wrapped around the column (`WHERE YEAR(col) = …`, `WHERE col + 0 = …`). → Rewrite as a
  range; note the index the query needs.
- **`DbContext` captured by a singleton**, or shared across threads. It is not thread-safe.

## D. Schema and migrations

- **Data loss in a migration** — dropping a column, narrowing a type, tightening nullability with no
  backfill step. → Expand → backfill → contract, across releases.
- **(SQL Server) Clustered key on an ever-increasing value** at high insert rates — last-page
  insert contention. → Non-sequential key, hash partitioning, or `OPTIMIZE_FOR_SEQUENTIAL_KEY`.
  Postgres has no clustered index and no equivalent; it contends on index pages and WAL instead.
- **(SQL Server) Random `Guid` as a clustered key** — the opposite failure: fragmentation and page
  splits. → Sequential GUID, or keep the clustered index off it.
- **Non-deterministic default** applied to existing rows (`GETDATE()`/`NEWID()`,
  `now()`/`gen_random_uuid()`) — silently backfills real data with generated values.
- **(Postgres) A migration taking `ACCESS EXCLUSIVE` on a hot table** — adding a constraint or
  rewriting a column locks out readers for the duration. → `NOT VALID` then `VALIDATE CONSTRAINT`;
  `CREATE INDEX CONCURRENTLY`. Also set a `lock_timeout` so it fails fast instead of queueing.
- **Migration with no rollback path**, where it touches shared state. "Revert the commit" is not an
  answer for a migration already applied to a shared database.
- **More than one migration in a diff touching the same table** — merge order becomes load-bearing.

## E. Resources and boundaries

- **Undisposed `IDisposable`/`IAsyncDisposable`** — connections, streams, `HttpResponseMessage`.
- **`HttpClient` constructed per call** — socket exhaustion. → `IHttpClientFactory`.
- **Sync I/O on a request path** — `File.ReadAllText`, `Stream.Read`.
- **Swallowed exception** — `catch { }`, or catching `Exception` to log-and-continue where the
  operation cannot actually continue.
- **Public API surface changed** without a corresponding note where the repo tracks public API.
- **Secrets or connection strings in source**, including a settings file with a real value.

---

## Reporting shape

Per finding: **the label**, the file and hunk, one line on why it bites *here*, and the fix.
Say **hard** only for a documented-standard breach or a contradicted ADR — everything else is a
judgement call, and marking it otherwise trains the reader to discount the report.
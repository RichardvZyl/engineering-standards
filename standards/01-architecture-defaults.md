<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 01 — Architecture defaults

The starting position for a new component. A default is not a mandate: depart from one when the
context warrants, and record the departure as an ADR ([`05`](./05-decision-records.md)).

Database rules live in [`02`](./02-database-standards.md). This file stops at the boundary of the
data layer deliberately — where the two touch, `02` owns it.

## Multi-tenancy is a first-class concern

**Assume tenant isolation is required until proven otherwise.** Retrofitting it is a migration of
every table, every query and every cache key; designing for it and later discovering a single
tenant costs almost nothing.

- Every query that reads tenant-scoped data **carries a tenant predicate**. Enforcement belongs
  in a place a developer cannot forget — a global query filter, a row-level security policy, a
  repository that will not construct an unscoped query — not in review discipline.
- **A tenant identifier is never taken from user-supplied request content.** It comes from the
  authenticated principal or the resolved host.
- Choose the isolation shape deliberately: database-per-tenant, schema-per-tenant, or
  discriminator column. The trade is blast radius and noisy-neighbour isolation against
  operational cost per tenant and the cost of cross-tenant reporting.
- **Caches, background jobs, logs and exports are tenant-scoped too.** These are where isolation
  usually leaks, because they are written after the access-path review is over.

## Read and write separation

Separate the read model from the write model where the two have genuinely different shapes —
which is most places once reporting exists.

Reference the read side **only where a component must be physically incapable of writing**. A
read-only connection or a read model without a mutating surface is a structural guarantee;
"this service does not write" in a comment is not.

Do not adopt full event sourcing by default. It is an excellent fit for an auditable ledger and a
poor fit for reference data, and the cost of reversing it is near-total.

## Expected failure is a value, not an exception

Use **result or outcome types for expected failures** — validation, business-rule rejection, a
not-found lookup. Reserve exceptions for the genuinely exceptional.

The reason is a signature that tells the truth. A method returning `Result<T>` forces the caller
to handle the failure branch; a method that throws on an ordinary business outcome does not, and
the missing `catch` is invisible in review.

Exceptions remain correct for programmer error, infrastructure failure, and anything that should
abort the unit of work.

## Money and idempotency

Anything touching money is **idempotent by construction**:

- An attempt is recorded against a **caller-supplied unique key** before work begins. A retry
  with the same key returns the original outcome rather than performing the work twice.
- The write is guarded by **optimistic concurrency on the row being changed** — a rowversion or
  equivalent — so a concurrent update fails loudly instead of silently overwriting.
- **Retries are assumed.** Networks time out after the server committed. A design that is correct
  only when every response arrives is not correct.

## Design for contention

Contention is a design input, not an operational surprise. Where a hot row is unavoidable:

- **Partition the work** by a natural key — account, tenant, instrument — so invariants validate
  against a subset rather than a global total.
- **Converge on a single source of truth at a controlled write rate** rather than letting every
  writer contend for the same row.
- Prefer **append-then-fold** over update-in-place for high-frequency counters: appended rows do
  not block each other, and the fold happens where it can be scheduled.

## Composition over god-services

Favour small, responsibility-scoped packages with explicit contracts. A shared library is a
coupling with a version number attached — that is an improvement on a shared class, not an
escape from the coupling.

Where a repository, unit-of-work or specification abstraction is used, it exists to make the
correct thing easy and the unsafe thing hard — an unscoped query, a missing transaction
boundary. An abstraction that only forwards calls to the ORM has added a layer and removed
nothing.

## Asynchronous boundaries

- A message consumer is **idempotent**, because at-least-once delivery is what the broker
  actually offers.
- **Ordering is not assumed** unless the transport guarantees it for the partition key in use.
- A saga or process manager owns its own state and its own compensation. Compensation is designed
  at the same time as the happy path, not added after the first partial failure in production.
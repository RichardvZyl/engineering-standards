---
name: architecture-defaults
description: >
  Starting position for a new component or service boundary. Use when choosing tenancy, read/write separation, result types, money idempotency, contention strategy, or async delivery. A default is not a mandate; a departure is an ADR. Does not own database rules. Triggers: new service, tenancy, CQRS, idempotency, saga, contention, result type, outbox.
metadata:
  standard: standards/01-architecture-defaults.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Architecture defaults

The rule is [`01-architecture-defaults.md`](../../01-architecture-defaults.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Designing a component, or reviewing one, before the schema. Database rules are database-standards.

## Also load

- [`database-standards`](../database-standards/SKILL.md)
- [`decision-records`](../decision-records/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Assume tenant isolation until proven otherwise. The tenant id comes from the authenticated principal or the resolved host, never from request content. Caches, jobs, logs, and exports are tenant-scoped too.
2. Separate read and write models where their shapes differ. A read side that must not write is structurally incapable of writing, not commented as such. Do not adopt event sourcing by default.
3. Expected failure is a result or outcome. Exceptions are for programmer error, infrastructure failure, and aborting the unit of work.
4. Money is idempotent by construction: caller-supplied unique key recorded before work, optimistic concurrency on the row, retries assumed.
5. Treat contention as a design input: partition by a natural key, or append-then-fold, rather than letting every writer hit one row.
6. Small packages with explicit contracts. An abstraction exists to make the unsafe thing hard. A consumer is idempotent; ordering is not assumed; compensation is designed with the happy path.

## Do not

- Restating database types, isolation, or migration rules here. Those belong to database-standards.
- Departing from a default without an ADR.

## Done when

- [ ] Tenancy, failure style, and idempotency are explicit.
- [ ] Any departure is recorded as a decision record, with its cost to reverse.

---
name: database-standards
description: >
  Apply the database rules before changing a schema, query, migration, index, isolation level, or money column. Use for SQL Server or PostgreSQL data access. This skill owns what must be true, not how to spot it in a diff. Triggers: schema, migration, query, index, tenant predicate, decimal, money, SARGable, isolation, backfill, lost update.
metadata:
  standard: standards/02-database-standards.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Database standards

The rule is [`02-database-standards.md`](../../02-database-standards.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Any schema, query, migration, or data-access change. For a diff, also load dotnet-sql-review and do not paste that checklist into the change.

## Also load

- [`dotnet-sql-review`](../dotnet-sql-review/SKILL.md)
- [`architecture-defaults`](../architecture-defaults/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Types. Money is decimal, never float or double. Precision and scale are in the schema. Business times are UTC or an explicit offset, not the server's local time.
2. Every query that reads tenant-scoped data carries a tenant predicate, enforced where a developer cannot forget it.
3. Isolation is stated, never assumed. Design to avoid deadlocks by consistent lock ordering. A lost update is a correctness bug. A transaction held open across a network call or a user is a defect.
4. Predicates are SARGable. No function on the column side. Parameter types match column types.
5. Indexes are deliberate, including last-page insert contention and the write cost of an unused index.
6. A performance claim is supported by the plan, logical reads, and wait statistics.
7. Migrations are forward-only and idempotent, tested against a realistic copy. A destructive change is two-phase. A backfill is batched and resumable.
8. Engine differences are load-bearing. Check which engine the change targets before copying a pattern from the other.

## Do not

- Copying the review baseline into this skill or into the standard. The baseline is the detection procedure; this standard is the rule.
- A floating-point money column, an unscoped tenant query, or a migration that drops and hopes.

## Done when

- [ ] The rule in 02 still holds for every query, type, and migration in the change.
- [ ] A diff was also passed through dotnet-sql-review.

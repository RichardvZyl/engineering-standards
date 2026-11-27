---
name: dotnet-sql-review
description: >
  Review a diff for database and data-access defects. Use when reviewing C#, Entity Framework, SQL Server, or PostgreSQL changes. Items are labelled heuristics, not automatic hard failures, unless they breach a documented standard or an accepted ADR. Triggers: code review, pull request, EF, SaveChanges, FromSqlRaw, IgnoreQueryFilters, N+1.
metadata:
  standard: standards/reference/dotnet-sql-baseline.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# .NET / SQL review baseline

The rule is [`dotnet-sql-baseline.md`](../../reference/dotnet-sql-baseline.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Reviewing a diff. The rules live in database-standards. This skill is how to notice a breach. Do not promote a heuristic to a hard failure without that standard or an ADR.

## Also load

- [`database-standards`](../database-standards/SKILL.md)
- [`review-standards`](../review-standards/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Confirm the engine. Items marked for one engine do not apply to the other.
2. Skip anything the analyzers already enforce.
3. Look in cost order: concurrency (lost update, check-then-act, unstated isolation), tenant isolation and money, query cost (N+1, client evaluation, unbounded reads), schema and migrations, resources and boundaries.
4. Report each finding as the label, the file and hunk, why it bites here, and the fix. Say hard only for a documented-standard breach or a contradicted ADR.

## Do not

- Re-flagging a warning the build already fails on.
- Copying these heuristics back into database-standards.

## Done when

- [ ] Group A (correctness under concurrency) was actually looked at, not assumed fine because tests passed.

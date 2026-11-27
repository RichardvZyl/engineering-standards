---
name: decision-records
description: >
  Decide whether a decision needs an ADR and write it in the required shape. Use for public contracts, persistence or tenancy, concurrency or isolation, significant dependencies, and any departure from these standards. The test is cost to reverse, not importance. Triggers: ADR, decision record, hard to reverse, supersede, architecture decision.
metadata:
  standard: standards/05-decision-records.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Decision records

The rule is [`05-decision-records.md`](../../05-decision-records.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

About to make a choice that later readers would otherwise have to re-derive, or that is costly or one-way to undo.

## Also load

- [`documentation-layout`](../documentation-layout/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. ADRs live in docs/adr/, named NNNN-kebab-title.md. The number is permanent.
2. Require a record when cost to reverse is above Reversible: a public contract, a persistence or tenancy shape, a concurrency or isolation strategy, a significant dependency change, or a departure from these standards. A trivial-to-undo debate does not need one.
3. Rate the shipped state, not the branch: Reversible, Costly, or One-way, with a clause that says what makes it that. The rating matches the chosen option's row. A One-way record names the escape. Never edit the rating because time passed.
4. Options considered is not optional, and includes do-nothing. A record with one option is a note.
5. Never edit a record to reflect a new decision, and never delete one. Mark it superseded and write a new record. Record contradictions; do not silently resolve them.
6. Update docs/adr/README.md in the same commit. The index carries number, title, status, and cost to reverse.

## Do not

- An ADR in an agent-state directory, a wiki, or a ticket.
- Filling docs/adr/ with records nobody will consult.

## Done when

- [ ] The index lists the record, and the cost-to-reverse clause matches the options table.

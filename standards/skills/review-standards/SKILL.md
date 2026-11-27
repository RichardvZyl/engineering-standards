---
name: review-standards
description: >
  Review a change on two axes that stay unmerged: standards and spec. Use for pull-request review and for self-review before requesting it. Mechanical checks belong to the build. Triggers: review, pull request, LGTM, approve, self-review, acceptance criteria.
metadata:
  standard: standards/06-review-standards.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Review standards

The rule is [`06-review-standards.md`](../../06-review-standards.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Reviewing someone else's change, or reading your own diff before you ask for review.

## Also load

- [`dotnet-sql-review`](../dotnet-sql-review/SKILL.md)
- [`decision-records`](../decision-records/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Anything a machine can check, a machine checks. A review that produced only style comments did not happen.
2. Score two axes separately. Standards: conventions, ADRs, and the database baseline. Spec: the planning item's acceptance criteria, not a recollection of the conversation. Do not collapse them into one verdict.
3. Look in this order: data integrity, concurrency (including retry after a timeout that arrived post-commit), blast radius, the spec axis, cost of the next change.
4. Comment on the change, not the author. Label blocking versus non-blocking. If you do not understand it, ask rather than approve. Disagreement escalates to a decision record when it is hard to reverse.
5. Self-review asks only whether the sentence, method, or migration is still right in six months in someone else's hands.

## Do not

- Reproducing the database checklist in the review comment as if this skill owned it. Point at dotnet-sql-review.
- An approval that means the diff was skimmed.

## Done when

- [ ] The review says which axis was assessed, and blocking comments are labelled.

---
name: keeping-documents-current
description: >
  Update every document that assumed the old state when something closes. Use when closing a question, a decision, a plan item, or an issue, and when a generated view or a stale reference would otherwise survive. Triggers: close, done, status change, stale, regenerate, debt marker, changelog.
metadata:
  standard: standards/08-keeping-documents-current.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Keeping documents current

The rule is [`08-keeping-documents-current.md`](../../08-keeping-documents-current.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Closing or reversing anything that other documents still describe as open or true.

## Also load

- [`documentation-layout`](../documentation-layout/SKILL.md)
- [`durable-references`](../durable-references/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Closing is not done until every document that assumed the old state is updated in the same commit or pull request.
2. Follow the closure table in the standard: a ruled question, a decision that changes status, a finished plan item, and an external issue each drag a specific set of surfaces with them.
3. Generated views are regenerated, never hand-edited.
4. Run the stale-reference sweep the standard describes before calling the closure done.
5. Write what will still be true. Prefer the shape to the census. Do not record a count that will expire.
6. Use the commit convention in the standard.
7. If a surface cannot be updated yet, leave the debt marker the standard requires. No outstanding markers means the closure is actually finished.

## Do not

- Hand-editing a generated diagram to match a decision you have not regenerated.
- A closure commit that updates the item and leaves the documents that cited the old answer.

## Done when

- [ ] The same change contains the status move and the documents that would otherwise lie.

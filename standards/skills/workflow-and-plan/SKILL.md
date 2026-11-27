---
name: workflow-and-plan
description: >
  Split recurring work into a reusable workflow and a disposable plan. Use when a task will happen again. The plan may reference the workflow. The workflow must never reference the plan. Triggers: workflow, runbook, plan, recurring, template procedure, playbook.
metadata:
  standard: standards/15-workflow-and-plan-pair.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Workflow and plan

The rule is [`15-workflow-and-plan-pair.md`](../../15-workflow-and-plan-pair.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

The work in front of you is likely to recur, or you are about to point a durable procedure at today's plan.

## Also load

- [`keeping-documents-current`](../keeping-documents-current/SKILL.md)
- [`documentation-layout`](../documentation-layout/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Produce two artefacts: a generic workflow and a plan for this instance.
2. The dependency runs one way. The plan may reference the workflow. The workflow must never reference the plan.
3. The workflow holds conditions, ordered steps, and acceptance criteria. The plan holds today's state, today's inventory, and today's decisions.
4. Apply the practical consequences in section 15.4. A workflow that names a specific plan rots when that plan ends.

## Do not

- Putting today's file names, counts, or branch names into the workflow.
- One combined document that is both the procedure and the instance.

## Done when

- [ ] Deleting or archiving the plan does not dangle a reference inside the workflow.

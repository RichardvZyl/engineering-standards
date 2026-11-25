<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 15 — Recurring work produces a workflow and a plan, and the dependency runs one way

## 15.1 The rule

Anything likely to recur produces **two artefacts**: a generic, reusable **workflow**, and a
**planning document** for the instance in front of you.

**The dependency is one-way. The plan may reference the workflow. The workflow must never reference the
plan.**

## 15.2 Why — the workflow is durable, the plan is disposable

A plan is finished the moment it is executed. It is then either deleted or kept as a record of what was
done on one day. Either way it stops being a live document.

A workflow's only property is that it is **reusable**. A workflow that points at a specific plan rots the
instant that plan is completed or deleted — the reference dangles, and with it goes the one property the
workflow had.

So the rule is not a style preference. It is the documentation form of the snapshot rule already in these
standards: **the thing that must survive cannot depend on the thing that is meant to go stale.** A
snapshot is never the source of truth, and a plan is never a workflow's source of truth.

## 15.3 What goes where

| The workflow holds | The plan holds |
| --- | --- |
| Conditions — when this applies, when it does not | Today's state, measured |
| Steps, in order, with their acceptance criteria | Today's inventory, as run-log readings |
| **Discovery** steps — how to find out, not what was found | Today's decisions and their rationale |
| **Exception branches** — what to do when a step's precondition fails | Today's specific repositories, counts, hashes, dates |
| Verification and rollback shape | Today's verification results |

## 15.4 Practical consequences — apply these

- **Recurring work produces two artefacts, not one.** Producing only a plan is *the* failure mode: the
  knowledge dies with the task, and the next occurrence starts from nothing.
- **A workflow containing a repository name, a date, a count, or a hash is almost certainly carrying plan
  content.** Treat that as a defect and refactor it: the fact moves to the plan, and the workflow keeps
  only the *check* that produced it. This is standard 09 applied to documents rather than paths.
- **When executing a plan teaches something general, it goes back into the workflow** — not into the next
  plan. A lesson recorded only in a plan is a lesson recorded nowhere.
- **Write the workflow first, or at least alongside.** Writing it afterwards, from a finished plan, is how
  plan content leaks into it.

## 15.5 Evidence — this has already bitten twice

Recorded because the rule is easier to follow when the cost of ignoring it is concrete.

1. A deliverable was requested and produced as a plan, and had to be **reshaped into a workflow**
   afterwards, once it became clear the same work would recur. Rework that producing the pair up front
   would have avoided entirely.
2. The repository-layout standard's **first real use found a case the workflow had not covered.** The gap
   was only visible because a workflow existed to be found wanting. Had there been only a plan, the gap
   would have been absorbed silently into that one plan and lost.

Both are arguments for producing the pair up front rather than promoting a plan to a workflow later.

## 15.6 Review checklist

- [ ] Recurring work produced both a workflow and a plan.
- [ ] The plan references the workflow; the workflow references no plan, by name or by path.
- [ ] The workflow contains no repository name, date, count, or hash.
- [ ] The workflow states its conditions, its discovery steps, and its exception branches — not just the
      happy path.
- [ ] Anything general learned during execution was written back into the workflow.

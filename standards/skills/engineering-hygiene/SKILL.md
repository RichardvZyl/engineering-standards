---
name: engineering-hygiene
description: >
  Apply git, secrets, test, dependency, style, and deletion rules. Use before committing, adding a dependency, writing a test, or deleting anything. Triggers: commit, branch, secret, editorconfig, feature flag, dependency, test, delete, stacked pull request.
metadata:
  standard: standards/03-engineering-hygiene.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Engineering hygiene

The rule is [`03-engineering-hygiene.md`](../../03-engineering-hygiene.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Committing, branching, deleting, adding a dependency, or deciding what a review is allowed to spend time on.

## Also load

- [`repository-worktrees`](../repository-worktrees/SKILL.md)
- [`review-standards`](../review-standards/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. Style is settled by configuration. Do not review brace placement. Where the build can enforce a rule, it does.
2. Trunk-based, short-lived branches, and no stray branches. On a trunk-only repository, never create a non-default branch, even when a bypass or admin role would allow it. Everywhere else, a branch exists only as a linked worktree beside root (and fully-merged). No parking branch. The full rule is repository-worktrees, section 10.10. Exceptions only as Conventions first allows.
3. Commits are small, green before commit (not merely before merge), and the message says why and cites the planning identifier.
4. Incomplete work ships behind a flag, not on a long-lived branch. Follow the stacked-PR containment order in the standard: upper PR bases the branch below, merge oldest-first, do not drop unique commits.
5. No secret is committed, in any form, on any branch. Environment-specific configuration comes from the environment.
6. Never log personal data, secrets, or anything crossing a tenant boundary. Retention is a design constraint. An audit trail is append-only.
7. Database tests run against a real database. A concurrency fix ships with a test that fails without the fix. Coverage is not a target.
8. A new dependency is a decision. Pin versions. Prefer the platform facility over a thin wrapper.
9. Repository instructions are binding on people and assistants.
10. Deletion is recoverable. Permanent deletion is not the default. Do not force-remove unless the request explicitly says the destruction is unrecoverable, and record that.

## Do not

- A style comment that displaced a real one.
- A red commit, a committed secret, or an unrecoverable delete as the default.

## Done when

- [ ] The commit is green, the message says why, and nothing secret is in the diff.
- [ ] If something was deleted, it went through the platform's recoverable-destruction facility, or the unrecoverable path was explicit and recorded.

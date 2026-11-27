---
name: repository-worktrees
description: >
  Place the base checkout and worktrees, and create branches from a current trunk. Use before git worktree add, git checkout -b, pruning a worktree, or publishing. The base is named root and is not a workspace. Triggers: worktree, root checkout, fully-merged, branch from, prune, session state.
metadata:
  standard: standards/10-repository-and-worktree-layout.md
---

<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# Repository and worktree layout

The rule is [`10-repository-and-worktree-layout.md`](../../10-repository-and-worktree-layout.md). Read that file before you act. This skill is the
trigger and the order of work. If a line here and the standard disagree, the standard
wins — fix this skill upstream in the same change. Do not grow a second copy of the rule.

## When

Creating a branch or worktree, removing one, or deciding where a checkout lives.

## Also load

- [`engineering-hygiene`](../engineering-hygiene/SKILL.md)
- [`deploy-artifacts`](../deploy-artifacts/SKILL.md)

Load those only when their descriptions match the task. Do not load the rest of the set.

## Apply, in this order

1. The repository directory holds the base and every worktree as siblings. The base is named root. Worktrees are not nested in the base, not inside a worktrees container, and not outside the repository directory. Add one from the base with a sibling path.
2. Do not edit or commit in the base. It tracks origin, fast-forward only. Unfinished work lives in a worktree.
3. Before creating a branch or worktree: fetch and prune, ask about open pull requests against the trunk and wait, fast-forward the base, branch from the remote ref. Read the trunk's name from the remote. A deliberately old base is named as such.
4. Removing a worktree is your obligation, and prune order matters. Never prune while that worktree's commits are unaccounted for. When true git-directory isolation is required, use a separate clone, not a worktree.
5. Agent session state lives in .session/ under the repository directory, keyed by provider, model, and session id. Not in the vendor's per-user cache.
6. fully-merged is the integration tip. Create it when missing, as a fast-forward of the remote default trunk, on repositories that accept feature work. Trunk-only repositories with a recorded policy do not. No code lives or runs outside its own repository. A long-running service starts from a merged release build.
7. No stray branches (10.10). A trunk-only repository never receives a non-default branch from an agent. On every other repository, a branch is a linked worktree beside root, with fully-merged as the integration tip. No parking branch. A bypass or admin right is not permission. An exception is only the direct authorization Conventions first already requires.
8. Apply the outage exception only as that section writes it. Do not generalize it, and do not copy any machine path out of it.

## Do not

- Working in root because it was the checkout you already had open.
- Branching from a stale base, or assuming the trunk is named main.
- Parking unfinished work as uncommitted changes in the base.

## Done when

- [ ] The checklist in section 10.9 is true of the layout you just changed.

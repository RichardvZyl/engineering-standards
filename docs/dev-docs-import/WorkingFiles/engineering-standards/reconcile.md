> Source: E:\Development\repositories\RichardvZyl\engineering-standards\root\.agents\reconcile.md | Branch: main | Commit: none | Status: untracked | Copied: 2026-11-06 07:57 SAST (working copy - edit the source, not this file)

# Reconcile — engineering-standards

> Probed 2026-10-26, after `git fetch --all --prune`. Trunk: `main` (derived from `origin/HEAD`).
> Status: done through converge. Prune deleted nothing.

## Base

| | Commit | Relative to the other |
|---|---|---|
| `main` (local, checkout `root/`) | `3c5dcff` | behind 2, ahead 0 |
| `origin/main` | `2a73616` | standards: worktrees sit beside root/, never under .agents/worktrees/ (#18) |

Convergence takes: park the dirty files in `root/`, then `git merge --ff-only origin/main`. Local `main` is not diverged.

No stopped merge, rebase, or cherry-pick.

## Ledger

| Entry | What it is | Evidence | Disposition |
|---|---|---|---|
| `main` | checkout `root/`, behind 2 | `rev-list --left-right --count origin/main...main` = `2 0` | live, because the worktree is dirty |
| `root/` working tree | 5 modified, 0 untracked | `status`: `.perseus/context.md`, `AGENTS.md`, `CHANGELOG.md`, `standards/03-engineering-hygiene.md`, `standards/07-repo-layout.md` | live |
| `docs/friends-repository-lessons` | 1 commit, upstream in sync, worktree clean | diff is only the planning document; draft PR #21. Replaces closed PR #19 | ready |
| `docs/worktrees-beside-root` | 2 commits, upstream `[gone]`, tree identical to `origin/main` | `git diff origin/main docs/worktrees-beside-root` is empty. `cherry` still prints `+` because #18 was squash-merged, so `branch -d` will refuse | duplicate by tree, not by patch-id |
| `docs-worktrees-beside-root/` untracked plan copy | removed on 2026-10-27 | the same document is committed on `docs/friends-repository-lessons` | removed after the committed copy existed |
| `handoff/lockdown-2026-10-16` | 1 commit `194ab67`, upstream in sync | `cherry` shows `+ 194ab67`. Draft PR #17. Its own text says it is not proposed for merge | your call |
| `handoff-lockdown/` working tree | 2 modified | `.perseus/context.md`, `AGENTS.md` | live |
| `standards/09-through-15` | 17 commits, upstream in sync, tree is behind `origin/main` | `cherry` shows `+` on all 17 (squash of #15 does not match patch-ids). Two-dot diff is `origin/main` having the #18 layout and this branch lacking it: 6 files, 10 insertions, 76 deletions | your call: keep as history, do not merge |
| `standards-09-through-15/` working tree | 6 modified | `.perseus/context.md`, `AGENTS.md`, `CHANGELOG.md`, `standards/03`, `standards/07`, `standards/10` | live |
| `wip/engineering-standards-09-15-loose-state` | 1 local commit `8372885` on top of the standards branch, tag `park/2026-10-21/engineering-standards-09-15-loose-state`, no upstream | two-dot vs `origin/main` is only `CHANGELOG.md` and `standards/VERSION` (this park does not have 0.8.0) | duplicate of the layout work now on `main`. Keep the tag. Do not land |
| `wip/engineering-standards-root-loose-state` | 1 local commit `a548525`, tag `park/2026-10-21/engineering-standards-root-loose-state`, no upstream | two-dot vs `origin/main` deletes standards 09–16 (1,572 deletions). That is an old base, not a change to land | duplicate of the layout patch. Keep the tag. Do not land |
| stashes | none | `stash list` empty | — |

## At risk

**Unreachable — no ref names it** (fixed by parking, phase 1)

- `root/` working tree: 5 modified files, no commit
- `handoff-lockdown/` working tree: 2 modified files, no commit
- `standards-09-through-15/` working tree: 6 modified files, no commit
- `docs-worktrees-beside-root/`: 1 untracked plan copy. Already committed on another branch. Leave it unless you say otherwise

**This machine only** (reachable, but not on any remote — publishing is a decision, not a step)

- `wip/engineering-standards-09-15-loose-state`: 1 commit, no upstream
- `wip/engineering-standards-root-loose-state`: 1 commit, no upstream
- `docs/worktrees-beside-root`: 2 commits. The remote branch is gone. The tree matches `origin/main`, so the commits are the pre-squash form of #18

## Roadmap

### 1. Park — local only, nothing pushed

- [ ] In `root/`: `git switch -c wip/root-dirty-2026-10-26`, commit the 5 modified files, `git tag park/2026-10-26/root-dirty`, then `git switch main`. Carries the loose edits off trunk. Skipping this blocks the fast-forward.
- [ ] In `handoff-lockdown/`: `git switch -c wip/handoff-dirty-2026-10-26`, commit the 2 modified files, tag `park/2026-10-26/handoff-dirty`, then `git switch handoff/lockdown-2026-10-16`. The published PR branch stays at `194ab67`.
- [ ] In `standards-09-through-15/`: `git switch -c wip/standards-09-dirty-2026-10-26`, commit the 6 modified files, tag `park/2026-10-26/standards-09-dirty`, then `git switch standards/09-through-15`.
- [ ] Do not `git add` the untracked plan copy under `docs-worktrees-beside-root/`.

### 2. Converge trunk

- [ ] In `root/`, on clean `main`: `git merge --ff-only origin/main`. Local `main` moves `3c5dcff` → `2a73616`. Nothing is pushed. Skipping this leaves the base checkout two commits behind GitHub.

### 3. Land

- [ ] No merge. Draft PR #21 (`docs/friends-repository-lessons`) is the landing place for the plan, and its questions are still open. `standards/09-through-15` and both October 21 `wip/` branches would not add work that `origin/main` lacks.

### 4. Rebase survivors

- [ ] Do not rebase `handoff/lockdown-2026-10-16` or `standards/09-through-15`. Both are already on `origin`. A rebase would rewrite published history and needs `--force-with-lease`, which this roadmap does not run.
- [ ] `docs/friends-repository-lessons` is already based on `2a73616`. No rebase.
- [ ] Leave both `wip/engineering-standards-*-loose-state` branches where they are. Rebasing the root park onto current `main` would try to delete standards 09–16.

### 5. Prune (after re-probe)

- [ ] Re-probe. Do not `branch -d` anything whose `git cherry origin/main <branch>` still shows `+`. That includes `docs/worktrees-beside-root` even though its tree matches `origin/main`.
- [ ] Do not `push origin --delete` for `standards/09-through-15` or `handoff/lockdown-2026-10-16`.
- [ ] Do not `worktree remove` a checkout that still holds the untracked plan copy.
- [ ] `git worktree prune` only if a later probe shows an orphaned admin entry. The opening probe had none.

## Your calls

| Decision | If yes | If no | What is lost either way |
|---|---|---|---|
| Publish the parked `wip/*-dirty-2026-10-26` branches after phase 1? | they survive losing this machine | they stay local, which already survives every step above | nothing in the roadmap. A remote `wip/` name would need a later delete |
| Publish the two October 21 `wip/` branches? | the old parks are on GitHub | they stay local, already tagged `park/2026-10-21/…` | nothing required for convergence |
| Delete local `docs/worktrees-beside-root` even though `cherry` is not all `-`? | drops the pre-squash commits. The tree is already `2a73616` | keeps a branch whose upstream is gone | the pre-squash commits `bbec47b` and `09c966b`, recoverable from the reflog until they expire. `branch -d` will refuse; deletion would be `-D` |
| Remove the `docs-worktrees-beside-root` worktree? | removes a checkout of a duplicate tree | keeps an untracked second copy of the plan file | that untracked copy. The committed copy is on PR #19 |
| Merge draft #17 or #19? | lands the handoff, or lands the plan before its questions are answered | both stay open | not part of this reconcile |
| Rebase the handoff branch onto `2a73616`? | the draft sits on current `main` | it stays one commit behind, which it already is (`b24c51b`) | a force-with-lease of a branch other people can see |

## Restore point

Captured before any execution. `git branch <name> <sha>` restores any of these.

```
c4c2c01 refs/heads/docs/friends-repository-lessons
09c966b616121a09eed1527555f5b292aa33a6d0 refs/heads/docs/worktrees-beside-root
194ab67d187bdcb3e6910612fd26353e9e67c642 refs/heads/handoff/lockdown-2026-10-16
3c5dcff474b6a53cb7a7ae48cfc25c9b2f936e77 refs/heads/main
313b19f856245564227b44c7783ee05be9f12ee4 refs/heads/standards/09-through-15
83728858d5a50463d81ea05c7b1d9ae5509f295a refs/heads/wip/engineering-standards-09-15-loose-state
a5485252564923c43c404ef4ff6e89c1ac2675ca refs/heads/wip/engineering-standards-root-loose-state
83728858d5a50463d81ea05c7b1d9ae5509f295a refs/tags/park/2026-10-21/engineering-standards-09-15-loose-state
a5485252564923c43c404ef4ff6e89c1ac2675ca refs/tags/park/2026-10-21/engineering-standards-root-loose-state
2a7361605d03341e571e5110012fc807c92a3f87 refs/remotes/origin/main
```

Stashes at capture time: none.

## Execution 2026-10-27

Phase 1 parked locally and pushed nothing:

- `wip/root-dirty-2026-10-27` at `0fd773d`, tag `park/2026-10-27/root-dirty`. `root/` is back on `main`.
- `wip/handoff-dirty-2026-10-27` at `222b3b4`, tag `park/2026-10-27/handoff-dirty`. The handoff checkout is back on `handoff/lockdown-2026-10-16`.
- `wip/standards-09-dirty-2026-10-27` at `51fb1bc`, tag `park/2026-10-27/standards-09-dirty`. That checkout is back on `standards/09-through-15`.

Phase 2 fast-forwarded local `main` from `3c5dcff` to `2a73616`. `main` matches `origin/main`. `standards/VERSION` is `0.8.0`.

Phase 3 and 4 were not run. Draft pull requests #17 and #19 were not merged. No published branch was rebased.

Phase 5 re-probe: `git cherry origin/main docs/worktrees-beside-root` still shows `+` for `bbec47b` and `09c966b`, so that branch was not deleted. `git worktree prune --dry-run` found nothing. No remote branch was deleted. The untracked plan copy under `docs-worktrees-beside-root/` was left in place.

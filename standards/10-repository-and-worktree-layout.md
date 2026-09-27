<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 10 — Repository and worktree layout

## 10.1 Shape

A repository occupies a **directory named after the repository**. Inside it, the base checkout and every
linked worktree sit as **siblings**:

```text
<repo-name>/
  root/                  <- the base checkout. Tracks origin. Never worked on directly.
  <worktree-name>/       <- a worktree. Where work happens.
  <worktree-name>/       <- another worktree, sibling of the base and of its peers.
```

Nothing else lives at that level. Worktrees are never nested inside the base, and the base is never the
repository directory itself.

## 10.2 The base directory is named `root`

**Decided. Do not relitigate.**

Considered: `root`; `main` or `trunk`; `.base` or `_base`; the bare repository name with worktrees
elsewhere.

`root` wins on three grounds. It is **already in use** in this estate — at least one repository is
already laid out this way, so choosing anything else would mean two conventions and a migration. It was
**already proposed** in the operator's own layout workflow, so it is the established intent rather than a
new invention. And it does not collide with a **branch** name: calling the directory `main` or `trunk`
makes "check out trunk" ambiguous between a branch and a directory, which is exactly the kind of
ambiguity that costs time in instructions written for someone else. A leading dot or underscore was
rejected because the base is not hidden bookkeeping — it is a real checkout an operator will open.

## 10.3 The base is for syncing, not for working

The base checkout exists to **track and synchronise with origin**. It is not a workspace.

- Do not edit files in the base. Do not commit there.
- The base holds the trunk branch and is kept fast-forward-only against origin.
- Work happens in a worktree. A worktree is merged **into** the base before the worktree is pruned.
- Genuinely unfinished work lives in a worktree beside the base, not as uncommitted changes in it.

The reason is recoverability. If the base is always a clean fast-forward of origin, then "what does
origin think" is answerable at any moment without inspecting anyone's work in progress, and a broken
worktree can be deleted without risking the only copy of the trunk.

## 10.4 Consequences

- The default location for new worktrees is a sibling of the base, inside the repository directory.
  Configure it once per repository rather than passing a location each time.
- Tooling that assumes the repository directory *is* the checkout needs its path adjusted by one level.
  This is the main cost of the convention and is accepted deliberately.
- Enumerating worktrees is a per-repository operation; see the sync workflow document for how to do it
  across an estate safely.

## 10.5 Review checklist

- [ ] Base checkout is named `root` and sits inside the repository directory.
- [ ] Every worktree is a sibling of `root`, not nested within it.
- [ ] The base has no local commits and no uncommitted changes.
- [ ] The base's trunk branch is a fast-forward of origin's trunk.
- [ ] Unfinished work is in a worktree, not in the base.

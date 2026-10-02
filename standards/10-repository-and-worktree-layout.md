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

## 10.5 Before creating a branch or a worktree, get the base current

**Rule.** Never branch from a stale base. Before `git checkout -b` or `git worktree add`:

1. **Fetch.** `git fetch origin --prune`.
2. **Check for open pull requests.** If any are open against the trunk, **ask whether they
   should be merged first**, and wait for the answer. Do not open a branch that is about to
   be made obsolete by a merge, and do not assume the answer either way.
3. **Bring the base checkout to the trunk's tip.** Fast-forward only — `git merge --ff-only
   origin/<trunk>`. If it will not fast-forward, the base has local commits and that is a
   separate decision, not something to paper over.
4. **Branch from the remote ref, not from whatever is checked out.** `git checkout -b <name>
   origin/<trunk>` or `git worktree add <path> -b <name> origin/<trunk>`.

**Read the trunk's name from the remote.** It is not always `main` and not always `master`;
assuming either mis-targets the base, the pull request, and every "is this unpushed?"
comparison.

**Why this is a rule and not a suggestion.** The cost is paid at merge time, and by then it
is much larger:

- A branch cut from a stale base carries a diff against history that no longer exists, so
  the merge has to reconcile changes the author never saw and never intended to touch.
- Every conflict it produces is **avoidable noise** — the reviewer cannot tell an intended
  change from a rebase artefact, so the review gets worse, not just longer.
- Work gets duplicated. Something already merged gets "fixed" again on the stale branch,
  and the second fix wins silently.
- It compounds. A stale branch that sits for a week is staler, and the reconciliation grows
  with the gap.

Getting the base to the most current point available makes the merge as small as it can be,
which is the whole point. Do it once, cheaply, before the work starts.

**Exception, stated so it is not abused.** If you deliberately need history as it was — to
reproduce a bug, to bisect, to build against a released tag — branch from the exact ref you
mean and **say so in the branch name or the pull request**. A deliberate old base is fine. An
accidental one is the failure this rule prevents.

## 10.6 A worktree writes into the main `.git`, and removing it is your obligation

`git worktree add` creates its own index and `HEAD`, which is why it does not collide with an
editor holding `.git/index.lock`. But it is **not** fully separate from the main repository:
it writes an administrative directory under the main `.git/worktrees/<name>`, and it adds a
`.git` *file* in the new directory pointing back at it.

**Know precisely what the isolation does and does not buy.**

- **Does buy:** a separate index and `HEAD`, so `add`, `commit` and `checkout` in the worktree
  cannot contend with the primary checkout's index lock. Two agents can hold the same
  repository on different branches at once.
- **Does not buy:** independence from the main `.git`. The admin write still happens. That it
  succeeds under a held `index.lock` is because it does not touch the *index* — a property of
  the current implementation, not a guarantee.

**Therefore the rule:** a worktree is created for a piece of work and **removed when that work
is merged or abandoned**, with `git worktree remove <path>` followed by `git worktree prune`.
Verified: after both, the removed worktree's own administrative entry under `.git/worktrees/<name>` is
gone and it no longer appears in `git worktree list` — entries for sibling worktrees correctly remain.

- **`remove` alone is not enough** when the directory was deleted by hand — that leaves the
  admin entry orphaned. `prune` is what clears it.
- **Prune order matters.** Prune the worktree before deleting its branch, never after: the
  admin entry is what still associates the directory with the commits it was built from.
- **Never prune while a worktree's commits are unaccounted for.** An orphaned worktree whose
  administrative pointer no longer resolves still holds the only record of which commit its
  files came from. Establish that from the owning repository first, make those commits
  reachable by creating a branch at them, and archive the directory — verified — before
  pruning anything.
- **Attach the prune to something that already runs.** Nobody remembers to run it by hand.
  The natural home is whatever already fires per session or per merge.

**When true separation from the main `.git` is required** — and only then — use a separate
clone rather than a worktree. It costs a second object store and its own fetch and push, and
buys a `.git` that nothing else writes to. A worktree is the right default; a clone is the
escape hatch.

## 10.7 Review checklist

- [ ] Base checkout is named `root` and sits inside the repository directory.
- [ ] Every worktree is a sibling of `root`, not nested within it.
- [ ] The base has no local commits and no uncommitted changes.
- [ ] The base's trunk branch is a fast-forward of origin's trunk.
- [ ] Unfinished work is in a worktree, not in the base.
- [ ] Before the branch or worktree was created: fetched, open pull requests against the trunk
      raised for a merge decision, and the base fast-forwarded to the trunk's tip.
- [ ] The branch was cut from the remote ref, and the trunk's name was read from the remote rather
      than assumed.
- [ ] Any deliberately old base is stated in the branch name or the pull request.
- [ ] Every worktree whose work is merged or abandoned has been removed **and** pruned, leaving no
      entry under `.git/worktrees`.
- [ ] No prune was run while a worktree's commits were unaccounted for, and nothing was removed
      without a verified archive.

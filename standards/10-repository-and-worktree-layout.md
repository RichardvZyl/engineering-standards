<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 10 — Repository and worktree layout

## 10.1 Shape

A repository occupies a **directory named after the repository**. Inside it, the base checkout and every
linked worktree sit as **siblings** — both are direct children of the repository directory:

```text
${repos_root}/{repository_owner}/{repository_name}/
  root/                  <- the base checkout. Tracks origin. Never worked on directly.
  <worktree-name>/       <- a worktree. Where work happens.
  <worktree-name>/       <- another worktree, sibling of the base and of its peers.
```

**Worked example** — one repository directory holding the base and two worktrees (names
illustrative):

```text
repositories/acme/payments/     <- one repository directory
  root/                         <- the base checkout
  fix-ledger-rounding/          <- a worktree, sibling of root
  docs-sync/                    <- another worktree, sibling of root
```

No worktree hides behind a container — not `worktrees/`, not a dotted `.worktrees/`, not
`.agents/worktrees/`, never outside the repository directory. Worktrees are never nested inside
the base, and the base is never the repository directory itself. The repository directory is named after the repository. Add one from the base, after the sync in 10.9:
`git worktree add ../<worktree-name> -b <branch> origin/<default>`.
That command leaves the branch checked out in `root/` unchanged. `<default>` is the remote's default branch.

The one class of non-checkout item that may live at this level is **repository-level shared
resources**: things that belong to the repository as a whole and must survive branch switches —
a local package feed (`local-feed/`), agent session state (`.session/`, section 10.7 below),
repository-level instruction files. They are never confused with checkouts: a checkout is
`root/` or a named worktree, nothing else.

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
- The branch checked out in `root/` is the repository's default branch. Read its name from the remote (`origin/HEAD`). It is sometimes `main` and sometimes `master`. Do not assume either name.
- Do not switch branches in `root/`. `git switch`, `git checkout` of another branch, and `git checkout -b` are forbidden in the base checkout. Switching the base moves the checkout that parallel agents are using as the trunk.
- A new branch exists only as a sibling worktree, created with `git worktree add ../<worktree-name> -b <branch> origin/<default>` from `root/` after the sync in 10.9. That command does not change the branch checked out in `root/`.
- The base is kept fast-forward-only against `origin/<default>`.
- Work happens in a worktree. A worktree is merged into the default branch before the worktree is pruned.
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

**Rule.** Never branch from a stale base. Before `git worktree add`:

1. **Sync first.** Section 10.9. `git fetch origin --prune`, then fast-forward `root/` with `git merge --ff-only origin/<default>`. If it will not fast-forward, stop.
2. **Check for open pull requests.** If any are open against the default branch, **ask whether they
   should be merged first**, and wait for the answer. Do not open a branch that is about to
   be made obsolete by a merge, and do not assume the answer either way.
3. **Create the worktree from the remote ref.** From `root/`: `git worktree add ../<worktree-name> -b <name> origin/<default>`. Do not run `git switch`, `git checkout` of another branch, or `git checkout -b` in `root/`. The base stays on the default branch for every other agent working in parallel.

**Read the default branch's name from the remote.** It is not always `main` and not always `master`;
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
reproduce a bug, to bisect, to build against a released tag — pass that ref to `git worktree add`
and **say so in the branch name or the pull request**. `root/` stays on the default branch.
A deliberate old base is fine. An accidental one is the failure this rule prevents.

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

## 10.7 Agent session state lives in `.session/`, not in AppData

**Rule.** The running state an agent accumulates while working a repository — session
checkpoints, resume files, per-session scratch — is stored **inside the repository directory**,
keyed by provider, model and session id:

```text
${repos_root}/{repository_owner}/{repository_name}/.session/{provider}/{model}/{session-id}/
```

Worked example:

```text
repositories/acme/payments/.session/claude/opus/20261009-134054/
  session_state.md
  timeline.md
```

Because `.session/` is a sibling of `root/`, the state is shared by every worktree of that
repository and lives outside all git trees — it is never committed, and it moves when the
repository moves. A provider's own store under the user's `AppData`/`Local` directories is a
**cache the vendor owns, not state of record**: nothing of record goes there under this
convention. `{session-id}` is unique per session — agents do not write into another session's
directory — and a session's directory is deleted once its state is captured elsewhere.

## 10.9 Sync with origin before any create, read, update, or delete

**Rule.** Before any create, read, update, or delete of repository content, sync `root/` with `origin`:

1. `git fetch origin --prune`.
2. Fast-forward only: `git merge --ff-only origin/<default>`, with `<default>` read from the remote.
3. If `root/` will not fast-forward, stop. Do not start the create, read, update, or delete.

A read of a stale base is a read of the wrong repository. The sync is part of the operation. Sibling worktrees are not a substitute for it: their checkouts are not the default branch.

## 10.10 Exploring a repository reads `root/` only

**Rule.** When exploring a repository — listing, searching, or reading files to learn what the repository is — read `root/` and ignore every sibling worktree.

A sibling worktree is unmerged work. It is not the repository. Read or change a worktree only when the instruction names that worktree, or when the task is about the worktrees themselves, such as cleaning every working branch.

## 10.11 Review checklist

- [ ] Base checkout is named `root` and sits inside the repository directory.
- [ ] Every worktree is a sibling of `root`, not nested within it.
- [ ] No worktree sits under `.agents/worktrees/`, inside `root/`, in a `worktrees/`
      container, or outside the repository directory.
- [ ] Repository-level shared resources (a local feed, `.session/`) sit at the
      repository-directory level, outside every checkout, and are not mistaken for checkouts.
- [ ] Agent session state lives under `.session/{provider}/{model}/{session-id}/` inside the
      repository directory — never as the canonical store in AppData/Local.
- [ ] The base has no local commits and no uncommitted changes.
- [ ] The branch checked out in `root/` is the remote's default branch, and it was not switched.
- [ ] Before any create, read, update, or delete, `root/` was fetched and fast-forwarded to `origin/<default>`.
- [ ] Exploration of the repository read `root/` only, unless the task named a worktree or was about the worktrees themselves.
- [ ] The base's default branch is a fast-forward of origin's default branch.
- [ ] Unfinished work is in a worktree, not in the base.
- [ ] Before the worktree was created: fetched, open pull requests against the default branch
      raised for a merge decision, and the base fast-forwarded to that branch's tip.
- [ ] The worktree was cut from the remote default branch with `git worktree add`, and that command did not change the branch checked out in `root/`.
- [ ] The default branch's name was read from the remote rather than assumed.
- [ ] Any deliberately old base is stated in the branch name or the pull request.
- [ ] Every worktree whose work is merged or abandoned has been removed **and** pruned, leaving no
      entry under `.git/worktrees`.
- [ ] No prune was run while a worktree's commits were unaccounted for, and nothing was removed
      without a verified archive.

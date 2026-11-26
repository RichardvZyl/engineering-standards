<!-- ─────────────────────────────────────────────────────────────────────────────
     VENDORED — READ-ONLY IN THIS REPOSITORY.
     This file is synced from the upstream engineering-standards repository.
     Local edits are overwritten by the next standards-sync pull request.
     Disagree with a rule? Change it upstream and let the sync carry it everywhere.
     ───────────────────────────────────────────────────────────────────────────── -->

# 03 — Engineering hygiene

## Style is settled by configuration

Formatting is not a review topic. The repository's `.editorconfig` decides it, the build enforces
it, and a review comment about brace placement is a review comment that displaced a real one.

The `.editorconfig` shipped alongside these standards sets: four-space indent, CRLF, `System.*`
usings first, no unnecessary usings (raised to a warning so the build sees them), and file-scoped
namespaces.

Where the build can enforce a rule, it does. **A convention that only lives in a document is a
convention that erodes** — see [`06`](./06-review-standards.md) on what review is for once the
mechanical checks are automated.

## Git

- **No stray branches.** Trunk-only repositories never get non-default branches from an agent,
  even when a ruleset bypass or admin role would allow it. Everywhere else, branches exist only
  as linked worktrees beside `root/` (and `fully-merged`); no parking branches. Exceptions only
  from the sole exception authorizer named in `AGENTS.md`, given directly — not relayed. Full
  rule: [`10`](./10-repository-and-worktree-layout.md) §10.10.
- **Trunk-based, with short-lived branches.** A branch that lives long enough to need a merge
  strategy has become a fork.
- **Small, reviewable commits with a message that says why.** The diff already says what. The
  commit message cites the planning identifier ([`04`](./04-documentation-layout.md)) — that
  citation is the join between the plan and the history.
- **Build and tests are green before commit.** Not before merge — before commit. A red commit in
  the history makes bisect useless exactly when it is needed.
- **Incomplete work ships behind a feature flag** rather than living on a branch. Flags are
  removed once the feature is permanent; a flag nobody will ever flip is dead code with extra
  branching.
- **Force-pushing a shared branch, and history rewriting on anything published, are prohibited.**
- **Delete a branch only once it carries zero unique commits.** Confirm with
  `git merge-base --is-ancestor <branch> <target>` before removing it; use
  `git branch -d`, never `-D`, so git refuses if work would be lost. Record the SHA of
  anything deleted so it remains recoverable from the reflog.
- **Sequence PRs by containment (stacked pull requests).** Before opening PRs, determine
  which branches are ancestors of others (`git merge-base --is-ancestor` across every
  pair). Open them oldest-first along the containment DAG. For a stack: the bottom PR
  targets the repository's integration tip ([`10`](./10-repository-and-worktree-layout.md)
  §10.8 — create `fully-merged` when that tip is missing); each upper PR targets the
  **branch below it**, not the integration tip, until that lower PR has merged. **Merge
  oldest-first.** After a lower PR merges, rebase or retarget every open upper PR onto the
  new integration tip before merging it. Do not merge an upper PR while its lower
  dependency is still open. Do not close or delete an upper branch while it still carries
  unique commits (same delete rule as above). Failure modes of out-of-order handling:
  history that cannot be cleanly reverted, **and** unique work on an upper branch falling
  off because the branch was closed, abandoned after a conflicted retarget, or never
  rebased onto the tip.
- **Resolve every stash before the session ends.** A parked stash is uncommitted work.
  Inspect first with `git stash show --include-untracked --stat`; a stash holding only
  git-ignored local files can be popped and dropped.
- **An agent session works in its own worktree, never in the primary checkout.** An editor
  holding `.git/index.lock` blocks every index-writing command in that repository — `add`,
  `commit`, `checkout` — and an agent reached through a sandbox frequently cannot clear the
  lock. A worktree carries its own index and HEAD against the same object store, so the
  collision cannot arise: from the base checkout run `git worktree add ../<worktree-name> -b <branch>
  origin/<default>`, work there, push, `git worktree remove` once merged. The worktree sits
  beside the base — `<repo>/<worktree-name>/` next to `<repo>/root/`, both direct
  children of the repository folder — never under `.agents/worktrees/`. It also keeps a
  human's in-progress work out of an agent's commit, and lets two agents hold the same
  repository on different branches at once.
- **`core.fileMode` is `false`, and the shipped `.gitattributes` is vendored unedited.** A
  repository read through a second filesystem — a container mount, WSL, a network share —
  otherwise reports every tracked file as rewritten on line endings and mode bits. That is
  indistinguishable from real uncommitted work, and it is exactly what `git add -A` commits.

## Secrets and configuration

- **No secret is committed, in any form, in any branch, ever** — not in a config file, not in a
  test fixture, not in a comment, not "temporarily". History is not a place a secret can be
  removed from; a committed secret is a rotated secret.
- Configuration that varies by environment comes from the environment. Local overrides are
  git-ignored by pattern, and the pattern is in `.gitignore` before the file exists.
- Connection details, keys and tokens are referenced, never inlined.

## Compliance is a design constraint

- **Never log personal data, secrets, or anything crossing a tenant boundary.** Logs are copied,
  shipped to third parties, and retained longer than the data they describe.
- Personal and financial data carries a **retention and deletion obligation**. Deletion is
  designed at the same time as storage, because a system that cannot delete cannot comply.
- Segregation of duties applies to the pipeline as much as the application: the person who
  authors a change is not the only person who can release it.
- An audit trail is **append-only**. A trail that can be updated in place is not evidence.

## Tests

- **Anything touching the database is tested against a real database**, in a container, not
  against an in-memory substitute. In-memory providers do not reproduce isolation levels, lock
  behaviour, constraint enforcement or plan choice — which is the whole of what needs testing.
- A concurrency fix ships with a test that **fails without the fix**. A test that passes before
  and after has demonstrated nothing.
- Tests are deterministic. A test that fails once per hundred runs is either a broken test or an
  unfixed race, and both must be resolved rather than retried.
- Coverage is a diagnostic, never a target.

## Dependencies

- A new dependency is a decision with a maintenance cost, recorded when the choice is close
  ([`05`](./05-decision-records.md)).
- Versions are pinned and updated deliberately.
- Prefer the platform's own facility over a package that wraps it thinly.

## Repository instructions

Repository-level agent instruction files — `AGENTS.md`, `CLAUDE.md`, or whatever a given tool
reads — are **binding on both people and assistants** working in that repository. Where such a
file contradicts these standards, the repository's file wins for repository-specific facts, and
these standards win for conventions. Project context belongs there; conventions belong here.

## Deletion is recoverable

**Rule.** Permanent deletion is not a default action. The preferred way to delete a file or
directory is through the platform's recoverable-destruction facility — the Recycle Bin on
Windows, the Trash on macOS — never a force-rm equivalent, unless the change is explicitly
requested as unrecoverable and that request is recorded.

**Reason.** A move to the recoverable-destruction facility can be walked back; a force-rm
cannot. Recoverable deletion preserves the ability to undo, exactly what the git rules above
demand of branches and stashes. Automating deletion without it turns an accident into a
permanent one, and a system that deletes without an undo path cannot be operated safely.

**Enforcement.** Where the agent harness supports pre-tool hooks, block the permanent-delete
commands and route deletion through a recoverable helper. The hook raises the cost of an
accident; it is not a security boundary — a person deliberately deleting, or an explicit and
recorded request for unrecoverable deletion, is still honoured.
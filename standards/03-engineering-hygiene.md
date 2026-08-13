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
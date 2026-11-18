# Plan: stacked PR merge-order and `fully-merged` creation

Planning identifier: `stacked-pr-merge-order-20261118`

## Goal

Extend the public engineering-standards set so stacked / containment-ordered pull requests have explicit merge-order rules and mitigations; require creating the integration tip `fully-merged` when it is missing; exempt trunk-only repositories that forbid non-trunk branches. Wording stays generic (no host paths, owners, products, or subscriptions).

## Builds on (does not reverse)

- [standards/03](../../standards/03-engineering-hygiene.md) — existing **Sequence PRs by containment** bullet.
- [standards/10 §10.8](../../standards/10-repository-and-worktree-layout.md) — `fully-merged` as publish/integration tip.
- Existing 03 rule: delete a branch only when it carries zero unique commits.

## Non-goals

- Naming any local drive, machine, person, or vendor subscription.
- Rewriting what `fully-merged` means for deploy (standard 18 still owns publish-from-`fully-merged`).
- Tooling bots or GitHub Actions in this change (document the rule; enforcement may follow later).

## Edits

1. **`standards/03`** — Expand the containment bullet into operational stacked-PR rules: upper base = lower branch; merge oldest-first; after lower merges, rebase/retarget upper onto the integration tip; do not close/delete an upper branch while it still has unique commits; failure modes include unclean revert **and** unique work falling off.
2. **`standards/10` §10.8** — If `fully-merged` is absent on a repository that accepts feature work / publish integration, create it as a fast-forward of the remote default trunk (trunk name read from the remote). Cross-link 03. Exempt repositories whose recorded policy forbids creating non-trunk local branches (meta / allowlist / non-project container repositories)—those stay trunk-only and do not create `fully-merged` or stacked feature branches.
3. **`standards/VERSION`** `0.9.0` → `0.10.0` (minor: material tightening / new obligations).
4. **`CHANGELOG.md`** — dated 0.10.0 block; empty Unreleased.
5. **README** standards table — only if a new section heading needs indexing (prefer no new standard number).

## Acceptance

- [ ] 03 and 10 text reviewable, generic, no environment-specific names.
- [ ] `pwsh ./scripts/Test-StandardsIntegrity.ps1` (and proprietary leak script if required) exit 0.
- [ ] Commits on `feat/stacked-pr-merge-order-20261118` (stacked on standard 18 tip).
- [ ] Merged into local `fully-merged` (and pushed when credentials allow).

## Merge order (dogfood)

1. Bottom (already open): standard 18 / `feat/deploy-artifacts-not-source-20261118` → `fully-merged` if not yet merged.
2. This branch → `fully-merged` after (or including) that tip.
3. Do not delete this branch until `git merge-base --is-ancestor` confirms it is contained in `fully-merged`.

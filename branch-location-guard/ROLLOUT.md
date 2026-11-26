# Rollout — branch-location guard into private repos

Source of truth: this folder in `engineering-standards`.
Follow-up agents add `.githooks/` via **draft PRs only**. Do not merge, do not
force-push, do not edit other repos from the agent that only lands this package.

## Inventory source

Private repositories under the `RichardvZyl` GitHub user, as visible to the
Cursor GitHub connection on 2026-11-26. The cloud-agent `gh` token could not
list private repos via `user/repos` (403); the list below came from the Cursor
GitHub tools instead. **Treat as complete for that connection, not as a proof
that no other private repos exist** (forks under other owners, org repos, or
repos the connection cannot see are unmarked).

## No-branch targets

| Target | On GitHub? | Mode | Notes |
|---|---|---|---|
| Development-root git repo | No (local only) | `NoBranch` | The git repo whose working tree is the development root folder. Not a GitHub remote. Install hooks on the local clone only. |
| Drive-root git repo | No (local only) | `NoBranch` | The git repo whose working tree is the drive root. Not a GitHub remote. Install hooks on the local clone only. |
| `grok-bot-workspace` | Yes (private) | `NoBranch` | Draft PR with `.githooks/` + install `-Mode NoBranch`. Also run the GitHub branch-creation audit. |

## Private GitHub repos (location mode unless noted)

Copy `.githooks/` from this package; open a draft PR; on each machine set
`BRANCH_GUARD_BASE` and run `Install-BranchGuard.ps1 -Apply` (or `-Mode NoBranch`
where marked).

| Repo | Default branch | Guard mode | Follow-up |
|---|---|---|---|
| `A2A` | master | Location | Draft PR: add `.githooks/`. |
| `A2A-Project-folder` | main | Location | Draft PR: add `.githooks/`. |
| `Abstractions` | master | Location | Draft PR: add `.githooks/`. |
| `AEZLedger` | master | Location | Draft PR: add `.githooks/`. |
| `agent-harness` | master | Location | Draft PR: add `.githooks/`. |
| `agent-team` | main | Location | Draft PR: add `.githooks/`. |
| `agent-tools-mcp` | main | Location | Draft PR: add `.githooks/`. |
| `agentic-data-stack` | main | Location | Draft PR: add `.githooks/`. |
| `autonomous-run-demo` | master | Location | Draft PR: add `.githooks/`. |
| `autonomous-worker` | main | Location | Draft PR: add `.githooks/`. |
| `buzzboard-private` | main | Location | Draft PR: add `.githooks/`. |
| `curriculum-vitae` | master | Location | Draft PR: add `.githooks/`. |
| `deterministic-ai-proof` | main | Location | Draft PR: add `.githooks/`. |
| `Development-Docs` | master | Location | Draft PR: add `.githooks/`. |
| `grok-bot-workspace` | main | **NoBranch** | Draft PR: add `.githooks/`. After merge/local pull: `Install-BranchGuard.ps1 -Apply -Mode NoBranch`. Run `Test-GitHubBranchCreationPolicy.ps1 -Repo RichardvZyl/grok-bot-workspace`. |
| `husk` | master | Location | Draft PR: add `.githooks/`. |
| `job-hunter` | main | Location | Draft PR: add `.githooks/`. |
| `kanban` | main | Location | Draft PR: add `.githooks/`. |
| `librechat-admin-panel` | main | Location | Draft PR: add `.githooks/`. |
| `OrchestrationSystem` | master | Location | Draft PR: add `.githooks/`. |
| `perseus-memory-viewer` | master | Location | Draft PR: add `.githooks/`. |
| `perseus-vault` | main | Location | Draft PR: add `.githooks/`. |
| `provider-usage-mcp` | master | Location | Draft PR: add `.githooks/`. |
| `QuantEngine` | master | Location | Draft PR: add `.githooks/`. |
| `repo-root-example` | main | Location | Draft PR: add `.githooks/`. |
| `Repos` | v1.2 | Location | Draft PR: add `.githooks/`. Confirm whether layout uses `root/` + worktrees under the owner base; if this repo is itself a special layout, re-check mode before applying. |
| `reusable-ai-tools` | master | Location | Draft PR: add `.githooks/`. |
| `RichardvZyl.github.io` | master | Location | Draft PR: add `.githooks/`. |
| `splyce-website` | master | Location | Draft PR: add `.githooks/`. |
| `switchboard` | main | Location | Draft PR: add `.githooks/`. |
| `sync-local-and-google` | main | Location | Draft PR: add `.githooks/`. |

**Count visible:** 31 private GitHub repositories.

## Per-repo steps (follow-up agent)

For each Location-mode repo:

1. Branch from the default branch: `cursor/branch-location-guard-<suffix>`.
2. Copy `engineering-standards/branch-location-guard/.githooks/` → `<repo>/.githooks/`.
3. Optionally copy `Install-BranchGuard.ps1` and `Test-GitHubBranchCreationPolicy.ps1` into `scripts/` (or keep only `.githooks/` if the repo prefers a minimal tree).
4. Open a **draft** PR. Do not merge.
5. Leave a PR note: developers must set `BRANCH_GUARD_BASE` and run
   `pwsh path/to/Install-BranchGuard.ps1 -Apply` once per clone.

For `grok-bot-workspace` (and the two local-only repos): same, but
`-Apply -Mode NoBranch`, and run the GitHub audit script where a remote exists.

## Could not see / undecidable

| Item | Status |
|---|---|
| Private repos invisible to the Cursor GitHub connection | Unknown — re-list with an owner-scoped token if completeness matters |
| Org-owned private repos (if any) | Not queried; this inventory is user `RichardvZyl` only |
| Development-root and drive-root remotes | Not on GitHub (404 for plausible names); local install only |
| Whether GitHub rulesets already block non-default branches | Per-repo; run `Test-GitHubBranchCreationPolicy.ps1` after the draft PR lands |
| Public repos under the same user | Out of scope for this private-repo rollout (including this `engineering-standards` kit itself) |

## Machine setup (once per developer)

1. Set `BRANCH_GUARD_BASE` permanently in the user environment to the owner
   folder that contains each `<repo>/root` and `<repo>/<worktree>` pair.
2. After pulling a repo that gained `.githooks/`, run the installer with `-Apply`
   (or `-Apply -Mode NoBranch` for no-branch targets).
3. Do **not** run the installer on CI or cloud agent VMs.

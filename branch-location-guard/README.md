# Branch-location guard

Fail-closed local git hooks that enforce the **Branching location** rule via
`Get-Decision`:

1. Refuse outside `BRANCH_GUARD_BASE`
2. Refuse wrong depth — must be `${BRANCH_GUARD_BASE}/<repo>/<worktree>`
3. Refuse the root leaf (`BRANCH_GUARD_ROOT_NAME`, default `root`)
4. Refuse when `git-dir == common-dir` (primary checkout, not a linked worktree)

`BRANCH_GUARD_BASE` comes **only** from the environment. There is no hardcoded
default. If unset, the guard refuses.

## What ships

| Path | Role |
|---|---|
| `.githooks/` | Committable hooks + `Get-Decision` scripts |
| `Install-BranchGuard.ps1` | Plan-only by default; `-Apply` sets local `core.hooksPath=.githooks` |
| `Test-GitHubBranchCreationPolicy.ps1` | Read-only audit of GitHub branch rules/rulesets |
| `tests/` | Original five `Get-Decision` Pester cases + WSL / unset-base / no-branch / log |
| `Run-Tests.ps1` | Runs tests; skips PowerShell tests gracefully if Pester is missing |
| `ROLLOUT.md` | Private-repo inventory and per-repo follow-up steps |

## Activation (local only)

```powershell
pwsh ./Install-BranchGuard.ps1                         # plan
pwsh ./Install-BranchGuard.ps1 -Apply                  # enforce (default)
pwsh ./Install-BranchGuard.ps1 -Apply -Mode log
pwsh ./Install-BranchGuard.ps1 -Apply -Mode no-branch
pwsh ./Install-BranchGuard.ps1 -Uninstall
```

`core.hooksPath` is **local** git config and is not pushed. CI and cloud agent
VMs therefore do **not** run these hooks unless someone deliberately installs
them there (do not).

When `-Apply` would replace a differing hook file, the previous file is kept as
`<name>.prev-YYYYMMDD` (never `backup` / `.bak`).

## Environment

| Variable | Required | Meaning |
|---|---|---|
| `BRANCH_GUARD_BASE` | Yes (enforce/log) | Owner folder containing each `<repo>/<worktree>` |
| `BRANCH_GUARD_MODE` | No | `enforce` (default), `log`, or `no-branch` |
| `BRANCH_GUARD_ROOT_NAME` | No | Leaf name refused as the base checkout (default `root`) |
| `BRANCH_GUARD_LOG` | No | Append-only log path; writes `<repoLeaf> <decision>` only |
| `branchGuard.mode` | No | Local git config mirror of mode (set by installer) |

### Modes

- **enforce** — refuse on `Get-Decision` failure (default, fail closed)
- **log** — run the same checks, record leaf + decision, allow the operation
- **no-branch** — only the repository default branch may be used (inverted guard)

### WSL

When inside WSL (`WSL_DISTRO_NAME` or `/proc/version` contains `microsoft`),
`/mnt/<letter>/...` paths are translated to `<LETTER>:\...` before comparison.
If `pwsh` is unreachable, POSIX `branch-location-guard.sh` implements the same
decision.

### pre-push stdin

`pre-push` fail-closes if git's ref stdin cannot be consumed.

## No-branch targets

Development-root git repo, drive-root git repo, and `grok-bot-workspace`: install
with `-Mode no-branch`. See README limits: no pre-checkout / pre-`worktree add`
hook; `post-checkout` and `reference-transaction` are best-effort.

## Tests

```powershell
pwsh ./Run-Tests.ps1
sh ./tests/test-posix-path.sh
```

## Rollout

See [`ROLLOUT.md`](./ROLLOUT.md). Follow-up agents copy `.githooks/` via draft PRs only.

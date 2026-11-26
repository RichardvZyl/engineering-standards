# Branch-location guard

Fail-closed local git hooks that enforce the **Branching location** rule:

> Commits and pushes only from a linked worktree at
> `${BRANCH_GUARD_BASE}/<repo>/<worktree>`. Never from
> `${BRANCH_GUARD_BASE}/<repo>/root`. Never outside the base.

`BRANCH_GUARD_BASE` comes **only** from the environment. There is no hardcoded
default. If it is unset, the guard refuses with a message telling you to set it.

## What ships

| Path | Role |
|---|---|
| `.githooks/` | Committable hooks + decision scripts (`pre-commit`, `pre-push`, `post-checkout`, `reference-transaction`, PowerShell + POSIX helpers) |
| `Install-BranchGuard.ps1` | Plan-only by default; `-Apply` sets local `core.hooksPath=.githooks`; `-Uninstall` clears it |
| `Test-GitHubBranchCreationPolicy.ps1` | Read-only audit of GitHub branch rules/rulesets |
| `tests/` | Pester + POSIX sh tests |
| `Run-Tests.ps1` | Runs tests; skips PowerShell tests gracefully if Pester is missing |
| `ROLLOUT.md` | Private-repo inventory and per-repo follow-up steps |

## Activation (local only)

Committed hooks are **not** active until local config points at them:

```powershell
pwsh ./Install-BranchGuard.ps1              # plan
pwsh ./Install-BranchGuard.ps1 -Apply       # set core.hooksPath=.githooks
pwsh ./Install-BranchGuard.ps1 -Apply -Mode NoBranch
pwsh ./Install-BranchGuard.ps1 -Uninstall
```

`core.hooksPath` is **local** git config. It is not pushed. CI runners and cloud
agent VMs therefore do **not** run these hooks unless someone deliberately
installs them there (do not).

When `-Apply` would replace an existing hook file that differs, the previous
file is kept as `<name>.prev-YYYYMMDD`. The installer never uses the names
`backup` or `.bak`.

## Environment

| Variable | Required | Meaning |
|---|---|---|
| `BRANCH_GUARD_BASE` | Yes (location mode) | Owner folder that contains each `<repo>/root` and `<repo>/<worktree>` |
| `BRANCH_GUARD_MODE` | No | `location` (default) or `no-branch` |
| `branchGuard.mode` | No | Local git config; same values; set by the installer |

### WSL

When the hook runs inside WSL (`WSL_DISTRO_NAME` set, or `/proc/version` contains
`microsoft`), `/mnt/<letter>/...` paths are translated to `<LETTER>:\...` (via
`wslpath -w` when available) before comparison. A Windows-style
`BRANCH_GUARD_BASE` is accepted the same way. If `pwsh` / `powershell.exe` is
unreachable, the POSIX `branch-location-guard.sh` implements the same decision
so WSL clones are not blocked by missing PowerShell tooling.

## No-branch mode

Some repositories must not grow feature branches or worktrees (estate policy):
the development-root git repo, the drive-root git repo, and `grok-bot-workspace`.
For those, install with `-Mode NoBranch`:

- `pre-commit` / `pre-push` refuse unless the current branch is the default branch
- `post-checkout` exits non-zero on a non-default branch (after the fact)
- `reference-transaction` refuses updates to non-default `refs/heads/*`

### Limits (documented, not papered over)

- Git has **no** pre-checkout and **no** pre-`worktree add` hook.
  `post-checkout` can only fail loudly after the fact.
- `reference-transaction` blocks many branch ref updates but is not a substitute
  for GitHub rulesets; run `Test-GitHubBranchCreationPolicy.ps1` to audit remotes.
- Detached HEAD is refused in no-branch mode.

## Roll a copy into another repo

1. Copy this package's `.githooks/` directory to the target repo root as `.githooks/`.
2. Optionally copy `Install-BranchGuard.ps1` next to it (or under `scripts/`).
3. Open a **draft** PR with those files.
4. On each developer machine: set `BRANCH_GUARD_BASE`, then
   `pwsh ./Install-BranchGuard.ps1 -Apply` (or `-Mode NoBranch` where required).

See [`ROLLOUT.md`](./ROLLOUT.md) for the private-repo list and follow-up checklist.

## Tests

```powershell
pwsh ./Run-Tests.ps1
# or directly:
pwsh -Command "Invoke-Pester -Script ./tests/BranchLocationGuard.Tests.ps1"
sh ./tests/test-posix-path.sh
```

On Linux, tests run when `pwsh` is available; `Run-Tests.ps1` exits 0 with a skip
message if Pester is not installed. The POSIX script runs with any POSIX `sh`.

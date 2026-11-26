#Requires -Version 7.0
<#
.SYNOPSIS
  Enforce branching location (or no-branch mode) for commit/push hooks.

.DESCRIPTION
  Location mode (default): allow only when the git toplevel is
  ${BRANCH_GUARD_BASE}/<repo>/<worktree> with <worktree> not equal to "root".
  BRANCH_GUARD_BASE must be set in the environment; there is no hardcoded default.
  Fail closed.

  No-branch mode (BRANCH_GUARD_MODE=no-branch or git config branchGuard.mode):
  allow only when the current branch is the repository default branch.

  On WSL, Windows and /mnt/<letter>/ paths are normalised before comparison.
#>
[CmdletBinding()]
param(
    [ValidateSet('Location', 'NoBranch')]
    [string] $Mode,

    # Injected for tests. Defaults to git rev-parse --show-toplevel.
    [string] $Toplevel,

    # Injected for tests. Defaults to the current branch name.
    [AllowEmptyString()]
    [string] $CurrentBranch,

    # Injected for tests. Defaults to the resolved default branch.
    [AllowEmptyString()]
    [string] $DefaultBranch,

    # Injected for tests. Defaults to $env:BRANCH_GUARD_BASE.
    [string] $Base,

    # When set, print Allow/Refuse and reason; still exit non-zero on refuse.
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
. (Join-Path $here 'BranchLocationGuard.Helpers.ps1')

$decisionParams = @{}
if ($PSBoundParameters.ContainsKey('Mode') -and $Mode) { $decisionParams.Mode = $Mode }
if ($PSBoundParameters.ContainsKey('Toplevel') -and $Toplevel) { $decisionParams.Toplevel = $Toplevel }
if ($PSBoundParameters.ContainsKey('CurrentBranch')) { $decisionParams.CurrentBranch = $CurrentBranch }
if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $decisionParams.DefaultBranch = $DefaultBranch }
if ($PSBoundParameters.ContainsKey('Base')) { $decisionParams.Base = $Base }

$result = Invoke-BranchGuardDecision @decisionParams

if ($PassThru) {
    [pscustomobject]@{
        Allowed = $result.Allowed
        Reason  = $result.Reason
        Mode    = $result.Mode
    }
}

if (-not $result.Allowed) {
    [Console]::Error.WriteLine("branch-location-guard: REFUSED. $($result.Reason)")
    exit 1
}

exit 0

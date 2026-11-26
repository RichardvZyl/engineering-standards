#Requires -Version 7.0
<#
.SYNOPSIS
  Enforce branching location (or no-branch mode) for commit/push hooks.

.DESCRIPTION
  Location (enforce|log): Get-Decision — outside-base, wrong-depth
  BRANCH_GUARD_BASE/<repo>/<worktree>, refuse ROOT leaf (BRANCH_GUARD_ROOT_NAME),
  refuse git-dir == common-dir. BRANCH_GUARD_BASE is required (no hardcoded default).

  Mode:
    enforce (default) — refuse on failure
    log               — allow, but record repo leaf + decision when BRANCH_GUARD_LOG is set
    no-branch         — only the default branch may be used

  BRANCH_GUARD_LOG: when set, append "<repoLeaf> <decision>" (no full paths).
#>
[CmdletBinding()]
param(
    [ValidateSet('enforce', 'log', 'no-branch', 'Location', 'NoBranch', 'Enforce', 'Log')]
    [string] $Mode,

    [string] $Toplevel,

    [AllowEmptyString()]
    [string] $CurrentBranch,

    [AllowEmptyString()]
    [string] $DefaultBranch,

    [string] $Base,

    [string] $GitDir,

    [string] $CommonDir,

    [string] $RootName,

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
if ($PSBoundParameters.ContainsKey('GitDir') -and $GitDir) { $decisionParams.GitDir = $GitDir }
if ($PSBoundParameters.ContainsKey('CommonDir') -and $CommonDir) { $decisionParams.CommonDir = $CommonDir }
if ($PSBoundParameters.ContainsKey('RootName') -and $RootName) { $decisionParams.RootName = $RootName }

$result = Invoke-BranchGuardDecision @decisionParams

Write-BranchGuardLog -RepoLeaf $result.RepoLeaf -Decision $result.Decision

$resolvedMode = $result.Mode
$shouldRefuse = (-not $result.Allowed) -and ($resolvedMode -ne 'log')

if ($PassThru) {
    [pscustomobject]@{
        Allowed  = (-not $shouldRefuse)
        Reason   = $result.Reason
        Mode     = $resolvedMode
        Code     = $result.Code
        Decision = $result.Decision
        RepoLeaf = $result.RepoLeaf
    }
}

if (-not $result.Allowed) {
    if ($resolvedMode -eq 'log') {
        [Console]::Error.WriteLine("branch-location-guard: LOG $($result.Decision) — $($result.Reason)")
        exit 0
    }
    [Console]::Error.WriteLine("branch-location-guard: REFUSED. $($result.Reason)")
    exit 1
}

exit 0

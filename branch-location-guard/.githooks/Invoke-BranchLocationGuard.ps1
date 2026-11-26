#Requires -Version 7.0
<#
.SYNOPSIS
  Git guard: refuses commit/push unless the working tree is a linked worktree placed as
  <BaseRoot>\<repo>\<worktree>, never <BaseRoot>\<repo>\root and never outside BaseRoot.
  Enforces the AGENTS.md "Branching location" rule. Fail closed: any error or undecidable state refuses.
.NOTES
  Exit 0 = allow, 1 = refuse. Logs repo name + decision only (no paths with user names, no command text).
  Env: BRANCH_GUARD_BASE (required; no hardcoded default), BRANCH_GUARD_MODE = enforce (default) | log | no-branch,
       BRANCH_GUARD_ROOT_NAME (default root), BRANCH_GUARD_LOG (optional log file).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('pre-commit', 'pre-push', 'post-checkout', 'manual')]
    [string] $Hook,

    [ValidateSet('enforce', 'log', 'no-branch', 'Location', 'NoBranch', 'Enforce', 'Log')]
    [string] $Mode,

    # Injected for tests
    [string] $Toplevel,
    [string] $GitDir,
    [string] $CommonDir,
    [string] $Base,
    [string] $RootName,
    [AllowEmptyString()]
    [string] $CurrentBranch,
    [AllowEmptyString()]
    [string] $DefaultBranch,

    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$here = $PSScriptRoot
. (Join-Path $here 'BranchLocationGuard.Helpers.ps1')

$resolvedMode = Get-BranchGuardMode -Mode $Mode
$rootName = if ($RootName) { $RootName } elseif ($env:BRANCH_GUARD_ROOT_NAME) { $env:BRANCH_GUARD_ROOT_NAME } else { 'root' }

try {
    if ($resolvedMode -eq 'no-branch') {
        $nb = @{}
        if ($PSBoundParameters.ContainsKey('CurrentBranch')) { $nb.CurrentBranch = $CurrentBranch }
        if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $nb.DefaultBranch = $DefaultBranch }
        $d = Get-NoBranchDecision @nb
    } else {
        $base = if ($Base) { $Base } elseif ($env:BRANCH_GUARD_BASE) { $env:BRANCH_GUARD_BASE } else { $null }
        if (-not $base) { throw 'BRANCH_GUARD_BASE is not set' }

        $top = if ($Toplevel) { $Toplevel } else { (& git rev-parse --show-toplevel).Trim() }
        $gd = if ($GitDir) { $GitDir } else { (& git rev-parse --path-format=absolute --git-dir).Trim() }
        $common = if ($CommonDir) { $CommonDir } else { (& git rev-parse --path-format=absolute --git-common-dir).Trim() }
        if (-not $top -or -not $gd -or -not $common) { throw 'git returned an empty path' }

        $d = Get-Decision -Top $top -GitDir $gd -CommonDir $common -Base $base -RootName $rootName
    }
} catch {
    $d = @{ Allowed = $false; Reason = "undecidable: $($_.Exception.Message)"; Repo = '?'; Code = 'Undecidable' }
}

# Original log line shape: hook, repo name, allowed, mode, reason (no full paths).
Write-GuardLog ("{0} repo={1} allowed={2} mode={3} reason={4}" -f $Hook, $d.Repo, $d.Allowed, $resolvedMode, $d.Reason)

if ($PassThru) {
    [pscustomobject]@{
        Allowed = $d.Allowed
        Reason  = $d.Reason
        Repo    = $d.Repo
        Code    = $(if ($d.ContainsKey('Code')) { $d.Code } else { $d.Reason })
        Mode    = $resolvedMode
    }
}

if ($d.Allowed) { exit 0 }

[Console]::Error.WriteLine("BRANCH LOCATION GUARD: $Hook refused ($($d.Reason)). Create a worktree next to root\ and work there: <base>\<repo>\<new-worktree>. See AGENTS.md.")
if ($resolvedMode -eq 'log') { exit 0 }
exit 1

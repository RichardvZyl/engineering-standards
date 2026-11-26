#Requires -Version 7.0
<#
.SYNOPSIS
  Activate or deactivate the committed .githooks/ branch-location guard.

.DESCRIPTION
  Plan-only by default. Pass -Apply to set local core.hooksPath=.githooks.
  Pass -Uninstall to unset core.hooksPath (committed hooks remain; they stay
  inactive without that local config).

  Never overwrites an existing hook file without keeping a dated copy named
  <name>.prev-YYYYMMDD. Never uses the words backup or .bak.

  Committed hooks are NOT active on CI or cloud VMs unless someone runs -Apply
  there (they should not). core.hooksPath is local config and is not pushed.
#>
[CmdletBinding(DefaultParameterSetName = 'Plan')]
param(
    [Parameter(ParameterSetName = 'Apply')]
    [switch] $Apply,

    [Parameter(ParameterSetName = 'Uninstall')]
    [switch] $Uninstall,

    [ValidateSet('Location', 'NoBranch')]
    [string] $Mode = 'Location',

    # Repository root that contains (or will contain) .githooks/. Defaults to cwd.
    [string] $RepoRoot,

    # Source of the canonical .githooks tree. Defaults to this package's .githooks.
    [string] $SourceHooks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Stamp {
    return (Get-Date -Format 'yyyyMMdd')
}

function Write-PlanLine {
    param([string] $Message)
    Write-Host $Message
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Get-Location).Path
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

if ([string]::IsNullOrWhiteSpace($SourceHooks)) {
    $SourceHooks = Join-Path $PSScriptRoot '.githooks'
}
$SourceHooks = (Resolve-Path -LiteralPath $SourceHooks).Path

$targetHooks = Join-Path $RepoRoot '.githooks'
$stamp = Get-Stamp

Push-Location -LiteralPath $RepoRoot
try {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a git repository: $RepoRoot"
    }

    $currentHooksPath = (& git config --local --get core.hooksPath 2>$null)
    if ($LASTEXITCODE -ne 0) { $currentHooksPath = $null }

    $currentMode = (& git config --local --get branchGuard.mode 2>$null)
    if ($LASTEXITCODE -ne 0) { $currentMode = $null }

    if ($PSCmdlet.ParameterSetName -eq 'Uninstall') {
        Write-PlanLine "Unset local core.hooksPath (was: $(if ($currentHooksPath) { $currentHooksPath } else { '<unset>' }))"
        Write-PlanLine "Unset local branchGuard.mode (was: $(if ($currentMode) { $currentMode } else { '<unset>' }))"
        Write-PlanLine 'Committed .githooks/ files are left in place; without core.hooksPath they are inactive.'
        git config --local --unset-all core.hooksPath 2>$null | Out-Null
        git config --local --unset-all branchGuard.mode 2>$null | Out-Null
        Write-Host 'Uninstalled: local core.hooksPath and branchGuard.mode cleared.' -ForegroundColor Green
        return
    }

    $modeValue = if ($Mode -eq 'NoBranch') { 'no-branch' } else { 'location' }

    Write-PlanLine "Repo:          $RepoRoot"
    Write-PlanLine "Source hooks:  $SourceHooks"
    Write-PlanLine "Target hooks:  $targetHooks"
    Write-PlanLine "Mode:          $modeValue"
    Write-PlanLine "core.hooksPath now: $(if ($currentHooksPath) { $currentHooksPath } else { '<unset>' })"
    Write-PlanLine "Would set:     core.hooksPath=.githooks (local only; not pushed)"
    Write-PlanLine "Would set:     branchGuard.mode=$modeValue (local only)"
    Write-PlanLine 'CI/cloud:      hooks stay dormant unless -Apply is run there (do not).'

    if (-not (Test-Path -LiteralPath $SourceHooks)) {
        throw "Source hooks directory missing: $SourceHooks"
    }

    $sourceFiles = Get-ChildItem -LiteralPath $SourceHooks -File
    if (-not (Test-Path -LiteralPath $targetHooks)) {
        Write-PlanLine "Would create directory: $targetHooks"
    }

    foreach ($file in $sourceFiles) {
        $dest = Join-Path $targetHooks $file.Name
        if (Test-Path -LiteralPath $dest) {
            $existing = Get-FileHash -LiteralPath $dest -Algorithm SHA256
            $incoming = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
            if ($existing.Hash -ne $incoming.Hash) {
                $prev = "$dest.prev-$stamp"
                Write-PlanLine "Would keep existing as: $(Split-Path -Leaf $prev) then replace $($file.Name)"
            } else {
                Write-PlanLine "Unchanged: $($file.Name)"
            }
        } else {
            Write-PlanLine "Would add: $($file.Name)"
        }
    }

    if (-not $Apply) {
        Write-Host 'Plan only. Re-run with -Apply to make changes.' -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path -LiteralPath $targetHooks)) {
        New-Item -ItemType Directory -Path $targetHooks | Out-Null
    }

    foreach ($file in $sourceFiles) {
        $dest = Join-Path $targetHooks $file.Name
        if (Test-Path -LiteralPath $dest) {
            $existing = Get-FileHash -LiteralPath $dest -Algorithm SHA256
            $incoming = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
            if ($existing.Hash -ne $incoming.Hash) {
                $prev = "$dest.prev-$stamp"
                if (Test-Path -LiteralPath $prev) {
                    $i = 2
                    while (Test-Path -LiteralPath "$prev-$i") { $i++ }
                    $prev = "$prev-$i"
                }
                Move-Item -LiteralPath $dest -Destination $prev
            } else {
                continue
            }
        }
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        if ($file.Name -notmatch '\.(ps1|md)$') {
            # Best-effort executable bit for hook scripts on Unix
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $dest 2>$null | Out-Null
            }
        }
    }

    git config --local core.hooksPath .githooks
    git config --local branchGuard.mode $modeValue
    Write-Host "Applied: core.hooksPath=.githooks, branchGuard.mode=$modeValue" -ForegroundColor Green
    if ($Mode -eq 'Location') {
        Write-Host 'Remember: set BRANCH_GUARD_BASE in your environment (required; no default).' -ForegroundColor Yellow
    }
}
finally {
    Pop-Location
}

#Requires -Version 7.0
# Dot-sourced by Invoke-BranchLocationGuard.ps1 and Pester tests.
# Get-Decision matches Richard's original algorithm (Resolve-Norm + Split-Path depth);
# WSL translation and env-only base are approved extensions applied at the edges.

Set-StrictMode -Version Latest

function Test-IsWsl {
    if (-not [string]::IsNullOrWhiteSpace($env:WSL_DISTRO_NAME)) { return $true }
    if (Test-Path -LiteralPath '/proc/version') {
        $v = Get-Content -LiteralPath '/proc/version' -Raw -ErrorAction SilentlyContinue
        if ($v -and $v -match 'microsoft') { return $true }
    }
    return $false
}

function ConvertTo-WindowsPathStyle {
    param([Parameter(Mandatory)][string] $Path)

    $p = $Path.Trim().TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($p)) { return $p }

    if ($p -match '^/mnt/([A-Za-z])(/.*)?$') {
        $drive = $Matches[1].ToUpperInvariant()
        $rest = if ($Matches[2]) { ($Matches[2] -replace '/', '\').TrimStart('\') } else { '' }
        if ($rest) { return "${drive}:\${rest}" }
        return "${drive}:\"
    }

    if ($p -match '^[A-Za-z]:') {
        return (($p -replace '/', '\') -replace '\\+', '\')
    }

    if (Test-IsWsl) {
        $wslpath = Get-Command wslpath -ErrorAction SilentlyContinue
        if ($wslpath) {
            try {
                $converted = & wslpath -w $p 2>$null
                if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($converted)) {
                    return ($converted.Trim() -replace '/', '\').TrimEnd('\')
                }
            } catch { }
        }
    }

    return ($p -replace '/', '\')
}

# Original Resolve-Norm, with WSL/Unix-safe handling for drive-letter paths on Linux.
function Resolve-Norm([string]$p) {
    $p = ConvertTo-WindowsPathStyle -Path $p
    $p = (($p -replace '/', '\') -replace '\\+', '\').TrimEnd('\')
    if ($IsWindows) {
        try {
            return [IO.Path]::GetFullPath($p).TrimEnd('\')
        } catch {
            return $p
        }
    }
    return $p
}

function Get-WinParent([string]$p) {
    $p = $p.TrimEnd('\')
    $i = $p.LastIndexOf('\')
    if ($i -lt 0) { return '' }
    return $p.Substring(0, $i)
}

function Get-WinLeaf([string]$p) {
    $p = $p.TrimEnd('\')
    $i = $p.LastIndexOf('\')
    if ($i -lt 0) { return $p }
    return $p.Substring($i + 1)
}

function Get-BranchGuardRootName {
    $name = $env:BRANCH_GUARD_ROOT_NAME
    if ([string]::IsNullOrWhiteSpace($name)) { return 'root' }
    return $name.Trim()
}

function Get-BranchGuardMode {
    param([string] $Mode)

    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        switch -Regex ($Mode.Trim()) {
            '^(?i)log$' { return 'log' }
            '^(?i)no-?branch$' { return 'no-branch' }
            '^(?i)enforce$' { return 'enforce' }
            '^(?i)location$' { return 'enforce' }
            default { return 'enforce' }
        }
    }

    $cfg = $null
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $cfg = (& git config --get branchGuard.mode 2>$null)
        if ($LASTEXITCODE -ne 0) { $cfg = $null }
    }
    if (-not [string]::IsNullOrWhiteSpace($cfg)) {
        return (Get-BranchGuardMode -Mode $cfg)
    }

    $envMode = $env:BRANCH_GUARD_MODE
    if (-not [string]::IsNullOrWhiteSpace($envMode)) {
        return (Get-BranchGuardMode -Mode $envMode)
    }

    return 'enforce'
}

function Get-GitToplevel {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not available' }
    $top = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) { throw 'git returned an empty path' }
    return $top.Trim()
}

function Get-GitDirPair {
    $gitDir = (& git rev-parse --path-format=absolute --git-dir 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitDir)) { throw 'git returned an empty path' }
    $commonDir = (& git rev-parse --path-format=absolute --git-common-dir 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commonDir)) { throw 'git returned an empty path' }
    return [pscustomobject]@{ GitDir = $gitDir.Trim(); CommonDir = $commonDir.Trim() }
}

function Get-GitCurrentBranch {
    $b = (& git branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0) { $b = $null }
    if ([string]::IsNullOrWhiteSpace($b)) { return '' }
    return $b.Trim()
}

function Get-GitDefaultBranch {
    $sym = (& git symbolic-ref refs/remotes/origin/HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $sym -match 'refs/remotes/origin/(.+)$') {
        return $Matches[1]
    }
    foreach ($candidate in @('main', 'master')) {
        & git show-ref --verify --quiet "refs/remotes/origin/$candidate" 2>$null
        if ($LASTEXITCODE -eq 0) { return $candidate }
        & git show-ref --verify --quiet "refs/heads/$candidate" 2>$null
        if ($LASTEXITCODE -eq 0) { return $candidate }
    }
    return 'main'
}

# Original log helper: timestamp + message; swallow write errors; no full paths.
function Write-GuardLog([string]$m) {
    if (-not $env:BRANCH_GUARD_LOG) { return }
    try {
        Add-Content -LiteralPath $env:BRANCH_GUARD_LOG -Value ('{0} {1}' -f (Get-Date -Format o), $m)
    } catch { }
}

function Get-Decision {
    <#
      Original positional contract:
        Get-Decision -Top -GitDir -CommonDir -Base -RootName
      Also accepts -Toplevel as an alias for -Top (callers/tests).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Toplevel')]
        [string] $Top,

        [Parameter(Position = 1)]
        [string] $GitDir,

        [Parameter(Position = 2)]
        [string] $CommonDir,

        [Parameter(Position = 3)]
        [string] $Base,

        [Parameter(Position = 4)]
        [string] $RootName
    )

    if ([string]::IsNullOrWhiteSpace($Base)) {
        $Base = $env:BRANCH_GUARD_BASE
    }
    if ([string]::IsNullOrWhiteSpace($Base)) {
        return @{
            Allowed = $false
            Reason  = 'undecidable: BRANCH_GUARD_BASE is not set'
            Repo    = '?'
            Code    = 'UnsetBase'
        }
    }
    if ([string]::IsNullOrWhiteSpace($RootName)) {
        $RootName = Get-BranchGuardRootName
    }

    $top = Resolve-Norm $Top
    $base = Resolve-Norm $Base
    $parent = Get-WinParent $top
    $repoDir = Get-WinParent $parent
    $leaf = Get-WinLeaf $top
    $repoName = Get-WinLeaf $parent

    if (-not $top.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return @{ Allowed = $false; Reason = 'outside-base'; Repo = $repoName; Code = 'OutsideBase' }
    }
    if ((Resolve-Norm $repoDir) -ne $base) {
        return @{ Allowed = $false; Reason = 'wrong-depth (expected <base>\<repo>\<worktree>)'; Repo = $repoName; Code = 'WrongDepth' }
    }
    if ($leaf -ieq $RootName) {
        return @{ Allowed = $false; Reason = "branching inside $RootName\ is not allowed"; Repo = $repoName; Code = 'RootLeaf' }
    }
    if ((Resolve-Norm $GitDir) -ieq (Resolve-Norm $CommonDir)) {
        return @{ Allowed = $false; Reason = 'not a linked worktree (git-dir equals common-dir)'; Repo = $repoName; Code = 'PrimaryCheckout' }
    }
    return @{ Allowed = $true; Reason = 'ok'; Repo = $repoName; Code = 'Allow' }
}

function Get-NoBranchDecision {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string] $CurrentBranch = $null,
        [AllowNull()]
        [AllowEmptyString()]
        [string] $DefaultBranch = $null
    )

    $branchProvided = $PSBoundParameters.ContainsKey('CurrentBranch')
    $defaultProvided = $PSBoundParameters.ContainsKey('DefaultBranch')

    if (-not $branchProvided) {
        try { $CurrentBranch = Get-GitCurrentBranch } catch {
            return @{ Allowed = $false; Reason = "undecidable: $($_.Exception.Message)"; Repo = '?'; Code = 'NoBranch' }
        }
    }
    if (-not $defaultProvided) {
        try { $DefaultBranch = Get-GitDefaultBranch } catch {
            return @{ Allowed = $false; Reason = "undecidable: $($_.Exception.Message)"; Repo = '?'; Code = 'NoBranch' }
        }
    }

    if ([string]::IsNullOrWhiteSpace($CurrentBranch)) {
        return @{
            Allowed = $false
            Reason  = 'no-branch mode refuses detached HEAD; check out the default branch'
            Repo    = '?'
            Code    = 'NoBranchDetached'
        }
    }
    if ($CurrentBranch -ne $DefaultBranch) {
        return @{
            Allowed = $false
            Reason  = "no-branch mode: current branch '$CurrentBranch' is not the default branch '$DefaultBranch'"
            Repo    = $CurrentBranch
            Code    = 'NoBranchWrongBranch'
        }
    }
    return @{ Allowed = $true; Reason = 'ok'; Repo = $CurrentBranch; Code = 'Allow' }
}

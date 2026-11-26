#Requires -Version 7.0
# Dot-sourced by Invoke-BranchLocationGuard.ps1 and Pester tests.
# Pure decision helpers; no side effects beyond reading env/git when args omitted.

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

    # /mnt/<letter>/... -> <LETTER>:\...
    if ($p -match '^/mnt/([A-Za-z])(/.*)?$') {
        $drive = $Matches[1].ToUpperInvariant()
        $rest = if ($Matches[2]) { ($Matches[2] -replace '/', '\').TrimStart('\') } else { '' }
        if ($rest) { return "${drive}:\${rest}" }
        return "${drive}:\"
    }

    # Already Windows-ish
    if ($p -match '^[A-Za-z]:') {
        return (($p -replace '/', '\') -replace '\\+', '\')
    }

    # Try wslpath -w when available (WSL Unix path that is not under /mnt)
    if (Test-IsWsl) {
        $wslpath = Get-Command wslpath -ErrorAction SilentlyContinue
        if ($wslpath) {
            try {
                $converted = & wslpath -w $p 2>$null
                if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($converted)) {
                    return ($converted.Trim() -replace '/', '\').TrimEnd('\')
                }
            } catch {
                # fall through
            }
        }
    }

    return ($p -replace '/', '\')
}

function ConvertTo-ComparablePath {
    param([Parameter(Mandatory)][string] $Path)
    $win = ConvertTo-WindowsPathStyle -Path $Path
    return $win.ToLowerInvariant().TrimEnd('\')
}

function Get-BranchGuardMode {
    param([string] $Mode)

    if (-not [string]::IsNullOrWhiteSpace($Mode)) {
        return $Mode
    }

    $cfg = $null
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $cfg = (& git config --get branchGuard.mode 2>$null)
        if ($LASTEXITCODE -ne 0) { $cfg = $null }
    }

    if (-not [string]::IsNullOrWhiteSpace($cfg)) {
        switch -Regex ($cfg.Trim()) {
            '^(?i)no-?branch$' { return 'NoBranch' }
            '^(?i)location$' { return 'Location' }
            default { return 'Location' }
        }
    }

    $envMode = $env:BRANCH_GUARD_MODE
    if (-not [string]::IsNullOrWhiteSpace($envMode)) {
        switch -Regex ($envMode.Trim()) {
            '^(?i)no-?branch$' { return 'NoBranch' }
            default { return 'Location' }
        }
    }

    return 'Location'
}

function Get-GitToplevel {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is not available'
    }
    $top = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) {
        throw 'not inside a git work tree'
    }
    return $top.Trim()
}

function Get-GitCurrentBranch {
    $b = (& git branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0) { $b = $null }
    if ([string]::IsNullOrWhiteSpace($b)) {
        # Detached HEAD — fail closed for no-branch mode
        return ''
    }
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

function Test-PathUnderBase {
    param(
        [Parameter(Mandatory)][string] $ComparableBase,
        [Parameter(Mandatory)][string] $ComparablePath
    )
    if ($ComparablePath -eq $ComparableBase) { return $true }
    $prefix = $ComparableBase + '\'
    return $ComparablePath.StartsWith($prefix, [System.StringComparison]::Ordinal)
}

function Get-RelativeSegments {
    param(
        [Parameter(Mandatory)][string] $ComparableBase,
        [Parameter(Mandatory)][string] $ComparablePath
    )
    if ($ComparablePath -eq $ComparableBase) { return ,[string[]]@() }
    $prefix = $ComparableBase + '\'
    if (-not $ComparablePath.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
        return $null
    }
    $rel = $ComparablePath.Substring($prefix.Length)
    if ([string]::IsNullOrWhiteSpace($rel)) { return ,[string[]]@() }
    return ,[string[]]@(@($rel -split '\\+') | Where-Object { $_ -ne '' })
}

function Invoke-BranchGuardDecision {
    [CmdletBinding()]
    param(
        [string] $Mode,
        [string] $Toplevel,
        [AllowNull()]
        [AllowEmptyString()]
        [string] $CurrentBranch = $null,
        [AllowNull()]
        [AllowEmptyString()]
        [string] $DefaultBranch = $null,
        [string] $Base
    )

    $resolvedMode = Get-BranchGuardMode -Mode $Mode

    if ($resolvedMode -eq 'NoBranch') {
        $branchProvided = $PSBoundParameters.ContainsKey('CurrentBranch')
        $defaultProvided = $PSBoundParameters.ContainsKey('DefaultBranch')

        if (-not $branchProvided) {
            try { $CurrentBranch = Get-GitCurrentBranch } catch {
                return [pscustomobject]@{ Allowed = $false; Mode = $resolvedMode; Reason = "cannot determine current branch: $($_.Exception.Message)" }
            }
        }
        if (-not $defaultProvided -or [string]::IsNullOrWhiteSpace($DefaultBranch)) {
            if (-not $defaultProvided) {
                try { $DefaultBranch = Get-GitDefaultBranch } catch {
                    return [pscustomobject]@{ Allowed = $false; Mode = $resolvedMode; Reason = "cannot determine default branch: $($_.Exception.Message)" }
                }
            }
        }
        if ([string]::IsNullOrWhiteSpace($CurrentBranch)) {
            return [pscustomobject]@{
                Allowed = $false
                Mode    = $resolvedMode
                Reason  = 'no-branch mode refuses detached HEAD; check out the default branch'
            }
        }
        if ($CurrentBranch -ne $DefaultBranch) {
            return [pscustomobject]@{
                Allowed = $false
                Mode    = $resolvedMode
                Reason  = "no-branch mode: current branch '$CurrentBranch' is not the default branch '$DefaultBranch'. Do not create or commit on other branches in this repository."
            }
        }
        return [pscustomobject]@{
            Allowed = $true
            Mode    = $resolvedMode
            Reason  = "on default branch '$DefaultBranch'"
        }
    }

    # Location mode
    if ([string]::IsNullOrWhiteSpace($Base)) {
        $Base = $env:BRANCH_GUARD_BASE
    }
    if ([string]::IsNullOrWhiteSpace($Base)) {
        return [pscustomobject]@{
            Allowed = $false
            Mode    = $resolvedMode
            Reason  = 'BRANCH_GUARD_BASE is not set. Set it to the repositories owner folder (the directory that contains each <repo>/root and <repo>/<worktree> pair), then retry. There is no hardcoded default.'
        }
    }

    if ([string]::IsNullOrWhiteSpace($Toplevel)) {
        try { $Toplevel = Get-GitToplevel } catch {
            return [pscustomobject]@{ Allowed = $false; Mode = $resolvedMode; Reason = "cannot determine git toplevel: $($_.Exception.Message)" }
        }
    }

    $cmpBase = ConvertTo-ComparablePath -Path $Base
    $cmpTop = ConvertTo-ComparablePath -Path $Toplevel

    if (-not (Test-PathUnderBase -ComparableBase $cmpBase -ComparablePath $cmpTop)) {
        return [pscustomobject]@{
            Allowed = $false
            Mode    = $resolvedMode
            Reason  = "toplevel '$Toplevel' is outside BRANCH_GUARD_BASE. Clones and worktrees must live under the configured base."
        }
    }

    $segments = Get-RelativeSegments -ComparableBase $cmpBase -ComparablePath $cmpTop
    if ($null -eq $segments) {
        return [pscustomobject]@{
            Allowed = $false
            Mode    = $resolvedMode
            Reason  = "toplevel '$Toplevel' is outside BRANCH_GUARD_BASE."
        }
    }

    # Expect exactly <repo>/<worktree>
    $segmentList = @($segments)
    if ($segmentList.Count -ne 2) {
        return [pscustomobject]@{
            Allowed = $false
            Mode    = $resolvedMode
            Reason  = "toplevel must be BRANCH_GUARD_BASE/<repo>/<worktree> (exactly two levels under the base). Got $($segmentList.Count) level(s) under the base. Never commit from the repository folder itself or from nested paths."
        }
    }

    $leaf = $segmentList[1]
    if ($leaf -eq 'root') {
        return [pscustomobject]@{
            Allowed = $false
            Mode    = $resolvedMode
            Reason  = "commits and pushes are not allowed from <repo>/root. Create a linked worktree beside root and work there."
        }
    }

    return [pscustomobject]@{
        Allowed = $true
        Mode    = $resolvedMode
        Reason  = "linked worktree '$leaf' under repo '$($segmentList[0])'"
    }
}

#Requires -Version 7.0
# Dot-sourced by Invoke-BranchLocationGuard.ps1 and Pester tests.
# Decision core mirrors the original Get-Decision contract, plus approved extensions
# (env-only base, WSL translation, no-branch mode).

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
            '^(?i)location$' { return 'enforce' } # alias used briefly in the first rebuild
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
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is not available'
    }
    $top = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) {
        throw 'not inside a git work tree'
    }
    return $top.Trim()
}

function Get-GitDirPair {
    # Absolute git-dir and git-common-dir. Equal ⇒ primary checkout (not a linked worktree).
    $gitDir = (& git rev-parse --path-format=absolute --git-dir 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitDir)) {
        throw 'cannot resolve --git-dir'
    }
    $commonDir = (& git rev-parse --path-format=absolute --git-common-dir 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commonDir)) {
        throw 'cannot resolve --git-common-dir'
    }
    return [pscustomobject]@{
        GitDir    = $gitDir.Trim()
        CommonDir = $commonDir.Trim()
    }
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

function Write-BranchGuardLog {
    param(
        [string] $RepoLeaf,
        [string] $Decision
    )
    $logPath = $env:BRANCH_GUARD_LOG
    if ([string]::IsNullOrWhiteSpace($logPath)) { return }
    $leaf = if ([string]::IsNullOrWhiteSpace($RepoLeaf)) { '-' } else { $RepoLeaf }
    $line = "$leaf $Decision"
    $dir = Split-Path -Parent $logPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Value $line -Encoding utf8
}

function New-Decision {
    param(
        [bool] $Allowed,
        [string] $Code,
        [string] $Reason,
        [string] $RepoLeaf = '',
        [string] $Mode = 'enforce'
    )
    return [pscustomobject]@{
        Allowed  = $Allowed
        Code     = $Code
        Decision = $Code
        Reason   = $Reason
        RepoLeaf = $RepoLeaf
        Mode     = $Mode
    }
}

function Get-Decision {
    <#
      .SYNOPSIS
        Original decision contract: outside-base, wrong-depth, root leaf, git-dir==common-dir.
    #>
    [CmdletBinding()]
    param(
        [string] $Toplevel,
        [string] $Base,
        [string] $GitDir,
        [string] $CommonDir,
        [string] $RootName
    )

    if ([string]::IsNullOrWhiteSpace($Base)) {
        $Base = $env:BRANCH_GUARD_BASE
    }
    if ([string]::IsNullOrWhiteSpace($Base)) {
        return New-Decision -Allowed $false -Code 'UnsetBase' `
            -Reason 'BRANCH_GUARD_BASE is not set. Set it to the repositories owner folder (the directory that contains each <repo>/root and <repo>/<worktree> pair), then retry. There is no hardcoded default.'
    }

    if ([string]::IsNullOrWhiteSpace($RootName)) {
        $RootName = Get-BranchGuardRootName
    }

    if ([string]::IsNullOrWhiteSpace($Toplevel)) {
        try { $Toplevel = Get-GitToplevel } catch {
            return New-Decision -Allowed $false -Code 'NoToplevel' `
                -Reason "cannot determine git toplevel: $($_.Exception.Message)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($GitDir) -or [string]::IsNullOrWhiteSpace($CommonDir)) {
        try {
            $pair = Get-GitDirPair
            if ([string]::IsNullOrWhiteSpace($GitDir)) { $GitDir = $pair.GitDir }
            if ([string]::IsNullOrWhiteSpace($CommonDir)) { $CommonDir = $pair.CommonDir }
        } catch {
            return New-Decision -Allowed $false -Code 'NoGitDir' `
                -Reason "cannot resolve git-dir/common-dir: $($_.Exception.Message)"
        }
    }

    $cmpBase = ConvertTo-ComparablePath -Path $Base
    $cmpTop = ConvertTo-ComparablePath -Path $Toplevel
    $cmpGit = ConvertTo-ComparablePath -Path $GitDir
    $cmpCommon = ConvertTo-ComparablePath -Path $CommonDir

    if (-not (Test-PathUnderBase -ComparableBase $cmpBase -ComparablePath $cmpTop)) {
        return New-Decision -Allowed $false -Code 'OutsideBase' `
            -Reason "toplevel '$Toplevel' is outside BRANCH_GUARD_BASE. Clones and worktrees must live under the configured base."
    }

    $segments = Get-RelativeSegments -ComparableBase $cmpBase -ComparablePath $cmpTop
    if ($null -eq $segments) {
        return New-Decision -Allowed $false -Code 'OutsideBase' `
            -Reason "toplevel '$Toplevel' is outside BRANCH_GUARD_BASE."
    }

    $segmentList = @($segments)
    # Expect exactly <repo>/<worktree>
    if ($segmentList.Count -ne 2) {
        $leaf = if ($segmentList.Count -ge 1) { $segmentList[-1] } else { '' }
        return New-Decision -Allowed $false -Code 'WrongDepth' -RepoLeaf $leaf `
            -Reason "toplevel must be BRANCH_GUARD_BASE/<repo>/<worktree> (exactly two levels under the base). Got $($segmentList.Count) level(s) under the base. Never commit from the repository folder itself or from nested paths."
    }

    $repoName = $segmentList[0]
    $leaf = $segmentList[1]
    $rootLc = $RootName.ToLowerInvariant()
    if ($leaf.ToLowerInvariant() -eq $rootLc) {
        return New-Decision -Allowed $false -Code 'RootLeaf' -RepoLeaf $leaf `
            -Reason "commits and pushes are not allowed from <repo>/$RootName. Create a linked worktree beside $RootName and work there."
    }

    # Primary checkout (not a linked worktree): git-dir resolves to the same place as common-dir.
    if ($cmpGit -eq $cmpCommon) {
        return New-Decision -Allowed $false -Code 'PrimaryCheckout' -RepoLeaf $leaf `
            -Reason "git-dir equals git-common-dir — this is the primary checkout, not a linked worktree. Work only in a linked worktree under BRANCH_GUARD_BASE/<repo>/<worktree>."
    }

    return New-Decision -Allowed $true -Code 'Allow' -RepoLeaf $leaf `
        -Reason "linked worktree '$leaf' under repo '$repoName'"
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
            return New-Decision -Allowed $false -Code 'NoBranch' -Mode 'no-branch' `
                -Reason "cannot determine current branch: $($_.Exception.Message)"
        }
    }
    if (-not $defaultProvided) {
        try { $DefaultBranch = Get-GitDefaultBranch } catch {
            return New-Decision -Allowed $false -Code 'NoBranch' -Mode 'no-branch' `
                -Reason "cannot determine default branch: $($_.Exception.Message)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($CurrentBranch)) {
        return New-Decision -Allowed $false -Code 'NoBranchDetached' -Mode 'no-branch' `
            -Reason 'no-branch mode refuses detached HEAD; check out the default branch'
    }
    if ($CurrentBranch -ne $DefaultBranch) {
        return New-Decision -Allowed $false -Code 'NoBranchWrongBranch' -Mode 'no-branch' `
            -RepoLeaf $CurrentBranch `
            -Reason "no-branch mode: current branch '$CurrentBranch' is not the default branch '$DefaultBranch'. Do not create or commit on other branches in this repository."
    }
    return New-Decision -Allowed $true -Code 'Allow' -Mode 'no-branch' -RepoLeaf $CurrentBranch `
        -Reason "on default branch '$DefaultBranch'"
}

function Invoke-BranchGuardDecision {
    # Compatibility wrapper used by hooks/tests: applies mode (enforce|log|no-branch).
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
        [string] $Base,
        [string] $GitDir,
        [string] $CommonDir,
        [string] $RootName
    )

    $resolvedMode = Get-BranchGuardMode -Mode $Mode

    if ($resolvedMode -eq 'no-branch') {
        $nbParams = @{ Mode = 'no-branch' }
        # Get-NoBranchDecision uses ContainsKey — splat carefully
        $nb = @{}
        if ($PSBoundParameters.ContainsKey('CurrentBranch')) { $nb.CurrentBranch = $CurrentBranch }
        if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $nb.DefaultBranch = $DefaultBranch }
        $result = Get-NoBranchDecision @nb
        $result.Mode = 'no-branch'
        return $result
    }

    $dParams = @{}
    if ($PSBoundParameters.ContainsKey('Toplevel') -and $Toplevel) { $dParams.Toplevel = $Toplevel }
    if ($PSBoundParameters.ContainsKey('Base')) { $dParams.Base = $Base }
    if ($PSBoundParameters.ContainsKey('GitDir') -and $GitDir) { $dParams.GitDir = $GitDir }
    if ($PSBoundParameters.ContainsKey('CommonDir') -and $CommonDir) { $dParams.CommonDir = $CommonDir }
    if ($PSBoundParameters.ContainsKey('RootName') -and $RootName) { $dParams.RootName = $RootName }

    $result = Get-Decision @dParams
    $result.Mode = $resolvedMode
    return $result
}

# Pester tests: original five Get-Decision cases (Guard.Tests.ps1) + approved extensions.
$ErrorActionPreference = 'Stop'

$helpers = Join-Path $PSScriptRoot '..' '.githooks' 'BranchLocationGuard.Helpers.ps1'
$helpers = (Resolve-Path -LiteralPath $helpers).Path
. $helpers

# Neutral owner folder (avoid proprietary path tokens in this kit repo).
$B = 'E:\dev\Owner'

Describe 'Get-Decision' {
    # Original five (Guard.Tests.ps1), positional contract.
    It 'allows linked worktree' {
        (Get-Decision "$B\repo\feat-x" "$B\repo\root\.git\worktrees\feat-x" "$B\repo\root\.git" $B 'root').Allowed | Should -Be $true
    }
    It 'refuses root' {
        (Get-Decision "$B\repo\root" "$B\repo\root\.git" "$B\repo\root\.git" $B 'root').Allowed | Should -Be $false
    }
    It 'refuses outside base' {
        (Get-Decision 'C:\tmp\repo\w' 'C:\a' 'C:\b' $B 'root').Allowed | Should -Be $false
    }
    It 'refuses wrong depth' {
        (Get-Decision "$B\repo\a\b" 'x' 'y' $B 'root').Allowed | Should -Be $false
    }
    It 'refuses non-linked' {
        (Get-Decision "$B\repo\w" "$B\repo\w\.git" "$B\repo\w\.git" $B 'root').Allowed | Should -Be $false
    }

    It 'uses original reason strings' {
        (Get-Decision 'C:\tmp\repo\w' 'C:\a' 'C:\b' $B 'root').Reason | Should -Be 'outside-base'
        (Get-Decision "$B\repo\a\b" 'x' 'y' $B 'root').Reason | Should -Be 'wrong-depth (expected <base>\<repo>\<worktree>)'
        (Get-Decision "$B\repo\root" "$B\repo\root\.git" "$B\repo\root\.git" $B 'root').Reason | Should -Be 'branching inside root\ is not allowed'
        (Get-Decision "$B\repo\w" "$B\repo\w\.git" "$B\repo\w\.git" $B 'root').Reason | Should -Be 'not a linked worktree (git-dir equals common-dir)'
        (Get-Decision "$B\repo\feat-x" "$B\repo\root\.git\worktrees\feat-x" "$B\repo\root\.git" $B 'root').Reason | Should -Be 'ok'
    }
}

Describe 'ConvertTo-WindowsPathStyle / WSL translation' {
    It 'translates /mnt/e/... to E:\...' {
        ConvertTo-WindowsPathStyle -Path '/mnt/e/dev/Owner' | Should -Be 'E:\dev\Owner'
    }

    It 'allows WSL-form toplevel when base is Windows-form' {
        $r = Get-Decision '/mnt/e/dev/Owner/repo/feat-x' `
            '/mnt/e/dev/Owner/repo/root/.git/worktrees/feat-x' `
            '/mnt/e/dev/Owner/repo/root/.git' $B 'root'
        $r.Allowed | Should -Be $true
    }
}

Describe 'BRANCH_GUARD_BASE required' {
    It 'refuses when BRANCH_GUARD_BASE is unset' {
        $prev = $env:BRANCH_GUARD_BASE
        try {
            Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue
            $r = Get-Decision -Top 'E:\x\y\z' -GitDir 'E:\x\y\z\.git' -CommonDir 'E:\x\y\z\.git' -Base '' -RootName 'root'
            $r.Allowed | Should -Be $false
            $r.Reason | Should -Match 'BRANCH_GUARD_BASE'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_BASE = $prev }
            else { Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue }
        }
    }
}

Describe 'BRANCH_GUARD_ROOT_NAME' {
    It 'refuses a custom root leaf name' {
        $r = Get-Decision "$B\repo\trunk" "$B\repo\root\.git\worktrees\x" "$B\repo\root\.git" $B 'trunk'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'trunk'
    }
}

Describe 'BRANCH_GUARD_MODE enforce|log' {
    It 'defaults to enforce' {
        $prev = $env:BRANCH_GUARD_MODE
        try {
            Remove-Item Env:BRANCH_GUARD_MODE -ErrorAction SilentlyContinue
            Get-BranchGuardMode | Should -Be 'enforce'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_MODE = $prev }
            else { Remove-Item Env:BRANCH_GUARD_MODE -ErrorAction SilentlyContinue }
        }
    }

    It 'honours log mode' {
        Get-BranchGuardMode -Mode log | Should -Be 'log'
    }
}

Describe 'BRANCH_GUARD_LOG (original shape)' {
    It 'writes timestamp + hook/repo/allowed/mode/reason without full paths' {
        $log = Join-Path ([System.IO.Path]::GetTempPath()) ("branch-guard-log-{0}.txt" -f [guid]::NewGuid())
        $prev = $env:BRANCH_GUARD_LOG
        try {
            $env:BRANCH_GUARD_LOG = $log
            Write-GuardLog ('{0} repo={1} allowed={2} mode={3} reason={4}' -f 'pre-commit', 'repo', $false, 'enforce', 'outside-base')
            $line = Get-Content -LiteralPath $log | Select-Object -First 1
            $line | Should -Match 'repo=repo'
            $line | Should -Match 'allowed=False'
            $line | Should -Match 'reason=outside-base'
            $line | Should -Not -Match '[A-Za-z]:\\'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_LOG = $prev }
            else { Remove-Item Env:BRANCH_GUARD_LOG -ErrorAction SilentlyContinue }
            Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
        }
    }
}

Describe 'No-branch mode' {
    It 'allows the default branch' {
        (Get-NoBranchDecision -CurrentBranch 'main' -DefaultBranch 'main').Allowed | Should -Be $true
    }

    It 'refuses a non-default branch' {
        $r = Get-NoBranchDecision -CurrentBranch 'feature' -DefaultBranch 'main'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'NoBranchWrongBranch'
    }

    It 'refuses detached HEAD (empty current branch)' {
        $r = Get-NoBranchDecision -CurrentBranch '' -DefaultBranch 'main'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'detached'
    }
}

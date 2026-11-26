# Pester tests for branch-location-guard.
# Compatible with Pester 4.x and 5.x assertion style used here (Should -Be).
$ErrorActionPreference = 'Stop'

$helpers = Join-Path $PSScriptRoot '..' '.githooks' 'BranchLocationGuard.Helpers.ps1'
$helpers = (Resolve-Path -LiteralPath $helpers).Path
. $helpers

Describe 'ConvertTo-WindowsPathStyle / WSL translation' {
    It 'translates /mnt/e/... to E:\...' {
        ConvertTo-WindowsPathStyle -Path '/mnt/e/Development/repositories/Owner' |
            Should -Be 'E:\Development\repositories\Owner'
    }

    It 'translates drive-root /mnt/e to E:\' {
        ConvertTo-WindowsPathStyle -Path '/mnt/e' | Should -Be 'E:\'
    }

    It 'normalises already-Windows paths to backslashes' {
        ConvertTo-WindowsPathStyle -Path 'E:/Development/repositories/Owner' |
            Should -Be 'E:\Development\repositories\Owner'
    }

    It 'comparable paths are case-insensitive and slash-normalised' {
        $a = ConvertTo-ComparablePath -Path '/mnt/e/Dev/Repo'
        $b = ConvertTo-ComparablePath -Path 'E:\dev\repo'
        $a | Should -Be $b
    }
}

Describe 'Location mode — BRANCH_GUARD_BASE required' {
    It 'refuses when BRANCH_GUARD_BASE is unset' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base '' `
            -Toplevel 'E:\Development\repositories\Owner\demo\feature'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'BRANCH_GUARD_BASE is not set'
    }

    It 'refuses when Base parameter is whitespace and env empty' {
        $prev = $env:BRANCH_GUARD_BASE
        try {
            Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue
            $r = Invoke-BranchGuardDecision -Mode Location -Toplevel 'E:\x\y\z'
            $r.Allowed | Should -Be $false
            $r.Reason | Should -Match 'BRANCH_GUARD_BASE is not set'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_BASE = $prev }
            else { Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue }
        }
    }
}

Describe 'Location mode — path policy' {
    $base = 'E:\Development\repositories\Owner'

    It 'allows a linked worktree under base' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\fix-thing'
        $r.Allowed | Should -Be $true
    }

    It 'allows WSL-form toplevel when base is Windows-form' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel '/mnt/e/Development/repositories/Owner/demo/fix-thing'
        $r.Allowed | Should -Be $true
    }

    It 'refuses <repo>/root' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\root'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'root'
    }

    It 'refuses paths outside the base' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel 'D:\elsewhere\demo\feature'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'outside'
    }

    It 'refuses the repo folder itself (one level under base)' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'exactly two levels'
    }

    It 'refuses nested deeper than repo/worktree' {
        $r = Invoke-BranchGuardDecision -Mode Location -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\feature\nested'
        $r.Allowed | Should -Be $false
    }
}

Describe 'No-branch mode' {
    It 'allows the default branch' {
        $r = Invoke-BranchGuardDecision -Mode NoBranch `
            -CurrentBranch 'main' -DefaultBranch 'main'
        $r.Allowed | Should -Be $true
    }

    It 'refuses a non-default branch' {
        $r = Invoke-BranchGuardDecision -Mode NoBranch `
            -CurrentBranch 'feature' -DefaultBranch 'main'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'no-branch'
    }

    It 'refuses detached HEAD (empty current branch)' {
        $r = Invoke-BranchGuardDecision -Mode NoBranch `
            -CurrentBranch '' -DefaultBranch 'main'
        $r.Allowed | Should -Be $false
        $r.Reason | Should -Match 'detached'
    }
}

Describe 'Get-BranchGuardMode' {
    It 'honours explicit -Mode' {
        Get-BranchGuardMode -Mode NoBranch | Should -Be 'NoBranch'
    }

    It 'reads BRANCH_GUARD_MODE=no-branch' {
        $prev = $env:BRANCH_GUARD_MODE
        try {
            $env:BRANCH_GUARD_MODE = 'no-branch'
            Get-BranchGuardMode | Should -Be 'NoBranch'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_MODE = $prev }
            else { Remove-Item Env:BRANCH_GUARD_MODE -ErrorAction SilentlyContinue }
        }
    }
}

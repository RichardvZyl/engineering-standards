# Pester tests for branch-location-guard.
# Includes the original five Get-Decision cases, plus approved extensions.
$ErrorActionPreference = 'Stop'

$helpers = Join-Path $PSScriptRoot '..' '.githooks' 'BranchLocationGuard.Helpers.ps1'
$helpers = (Resolve-Path -LiteralPath $helpers).Path
. $helpers

$base = 'E:\Development\repositories\Owner'

Describe 'Get-Decision (original five)' {
    It 'allows a linked worktree at base\repo\worktree' {
        $r = Get-Decision -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\fix-thing' `
            -GitDir 'E:\Development\repositories\Owner\demo\root\.git\worktrees\fix-thing' `
            -CommonDir 'E:\Development\repositories\Owner\demo\root\.git'
        $r.Allowed | Should -Be $true
        $r.Code | Should -Be 'Allow'
        $r.RepoLeaf | Should -Be 'fix-thing'
    }

    It 'refuses outside base' {
        $r = Get-Decision -Base $base `
            -Toplevel 'D:\elsewhere\demo\feature' `
            -GitDir 'D:\elsewhere\demo\feature\.git' `
            -CommonDir 'D:\elsewhere\demo\feature\.git'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'OutsideBase'
    }

    It 'refuses wrong depth (not exactly base\repo\worktree)' {
        $r = Get-Decision -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo' `
            -GitDir 'E:\Development\repositories\Owner\demo\.git\worktrees\x' `
            -CommonDir 'E:\Development\repositories\Owner\demo\.git'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'WrongDepth'
    }

    It 'refuses root leaf' {
        $r = Get-Decision -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\root' `
            -GitDir 'E:\Development\repositories\Owner\demo\root\.git\worktrees\x' `
            -CommonDir 'E:\Development\repositories\Owner\demo\root\.git'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'RootLeaf'
    }

    It 'refuses when git-dir equals common-dir (primary checkout)' {
        $r = Get-Decision -Base $base `
            -Toplevel 'E:\Development\repositories\Owner\demo\feature' `
            -GitDir 'E:\Development\repositories\Owner\demo\feature\.git' `
            -CommonDir 'E:\Development\repositories\Owner\demo\feature\.git'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'PrimaryCheckout'
    }
}

Describe 'ConvertTo-WindowsPathStyle / WSL translation' {
    It 'translates /mnt/e/... to E:\...' {
        ConvertTo-WindowsPathStyle -Path '/mnt/e/Development/repositories/Owner' |
            Should -Be 'E:\Development\repositories\Owner'
    }

    It 'allows WSL-form toplevel when base is Windows-form' {
        $r = Get-Decision -Base $base `
            -Toplevel '/mnt/e/Development/repositories/Owner/demo/fix-thing' `
            -GitDir '/mnt/e/Development/repositories/Owner/demo/root/.git/worktrees/fix-thing' `
            -CommonDir '/mnt/e/Development/repositories/Owner/demo/root/.git'
        $r.Allowed | Should -Be $true
    }
}

Describe 'BRANCH_GUARD_BASE required' {
    It 'refuses when BRANCH_GUARD_BASE is unset' {
        $prev = $env:BRANCH_GUARD_BASE
        try {
            Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue
            $r = Get-Decision -Base '' -Toplevel 'E:\x\y\z' -GitDir 'E:\x\y\z\.git' -CommonDir 'E:\x\y\z\.git'
            $r.Allowed | Should -Be $false
            $r.Code | Should -Be 'UnsetBase'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_BASE = $prev }
            else { Remove-Item Env:BRANCH_GUARD_BASE -ErrorAction SilentlyContinue }
        }
    }
}

Describe 'BRANCH_GUARD_ROOT_NAME' {
    It 'refuses a custom root leaf name' {
        $r = Get-Decision -Base $base -RootName 'trunk' `
            -Toplevel 'E:\Development\repositories\Owner\demo\trunk' `
            -GitDir 'E:\Development\repositories\Owner\demo\root\.git\worktrees\x' `
            -CommonDir 'E:\Development\repositories\Owner\demo\root\.git'
        $r.Allowed | Should -Be $false
        $r.Code | Should -Be 'RootLeaf'
    }
}

Describe 'BRANCH_GUARD_MODE enforce|log' {
    It 'Get-BranchGuardMode defaults to enforce' {
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

Describe 'BRANCH_GUARD_LOG (repo leaf + decision only)' {
    It 'writes leaf and decision, not a full path' {
        $log = Join-Path ([System.IO.Path]::GetTempPath()) ("branch-guard-log-{0}.txt" -f [guid]::NewGuid())
        $prev = $env:BRANCH_GUARD_LOG
        try {
            $env:BRANCH_GUARD_LOG = $log
            Write-BranchGuardLog -RepoLeaf 'fix-thing' -Decision 'Allow'
            Write-BranchGuardLog -RepoLeaf 'root' -Decision 'RootLeaf'
            $lines = Get-Content -LiteralPath $log
            $lines[0] | Should -Be 'fix-thing Allow'
            $lines[1] | Should -Be 'root RootLeaf'
            ($lines -join "`n") | Should -Not -Match '[A-Za-z]:\\'
        } finally {
            if ($null -ne $prev) { $env:BRANCH_GUARD_LOG = $prev }
            else { Remove-Item Env:BRANCH_GUARD_LOG -ErrorAction SilentlyContinue }
            Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
        }
    }
}

Describe 'No-branch mode' {
    It 'allows the default branch' {
        $r = Get-NoBranchDecision -CurrentBranch 'main' -DefaultBranch 'main'
        $r.Allowed | Should -Be $true
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

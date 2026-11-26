#Requires -Version 7.0
<#
.SYNOPSIS
  Run Pester tests for the branch-location guard; skip gracefully if Pester is missing.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$tests = Join-Path $PSScriptRoot 'tests' 'BranchLocationGuard.Tests.ps1'

if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host 'Pester is not installed. Skipping PowerShell tests.' -ForegroundColor Yellow
    Write-Host 'Install with: Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck' -ForegroundColor DarkGray
    exit 0
}

Import-Module Pester -ErrorAction Stop
Write-Host "Pester $((Get-Module Pester).Version) — running $tests"

# Pester 4 vs 5 invocation
$major = (Get-Module Pester).Version.Major
if ($major -ge 5) {
    $config = New-PesterConfiguration
    $config.Run.Path = $tests
    $config.Run.Exit = $true
    $config.Output.Verbosity = 'Detailed'
    Invoke-Pester -Configuration $config
} else {
    $result = Invoke-Pester -Script $tests -PassThru
    if ($result.FailedCount -gt 0) { exit 1 }
}

# Also run POSIX tests when sh is available
$shTest = Join-Path $PSScriptRoot 'tests' 'test-posix-path.sh'
if (Get-Command sh -ErrorAction SilentlyContinue) {
    Write-Host 'Running POSIX sh tests...'
    & sh $shTest
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host 'All available tests passed.' -ForegroundColor Green

#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Links each standards skill into a harness directory. Does not copy.

.DESCRIPTION
    standards/skills/ is the source. A copy would fork the rule, so this creates one
    directory link per skill and refuses to write file contents.

    The link target is resolved when the script runs. It is not written into a document.
    Re-run the script if the checkout moves.

    Windows uses a junction. Other platforms use a symbolic link.

.PARAMETER RepositoryRoot
    Repository root. Defaults to the parent of this script's directory.

.PARAMETER Destination
    Directory that will hold one link per skill. Defaults to .agents/skills under the
    repository root. Created if it is missing. Refuses a destination inside standards/.

.EXAMPLE
    pwsh ./scripts/Link-StandardsSkills.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param(
    [string] $RepositoryRoot,
    [string] $Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = if ($RepositoryRoot) { (Resolve-Path -LiteralPath $RepositoryRoot).Path } else { Split-Path -Parent $PSScriptRoot }
$skills = Join-Path $root 'standards/skills'
if (-not $Destination) { $Destination = Join-Path $root '.agents/skills' }

$normalisedRoot = [System.IO.Path]::GetFullPath($root).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$normalisedSkills = [System.IO.Path]::GetFullPath($skills)
$normalisedDest = [System.IO.Path]::GetFullPath($Destination)

if (-not $normalisedSkills.StartsWith(
        $normalisedRoot + [System.IO.Path]::DirectorySeparatorChar,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run: skills path is not inside the repository root."
}
if ($normalisedDest.StartsWith($normalisedSkills, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to link skills inside standards/skills/. That directory is the source."
}
if (-not (Test-Path -LiteralPath $skills)) {
    throw "No standards/skills directory at '$skills'."
}

if (-not (Test-Path -LiteralPath $normalisedDest)) {
    if ($PSCmdlet.ShouldProcess($normalisedDest, 'Create destination directory')) {
        New-Item -ItemType Directory -Path $normalisedDest | Out-Null
    }
}

$linked = 0
$skipped = 0
foreach ($skill in @(Get-ChildItem -LiteralPath $skills -Directory)) {
    $marker = Join-Path $skill.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $marker)) { continue }

    $linkPath = Join-Path $normalisedDest $skill.Name
    if (Test-Path -LiteralPath $linkPath) {
        $item = Get-Item -LiteralPath $linkPath -Force
        $existing = $null
        if ($item.Target) {
            $raw = @($item.Target)[0]
            if (-not [System.IO.Path]::IsPathRooted($raw)) {
                $raw = Join-Path $item.Directory.FullName $raw
            }
            $existing = [System.IO.Path]::GetFullPath($raw)
        }
        $wanted = [System.IO.Path]::GetFullPath($skill.FullName)
        $sep = [System.IO.Path]::DirectorySeparatorChar
        if ($existing -and ($existing.TrimEnd($sep) -eq $wanted.TrimEnd($sep))) {
            $skipped++
            continue
        }
        throw "Refusing to replace '$linkPath'. It exists and does not already point at the skill."
    }

    if ($PSCmdlet.ShouldProcess($linkPath, "Link to $($skill.FullName)")) {
        if ($IsWindows) {
            New-Item -ItemType Junction -Path $linkPath -Target $skill.FullName | Out-Null
        }
        else {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $skill.FullName | Out-Null
        }
        $linked++
    }
}

Write-Host "Linked $linked, already correct $skipped."

#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Structural checks on standards/, templates/ and any ADR index present.

.DESCRIPTION
    The leak guard (Test-NoProprietaryLeak.ps1) decides what must NOT be in the repository.
    This decides what MUST be true of what is:

      1. Vendoring header - every file under standards/ opens with the read-only header.
         A vendored file without it gets edited downstream by someone with no way of knowing
         better, and that edit is lost at the next sync.
      2. VERSION - present and valid semver. The sync PR title is built from it.
      3. Relative links - every relative markdown link resolves to a file that exists.
         templates/ is EXCLUDED: its links are written to resolve after seeding into a
         consuming repo, so they are correctly broken here.
      4. ADR index - if docs/adr/ exists, every record has a row in its README and every row
         points at a record that exists.

.PARAMETER Path
    Repository root. Defaults to the parent of this script's directory.

.EXAMPLE
    pwsh ./scripts/Test-StandardsIntegrity.ps1

.OUTPUTS
    Exit code 0 when every check passes, 1 otherwise.
#>

[CmdletBinding()]
param(
    [string] $Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = if ($Path) { (Resolve-Path -LiteralPath $Path).Path } else { Split-Path -Parent $PSScriptRoot }

$failures = [System.Collections.Generic.List[string]]::new()
$checked = [ordered]@{}

function Add-Failure {
    param([string] $Message)
    $failures.Add($Message)
}

# --- 1. Vendoring header ------------------------------------------------------

$headerMarker = 'VENDORED — READ-ONLY IN THIS REPOSITORY.'
$standardsPath = Join-Path $root 'standards'
$standardsFiles = @()

if (Test-Path -LiteralPath $standardsPath) {
    $standardsFiles = @(Get-ChildItem -LiteralPath $standardsPath -Recurse -File -Filter '*.md')

    foreach ($file in $standardsFiles) {
        $head = (Get-Content -LiteralPath $file.FullName -TotalCount 8) -join "`n"
        if ($head -notmatch [regex]::Escape($headerMarker)) {
            Add-Failure "Missing vendoring header: standards/$($file.Name)"
        }
    }
}
else {
    Add-Failure "No standards/ directory found at '$root'."
}

$checked['Standards files'] = $standardsFiles.Count

# --- 2. VERSION ---------------------------------------------------------------

$versionFile = Join-Path $standardsPath 'VERSION'
$version = $null

if (-not (Test-Path -LiteralPath $versionFile)) {
    Add-Failure "standards/VERSION is missing. The sync PR title is built from it."
}
else {
    $version = ([System.IO.File]::ReadAllText($versionFile)).Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') {
        Add-Failure "standards/VERSION is not valid semver: '$version'."
    }
}

$checked['VERSION'] = $version ?? '(missing)'

# --- 3. Relative links --------------------------------------------------------

# templates/ links resolve only after seeding downstream; excluded by design.
$linkFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' -Force |
        Where-Object {
            $relative = [System.IO.Path]::GetRelativePath($root, $_.FullName)
            $segments = $relative -split '[\\/]'
            ($segments -notcontains '.git') -and ($segments[0] -ne 'templates')
        }
)

$linkCount = 0
$linkPattern = '\[(?<text>[^\]]*)\]\((?<target>[^)\s]+)(?:\s+"[^"]*")?\)'

foreach ($file in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $fileDir = Split-Path -Parent $file.FullName

    # A link inside a code fence or a code span is illustrative - a format example, not a
    # reference. Strip both before matching, or every documented template trips the check.
    # \r? before $ is load-bearing: .gitattributes pins *.md to CRLF, and in multiline mode
    # $ matches before the \n with the \r still unconsumed, so without it the closing fence
    # never matches and this strip silently removes nothing.
    $content = [regex]::Replace($content, '(?ms)^[ \t]*(```|~~~).*?^[ \t]*\1[ \t]*\r?$', '')
    $content = [regex]::Replace($content, '`[^`\r\n]*`', '')

    foreach ($match in [regex]::Matches($content, $linkPattern)) {
        $target = $match.Groups['target'].Value

        if ($target -match '^(https?:|mailto:|#)') { continue }

        $linkCount++
        $targetPath = ($target -split '#')[0]
        if ([string]::IsNullOrWhiteSpace($targetPath)) { continue }

        $resolved = [System.IO.Path]::GetFullPath((Join-Path $fileDir $targetPath))
        if (-not (Test-Path -LiteralPath $resolved)) {
            $relative = [System.IO.Path]::GetRelativePath($root, $file.FullName)
            Add-Failure "Broken link in ${relative}: '$target'"
        }
    }
}

$checked['Relative links'] = $linkCount

# --- 4. ADR index -------------------------------------------------------------

$adrPath = Join-Path $root 'docs/adr'
$adrCount = 0

if (Test-Path -LiteralPath $adrPath) {
    $indexFile = Join-Path $adrPath 'README.md'

    if (-not (Test-Path -LiteralPath $indexFile)) {
        Add-Failure "docs/adr/ exists but has no README.md index."
    }
    else {
        $index = [System.IO.File]::ReadAllText($indexFile)
        $records = @(
            Get-ChildItem -LiteralPath $adrPath -File -Filter '*.md' |
                Where-Object { $_.Name -ne 'README.md' }
        )
        $adrCount = $records.Count

        foreach ($record in $records) {
            if ($index -notmatch [regex]::Escape($record.Name)) {
                Add-Failure "ADR not listed in docs/adr/README.md: $($record.Name)"
            }
        }

        foreach ($match in [regex]::Matches($index, '\((?<target>\./\d{4}-[^)]+\.md)\)')) {
            $target = $match.Groups['target'].Value
            if (-not (Test-Path -LiteralPath (Join-Path $adrPath $target))) {
                Add-Failure "docs/adr/README.md lists a record that does not exist: $target"
            }
        }
    }
}

$checked['ADR records'] = $adrCount

# --- Report -------------------------------------------------------------------

Write-Host "`nStandards integrity" -ForegroundColor Cyan
foreach ($key in $checked.Keys) {
    Write-Host ("  {0,-18} {1}" -f $key, $checked[$key])
}

if ($failures.Count -gt 0) {
    Write-Host "`nFAILED ($($failures.Count)):" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`nAll integrity checks passed." -ForegroundColor Green
exit 0
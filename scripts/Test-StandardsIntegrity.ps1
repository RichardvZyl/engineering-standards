#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Structural checks on standards/, templates/ and any ADR index present.

.DESCRIPTION
    The leak guard (Test-NoProprietaryLeak.ps1) decides what must NOT be in the repository.
    This decides what MUST be true of what is:

      1. Vendoring header - every file under standards/ carries the read-only header.
         A vendored file without it gets edited downstream by someone with no way of knowing
         better, and that edit is lost at the next sync. A SKILL.md opens with YAML frontmatter,
         which a harness requires at byte 0; the header follows it and must still be present.
      2. VERSION - present and valid semver. The sync PR title is built from it.
      3. Relative links - every relative markdown link resolves to a file that exists.
         templates/ is EXCLUDED (its links resolve after seeding into a consuming repo) and
         docs/dev-docs-import/ is EXCLUDED (imported reference and archival material whose
         links resolve only in their original home). Both are correctly broken in place.
      4. ADR index - if docs/adr/ exists, every record has a row in its README and every row
         points at a record that exists.
      5. Skill projection - standards/skills holds one SKILL.md per standards markdown file
         outside that directory, plus exactly one router. Each skill names its standard, links
         it, and is linked from standards/skills/README.md. Nothing else lives in that tree.

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
        $relative = ([System.IO.Path]::GetRelativePath($standardsPath, $file.FullName)) -replace '\\', '/'
        $isSkill = ($file.Name -eq 'SKILL.md') -and $relative.StartsWith('skills/')
        $take = if ($isSkill) { 40 } else { 8 }
        $headLines = @(Get-Content -LiteralPath $file.FullName -TotalCount $take)
        $head = $headLines -join "`n"
        if ($head -notmatch [regex]::Escape($headerMarker)) {
            Add-Failure "Missing vendoring header: standards/$relative"
        }
        if ($isSkill -and ($headLines.Count -eq 0 -or $headLines[0] -ne '---')) {
            Add-Failure "Skill must open with YAML frontmatter: standards/$relative"
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

# templates/ links resolve only after seeding downstream; docs/dev-docs-import/ is imported
# reference and archival material (pre-consolidation standards snapshots and worktree backups)
# whose links resolve only in their original home. Both are excluded from link checking.
$linkFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' -Force |
        Where-Object {
            $relative = [System.IO.Path]::GetRelativePath($root, $_.FullName)
            $segments = $relative -split '[\\/]'
            ($segments -notcontains '.git') -and ($segments[0] -ne 'templates') -and -not ($segments[0] -eq 'docs' -and $segments[1] -eq 'dev-docs-import')
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


# --- 5. Skill projection ------------------------------------------------------

$skillRoot = Join-Path $standardsPath 'skills'
$skillReadme = Join-Path $skillRoot 'README.md'
$skillCount = 0

if (-not (Test-Path -LiteralPath $skillRoot)) {
    Add-Failure 'standards/skills/ is missing. Each standard needs an agent skill.'
}
else {
    $expected = @{}
    foreach ($file in $standardsFiles) {
        $relative = ([System.IO.Path]::GetRelativePath($standardsPath, $file.FullName)) -replace '\\', '/'
        if ($relative.StartsWith('skills/')) { continue }
        $expected["standards/$relative"] = $false
    }

    $skillDocs = @(Get-ChildItem -LiteralPath $skillRoot -Recurse -File -Filter 'SKILL.md')
    $skillCount = $skillDocs.Count
    $routerCount = 0

    foreach ($skill in $skillDocs) {
        $dirName = $skill.Directory.Name
        $skillText = [System.IO.File]::ReadAllText($skill.FullName)
        if ($skillText -notmatch '(?s)\A---\r?\n(.*?)\r?\n---') {
            Add-Failure "Skill frontmatter missing or not at byte 0: standards/skills/$dirName/SKILL.md"
            continue
        }
        $front = $Matches[1]
        $nameOk = $front -match '(?m)^name:\s*(\S+)\s*$'
        if (-not $nameOk -or $Matches[1] -ne $dirName) {
            Add-Failure "Skill name does not match its directory: standards/skills/$dirName/SKILL.md"
        }
        if ($front -notmatch '(?m)^description:\s*\S') {
            Add-Failure "Skill description missing: standards/skills/$dirName/SKILL.md"
        }

        $isRouter = $front -match '(?m)^[ ]{2}role:\s*router\s*$'
        $standardMatch = [regex]::Match($front, '(?m)^[ ]{2}standard:\s*(\S+)\s*$')
        if ($isRouter) {
            $routerCount++
            if ($standardMatch.Success) {
                Add-Failure "Router skill must not name a standard: standards/skills/$dirName/SKILL.md"
            }
            continue
        }
        if (-not $standardMatch.Success) {
            Add-Failure "Skill does not name its standard: standards/skills/$dirName/SKILL.md"
            continue
        }
        $standardRel = $standardMatch.Groups[1].Value
        if (-not $expected.ContainsKey($standardRel)) {
            Add-Failure "Skill points at a file that is not a standard: $standardRel ($dirName)"
            continue
        }
        if ($expected[$standardRel]) {
            Add-Failure "More than one skill points at $standardRel"
        }
        $expected[$standardRel] = $true

        $tail = $standardRel.Substring('standards/'.Length)
        $needle = "](../../$tail)"
        if ($skillText.IndexOf($needle, [System.StringComparison]::Ordinal) -lt 0) {
            Add-Failure "Skill body does not link its standard: standards/skills/$dirName/SKILL.md"
        }
    }

    if ($routerCount -ne 1) {
        Add-Failure "Expected exactly one router skill (metadata.role: router). Found $routerCount."
    }

    foreach ($key in @($expected.Keys)) {
        if (-not $expected[$key]) {
            Add-Failure "No skill for $key"
        }
    }

    if (Test-Path -LiteralPath $skillReadme) {
        $readmeText = [System.IO.File]::ReadAllText($skillReadme)
        foreach ($skill in $skillDocs) {
            $token = "./$($skill.Directory.Name)/SKILL.md"
            if ($readmeText.IndexOf($token, [System.StringComparison]::Ordinal) -lt 0) {
                Add-Failure "standards/skills/README.md does not link $token"
            }
        }
    }
    else {
        Add-Failure 'standards/skills/README.md is missing.'
    }

    $stray = @(
        Get-ChildItem -LiteralPath $skillRoot -Recurse -File |
            Where-Object {
                $relative = ([System.IO.Path]::GetRelativePath($skillRoot, $_.FullName)) -replace '\\', '/'
                -not ($relative -eq 'README.md' -or $relative -match '^[^/]+/SKILL\.md$')
            }
    )
    foreach ($extra in $stray) {
        $relative = ([System.IO.Path]::GetRelativePath($root, $extra.FullName)) -replace '\\', '/'
        Add-Failure "Unexpected file in the skill projection: $relative"
    }
}

$checked['Skills'] = $skillCount

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
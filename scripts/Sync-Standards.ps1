#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Mirrors standards/ from the upstream engineering-standards repository into this one.

.DESCRIPTION
    Vendoring keeps a clone self-describing, but a vendored copy silently rots. This script is
    the other half: it makes drift visible as a diff, which the calling workflow turns into a
    pull request.

    GUARANTEES, in order of importance:

      1. It writes ONLY inside standards/. Nothing else in the repository is read for writing,
         and the target path is verified to be inside the repository root before any write.
      2. It NEVER commits, pushes, merges or opens anything. It changes files on disk and
         reports what changed. The workflow decides what to do with that.
      3. The mirror includes deletions - a standard removed upstream is removed locally, so the
         local set cannot accumulate files that upstream has retired.

    Run it locally any time to preview drift; -WhatIf shows the changes without making them.

.PARAMETER UpstreamRepo
    Upstream in owner/name form, or any URL git can clone.

.PARAMETER Ref
    Branch or tag to sync from.

.PARAMETER RepositoryRoot
    Root of the consuming repository. Defaults to the parent of this script's directory.

.PARAMETER GitHubOutput
    Emit key=value pairs for GitHub Actions. Defaults on when GITHUB_OUTPUT is set.

.EXAMPLE
    pwsh ./scripts/Sync-Standards.ps1 -WhatIf

.EXAMPLE
    pwsh ./scripts/Sync-Standards.ps1 -UpstreamRepo RichardvZyl/engineering-standards -Ref main

.OUTPUTS
    An object with FromVersion, ToVersion, Changed, Added, Removed and HasDrift.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string] $UpstreamRepo = 'RichardvZyl/engineering-standards',
    [string] $Ref = 'main',
    [string] $RepositoryRoot,
    [switch] $GitHubOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = if ($RepositoryRoot) { (Resolve-Path -LiteralPath $RepositoryRoot).Path } else { Split-Path -Parent $PSScriptRoot }
$localStandards = Join-Path $root 'standards'

# Guarantee 1, enforced rather than intended: refuse to write anywhere but <root>/standards.
$normalisedRoot = [System.IO.Path]::GetFullPath($root).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$normalisedTarget = [System.IO.Path]::GetFullPath($localStandards)
if (-not $normalisedTarget.StartsWith(
        $normalisedRoot + [System.IO.Path]::DirectorySeparatorChar,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run: resolved target '$normalisedTarget' is not inside repository root '$normalisedRoot'."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is not available on PATH."
}

$cloneUrl = if ($UpstreamRepo -match '^[\w.-]+/[\w.-]+$') { "https://github.com/$UpstreamRepo.git" } else { $UpstreamRepo }

function Get-VersionOrUnknown {
    param([string] $StandardsPath)

    $file = Join-Path $StandardsPath 'VERSION'
    if (Test-Path -LiteralPath $file) {
        return ([System.IO.File]::ReadAllText($file)).Trim()
    }
    return 'unknown'
}

function Get-FileMap {
    param([string] $StandardsPath)

    $map = @{}
    if (-not (Test-Path -LiteralPath $StandardsPath)) { return $map }

    foreach ($file in (Get-ChildItem -LiteralPath $StandardsPath -Recurse -File -Force)) {
        $relative = [System.IO.Path]::GetRelativePath($StandardsPath, $file.FullName)
        $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return $map
}

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("standards-sync-" + [System.Guid]::NewGuid().ToString('n'))

try {
    Write-Host "Fetching $cloneUrl at '$Ref'..." -ForegroundColor Cyan

    # A blobless partial clone: enough to read standards/, without the full history.
    & git clone --depth 1 --branch $Ref --filter=blob:none --quiet $cloneUrl $temp 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed for '$cloneUrl' at ref '$Ref' (exit $LASTEXITCODE)."
    }

    $upstreamStandards = Join-Path $temp 'standards'
    if (-not (Test-Path -LiteralPath $upstreamStandards)) {
        throw "Upstream has no standards/ directory at ref '$Ref'. Refusing to mirror an empty set."
    }

    $fromVersion = Get-VersionOrUnknown -StandardsPath $localStandards
    $toVersion = Get-VersionOrUnknown -StandardsPath $upstreamStandards

    $localMap = Get-FileMap -StandardsPath $localStandards
    $upstreamMap = Get-FileMap -StandardsPath $upstreamStandards

    $added = @($upstreamMap.Keys | Where-Object { -not $localMap.ContainsKey($_) } | Sort-Object)
    $removed = @($localMap.Keys | Where-Object { -not $upstreamMap.ContainsKey($_) } | Sort-Object)
    $changed = @(
        $upstreamMap.Keys |
            Where-Object { $localMap.ContainsKey($_) -and $localMap[$_] -ne $upstreamMap[$_] } |
            Sort-Object
    )

    $hasDrift = ($added.Count + $removed.Count + $changed.Count) -gt 0

    if (-not $hasDrift) {
        Write-Host "No drift. standards/ matches upstream at $toVersion." -ForegroundColor Green
    }
    else {
        Write-Host "`nDrift detected: $fromVersion -> $toVersion" -ForegroundColor Yellow
        foreach ($f in $added)   { Write-Host "  added    $f" -ForegroundColor Green }
        foreach ($f in $changed) { Write-Host "  changed  $f" -ForegroundColor Yellow }
        foreach ($f in $removed) { Write-Host "  removed  $f" -ForegroundColor Red }

        if ($PSCmdlet.ShouldProcess($localStandards, "Mirror standards/ from $UpstreamRepo@$Ref")) {

            if (-not (Test-Path -LiteralPath $localStandards)) {
                New-Item -ItemType Directory -Path $localStandards -Force | Out-Null
            }

            # Deletions first, so a rename does not briefly leave both names present.
            foreach ($relative in $removed) {
                $target = Join-Path $localStandards $relative
                Remove-Item -LiteralPath $target -Force
            }

            foreach ($relative in ($added + $changed)) {
                $source = Join-Path $upstreamStandards $relative
                $target = Join-Path $localStandards $relative
                $targetDir = Split-Path -Parent $target
                if (-not (Test-Path -LiteralPath $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $source -Destination $target -Force
            }

            # Prune directories the mirror emptied.
            Get-ChildItem -LiteralPath $localStandards -Recurse -Directory -Force |
                Sort-Object { $_.FullName.Length } -Descending |
                Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
                Remove-Item -Force

            Write-Host "`nMirrored. Nothing outside standards/ was touched." -ForegroundColor Green
        }
    }

    $result = [pscustomobject]@{
        FromVersion = $fromVersion
        ToVersion   = $toVersion
        Added       = $added
        Changed     = $changed
        Removed     = $removed
        HasDrift    = $hasDrift
    }

    if ($GitHubOutput -or $env:GITHUB_OUTPUT) {
        $summary = @(
            $(if ($added.Count)   { "Added: "   + ($added   -join ', ') })
            $(if ($changed.Count) { "Changed: " + ($changed -join ', ') })
            $(if ($removed.Count) { "Removed: " + ($removed -join ', ') })
        ) | Where-Object { $_ }

        @(
            "has_drift=$($hasDrift.ToString().ToLowerInvariant())"
            "from_version=$fromVersion"
            "to_version=$toVersion"
            "summary=$($summary -join ' | ')"
        ) | Add-Content -LiteralPath $env:GITHUB_OUTPUT
    }

    return $result
}
finally {
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
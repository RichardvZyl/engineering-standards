#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Fails if proprietary names, credentials, machine-local paths or private-context
    files have reached this repository.

.DESCRIPTION
    This repository is public and carries CONVENTIONS, never INSTANCES. A line that
    names a repo, org, client or product is project context and belongs in that
    project's own AGENTS.md.

    That boundary is easy to cross by accident, so it is enforced here rather than
    promised. Three independent checks run on every push:

      1. Deny tokens  - each file is lowercased and split on /[^a-z0-9]+/; every
                        token's SHA-256 is compared against scripts/deny-tokens.sha256.
                        Catches org, client and product names without naming them
                        in this repo. See that file for why it stores digests.
      2. Patterns     - generic, publishable regexes for credentials and for
                        machine-local absolute paths. An 'E:\...\Repos\...' path is
                        an instance leak as surely as a client name is.
      3. Private files - any *.private.md in the tree. The convention is that such
                        files are never committed; existence alone is the failure.

.PARAMETER Path
    Root to scan. Defaults to the repository root (parent of this script).

.PARAMETER AddToken
    Append the SHA-256 of this token to the deny list, then exit. Lowercases and
    strips non-alphanumerics first, so 'Acme.Widgets' is stored as two tokens.

.PARAMETER WarningsAsErrors
    Treat Warn-severity findings as failures. Off by default so a contact email
    does not break the build.

.EXAMPLE
    pwsh ./scripts/Test-NoProprietaryLeak.ps1

.EXAMPLE
    pwsh ./scripts/Test-NoProprietaryLeak.ps1 -AddToken 'AcmeCorp'

.OUTPUTS
    Exit code 0 when clean, 1 when any Fail-severity finding is present.
#>

[CmdletBinding(DefaultParameterSetName = 'Scan')]
param(
    [Parameter(ParameterSetName = 'Scan')]
    [string] $Path,

    # Valid in both parameter sets: -AddToken needs to know where to append.
    [string] $DenyTokenPath,

    [Parameter(ParameterSetName = 'Scan')]
    [switch] $WarningsAsErrors,

    [Parameter(ParameterSetName = 'AddToken', Mandatory)]
    [string] $AddToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = if ($Path) { (Resolve-Path -LiteralPath $Path).Path } else { Split-Path -Parent $PSScriptRoot }
$denyPath = if ($DenyTokenPath) { $DenyTokenPath } else { Join-Path $PSScriptRoot 'deny-tokens.sha256' }

function Get-TokenDigest {
    param([Parameter(Mandatory)][string] $Token)

    $normalised = ($Token -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($normalised)) {
        throw "Token '$Token' normalises to nothing."
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalised)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [System.Convert]::ToHexString($hash).ToLowerInvariant()
}

# --- -AddToken: extend the deny list, then stop ------------------------------

if ($PSCmdlet.ParameterSetName -eq 'AddToken') {
    $digest = Get-TokenDigest -Token $AddToken

    $raw = if (Test-Path -LiteralPath $denyPath) {
        [System.IO.File]::ReadAllText($denyPath)
    } else { '' }

    $existing = @(
        $raw -split '\r?\n' |
            ForEach-Object { $_.Trim().ToLowerInvariant() } |
            Where-Object { $_ -and -not $_.StartsWith('#') }
    )

    if ($existing -contains $digest) {
        Write-Host "Already present. Deny list unchanged." -ForegroundColor Yellow
        exit 0
    }

    # This repo sets insert_final_newline = false, so the list normally ends mid-line.
    # Appending blind would concatenate onto the last digest and silently disable it.
    if ($raw.Length -gt 0 -and $raw -notmatch '\r?\n$') {
        [System.IO.File]::AppendAllText($denyPath, [System.Environment]::NewLine)
    }

    [System.IO.File]::AppendAllText($denyPath, $digest)

    Write-Host "Added digest for the supplied token to $denyPath" -ForegroundColor Green
    Write-Host "The token itself was not written anywhere." -ForegroundColor DarkGray
    exit 0
}

# --- Inputs ------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $denyPath)) {
    Write-Error "Deny-token list not found at '$denyPath'. The guard cannot run without it."
    exit 1
}

$denyDigests = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        Get-Content -LiteralPath $denyPath |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') } |
            ForEach-Object { $_.ToLowerInvariant() }
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

if ($denyDigests.Count -eq 0) {
    Write-Error "Deny-token list at '$denyPath' is empty. Refusing to pass vacuously."
    exit 1
}

# Generic and safe to publish: none of these name a client, org or product.
$patterns = @(
    @{ Name = 'Private key block'; Severity = 'Fail'; Regex = '-----BEGIN [A-Z ]*PRIVATE KEY-----' }
    @{ Name = 'Password assignment'; Severity = 'Fail'; Regex = '(?i)\b(password|pwd)\s*=\s*[^\s;"'']{3,}' }
    @{ Name = 'Connection string'; Severity = 'Fail'; Regex = '(?i)\b(Data Source|Initial Catalog|AccountKey|Server\s*=\s*tcp:)' }
    @{ Name = 'Bearer token'; Severity = 'Fail'; Regex = '(?i)Authorization:\s*Bearer\s+[A-Za-z0-9\-_\.]{20,}' }
    @{ Name = 'Windows user path'; Severity = 'Fail'; Regex = '(?i)[A-Z]:\\Users\\[A-Za-z0-9._-]+' }
    @{ Name = 'Local repo path'; Severity = 'Fail'; Regex = '(?i)[A-Z]:\\[^\r\n"'']*\\Repos\\' }
    @{ Name = 'UNC share path'; Severity = 'Warn'; Regex = '\\\\[A-Za-z0-9._-]+\\[A-Za-z0-9$._-]+' }
    @{ Name = 'Email address'; Severity = 'Warn'; Regex = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' }
)

# The guard and its list quote these patterns literally and would flag themselves.
$excludedFiles = @(
    $PSCommandPath
    $denyPath
) | ForEach-Object { (Resolve-Path -LiteralPath $_ -ErrorAction SilentlyContinue).Path } | Where-Object { $_ }

$excludedDirs = @('.git', 'node_modules', 'bin', 'obj', '.vs')

$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param($File, $Line, $Severity, $Rule, $Detail)

    $findings.Add([pscustomobject]@{
        File     = [System.IO.Path]::GetRelativePath($repoRoot, $File)
        Line     = $Line
        Severity = $Severity
        Rule     = $Rule
        Detail   = $Detail
    })
}

# --- Scan --------------------------------------------------------------------

$files = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Force |
    Where-Object {
        $relative = [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName)
        $segments = $relative -split '[\\/]'
        -not ($segments | Where-Object { $excludedDirs -contains $_ })
    }

foreach ($file in $files) {

    # Check 3: private-context files must never be committed.
    if ($file.Name -like '*.private.md') {
        Add-Finding -File $file.FullName -Line 0 -Severity 'Fail' -Rule 'Private file' `
            -Detail 'A *.private.md file is committed. These carry project context and are never public.'
        continue
    }

    if ($excludedFiles -contains $file.FullName) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -eq 0) { continue }

    # Skip binaries: a NUL byte in the first 8 KB is the usual tell.
    $probe = [Math]::Min($bytes.Length, 8192)
    if ([Array]::IndexOf($bytes, [byte]0, 0, $probe) -ge 0) { continue }

    $lines = [System.Text.Encoding]::UTF8.GetString($bytes) -split '\r?\n'

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $lineNumber = $i + 1

        # Check 1: deny tokens, compared as digests.
        foreach ($token in ($line.ToLowerInvariant() -split '[^a-z0-9]+')) {
            if ($token.Length -lt 3) { continue }
            $bytesToken = [System.Text.Encoding]::UTF8.GetBytes($token)
            $digest = [System.Convert]::ToHexString(
                [System.Security.Cryptography.SHA256]::HashData($bytesToken)).ToLowerInvariant()

            if ($denyDigests.Contains($digest)) {
                Add-Finding -File $file.FullName -Line $lineNumber -Severity 'Fail' -Rule 'Deny token' `
                    -Detail "A denied token appears here. It names an org, client or product; move it to that project's AGENTS.md."
                break
            }
        }

        # Check 2: credential and machine-local-path patterns.
        foreach ($pattern in $patterns) {
            if ($line -match $pattern.Regex) {
                Add-Finding -File $file.FullName -Line $lineNumber -Severity $pattern.Severity -Rule $pattern.Name `
                    -Detail $Matches[0]
            }
        }
    }
}

# --- Report ------------------------------------------------------------------

$failures = @($findings | Where-Object { $_.Severity -eq 'Fail' })
$warnings = @($findings | Where-Object { $_.Severity -eq 'Warn' })

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | Format-Table File, Line, Rule, Detail -AutoSize -Wrap | Out-String -Width 200 | Write-Host
}

if ($failures.Count -gt 0) {
    Write-Host "`nProprietary-leak guard FAILED ($($failures.Count)):" -ForegroundColor Red
    $failures | Format-Table File, Line, Rule, Detail -AutoSize -Wrap | Out-String -Width 200 | Write-Host
    Write-Host "The template carries the convention, never the instance." -ForegroundColor Red
    exit 1
}

if ($WarningsAsErrors -and $warnings.Count -gt 0) {
    Write-Host "Failing on warnings by request (-WarningsAsErrors)." -ForegroundColor Red
    exit 1
}

Write-Host "Proprietary-leak guard passed. $($files.Count) files scanned." -ForegroundColor Green
exit 0
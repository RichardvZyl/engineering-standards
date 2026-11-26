#Requires -Version 7.0
<#
.SYNOPSIS
  Read-only audit: does a GitHub repository's rules/rulesets block creating non-default branches?

.DESCRIPTION
  Reports classic branch protection and repository rulesets that affect refs/heads/*.
  Does not change anything. Requires `gh` authenticated with read access to the repo.

.PARAMETER Repo
  owner/name (e.g. RichardvZyl/grok-bot-workspace)

.EXAMPLE
  pwsh ./Test-GitHubBranchCreationPolicy.ps1 -Repo RichardvZyl/grok-bot-workspace
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[^/]+/[^/]+$')]
    [string] $Repo
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'gh CLI is required for this audit.'
}

$owner, $name = $Repo.Split('/')

Write-Host "=== Branch-creation policy audit: $Repo ==="

# Default branch
$repoJson = gh api "repos/$Repo" --jq '{default_branch: .default_branch, private: .private}' | ConvertFrom-Json
$default = $repoJson.default_branch
Write-Host "Default branch: $default"
Write-Host "Private:        $($repoJson.private)"

# Classic branch protection on default (does not by itself block creating OTHER branches)
Write-Host ''
Write-Host '-- Classic branch protection (default branch) --'
try {
    $prot = gh api "repos/$Repo/branches/$default/protection" 2>$null | ConvertFrom-Json
    Write-Host "Protection present on '$default': yes"
    Write-Host "  allow_force_pushes: $($prot.allow_force_pushes.enabled)"
    Write-Host "  allow_deletions:    $($prot.allow_deletions.enabled)"
    Write-Host '  Note: classic protection on the default branch does NOT stop creating other branches.'
} catch {
    Write-Host "Protection present on '$default': no (or inaccessible)"
}

# Rulesets
Write-Host ''
Write-Host '-- Repository rulesets --'
$rulesetsRaw = gh api "repos/$Repo/rulesets" 2>$null
if (-not $rulesetsRaw) {
    Write-Host 'No rulesets returned (none, or token lacks administration:read / contents).'
    Write-Host 'VERDICT: undecidable — could not list rulesets.'
    exit 2
}

$rulesets = $rulesetsRaw | ConvertFrom-Json
if (-not $rulesets -or @($rulesets).Count -eq 0) {
    Write-Host 'Rulesets: none'
    Write-Host 'VERDICT: does NOT appear to block creating non-default branches via rulesets.'
    Write-Host 'Local no-branch hooks remain the enforcement for clones that install them.'
    exit 0
}

$blocksCreation = $false
foreach ($rs in @($rulesets)) {
    Write-Host "Ruleset: $($rs.name) (id=$($rs.id), enforcement=$($rs.enforcement), target=$($rs.target))"
    try {
        $detail = gh api "repos/$Repo/rulesets/$($rs.id)" | ConvertFrom-Json
    } catch {
        Write-Host '  (detail inaccessible)'
        continue
    }
    $include = @($detail.conditions.ref_name.include)
    $exclude = @($detail.conditions.ref_name.exclude)
    Write-Host "  ref include: $($include -join ', ')"
    Write-Host "  ref exclude: $($exclude -join ', ')"
    $rules = @($detail.rules)
    foreach ($rule in $rules) {
        Write-Host "  rule: $($rule.type)"
        # creation rule on refs/heads/* (not only default) can block new branches
        if ($rule.type -eq 'creation' -and $detail.enforcement -eq 'active') {
            $coversAllHeads = $include | Where-Object { $_ -eq 'refs/heads/*' -or $_ -eq '~ALL' -or $_ -eq '~DEFAULT_BRANCH' }
            # If include is only ~DEFAULT_BRANCH, creation restriction applies to default, not others.
            $onlyDefault = ($include.Count -gt 0) -and ($include | ForEach-Object { $_ -eq '~DEFAULT_BRANCH' } | Where-Object { $_ } | Measure-Object).Count -eq $include.Count
            if (-not $onlyDefault) {
                $blocksCreation = $true
                Write-Host '  -> creation rule may block creating matching branches'
            }
        }
    }
}

Write-Host ''
if ($blocksCreation) {
    Write-Host 'VERDICT: rulesets appear to restrict branch creation on some/all heads. Confirm in GitHub Settings > Rules.'
    exit 0
}

Write-Host 'VERDICT: no active creation rule found that clearly blocks non-default branches.'
Write-Host 'Local no-branch hooks remain necessary for clone-side enforcement.'
exit 0

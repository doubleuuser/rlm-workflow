[CmdletBinding()]
param(
  [string]$RepoRoot = (Get-Location).Path,
  [switch]$SkipPlansUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
  )

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Ensure-Directory {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Write-Output "[OK] Created directory: $Path"
  } else {
    Write-Output "[OK] Directory exists: $Path"
  }
}

function Ensure-File {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    $parent = Split-Path -Path $Path -Parent
    if ($parent) {
      Ensure-Directory -Path $parent
    }
    Write-Utf8NoBom -Path $Path -Content $Content
    Write-Output "[OK] Created file: $Path"
  } else {
    Write-Output "[OK] File exists: $Path"
  }
}

function Upsert-MarkedBlock {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$StartMarker,
    [Parameter(Mandatory = $true)][string]$EndMarker,
    [Parameter(Mandatory = $true)][string]$BlockBody
  )

  $existing = ""
  if (Test-Path -LiteralPath $FilePath) {
    $existing = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
  }

  $block = "$StartMarker`r`n$BlockBody`r`n$EndMarker"
  $pattern = "(?s)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))"

  if ([regex]::IsMatch($existing, $pattern)) {
    $updated = [regex]::Replace(
      $existing,
      $pattern,
      [System.Text.RegularExpressions.MatchEvaluator] { param($m) $block }
    )
  } else {
    if ([string]::IsNullOrWhiteSpace($existing)) {
      $updated = "$block`r`n"
    } else {
      $trimmed = $existing.TrimEnd("`r", "`n")
      $updated = "$trimmed`r`n`r`n$block`r`n"
    }
  }

  if ($updated -ne $existing) {
    Write-Utf8NoBom -Path $FilePath -Content $updated
    Write-Output "[OK] Updated file: $FilePath"
  } else {
    Write-Output "[OK] File already up to date: $FilePath"
  }
}

$resolvedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
Write-Output "[INFO] Repo root: $resolvedRepoRoot"

$codexDir = Join-Path $resolvedRepoRoot ".codex"
$agentDir = Join-Path $resolvedRepoRoot ".agent"
$rlmDir = Join-Path $codexDir "rlm"
$skillRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$canonicalPlansPath = Join-Path $skillRoot "references\plans-canonical.md"
$agentsPath = Join-Path $codexDir "AGENTS.md"
$decisionsPath = Join-Path $codexDir "DECISIONS.md"
$statePath = Join-Path $codexDir "STATE.md"
$plansPath = Join-Path $agentDir "PLANS.md"

Ensure-Directory -Path $codexDir
Ensure-Directory -Path $agentDir
Ensure-Directory -Path $rlmDir

Ensure-File -Path (Join-Path $rlmDir ".gitkeep") -Content ""
Ensure-File -Path $decisionsPath -Content @"
# DECISIONS.md

## RLM Run Index

- No runs recorded yet.
"@
Ensure-File -Path $statePath -Content @"
# STATE.md

## Current State

- Initial state not documented yet.
"@
Ensure-File -Path $agentsPath -Content @"
# AGENTS.md
"@
if (Test-Path -LiteralPath $canonicalPlansPath) {
  $seedPlans = Get-Content -LiteralPath $canonicalPlansPath -Raw -Encoding UTF8
  if (-not [string]::IsNullOrWhiteSpace($seedPlans)) {
    Ensure-File -Path $plansPath -Content ($seedPlans.TrimEnd("`r", "`n") + "`r`n")
  } else {
    Ensure-File -Path $plansPath -Content "## Canonical location`r`n"
  }
} else {
  Ensure-File -Path $plansPath -Content "## Canonical location`r`n"
}

$agentsBlock = @(
  '## RLM Workflow Skill',
  '',
  'This repository uses the `rlm-workflow` skill to execute the repo-document RLM workflow.',
  'Canonical workflow rules are defined in `/.agent/PLANS.md`.',
  "Triggers on RLM requests like Implement requirement 'run-id' and phase-specific commands.",
  '',
  'Primary run artifacts live in:',
  '- `/.codex/rlm/<run-id>/00-requirements.md`',
  '- `/.codex/rlm/<run-id>/01-as-is.md`',
  '- `/.codex/rlm/<run-id>/02-to-be-plan.md`',
  '- `/.codex/rlm/<run-id>/03-implementation-summary.md`',
  '- `/.codex/rlm/<run-id>/04-test-summary.md`',
  '- `/.codex/rlm/<run-id>/05-manual-qa.md`',
  '- `/.codex/rlm/<run-id>/addenda/`'
) -join "`r`n"

Upsert-MarkedBlock `
  -FilePath $agentsPath `
  -StartMarker "<!-- RLM-WORKFLOW-SKILL:START -->" `
  -EndMarker "<!-- RLM-WORKFLOW-SKILL:END -->" `
  -BlockBody $agentsBlock

if (-not $SkipPlansUpdate) {
  if (Test-Path -LiteralPath $canonicalPlansPath) {
    $plansBlock = Get-Content -LiteralPath $canonicalPlansPath -Raw -Encoding UTF8
    if (-not [string]::IsNullOrWhiteSpace($plansBlock)) {
      $normalizedCanonical = $plansBlock.TrimEnd("`r", "`n") + "`r`n"
      $existingPlans = Get-Content -LiteralPath $plansPath -Raw -Encoding UTF8
      if ($existingPlans -ne $normalizedCanonical) {
        Write-Utf8NoBom -Path $plansPath -Content $normalizedCanonical
        Write-Output "[OK] Synced .agent/PLANS.md from canonical template: $canonicalPlansPath"
      } else {
        Write-Output "[OK] File already up to date: $plansPath"
      }
    } else {
      Write-Output "[INFO] Skipped PLANS update: canonical plans file is empty at $canonicalPlansPath"
    }
  } else {
    Write-Output "[INFO] Skipped PLANS update: canonical plans file not found at $canonicalPlansPath"
  }
} else {
  Write-Output "[INFO] Skipped PLANS update by configuration."
}

$updateSkillsScript = Join-Path $codexDir "scripts/update-agents-skills.ps1"
if (Test-Path -LiteralPath $updateSkillsScript) {
  Write-Output "[INFO] Refreshing installed skills section in .codex/AGENTS.md"
  & powershell -ExecutionPolicy Bypass -File $updateSkillsScript | ForEach-Object { Write-Output $_ }
} else {
  Write-Output "[INFO] Skill index refresh script not found at $updateSkillsScript"
}

Write-Output "[OK] RLM workflow installation bootstrap complete."

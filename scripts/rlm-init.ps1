[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [string]$RepoRoot = (Get-Location).Path,
    [ValidateSet("feature", "bugfix", "refactor")][string]$Template = "feature",
    [string]$FromIssue = "",
    [switch]$Force
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
        Write-Host ("[OK] Created directory: {0}" -f $Path)
    } else {
        Write-Host ("[OK] Directory exists: {0}" -f $Path)
    }
}

function New-RequirementsContent {
    param(
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$Template,
        [string]$FromIssue
    )

    $inputs = @("- [chat summary or source notes if captured in repo]")
    if (-not [string]::IsNullOrWhiteSpace($FromIssue)) {
        $inputs += "- Source: $FromIssue"
    }
    $inputsBlock = ($inputs -join "`r`n")

    return @"
Run: `/.codex/rlm/$RunId/`
Phase: `00 Requirements`
Status: `DRAFT`
Inputs:
$inputsBlock
Outputs:
- `/.codex/rlm/$RunId/00-requirements.md`
Scope note: This document defines stable requirement identifiers and acceptance criteria. (Template: $Template)

## TODO

- [ ] Elicit requirements from user/context
- [ ] Define requirement identifiers (R1, R2, ...)
- [ ] Write acceptance criteria for each requirement
- [ ] Document out of scope items (OOS1, OOS2, ...)
- [ ] List constraints and assumptions
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Requirements

### `R1` <short title>

Description:
Acceptance criteria:
- [observable condition 1]
- [observable condition 2]

## Out of Scope

- `OOS1`: ...

## Constraints

- ...

## Assumptions

- ...

## Coverage Gate
...
Coverage: FAIL

## Approval Gate
...
Approval: FAIL
"@
}

$resolvedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
Write-Host ("[INFO] Repo root: {0}" -f $resolvedRepoRoot)

$rlmRoot = Join-Path $resolvedRepoRoot ".codex/rlm"
$runDir = Join-Path $rlmRoot $RunId

Ensure-Directory -Path $rlmRoot
Ensure-Directory -Path $runDir

# Run-local scaffolding
Ensure-Directory -Path (Join-Path $runDir "addenda")

$evidenceDir = Join-Path $runDir "evidence"
Ensure-Directory -Path $evidenceDir
Ensure-Directory -Path (Join-Path $evidenceDir "screenshots")
Ensure-Directory -Path (Join-Path $evidenceDir "logs")
Ensure-Directory -Path (Join-Path $evidenceDir "perf")
Ensure-Directory -Path (Join-Path $evidenceDir "traces")
Ensure-Directory -Path (Join-Path $evidenceDir "other")

$requirementsPath = Join-Path $runDir "00-requirements.md"
if ((Test-Path -LiteralPath $requirementsPath) -and (-not $Force)) {
    Write-Host ("[INFO] Requirements file exists, not overwriting: {0}" -f $requirementsPath)
} else {
    $content = New-RequirementsContent -RunId $RunId -Template $Template -FromIssue $FromIssue
    Write-Utf8NoBom -Path $requirementsPath -Content $content
    Write-Host ("[OK] Wrote requirements template: {0}" -f $requirementsPath)
}

Write-Host ""
Write-Host "Next steps:"
Write-Host ("1) Edit: .codex/rlm/{0}/00-requirements.md" -f $RunId)
Write-Host ("2) Run:  Implement requirement '{0}'" -f $RunId)


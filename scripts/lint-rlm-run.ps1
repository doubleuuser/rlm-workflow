[CmdletBinding()]
param(
    [string]$RunId = "",
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$AllRuns,
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Issue {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("FAIL", "WARN")][string]$Severity,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$Message,
        [string[]]$RemediationLines = @()
    )

    Write-Host ("[{0}] {1}: {2}" -f $Severity, $FilePath, $Message)
    if ($RemediationLines.Count -gt 0) {
        Write-Host "Remediation (copy/paste):"
        foreach ($line in $RemediationLines) {
            Write-Host ("  {0}" -f $line)
        }
    }
    Write-Host ""
}

function Get-MdFieldValue {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$FieldName
    )

    $pattern = "(?m)^[ \t]*$([regex]::Escape($FieldName)):\s*(?<value>.+?)\s*$"
    $m = [regex]::Match($Content, $pattern)
    if (-not $m.Success) { return $null }

    $value = $m.Groups["value"].Value.Trim()
    $trimChars = @([char]0x60, [char]0x22, [char]0x27) # ` " '
    return $value.Trim($trimChars)
}

function Test-HasHeaderField {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$FieldName
    )

    return ($Content -match ("(?m)^[ \t]*{0}:" -f [regex]::Escape($FieldName)))
}

function Test-HasHeading {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$HeadingText
    )

    $pattern = "(?m)^[ \t]*##\s+$([regex]::Escape($HeadingText))\s*$"
    return [regex]::IsMatch($Content, $pattern)
}

function Test-HasGateLine {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$GateName
    )

    $pattern = "(?m)^[ \t]*$([regex]::Escape($GateName)):\s*(PASS|FAIL)\s*$"
    return [regex]::IsMatch($Content, $pattern)
}

function Get-TodoStats {
    param([Parameter(Mandatory = $true)][string]$Content)

    $lines = $Content -split "`r?`n"
    $inTodo = $false
    $hasTodoHeader = $false
    $unchecked = 0
    $checked = 0
    $total = 0

    foreach ($line in $lines) {
        if (-not $inTodo) {
            if ($line -match '^\s*##\s+TODO\s*$') {
                $inTodo = $true
                $hasTodoHeader = $true
            }
            continue
        }

        if ($line -match '^\s*##\s+' -or $line -match '^\s*#\s+') {
            break
        }

        if ($line -match '^\s*[-*]\s+\[(?<mark>[ xX])\]\s+') {
            $total++
            if ($Matches.mark -match '[xX]') { $checked++ } else { $unchecked++ }
        }
    }

    return [pscustomobject]@{
        HasTodo = $hasTodoHeader
        Total = $total
        Checked = $checked
        Unchecked = $unchecked
    }
}

function Get-LatestRunDirectory {
    param([Parameter(Mandatory = $true)][string]$RlmDir)

    $runs = Get-ChildItem -LiteralPath $RlmDir -Directory -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending

    if (-not $runs -or $runs.Count -eq 0) {
        return $null
    }

    return $runs[0].FullName
}

function Get-ArtifactRequiredSections {
    param([Parameter(Mandatory = $true)][string]$FileName)

    $map = @{
        "00-worktree.md" = @(
            "TODO",
            "Directory Selection",
            "Safety Verification",
            "Worktree Creation",
            "Main Branch Protection",
            "Project Setup",
            "Test Baseline Verification",
            "Worktree Context",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "00-requirements.md" = @(
            "TODO",
            "Requirements",
            "Out of Scope",
            "Constraints",
            "Assumptions",
            "Coverage Gate",
            "Approval Gate"
        )
        "01-as-is.md" = @(
            "TODO",
            "Reproduction Steps (Novice-Runnable)",
            "Current Behavior by Requirement",
            "Relevant Code Pointers",
            "Known Unknowns",
            "Evidence",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "01.5-root-cause.md" = @(
            "TODO",
            "Error Analysis",
            "Reproduction Verification",
            "Recent Changes Analysis",
            "Evidence Gathering (Multi-Layer if applicable)",
            "Data Flow Trace",
            "Pattern Analysis",
            "Hypothesis Testing",
            "Root Cause Summary",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "02-to-be-plan.md" = @(
            "TODO",
            "Planned Changes by File",
            "Implementation Steps",
            "Testing Strategy",
            "Playwright Plan (if applicable)",
            "Manual QA Scenarios",
            "Idempotence and Recovery",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "03-implementation-summary.md" = @(
            "TODO",
            "Changes Applied",
            "TDD Compliance Log",
            "Plan Deviations",
            "Implementation Evidence",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "03.5-code-review.md" = @(
            "TODO",
            "Review Scope",
            "Plan Alignment Assessment",
            "Code Quality Assessment",
            "Issues Found",
            "Verdict",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "04-test-summary.md" = @(
            "TODO",
            "Environment",
            "Execution Mode",
            "Commands Executed (Exact)",
            "Results Summary",
            "Evidence and Artifacts",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
        "05-manual-qa.md" = @(
            "TODO",
            "QA Scenarios and Results",
            "Evidence and Artifacts",
            "User Sign-Off",
            "Traceability",
            "Coverage Gate",
            "Approval Gate"
        )
    }

    if ($map.ContainsKey($FileName)) { return $map[$FileName] }
    return @("TODO", "Coverage Gate", "Approval Gate")
}

function Get-HeaderRemediationLines {
    param([string[]]$MissingFields)

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($field in $MissingFields) {
        switch ($field) {
            "Run" { $lines.Add('Run: `/.codex/rlm/<run-id>/`') }
            "Phase" { $lines.Add('Phase: `<phase name>`') }
            "Status" { $lines.Add('Status: `DRAFT`') }
            "Inputs" {
                $lines.Add("Inputs:")
                $lines.Add('- `<path>`')
            }
            "Outputs" {
                $lines.Add("Outputs:")
                $lines.Add('- `<path>`')
            }
            "Scope note" { $lines.Add("Scope note: <one sentence describing what this artifact decides/enables>.") }
            "LockedAt" { $lines.Add('LockedAt: `YYYY-MM-DDTHH:mm:ssZ`') }
            "LockHash" { $lines.Add('LockHash: `<sha256-hex>`') }
        }
    }
    return $lines.ToArray()
}

function Lint-ArtifactFile {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$RunDir
    )

    $fileName = Split-Path -Path $FilePath -Leaf
    $content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    $status = Get-MdFieldValue -Content $content -FieldName "Status"
    if ([string]::IsNullOrWhiteSpace($status)) { $status = "UNKNOWN" }

    $missingHeaderFields = New-Object System.Collections.Generic.List[string]
    foreach ($field in @("Run", "Phase", "Status", "Inputs", "Outputs", "Scope note")) {
        if (-not (Test-HasHeaderField -Content $content -FieldName $field)) {
            $missingHeaderFields.Add($field)
        }
    }

    if ($missingHeaderFields.Count -gt 0) {
        Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("Missing required header field(s): {0}" -f ($missingHeaderFields -join ", ")) -RemediationLines (Get-HeaderRemediationLines -MissingFields $missingHeaderFields.ToArray())
        return @{ Fail = 1; Warn = 0 }
    }

    $failCount = 0
    $warnCount = 0

    if ($status -ne "DRAFT" -and $status -ne "LOCKED") {
        $failCount++
        Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("Invalid Status value '{0}' (expected DRAFT or LOCKED)" -f $status) -RemediationLines @('Status: `DRAFT`')
    }

    if ($status -eq "LOCKED") {
        $lockMissing = New-Object System.Collections.Generic.List[string]
        foreach ($field in @("LockedAt", "LockHash")) {
            if (-not (Test-HasHeaderField -Content $content -FieldName $field)) {
                $lockMissing.Add($field)
            }
        }
        if ($lockMissing.Count -gt 0) {
            $failCount++
            Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("Status is LOCKED but missing: {0}" -f ($lockMissing -join ", ")) -RemediationLines (Get-HeaderRemediationLines -MissingFields $lockMissing.ToArray())
        }
    }

    $todo = Get-TodoStats -Content $content
    if (-not $todo.HasTodo) {
        $failCount++
        Write-Issue -Severity "FAIL" -FilePath $FilePath -Message "Missing required section: ## TODO" -RemediationLines @("## TODO", "", "- [ ] <task 1>", "- [ ] <task 2>")
    } elseif ($status -eq "LOCKED" -and $todo.Unchecked -gt 0) {
        $failCount++
        Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("LOCKED artifact has unchecked TODO items: {0}" -f $todo.Unchecked) -RemediationLines @(
            '# Option A: check all TODO boxes under ## TODO',
            '# Option B: set Status back to `DRAFT` until TODOs are complete'
        )
    }

    foreach ($heading in (Get-ArtifactRequiredSections -FileName $fileName)) {
        if (-not (Test-HasHeading -Content $content -HeadingText $heading)) {
            $failCount++
            Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("Missing required section heading: ## {0}" -f $heading) -RemediationLines @("## $heading", "", "<content>")
        }
    }

    foreach ($gate in @("Coverage", "Approval")) {
        if (-not (Test-HasGateLine -Content $content -GateName $gate)) {
            $failCount++
            Write-Issue -Severity "FAIL" -FilePath $FilePath -Message ("Missing required gate line: {0}: PASS|FAIL" -f $gate) -RemediationLines @("$($gate): FAIL")
        }
    }

    # Evidence directory convention checks (Phase 4/5).
    if ($fileName -in @("04-test-summary.md", "05-manual-qa.md")) {
        $evidenceDir = Join-Path $RunDir "evidence"
        if (-not (Test-Path -LiteralPath $evidenceDir)) {
            $warnCount++
            Write-Issue -Severity "WARN" -FilePath $FilePath -Message ("Evidence directory missing at {0}" -f $evidenceDir) -RemediationLines @(
                ('New-Item -ItemType Directory -Force -Path "{0}"' -f (Join-Path $evidenceDir "screenshots")),
                ('New-Item -ItemType Directory -Force -Path "{0}"' -f (Join-Path $evidenceDir "logs")),
                ('New-Item -ItemType Directory -Force -Path "{0}"' -f (Join-Path $evidenceDir "perf"))
            )
        }
    }

    return @{ Fail = $failCount; Warn = $warnCount }
}

$resolvedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$rlmRoot = Join-Path $resolvedRepoRoot ".codex/rlm"

if (-not (Test-Path -LiteralPath $rlmRoot)) {
    Write-Host "[FAIL] RLM directory not found at: $rlmRoot"
    Write-Host "       Is this the project repo root? (Expected .codex/rlm/)"
    exit 1
}

$runDirs = @()

if ($AllRuns) {
    $runDirs = Get-ChildItem -LiteralPath $rlmRoot -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    if (-not $runDirs -or $runDirs.Count -eq 0) {
        Write-Host "[FAIL] No runs found under: $rlmRoot"
        exit 1
    }
} elseif (-not [string]::IsNullOrWhiteSpace($RunId)) {
    $runDir = Join-Path $rlmRoot $RunId
    if (-not (Test-Path -LiteralPath $runDir)) {
        Write-Host "[FAIL] Run directory not found: $runDir"
        exit 1
    }
    $runDirs = @($runDir)
} else {
    $runDir = Get-LatestRunDirectory -RlmDir $rlmRoot
    if ($null -eq $runDir) {
        Write-Host "[FAIL] No runs found under: $rlmRoot"
        exit 1
    }
    $runDirs = @($runDir)
}

$totalFail = 0
$totalWarn = 0

foreach ($runDir in $runDirs) {
    $runIdLocal = Split-Path -Path $runDir -Leaf
    Write-Host ("Linting run: {0}" -f $runIdLocal)
    Write-Host ("Path: {0}" -f $runDir)
    Write-Host ""

    $artifactFiles = @(
        "00-requirements.md",
        "00-worktree.md",
        "01-as-is.md",
        "01.5-root-cause.md",
        "02-to-be-plan.md",
        "03-implementation-summary.md",
        "03.5-code-review.md",
        "04-test-summary.md",
        "05-manual-qa.md"
    )

    foreach ($artifact in $artifactFiles) {
        $artifactPath = Join-Path $runDir $artifact
        if (-not (Test-Path -LiteralPath $artifactPath)) {
            Write-Host ("[WARN] Missing artifact (ok if not reached yet): {0}" -f $artifactPath)
            $totalWarn++
            continue
        }

        $result = Lint-ArtifactFile -FilePath $artifactPath -RunDir $runDir
        $totalFail += $result.Fail
        $totalWarn += $result.Warn
    }

    $addendaDir = Join-Path $runDir "addenda"
    if (Test-Path -LiteralPath $addendaDir) {
        $addendaFiles = Get-ChildItem -LiteralPath $addendaDir -File -Filter "*.md" -ErrorAction SilentlyContinue
        foreach ($addendum in $addendaFiles) {
            $result = Lint-ArtifactFile -FilePath $addendum.FullName -RunDir $runDir
            $totalFail += $result.Fail
            $totalWarn += $result.Warn
        }
    }

    Write-Host "----"
    Write-Host ""
}

Write-Host "Summary"
Write-Host ("- FAIL: {0}" -f $totalFail)
Write-Host ("- WARN: {0}" -f $totalWarn)
Write-Host ""

$effectiveFail = $totalFail + ($(if ($Strict) { $totalWarn } else { 0 }))
if ($effectiveFail -gt 0) {
    Write-Host "[FAIL] Lint failed"
    exit 1
}

Write-Host "[OK] Lint passed"
exit 0

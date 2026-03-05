[CmdletBinding()]
param(
    [string]$RunId = "",
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$ShowHashes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-NormalizedArtifactTextForLockHash {
    param([Parameter(Mandatory = $true)][string]$Content)

    # Canonical LockHash input:
    # - normalize newlines to LF
    # - remove the LockHash line entirely (including its trailing newline, if present)
    $normalized = $Content -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"
    $normalized = $normalized -replace "(?m)^[ \t]*LockHash:.*(?:`n|$)", ""

    return $normalized
}

function Get-LockHash256FromContent {
    param([Parameter(Mandatory = $true)][string]$Content)

    $normalized = Get-NormalizedArtifactTextForLockHash -Content $Content
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
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

function Get-GateStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$GateName
    )

    $pattern = "(?m)^[ \t]*$([regex]::Escape($GateName)):\s*(?<value>PASS|FAIL)\s*$"
    $m = [regex]::Match($Content, $pattern)
    if ($m.Success) {
        return $m.Groups["value"].Value.ToUpperInvariant()
    }
    return "MISSING"
}

function Get-ArtifactState {
    param(
        [Parameter(Mandatory = $true)][string]$ArtifactPath
    )

    if (-not (Test-Path -LiteralPath $ArtifactPath)) {
        return [pscustomobject]@{
            Exists = $false
            Status = "PENDING"
            LockValid = $false
            LockProblems = @("File missing")
            LockedAt = $null
            StoredHash = $null
            ActualHash = $null
            Coverage = $null
            Approval = $null
            Todo = [pscustomobject]@{ HasTodo = $false; Total = 0; Checked = 0; Unchecked = 0 }
        }
    }

    $content = Get-Content -LiteralPath $ArtifactPath -Raw -Encoding UTF8
    $status = Get-MdFieldValue -Content $content -FieldName "Status"
    if ([string]::IsNullOrWhiteSpace($status)) { $status = "UNKNOWN" }

    $todo = Get-TodoStats -Content $content
    $coverage = Get-GateStatus -Content $content -GateName "Coverage"
    $approval = Get-GateStatus -Content $content -GateName "Approval"

    $lockedAt = Get-MdFieldValue -Content $content -FieldName "LockedAt"
    $storedHash = Get-MdFieldValue -Content $content -FieldName "LockHash"
    $actualHash = $null

    $lockProblems = New-Object System.Collections.Generic.List[string]
    $lockValid = $false

    if ($status -ne "LOCKED") {
        $lockProblems.Add("Status is '$status' (expected LOCKED for lock-valid)")
    } else {
        if ([string]::IsNullOrWhiteSpace($lockedAt)) { $lockProblems.Add("Missing LockedAt") }
        if ([string]::IsNullOrWhiteSpace($storedHash)) { $lockProblems.Add("Missing LockHash") }

        if (-not [string]::IsNullOrWhiteSpace($storedHash)) {
            $actualHash = Get-LockHash256FromContent -Content $content
            if ($storedHash.Trim().ToLower() -ne $actualHash.ToLower()) {
                $lockProblems.Add("LockHash mismatch")
            }
        }

        if ($coverage -ne "PASS") { $lockProblems.Add("Coverage gate is $coverage") }
        if ($approval -ne "PASS") { $lockProblems.Add("Approval gate is $approval") }

        if (-not $todo.HasTodo) {
            $lockProblems.Add("Missing ## TODO section")
        } elseif ($todo.Unchecked -gt 0) {
            $lockProblems.Add("Unchecked TODO items: $($todo.Unchecked)")
        }

        if ($lockProblems.Count -eq 0) { $lockValid = $true }
    }

    return [pscustomobject]@{
        Exists = $true
        Status = $status
        LockValid = $lockValid
        LockProblems = $lockProblems.ToArray()
        LockedAt = $lockedAt
        StoredHash = $storedHash
        ActualHash = $actualHash
        Coverage = $coverage
        Approval = $approval
        Todo = $todo
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

$resolvedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$rlmRoot = Join-Path $resolvedRepoRoot ".codex/rlm"

if (-not (Test-Path -LiteralPath $rlmRoot)) {
    Write-Host "[FAIL] RLM directory not found at: $rlmRoot"
    Write-Host "       Is this the project repo root? (Expected .codex/rlm/)"
    exit 1
}

$runDir = $null
$effectiveRunId = $RunId

if (-not [string]::IsNullOrWhiteSpace($RunId)) {
    $runDir = Join-Path $rlmRoot $RunId
    if (-not (Test-Path -LiteralPath $runDir)) {
        Write-Host "[FAIL] Run directory not found: $runDir"
        exit 1
    }
} else {
    $runDir = Get-LatestRunDirectory -RlmDir $rlmRoot
    if ($null -eq $runDir) {
        Write-Host "[FAIL] No runs found under: $rlmRoot"
        exit 1
    }
    $effectiveRunId = Split-Path -Path $runDir -Leaf
}

$phases = @(
    [pscustomobject]@{ Key = "00R"; Label = "Phase 0 (Requirements)"; File = "00-requirements.md"; Optional = $false; PhaseName = "0 (Requirements)" }
    [pscustomobject]@{ Key = "00W"; Label = "Phase 0 (Worktree)"; File = "00-worktree.md"; Optional = $false; PhaseName = "0 (Worktree)" }
    [pscustomobject]@{ Key = "01"; Label = "Phase 1 (AS-IS)"; File = "01-as-is.md"; Optional = $false; PhaseName = "1 (AS-IS)" }
    [pscustomobject]@{ Key = "01.5"; Label = "Phase 1.5 (Root Cause)"; File = "01.5-root-cause.md"; Optional = $true; PhaseName = "1.5 (Root Cause)" }
    [pscustomobject]@{ Key = "02"; Label = "Phase 2 (TO-BE Plan)"; File = "02-to-be-plan.md"; Optional = $false; PhaseName = "2 (TO-BE Plan)" }
    [pscustomobject]@{ Key = "03"; Label = "Phase 3 (Implementation)"; File = "03-implementation-summary.md"; Optional = $false; PhaseName = "3 (Implementation)" }
    [pscustomobject]@{ Key = "03.5"; Label = "Phase 3.5 (Code Review)"; File = "03.5-code-review.md"; Optional = $true; PhaseName = "3.5 (Code Review)" }
    [pscustomobject]@{ Key = "04"; Label = "Phase 4 (Test Summary)"; File = "04-test-summary.md"; Optional = $false; PhaseName = "4 (Test Summary)" }
    [pscustomobject]@{ Key = "05"; Label = "Phase 5 (Manual QA)"; File = "05-manual-qa.md"; Optional = $false; PhaseName = "5 (Manual QA)" }
)

$statesByKey = @{}
foreach ($phase in $phases) {
    $artifactPath = Join-Path $runDir $phase.File
    $state = Get-ArtifactState -ArtifactPath $artifactPath
    if ($phase.Optional -and -not $state.Exists) {
        $state.Status = "SKIPPED"
    }
    $statesByKey[$phase.Key] = $state
}

# Determine current phase (first required/active phase that is not lock-valid).
$current = $null
foreach ($phase in $phases) {
    $state = $statesByKey[$phase.Key]
    if ($phase.Optional -and $state.Status -eq "SKIPPED") { continue }
    if (-not $state.Exists) {
        $current = [pscustomobject]@{ Phase = $phase; State = $state }
        break
    }
    if (-not $state.LockValid) {
        $current = [pscustomobject]@{ Phase = $phase; State = $state }
        break
    }
}

$runTitle = "RLM Run: $effectiveRunId"
Write-Host $runTitle
Write-Host ("=" * [Math]::Max(8, $runTitle.Length))
Write-Host ""

Write-Host "Phase Status:"
foreach ($phase in $phases) {
    $state = $statesByKey[$phase.Key]
    $display = $state.Status
    $suffix = ""
    if ($display -eq "SKIPPED") {
        $suffix = " (not needed)"
    } elseif ($display -eq "LOCKED" -and -not $state.LockValid) {
        $display = "LOCKED*"
        $suffix = " (invalid)"
    }

    $statusText = ("[{0}]{1}" -f $display, $suffix)
    Write-Host ("  {0,-26} {1}" -f $phase.Label, $statusText)
}

Write-Host ""

if ($null -eq $current) {
    Write-Host "Current Phase: COMPLETE"
    Write-Host "Status: LOCKED"
} else {
    Write-Host ("Current Phase: {0}" -f $current.Phase.PhaseName)
    Write-Host ("Status: {0}" -f $current.State.Status)
}

Write-Host ""
Write-Host "Lock Chain:"

$chainOkThrough = $null
foreach ($phase in $phases) {
    $state = $statesByKey[$phase.Key]
    if ($phase.Optional -and $state.Status -eq "SKIPPED") { continue }

    $artifactRel = ".codex/rlm/$effectiveRunId/$($phase.File)"
    if ($state.LockValid) {
        Write-Host ("  [OK]  {0}" -f $artifactRel)
        $chainOkThrough = $phase.Key
        if ($ShowHashes -and $state.Status -eq "LOCKED") {
            Write-Host ("        LockHash: {0}" -f $state.StoredHash)
        }
    } else {
        if (-not $state.Exists) {
            Write-Host ("  [PENDING] {0}" -f $artifactRel)
        } elseif ($state.Status -ne "LOCKED") {
            Write-Host ("  [DRAFT]   {0}" -f $artifactRel)
        } else {
            $reason = ($state.LockProblems | Select-Object -First 1)
            if ([string]::IsNullOrWhiteSpace($reason)) { $reason = "Not lock-valid" }
            Write-Host ("  [FAIL]    {0} - {1}" -f $artifactRel, $reason)
        }
        break
    }
}

$evidenceDir = Join-Path $runDir "evidence"
$evidenceRel = ".codex/rlm/$effectiveRunId/evidence/"
$evidenceExists = Test-Path -LiteralPath $evidenceDir
$evidenceFiles = 0
if ($evidenceExists) {
    $evidenceFiles = (Get-ChildItem -LiteralPath $evidenceDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
}

Write-Host ""
Write-Host "Evidence:"
Write-Host ("  Path:   {0}" -f $evidenceRel)
Write-Host ("  Exists: {0}" -f ($(if ($evidenceExists) { "Yes" } else { "No" })))
Write-Host ("  Files:  {0}" -f $evidenceFiles)

Write-Host ""
Write-Host "Next Steps:"

if ($null -eq $current) {
    Write-Host ("  1. Update /.codex/DECISIONS.md and /.codex/STATE.md (Phases 6/7).")
    Write-Host ("  2. Merge the worktree branch when ready.")
} else {
    $nextArtifact = ".codex/rlm/$effectiveRunId/$($current.Phase.File)"
    switch ($current.Phase.Key) {
        "00R" {
            Write-Host ("  1. Create/complete {0} (define R1.., fill TODO, Coverage, Approval)." -f $nextArtifact)
            Write-Host ("  2. Lock it (set Status: LOCKED, add LockedAt + LockHash).")
        }
        "00W" {
            Write-Host ("  1. Set up isolated worktree and baseline tests, then write evidence into {0}." -f $nextArtifact)
            Write-Host ("  2. Lock it, then proceed to 01-as-is.md.")
        }
        "01" {
            Write-Host ("  1. Write AS-IS analysis into {0} (repro steps, current behavior, code pointers, evidence)." -f $nextArtifact)
            Write-Host ("  2. Lock it, then proceed to planning (02-to-be-plan.md).")
        }
        "01.5" {
            Write-Host ("  1. Complete root-cause analysis in {0} (no fixes yet)." -f $nextArtifact)
            Write-Host ("  2. Lock it, then incorporate into Phase 2 plan.")
        }
        "02" {
            Write-Host ("  1. Complete the ExecPlan in {0} (files, steps, testing, QA, recovery)." -f $nextArtifact)
            Write-Host ("  2. Lock it, then start implementation (Phase 3) with TDD.")
        }
        "03" {
            Write-Host ("  1. Implement plan via TDD and document in {0} (TDD log + evidence refs)." -f $nextArtifact)
            Write-Host ("  2. Lock it, then run validation (Phase 4).")
        }
        "03.5" {
            Write-Host ("  1. Complete code review in {0} and resolve any issues." -f $nextArtifact)
            Write-Host ("  2. Lock it, then proceed to Phase 4.")
        }
        "04" {
            Write-Host ("  1. Run tests and record exact commands/results in {0}." -f $nextArtifact)
            Write-Host ("  2. Save artifacts under {0} and reference paths in the doc." -f $evidenceRel)
            Write-Host ("  3. Lock Phase 4, then proceed to Manual QA (Phase 5).")
        }
        "05" {
            Write-Host ("  1. Execute manual QA scenarios and record results in {0}." -f $nextArtifact)
            Write-Host ("  2. Save screenshots/logs under {0} and reference paths." -f $evidenceRel)
            Write-Host ("  3. Record explicit user sign-off, lock Phase 5, then update DECISIONS/STATE.")
        }
        default {
            Write-Host ("  1. Complete {0}, pass gates, and lock the artifact." -f $nextArtifact)
        }
    }
}

Write-Host ""
Write-Host "Quick Command:"
Write-Host ("  Implement requirement '{0}'" -f $effectiveRunId)

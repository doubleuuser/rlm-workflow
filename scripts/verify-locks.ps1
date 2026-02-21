[CmdletBinding()]
param(
    [string]$RunId = "",
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$Fix,
    [switch]$Verbose
)

<#
.SYNOPSIS
    Verify RLM artifact lock integrity

.DESCRIPTION
    Validates that all RLM artifacts in a run have correct SHA-256 lock hashes.
    Can optionally fix incorrect hashes (use with caution).

.EXAMPLE
    ./verify-locks.ps1 -RunId "2026-02-21-feature"

.EXAMPLE
    ./verify-locks.ps1 -RunId "2026-02-21-feature" -Fix
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$Status,
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "PASS" = "Green"
        "FAIL" = "Red"
        "WARN" = "Yellow"
        "INFO" = "Cyan"
    }
    
    if ($colorMap.ContainsKey($Status)) {
        $Color = $colorMap[$Status]
    }
    
    Write-Host "[$Status] " -ForegroundColor $Color -NoNewline
    Write-Host $Message
}

function Get-FileHash256 {
    param([string]$FilePath)
    
    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $null
    }
    
    $hash = Get-FileHash -Algorithm SHA256 -Path $FilePath
    return $hash.Hash.ToLower()
}

function Test-LockValid {
    param(
        [string]$ArtifactPath,
        [switch]$Fix
    )
    
    if (-not (Test-Path -LiteralPath $ArtifactPath)) {
        return @{ Valid = $false; Error = "File not found" }
    }
    
    $content = Get-Content -LiteralPath $ArtifactPath -Raw -Encoding UTF8
    
    # Extract Status
    $statusMatch = $content | Select-String -Pattern "Status:\s*`?(\w+)`?"
    if (-not $statusMatch) {
        return @{ Valid = $false; Error = "No Status field found" }
    }
    
    $status = $statusMatch.Matches[0].Groups[1].Value
    if ($status -ne "LOCKED") {
        return @{ Valid = $false; Error = "Status is '$status', expected 'LOCKED'" }
    }
    
    # Extract LockHash
    $hashMatch = $content | Select-String -Pattern "LockHash:\s*`?([a-f0-9]{64})`?"
    if (-not $hashMatch) {
        return @{ Valid = $false; Error = "No LockHash field found" }
    }
    
    $storedHash = $hashMatch.Matches[0].Groups[1].Value.ToLower()
    
    # Extract LockedAt
    $lockedAtMatch = $content | Select-String -Pattern "LockedAt:\s*`?([\d-T:Z]+)`?"
    if (-not $lockedAtMatch) {
        return @{ Valid = $false; Error = "No LockedAt field found" }
    }
    
    $lockedAt = $lockedAtMatch.Matches[0].Groups[1].Value
    
    # Compute actual hash
    $actualHash = Get-FileHash256 -FilePath $ArtifactPath
    
    # Compare hashes
    if ($storedHash -ne $actualHash) {
        $result = @{
            Valid = $false
            Error = "Hash mismatch"
            StoredHash = $storedHash
            ActualHash = $actualHash
            LockedAt = $lockedAt
        }
        
        if ($Fix) {
            # Replace old hash with new hash
            $newContent = $content -replace "LockHash:\s*`?[a-f0-9]{64}`?", "LockHash: `$actualHash`"
            
            # Update LockedAt
            $newLockedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            $newContent = $newContent -replace "LockedAt:\s*`?[\d-T:Z]+`?", "LockedAt: `$newLockedAt`"
            
            # Write back
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($ArtifactPath, $newContent, $utf8NoBom)
            
            $result.Fixed = $true
            $result.NewLockedAt = $newLockedAt
        }
        
        return $result
    }
    
    return @{
        Valid = $true
        LockedAt = $lockedAt
        Hash = $storedHash
    }
}

function Test-CoverageGate {
    param([string]$ArtifactPath)
    
    $content = Get-Content -LiteralPath $ArtifactPath -Raw -Encoding UTF8
    
    # Check for Coverage: PASS
    if ($content -match "Coverage:\s*PASS") {
        return @{ Pass = $true }
    }
    
    if ($content -match "Coverage:\s*FAIL") {
        $reason = "Coverage gate shows FAIL"
        return @{ Pass = $false; Reason = $reason }
    }
    
    return @{ Pass = $false; Reason = "No Coverage gate result found" }
}

function Test-ApprovalGate {
    param([string]$ArtifactPath)
    
    $content = Get-Content -LiteralPath $ArtifactPath -Raw -Encoding UTF8
    
    # Check for Approval: PASS
    if ($content -match "Approval:\s*PASS") {
        return @{ Pass = $true }
    }
    
    if ($content -match "Approval:\s*FAIL") {
        $reason = "Approval gate shows FAIL"
        return @{ Pass = $false; Reason = $reason }
    }
    
    return @{ Pass = $false; Reason = "No Approval gate result found" }
}

# Main execution
$resolvedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
Write-Host ""
Write-Host "RLM Lock Verification"
Write-Host "====================="
Write-Host ""
Write-Host "Repository: $resolvedRepoRoot"

if ($RunId) {
    Write-Host "Run ID: $RunId"
    $rlmDir = Join-Path $resolvedRepoRoot ".codex" "rlm" $RunId
} else {
    Write-Host "Run ID: (scanning all runs)"
    $rlmDir = Join-Path $resolvedRepoRoot ".codex" "rlm"
}

Write-Host ""

if (-not (Test-Path -LiteralPath $rlmDir)) {
    Write-Status -Status "FAIL" -Message "RLM directory not found: $rlmDir"
    exit 1
}

# Find runs to check
$runs = @()
if ($RunId) {
    $runs = @($RunId)
} else {
    $runs = Get-ChildItem -Path $rlmDir -Directory | Select-Object -ExpandProperty Name | Sort-Object
}

$totalRuns = 0
$validRuns = 0
$fixedRuns = 0
$failedRuns = 0

foreach ($run in $runs) {
    $totalRuns++
    $runDir = Join-Path $rlmDir $run
    
    Write-Host "Checking run: $run"
    Write-Host "-" * 50
    
    $artifacts = @(
        @{ File = "00-requirements.md"; Phase = "00"; Name = "Requirements"; Optional = $true }
        @{ File = "01-as-is.md"; Phase = "01"; Name = "AS-IS Analysis"; Optional = $true }
        @{ File = "01.5-root-cause.md"; Phase = "01.5"; Name = "Root Cause"; Optional = $true }
        @{ File = "02-to-be-plan.md"; Phase = "02"; Name = "TO-BE Plan"; Optional = $true }
        @{ File = "03-implementation-summary.md"; Phase = "03"; Name = "Implementation"; Optional = $true }
        @{ File = "04-test-summary.md"; Phase = "04"; Name = "Test Summary"; Optional = $true }
        @{ File = "05-manual-qa.md"; Phase = "05"; Name = "Manual QA"; Optional = $true }
        @{ File = "00-worktree.md"; Phase = "00"; Name = "Worktree Setup"; Optional = $true }
    )
    
    $runValid = $true
    $runFixed = $false
    
    foreach ($artifact in $artifacts) {
        $artifactPath = Join-Path $runDir $artifact.File
        
        if (-not (Test-Path -LiteralPath $artifactPath)) {
            if (-not $artifact.Optional) {
                Write-Status -Status "INFO" -Message "$($artifact.Name): Not found (optional)"
            }
            continue
        }
        
        # Check if locked
        $content = Get-Content -LiteralPath $artifactPath -Raw -Encoding UTF8
        if (-not ($content -match "Status:\s*`?LOCKED`?")) {
            Write-Status -Status "WARN" -Message "$($artifact.Name): Not locked (DRAFT)"
            $runValid = $false
            continue
        }
        
        # Test lock validity
        $result = Test-LockValid -ArtifactPath $artifactPath -Fix:$Fix
        
        if ($result.Valid) {
            Write-Status -Status "PASS" -Message "$($artifact.Name): Valid (locked at $($result.LockedAt))"
        } else {
            if ($result.Fixed) {
                Write-Status -Status "WARN" -Message "$($artifact.Name): Fixed hash mismatch (was tampered)"
                Write-Host "         Old hash: $($result.StoredHash)"
                Write-Host "         New hash: $($result.ActualHash)"
                Write-Host "         Updated at: $($result.NewLockedAt)"
                $runFixed = $true
            } else {
                Write-Status -Status "FAIL" -Message "$($artifact.Name): $($result.Error)"
                if ($result.StoredHash) {
                    Write-Host "         Stored: $($result.StoredHash)"
                    Write-Host "         Actual: $($result.ActualHash)"
                }
                $runValid = $false
            }
        }
        
        # Check gates
        $coverage = Test-CoverageGate -ArtifactPath $artifactPath
        $approval = Test-ApprovalGate -ArtifactPath $artifactPath
        
        if (-not $coverage.Pass) {
            Write-Status -Status "FAIL" -Message "$($artifact.Name): Coverage gate - $($coverage.Reason)"
            $runValid = $false
        }
        
        if (-not $approval.Pass) {
            Write-Status -Status "FAIL" -Message "$($artifact.Name): Approval gate - $($approval.Reason)"
            $runValid = $false
        }
    }
    
    # Check addenda
    $addendaDir = Join-Path $runDir "addenda"
    if (Test-Path -LiteralPath $addendaDir) {
        $addendaFiles = Get-ChildItem -Path $addendaDir -Filter "*.md"
        if ($addendaFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "Addenda:"
            foreach ($addendum in $addendaFiles) {
                $addendumPath = $addendum.FullName
                $result = Test-LockValid -ArtifactPath $addendumPath -Fix:$Fix
                
                if ($result.Valid) {
                    Write-Status -Status "PASS" -Message "  $($addendum.Name): Valid"
                } else {
                    if ($result.Fixed) {
                        Write-Status -Status "WARN" -Message "  $($addendum.Name): Fixed"
                        $runFixed = $true
                    } else {
                        Write-Status -Status "FAIL" -Message "  $($addendum.Name): $($result.Error)"
                        $runValid = $false
                    }
                }
            }
        }
    }
    
    Write-Host ""
    
    if ($runValid -and -not $runFixed) {
        $validRuns++
        Write-Status -Status "PASS" -Message "Run '$run': All locks valid"
    } elseif ($runFixed) {
        $fixedRuns++
        Write-Status -Status "WARN" -Message "Run '$run': Locks fixed (tampering detected)"
    } else {
        $failedRuns++
        Write-Status -Status "FAIL" -Message "Run '$run': Lock verification failed"
    }
    
    Write-Host ""
}

# Summary
Write-Host "====================="
Write-Host "Summary"
Write-Host "====================="
Write-Host ""
Write-Host "Total runs checked: $totalRuns"
Write-Status -Status "PASS" -Message "Valid runs: $validRuns"
if ($fixedRuns -gt 0) {
    Write-Status -Status "WARN" -Message "Fixed runs (tampered): $fixedRuns"
}
if ($failedRuns -gt 0) {
    Write-Status -Status "FAIL" -Message "Failed runs: $failedRuns"
}

Write-Host ""

if ($failedRuns -eq 0) {
    Write-Status -Status "PASS" -Message "All locks verified successfully"
    exit 0
} else {
    Write-Status -Status "FAIL" -Message "Some locks failed verification"
    exit 1
}


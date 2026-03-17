# RLM Artifact Writing Guide and Templates

Use this file when writing any per-run artifact in:
- `/.codex/rlm/<run-id>/00-worktree.md`
- `/.codex/rlm/<run-id>/00-requirements.md`
- `/.codex/rlm/<run-id>/01-as-is.md`
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
- `/.codex/rlm/<run-id>/04-test-summary.md`
- `/.codex/rlm/<run-id>/05-manual-qa.md`
- `/.codex/rlm/<run-id>/addenda/*.md`

This guide is intentionally prescriptive so two different agents produce equivalent artifacts.

## Table of Contents

- [Quick Start Checklist](#quick-start-checklist)
- [Required Header (All Artifacts)](#required-header-all-artifacts)
- [Universal Sections (All Artifacts Except `00-requirements.md`)](#universal-sections-all-artifacts-except-00-requirementsmd)
- [Evidence Directory (Per Run)](#evidence-directory-per-run)
- [Phase-by-Phase Authoring Templates](#phase-by-phase-authoring-templates)
- [Phase 0 Template (`00-worktree.md`) - Isolation REQUIRED](#phase-0-template-00-worktreemd---isolation-required)
- [Phase 0 Requirements Template (`00-requirements.md`)](#phase-0-requirements-template-00-requirementsmd)
- [Phase 1 Template (`01-as-is.md`)](#phase-1-template-01-as-ismd)
- [Phase 1.5 Template (`01.5-root-cause.md`) - Debug Mode Only](#phase-15-template-015-root-causemd---debug-mode-only)
- [Phase 2 Template (`02-to-be-plan.md`, ExecPlan Grade)](#phase-2-template-02-to-be-planmd-execplan-grade)
- [Phase 3 Template (`03-implementation-summary.md`)](#phase-3-template-03-implementation-summarymd)
- [Phase 3.5 Template (`03.5-code-review.md`) - Optional](#phase-35-template-035-code-reviewmd---optional)
- [Phase 4 Template (`04-test-summary.md`)](#phase-4-template-04-test-summarymd)
- [Phase 5 Template (`05-manual-qa.md`)](#phase-5-template-05-manual-qamd)
- [Addenda Templates](#addenda-templates)
- [Stage-Local Addendum](#stage-local-addendum)
- [Upstream-Gap Addendum](#upstream-gap-addendum)
- [Artifact Linting (Structure + TODO Discipline)](#artifact-linting-structure--todo-discipline)
- [Locking Commands](#locking-commands)
- [Common Failure Modes (Use as Pre-Lock Checklist)](#common-failure-modes-use-as-pre-lock-checklist)
- [Lock Verification](#lock-verification)

## Quick Start Checklist

1. Resolve the run id and exact output path.
2. **Ensure `00-requirements.md` exists, then create/lock Phase 0 worktree (`00-worktree.md`) before Phase 1+ (isolated workspace setup).**
3. **If writing Phase 3 or later, verify all prior phase artifacts are lock-valid before proceeding.**
4. Verify phase isolation: only the current phase may be `DRAFT`; do not proceed if a prior phase is unresolved.
5. Determine effective inputs:
   - base input files for this phase
   - plus stage-local addenda for each base input, lexical order
6. Write the required header with exact input/output paths.
7. Write phase-specific content sections from this guide.
8. Write `Traceability`, `Coverage Gate`, and `Approval Gate`.
9. Perform a pre-lock completeness check using this template's required sections and gates.
10. Verify LockHash matches SHA-256 of content before locking.
11. Lock only after both gates pass (`Status`, `LockedAt`, `LockHash`).

## Required Header (All Artifacts)

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `0N <phase-name>`
Status: `DRAFT`
Inputs:
- `/<path-to-input-1>`
- `/<path-to-input-2>`
Outputs:
- `/<path-to-this-output>`
Scope note: One short paragraph describing what this artifact decides or enables.
```

When locking, append:

```md
LockedAt: `YYYY-MM-DDTHH:MM:SSZ`
LockHash: `<sha256-hex>`
```

## Universal Sections (All Artifacts Except `00-requirements.md`)

Traceability is not required in `00-requirements.md`, but every downstream artifact (Phase 1+) must include it.

```md
## Traceability

- `R1` -> [where this artifact addresses it] | Evidence: [files, commands, observations]
- `R2` -> [where this artifact addresses it] | Evidence: [files, commands, observations]
- `R3` -> Deferred in this phase | Rationale: [...] | Impact: [...]
```

```md
## Coverage Gate

- Effective inputs reviewed:
  - `/<base-input-1>`
  - `/<matching-addendum-1>`
  - `/<matching-addendum-2>`
- Requirement coverage check:
  - `R1`: Covered at [section]
  - `R2`: Covered at [section]
  - `R3`: Deferred [why]
- Out-of-scope confirmation:
  - `OOS1`: unchanged
  - `OOS2`: unchanged

Coverage: PASS
```

```md
## Approval Gate

- Objective readiness checks:
  - [artifact is internally consistent]
  - [commands are runnable and specific]
  - [tests/QA expectations are explicit for this phase]
  - [no required section is missing]
- Remaining blockers:
  - none

Approval: PASS
```

If either gate fails, set `FAIL` and list exact fixes required before proceeding.

## Evidence Directory (Per Run)

To keep Phase 4/5 fast and reproducible, store all non-Markdown evidence artifacts under a standard folder:

- `/.codex/rlm/<run-id>/evidence/`
  - `screenshots/` (UI screenshots, failure screenshots)
  - `logs/` (console/server/CI excerpts)
  - `perf/` (profiles, measurements, benchmarks)
  - `traces/` (Playwright traces, HARs; if applicable)
  - `other/` (fallback)

Reference these artifacts in Phase 3/4/5 using repo-relative paths.

## Phase-by-Phase Authoring Templates

## Phase 0 Template (`00-worktree.md`) - Isolation REQUIRED

Required outcome:
- Isolated git worktree created on feature branch
- Worktree directory verified as git-ignored
- Project setup completed
- Clean test baseline verified
- Main branch protection confirmed

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `00 Worktree Setup`
Status: `DRAFT`
Inputs:
- Current git repository state
- User preference (for worktree location)
Outputs:
- `/.codex/rlm/<run-id>/00-worktree.md`
- Isolated worktree at `[location]`
Scope note: This document records isolated workspace setup and verifies clean test baseline.

## TODO

- [ ] Verify current branch (main/master protection check)
- [ ] Select worktree location (`.worktrees/<run-id>/` preferred)
- [ ] Verify worktree directory is git-ignored
- [ ] Create git worktree with feature branch
- [ ] Run project setup (npm install, cargo build, etc.)
- [ ] Verify clean test baseline (all tests passing)
- [ ] Document worktree location and branch name
- [ ] Record baseline commit SHA

## Directory Selection

**Convention checked:**
- [ ] `.worktrees/` exists
- [ ] `worktrees/` exists
- [ ] CLAUDE.md preference found
- [ ] User preference obtained

**Selected location:** `.worktrees/` (project-local, hidden)
**Rationale:** [why this location]

## Safety Verification

**Gitignore check:**
```bash
$ git check-ignore -q .worktrees && echo "IGNORED" || echo "NOT IGNORED"
IGNORED
```

**Result:** ? Directory is properly ignored

(If NOT ignored: added to .gitignore and committed before proceeding)

## Worktree Creation

**Current branch before:** `main` (or `master`)

**Command:**
```bash
git worktree add .worktrees/<run-id> -b rlm/<run-id>
```

**Output:**
```
Preparing worktree (new branch 'rlm/<run-id>')
HEAD is now at abc1234 Previous commit message
```

**Branch created:** `rlm/<run-id>`
**Worktree location:** `/full/path/to/project/.worktrees/<run-id>`

## Main Branch Protection

**Original branch:** `main`
**Action:** Created worktree (default behavior)
**Isolation:** ? Working in isolated worktree

(If on main and user insisted: document explicit consent here)

## Project Setup

**Detected project type:** [Node.js/Rust/Python/Go/etc.]

**Commands executed:**
```bash
cd .worktrees/<run-id>
[npm install / cargo build / pip install / etc.]
```

**Output:**
```
[setup output]
```

**Setup status:** ? Complete / ? Issues noted

## Test Baseline Verification

**Command:**
```bash
[npm test / cargo test / pytest / etc.]
```

**Results:**
- Total: [N] tests
- Passed: [N]
- Failed: [N]
- Skipped: [N]

**Baseline:** ? Clean (all tests passing) / ? Pre-existing failures noted

(If failures exist, document and get explicit consent to proceed)

## Worktree Context

**All subsequent phases will execute in:**
- Directory: `.worktrees/<run-id>/`
- Branch: `rlm/<run-id>`
- Base commit: `abc1234`

## Traceability

- RLM process -> Isolated workspace established | Evidence: worktree at `.worktrees/<run-id>`

## Coverage Gate

- [ ] Worktree location selected following priority rules
- [ ] Directory verified as git-ignored (if project-local)
- [ ] Worktree created successfully on feature branch
- [ ] Project setup completed without errors
- [ ] Clean test baseline verified (all tests passing, or failures documented)
- [ ] Main branch protection confirmed (working in isolation, or consent documented)

Coverage: PASS / FAIL

## Approval Gate

- [ ] Isolated workspace ready for development
- [ ] No pending setup issues
- [ ] Ready to proceed to Phase 1/2
- [ ] LockHash matches SHA-256 of content (verified)

Approval: PASS / FAIL

LockedAt: `YYYY-MM-DDTHH:MM:SSZ`
LockHash: `<sha256-hex>`
```

## Phase 0 Requirements Template (`00-requirements.md`)

Required outcome:
- stable requirement IDs (`R1`, `R2`, ...)
- out-of-scope IDs (`OOS1`, `OOS2`, ...)
- observable acceptance criteria per requirement
- constraints/assumptions

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `00 Requirements`
Status: `DRAFT`
Inputs:
- [chat summary or source notes if captured in repo]
Outputs:
- `/.codex/rlm/<run-id>/00-requirements.md`
Scope note: This document defines stable requirement identifiers and acceptance criteria.

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

### `R2` <short title>
Description:
Acceptance criteria:
- [...]

## Out of Scope

- `OOS1`: ...
- `OOS2`: ...

## Constraints

- ...

## Assumptions

- ...

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Phase 1 Template (`01-as-is.md`)

Required outcome:
- novice-runnable repro
- current behavior tied to `R#`
- concrete code pointers
- known unknowns

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `01 AS-IS`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/00-requirements.md`
- `/.codex/rlm/<run-id>/addenda/00-requirements.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/01-as-is.md`
Scope note: This document captures current behavior and evidence before changes.

## TODO

- [ ] Read and understand requirements from Phase 1
- [ ] Read and understand requirements from Phase 0
- [ ] Create novice-runnable reproduction steps
- [ ] Document current behavior for each requirement (R1, R2, ...)
- [ ] Identify and record relevant code pointers
- [ ] List known unknowns
- [ ] Gather evidence (logs, screenshots, outputs)
- [ ] Create traceability mapping
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Reproduction Steps (Novice-Runnable)

1. ...
2. ...
3. ...

## Current Behavior by Requirement

- `R1`: [what currently happens]
- `R2`: [what currently happens]

## Relevant Code Pointers

- `path/to/file.ext`: [why relevant]
- `path/to/other.ext`: [why relevant]

## Known Unknowns

- ...

## Evidence

- Command output: ...
- Log snippet: ...
- UI observation: ...

## Traceability
...

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Phase 1.5 Template (`01.5-root-cause.md`) - Debug Mode Only

Required outcome:
- systematic root cause analysis for bug fixes
- error analysis, reproduction verification, data flow tracing
- documented hypothesis testing
- root cause summary for Phase 2 planning

**Use when:** Requirement involves fixing a bug, test failure, or investigating unexpected behavior.

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `01.5 Root Cause Analysis`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/01-as-is.md`
- [relevant addenda]
Outputs:
- `/.codex/rlm/<run-id>/01.5-root-cause.md`
Scope note: This document records systematic debugging process and identified root cause before any fix is attempted.

## TODO

- [ ] Analyze error messages and stack traces
- [ ] Verify reproduction (confirm bug is reproducible)
- [ ] Review recent changes (git history, dependencies)
- [ ] Gather evidence (logs, data flow, state inspection)
- [ ] Trace data flow to identify source
- [ ] Analyze patterns (working vs broken comparisons)
- [ ] Form and test hypotheses
- [ ] Confirm root cause (not just symptom)
- [ ] Define fix strategy for Phase 3
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Error Analysis

**Error Message:** [verbatim]
**Stack Trace:** [key frames]
**File:Line:** [locations]
**Key Insight:** [what the error is telling you]

## Reproduction Verification

**Steps:**
1. [exact step]
2. [exact step]
3. [exact step]

**Reproducible:** Yes / No / Intermittent
**Frequency:** [X out of Y attempts]
**Deterministic:** Yes / No

## Recent Changes Analysis

**Git History:** [relevant commits]
**Dependency Changes:** [if applicable]
**Environment:** [OS, runtime versions]
**Likely Culprit:** [most suspicious change]

## Evidence Gathering (Multi-Layer if applicable)

**Layer 1: [Component]**
- Input: [data]
- Output: [data]
- Status: ? Working / ? Broken

**Failure Boundary:** [where it breaks]

## Data Flow Trace

**Error Location:** [file:line - function]
**Bad Value:** [what was wrong]

**Call Stack (backward):**
1. `functionA()` at fileA:line - received [value]
2. `functionB()` at fileB:line - passed [value]
3. [source] `functionC()` at fileC:line - ORIGIN

## Pattern Analysis

**Working Example:** [file:location]
**Broken Code:** [file:location]

**Key Differences:**
| Aspect | Working | Broken |
|--------|---------|--------|
| [X] | [value] | [value] |

## Hypothesis Testing

### Hypothesis 1
**Statement:** [clear hypothesis]
**Test:** [minimal change]
**Result:** [confirmed/rejected]

### Hypothesis 2 (if needed)
[...]

**Confirmed Root Cause:** [final hypothesis]

## Root Cause Summary

**Root Cause:** [one sentence]
**Location:** [file:line]
**Detailed Explanation:** [paragraph]
**Fix Strategy:** [approach for Phase 3]
**Test Strategy:** [how to verify fix]

## Traceability

- R# (Bug fix requirement) -> Root cause identified at [location] | Evidence: [section]

## Coverage Gate

- [ ] Error messages analyzed
- [ ] Reproduction verified
- [ ] Recent changes reviewed
- [ ] Data flow traced to source
- [ ] Pattern analysis completed
- [ ] Hypothesis tested and confirmed
- [ ] Root cause documented (not just symptom)
- [ ] Fix strategy defined

Coverage: PASS / FAIL

## Approval Gate

- [ ] Root cause identified at source (not just symptom location)
- [ ] Fix approach clear and minimal
- [ ] Test strategy defined
- [ ] No "quick fix" attempts made
- [ ] Ready to proceed to Phase 3 with fix plan

Approval: PASS / FAIL
```

## Phase 2 Template (`02-to-be-plan.md`, ExecPlan Grade)

Required outcome:
- concrete edits by file and location
- exact commands
- tests to add/run
- manual QA scenarios
- recovery/idempotence
- traceability mapping `R# -> planned change + validation`
- sub-phases (`SP1`, `SP2`, ...) when scope/risk is large

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `02 TO-BE plan`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/01-as-is.md`
- `/.codex/rlm/<run-id>/00-requirements.md`
- `/.codex/rlm/<run-id>/addenda/01-as-is.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
Scope note: This document defines the implementation and validation plan.

## TODO

- [ ] Read Phase 2 (AS-IS) and Phase 1 (Requirements) artifacts
- [ ] If Phase 1.5 exists: incorporate root cause findings
- [ ] Define sub-phases (SP1, SP2, ...) if scope/risk is large
- [ ] Specify concrete file changes (what, where, how)
- [ ] Define implementation steps in sequence
- [ ] Design testing strategy (new + regression + guardrail)
- [ ] Document Playwright test plan (if applicable)
- [ ] Define manual QA scenarios
- [ ] Create traceability mapping (R# -> changes -> validation)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Planned Changes by File

- `path/to/file.ext`: [exact change]
- `path/to/file2.ext`: [exact change]

## Implementation Steps

1. ...
2. ...
3. ...

## Testing Strategy

- New behavior tests: ...
- Regression tests: ...
- Guardrail tests: ...
- Commands:
  - `...`
  - `...`

## Playwright Plan (if applicable)

- Tags: `@rlm:<run-id>`, `@sp1`, `@smoke`
- Tier A command(s): `...`
- Tier B command(s): `...`
- Evidence outputs: `playwright-report/`, `test-results/`

## Manual QA Scenarios

1. Scenario:
   - Steps:
   - Expected:

2. Scenario:
   - Steps:
   - Expected:

## Idempotence and Recovery

- Re-run safety notes:
- Rollback notes:

## Implementation Sub-phases

### `SP1` <name>
Scope and requirement mapping:
- Covers: `R1`, `R3`

Implementation checklist:
- [ ] edit `path/to/file.ext` ...
- [ ] add test `path/to/test.spec.ts` ...

Tests for this sub-phase:
- `...`
- Pass criteria: ...

Sub-phase acceptance:
- ...

### `SP2` <name>
[same structure]

## Traceability
...

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Phase 3 Template (`03-implementation-summary.md`)

Required outcome:
- what changed, where, why
- implementation evidence
- **TDD compliance log (RED-GREEN-REFACTOR for each requirement)**
- deviations from plan (if any)

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `03 Implementation`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/addenda/02-to-be-plan.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
Scope note: This document records completed code changes, TDD compliance, and implementation evidence.

## TODO

- [ ] Read locked Phase 3 (TO-BE) plan
- [ ] Determine execution mode (Parallel vs Sequential)
- [ ] For each sub-phase (SP1, SP2, ...):
  - [ ] Implement per plan (TDD discipline)
  - [ ] Write tests BEFORE code (RED phase)
  - [ ] Make tests pass (GREEN phase)
  - [ ] Refactor while keeping tests green
  - [ ] Self-review / subagent review
  - [ ] Run integration tests
- [ ] Complete TDD Compliance Log for all requirements
- [ ] Document any plan deviations
- [ ] Record implementation evidence (diffs, logs)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Changes Applied

- `path/to/file.ext`: [change summary]
- `path/to/file2.ext`: [change summary]

## Sub-phase Implementation Summary

- `SP1`: [what shipped, files touched, notes]
- `SP2`: [what shipped, files touched, notes]

## TDD Compliance Log

**The Iron Law:** NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

### Requirement R1 ([description])

**Test:** `path/to/test.spec.ts` - "[test name]"

**RED Phase** ([ISO8601 timestamp]):
```bash
[exact command run]
[test failure output - showing it failed correctly]
```
- Expected failure: [what should fail]
- Actual failure: [what actually failed]
- RED verified: ? / ?

**GREEN Phase** ([ISO8601 timestamp]):
- Implementation: [minimal change made]
```bash
[exact command run]
[test pass output]
```
- GREEN verified: ? / ?

**REFACTOR Phase** ([ISO8601 timestamp]):
- Cleanups: [description of improvements]
- All tests still passing: ? / ?

**Final State:** [All tests passing / Issues noted]

### Requirement R2 (Bug Fix - Regression Test)

**Regression Test:** `path/to/regression.test.ts` - "[test name]"

**RED Phase** ([ISO8601 timestamp]):
- Bug reproduced: [evidence]
- RED verified: ? / ?

**GREEN Phase** ([ISO8601 timestamp]):
- Fix applied: [minimal change]
- GREEN verified: ? / ?

**REFACTOR:** [N/A or description]

**Final State:** [Test passes, bug fixed]

### TDD Red Flags Check

- [ ] No code written before failing test
- [ ] All RED phases documented with failure output
- [ ] All GREEN phases documented with minimal implementation
- [ ] No tests passing immediately (would indicate wrong test)
- [ ] No "tests to be added later"

## Plan Deviations

- Deviation:
  - Why:
  - Impact:
  - Evidence:

## Implementation Evidence

- Diff pointers:
- Runtime evidence:
- Build/lint results:

## Traceability
...

## Coverage Gate

- [ ] All requirements (R1..Rn) have implementation
- [ ] All sub-phases completed
- [ ] TDD Compliance Log complete for all requirements
- [ ] No production code without preceding failing test
- [ ] Plan deviations documented (if any)
- [ ] Implementation evidence recorded

TDD Compliance: PASS / FAIL
Coverage: PASS / FAIL

## Approval Gate

- [ ] Implementation matches Phase 2 TO-BE plan (or deviations documented)
- [ ] All tests passing
- [ ] Build/lint clean
- [ ] TDD Iron Law followed (no code before tests)
- [ ] Ready for Phase 5

Approval: PASS / FAIL
```

## Phase 3.5 Template (`03.5-code-review.md`) - Optional

Required outcome:
- Independent review of Phase 3 implementation against plan
- Code quality assessment
- Issue classification (Critical/Important/Minor)
- Clear verdict (Approved / Changes Required)

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `03.5 Code Review`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
- Git range: BASE_SHA..HEAD_SHA
Outputs:
- `/.codex/rlm/<run-id>/03.5-code-review.md`
Scope note: This document records independent review of implementation against plan and coding standards.

## TODO

- [ ] Read Phase 2 plan and Phase 3 implementation summary
- [ ] Review git diff (BASE_SHA..HEAD_SHA)
- [ ] Assess plan alignment for each requirement (R1, R2, ...)
- [ ] Assess plan alignment for each sub-phase (SP1, SP2, ...)
- [ ] Evaluate code quality (architecture, naming, error handling)
- [ ] Evaluate test quality (coverage, edge cases)
- [ ] Verify TDD compliance
- [ ] Categorize issues (Critical/Important/Minor)
- [ ] Document positive findings
- [ ] Record recommendations
- [ ] Render verdict (Approved / Changes Required)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Review Scope

- Sub-phases reviewed: SP1, SP2, ...
- Git range reviewed: [BASE_SHA]..[HEAD_SHA]

## Plan Alignment Assessment

- **R1**: [description]
  - Plan requirement: [what was planned]
  - Implementation: [what was done]
  - Aligned: OK / WARN / FAIL
  - Notes: [deviations if any]

- **SP1**: [description]
  - Plan specification: [what was specified]
  - Implementation: [what was done]
  - Aligned: OK / WARN / FAIL
  - Notes: [deviations if any]

## Code Quality Assessment

### Architecture & Design
- SOLID principles: OK / WARN / FAIL
- Separation of concerns: OK / WARN / FAIL
- Integration with existing code: OK / WARN / FAIL

### Code Quality
- Naming conventions: OK / WARN / FAIL
- Error handling: OK / WARN / FAIL
- Type safety: OK / WARN / FAIL
- Maintainability: OK / WARN / FAIL

### Test Quality
- Test coverage adequate: OK / WARN / FAIL
- Test quality: OK / WARN / FAIL
- Edge cases covered: OK / WARN / FAIL

### TDD Compliance
- All production code preceded by failing tests: OK / WARN / FAIL
- TDD cycles documented: OK / WARN / FAIL
- No evidence of "code first, test later": OK / WARN / FAIL

## Issues Found

### Critical (must fix before proceeding)
1. **[Issue name]**
   - **Location:** `file:line`
   - **Problem:** [description]
   - **Recommendation:** [specific fix]

### Important (should fix)
1. **[Issue name]**
   - **Location:** `file:line`
   - **Problem:** [description]
   - **Recommendation:** [specific fix]

### Minor (suggestions)
1. **[Issue name]**
   - **Suggestion:** [description]

## Positive Findings

- [What was done well]

## Recommendations

- **Immediate:** [what to fix now]
- **Future:** [improvements for later]

## Verdict

- [ ] **APPROVED** - Ready to proceed to Phase 5
- [ ] **APPROVED WITH NOTES** - Minor issues, can proceed
- [ ] **CHANGES REQUIRED** - Fix issues, then re-review

## Review Metadata

- Reviewer: [agent name / self-review]
- Execution Mode: Parallel (subagent) / Sequential (self-review)
- Review duration: [time spent]
- Files reviewed: [count]
- Lines of code reviewed: [count]

## Traceability
...

## Coverage Gate

- [ ] All sub-phases reviewed
- [ ] Plan alignment verified for all requirements
- [ ] Code quality assessed
- [ ] Issues categorized by severity
- [ ] Verdict recorded

Coverage: PASS / FAIL

## Approval Gate

- [ ] Review completed objectively
- [ ] Issues clearly documented
- [ ] Verdict justified
- [ ] Ready for Phase 5 (if approved)

Approval: PASS / FAIL
```

## Phase 4 Template (`04-test-summary.md`)

Required outcome:
- pre-test implementation audit against requirements and TO-BE plan
- exact commands executed
- pass/fail outcomes
- evidence artifact locations (standardized under `/.codex/rlm/<run-id>/evidence/`)
- flake/retry notes
- parallel test execution summary (if applicable)

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `04 Test Summary`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
- `/.codex/rlm/<run-id>/03.5-code-review.md` [if present]
- [relevant addenda]
Outputs:
- `/.codex/rlm/<run-id>/04-test-summary.md`
Scope note: This document records test execution evidence and readiness.

## TODO

- [ ] Read Phase 2 plan and Phase 3 implementation summary
- [ ] Audit implementation summary against `00-requirements.md` and `02-to-be-plan.md`
- [ ] Determine test execution mode (Parallel vs Sequential)
- [ ] Execute unit tests (document commands and results)
- [ ] Execute integration tests (document commands and results)
- [ ] Execute E2E Tier A tests (document commands and results)
- [ ] Execute Tier B regression tests (if applicable)
- [ ] Document any failures and diagnostics
- [ ] Note any flake/retry occurrences
- [ ] Verify TDD compliance (all Phase 3 tests passing)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Pre-Test Implementation Audit

- Requirement alignment (`00-requirements.md`): list each requirement and confirm implemented/not implemented with evidence.
- Plan alignment (`02-to-be-plan.md`): list planned steps/sub-phases and confirm implemented/not implemented with evidence.
- Mismatches found:
  - [ ] None
  - [ ] Yes (document each mismatch and required addendum or fix before proceeding)

## Environment

- OS:
- Runtime versions:
- Test framework versions:
- Base URL / server mode:

## Execution Mode

- **Mode:** Parallel / Sequential
- **Subagent Usage:**
  - Unit tests: [subagent name] / Main agent
  - Integration tests: [subagent name] / Main agent
  - E2E tests: [subagent name] / Main agent
- **Parallel execution time:** [X] minutes (vs [Y] estimated sequential)

## Commands Executed (Exact)

- `...`
- `...`

## Results Summary

- Total:
- Passed:
- Failed:
- Skipped:

## Evidence and Artifacts

Store and reference artifacts under:
- `/.codex/rlm/<run-id>/evidence/`
  - `evidence/screenshots/`
  - `evidence/logs/`
  - `evidence/perf/`
  - `evidence/traces/` (if applicable)

## By Sub-phase

- `SP1`:
  - Tier A command(s):
  - Result:
  - Evidence path(s):
- `SP2`:
  - Tier A command(s):
  - Result:
  - Evidence path(s):

## Tier B / Broader Regression

- Command(s):
- Result:
- Evidence path(s):

## Failures and Diagnostics (if any)

- Failing test:
  - Symptom:
  - Suspected cause:
  - Artifact path:
  - Mitigation:

## Flake/Rerun Notes

- Rerun command:
- Outcome:
- Deterministic or flaky:

## Traceability
...

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Phase 5 Template (`05-manual-qa.md`)

Required outcome:
- plan scenarios executed by user
- observed outcomes
- explicit user sign-off

Compact table is allowed in this phase.

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `05 Manual QA`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- [relevant addenda]
Outputs:
- `/.codex/rlm/<run-id>/05-manual-qa.md`
Scope note: This document records user-validated QA outcomes and sign-off.

## TODO

- [ ] Read Phase 2 plan (QA scenarios)
- [ ] Present QA scenarios to user
- [ ] **PAUSE:** Wait for user to execute scenarios
- [ ] Record observed outcomes for each scenario
- [ ] Document pass/fail status
- [ ] Record user sign-off (name, date, notes)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## QA Scenarios and Results

| Scenario | Expected | Observed | Pass/Fail | Notes |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... |

## Evidence and Artifacts

Store and reference artifacts under:
- `/.codex/rlm/<run-id>/evidence/`
  - `evidence/screenshots/` (screenshots, videos-as-files)
  - `evidence/logs/` (console/server output excerpts)
  - `evidence/perf/` (if QA included perf checks)

## User Sign-Off

- Approved by:
- Date:
- Notes:

## Traceability
...

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

If user has not yet signed off, keep `Approval: FAIL` and list what is pending.

## Addenda Templates

## Stage-Local Addendum

File name:
- `<base>.addendum-01.md`

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `<current phase>`
Status: `DRAFT`
Inputs:
- `<base artifact>`
Outputs:
- `/.codex/rlm/<run-id>/addenda/<base>.addendum-01.md`
Scope note: This addendum supplements phase-local content without changing locked history.

## TODO

- [ ] Add the missing information
- [ ] Update Traceability/Coverage implications in the current phase artifact (if needed)
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Addendum Content

- Added/clarified information:
- Rationale:
- Impact on phase output:

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Upstream-Gap Addendum

File name:
- `<current>.upstream-gap.<prior>.addendum-01.md`

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `<current phase>`
Status: `DRAFT`
Inputs:
- `<current phase inputs>`
- `<locked prior artifact>`
Outputs:
- `/.codex/rlm/<run-id>/addenda/<current>.upstream-gap.<prior>.addendum-01.md`
Scope note: This addendum records a discovered gap in a locked upstream artifact.

## TODO

- [ ] Record the upstream gap precisely
- [ ] Add discovery evidence (commands, files, outputs)
- [ ] State impact and compensation plan
- [ ] Update current-phase planning/implementation accordingly
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Gap Statement

- Missing or incorrect upstream content:

## Discovery Evidence

- How the gap was found:
- Supporting evidence:

## Impact

- Impact on current phase:
- Impact on later phases:

## Compensation Plan

- Tests, validation, or process compensations applied now:

## Traceability Impact

- Affected requirements: `R#`, `R#`

## Coverage Gate
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Artifact Linting (Structure + TODO Discipline)

Before locking (or when a lock verification fails unexpectedly), lint the run artifacts for required header fields, required section headings, and TODO completion rules:

```powershell
# Python (cross-platform):
python ./.agents/skills/rlm-workflow/scripts/lint-rlm-run.py --run-id "<run-id>"
# Or, when running from this repo:
python ./scripts/lint-rlm-run.py --run-id "<run-id>"
python3 ./.agents/skills/rlm-workflow/scripts/lint-rlm-run.py --run-id "<run-id>"
python3 ./scripts/lint-rlm-run.py --run-id "<run-id>"

# Treat WARN as FAIL
python ./.agents/skills/rlm-workflow/scripts/lint-rlm-run.py --run-id "<run-id>" --strict
python ./scripts/lint-rlm-run.py --run-id "<run-id>" --strict
python3 ./.agents/skills/rlm-workflow/scripts/lint-rlm-run.py --run-id "<run-id>" --strict
python3 ./scripts/lint-rlm-run.py --run-id "<run-id>" --strict

# Lint specific run
.\.agents\skills\rlm-workflow\scripts\lint-rlm-run.ps1 -RunId "<run-id>"
# Or, when running from this repo:
.\scripts\lint-rlm-run.ps1 -RunId "<run-id>"

# Treat WARN as FAIL
.\.agents\skills\rlm-workflow\scripts\lint-rlm-run.ps1 -RunId "<run-id>" -Strict
.\scripts\lint-rlm-run.ps1 -RunId "<run-id>" -Strict
```

## Locking Commands

PowerShell:

```powershell
$p = '.codex/rlm/<run-id>/<artifact>.md'
$t = Get-Content -LiteralPath $p -Raw -Encoding UTF8
$n = ($t -replace "`r`n","`n") -replace "(?m)^LockHash:.*(?:`n|$)",""
$b = [System.Text.Encoding]::UTF8.GetBytes($n)
$h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
($h | ForEach-Object { $_.ToString("x2") }) -join ""
```

Shell:

```bash
sed '/^LockHash:/d' .codex/rlm/<run-id>/<artifact>.md | tr -d '\r' | sha256sum
```

## Common Failure Modes (Use as Pre-Lock Checklist)

- Missing one or more effective-input addenda under `Inputs`.
- Coverage Gate says PASS but does not map every `R#`.
- Approval Gate says PASS with unresolved blockers.
- `Traceability` references vague evidence instead of concrete files/commands.
- Artifact locked without `LockedAt` and `LockHash`.
- **LockHash does not match SHA-256 of normalized content (tampering detected).**
- Editing locked prior-phase artifacts instead of writing addenda.
- Working on main/master branch without explicit consent documented.
- Worktree directory not git-ignored (project-local worktrees).
- Baseline tests failing (pre-existing issues not documented).

## Lock Verification

### Automated Verification

Use the provided script to verify all locks in a run:

```bash
# Verify specific run
python ./.agents/skills/rlm-workflow/scripts/verify-locks.py --run-id "2026-02-21-feature"
# Or, when running from this repo:
python ./scripts/verify-locks.py --run-id "2026-02-21-feature"
python3 ./.agents/skills/rlm-workflow/scripts/verify-locks.py --run-id "2026-02-21-feature"
python3 ./scripts/verify-locks.py --run-id "2026-02-21-feature"

# Fix incorrect hashes (use with caution)
python ./.agents/skills/rlm-workflow/scripts/verify-locks.py --run-id "2026-02-21-feature" --fix
# Or, when running from this repo:
python ./scripts/verify-locks.py --run-id "2026-02-21-feature" --fix
python3 ./.agents/skills/rlm-workflow/scripts/verify-locks.py --run-id "2026-02-21-feature" --fix
python3 ./scripts/verify-locks.py --run-id "2026-02-21-feature" --fix
```

```powershell
# Verify specific run
.\.agents\skills\rlm-workflow\scripts\verify-locks.ps1 -RunId "2026-02-21-feature"
# Or, when running from this repo:
.\scripts\verify-locks.ps1 -RunId "2026-02-21-feature"

# Fix incorrect hashes (use with caution)
.\.agents\skills\rlm-workflow\scripts\verify-locks.ps1 -RunId "2026-02-21-feature" -Fix
# Or, when running from this repo:
.\scripts\verify-locks.ps1 -RunId "2026-02-21-feature" -Fix
```

### Manual Verification

Compute SHA-256 hash:

**PowerShell:**
```powershell
$p = '.codex/rlm/<run-id>/<artifact>.md'
$t = Get-Content -LiteralPath $p -Raw -Encoding UTF8
$n = ($t -replace "`r`n","`n") -replace "(?m)^LockHash:.*(?:`n|$)",""
$b = [System.Text.Encoding]::UTF8.GetBytes($n)
$h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
($h | ForEach-Object { $_.ToString("x2") }) -join ""
```

**Shell:**
```bash
sed '/^LockHash:/d' .codex/rlm/<run-id>/<artifact>.md | tr -d '\r' | sha256sum
```

Compare computed hash with `LockHash` in artifact header. They must match exactly.



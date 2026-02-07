# RLM Artifact Writing Guide and Templates

Use this file when writing any per-run artifact in:
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
- [Universal Sections (All Artifacts Except Phase 1 Optional Traceability)](#universal-sections-all-artifacts-except-phase-1-optional-traceability)
- [Phase-by-Phase Authoring Templates](#phase-by-phase-authoring-templates)
- [Phase 1 Template (`00-requirements.md`)](#phase-1-template-00-requirementsmd)
- [Phase 2 Template (`01-as-is.md`)](#phase-2-template-01-as-ismd)
- [Phase 3 Template (`02-to-be-plan.md`, ExecPlan Grade)](#phase-3-template-02-to-be-planmd-execplan-grade)
- [Phase 4 Template (`03-implementation-summary.md`)](#phase-4-template-03-implementation-summarymd)
- [Phase 5 Template (`04-test-summary.md`)](#phase-5-template-04-test-summarymd)
- [Phase 6 Template (`05-manual-qa.md`)](#phase-6-template-05-manual-qamd)
- [Addenda Templates](#addenda-templates)
- [Stage-Local Addendum](#stage-local-addendum)
- [Upstream-Gap Addendum](#upstream-gap-addendum)
- [Locking Commands](#locking-commands)
- [Common Failure Modes (Use as Pre-Lock Checklist)](#common-failure-modes-use-as-pre-lock-checklist)

## Quick Start Checklist

1. Resolve the run id and exact output path.
2. If writing Phase 3 or later, verify all prior phase artifacts are lock-valid before proceeding.
3. Verify phase isolation: only the current phase may be `DRAFT`; do not proceed if a prior phase is unresolved.
4. Determine effective inputs:
   - base input files for this phase
   - plus stage-local addenda for each base input, lexical order
5. Write the required header with exact input/output paths.
6. Write phase-specific content sections from this guide.
7. Write `Traceability`, `Coverage Gate`, and `Approval Gate`.
8. Keep `Status: DRAFT` while iterating.
9. Lock only after both gates pass (`Status`, `LockedAt`, `LockHash`).

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

## Universal Sections (All Artifacts Except Phase 1 Optional Traceability)

Phase 1 may omit Traceability, but every later artifact must include it.

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

## Phase-by-Phase Authoring Templates

## Phase 1 Template (`00-requirements.md`)

Required outcome:
- stable requirement IDs (`R1`, `R2`, ...)
- out-of-scope IDs (`OOS1`, `OOS2`, ...)
- observable acceptance criteria per requirement
- constraints/assumptions

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `01 Requirements`
Status: `DRAFT`
Inputs:
- [chat summary or source notes if captured in repo]
Outputs:
- `/.codex/rlm/<run-id>/00-requirements.md`
Scope note: This document defines stable requirement identifiers and acceptance criteria.

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

## Phase 2 Template (`01-as-is.md`)

Required outcome:
- novice-runnable repro
- current behavior tied to `R#`
- concrete code pointers
- known unknowns

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `02 AS-IS`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/00-requirements.md`
- `/.codex/rlm/<run-id>/addenda/00-requirements.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/01-as-is.md`
Scope note: This document captures current behavior and evidence before changes.

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

## Phase 3 Template (`02-to-be-plan.md`, ExecPlan Grade)

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
Phase: `03 TO-BE plan`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/01-as-is.md`
- `/.codex/rlm/<run-id>/00-requirements.md`
- `/.codex/rlm/<run-id>/addenda/01-as-is.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
Scope note: This document defines the implementation and validation plan.

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

## Phase 4 Template (`03-implementation-summary.md`)

Required outcome:
- what changed, where, why
- implementation evidence
- deviations from plan (if any)

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `04 Implementation`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/addenda/02-to-be-plan.addendum-01.md` [if present]
Outputs:
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
Scope note: This document records completed code changes and implementation evidence.

## Changes Applied

- `path/to/file.ext`: [change summary]
- `path/to/file2.ext`: [change summary]

## Sub-phase Implementation Summary

- `SP1`: [what shipped, files touched, notes]
- `SP2`: [what shipped, files touched, notes]

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
...
Coverage: PASS

## Approval Gate
...
Approval: PASS
```

## Phase 5 Template (`04-test-summary.md`)

Required outcome:
- exact commands executed
- pass/fail outcomes
- evidence artifact locations
- flake/retry notes

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `05 Test Summary`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- `/.codex/rlm/<run-id>/03-implementation-summary.md`
- [relevant addenda]
Outputs:
- `/.codex/rlm/<run-id>/04-test-summary.md`
Scope note: This document records test execution evidence and readiness.

## Environment

- OS:
- Runtime versions:
- Test framework versions:
- Base URL / server mode:

## Commands Executed (Exact)

- `...`
- `...`

## Results Summary

- Total:
- Passed:
- Failed:
- Skipped:

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

## Phase 6 Template (`05-manual-qa.md`)

Required outcome:
- plan scenarios executed by user
- observed outcomes
- explicit user sign-off

Compact table is allowed in this phase.

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `06 Manual QA`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/<run-id>/02-to-be-plan.md`
- [relevant addenda]
Outputs:
- `/.codex/rlm/<run-id>/05-manual-qa.md`
Scope note: This document records user-validated QA outcomes and sign-off.

## QA Scenarios and Results

| Scenario | Expected | Observed | Pass/Fail | Notes |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... |

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

## Locking Commands

PowerShell:

```powershell
(Get-FileHash -Algorithm SHA256 '.codex/rlm/<run-id>/<artifact>.md').Hash.ToLower()
```

Shell:

```bash
sha256sum .codex/rlm/<run-id>/<artifact>.md
```

## Common Failure Modes (Use as Pre-Lock Checklist)

- Missing one or more effective-input addenda under `Inputs`.
- Coverage Gate says PASS but does not map every `R#`.
- Approval Gate says PASS with unresolved blockers.
- `Traceability` references vague evidence instead of concrete files/commands.
- Artifact locked without `LockedAt` and `LockHash`.
- Editing locked prior-phase artifacts instead of writing addenda.

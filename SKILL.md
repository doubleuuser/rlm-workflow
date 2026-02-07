---
name: rlm-workflow
description: Execute this repository's RLM (Repo-Document Workflow) end-to-end with strict phase gates, artifact locking, addenda, traceability, and single-command auto-resume behavior. Use when a request mentions "Implement requirement run-id", asks to run a specific RLM phase, requires creating or updating files in .codex/rlm/run-id/, needs an ExecPlan-grade phase 3 plan under .agent/PLANS.md, or asks to continue a paused run after manual QA.
---

# RLM Workflow

## Overview

Implement repository work using the canonical RLM process in `.agent/PLANS.md`, with invocation conventions from `.codex/AGENTS.md`. Treat repository artifacts as the source of truth and keep prompts as path-based commands.

## Install Bootstrap

Run the bootstrap script when this skill is added to a repository:

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/rlm-workflow/scripts/install-rlm-workflow.ps1 -RepoRoot .
```

The script performs installation-time setup:
- Creates `.codex/rlm/` scaffold (`.codex/rlm/.gitkeep`) and required global files if missing.
- Guarantees `.agent/PLANS.md` exists after installation.
- Adds explicit RLM workflow references to `.codex/AGENTS.md`.
- Explicitly inserts: `Triggers on RLM requests like Implement requirement 'run-id' and phase-specific commands.`
- Refreshes the auto-generated installed skills section when `.codex/scripts/update-agents-skills.ps1` exists.
- Upserts full canonical RLM workflow content into `.agent/PLANS.md` from `references/plans-canonical.md` (skip with `-SkipPlansUpdate`).

## Read Order

1. Read `.codex/AGENTS.md` intro sections for local invocation conventions.
2. Read `.agent/PLANS.md` for canonical phase rules and requirements.
3. If AGENTS wording and PLANS wording differ, follow PLANS (AGENTS declares PLANS canonical) and note the mismatch in the current phase artifact when relevant.

## Trigger Examples

- `Implement requirement '2026-02-07-some-change'`
- `Run RLM Phase 3 for .codex/rlm/2026-02-07-some-change/`
- `Create .codex/rlm/<run-id>/02-to-be-plan.md with Coverage and Approval gates`
- `Update tests and lock Phase 5 artifact for this run`

## Invocation Mode

- Single-command mode:
  - On `Implement requirement '<run-id>'`, resolve run folder and execute phases sequentially.
  - Pause only for manual QA sign-off in Phase 6.
- Single-phase mode:
  - On `Run RLM Phase N`, execute only that phase and write only that phase outputs.

## Single-Command Contract (Mandatory)

- Resolve run folder at `.codex/rlm/<run-id>/`.
- If run folder or `00-requirements.md` is missing, stop and ask for it. Do not invent requirements.
- Auto-resume from current state:
  - If a phase artifact exists as `DRAFT` or with failing gates, resume that phase.
  - If a phase artifact is missing, create it for the next phase in sequence.
  - Never back-edit locked prior-phase artifacts.
- Execute in order: Phase 2 through Phase 8.
- For Phase 6:
  - Write `05-manual-qa.md` with scenarios in `DRAFT`.
  - Pause and request user results/sign-off.
  - On next invocation, record results, lock Phase 6, then continue to Phase 7 and 8.

## Run Folder and Artifacts

- Primary run path: `.codex/rlm/<run-id>/`
- Per-run artifacts:
  - `00-requirements.md`
  - `01-as-is.md`
  - `02-to-be-plan.md`
  - `03-implementation-summary.md`
  - `04-test-summary.md`
  - `05-manual-qa.md`
  - `addenda/`
- Global artifacts:
  - `.codex/DECISIONS.md`
  - `.codex/STATE.md`

## Phase Execution Protocol

1. Identify phase input base files from `.agent/PLANS.md`.
2. Expand each input to effective input: base file plus stage-local addenda in lexical order.
3. Read all effective inputs before drafting output.
4. Create/update the phase artifact with required header fields:
   - `Run`, `Phase`, `Status`, `Inputs`, `Outputs`, `Scope note`
5. Include a `Traceability` section mapping each `R#` to where it is addressed and evidenced.
6. End with `Coverage Gate` and `Approval Gate`, each concluding with explicit `PASS` or `FAIL`.
7. Keep `Status: DRAFT` until both gates pass.
8. On pass, lock artifact:
   - Set `Status: LOCKED`
   - Add `LockedAt` (ISO8601)
   - Add `LockHash` (SHA-256 of the file content)

Use `references/artifact-template.md` for exact header and gate scaffolding.

## Mandatory PLANS Sections to Enforce

Always enforce these sections from `.agent/PLANS.md` when applicable:

- `Large requirements: Implementation sub-phases (required when scope is large or risky)`
- `Playwright tagging for RLM runs and implementation sub-phases (required)`
- `Testing discipline (TDD + Playwright)` sections for Phase 3, 4, and 5
- `RLM single-command orchestration ("Implement requirement '<run-id>'")`
- `Run folder resolution`
- `Phase auto-resume and phase selection`
- `Manual QA stop (the only intentional pause)`
- `Locking rules for single-command execution`

## Immutability and Addenda

- Never edit a locked prior-phase artifact.
- If a gap is discovered in a locked upstream artifact, create an upstream-gap addendum in the current phase.
- Addendum naming:
  - Stage-local: `<base>.addendum-01.md`
  - Upstream-gap: `<current>.upstream-gap.<prior>.addendum-01.md`
- Lock all addenda created in the active phase when that phase locks.

## Phase Expectations

1. Phase 1 (`00-requirements.md`)
   - Define stable IDs `R1..Rn` and `OOS1..OOSn`.
   - Define observable acceptance criteria for each `R#`.
2. Phase 2 (`01-as-is.md`)
   - Provide novice-runnable repro, current behavior, code pointers, known unknowns.
3. Phase 3 (`02-to-be-plan.md`)
   - Produce ExecPlan-grade plan with concrete file edits, commands, tests, manual QA scenarios.
   - Add implementation sub-phases (`SP1`, `SP2`, ...) when scope/risk is large.
4. Phase 4 (`03-implementation-summary.md`)
   - Record what changed, where, and why.
5. Phase 5 (`04-test-summary.md`)
   - Record concrete validation commands, results, and requirement coverage.
6. Phase 6 (`05-manual-qa.md`)
   - Pause for user sign-off; record observed outcomes and explicit approval.
7. Phase 7 and 8
   - Update `.codex/DECISIONS.md`, then `.codex/STATE.md`.

## Manual QA Pause Rule

Pause only during Phase 6 for explicit user validation/sign-off. Do not pause for approval in other phases when gates can be evaluated mechanically.

## Operating Rules

- Keep prompts short and path-based; keep substantive requirements and plans in repo documents.
- Use deterministic, reproducible commands for implementation and validation.
- If required input is missing, create the minimal current-phase addendum; do not back-edit locked history.

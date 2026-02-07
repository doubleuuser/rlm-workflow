## Canonical location

This file is the canonical source of truth for how agents work in this repository.



## Scope

This file defines:

- ExecPlans: a single, self-contained, novice-guiding execution plan for complex work.
- RLM: a stage-gated, repo-document workflow that prevents “context rot” by making static repo documents the source of truth across phases, with explicit coverage and approval gates.

# RLM: Repo-Document Workflow (Recursive Language Model discipline)

RLM is an extension of ExecPlans designed to prevent “context rot.” In RLM, substantive requirements and plans must live in static repository documents. Prompts must not carry requirements or plans; prompts only instruct an agent which RLM phase to execute and which repo file(s) to use as inputs and outputs.

RLM is recommended for: multi-step debugging, platform-specific behavior, risky refactors, migrations, or any change where an AS-IS analysis, explicit validation, and manual QA sign-off are necessary.

## Non-negotiable RLM rules

1) Repo documents are the source of truth.

At the start of each phase, the agent must read the phase input document(s) from disk (including applicable addenda; see Addenda policy below) and treat them as authoritative. Conversational context may be used only to issue commands (“run Phase 3 using these file paths”), not to carry requirements.

2) Prompts are commands, not specifications.

Do not paste substantive requirements, acceptance criteria, test cases, or implementation plans into prompts. Place them in repo documents, then reference paths in the prompt.

3) One-way phases.

Within a phase, the agent may iterate on that phase’s outputs until gates pass. After advancing to the next phase, the agent must not edit prior-phase artifacts. If a later phase discovers missing or incorrect information in an earlier phase, use an addendum in the current phase (see Addenda policy).

4) Explicit gates are mandatory.

Every phase output must end with:
- Coverage Gate: prove the output doc addresses everything relevant in the input doc (including input addenda).
- Approval Gate: prove the output is ready to proceed.

Manual QA approval requires explicit user sign-off recorded in the Manual QA artifact.

## Global artifacts (across all RLM runs)

RLM uses two global documents shared by all requirements:

- `/.codex/DECISIONS.md` — a global decision ledger and index of all completed (or aborted) runs. Each entry must reference the run folder and capture what changed and why.
- `/.codex/STATE.md` — a global “current state of the app” document. It must reflect what is true now, not what was intended.

These two files are updated in later phases (see Phase 7 and Phase 8).

## RLM run directory layout (per requirement)

Each RLM run uses a stable folder:

`/.codex/rlm/<run-id>/`

Required per-run artifacts:

- `00-requirements.md`
- `01-as-is.md`
- `02-to-be-plan.md`
- `03-implementation-summary.md`
- `04-test-summary.md`
- `05-manual-qa.md`
- `addenda/` (see Addenda policy)

The run folder is the durable record for the requirement. It must be sufficient to understand and reproduce work without relying on chat logs.

## RLM phases

RLM phases are stage-gated. The next phase uses the previous phase’s output as input.

Phase 1 — Requirements
- Input: chat discussion outside the repo documents
- Output: `/.codex/rlm/<run-id>/00-requirements.md`

Phase 2 — AS-IS analysis
- Input: `00-requirements.md` (plus addenda)
- Output: `01-as-is.md`

Phase 3 — TO-BE plan (ExecPlan-grade)
- Input: `01-as-is.md` (plus addenda) and by reference `00-requirements.md`
- Output: `02-to-be-plan.md`
- This phase output is the execution plan and must follow the ExecPlan requirements in this file.

Phase 4 — Implementation
- Input: `02-to-be-plan.md` (plus addenda)
- Output: `03-implementation-summary.md`

Phase 5 — Tests and validation
- Input: `02-to-be-plan.md` and `03-implementation-summary.md` (plus addenda)
- Output: `04-test-summary.md`

Phase 6 — Manual QA (user sign-off)
- Input: QA scenarios defined in `02-to-be-plan.md` (plus addenda) and the implemented system
- Output: `05-manual-qa.md` (completed with observed results and user approval)

Phase 7 — Global DECISIONS update
- Input: all run artifacts (including addenda)
- Output: update/append `/.codex/DECISIONS.md` with a new run entry that references the run folder docs

Phase 8 — Global STATE update
- Input: the run’s DECISIONS entry
- Output: update `/.codex/STATE.md` to reflect the current state after the change

## RLM prompt contract (how users should invoke phases)

RLM prompts must be concise and path-based. A good prompt:
- names the phase,
- names the input file path(s),
- names the required output file path(s),
- instructs the agent to enforce Coverage and Approval gates,
- avoids pasting substantive content.

Example prompt pattern:

“Run RLM Phase 3. Input: `/.codex/rlm/<run-id>/01-as-is.md` (and addenda). Output: `/.codex/rlm/<run-id>/02-to-be-plan.md` as an ExecPlan per `/.codex/PLANS.md`. Enforce Coverage and Approval gates. Do not paste requirements into the prompt; only reference repo files.”

## Required structure for every RLM phase artifact (headers + gates)

Every per-run RLM artifact (`00-requirements.md` through `05-manual-qa.md`, plus any addendum files) must begin with a short header and must end with Coverage and Approval gates.

### Required header fields (top of file)

Each artifact must start with the following fields in plain markdown:

- Run: `/.codex/rlm/<run-id>/`
- Phase: `01 AS-IS` (or the relevant phase number/name)
- Status: `DRAFT` or `LOCKED`
- Inputs: list repo-relative paths read to produce this artifact (include addenda when applicable)
- Outputs: list repo-relative paths written by this phase (usually this file, sometimes additional files)
- Scope note: one short paragraph stating what this artifact is intended to decide/enable

Example header:

Run: `/.codex/rlm/2026-01-07-example/`
Phase: `02 TO-BE plan`
Status: `DRAFT`
Inputs:
- `/.codex/rlm/2026-01-07-example/01-as-is.md`
- `/.codex/rlm/2026-01-07-example/addenda/01-as-is.addendum-01.md`
Outputs:
- `/.codex/rlm/2026-01-07-example/02-to-be-plan.md`
Scope note: This document defines the planned changes and how to validate them.

When Status is `LOCKED`, append these fields to the header:

- LockedAt: ISO8601 timestamp
- LockHash: SHA-256 of the file content at lock time (excluding any later filesystem metadata)

### Required gate sections (end of file)

Every artifact must end with these two sections:

#### Coverage Gate

State whether the artifact covers everything relevant in the phase input docs. Coverage must be proven mechanically via requirement IDs:

- Phase 1 establishes stable requirement IDs (R1, R2, …) and Out of Scope IDs (OOS1, OOS2, …).
- Downstream artifacts must map each requirement ID to where it is addressed in that artifact and/or where evidence exists.
- If a requirement is intentionally deferred, say so explicitly and record the rationale.

The Coverage Gate must conclude with one of:

- Coverage: PASS
- Coverage: FAIL (and list what is missing and how it will be added before proceeding)

#### Approval Gate

State whether the artifact is ready to proceed to the next phase. The Approval Gate must be objective wherever possible (repro is unambiguous, plan includes runnable commands, tests pass, etc.).

Manual QA is the exception: Phase 6 requires explicit user sign-off, recorded in the Manual QA artifact.

The Approval Gate must conclude with one of:

- Approval: PASS
- Approval: FAIL (and list what must change before proceeding)

## Locking and immutability (phase advancement rules)

RLM phases are one-way. Iteration is allowed within a phase, but after a phase advances, earlier artifacts must not be edited.

### DRAFT vs LOCKED

- While a phase is in progress, its output artifact status is `DRAFT`. The agent may revise it until both gates pass.
- When both gates pass, the agent must:
  1) set Status to `LOCKED`,
  2) set `LockedAt`,
  3) compute `LockHash` (SHA-256),
  4) then proceed to the next phase.

After an artifact is `LOCKED`, it must not be edited. If something is later discovered to be missing or wrong, use an addendum in the current phase (see Addenda policy).

### No backtracking rule

If the agent is in Phase N, it must not modify artifacts from Phase < N. If a Phase < N artifact is incomplete or incorrect, the agent must record the gap via a current-phase upstream-gap addendum and proceed forward without editing the locked earlier artifact.

### How to compute LockHash

When locking an artifact, compute the SHA-256 hash from the repo root. For example:

    sha256sum /.codex/rlm/<run-id>/01-as-is.md

Record the resulting hex digest as `LockHash`.

## Addenda (mandatory)

Addenda are used to preserve immutability while allowing discovery, and to ensure “effective input” is not lost to context rot.

All addenda live under:

`/.codex/rlm/<run-id>/addenda/`

### Stage-local addenda (same stage)

Stage-local addenda supplement a stage artifact without requiring destructive edits.

Naming:

- `<base-filename>.addendum-01.md`
- `<base-filename>.addendum-02.md`
- … and so on

Examples:

- `01-as-is.addendum-01.md`
- `02-to-be-plan.addendum-01.md`

### Upstream-gap addenda (current stage records a gap in a locked earlier stage)

If, in Phase N, the agent discovers missing or incorrect information in a LOCKED Phase < N artifact, the agent must not edit the earlier artifact. Instead it must create a current-phase upstream-gap addendum.

Naming:

`<current-base>.upstream-gap.<prior-base>.addendum-01.md`

Examples (while in Phase 04, discovering a gap in Phase 02):

- `04-test-summary.upstream-gap.02-to-be-plan.addendum-01.md`

The upstream-gap addendum must:
- state the gap,
- explain how it was discovered (evidence),
- state the implications for the current and later phases,
- state how the current phase compensates (tests added, plan deviation recorded, etc.).

### Mandatory “effective input” read rule

When a phase declares an input artifact (for example `01-as-is.md`), the agent must treat the effective input as:

- the base file, plus
- all matching stage-local addenda in lexical order.

The agent must explicitly list all input addenda in the output artifact’s header under Inputs.

### Addenda locking

Addenda follow the same DRAFT/LOCKED rule:
- If an addendum is created during an active phase, it is `DRAFT` until the phase locks.
- When the phase locks, any stage-local addenda and upstream-gap addenda created in that phase must be locked as well.

## Requirement IDs and traceability (mandatory for Coverage Gate)

RLM coverage must be mechanical. The Phase 1 requirements document must define stable IDs and acceptance criteria.

### Requirements document requirements (Phase 1)

`00-requirements.md` must include:

- Requirement IDs: R1, R2, …
- Out of Scope IDs: OOS1, OOS2, …
- Observable acceptance criteria for each R# (what a human can do/see)
- Constraints (if any) that are non-negotiable

### Downstream traceability rule

Every downstream artifact must include a short “Traceability” section that maps each R# to where it is addressed and what evidence exists.

- In analysis and plan phases, evidence may be code pointers, planned tests, and described verification steps.
- In implementation and validation phases, evidence should be concrete: file paths, diffs, logs, test results, and runtime observations.

If a requirement is deferred, it must be explicitly marked as deferred with rationale and its impact on acceptance.

## Formatting exception for Manual QA

This document prefers prose-first writing and discourages tables. Manual QA is the exception.

The Phase 6 Manual QA artifact (`05-manual-qa.md`) may use a compact table to present scenarios, expected outcomes, and observed outcomes if it materially improves clarity. Keep it small and focused.

## Minimum content expectations by RLM phase

These are minimum expectations. Each artifact must still include the required header and gate sections.

Phase 1 — `00-requirements.md`
- Stable requirement IDs (R1…)
- Out of scope IDs (OOS1…)
- Acceptance criteria per R#
- Constraints and assumptions
- Traceability is not required here, but must be enabled by the IDs

Phase 2 — `01-as-is.md`
- Repro steps (novice-runnable)
- Current behavior description tied to requirement IDs
- Relevant code pointers by full path (files, functions/modules)
- Known unknowns (explicit)
- Evidence snippets where possible (logs, screenshots described, etc.)

Phase 3 — `02-to-be-plan.md` (ExecPlan-grade)
- Must comply with all ExecPlan requirements in this file
- Must include:
  - concrete edits by file path and location
  - commands to run
  - tests to add/run
  - manual QA scenarios
  - idempotence/recovery guidance
- Must include traceability mapping R# → planned change + validation

## Large requirements: Implementation sub-phases (required when scope is large or risky)

Some requirements are too large or risky to implement safely as a single “Phase 4 then Phase 5” blob. In these cases, the work must be decomposed into ordered sub-phases. Each sub-phase has its own implementation steps, an implementation checklist, and an explicit set of tests that must be run and pass before proceeding.

This is not a new top-level RLM phase. Sub-phases are a required structure inside Phase 3 planning and Phase 4/5 execution.

### When sub-phases are mandatory

Use sub-phases when any of the following are true:

- The change touches multiple subsystems (UI + state + persistence + backend, etc.).
- The change is expected to take more than one focused development session.
- The risk of regressions is non-trivial (touches critical flows, input handling, playback, persistence, auth, payments, etc.).
- The requirement includes multiple user-visible behaviors that can be delivered incrementally.

If sub-phases are not used for a large change, the Phase 3 Approval Gate must be FAIL unless the plan explicitly justifies why a single pass is safe.

### Where sub-phases live (Phase 3: `02-to-be-plan.md`)

When sub-phases are used, `02-to-be-plan.md` must include a section titled:

“Implementation Sub-phases”

Under it, define sub-phases as `SP1`, `SP2`, … in order. Each sub-phase must include:

1) Scope and purpose
- A short paragraph describing what will exist at the end of the sub-phase that does not exist before.
- Explicit mapping to requirement IDs (R#) covered by this sub-phase.

2) Implementation checklist (mandatory)
- A checkbox list of concrete edits/steps. This is allowed even if other narrative sections remain prose-first.
- Checklist items must name file paths and functions/modules where applicable.

3) Tests for this sub-phase (mandatory)
- A concrete list of tests to run before the sub-phase is considered complete.
- Include exact commands (repo-specific).
- Include Playwright scope rules:
  - Prefer a fast Tier A run for the sub-phase (new/changed tests + `@smoke` if applicable).
  - Specify any tags to use (e.g., `@rlm:<run-id>`, `@smoke`).
- State pass criteria (what “green” means).

4) Sub-phase acceptance (mandatory)
- Observable behavior a human can verify for this increment (even if the requirement is not fully complete yet).
- Any temporary limitations or feature flags must be stated explicitly.

5) Rollback / recovery notes (when relevant)
- If the sub-phase can leave the repo in a partially migrated state, describe how to recover.

Phase 3 Approval Gate must be FAIL unless sub-phases (when required) include checklists and test commands as described above.

### Execution rule (Phase 4 + Phase 5 are performed per sub-phase)

When implementing a plan with sub-phases, the agent must execute sub-phases sequentially:

For each sub-phase SPk:

1) Implement SPk according to the plan checklist.
2) Run the SPk test set exactly as specified in the plan.
3) If any SPk tests fail:
   - Do not proceed to the next sub-phase.
   - Iterate on implementation (and tests, if the plan requires test additions) until SPk tests pass.
4) Only after SPk tests pass may the agent proceed to SP(k+1).

This rule is non-negotiable. The agent must not “finish implementation first and test later” when sub-phases are defined.

### How to record progress and evidence (Phase 4 and Phase 5 artifacts)

Phase 4 output (`03-implementation-summary.md`) must include a section:

“Sub-phase Implementation Summary”

For each SPk, record:
- files touched (paths),
- key behavior changes,
- any deviations from the Phase 3 plan (with rationale and evidence pointers).

Phase 5 output (`04-test-summary.md`) must be organized by sub-phase when sub-phases exist:

- SP1: commands executed + results + artifact paths
- SP2: commands executed + results + artifact paths
- …

The Phase 5 Approval Gate must be FAIL unless every sub-phase’s required tests have been executed and are passing (or an explicit decision with mitigation is recorded, and the requirement’s constraints allow it).

### Plan amendments during implementation (without editing locked Phase 3)

Phase 3 artifacts are locked before Phase 4 begins. If, during Phase 4/5, the agent discovers that the locked plan is missing steps, missing tests, incorrect assumptions, or requires sequencing changes, the agent must not edit the locked `02-to-be-plan.md`.

Instead, the agent must create a current-phase upstream-gap addendum that functions as a “plan amendment” for the remaining work.

- Addendum location: `/rlm/<run-id>/addenda/`
- Naming (examples):
  - `03-implementation-summary.upstream-gap.02-to-be-plan.addendum-01.md`
  - `04-test-summary.upstream-gap.02-to-be-plan.addendum-01.md`

Each plan-amendment addendum must:
- state what in the plan was missing/incorrect,
- provide evidence for why the amendment is needed,
- specify the amended steps/tests for the remaining sub-phases,
- state the impact on traceability (which R# are affected),
- and be treated as part of the effective plan input for the remainder of the run.

When plan amendments exist, subsequent sub-phases must follow the effective plan (base plan + relevant amendment addenda).

## Playwright tagging for RLM runs and implementation sub-phases (required)

When RLM uses implementation sub-phases (SP1, SP2, …), Playwright tests must be taggable so the agent can run fast, targeted Tier A validations per sub-phase and broader Tier B regressions at appropriate points.

### Required tags

All Playwright tests added or modified as part of an RLM run must include the run tag:

- `@rlm:<run-id>`

When sub-phases exist, tests must also be tagged with the sub-phase tag:

- `@sp1`, `@sp2`, … corresponding to the sub-phase that introduced or modified the test

If the repository maintains a smoke tier, critical-path guardrail tests must also be tagged:

- `@smoke`

These tags may be applied at the `test.describe()` level or on individual tests, but they must be queryable via Playwright’s `--grep` or equivalent mechanism used by the repository.

### Tagging examples (informative)

A test introduced in SP2 of run `01-example` should be discoverable by grepping for:

- `@rlm:01-example` and `@sp2`

A smoke guardrail test relevant to the run should be discoverable by:

- `@smoke` (and optionally also `@rlm:<run-id>` if it was changed in the run)

### Tier A / Tier B command requirements (must be specified in the plan)

When sub-phases exist, the TO-BE plan (`02-to-be-plan.md`) must specify Playwright commands for:

Tier A (per sub-phase, fast loop)

- Run the tests introduced/modified in the current sub-phase:
  - `@rlm:<run-id>` + `@spK`
- Plus any required smoke guardrails for affected flows:
  - `@smoke` (optionally scoped further if the repo supports it)

Tier B (broader regression)

- Run all tests for the run:
  - `@rlm:<run-id>` (all sub-phases)
- Optionally run the full suite, or all `@smoke`, or broader tags as required by constraints.

The plan must record the exact repo-specific commands (package manager, scripts, env vars) rather than generic placeholders.

### Execution rule (non-negotiable)

For each sub-phase SPk:

- The agent must run Tier A for SPk and require it to be green before starting SP(k+1).
- If Tier A fails, fix and rerun until green. Do not proceed.
- Tier B must be run before locking Phase 5 unless an explicit constraint in `00-requirements.md` allows a narrower run.

### Test summary rule (Phase 5)

When sub-phases exist, the test summary (`04-test-summary.md`) must record Playwright results by sub-phase:

- SPk Tier A command(s) + results + artifact paths
- Any Tier B run(s) + results + artifact paths

If a failure is flaky, the summary must record the rerun commands and outcomes, and the mitigation applied.

## Playwright test placement and naming conventions (required)

To keep RLM runs discoverable, reviewable, and fast to validate per sub-phase, Playwright tests must follow a consistent placement and naming convention.

### Respect existing repository conventions first (non-negotiable)

Before creating new Playwright tests or moving existing ones, the agent must determine the repository’s current Playwright layout by inspecting:

- Playwright config (e.g., `playwright.config.ts` / `.js`) for `testDir`, and
- package scripts that run Playwright (e.g., `package.json` scripts).

If the repo already has an established Playwright test directory and naming pattern, new tests must follow it. Do not introduce a second Playwright test tree.

If the repository does not have an established Playwright test directory, the agent may create one, but must record the decision and rationale in the Decision Log and keep the structure minimal.

### Standard test directory selection rule

When the repository already has a Playwright `testDir`, use it as the canonical location for new tests.

If `testDir` is not set and no obvious convention exists, use one of the following defaults (in this priority order), choosing the first that matches existing patterns in the repo:

1) `tests/e2e/`
2) `e2e/`
3) `playwright/tests/`

The Phase 3 plan must record the chosen directory path(s) explicitly.

### File naming (required)

Each new Playwright test file added for an RLM run must include the run id and the sub-phase, and should be readable in file listings without opening the file.

Required format (kebab-case, TypeScript example):

- `rlm-<run-id>.sp<k>.<short-topic>.spec.ts`

Examples:

- `rlm-01-keyboard-controls-in-deck-settings.sp1.shortcut-discovery.spec.ts`
- `rlm-01-keyboard-controls-in-deck-settings.sp2.persistence-guardrail.spec.ts`

If the repo uses a different extension or suffix (e.g., `.test.ts`), match the repo convention, but keep the `rlm-<run-id>.sp<k>.` prefix.

### Test title and tag placement (required)

Tests must include tags in a way that is grep-able via the repo’s chosen Playwright filtering mechanism (typically `--grep`).

Preferred pattern (apply tags at the `test.describe()` level):

- `test.describe('@rlm:<run-id> @sp<k> <topic>', () => { ... })`

If a test is part of a smoke tier, include `@smoke` in the same describe title:

- `test.describe('@smoke @rlm:<run-id> @sp<k> <topic>', () => { ... })`

Do not rely on brittle text selectors in tests. Prefer stable selectors (`data-testid` or equivalent). If the repo does not use stable selectors today, the plan may introduce `data-testid` additions as part of the requirement, and must record them as part of the implementation checklist.

### Requirement traceability inside tests (required)

At the top of each new Playwright test file, include a short comment block that ties the test back to the requirement IDs it covers.

Example:

- `// RLM run: <run-id>`
- `// Sub-phase: SP<k>`
- `// Covers: R1, R3`
- `// Guardrails: (if any) R2 (non-regression)`

This comment is not a substitute for the Traceability section in the RLM artifacts, but it makes tests easier to audit during review.

### Fixtures and test data placement (recommended; required if new fixtures are added)

If tests require fixtures, seed data, or static assets, prefer colocating them under a dedicated folder near the test directory to avoid scattering run-specific artifacts across the repo.

Recommended pattern (adapt to repo conventions):

- `<playwright-test-dir>/fixtures/rlm/<run-id>/...`

If the repo already has a fixtures convention, follow it. Any new fixtures directories must be recorded in the Phase 3 plan and listed in Phase 4’s touched files.

### Tier A discovery rule (required)

Tier A for a sub-phase must be able to target the sub-phase tests without manual selection. Therefore, either:

- tags must be present and filterable (preferred), or
- the plan must specify an equivalent deterministic selection mechanism used by the repo.

If the repo’s Playwright setup cannot reliably filter by tags, the Phase 3 plan must define an alternative (for example, file glob patterns that correspond to `rlm-<run-id>.sp<k>.*`), and must use that alternative consistently throughout Phase 4/5 execution and reporting.


### Testing discipline (TDD + Playwright) — Phase 3 (TO-BE plan) must include a “Testing Strategy” section that specifies:

- New behavior tests to add (required for features).
- Regression-first tests that fail on current behavior (required for bug fixes).
- Non-regression guardrail tests for adjacent critical behavior (required whenever existing flows may be impacted).
- Exact test file paths and exact commands to run.
- Expected pass criteria.

Phase 4 — `03-implementation-summary.md`
- Files touched (repo-relative paths)
- What changed and why
- Traceability mapping R# → implementation evidence

### Testing discipline (TDD + Playwright) — Phase 4 (Implementation) must begin with tests-first:

- Bug fixes: add a failing regression test first, then implement until it passes.
- Features: add tests for the new behavior first (may fail initially), then implement until they pass.

Phase 5 — `04-test-summary.md`
- Tests executed (commands)
- Results (pass/fail) with concise evidence
- If any required test is failing, the phase must not advance until fixed or explicitly decided with rationale and mitigation recorded

### Testing discipline (TDD + Playwright) — Phase 5 (Tests/validation) must run:

- Tier A: the new/modified tests for this run plus relevant smoke tests.
- Tier B: the full Playwright suite (or a broader tagged set) before locking the phase, unless an explicit constraint in `00-requirements.md` permits a narrower run.

If Playwright coverage is infeasible or would be flaky for a specific behavior, the plan must explicitly record the exception and mitigation in the Approval Gate (e.g., unit test coverage + manual QA scenario).

### Playwright evidence capture and `04-test-summary.md` standard (required)

Playwright is the primary end-to-end regression safety net in this repository. To prevent regressions and make failures diagnosable, RLM must standardize what is recorded in the Phase 5 artifact (`04-test-summary.md`) and how Playwright evidence is captured.

This section defines requirements for:

- Phase 3: the TO-BE plan must specify Playwright tests, tags, and how to run them.
- Phase 5: the test summary must capture exact commands, results, and where to find debugging artifacts.

#### Phase 3 requirements (plan must define this up front)

The ExecPlan-grade TO-BE plan (`02-to-be-plan.md`) must include a “Playwright Plan” subsection that specifies:

1) Which Playwright tests will be added or modified (file paths) and the intent of each test.
2) Tagging strategy for this run:
   - Tests added for the run must be tagged with `@rlm:<run-id>`.
   - If the repository uses a smoke tier, critical-path tests must also be tagged `@smoke`.
3) Exact commands to run Tier A (fast loop) and Tier B (broader regression), as they apply to this repo’s toolchain.
4) How the app is started for E2E (or how requests are stubbed):
   - If a dev server is required, specify the exact start command, base URL, and readiness condition.
   - If stubbing network calls is required, specify what is stubbed and why.
5) Selector strategy: E2E tests must target stable selectors (prefer `data-testid` or equivalent), not brittle text selectors, unless explicitly justified.

The Phase 3 Approval Gate must be FAIL if the plan does not specify the above items with concrete, repo-specific details.

#### Phase 5 output requirements (`04-test-summary.md` must include these sections)

The Phase 5 artifact (`04-test-summary.md`) must be self-sufficient for diagnosing failures. It must contain the following sections in order.

1) Environment

Record enough environment detail to reproduce:

- Repo root (path) and run id
- Platform (OS) and Node/runtime version
- Playwright version
- Browser projects executed (e.g., chromium/firefox/webkit) and whether headed/headless
- Base URL used (if applicable)

2) Commands executed (exact)

List the exact commands actually executed (copy/paste exact shell lines), including:

- Any build commands
- Any dev server start command (and whether it ran in a separate terminal/process)
- Tier A Playwright command(s) executed
- Tier B Playwright command(s) executed (if required by the run’s constraints)

If the repo uses scripts (e.g., `test:e2e`), record the script and the underlying Playwright invocation if available.

3) Results summary

Provide a compact pass/fail summary:

- Total tests run, passed, failed, skipped
- If failures occurred: list failing test titles and file paths
- Whether failures are deterministic or flaky (based on reruns described below)

4) Debugging artifacts (mandatory to locate)

The summary must state exactly where artifacts were written in this repo and how to open them.

At minimum, record paths for:

- Playwright HTML report directory (e.g., `playwright-report/`)
- Test results directory (e.g., `test-results/`)
- Trace files (if generated)
- Screenshots (if generated)
- Videos (if generated)

If the repository uses a custom Playwright config, explicitly cite the config file path that defines these output locations (e.g., `playwright.config.ts`).

5) Failure diagnosis notes (required when failures exist)

For each failing test:

- Failure symptom in one sentence (what did not happen)
- Primary suspected root cause (if known)
- The most relevant artifact to inspect (report/trace/screenshot/video path)
- Any immediate remediation step taken

6) Rerun policy and flake handling (required)

To prevent “green by accident,” Phase 5 must follow this policy:

- On any Playwright failure, rerun the failing test(s) in isolation at least once.
- If the failure disappears on rerun, treat it as a potential flake and record:
  - how it was rerun,
  - whether it reproduced,
  - and what mitigation was applied (e.g., improved selector, proper waiting condition, deterministic state setup).

Do not mark Approval PASS if there are unresolved, newly introduced flakes without an explicit decision and mitigation.

#### Evidence capture policy (how Playwright should be configured/used for RLM)

Playwright evidence must be sufficient to debug without guesswork.

- Prefer to have traces available for failures. If traces are not always-on, ensure they are captured on the first retry for failures (or equivalent policy supported by the repo).
- Screenshots on failure are strongly recommended.
- Videos on failure are recommended for interaction-heavy flows.

If the repo’s Playwright configuration does not currently produce these artifacts, the plan may introduce minimal, non-invasive configuration changes to enable them (without changing product behavior). Such changes must be recorded in the Decision Log and reflected in the test summary.

#### Phase 5 Approval Gate requirements

Phase 5 Approval must be FAIL unless:

- The tests specified in the plan for Tier A have been run and are passing, or failures have been resolved.
- Any required Tier B run (as specified in the plan or constraints) has been completed and is passing, or an explicit decision with mitigation is recorded.
- The test summary contains the required sections above and points to concrete artifact paths for any failures that occurred during the phase.

Phase 6 — `05-manual-qa.md`
- Manual QA scenarios (from plan) and observed results
- Explicit user sign-off (name/handle + date + notes)
- If user does not approve, iterate within this phase until approved or record an explicit abort decision

Phase 7 — update `/.codex/DECISIONS.md`
- Append a new entry referencing:
  - the run folder path
  - all run artifacts (including addenda)
  - what changed (user-visible behavior)
  - why (tradeoffs)
  - how (high-level approach)
  - what was not done (OOS)
  - known issues / follow-ups

Phase 8 — update `/.codex/STATE.md`
- Update current-state documentation to reflect the new reality:
  - features and flags/config
  - known limitations
  - operational notes

## RLM single-command orchestration ("Implement requirement '<run-id>'")

RLM must be operable via a single short prompt. When the user says:

- Implement requirement '<run-id>'

…the agent must execute the RLM workflow end-to-end by reading repo documents, generating missing phase artifacts, enforcing gates, locking artifacts, and updating global documents, without requiring the user to provide long prompts.

### Run folder resolution

Given `<run-id>`, the agent must locate the run folder at:

- `/rlm/<run-id>/`

A valid run folder must contain at minimum:

- `/rlm/<run-id>/00-requirements.md`

If the run folder or `00-requirements.md` does not exist, the agent must stop and instruct the user to create it (the agent must not invent requirements).

### Phase auto-resume and phase selection

The single-command orchestrator must be idempotent and resumable. On every invocation of “Implement requirement '<run-id>'” the agent must:

1) Determine the current phase by inspecting which phase outputs exist and whether they are LOCKED.
2) If a phase output exists but is DRAFT (or gates are FAIL), resume that phase and iterate until PASS and then lock.
3) If a phase output does not exist, start that phase by creating its output artifact (and addenda if needed).
4) Never edit artifacts from earlier phases once they are LOCKED. If an earlier phase is missing something, use the Addenda policy (below) to record the gap in the current phase.

The orchestrator proceeds in order:

Phase 2: create/lock `01-as-is.md`  
Phase 3: create/lock `02-to-be-plan.md` (ExecPlan-grade)  
Phase 4: implement and create/lock `03-implementation-summary.md`  
Phase 5: run tests and create/lock `04-test-summary.md`  
Phase 6: create `05-manual-qa.md` and obtain user sign-off; then lock it  
Phase 7: update global `/.codex/DECISIONS.md`  
Phase 8: update global `/.codex/STATE.md`

### Mandatory “effective input” rule (base + addenda)

Whenever the orchestrator reads a phase input artifact, it must treat the effective input as:

- the base artifact, plus
- all matching stage-local addenda in `/rlm/<run-id>/addenda/` in lexical order.

The orchestrator must list all effective inputs in the header of each output artifact under Inputs.

### Mandatory gates

For each phase artifact created or updated, the orchestrator must enforce:

- Coverage Gate: PASS only if the output covers everything relevant in the effective inputs (including addenda), proven via Requirement IDs (R1, R2, …).
- Approval Gate: PASS only if phase readiness criteria are met.

If either gate is FAIL, the orchestrator must iterate within the same phase until both are PASS, then lock and proceed.

### Manual QA stop (the only intentional pause)

Phase 6 requires explicit user sign-off recorded in `05-manual-qa.md`.

Therefore, when the orchestrator reaches Phase 6, it must:

1) Ensure the plan’s QA scenarios are present (from `02-to-be-plan.md` effective content). If missing, create a Phase 6 upstream-gap addendum and include the missing scenarios in `05-manual-qa.md`.
2) Ask the user to execute the manual QA scenarios and report results.
3) Stop after writing `05-manual-qa.md` in DRAFT with the scenarios.

On the next invocation of “Implement requirement '<run-id>'”, if the user has provided QA results, the agent must record them into `05-manual-qa.md`, pass gates, lock Phase 6, and proceed to Phase 7 and Phase 8.

### Locking rules for single-command execution

Within a phase, the agent may iterate on that phase’s output artifact and create phase-local addenda. Once both gates are PASS for a phase, the agent must set Status to LOCKED and record LockedAt and LockHash.

After locking a phase, the orchestrator must not edit that phase’s base artifact or its stage-local addenda.

### Addenda integration for single-command execution

If the orchestrator discovers missing or incorrect information in a LOCKED earlier phase, it must not modify that earlier phase. It must create an upstream-gap addendum in the current phase (as defined in the Addenda section) and proceed forward using the current phase’s addendum to compensate.

## RLM operator contract (what the user does)

To start an RLM run:

1) Create `/rlm/<run-id>/00-requirements.md` and ensure it contains requirement IDs (R1, R2, …) and acceptance criteria.
2) Invoke: Implement requirement '<run-id>'

To continue after Manual QA:

1) Run the requested QA scenarios.
2) Provide results in chat (pass/fail notes per scenario).
3) Invoke again: Implement requirement '<run-id>'

<!-- RLM-WORKFLOW-SKILL:START -->
## RLM Skill Integration

The rlm-workflow skill operationalizes this document's RLM rules during execution.
Use it for RLM-triggered prompts such as Implement requirement 'run-id' and phase-specific commands.
<!-- RLM-WORKFLOW-SKILL:END -->

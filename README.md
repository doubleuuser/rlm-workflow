# RLM Workflow

A multi-platform Recursive Language Models (RLM) workflow for AI-assisted software development with strict phase gates, TDD discipline, and systematic debugging.

Distributed as Agent Skills; install via Skills CLI (works across supported agents).

## Installation

### Skills CLI (Recommended)

```bash
# Interactive install
npx skills add doubleuuser/rlm-workflow
```

**NOTE:** This repo contains a root skill (`rlm-workflow`) plus additional subskills under `skills/*`.
To list and install the full set from the repo root, use `--full-depth`.

#### List skills

```bash
# List the root skill only
npx skills add doubleuuser/rlm-workflow --list

# List ALL skills in the repo (root + subskills)
npx skills add doubleuuser/rlm-workflow --list --full-depth
```

#### Install skills

```bash
# Install all skills (root + subskills)
npx skills add doubleuuser/rlm-workflow --skill '*' --full-depth

# Global install (available everywhere)
npx skills add doubleuuser/rlm-workflow --skill '*' --full-depth -g -y

# Install a single subskill
# Option A (repo path):
npx skills add doubleuuser/rlm-workflow/skills/rlm-tdd
# Option B (explicit skill selection):
npx skills add doubleuuser/rlm-workflow --skill rlm-tdd --full-depth
```

### Bootstrap

After installation, the skill auto-bootstraps on first invocation. To manually bootstrap:

```bash
# Windows PowerShell:
powershell -ExecutionPolicy Bypass -File "<SKILL_DIR>/scripts/install-rlm-workflow.ps1" -RepoRoot .

# PowerShell 7+ (pwsh):
pwsh -NoProfile -File "<SKILL_DIR>/scripts/install-rlm-workflow.ps1" -RepoRoot .
```

Find the installed location via `npx skills list` (or use project-local install so `<SKILL_DIR>` is under `.agents/skills/...`).

## 1. Introduction to RLM-workflow

`rlm-workflow` is a multi-platform skill/plugin for running the repository's RLM (Recursive Language Models) workflow with strict phase gates, traceability, locking, and addenda rules.

rlm-workflow is inspired by the MIT paper 'Recursive Language Models'. While the paper reports increased performance, reduced context rot and an effective context window of 10 million tokens by using agents, agents are a sidetrack. The core finding is that important information such as requirements, implementation plans and current codebase analysis must NOT be part of the agent context but stored in static files. 

rlm-workflow uses a standard kanban-workflow with distinct phases like requirements, codebase analysis, implementation plan, implementation summary, verification, manual QA of implementation, and then updating of global repo artifacts (STATE.md and DECISIONS.md) to document the codebase.

## 2. Why use it

- It keeps requirements and plans in repo files instead of chat context.
- It enforces deterministic phase outputs with explicit `Coverage Gate` and `Approval Gate`.
- It supports resumable, single-command execution for complex multi-phase work.
- It reduces regressions by requiring validation and manual QA sign-off flow.
- It increases effective context windows, multi-step run accuracy, by preventing context rot and requirement drift.
- It **isolates development** via git worktrees, preventing main branch pollution.
- It **protects the main branch** by requiring explicit consent to work directly on it.
- All historical implementations, including Why, What and How, can easily be audited in the .codex/rlm/ folder where each requirement has its own folder with locked artifacts per phase.

### Key Features

**Quality & Discipline**
- **TDD Discipline** - Strict RED-GREEN-REFACTOR cycle with The Iron Law: *No production code without a failing test first*
- **Systematic Debugging** - Optional Phase 1.5 debug mode for bug fixes with 4-phase root cause analysis
- **TODO Discipline** - Mandatory checkable TODOs in every phase artifact; no locking with unchecked items
- **Rationalization Awareness** - Common excuse/reality tables to prevent corner-cutting

**Execution & Scaling**
- **Subagent-Driven Execution** - Automatic parallel execution with fallback to sequential mode
- **Phase 3.5 Code Review** - Optional subagent review between implementation and testing
- **Parallel Testing** - Concurrent test execution (unit, integration, E2E)

**Safety & Control**
- **Git Worktree Isolation** - Isolated workspace setup (REQUIRED before other phases)
- **Branch Protection** - Prevents main branch work without explicit consent
- **Lock Verification** - Automated SHA-256 lock hash validation (normalized artifact content; see below)
- **Hard Gates** - Non-negotiable checkpoints marked with `<HG>` tags prevent skipping steps

## 3. How to use it

1. Install with:
   - `npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow`
2. Create a run folder and Phase 0 Requirements artifact:
   - Path: `.codex/rlm/<run-id>/00-requirements.md`
   - Example: I create the folder for my first requirements as: /rlm/00-my-first-requirements
   - I then create the requirements doc inside the same folder: /00-my-first-requirements/00-requirements.md
   - Ideally, these requirements should be fleshed out with an agent beforehand, but they can also be simple ("add a button to delete these feed items"), and the agent will flesh out the requirements for you as part of the workflow.
3. Invoke execution:
   - `Implement requirement '<run-id>'`
   - Example: `Implement requirement 00-my-first-requirements`
   - What it does: runs/resumes phases automatically in order. The requirements doc will be read and formatted according to workflow rules.
   - User input required: No (until manual QA phase).
4. **Phase 0 Worktree Setup (`00-worktree.md`) - Isolation (REQUIRED):**
   - **The Iron Law:** Never work on main/master without explicit consent
   - What it does: creates isolated git worktree, runs project setup, verifies clean test baseline
   - **Safety:** Verifies worktree directory is git-ignored
   - **Baseline:** All tests passing before changes begin
   - User input required: No (auto-creates worktree if on main branch).
5. Phase 1 (`01-as-is.md`) - AS-IS analysis:
   - What it does: captures current behavior, repro steps, code pointers, known unknowns.
   - **Context:** Executes in isolated worktree
   - User input required: Usually no.
6. **Phase 1.5 (`01.5-root-cause.md`) - Root Cause Analysis (optional, debug mode):**
   - **When:** For bug fixes, test failures, unexpected behavior
   - What it does: systematic 4-phase debugging (error analysis -> reproduction -> data flow tracing -> hypothesis testing)
   - **The Iron Law:** No fixes without root cause investigation first
   - User input required: No.
7. Phase 2 (`02-to-be-plan.md`) - TO-BE plan:
   - What it does: creates an ExecPlan-grade implementation + validation plan (including tests and manual QA scenarios).
   - If Phase 1.5 exists: incorporates root cause findings into fix plan
   - User input required: Usually no, unless the user wants to refine scope/tradeoffs.
8. **Phase 3 (`03-implementation-summary.md`) - Implementation (TDD Discipline + Parallelization):**
   - What it does: applies planned code changes and records what changed and why.
   - **The Iron Law:** No production code without a failing test first
   - **Required:** TDD Compliance Log documenting RED-GREEN-REFACTOR cycles
   - **Execution Modes:**
     - **Parallel Mode:** Dispatch subagents for independent sub-phases (3x faster)
     - **Sequential Mode:** Execute sub-phases sequentially in main agent (fallback)
   - User input required: No.
9. **Phase 3.5 (`03.5-code-review.md`) - Code Review (optional):**
   - **When:** High-risk changes, complex sub-phases, or extra confidence needed
   - What it does: subagent review of implementation against plan and coding standards
   - **Parallel Mode:** Independent `code-reviewer` subagent
   - **Sequential Mode:** Extended self-review checklist
   - User input required: No.
10. Phase 4 (`04-test-summary.md`) - Tests and validation:
   - What it does: runs planned validation and records commands/results/evidence.
   - Verifies TDD compliance: all tests from Phase 3 passing
   - **Parallel Mode:** Concurrent test suites (unit + integration + E2E)
   - **Sequential Mode:** Run test suites sequentially
   - User input required: No.
11. Phase 5 (`05-manual-qa.md`) - Manual QA sign-off:
   - What it does: pauses for human QA execution and records observed results.
   - User input required: Yes (the user must run QA scenarios and provide sign-off or failure notes).
12. Phase 6 - Global decisions update:
   - Artifact updated: `.codex/DECISIONS.md`
   - What it does: records what changed, why, and references all run artifacts.
   - User input required: No.
13. Phase 7 - Global state update:
   - Artifact updated: `.codex/STATE.md`
   - What it does: updates current system state to reflect the final implemented behavior.
   - User input required: No.

Optional phase-specific control:
   - Example: `Run RLM Phase 3 for 00-my-first-requirements`
   - What it does: executes only one selected phase, but still enforces sequential lock-chain rules.
   - User input required: Depends on phase (manual input required at Phase 5 only).

## Execution Modes

RLM automatically detects subagent capabilities and selects the optimal execution mode:

### Parallel Mode (Subagents Available)

When subagent spawning is available (Claude Code `Task` tool, Codex native subagents, etc.):

**Phase 3 - Parallel Implementation:**
- Controller dispatches implementer subagents for independent sub-phases concurrently
- Two-stage review: spec compliance -> code quality
- Review loops until each sub-phase is approved
- Integration testing after all sub-phases complete

**Phase 3.5 - Independent Review:**
- `code-reviewer` subagent evaluates against plan and standards
- Severity classification (Critical/Important/Minor)
- Fixes loop until approved

**Phase 4 - Parallel Testing:**
- Subagent 1: Unit tests
- Subagent 2: Integration tests
- Subagent 3: E2E Tier A
- All run concurrently, results aggregated

### Sequential Mode (Fallback)

When subagents are unavailable (platform limitation, user request):

- Sub-phases executed sequentially in main agent
- Extended self-review checklist
- Integration testing between each sub-phase
- Slower but equally rigorous

### Mode Detection

**Automatic at Phase 3 start:**
```
1. Check for agent/Task tool capability
2. If available -> Use PARALLEL mode
3. If unavailable -> Use SEQUENTIAL mode
```

**Platforms:**
- **Claude Code:** Parallel if `Task` tool available
- **Codex:** Parallel if native subagent support
- **OpenCode:** Check `skill` tool capabilities
- **Cursor:** Usually sequential (limited subagent support)

## 4. What it does

- Executes RLM phases using `.agent/PLANS.md` as canonical rules.
- Writes and updates run artifacts under `.codex/rlm/<run-id>/`.
- Applies effective-input processing (base artifact + addenda).
- Produces traceability mappings from `R#` to evidence.
- Locks artifacts only when gates pass, with `LockedAt` and `LockHash`.
- Enforces hard-stop phase transition checks so later phases cannot run unless prior phases are lock-valid.
- Enforces strict phase isolation: only one active/DRAFT phase is allowed per run.
- Handles manual QA pause/resume behavior for Phase 6.

## 5. Verification & Safety

### Lock Verification

Verify integrity of locked artifacts:

`LockHash` is computed from a canonical normalized form of the artifact text (LF newlines, with the `LockHash:` line removed). Use the provided verifier script rather than hashing the raw file bytes directly.

```powershell
# Verify specific run
powershell -ExecutionPolicy Bypass -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot . -RunId "<run-id>"
pwsh -NoProfile -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot . -RunId "<run-id>"

# Scan all runs
powershell -ExecutionPolicy Bypass -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot .
pwsh -NoProfile -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot .

# Fix incorrect hashes (use with caution; indicates post-lock modifications)
powershell -ExecutionPolicy Bypass -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot . -RunId "<run-id>" -Fix
pwsh -NoProfile -File "<SKILL_DIR>/scripts/verify-locks.ps1" -RepoRoot . -RunId "<run-id>" -Fix
```

Find the installed location via `npx skills list` (or use project-local install so `<SKILL_DIR>` is under `.agents/skills/...`).

### Worktree Status

Check if you're in an isolated worktree:

```bash
# Show current worktree
git worktree list

# Should show: /path/to/project/.worktrees/<run-id>
# NOT: /path/to/project (main working tree)
```

### Branch Protection

If you accidentally start on main branch, the workflow will:
1. Display a warning
2. Create an isolated worktree (default)
3. Require explicit consent to proceed on main

### Clean Baseline

Before making changes, Phase 0 verifies:
- All tests passing
- No uncommitted changes
- Known starting state

This ensures any failures are due to your changes, not pre-existing issues.

### Skill Priority System

When a requirement involves multiple concerns, the workflow applies skills in priority order:

| Priority | Concern | When to Apply |
|----------|---------|---------------|
| 1 | **Debugging** | Bug fixes, crashes, test failures -> Run Phase 1.5 first |
| 2 | **Design** | New features -> Complete Phase 1 (AS-IS) before planning |
| 3 | **Implementation** | After analysis complete -> Proceed to Phase 3+ |
| 4 | **Testing** | All implementation -> Use TDD discipline in Phase 3 |
| 5 | **Review** | After implementation -> Optional Phase 3.5 Code Review |

**Example:** "Fix login crash" -> Debugging priority -> Phase 1.5 (Root Cause) before Phase 2 (Planning)

### Hard Gates

Hard gates (`<HG>`) are non-negotiable checkpoints that prevent skipping steps:

| Gate | Condition |
|------|-----------|
| **HG-0** | Do NOT proceed to Phase 1 until worktree is created and verified |
| **HG-1** | Do NOT create Phase 3 plan until Phase 2 is LOCKED |
| **HG-2** | Do NOT plan fix until Phase 1.5 root cause analysis is complete |
| **HG-3** | Do NOT write code until failing test is documented (TDD) |
| **HG-4** | Do NOT proceed to QA until all tests pass |
| **HG-5** | Do NOT update global docs until user signs off on QA |
| **HG-6** | Do NOT start Phase N unless all prior phases are lock-valid |
| **HG-7** | Do NOT work on main branch without explicit consent |

**If a hard gate is violated:** STOP immediately, return to the skipped phase, complete it properly, lock it, then resume.

## 6. How it does it

- Reads `.codex/AGENTS.md` for local invocation conventions and `.agent/PLANS.md` for authoritative process rules.
- Runs single-command orchestration with auto-resume:
  - resume incomplete phases
  - create missing next-phase artifacts
  - block any phase advancement when prior artifacts are not lock-valid
  - forbid parallel phase work (no multi-phase DRAFT state)
  - never modify locked prior-phase artifacts
- Uses stage-local and upstream-gap addenda to preserve immutability while handling new findings.
- Uses `references/artifact-template.md` as the artifact-writing standard.
- **Enforces worktree isolation via `skills/rlm-worktree/SKILL.md`** - Phase 0 isolation before all other phases
- **Enforces TDD discipline via `skills/rlm-tdd/SKILL.md`** - RED-GREEN-REFACTOR cycles, The Iron Law
- **Supports systematic debugging via `skills/rlm-debugging/SKILL.md`** - Phase 1.5 root cause analysis
- **Enables parallel execution via `skills/rlm-subagent/SKILL.md`** - Subagent-driven execution with sequential fallback
- **Prevents rationalization via `references/rationalizations.md`** - Common excuse/reality tables
- **Enforces TODO discipline** - Mandatory checkable TODOs in all phases; no locking with unchecked items

## 7. How to modify the workflow

Below are common customizations and exactly which file(s) to edit for each.

1. Change trigger phrases or when the skill should activate.
   - Edit: `SKILL.md` (frontmatter `description`)

2. Change phase behavior (for example, require an extra approval pause in Phase 3).
   - Edit: `SKILL.md` (single-command contract and phase rules)
   - Edit: `references/plans-canonical.md` (full canonical PLANS text that gets upserted on install)
   - Edit: `references/artifact-template.md` (gates/checklists to match the new rule)

3. Change artifact format or required sections.
   - Edit: `references/artifact-template.md` (headers, traceability, gate templates)
   - Edit: `SKILL.md` (phase execution protocol and expectations)

4. Change run folder structure or artifact file names.
   - Edit: `SKILL.md` (run folder and artifact paths)
   - Edit: `references/artifact-template.md` (all template paths)
   - Edit: `scripts/install-rlm-workflow.ps1` (scaffold and inserted path references)

5. Change what gets inserted into `.codex/AGENTS.md` and `.agent/PLANS.md`.
   - Edit: `scripts/install-rlm-workflow.ps1` (`$agentsBlock` and PLANS upsert markers/settings)
   - Edit: `references/plans-canonical.md` (the full PLANS content that is inserted)

6. Add or change global artifacts beyond `DECISIONS.md` and `STATE.md`.
   - Edit: `SKILL.md` (global artifacts + phase expectations)
   - Edit: `scripts/install-rlm-workflow.ps1` (create/ensure those files)
   - Edit: `references/artifact-template.md` (if new required sections are needed)

7. Change testing policy (TDD depth, Playwright tagging, tier commands).
   - Edit: `SKILL.md` (mandatory PLANS sections to enforce)
   - Edit: `skills/rlm-tdd/SKILL.md` (TDD discipline rules)
   - Edit: `references/artifact-template.md` (test summary and plan template sections)
   - Edit in target repo: `.agent/PLANS.md` (canonical testing rules)

8. Change systematic debugging process (Phase 1.5).
   - Edit: `skills/rlm-debugging/SKILL.md` (debugging methodology)
   - Edit: `references/plans-canonical.md` (Phase 1.5 integration)
   - Edit: `references/artifact-template.md` (Phase 1.5 template)

9. Change rationalization tables.
   - Edit: `references/rationalizations.md` (excuse/reality tables)
   - Edit: `references/artifact-template.md` (Rationalization Awareness section)

10. Change how installation/setup works.
   - Edit: `scripts/install-rlm-workflow.ps1`
   - Edit: `README.md` (installation instructions)
   - Edit: `SKILL.md` (Install Bootstrap section)
   - Note: installer guarantees `.agent/PLANS.md` exists after installation.

11. Update end-user documentation and examples.
   - Edit: `README.md`

12. Keep inserted AGENTS skills index in sync after edits.
   - Edit: `scripts/install-rlm-workflow.ps1` (`$agentsBlock`)
   - Then re-run the installer against the target repo (see Bootstrap section)

## Optional Templates

Copy/paste prompt templates for agents that support custom commands:

- `docs/templates/commands/rlm-init.md` - prompt template to bootstrap a new run
- `docs/templates/commands/rlm-status.md` - prompt template to summarize run status
- `docs/templates/hooks/*` - optional hook templates (manual wiring only)

These are templates only; Skills CLI does not register commands/hooks automatically.

### Cross-Platform Skills

Skills are shared across all platforms via the `skills/` directory:
- `skills/rlm-worktree/SKILL.md` - Phase 0 worktree isolation
- `skills/rlm-tdd/SKILL.md` - TDD discipline for Phase 3
- `skills/rlm-debugging/SKILL.md` - Systematic debugging for Phase 1.5
- `skills/rlm-subagent/SKILL.md` - Parallel execution with fallback




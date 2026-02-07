# RLM Workflow Skill for Codex

## 0. How to install

```bash
npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow
```
NOTE: This workflow is currently built for use with CODEX. If you use other harnesses, agents or models, you can easily customize it accordingly, since this workflow is just based on a number of markdown files.

## 1. Introduction to RLM-workflow skill

`rlm-workflow` is a Codex skill for running the repository's RLM (Recursive Language Model workflow) with strict phase gates, traceability, locking, and addenda rules.

rlm-workflow is inspired by the MIT paper 'Recursive Language Models'. While the paper reports increased performance, reduced context rot and an effective context window of 10 million tokens by using agents, agents are a sidetrack. The core finding is that important information such as requirements, implementation plans and current codebase analysis must NOT be part of the agent context but stored in static files. 

rlm-workflow uses a standard kanban-workflow with distinct phases like requirements, codebase analysis, implementation plan, implementation summary, verification, manual QA of implementation, and then updating of global repo artifacts (STATE.md and DECISIONS.md) to document the codebase.

Each phase takes the previous phases' output docs as input, and outputs one markdown file of its own. When a phase is done, the artifact is locked with a hash to prevent drift.

The phases can easily be customized by editing the SKILL.md doc. 

Currently, the workflow asks for manual verification at the QA phase. If you want it to wait for permission at other stages, like the TO-BE implementation plan, before continuing, you can easily add that to the SKILL.md doc.

## 2. Why use it

- It keeps requirements and plans in repo files instead of chat context.
- It enforces deterministic phase outputs with explicit `Coverage Gate` and `Approval Gate`.
- It supports resumable, single-command execution for complex multi-phase work.
- It reduces regressions by requiring validation and manual QA sign-off flow.
- It increases effective context windows, multi-step run accuracy, by preventing context rot and requirement drift.
- All historical implementations, including Why, What and How, can easily be audited in the .codex/rlm/ folder where each requirement has its own folder with locked artifacts per phase.

## 3. How to use it

1. Install with:
   - `npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow`
2. Create a run folder and Phase 1 requirements artifact:
   - Path: `.codex/rlm/<run-id>/00-requirements.md`
   - Example: I create the folder for my first requirements as: /rlm/00-my-first-requirements
   - I then create the requirements doc inside the same folder: /00-my-first-requirements/00-requirements.md
   - Ideally, these requirements should be fleshed out with an agent beforehand, but they can also be simple ("add a button to delete these feed items"), and the agent will flesh out the requirements for you as part of the workflow.
3. Invoke execution:
   - `Implement requirement '<run-id>'`
   - Example: `Implement requirement 00-my-first-requirements`
   - What it does: runs/resumes phases automatically in order. The requirements doc will be read and formatted according to workflow rules.
   - User input required: No (until manual QA phase).
4. Phase 2 (`01-as-is.md`) - AS-IS analysis:
   - What it does: captures current behavior, repro steps, code pointers, known unknowns.
   - User input required: Usually no.
5. Phase 3 (`02-to-be-plan.md`) - TO-BE plan:
   - What it does: creates an ExecPlan-grade implementation + validation plan (including tests and manual QA scenarios).
   - User input required: Usually no, unless the user wants to refine scope/tradeoffs.
6. Phase 4 (`03-implementation-summary.md`) - Implementation:
   - What it does: applies planned code changes and records what changed and why.
   - User input required: No.
7. Phase 5 (`04-test-summary.md`) - Tests and validation:
   - What it does: runs planned validation and records commands/results/evidence.
   - User input required: No.
8. Phase 6 (`05-manual-qa.md`) - Manual QA sign-off:
   - What it does: pauses for human QA execution and records observed results.
   - User input required: Yes (the user must run QA scenarios and provide sign-off or failure notes).
9. Phase 7 - Global decisions update:
   - Artifact updated: `.codex/DECISIONS.md`
   - What it does: records what changed, why, and references all run artifacts.
   - User input required: No.
10. Phase 8 - Global state update:
   - Artifact updated: `.codex/STATE.md`
   - What it does: updates current system state to reflect the final implemented behavior.
   - User input required: No.

Optional phase-specific control:
   - Example: `Run RLM Phase 3 for 00-my-first-requirements`
   - What it does: executes only one selected phase.
   - User input required: Depends on phase (manual input required at Phase 6 only).

## 4. What it does

- Executes RLM phases using `.agent/PLANS.md` as canonical rules.
- Writes and updates run artifacts under `.codex/rlm/<run-id>/`.
- Applies effective-input processing (base artifact + addenda).
- Produces traceability mappings from `R#` to evidence.
- Locks artifacts only when gates pass, with `LockedAt` and `LockHash`.
- Handles manual QA pause/resume behavior for Phase 6.

## 5. How it does it

- Reads `.codex/AGENTS.md` for local invocation conventions and `.agent/PLANS.md` for authoritative process rules.
- Runs single-command orchestration with auto-resume:
  - resume incomplete phases
  - create missing next-phase artifacts
  - never modify locked prior-phase artifacts
- Uses stage-local and upstream-gap addenda to preserve immutability while handling new findings.
- Uses `references/artifact-template.md` as the artifact-writing standard.

## 6. How to modify the workflow

Below are common customizations and exactly which file(s) to edit for each.

1. Change trigger phrases or when the skill should activate.
   - Edit: `SKILL.md` (frontmatter `description`)
   - Optional: `agents/openai.yaml` (`default_prompt`, `short_description`)

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
   - Edit: `references/artifact-template.md` (test summary and plan template sections)
   - Edit in target repo: `.agent/PLANS.md` (canonical testing rules)

8. Change how installation/setup works.
   - Edit: `scripts/install-rlm-workflow.ps1`
   - Edit: `README.md` (installation instructions)
   - Edit: `SKILL.md` (Install Bootstrap section)
   - Note: installer guarantees `.agent/PLANS.md` exists after installation.

9. Update end-user documentation and examples.
   - Edit: `README.md`

10. Keep inserted AGENTS skills index in sync after edits.
   - Run in target repo: `powershell -ExecutionPolicy Bypass -File .codex/scripts/update-agents-skills.ps1`

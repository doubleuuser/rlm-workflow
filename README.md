# RLM Workflow Skill

## 0. How to install

```bash
npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow
```

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

## 3. How to use it

1. Install/discover the skill in your environment.
2. Install with:
   - `npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow`
3. Start or continue work with short commands such as:
   - `Implement requirement '<run-id>'`
   - `Run RLM Phase 3 for .codex/rlm/<run-id>/`

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

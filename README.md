# RLM Workflow Skill

## 0. How to install

```bash
npx skills add https://github.com/doubleuuser/rlm-workflow --skill rlm-workflow
```

## 1. Introduction to RLM-workflow skill

`rlm-workflow` is a Codex skill for running the repository's RLM (Repo-Document Workflow) with strict phase gates, traceability, locking, and addenda rules.

## 2. Why use it

- It keeps requirements and plans in repo files instead of chat context.
- It enforces deterministic phase outputs with explicit `Coverage Gate` and `Approval Gate`.
- It supports resumable, single-command execution for complex multi-phase work.
- It reduces regressions by requiring validation and manual QA sign-off flow.

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

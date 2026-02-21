# RLM Workflow (Agent Skills)

`rlm-workflow` is a skills package for AI-assisted software development with strict phase gates, locked artifacts, TDD discipline, and systematic debugging.

This repo is installed as **Agent Skills** via the **Skills CLI**.

## Install

Interactive install (auto-detects agents and prompts you):

```bash
npx skills add doubleuuser/rlm-workflow
```

List available skills (no install):

```bash
npx skills add doubleuuser/rlm-workflow --list
```

Install all skills from this repo:

```bash
npx skills add doubleuuser/rlm-workflow --skill '*'
```

Global install (available across projects):

```bash
npx skills add doubleuuser/rlm-workflow --skill '*' -g -y
```

If symlinks aren't supported in your environment, add `--copy`.

## Included skills

* `rlm-workflow` (root meta-skill / orchestrator)
* `rlm-worktree` (Phase 0 worktree isolation)
* `rlm-debugging` (Phase 1.5 systematic debugging)
* `rlm-tdd` (TDD discipline for implementation)
* `rlm-subagent` (parallelization + fallback patterns)

## Usage

1. Create a run requirements artifact:

   * `.codex/rlm/<run-id>/00-requirements.md`

2. In your agent chat, run:

   * `Implement requirement '<run-id>'`

On first invocation, `rlm-workflow` will bootstrap and upsert the required repo scaffolding (AGENTS/PLANS/etc) if missing or outdated.

## License

Apache-2.0

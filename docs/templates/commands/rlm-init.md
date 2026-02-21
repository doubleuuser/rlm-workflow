# rlm-init (prompt template)

> This is a copy/paste prompt template. Some agents support custom slash commands; if yours doesn't, paste this prompt into chat.

## Usage Pattern

```
Initialize RLM run: <run-id> [options]
```

## Arguments

- `run-id` - Unique identifier for this run (e.g., "2026-02-21-user-auth")
- `--template` - Use a specific template (feature|bugfix|refactor)
- `--from-issue` - Link to GitHub issue number

## Description

Creates a new RLM run folder with scaffolding:

1. Creates `.codex/rlm/<run-id>/` directory
2. Generates `00-requirements.md` template
3. Optionally populates from issue template

## Example

```
Initialize RLM run: 2026-02-21-add-oauth --template feature
```

## Output

After running this command:
- Directory: `.codex/rlm/2026-02-21-add-oauth/`
- Template: `.codex/rlm/2026-02-21-add-oauth/00-requirements.md`

Next step: Edit the requirements file, then run:
```
Implement requirement '2026-02-21-add-oauth'
```

## Implementation

Use the `rlm-workflow` skill to execute initialization:

1. Resolve run folder path
2. Create directory structure
3. Generate requirements template from `references/artifact-template.md`
4. Report success with next steps

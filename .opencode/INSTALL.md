# RLM Workflow Installation for OpenCode

## Prerequisites

- OpenCode.ai CLI installed
- Node.js 18+ (for plugin execution)
- Git

## Installation

### Step 1: Clone the Repository

```bash
# Clone to OpenCode skills directory
mkdir -p ~/.config/opencode/skills
git clone https://github.com/doubleuuser/rlm-workflow.git ~/.config/opencode/skills/rlm-workflow
```

### Step 2: Enable the Plugin

Add to your OpenCode configuration (usually `~/.config/opencode/config.json`):

```json
{
  "plugins": [
    {
      "id": "rlm-workflow",
      "path": "~/.config/opencode/skills/rlm-workflow/.opencode/plugins/rlm-workflow.js"
    }
  ]
}
```

Or use the OpenCode CLI:

```bash
opencode plugin add ~/.config/opencode/skills/rlm-workflow/.opencode/plugins/rlm-workflow.js
```

### Step 3: Restart OpenCode

The plugin loads on startup and injects RLM workflow context into the system prompt.

```bash
opencode restart
```

### Step 4: Verify Installation

In an OpenCode chat, try:

```
List available RLM skills
```

You should see:
- rlm-workflow
- rlm-tdd
- rlm-debugging

## Usage

### Starting a New Run

```
Implement requirement 'my-feature'
```

OpenCode will:
1. Check for existing runs in `.codex/rlm/`
2. Auto-resume from current phase if found
3. Or guide you to create `00-requirements.md`

### Using Individual Skills

You can invoke specific skills:

```
Use the rlm-tdd skill for implementing this feature
```

```
Use the rlm-debugging skill to analyze this bug
```

### Checking Status

Use the built-in tool:

```
Check rlm:status for run 'my-feature'
```

Or without specifying a run (shows most recent):

```
What's the status of the current RLM run?
```

## Platform Differences

### OpenCode vs Claude Code vs Codex

| Feature | OpenCode | Claude Code | Codex |
|---------|----------|-------------|-------|
| Skill tool | `skill` | `Skill` | Native skill discovery |
| Hooks | Plugin API | Shell hooks | Session bootstrap |
| Auto-update | Manual | Plugin marketplace | Git pull |
| Session persistence | Built-in | Built-in | Built-in |

### OpenCode-Specific Notes

1. **Plugin Architecture**: Uses OpenCode's native plugin system with JavaScript
2. **Context Injection**: Bootstrap content injected via `session.created` hook
3. **Custom Tools**: Provides `rlm:list-skills` and `rlm:status` tools
4. **No Shell Hooks**: Unlike Claude Code, uses JavaScript hooks instead of shell scripts

## Troubleshooting

### Plugin Not Loading

1. Check plugin path is correct in config
2. Verify file exists: `ls ~/.config/opencode/skills/rlm-workflow/.opencode/plugins/rlm-workflow.js`
3. Check OpenCode logs for errors: `opencode logs`

### Skills Not Found

1. Ensure rlm-workflow is cloned correctly
2. Verify SKILL.md files exist in expected locations
3. Try reinstalling: `rm -rf ~/.config/opencode/skills/rlm-workflow` and re-clone

### Context Not Injected

1. Check if experimental features are enabled
2. Restart OpenCode completely
3. Try manually: "Load the rlm-workflow skill"

## Updating

```bash
cd ~/.config/opencode/skills/rlm-workflow
git pull origin main
```

Then restart OpenCode.

## Uninstallation

```bash
# Remove plugin from config
opencode plugin remove rlm-workflow

# Or manually edit ~/.config/opencode/config.json

# Remove files
rm -rf ~/.config/opencode/skills/rlm-workflow
```

## Support

- GitHub Issues: https://github.com/doubleuuser/rlm-workflow/issues
- Documentation: See `README.md` and `SKILL.md` in the repository

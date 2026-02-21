#!/usr/bin/env bash
#
# Claude Code Session Start Hook for RLM Workflow
# 
# This hook runs at the start of each Claude Code session to:
# 1. Bootstrap RLM workflow context
# 2. Ensure skills are discoverable
# 3. Show available RLM capabilities
#

set -euo pipefail

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Plugin root directory
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME="rlm-workflow"

echo ""
echo "📋 RLM Workflow Plugin"
echo "====================="
echo ""

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    echo "Repository: $(basename "$REPO_ROOT")"
else
    echo "Warning: Not in a git repository. RLM workflow requires version control."
fi

echo ""
echo "Available Skills:"
echo "  • rlm-workflow    - Main workflow orchestration"
echo "  • rlm-tdd         - TDD discipline for Phase 3"
echo "  • rlm-debugging   - Systematic debugging for Phase 1.5"
echo ""

echo "Quick Start:"
echo "  1. Create run folder: mkdir -p .codex/rlm/my-feature"
echo "  2. Write requirements: .codex/rlm/my-feature/00-requirements.md"
echo "  3. Invoke: 'Implement requirement my-feature'"
echo ""

# Check for existing RLM runs
if [ -d ".codex/rlm" ] 2>/dev/null; then
    RUN_COUNT=$(find .codex/rlm -maxdepth 1 -type d | wc -l)
    if [ "$RUN_COUNT" -gt 1 ]; then
        ACTIVE_RUNS=$(find .codex/rlm -maxdepth 2 -name "*.md" -newer .codex/rlm/.gitkeep 2>/dev/null | head -5 || echo "")
        if [ -n "$ACTIVE_RUNS" ]; then
            echo "Recent Activity:"
            find .codex/rlm -maxdepth 1 -type d -not -path ".codex/rlm" | while read -r run_dir; do
                run_name=$(basename "$run_dir")
                if [ -f "$run_dir/00-requirements.md" ]; then
                    status=$(grep "^Status:" "$run_dir/"*.md 2>/dev/null | tail -1 | cut -d: -f2 | tr -d ' ' || echo "UNKNOWN")
                    echo "  • $run_name - Status: $status"
                fi
            done
            echo ""
        fi
    fi
fi

echo "Documentation:"
echo "  • Workflow rules: .agent/PLANS.md"
echo "  • Artifact templates: references/artifact-template.md"
echo "  • Rationalizations: references/rationalizations.md"
echo ""

echo "====================="
echo ""

# Export environment variable for child processes
export RLM_WORKFLOW_ROOT="$PLUGIN_ROOT"
export RLM_WORKFLOW_VERSION="2.0.0"

# Success - hook completed
echo "✅ RLM Workflow ready"
echo ""

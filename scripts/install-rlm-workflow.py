#!/usr/bin/env python3
"""
Cross-platform installer/bootstrapper for rlm-workflow.

Behavior is shared with install-rlm-workflow.ps1:
- ensures scaffold directories/files exist
- upserts managed block in .codex/AGENTS.md from references/agents-block.md
- upserts managed block in .agent/PLANS.md from references/plans-canonical.md
- preserves unrelated existing file content
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def write_utf8_no_bom(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8", newline="\n")


def ensure_directory(path: Path) -> None:
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
        print(f"[OK] Created directory: {path}")
    else:
        print(f"[OK] Directory exists: {path}")


def ensure_file(path: Path, content: str) -> None:
    if not path.exists():
        if path.parent:
            ensure_directory(path.parent)
        write_utf8_no_bom(path, content)
        print(f"[OK] Created file: {path}")
    else:
        print(f"[OK] File exists: {path}")


def upsert_marked_block(file_path: Path, start_marker: str, end_marker: str, block_body: str) -> None:
    existing = file_path.read_text(encoding="utf-8") if file_path.exists() else ""
    block = f"{start_marker}\n{block_body}\n{end_marker}"
    pattern = re.compile(rf"{re.escape(start_marker)}.*?{re.escape(end_marker)}", re.DOTALL)

    if pattern.search(existing):
        updated = pattern.sub(block, existing)
    else:
        if existing.strip() == "":
            updated = f"{block}\n"
        else:
            updated = f"{existing.rstrip()}\n\n{block}\n"

    if updated != existing:
        write_utf8_no_bom(file_path, updated)
        print(f"[OK] Updated file: {file_path}")
    else:
        print(f"[OK] File already up to date: {file_path}")


def normalize_with_trailing_newline(content: str) -> str:
    return content.rstrip("\r\n") + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Install/bootstrap rlm-workflow scaffolding.")
    parser.add_argument("--repo-root", default=".", help="Repository root path (default: current directory).")
    parser.add_argument(
        "--skip-plans-update",
        action="store_true",
        help="Skip canonical plans upsert.",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    print(f"[INFO] Repo root: {repo_root}")

    skill_root = Path(__file__).resolve().parent.parent
    canonical_plans_path = skill_root / "references" / "plans-canonical.md"
    agents_block_path = skill_root / "references" / "agents-block.md"

    codex_dir = repo_root / ".codex"
    agent_dir = repo_root / ".agent"
    rlm_dir = codex_dir / "rlm"

    agents_path = codex_dir / "AGENTS.md"
    decisions_path = codex_dir / "DECISIONS.md"
    state_path = codex_dir / "STATE.md"
    plans_path = agent_dir / "PLANS.md"

    plans_start_marker = "<!-- RLM-WORKFLOW-PLANS:START -->"
    plans_end_marker = "<!-- RLM-WORKFLOW-PLANS:END -->"

    ensure_directory(codex_dir)
    ensure_directory(agent_dir)
    ensure_directory(rlm_dir)

    ensure_file(rlm_dir / ".gitkeep", "")
    ensure_file(
        decisions_path,
        "# DECISIONS.md\n\n## RLM Run Index\n\n- No runs recorded yet.\n",
    )
    ensure_file(
        state_path,
        "# STATE.md\n\n## Current State\n\n- Initial state not documented yet.\n",
    )
    ensure_file(agents_path, "# AGENTS.md\n")
    ensure_file(plans_path, "")

    if not agents_block_path.exists():
        raise FileNotFoundError(f"Missing shared AGENTS block template: {agents_block_path}")
    agents_block = agents_block_path.read_text(encoding="utf-8").rstrip("\r\n")

    upsert_marked_block(
        agents_path,
        "<!-- RLM-WORKFLOW:START -->",
        "<!-- RLM-WORKFLOW:END -->",
        agents_block,
    )

    if not args.skip_plans_update:
        if canonical_plans_path.exists():
            plans_block = canonical_plans_path.read_text(encoding="utf-8")
            if plans_block.strip():
                plans_body = plans_block.rstrip("\r\n")
                normalized_canonical = normalize_with_trailing_newline(plans_body)
                existing_plans = plans_path.read_text(encoding="utf-8") if plans_path.exists() else ""
                normalized_existing = (
                    normalize_with_trailing_newline(existing_plans) if existing_plans else ""
                )
                plans_pattern = re.compile(
                    rf"{re.escape(plans_start_marker)}.*?{re.escape(plans_end_marker)}",
                    re.DOTALL,
                )
                has_managed_block = bool(plans_pattern.search(existing_plans))

                if (not has_managed_block) and (normalized_existing == normalized_canonical):
                    wrapped = f"{plans_start_marker}\n{plans_body}\n{plans_end_marker}\n"
                    write_utf8_no_bom(plans_path, wrapped)
                    print("[OK] Migrated .agent/PLANS.md to managed upsert block format.")
                else:
                    upsert_marked_block(
                        plans_path,
                        plans_start_marker,
                        plans_end_marker,
                        plans_body,
                    )
            else:
                print(f"[INFO] Skipped PLANS update: canonical plans file is empty at {canonical_plans_path}")
        else:
            print(f"[INFO] Skipped PLANS update: canonical plans file not found at {canonical_plans_path}")
    else:
        print("[INFO] Skipped PLANS update by configuration.")

    print("[OK] RLM workflow installation bootstrap complete.")


if __name__ == "__main__":
    main()

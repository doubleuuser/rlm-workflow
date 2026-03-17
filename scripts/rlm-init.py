#!/usr/bin/env python3
"""
Initialize an RLM run folder and requirements scaffold.

Python equivalent to scripts/rlm-init.ps1.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def write_utf8_no_bom(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8", newline="\n")


def ensure_directory(path: Path) -> None:
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
        print(f"[OK] Created directory: {path}")
    else:
        print(f"[OK] Directory exists: {path}")


def requirements_content(run_id: str, template: str, from_issue: str) -> str:
    inputs = ["- [chat summary or source notes if captured in repo]"]
    if from_issue.strip():
        inputs.append(f"- Source: {from_issue.strip()}")
    inputs_block = "\n".join(inputs)

    return f"""Run: `/.codex/rlm/{run_id}/`
Phase: `00 Requirements`
Status: `DRAFT`
Inputs:
{inputs_block}
Outputs:
- `/.codex/rlm/{run_id}/00-requirements.md`
Scope note: This document defines stable requirement identifiers and acceptance criteria. (Template: {template})

## TODO

- [ ] Elicit requirements from user/context
- [ ] Define requirement identifiers (R1, R2, ...)
- [ ] Write acceptance criteria for each requirement
- [ ] Document out of scope items (OOS1, OOS2, ...)
- [ ] List constraints and assumptions
- [ ] Complete Coverage Gate checklist
- [ ] Complete Approval Gate checklist

## Requirements

### `R1` <short title>

Description:
Acceptance criteria:
- [observable condition 1]
- [observable condition 2]

## Out of Scope

- `OOS1`: ...

## Constraints

- ...

## Assumptions

- ...

## Coverage Gate
...
Coverage: FAIL

## Approval Gate
...
Approval: FAIL
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Initialize an RLM run folder and requirements template.")
    parser.add_argument("--run-id", required=True, help="Run ID (folder name under .codex/rlm/).")
    parser.add_argument("--repo-root", default=".", help="Repository root path.")
    parser.add_argument(
        "--template",
        choices=["feature", "bugfix", "refactor"],
        default="feature",
        help="Requirements template flavor.",
    )
    parser.add_argument("--from-issue", default="", help="Optional issue/ticket/source reference.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing 00-requirements.md.")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    print(f"[INFO] Repo root: {repo_root}")

    rlm_root = repo_root / ".codex" / "rlm"
    run_dir = rlm_root / args.run_id

    ensure_directory(rlm_root)
    ensure_directory(run_dir)
    ensure_directory(run_dir / "addenda")

    evidence_dir = run_dir / "evidence"
    ensure_directory(evidence_dir)
    for sub in ("screenshots", "logs", "perf", "traces", "other"):
        ensure_directory(evidence_dir / sub)

    requirements_path = run_dir / "00-requirements.md"
    if requirements_path.exists() and not args.force:
        print(f"[INFO] Requirements file exists, not overwriting: {requirements_path}")
    else:
        write_utf8_no_bom(requirements_path, requirements_content(args.run_id, args.template, args.from_issue))
        print(f"[OK] Wrote requirements template: {requirements_path}")

    print()
    print("Next steps:")
    print(f"1) Edit: .codex/rlm/{args.run_id}/00-requirements.md")
    print(f"2) Run:  Implement requirement '{args.run_id}'")


if __name__ == "__main__":
    main()

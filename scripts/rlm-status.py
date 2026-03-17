#!/usr/bin/env python3
"""
Show RLM run status, lock chain validity, and next steps.

Python equivalent to scripts/rlm-status.ps1.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


STATUS_RE = re.compile(r"(?m)^[ \t]*Status:\s*(.+?)\s*$")
LOCK_HASH_RE = re.compile(r"(?m)^[ \t]*LockHash:\s*(.+?)\s*$")
LOCKED_AT_RE = re.compile(r"(?m)^[ \t]*LockedAt:\s*(.+?)\s*$")
GATE_RE_TEMPLATE = r"(?m)^[ \t]*{gate}:\s*(PASS|FAIL)\s*$"
LOCK_HASH_LINE_RE = re.compile(r"(?m)^[ \t]*LockHash:.*(?:\n|$)")


def trim_md_value(value: str) -> str:
    return value.strip().strip("`\"'")


def get_md_field_value(content: str, field_name: str) -> str | None:
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(field_name)}:\s*(.+?)\s*$")
    match = pattern.search(content)
    if not match:
        return None
    return trim_md_value(match.group(1))


def get_gate_status(content: str, gate_name: str) -> str:
    pattern = re.compile(GATE_RE_TEMPLATE.format(gate=re.escape(gate_name)))
    match = pattern.search(content)
    return match.group(1).upper() if match else "MISSING"


def normalize_for_lock_hash(content: str) -> str:
    normalized = content.replace("\r\n", "\n").replace("\r", "\n")
    return LOCK_HASH_LINE_RE.sub("", normalized)


def lock_hash_from_content(content: str) -> str:
    normalized = normalize_for_lock_hash(content)
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def get_todo_stats(content: str) -> tuple[bool, int, int, int]:
    lines = content.splitlines()
    in_todo = False
    has_todo = False
    checked = 0
    unchecked = 0
    total = 0

    for line in lines:
        if not in_todo:
            if re.match(r"^\s*##\s+TODO\s*$", line):
                in_todo = True
                has_todo = True
            continue

        if re.match(r"^\s*##\s+", line) or re.match(r"^\s*#\s+", line):
            break

        item = re.match(r"^\s*[-*]\s+\[([ xX])\]\s+", line)
        if item:
            total += 1
            if item.group(1).lower() == "x":
                checked += 1
            else:
                unchecked += 1

    return has_todo, total, checked, unchecked


@dataclass
class TodoStats:
    has_todo: bool
    total: int
    checked: int
    unchecked: int


@dataclass
class ArtifactState:
    exists: bool
    status: str
    lock_valid: bool
    lock_problems: list[str]
    locked_at: str | None
    stored_hash: str | None
    actual_hash: str | None
    coverage: str | None
    approval: str | None
    todo: TodoStats


def get_artifact_state(artifact_path: Path) -> ArtifactState:
    if not artifact_path.exists():
        return ArtifactState(
            exists=False,
            status="PENDING",
            lock_valid=False,
            lock_problems=["File missing"],
            locked_at=None,
            stored_hash=None,
            actual_hash=None,
            coverage=None,
            approval=None,
            todo=TodoStats(False, 0, 0, 0),
        )

    content = artifact_path.read_text(encoding="utf-8")
    status = get_md_field_value(content, "Status") or "UNKNOWN"
    has_todo, total, checked, unchecked = get_todo_stats(content)
    todo = TodoStats(has_todo, total, checked, unchecked)
    coverage = get_gate_status(content, "Coverage")
    approval = get_gate_status(content, "Approval")
    locked_at = get_md_field_value(content, "LockedAt")
    stored_hash = get_md_field_value(content, "LockHash")
    actual_hash = None
    lock_problems: list[str] = []
    lock_valid = False

    if status != "LOCKED":
        lock_problems.append(f"Status is '{status}' (expected LOCKED for lock-valid)")
    else:
        if not locked_at:
            lock_problems.append("Missing LockedAt")
        if not stored_hash:
            lock_problems.append("Missing LockHash")
        if stored_hash:
            actual_hash = lock_hash_from_content(content)
            if stored_hash.strip().lower() != actual_hash.lower():
                lock_problems.append("LockHash mismatch")
        if coverage != "PASS":
            lock_problems.append(f"Coverage gate is {coverage}")
        if approval != "PASS":
            lock_problems.append(f"Approval gate is {approval}")
        if not todo.has_todo:
            lock_problems.append("Missing ## TODO section")
        elif todo.unchecked > 0:
            lock_problems.append(f"Unchecked TODO items: {todo.unchecked}")
        if not lock_problems:
            lock_valid = True

    return ArtifactState(
        exists=True,
        status=status,
        lock_valid=lock_valid,
        lock_problems=lock_problems,
        locked_at=locked_at,
        stored_hash=stored_hash,
        actual_hash=actual_hash,
        coverage=coverage,
        approval=approval,
        todo=todo,
    )


def get_latest_run_directory(rlm_dir: Path) -> Path | None:
    runs = [p for p in rlm_dir.iterdir() if p.is_dir()]
    if not runs:
        return None
    runs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return runs[0]


def print_phase_status(phases: Iterable[dict[str, str]], states: dict[str, ArtifactState], show_hashes: bool, run_id: str) -> None:
    print("Phase Status:")
    for phase in phases:
        state = states[phase["Key"]]
        display = state.status
        suffix = ""
        if display == "SKIPPED":
            suffix = " (not needed)"
        elif display == "LOCKED" and not state.lock_valid:
            display = "LOCKED*"
            suffix = " (invalid)"
        print(f"  {phase['Label']:<26} [{display}]{suffix}")

    print()
    print("Lock Chain:")
    for phase in phases:
        state = states[phase["Key"]]
        if phase["Optional"] and state.status == "SKIPPED":
            continue

        artifact_rel = f".codex/rlm/{run_id}/{phase['File']}"
        if state.lock_valid:
            print(f"  [OK]  {artifact_rel}")
            if show_hashes and state.status == "LOCKED" and state.stored_hash:
                print(f"        LockHash: {state.stored_hash}")
            continue

        if not state.exists:
            print(f"  [PENDING] {artifact_rel}")
        elif state.status != "LOCKED":
            print(f"  [DRAFT]   {artifact_rel}")
        else:
            reason = state.lock_problems[0] if state.lock_problems else "Not lock-valid"
            print(f"  [FAIL]    {artifact_rel} - {reason}")
        break


def main() -> None:
    parser = argparse.ArgumentParser(description="Show RLM run status and lock-chain summary.")
    parser.add_argument("--run-id", default="", help="Run ID to inspect (default: latest run).")
    parser.add_argument("--repo-root", default=".", help="Repository root path.")
    parser.add_argument("--show-hashes", action="store_true", help="Show LockHash values for lock-valid phases.")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    rlm_root = repo_root / ".codex" / "rlm"
    if not rlm_root.exists():
        print(f"[FAIL] RLM directory not found at: {rlm_root}")
        print("       Is this the project repo root? (Expected .codex/rlm/)")
        sys.exit(1)

    if args.run_id.strip():
        run_dir = rlm_root / args.run_id.strip()
        if not run_dir.exists():
            print(f"[FAIL] Run directory not found: {run_dir}")
            sys.exit(1)
        run_id = args.run_id.strip()
    else:
        latest = get_latest_run_directory(rlm_root)
        if latest is None:
            print(f"[FAIL] No runs found under: {rlm_root}")
            sys.exit(1)
        run_dir = latest
        run_id = latest.name

    phases = [
        {"Key": "00R", "Label": "Phase 0 (Requirements)", "File": "00-requirements.md", "Optional": False, "PhaseName": "0 (Requirements)"},
        {"Key": "00W", "Label": "Phase 0 (Worktree)", "File": "00-worktree.md", "Optional": False, "PhaseName": "0 (Worktree)"},
        {"Key": "01", "Label": "Phase 1 (AS-IS)", "File": "01-as-is.md", "Optional": False, "PhaseName": "1 (AS-IS)"},
        {"Key": "01.5", "Label": "Phase 1.5 (Root Cause)", "File": "01.5-root-cause.md", "Optional": True, "PhaseName": "1.5 (Root Cause)"},
        {"Key": "02", "Label": "Phase 2 (TO-BE Plan)", "File": "02-to-be-plan.md", "Optional": False, "PhaseName": "2 (TO-BE Plan)"},
        {"Key": "03", "Label": "Phase 3 (Implementation)", "File": "03-implementation-summary.md", "Optional": False, "PhaseName": "3 (Implementation)"},
        {"Key": "03.5", "Label": "Phase 3.5 (Code Review)", "File": "03.5-code-review.md", "Optional": True, "PhaseName": "3.5 (Code Review)"},
        {"Key": "04", "Label": "Phase 4 (Test Summary)", "File": "04-test-summary.md", "Optional": False, "PhaseName": "4 (Test Summary)"},
        {"Key": "05", "Label": "Phase 5 (Manual QA)", "File": "05-manual-qa.md", "Optional": False, "PhaseName": "5 (Manual QA)"},
    ]

    states: dict[str, ArtifactState] = {}
    for phase in phases:
        state = get_artifact_state(run_dir / phase["File"])
        if phase["Optional"] and not state.exists:
            state.status = "SKIPPED"
        states[phase["Key"]] = state

    current_phase: dict[str, str] | None = None
    current_state: ArtifactState | None = None
    for phase in phases:
        state = states[phase["Key"]]
        if phase["Optional"] and state.status == "SKIPPED":
            continue
        if not state.exists or not state.lock_valid:
            current_phase = phase
            current_state = state
            break

    title = f"RLM Run: {run_id}"
    print(title)
    print("=" * max(8, len(title)))
    print()

    print_phase_status(phases, states, args.show_hashes, run_id)
    print()
    if current_phase is None:
        print("Current Phase: COMPLETE")
        print("Status: LOCKED")
    else:
        print(f"Current Phase: {current_phase['PhaseName']}")
        print(f"Status: {current_state.status}")

    evidence_dir = run_dir / "evidence"
    evidence_files = sum(1 for p in evidence_dir.rglob("*") if p.is_file()) if evidence_dir.exists() else 0
    evidence_rel = f".codex/rlm/{run_id}/evidence/"
    print()
    print("Evidence:")
    print(f"  Path:   {evidence_rel}")
    print(f"  Exists: {'Yes' if evidence_dir.exists() else 'No'}")
    print(f"  Files:  {evidence_files}")

    print()
    print("Next Steps:")
    if current_phase is None:
        print("  1. Update /.codex/DECISIONS.md and /.codex/STATE.md (Phases 6/7).")
        print("  2. Merge the worktree branch when ready.")
    else:
        next_artifact = f".codex/rlm/{run_id}/{current_phase['File']}"
        key = current_phase["Key"]
        if key == "00R":
            print(f"  1. Create/complete {next_artifact} (define R1.., fill TODO, Coverage, Approval).")
            print("  2. Lock it (set Status: LOCKED, add LockedAt + LockHash).")
        elif key == "00W":
            print(f"  1. Set up isolated worktree and baseline tests, then write evidence into {next_artifact}.")
            print("  2. Lock it, then proceed to 01-as-is.md.")
        elif key == "01":
            print(f"  1. Write AS-IS analysis into {next_artifact} (repro steps, current behavior, code pointers, evidence).")
            print("  2. Lock it, then proceed to planning (02-to-be-plan.md).")
        elif key == "01.5":
            print(f"  1. Complete root-cause analysis in {next_artifact} (no fixes yet).")
            print("  2. Lock it, then incorporate into Phase 2 plan.")
        elif key == "02":
            print(f"  1. Complete the ExecPlan in {next_artifact} (files, steps, testing, QA, recovery).")
            print("  2. Lock it, then start implementation (Phase 3) with TDD.")
        elif key == "03":
            print(f"  1. Implement plan via TDD and document in {next_artifact} (TDD log + evidence refs).")
            print("  2. Lock it, then run validation (Phase 4).")
        elif key == "03.5":
            print(f"  1. Complete code review in {next_artifact} and resolve any issues.")
            print("  2. Lock it, then proceed to Phase 4.")
        elif key == "04":
            print(f"  1. Run tests and record exact commands/results in {next_artifact}.")
            print(f"  2. Save artifacts under {evidence_rel} and reference paths in the doc.")
            print("  3. Lock Phase 4, then proceed to Manual QA (Phase 5).")
        elif key == "05":
            print(f"  1. Execute manual QA scenarios and record results in {next_artifact}.")
            print(f"  2. Save screenshots/logs under {evidence_rel} and reference paths.")
            print("  3. Record explicit user sign-off, lock Phase 5, then update DECISIONS/STATE.")
        else:
            print(f"  1. Complete {next_artifact}, pass gates, and lock the artifact.")

    print()
    print("Quick Command:")
    print(f"  Implement requirement '{run_id}'")


if __name__ == "__main__":
    main()

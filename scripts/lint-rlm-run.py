#!/usr/bin/env python3
"""
Lint RLM artifacts for required structure and gate discipline.

Python equivalent to scripts/lint-rlm-run.ps1.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def write_issue(severity: str, file_path: Path, message: str, remediation_lines: list[str] | None = None) -> None:
    print(f"[{severity}] {file_path}: {message}")
    if remediation_lines:
        print("Remediation (copy/paste):")
        for line in remediation_lines:
            print(f"  {line}")
    print()


def get_md_field_value(content: str, field_name: str) -> str | None:
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(field_name)}:\s*(.+?)\s*$")
    match = pattern.search(content)
    if not match:
        return None
    return match.group(1).strip().strip("`\"'")


def has_header_field(content: str, field_name: str) -> bool:
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(field_name)}:")
    return bool(pattern.search(content))


def has_heading(content: str, heading_text: str) -> bool:
    pattern = re.compile(rf"(?m)^[ \t]*##\s+{re.escape(heading_text)}\s*$")
    return bool(pattern.search(content))


def has_gate_line(content: str, gate_name: str) -> bool:
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(gate_name)}:\s*(PASS|FAIL)\s*$")
    return bool(pattern.search(content))


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


def get_latest_run_directory(rlm_dir: Path) -> Path | None:
    runs = [p for p in rlm_dir.iterdir() if p.is_dir()]
    if not runs:
        return None
    runs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return runs[0]


def get_artifact_required_sections(file_name: str) -> list[str]:
    section_map: dict[str, list[str]] = {
        "00-worktree.md": [
            "TODO",
            "Directory Selection",
            "Safety Verification",
            "Worktree Creation",
            "Main Branch Protection",
            "Project Setup",
            "Test Baseline Verification",
            "Worktree Context",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "00-requirements.md": [
            "TODO",
            "Requirements",
            "Out of Scope",
            "Constraints",
            "Assumptions",
            "Coverage Gate",
            "Approval Gate",
        ],
        "01-as-is.md": [
            "TODO",
            "Reproduction Steps (Novice-Runnable)",
            "Current Behavior by Requirement",
            "Relevant Code Pointers",
            "Known Unknowns",
            "Evidence",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "01.5-root-cause.md": [
            "TODO",
            "Error Analysis",
            "Reproduction Verification",
            "Recent Changes Analysis",
            "Evidence Gathering (Multi-Layer if applicable)",
            "Data Flow Trace",
            "Pattern Analysis",
            "Hypothesis Testing",
            "Root Cause Summary",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "02-to-be-plan.md": [
            "TODO",
            "Planned Changes by File",
            "Implementation Steps",
            "Testing Strategy",
            "Playwright Plan (if applicable)",
            "Manual QA Scenarios",
            "Idempotence and Recovery",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "03-implementation-summary.md": [
            "TODO",
            "Changes Applied",
            "TDD Compliance Log",
            "Plan Deviations",
            "Implementation Evidence",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "03.5-code-review.md": [
            "TODO",
            "Review Scope",
            "Plan Alignment Assessment",
            "Code Quality Assessment",
            "Issues Found",
            "Verdict",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "04-test-summary.md": [
            "TODO",
            "Pre-Test Implementation Audit",
            "Environment",
            "Execution Mode",
            "Commands Executed (Exact)",
            "Results Summary",
            "Evidence and Artifacts",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
        "05-manual-qa.md": [
            "TODO",
            "QA Scenarios and Results",
            "Evidence and Artifacts",
            "User Sign-Off",
            "Traceability",
            "Coverage Gate",
            "Approval Gate",
        ],
    }
    return section_map.get(file_name, ["TODO", "Coverage Gate", "Approval Gate"])


def get_header_remediation_lines(missing_fields: list[str]) -> list[str]:
    out: list[str] = []
    for field in missing_fields:
        if field == "Run":
            out.append("Run: `/.codex/rlm/<run-id>/`")
        elif field == "Phase":
            out.append("Phase: `<phase name>`")
        elif field == "Status":
            out.append("Status: `DRAFT`")
        elif field == "Inputs":
            out.append("Inputs:")
            out.append("- `<path>`")
        elif field == "Outputs":
            out.append("Outputs:")
            out.append("- `<path>`")
        elif field == "Scope note":
            out.append("Scope note: <one sentence describing what this artifact decides/enables>.")
        elif field == "LockedAt":
            out.append("LockedAt: `YYYY-MM-DDTHH:mm:ssZ`")
        elif field == "LockHash":
            out.append("LockHash: `<sha256-hex>`")
    return out


def lint_artifact_file(file_path: Path, run_dir: Path) -> tuple[int, int]:
    content = file_path.read_text(encoding="utf-8")
    file_name = file_path.name
    status = get_md_field_value(content, "Status") or "UNKNOWN"

    missing_header_fields = [
        field
        for field in ("Run", "Phase", "Status", "Inputs", "Outputs", "Scope note")
        if not has_header_field(content, field)
    ]
    if missing_header_fields:
        write_issue(
            "FAIL",
            file_path,
            f"Missing required header field(s): {', '.join(missing_header_fields)}",
            get_header_remediation_lines(missing_header_fields),
        )
        return 1, 0

    fail_count = 0
    warn_count = 0

    if status not in ("DRAFT", "LOCKED"):
        fail_count += 1
        write_issue(
            "FAIL",
            file_path,
            f"Invalid Status value '{status}' (expected DRAFT or LOCKED)",
            ["Status: `DRAFT`"],
        )

    if status == "LOCKED":
        lock_missing = [field for field in ("LockedAt", "LockHash") if not has_header_field(content, field)]
        if lock_missing:
            fail_count += 1
            write_issue(
                "FAIL",
                file_path,
                f"Status is LOCKED but missing: {', '.join(lock_missing)}",
                get_header_remediation_lines(lock_missing),
            )

    has_todo, _total, _checked, unchecked = get_todo_stats(content)
    if not has_todo:
        fail_count += 1
        write_issue("FAIL", file_path, "Missing required section: ## TODO", ["## TODO", "", "- [ ] <task 1>", "- [ ] <task 2>"])
    elif status == "LOCKED" and unchecked > 0:
        fail_count += 1
        write_issue(
            "FAIL",
            file_path,
            f"LOCKED artifact has unchecked TODO items: {unchecked}",
            ["# Option A: check all TODO boxes under ## TODO", "# Option B: set Status back to `DRAFT` until TODOs are complete"],
        )

    for heading in get_artifact_required_sections(file_name):
        if not has_heading(content, heading):
            fail_count += 1
            write_issue("FAIL", file_path, f"Missing required section heading: ## {heading}", [f"## {heading}", "", "<content>"])

    for gate in ("Coverage", "Approval"):
        if not has_gate_line(content, gate):
            fail_count += 1
            write_issue("FAIL", file_path, f"Missing required gate line: {gate}: PASS|FAIL", [f"{gate}: FAIL"])

    if file_name in ("04-test-summary.md", "05-manual-qa.md"):
        evidence_dir = run_dir / "evidence"
        required_subdirs = ("screenshots", "logs", "perf", "traces")
        if not evidence_dir.exists():
            warn_count += 1
            remediation = [
                f'mkdir -p "{evidence_dir / "screenshots"}"',
                f'mkdir -p "{evidence_dir / "logs"}"',
                f'mkdir -p "{evidence_dir / "perf"}"',
                f'mkdir -p "{evidence_dir / "traces"}"',
                f'mkdir -p "{evidence_dir / "other"}"',
            ]
            write_issue("WARN", file_path, f"Evidence directory missing at {evidence_dir}", remediation)
        else:
            missing_subdirs = [s for s in required_subdirs if not (evidence_dir / s).exists()]
            if missing_subdirs:
                warn_count += 1
                remediation = [f'mkdir -p "{evidence_dir / s}"' for s in missing_subdirs]
                write_issue(
                    "WARN",
                    file_path,
                    f"Evidence subfolder(s) missing under {evidence_dir}: {', '.join(missing_subdirs)}",
                    remediation,
                )

    return fail_count, warn_count


def main() -> None:
    parser = argparse.ArgumentParser(description="Lint RLM run artifacts.")
    parser.add_argument("--run-id", default="", help="Run ID to lint (default: latest run).")
    parser.add_argument("--repo-root", default=".", help="Repository root path.")
    parser.add_argument("--all-runs", action="store_true", help="Lint all runs under .codex/rlm.")
    parser.add_argument("--strict", action="store_true", help="Treat WARN as FAIL.")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    rlm_root = repo_root / ".codex" / "rlm"
    if not rlm_root.exists():
        print(f"[FAIL] RLM directory not found at: {rlm_root}")
        print("       Is this the project repo root? (Expected .codex/rlm/)")
        sys.exit(1)

    run_dirs: list[Path] = []
    if args.all_runs:
        run_dirs = [p for p in rlm_root.iterdir() if p.is_dir()]
        if not run_dirs:
            print(f"[FAIL] No runs found under: {rlm_root}")
            sys.exit(1)
    elif args.run_id.strip():
        run_dir = rlm_root / args.run_id.strip()
        if not run_dir.exists():
            print(f"[FAIL] Run directory not found: {run_dir}")
            sys.exit(1)
        run_dirs = [run_dir]
    else:
        latest = get_latest_run_directory(rlm_root)
        if latest is None:
            print(f"[FAIL] No runs found under: {rlm_root}")
            sys.exit(1)
        run_dirs = [latest]

    total_fail = 0
    total_warn = 0
    artifacts = [
        "00-requirements.md",
        "00-worktree.md",
        "01-as-is.md",
        "01.5-root-cause.md",
        "02-to-be-plan.md",
        "03-implementation-summary.md",
        "03.5-code-review.md",
        "04-test-summary.md",
        "05-manual-qa.md",
    ]

    for run_dir in run_dirs:
        print(f"Linting run: {run_dir.name}")
        print(f"Path: {run_dir}")
        print()

        for artifact in artifacts:
            artifact_path = run_dir / artifact
            if not artifact_path.exists():
                print(f"[WARN] Missing artifact (ok if not reached yet): {artifact_path}")
                total_warn += 1
                continue

            fail_count, warn_count = lint_artifact_file(artifact_path, run_dir)
            total_fail += fail_count
            total_warn += warn_count

        addenda_dir = run_dir / "addenda"
        if addenda_dir.exists():
            for addendum in sorted(addenda_dir.glob("*.md")):
                fail_count, warn_count = lint_artifact_file(addendum, run_dir)
                total_fail += fail_count
                total_warn += warn_count

        print("----")
        print()

    print("Summary")
    print(f"- FAIL: {total_fail}")
    print(f"- WARN: {total_warn}")
    print()

    effective_fail = total_fail + (total_warn if args.strict else 0)
    if effective_fail > 0:
        print("[FAIL] Lint failed")
        sys.exit(1)

    print("[OK] Lint passed")
    sys.exit(0)


if __name__ == "__main__":
    main()

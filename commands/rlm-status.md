---
name: /rlm:status
description: Check status of current RLM run - shows active phase, lock status, and next steps
disable-model-invocation: false
---

# /rlm:status - Check RLM Run Status

## Usage

```
/rlm:status [run-id]
```

## Arguments

- `run-id` (optional) - Specific run to check. Defaults to most recent.

## Description

Displays comprehensive status of an RLM run:

- Current phase and status (DRAFT/LOCKED)
- Lock chain validation
- Coverage/Approval gate status
- Next steps
- Recent activity

## Output Format

```
RLM Run: 2026-02-21-user-auth
========================

Phase Status:
  Phase 0 (Requirements)     ✅ LOCKED
  Phase 1 (AS-IS)           ✅ LOCKED
  Phase 1.5 (Root Cause)     ⏭️  SKIPPED (not needed)
  Phase 2 (TO-BE Plan)      📝 DRAFT
  Phase 3 (Implementation)  ⏳ PENDING
  Phase 4 (Test Summary)    ⏳ PENDING
  Phase 5 (Manual QA)       ⏳ PENDING

Current Phase: 2 (TO-BE Plan)
Status: DRAFT

Next Steps:
  1. Complete plan in 02-to-be-plan.md
  2. Ensure Coverage Gate: PASS
  3. Ensure Approval Gate: PASS
  4. Lock phase to proceed

Quick Command:
  Implement requirement '2026-02-21-user-auth'
```

## Implementation

1. Scan `.codex/rlm/<run-id>/` directory
2. Check each phase artifact for existence and lock status
3. Validate lock chain
4. Identify current active phase
5. Display status with clear indicators


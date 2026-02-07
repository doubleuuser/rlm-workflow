# RLM Artifact Template

Use this template for any per-run phase artifact (`00` through `05`) and for addenda.

## Required Header

```md
Run: `/.codex/rlm/<run-id>/`
Phase: `0N <phase-name>`
Status: `DRAFT`
Inputs:
- `/<path-to-input-1>`
- `/<path-to-input-2>`
Outputs:
- `/<path-to-this-output>`
Scope note: One short paragraph describing what this artifact decides or enables.
```

When locking, append:

```md
LockedAt: `YYYY-MM-DDTHH:MM:SSZ`
LockHash: `<sha256-hex>`
```

## Required Sections

```md
## Traceability

- `R1` -> [where addressed in this artifact, planned evidence or concrete evidence]
- `R2` -> ...

## Coverage Gate

- Input set reviewed:
  - list all base inputs and addenda used as effective input
- Requirement coverage:
  - `R1`: Covered at ...
  - `R2`: Covered at ...
- Deferrals (if any):
  - `R#`: deferred because ..., impact ...

Coverage: PASS
```

```md
## Approval Gate

- Objective checks:
  - [example: commands are runnable]
  - [example: planned/actual tests are specified and pass]
  - [example: output is reproducible and unambiguous]

Approval: PASS
```

If either gate fails, use `FAIL` and explicitly list missing items and required fixes.

## Hash Commands

PowerShell:

```powershell
(Get-FileHash -Algorithm SHA256 '.codex/rlm/<run-id>/<artifact>.md').Hash.ToLower()
```

Shell:

```bash
sha256sum .codex/rlm/<run-id>/<artifact>.md
```


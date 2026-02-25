# RLM Rationalization Tables

**Use this reference when you find yourself making excuses to skip process steps.**

These tables document common cognitive biases and rationalizations that lead to cutting corners. When you recognize a thought from the left column, read the reality on the right and follow the process.

---

## Universal Rationalizations (All Phases)

| Excuse | Reality |
|--------|---------|
| "This requirement is simple, I don't need all these phases" | Simple changes are where assumptions cause the most wasted work. Short phases are fast. |
| "I can skip ahead and come back" | You won't come back. Do it now while context is fresh. |
| "The phases are overkill for this project" | The phases exist to prevent failures. They take less time than fixing failures. |
| "I'll document it later" | Later never comes. Document now or it doesn't exist. |
| "I remember what we decided" | Memory is unreliable. Lock it in the artifact. |
| "This is just a temporary fix" | Temporary fixes become permanent. Do it right. |
| "The user trusts me to skip steps" | The user trusts you to follow the process that ensures quality. |
| "I know the process, I don't need to read the skill" | Skills evolve. Read the current version. Violating letter = violating spirit. |
| "This feels productive" | Undisciplined action wastes time. Process prevents thrashing. |
| "I'm different/special/experienced" | The process applies to everyone. Experience doesn't exempt you from discipline. |

---

## Phase 1: Requirements Rationalizations

| Excuse | Reality |
|--------|---------|
| "The requirements are obvious" | Obvious to you ≠ obvious to others. Write them down. |
| "I'll figure out acceptance criteria as I go" | Without criteria, you can't know when you're done. |
| "We don't need requirement IDs" | IDs enable mechanical traceability. Without them, coverage is unprovable. |
| "Out of scope is obvious" | Scope creep is real. Document what's OUT to protect against it. |
| "Constraints will become clear later" | Constraints change design. Discover them now, not after implementation. |
| "I can just ask the user what they want" | Each round-trip costs hours. Batch questions, document answers. |

---

## Phase 2: AS-IS Analysis Rationalizations

| Excuse | Reality |
|--------|---------|
| "I already know how it works" | You know how you THINK it works. Verify with evidence. |
| "The current behavior is obvious" | Write it down. Future you will thank present you. |
| "I don't need repro steps" | Without repro steps, you can't verify the fix later. |
| "Code pointers are in my IDE" | IDE context is ephemeral. Document pointers in the artifact. |
| "Known unknowns are for beginners" | Experts know what they don't know. Document gaps explicitly. |
| "AS-IS analysis is overhead" | 15 minutes of analysis saves hours of wrong fixes. |

---

## Phase 1.5: Root Cause Analysis Rationalizations (Debug Mode)

| Excuse | Reality |
|--------|---------|
| "I can see the problem, let me just fix it" | Seeing symptoms ≠ understanding root cause. Fix at source, not symptom. |
| "Quick fix first, investigate later" | "Later" never happens. Do it right from the start. |
| "I don't have time for systematic debugging" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "The error message tells me exactly what's wrong" | Error messages show symptoms. Trace to find the source. |
| "One fix attempt is enough if I'm careful" | First attempts often fail. The process anticipates iteration. |
| "I'll add logging to understand it" | Logging is good. But don't stop there - trace the data flow. |
| "It's a race condition, can't reproduce reliably" | Intermittent bugs need MORE investigation, not less. |
| "The previous developer made a mistake" | Blame doesn't fix bugs. Understanding does. |

---

## Phase 3: TO-BE Plan Rationalizations

| Excuse | Reality |
|--------|---------|
| "I know what to do, I don't need a detailed plan" | Plans are for coordination and verification. Write it down. |
| "The plan will become clear as I implement" | That's called "making it up as you go" - it produces bugs. |
| "Concrete file paths are too specific" | Specificity prevents errors. "The file" is ambiguous. |
| "I'll figure out test commands later" | Testing is part of the plan. Include exact commands now. |
| "Sub-phases are overkill for this" | Large changes without sub-phases are risky. Use them. |
| "Playwright tests can wait" | E2E tests are your regression safety net. Plan them now. |
| "Manual QA is not needed for this change" | Automated ≠ user-validated. Always include manual QA. |
| "Idempotence doesn't matter" | You'll run this more than once. Plan for re-run safety. |

---

## Phase 4: Implementation Rationalizations

### TDD-Specific

| Excuse | Reality |
|--------|---------|
| "This is just a simple fix, no test needed" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after confirming the fix works" | Tests passing immediately prove nothing. You never saw it catch the bug. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "I already manually tested it" | Ad-hoc != systematic. No record, can't re-run, no regression protection. |
| "Deleting working code is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "TDD is dogmatic, I'm being pragmatic" | TDD IS pragmatic. Finds bugs before commit, enables refactoring. |
| "I'll keep the code as reference" | You'll adapt it. That's testing after. Delete means delete. |
| "Test hard = design unclear" | Listen to the test. Hard to test = hard to use. Simplify design. |
| "I need to explore first" | Fine. Throw away exploration, start TDD fresh. |
| "This is different because..." | It's not. The rules don't have exceptions. |
| "The test passes immediately, that's good" | Immediate pass = not testing what you think. Fix the test. |
| "I can add tests in Phase 5" | Phase 3 requires TDD. Phase 4 validates. Phase 5 is manual QA. Don't defer. |

### Implementation-General

| Excuse | Reality |
|--------|---------|
| "The plan is just a guideline" | The plan is a commitment. Deviations need documentation. |
| "I found a better way while coding" | Better ways discovered during implementation go in addenda, not immediate changes. |
| "YAGNI doesn't apply here" | YAGNI always applies. You aren't gonna need it. |
| "I'll clean it up in refactoring" | Code now, refactor later = technical debt. Write clean code now. |
| "The user won't notice this change" | Every change needs a reason. Document all deviations. |
| "Comments are for beginners" | Comments explain WHY, not what. Everyone needs context. |

---

## Phase 5: Testing Rationalizations

| Excuse | Reality |
|--------|---------|
| "The tests I wrote pass, that's enough" | Tier B regression tests catch what you broke unknowingly. |
| "Playwright is too slow" | Slow now is faster than debugging production later. |
| "Flaky tests are just the test environment" | Flaky tests hide real bugs. Fix the flake or the test. |
| "I'll document the test results from memory" | Memory is fallible. Copy-paste actual output. |
| "One test run is enough" | Rerun failures to distinguish flaky from deterministic. |
| "The build passes, so tests aren't needed" | Build ≠ behavior. Tests verify behavior. |
| "Coverage metrics are good enough" | Coverage ≠ correctness. Verify actual behavior. |

---

## Phase 6: Manual QA Rationalizations

| Excuse | Reality |
|--------|---------|
| "Automated tests cover everything" | Automated ≠ user-validated. Users find what you missed. |
| "I tested it manually while developing" | Development testing ≠ systematic QA. Follow the scenarios. |
| "The user can test it after release" | QA now prevents production incidents. |
| "Manual QA is bureaucracy" | 5 minutes of QA saves hours of incident response. |
| "I'll sign off without actually testing" | Your signature means you verified. Verify, then sign. |
| "The scenarios are too basic" | Basic scenarios catch basic bugs. Run them. |

---

## Phase 6/7: Documentation Rationalizations

| Excuse | Reality |
|--------|---------|
| "DECISIONS.md will get too long" | DECISIONS.md is append-only by design. Length is fine. |
| "STATE.md is just overhead" | STATE.md is the single source of truth for current behavior. |
| "I documented it in the commit message" | Commit messages are buried. DECISIONS.md is discoverable. |
| "Future developers can read the code" | Code shows what, not why. Document the why. |
| "The run folder has all the details" | Run folders are archives. DECISIONS.md is the index. |

---

## Locking & Immutability Rationalizations

| Excuse | Reality |
|--------|---------|
| "I need to fix something in the locked artifact" | Locked means locked. Use an addendum in the current phase. |
| "The lock is just bureaucratic" | Locks preserve audit trails and prevent drift. |
| "I'll update the hash after editing" | That's tampering. Never edit locked artifacts. |
| "Addenda are too much overhead" | Addenda preserve history. History is valuable. |
| "No one will notice a small edit" | Integrity matters. Follow the process. |

---

## Single-Command Orchestration Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll run phases manually for more control" | Manual execution skips gates and consistency checks. |
| "I can skip Phase X because..." | No you can't. The phases are sequential for a reason. |
| "I'll create Phase 4 before Phase 3 is locked" | Parallel phase work is forbidden. Complete phases in order. |
| "The orchestrator is just automation" | The orchestrator enforces discipline. Use it. |

---

## How to Use These Tables

### For Individual Contributors

1. **When you catch yourself thinking an excuse:**
   - Pause
   - Find the excuse in these tables
   - Read the reality
   - Follow the process

2. **When reviewing work:**
   - Look for signs of skipped steps
   - Reference these tables to explain why process matters
   - Require compliance before approval

### For Team Leads

1. **Add to AGENTS.md:**
   ```markdown
   ## Rationalization Awareness
   
   When you find yourself thinking "this is different because..." 
   or "I can skip this step," reference `references/rationalizations.md`.
   
   Common traps:
   - "This is simple" -> Simple is where assumptions live
   - "I'm experienced" -> Experience doesn't exempt discipline
   - "I'll do it later" -> Later never comes
   ```

2. **In Phase Reviews:**
   - Check artifacts for completeness
   - If gates are claimed PASS but evidence is thin, reference relevant rationalization
   - Require specific evidence, not assertions

### In Code Reviews

```markdown
**Process Check:** This change appears to skip [step]. 

Reference: `references/rationalizations.md` - Section [X]

The reality check: [quote from table]

Required: [specific fix to follow process]
```

---

## The Meta-Rationalization

| Excuse | Reality |
|--------|---------|
| "These rationalization tables are overkill" | Rationalizing about rationalizations is peak self-deception. Read the tables. |

---

## References

- **SEE ALSO:** `skills/rlm-worktree/SKILL.md` - Worktree isolation-specific rationalizations
- **SEE ALSO:** `skills/rlm-tdd/SKILL.md` - TDD-specific rationalizations
- **SEE ALSO:** `skills/rlm-debugging/SKILL.md` - Debugging-specific rationalizations
- **SEE ALSO:** `skills/rlm-subagent/SKILL.md` - Parallel execution-specific rationalizations
- **APPLIES TO:** All RLM phases and activities


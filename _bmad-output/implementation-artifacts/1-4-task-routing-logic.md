# Story 1.4: Task Routing Logic

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to intelligently decide between Quick Flow and Full Method,
so that simple tasks don't get over-engineered and complex tasks get proper planning.

## Acceptance Criteria

1. **Given** `state.yaml` has `route: null` (no override flag was used)
   **When** the orchestrator agent launches for the first time
   **Then** it analyzes the task description and sets `route` to either `quick` or `full`

2. **Given** a task description like "Fix the login button styling on the dashboard"
   **When** the routing analysis runs
   **Then** the route is set to `quick` (single-file, well-defined, narrow scope)

3. **Given** a task description like "Build a notification system with email and push support, batching, and user preferences"
   **When** the routing analysis runs
   **Then** the route is set to `full` (multi-component, architectural impact, ambiguous scope)

4. **Given** `state.yaml` already has `route: quick` or `route: full` (override flag was used)
   **When** the orchestrator agent launches
   **Then** it skips routing analysis and respects the existing route value

5. **Given** routing is determined
   **When** the orchestrator updates state
   **Then** `state.yaml` reflects the route decision and `currentStage` is set to the first stage of the chosen track (`prd` for full, `quick-spec` for quick)

## Tasks / Subtasks

- [x] Task 1: Implement routing logic in the orchestrator agent definition (AC: #1, #2, #3, #4)
  - [x] 1.1: Modify `.claude/agents/bmad-orchestrator.md` Section 1.2 — replace the `currentStage is null` placeholder (currently exits with code 1 and "Routing not yet implemented") with actual routing logic
  - [x] 1.2: Implement the routing decision algorithm — analyze the `task` field from state.yaml and determine `quick` vs `full` based on these guidelines:
    - **Quick Flow indicators:** single-file changes, bug fixes, small utilities, well-defined narrow tasks, specific file references, styling fixes, typo corrections, simple refactors
    - **Full Method indicators:** multi-component features, new systems, architectural changes, ambiguous scope, multi-domain integration, user-facing features requiring design, database schema changes, API design
  - [x] 1.3: Implement the override bypass — when `route` is already set to `quick` or `full` (not `null`), skip routing analysis entirely and proceed with existing route
  - [x] 1.4: After routing decision, set `currentStage` to the first stage of the chosen track: `prd` for `full`, `quick-spec` for `quick`

- [x] Task 2: Implement state update after routing (AC: #5)
  - [x] 2.1: After determining route and first stage, perform atomic state update:
    - Set `route` to the determined value (`quick` or `full`)
    - Set `currentStage` to the first stage of the chosen track
    - Update `updatedAt` to current ISO-8601 timestamp
    - Preserve all other fields exactly
  - [x] 2.2: Use the atomic write pattern: write to `state.yaml.tmp` then `mv` to `state.yaml`
  - [x] 2.3: After state update, proceed to template loading (Section 3) for the newly set `currentStage` — do NOT exit; continue the current stage execution within the same Ralph Loop iteration

- [x] Task 3: Write tests for routing logic (AC: #1-#5)
  - [x] 3.1: Add bats tests to `tests/orchestrator-agent.bats` validating:
    - Agent definition contains routing decision logic (not the old placeholder)
    - Quick Flow routing guidelines are present in the agent definition
    - Full Method routing guidelines are present in the agent definition
    - Override bypass logic is documented (skip routing when route != null)
    - First stage mapping: `full` -> `prd`, `quick` -> `quick-spec`
  - [x] 3.2: Verify existing tests still pass (zero regressions on all 46 existing tests)

## Dev Notes

### Architecture Compliance

**This story modifies exactly 1 file:**
- `.claude/agents/bmad-orchestrator.md` — Replace the routing placeholder with actual routing logic

**This is an agent definition modification, NOT a bash script.** The routing logic is embedded in the orchestrator agent's prompt instructions. When the agent launches and finds `currentStage: null` and `route: null`, it uses LLM judgment to analyze the task description and decide the track.

**Critical understanding:** The routing is an LLM judgment call, not a rule engine. The guidelines in the agent definition tell the LLM what signals to look for when deciding. The LLM reads the task description and makes a decision based on the routing guidelines embedded in its instructions.

### What Currently Exists (Section 1.2 of bmad-orchestrator.md)

The current placeholder at Section 1.2, point 1:

```markdown
1. **If `currentStage` is `null`:** Routing has not happened yet. This means Story 1.4 (task routing logic) is needed. Exit with code 1 and log: "Routing not yet implemented — currentStage is null. Run routing first (Story 1.4)."
```

This entire block must be replaced with the routing logic. After routing:
- If `route` was already set (override): skip routing, set `currentStage` to first stage of that track, proceed to template loading
- If `route` is `null`: analyze task, determine route, set `currentStage`, update state atomically, proceed to template loading

### Routing Guidelines (from Architecture)

From architecture.md Section "Routing Logic":
- **Location:** In the orchestrator agent prompt, not a config file
- **Method:** LLM judgment call analyzing the task description
- **Quick Flow:** single-file changes, bug fixes, small utilities, well-defined narrow tasks
- **Full Method:** multi-component features, new systems, architectural changes, ambiguous scope
- **Overrides:** `--quick` and `--full` flags bypass LLM routing entirely

### State Update Flow After Routing

1. Routing determines `route` value (`quick` or `full`)
2. Map route to first stage: `full` -> `prd`, `quick` -> `quick-spec`
3. Atomic state update: set `route`, `currentStage`, `updatedAt`
4. **Continue execution** — do NOT exit with code 0 after routing. The routing and first stage execution happen in the same Ralph Loop iteration. After updating state with the route and first stage, proceed directly to Section 3 (Template Loading) to execute the first stage.

### Previous Story Intelligence

**Story 1.3 (Orchestrator Agent — Cold Start & State Management):**
- Created `.claude/agents/bmad-orchestrator.md` — 308-line comprehensive agent definition
- Section 1.2 "Determine What To Do" has 5 conditional branches; point 1 is the routing placeholder to replace
- Section 7.2 documents the atomic write pattern
- Section 2 documents pipeline stage sequences (Full Method and Quick Flow tracks)
- Code review fixes added `paused` status handling, CONCERNS quality gate, story loop iteration logic
- 46 bats tests in `tests/orchestrator-agent.bats`
- **Key learning:** Agent definitions are markdown prompt templates — changes are textual, not code compilation
- **Key learning:** The agent definition must be self-contained; every launch is a cold start from state.yaml

**Story 1.2 (Ralph Loop):**
- `loop.sh` dispatches on exit codes 0/1/2/3
- After routing + first stage execution complete in one iteration, exit code 0 causes relaunch for next stage
- **Key learning:** One Ralph Loop iteration = one complete pipeline stage with all back-and-forth

**Story 1.1 (Slash Command):**
- Sets `route: null` when no override flag; `route: quick|full` when flags used
- Sets `currentStage: null` always (routing determines first stage)
- This is the exact state the routing logic will encounter on first launch

### Git Intelligence

Recent commits:
- `8df8ddb` feat: implement orchestrator agent definition (story 1-3)
- `d2d8545` feat: implement Ralph Loop script (story 1-2)
- `58b1dd1` added orchestrate claude command

**Patterns established:**
- Commit messages follow `feat:` / `fix:` prefixes
- Tests use bats framework in `tests/` directory
- Agent definitions are markdown files checked into `.claude/agents/`

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — Modified by this story (routing logic added to Section 1.2)
- `tests/orchestrator-agent.bats` — Modified to add routing-specific tests
- No new files created; this is purely a modification story
- Alignment with project structure: all changes stay within existing file boundaries

### Anti-Patterns to Avoid

- Creating a separate routing config file or script — routing lives IN the agent definition
- Implementing routing as deterministic rules — it's LLM judgment with guidelines
- Exiting with code 0 after routing without executing the first stage — routing + first stage = one iteration
- Modifying `loop.sh` — the loop script is not touched by this story
- Modifying the slash command — the slash command already handles override flags correctly
- Adding new stage identifiers — use only the frozen identifiers
- Breaking the existing 46 bats tests

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Routing Logic] — LLM judgment with Quick/Full guidelines
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — State file fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Pipeline Stage Sequences] — prd first for full, quick-spec first for quick
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] — Atomic writes, naming
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4] — Full acceptance criteria
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5] — Next story (first stage template), depends on routing working
- [Source: _bmad-output/project-context.md] — All implementation rules
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — prd, quick-spec
- [Source: _bmad-output/project-context.md#State File Rules] — Atomic writes, camelCase
- [Source: _bmad-output/implementation-artifacts/1-3-orchestrator-agent-cold-start-state-management.md] — Previous story, current agent definition structure
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] — Current placeholder to replace
- [Source: .claude/commands/bmad-orchestrate.md] — Slash command sets route: null / currentStage: null

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None required — straightforward text modification and test addition.

### Completion Notes List

- Replaced Section 1.2 point 1 routing placeholder with full Routing Protocol (steps a–e)
- Routing protocol includes: override bypass, LLM routing decision with quick/full signal guidelines, first stage mapping, atomic state update, continue-to-template-loading instruction
- Added 7 new bats tests (tests 47–53) covering all routing acceptance criteria
- All 53 tests pass (46 existing + 7 new), zero regressions
- Only modified 2 files as expected: agent definition and test file
- **Code review additions:** Quick signals include `configuration tweaks` and `documentation updates`; Full signals include `features requiring multiple coordinated artifacts` — intentional enhancements beyond story spec to improve LLM routing accuracy
- **Code review fix (M3):** Reordered Section 1.2 so terminal states (completed/failed/paused) are checked before routing — prevents routing attempt on a failed pipeline
- **Code review fix (M2):** Added test 1.4-8 for "default to full when uncertain" safety heuristic
- **Code review fix (M3):** Added test 1.4-9 verifying terminal state checks precede routing

### Change Log

- 2026-02-03: Implemented task routing logic — replaced placeholder in Section 1.2 with Routing Protocol, added 7 bats tests
- 2026-02-03: Code review fixes — reordered Section 1.2 (terminal states before routing), added 2 new tests (safety heuristic + ordering), documented extra routing signals

### File List

- `.claude/agents/bmad-orchestrator.md` — Modified Section 1.2: replaced routing placeholder with full Routing Protocol; reordered conditional checks (terminal states before routing)
- `tests/orchestrator-agent.bats` — Added 9 new routing tests (Routing 1.4-1 through 1.4-9)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — Updated story status to `review`

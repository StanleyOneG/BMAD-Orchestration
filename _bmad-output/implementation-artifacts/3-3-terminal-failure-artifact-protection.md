# Story 3.3: Terminal Failure & Artifact Protection

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the pipeline to stop cleanly when recovery is impossible and my existing work to be protected from accidental overwrite,
so that I never lose completed artifacts and always know when to intervene manually.

## Acceptance Criteria

1. **Given** `currentRetries` reaches `maxRetries` for a stage
   **When** the orchestrator evaluates the retry count
   **Then** it sets `status: failed` in `state.yaml` and exits with code 1

2. **Given** the pipeline transitions to `status: failed`
   **When** the agent exits
   **Then** `state.yaml` accurately reflects all completed stages, the failed stage, and the complete failure history

3. **Given** a fresh run (`runType: fresh`) is initiated via `/bmad-orchestrate`
   **When** existing artifacts are detected in `_bmad-output/` or an existing `state.yaml` is found
   **Then** the command fails with a clear error: "Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first."

4. **Given** a resume run (`runType: resume`) is initiated
   **When** existing artifacts and `state.yaml` are found
   **Then** the orchestrator respects all existing artifacts, does not overwrite them, and continues from the last completed stage

5. **Given** a stage partially completed before failure
   **When** the orchestrator evaluates artifacts on resume
   **Then** partial artifacts from the failed stage are not treated as complete -- the stage is re-run from the beginning

## Tasks / Subtasks

- [x] Task 1: Validate terminal failure flow in orchestrator agent (AC: #1, #2)
  - [x] 1.1: Review Section 5.5 (On Verification Fail) — confirm `currentRetries >= maxRetries` triggers `status: failed` and exit code 1
  - [x] 1.2: Review Section 6 (Failure Handling) — confirm retry exhaustion sets `status: failed` and exits with code 1
  - [x] 1.3: Verify that when `status: failed` is set, the state file preserves ALL fields: `completedStages` (what succeeded), `currentStage` (what failed), `failures` array (full failure history), `currentRetries`, `storyLoop` progress
  - [x] 1.4: Trace the complete terminal failure flow end-to-end: stage fails → Section 5.5 → failures array appended → currentRetries incremented → currentRetries >= maxRetries → status: failed → atomic write → exit code 1 → loop.sh stops with FAILED report
  - [x] 1.5: If any gaps found in 1.1-1.4, update `.claude/agents/bmad-orchestrator.md` to close them

- [x] Task 2: Enhance artifact overwrite protection in slash command (AC: #3)
  - [x] 2.1: Review Step 3 (Artifact Overwrite Protection) in `.claude/commands/bmad-orchestrate.md` — currently checks only for `state.yaml` existence
  - [x] 2.2: Enhance Step 3 to ALSO check for existing `_bmad-output/` artifacts on fresh runs. If `_bmad-output/planning-artifacts/` or `_bmad-output/implementation-artifacts/` contain files AND `state.yaml` exists, fail with the error message: "Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first."
  - [x] 2.3: CRITICAL DESIGN DECISION: The current Step 3 only checks `state.yaml`. The AC says "existing artifacts are detected in `_bmad-output/` OR an existing `state.yaml` is found." This means the check should be: `state.yaml` exists OR `_bmad-output/` has orchestrator-produced artifacts. Update accordingly.
  - [x] 2.4: Define what counts as "orchestrator-produced artifacts" to avoid false positives from pre-existing project files: check for `.bmad-orchestrator/state.yaml` (primary signal) OR `.bmad-orchestrator/status-report.md` (secondary signal). The `_bmad-output/` check is an additional safety net: if `_bmad-output/planning-artifacts/prd.md` exists (a known orchestrator artifact), warn the user.

- [x] Task 3: Validate resume artifact respect in orchestrator agent (AC: #4)
  - [x] 3.1: Review Section 1.4 (Resume Behavior) in orchestrator agent — confirm it describes artifact respect on resume
  - [x] 3.2: Verify the orchestrator's cold-start flow (Section 1.2) correctly handles `runType: resume` by trusting `completedStages` and `currentStage` from state.yaml
  - [x] 3.3: Verify the slash command's Step 2 (Resume Handling) preserves `completedStages`, `currentStage`, `storyLoop`, and `failures` — only modifies `runType`, `updatedAt`, and `status`
  - [x] 3.4: If any gaps found, update orchestrator agent and/or slash command

- [x] Task 4: Enhance partial artifact handling on resume (AC: #5)
  - [x] 4.1: Analyze the current verification pattern (Section 5) — does the artifact check (Section 5.1) effectively handle partial artifacts? If a stage partially produced artifacts before crashing, the next run would: cold start → read state → currentStage unchanged (still the failed stage) → load template → pre-validate requiredArtifacts → launch sub-agent → sub-agent regenerates artifacts from its workflow
  - [x] 4.2: Document the key insight: partial artifacts are handled IMPLICITLY because the orchestrator never marks a stage as completed if verification hasn't passed. On resume, `currentStage` is still the failed stage, so it re-runs from the beginning. The sub-agent workflows are designed to overwrite their own output.
  - [x] 4.3: Add explicit documentation to the orchestrator agent clarifying partial artifact behavior — add a note to Section 1.4 (Resume Behavior) or create a new subsection explaining that partial artifacts from a failed stage are overwritten when the stage re-runs, because `completedStages` never included the failed stage and `currentStage` points to it for re-execution
  - [x] 4.4: Edge case: What if a stage produced SOME of its `producedArtifacts` but not all? On retry, the sub-agent reruns its workflow from scratch (it has no memory). The produced artifacts are overwritten by the new run. This is safe because: (a) the stage was never marked complete, (b) the sub-agent workflow produces all outputs or none.

- [x] Task 5: Write bats tests for terminal failure and artifact protection (AC: #1, #2, #3, #4, #5)
  - [x] 5.1: Add tests to `tests/orchestrator-agent.bats` validating terminal failure in the orchestrator agent:
    - Agent describes maxRetries check triggering terminal failure
    - Agent describes status: failed on retry exhaustion
    - Agent describes exit code 1 for terminal failure
    - Agent describes state preservation on failure (completedStages, currentStage, failures, storyLoop)
  - [x] 5.2: Add tests validating artifact overwrite protection in slash command:
    - Slash command describes Step 3 artifact overwrite protection
    - Slash command checks for state.yaml existence
    - Slash command describes error message for existing artifacts on fresh run
    - Slash command describes enhanced check including _bmad-output/ artifacts
  - [x] 5.3: Add tests validating resume artifact respect:
    - Orchestrator describes resume behavior respecting existing artifacts
    - Orchestrator describes completedStages trust on resume
    - Slash command preserves state fields on resume (only modifies runType, updatedAt, status)
  - [x] 5.4: Add tests validating partial artifact handling:
    - Orchestrator describes that failed stages are re-run (currentStage unchanged)
    - Orchestrator describes that completedStages never includes a stage that didn't pass verification
    - Orchestrator describes implicit partial artifact handling through re-execution
  - [x] 5.5: Add tests validating loop.sh terminal failure handling:
    - Loop script handles exit code 1 (stop with FAILED status report)
    - Loop script captures failure details in status report
    - Loop script does NOT relaunch after exit code 1
  - [x] 5.6: Use test naming pattern: `@test "Terminal 3.3-N: description"` for all tests
  - [x] 5.7: Verify all existing tests still pass (zero regressions on all 298 existing tests)

- [ ] Task 6: Manual verification (AC: #1, #2, #3, #4, #5) -- MANUAL
  - [ ] 6.1: Verify the orchestrator agent describes complete terminal failure flow from retry exhaustion through exit code 1
  - [ ] 6.2: Verify the slash command describes enhanced artifact overwrite protection for fresh runs
  - [ ] 6.3: Verify resume flow preserves all existing artifacts and state
  - [ ] 6.4: Trace a hypothetical partial artifact scenario end-to-end through documentation
  - [ ] 6.5: Verify loop.sh stops cleanly on exit code 1 with FAILED report

## Dev Notes

### Architecture Compliance

**This story modifies 1-2 existing files and creates 0 new files:**
- `.claude/commands/bmad-orchestrate.md` -- **MODIFIED** -- Enhance Step 3 (Artifact Overwrite Protection) to check for `_bmad-output/` artifacts in addition to `state.yaml`
- `.claude/agents/bmad-orchestrator.md` -- **POTENTIALLY MODIFIED** -- Add explicit partial artifact handling documentation to Section 1.4 (Resume Behavior). May not need changes if terminal failure flow is already complete.
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add terminal failure, artifact protection, and resume tests (~25-35 new tests)

**No new files created.** Terminal failure and artifact protection are enhancements to existing components, not new components.

### What Makes This Story UNIQUE

**Story 3.3 covers TWO distinct capabilities:**

1. **Terminal failure (AC #1, #2):** When retries are exhausted, the pipeline stops cleanly with full state preservation. This is the END of the failure recovery chain: 3.1 (same-stage retry) -> 3.2 (upstream re-routing) -> 3.3 (terminal failure when nothing works).

2. **Artifact protection (AC #3, #4, #5):** Preventing data loss by blocking fresh runs when previous artifacts exist, respecting existing artifacts on resume, and handling partial artifacts from failed stages.

**Most of the terminal failure logic is ALREADY IMPLEMENTED** (Section 5.5, Section 6). The primary work is:
- Validating completeness and closing any documentation gaps
- Enhancing the slash command's artifact overwrite protection
- Adding explicit partial artifact handling documentation
- Comprehensive testing

### Current Implementation -- What Already Exists

**Terminal failure (orchestrator agent):**
- Section 5.5: `currentRetries >= maxRetries` -> `status: failed`, exit code 1 -- COMPLETE
- Section 6: `status: failed` exit code 1 -- COMPLETE
- Section 7.1: State update preserves all fields -- COMPLETE
- Section 7.2: Atomic write ensures consistency -- COMPLETE

**Artifact overwrite protection (slash command):**
- Step 3: Checks if `state.yaml` exists on fresh runs -- PARTIAL (only checks state.yaml, not _bmad-output/)
- Step 2: Resume handling preserves existing state -- COMPLETE (only modifies runType, updatedAt, status)

**Resume artifact respect (orchestrator agent):**
- Section 1.4: Resume behavior documented -- COMPLETE (trusts completedStages, currentStage)
- Section 1.2: Cold start reads state and continues from currentStage -- COMPLETE

**Loop.sh terminal failure handling:**
- Exit code 1 -> write FAILED status report -> stop -- COMPLETE
- Exit code dispatch fully implemented -- COMPLETE

**What's MISSING (the gaps this story fills):**
- Slash command Step 3 only checks `state.yaml`, not `_bmad-output/` artifacts (partial implementation of AC #3)
- No explicit documentation about partial artifact handling on resume (AC #5 is handled implicitly but not documented)
- No dedicated tests for terminal failure flow, artifact protection, or partial artifact handling

### GAP -- Artifact Overwrite Protection Enhancement

**The key enhancement:** The current slash command Step 3 checks ONLY for `state.yaml` existence. The epic AC says "existing artifacts are detected in `_bmad-output/` OR an existing `state.yaml` is found." The enhancement should:

1. Keep the existing `state.yaml` check as the PRIMARY signal
2. Add a secondary check: if `.bmad-orchestrator/status-report.md` exists, that also indicates a previous run
3. Add a safety net check: if `_bmad-output/planning-artifacts/prd.md` exists (a well-known orchestrator artifact), warn the user

**DESIGN DECISION -- How aggressive should artifact detection be?**
- **Conservative (recommended):** Check for `state.yaml` OR `status-report.md` as primary signals. Optionally warn about `_bmad-output/` artifacts but don't block on them alone (they could be from manual BMAD usage).
- **Aggressive:** Block if ANY `_bmad-output/` artifacts exist. This could cause false positives with pre-existing projects.
- **Resolution:** Use conservative approach. The `state.yaml` is the definitive signal that an orchestrator run exists. The `_bmad-output/` check should be a warning, not a hard block. Update error message accordingly.

### GAP -- Partial Artifact Handling Documentation

**The current behavior is correct but undocumented.** When a stage partially produces artifacts before crashing:

1. The orchestrator never marked the stage as completed (verification didn't pass)
2. `currentStage` still points to the failed stage
3. On resume, the orchestrator re-runs the failed stage from scratch
4. The sub-agent workflow overwrites any partial artifacts

This implicit handling is correct and safe. The documentation gap is in Section 1.4 (Resume Behavior) -- it should explicitly state this behavior so developers don't try to add complex partial artifact detection logic.

### Interaction with Previous Stories

**Story 3.1 (Failure Detection & Retry):**
- Established the retry flow: failure -> increment currentRetries -> exit 0 for retry
- Story 3.3 validates the terminal case: currentRetries >= maxRetries -> status: failed -> exit 1
- Section 3.4 (Failure Context Construction) is unaffected by this story

**Story 3.2 (Upstream Re-routing):**
- Established re-routing counts against maxRetries
- Terminal failure after re-routing attempts also applies (maxRetries includes re-route attempts)
- Story 3.3 doesn't modify re-routing logic, only validates that terminal failure works correctly even after re-routing

**Story 1.1 (Slash Command):**
- Created the slash command with Step 3 (Artifact Overwrite Protection)
- Story 3.3 enhances Step 3 with additional artifact detection

### Previous Story Intelligence (Stories 3.1 & 3.2)

**Key learnings from Story 3.1:**
- Validation-focused stories: most logic already implemented, story is about validation + gap-filling + testing
- Section 3.4 (Failure Context Construction) was the primary enhancement -- 22 new lines
- 34 tests added, total went from 229 to 263
- Test naming: `@test "Failure 3.1-N: description"`
- Code review found empty-filter edge case -- guard added

**Key learnings from Story 3.2:**
- Added Section 6.5 (Upstream Re-Routing) -- ~40 lines
- Modified Section 7.1 for reRouteOrigin handling
- 35 tests added, total went from 263 to 298
- Test naming: `@test "ReRoute 3.2-N: description"`
- Code review found 5 issues: Section 1.1 field enumeration, Section 6.5 scoping, completedStages duplicates, currentRetries reset, template reference

**Pattern to follow for Story 3.3:**
- Validate existing terminal failure logic before adding anything
- Enhance slash command Step 3 (relatively small change)
- Add partial artifact documentation to Section 1.4 (small addition)
- Tests should validate agent documentation describes the behavior
- Use `@test "Terminal 3.3-N: description"` naming pattern
- Expect ~25-35 new tests

### Git Intelligence

- Recent commits follow pattern: `feat: <description> (story X-Y)`
- Story 3.2 modified 5 files (orchestrator agent, readiness template, story file, sprint-status, tests)
- Total tests: 298, all passing
- Orchestrator agent has been modified in stories 1-3, 1-4, 2-3, 2-4, 2-5, 2-7, 3-1, 3-2
- Slash command has NOT been modified since initial creation (Story 1.1)

### Anti-Patterns to Avoid

- Rewriting existing terminal failure logic (it's likely already correct -- validate first)
- Making artifact protection too aggressive (false positives with pre-existing `_bmad-output/` files from manual BMAD usage)
- Adding complex partial artifact detection logic (implicit re-execution is the correct pattern)
- Breaking existing section numbering in bmad-orchestrator.md
- Changing existing bats tests (only add new ones)
- Multi-line error messages in the failures array (single-line summaries only per architecture)
- Direct writes to state.yaml (always temp-then-rename per Section 7.2)
- Conflating terminal failure with re-routing failure (re-routing feeds INTO terminal failure via maxRetries, but they are separate concepts)

### Project Structure Notes

- `.claude/commands/bmad-orchestrate.md` -- MODIFIED: Enhance Step 3 (Artifact Overwrite Protection) to also check for _bmad-output/ artifacts
- `.claude/agents/bmad-orchestrator.md` -- POTENTIALLY MODIFIED: Add partial artifact handling documentation to Section 1.4
- `tests/orchestrator-agent.bats` -- MODIFIED: Add ~25-35 new tests for terminal failure, artifact protection, resume, and partial artifacts
- No new files created
- All changes in existing files per architecture boundaries

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.3] -- Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 3] -- Failure Recovery & Artifact Safety epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] -- FR27 maps to 3.3 (terminal FAILED status), FR36 maps to 3.3 (artifact overwrite protection on fresh runs), FR37 maps to 3.3 (artifact respect on resume runs)
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] -- failures array, currentRetries, maxRetries, status field values
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] -- 5-step verification flow with pass/fail branches
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] -- Error messages single-line, atomic writes, camelCase YAML fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] -- Exit code convention (1 = failed after retries)
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries] -- Boundary 3: Orchestrator reads _bmad-output/ only for verification
- [Source: _bmad-output/planning-artifacts/prd.md#FR27] -- "Orchestrator can transition to FAILED status when retry limit is exhausted"
- [Source: _bmad-output/planning-artifacts/prd.md#FR36] -- "Orchestrator can detect existing artifacts and prevent accidental overwrite on fresh runs"
- [Source: _bmad-output/planning-artifacts/prd.md#FR37] -- "Orchestrator can respect existing artifacts and continue from them on `--resume` runs"
- [Source: _bmad-output/planning-artifacts/prd.md#NFR5] -- "Partial artifacts from a failed stage must not be treated as complete by subsequent stages"
- [Source: _bmad-output/project-context.md#State File Rules] -- Atomic writes, camelCase fields, single-line errors
- [Source: _bmad-output/project-context.md#Exit Code Convention] -- 0/1/2/3 mapping
- [Source: _bmad-output/project-context.md#Anti-Patterns] -- Writing directly to state.yaml, skipping verification
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.5] -- On Verification Fail: currentRetries >= maxRetries -> status: failed, exit 1
- [Source: .claude/agents/bmad-orchestrator.md#Section 6] -- Failure Handling: retry exhaustion -> status: failed, exit 1
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.1] -- State Update: preserves all fields on update
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.2] -- Atomic Write: temp-then-rename pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.4] -- Resume Behavior: trusts completedStages and currentStage
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] -- Cold Start: handles status=failed by exiting code 1
- [Source: .claude/agents/bmad-orchestrator.md#Section 8] -- Exit Code Protocol: code 1 = failed after retries
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] -- Boundary Rules: never directly write BMAD artifacts
- [Source: .claude/agents/bmad-orchestrator.md#Section 6.5] -- Upstream Re-Routing: re-routes count against maxRetries (feeds into terminal failure)
- [Source: .claude/commands/bmad-orchestrate.md#Step 2] -- Resume Handling: preserves completedStages, currentStage, storyLoop, failures
- [Source: .claude/commands/bmad-orchestrate.md#Step 3] -- Artifact Overwrite Protection: currently checks state.yaml only
- [Source: .claude/commands/bmad-orchestrate.md#Step 4] -- State creation: maxRetries: 3, failures: [], currentRetries: 0
- [Source: .bmad-orchestrator/loop.sh#handle_exit_code] -- Exit code 1 -> FAILED status report -> stop loop
- [Source: .bmad-orchestrator/loop.sh#preflight_check] -- Checks status=failed and refuses to run (must --resume)
- [Source: _bmad-output/implementation-artifacts/3-1-stage-failure-detection-retry-logic.md] -- Previous story: failure detection validation pattern, 263 tests
- [Source: _bmad-output/implementation-artifacts/3-2-upstream-re-routing-remediation.md] -- Previous story: re-routing counts against maxRetries, 298 tests
- [Source: tests/orchestrator-agent.bats] -- 298 existing tests, naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

### Completion Notes List

- Task 1: Validated terminal failure flow end-to-end. Section 5.5 and Section 6 both correctly describe `currentRetries >= maxRetries` triggering `status: failed` and exit code 1. State preservation confirmed through Section 7.1 ("All other fields preserved as-is"). No gaps found — no changes needed to orchestrator agent for terminal failure logic.
- Task 2: Enhanced slash command Step 3 (Artifact Overwrite Protection) with three-tier detection: primary (state.yaml), secondary (status-report.md), and safety net (prd.md warning). Used conservative design — `.bmad-orchestrator/` files are hard blocks, `_bmad-output/` artifacts are warnings only to avoid false positives from manual BMAD usage.
- Task 3: Validated resume artifact respect. Section 1.4 describes artifact respect, Section 1.2 handles resume transparently, slash command Step 2 preserves all state fields except runType/updatedAt/status. No gaps found.
- Task 4: Added "Partial Artifact Handling on Resume" documentation to Section 1.4 of orchestrator agent. Documents the implicit handling mechanism: failed stages are never in completedStages, currentStage still points to them, sub-agents re-execute fully on retry. Explicit statement that no special partial artifact detection logic is needed.
- Task 5: Added 35 new tests (Terminal 3.3-1 through 3.3-35). All 333 tests pass (298 existing + 35 new, zero regressions). Tests cover: terminal failure flow (10), artifact overwrite protection (9), resume artifact respect (4), partial artifact handling (7), loop.sh terminal failure (5).
- Task 6: Manual verification — left unchecked as MANUAL task per story specification.

### Change Log

- Enhanced `.claude/commands/bmad-orchestrate.md` Step 3 with multi-signal artifact overwrite protection (2026-02-03)
- Added partial artifact handling documentation to `.claude/agents/bmad-orchestrator.md` Section 1.4 (2026-02-03)
- Added 35 bats tests for terminal failure, artifact protection, resume, and partial artifacts (2026-02-03)
- Code review fixes: aligned Step 3 error message to AC #3 wording, elevated safety net prd.md check from warning to hard block per AC, scoped test 3.3-33 to handle_exit_code, strengthened test 3.3-6 with direct field preservation assertion (2026-02-03)

### File List

- `.claude/commands/bmad-orchestrate.md` — MODIFIED — Enhanced Step 3 with primary/secondary/safety-net artifact detection
- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added "Partial Artifact Handling on Resume" to Section 1.4
- `tests/orchestrator-agent.bats` — MODIFIED — Added 35 new tests (Terminal 3.3-1 through 3.3-35)
- `_bmad-output/implementation-artifacts/3-3-terminal-failure-artifact-protection.md` — MODIFIED — Story file updated with task completion and dev record
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated to review

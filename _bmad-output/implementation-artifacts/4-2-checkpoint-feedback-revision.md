# Story 4.2: Checkpoint Feedback & Revision

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want to provide feedback at a checkpoint that the orchestrator incorporates before moving on,
so that I can steer the output without manually editing artifacts.

## Acceptance Criteria

1. **Given** the orchestrator has paused at a checkpoint gate
   **When** the user resumes with feedback (e.g., `/bmad-orchestrate --resume` with the orchestrator detecting user-provided feedback)
   **Then** the orchestrator re-runs the paused stage with the feedback injected as additional context

2. **Given** user feedback like "PRD is missing refresh token handling"
   **When** the orchestrator processes the feedback
   **Then** it constructs remediation instructions from the feedback and injects them into the stage template's `{{failure_context}}` field

3. **Given** the orchestrator revises a stage based on feedback
   **When** the revised stage completes
   **Then** it pauses again at the same gate with an updated summary for the user to re-review

4. **Given** the user approves after revision (resumes without feedback)
   **When** the orchestrator detects no feedback
   **Then** it advances to the next stage normally

5. **Given** feedback is provided at a checkpoint
   **When** the orchestrator logs the interaction
   **Then** the feedback and revision are recorded in the `failures` array as a checkpoint revision (distinct from an actual failure)

## Tasks / Subtasks

- [x]Task 1: Design feedback delivery mechanism in slash command (AC: #1, #4)
  - [x]1.1: Add optional `--feedback "text"` flag parsing to `.claude/commands/bmad-orchestrate.md` Input Parsing section
  - [x]1.2: Modify Step 2 (Resume Handling) to detect feedback: if `--feedback` flag is present, store feedback text in `state.yaml` as `checkpointFeedback` field
  - [x]1.3: When `--feedback` is provided on resume: set `status: running` AND write `checkpointFeedback: "<feedback text>"` to state
  - [x]1.4: When no `--feedback` is provided on resume (approval flow): set `status: running`, ensure `checkpointFeedback` is absent/null in state
  - [x]1.5: CRITICAL: Only allow `--feedback` when combined with `--resume`. If `--feedback` is used without `--resume`, fail with error: "Error: --feedback can only be used with --resume after a checkpoint pause."
  - [x]1.6: Update Step 2 output message when feedback is provided: "Resumed pipeline with feedback. Run `.bmad-orchestrator/loop.sh` to continue."

- [x]Task 2: Implement feedback-aware checkpoint revision in orchestrator agent (AC: #1, #2, #3)
  - [x]2.1: Add `checkpointFeedback` to the field list in Section 1.1 (Read State File) — read it as optional field, defaults to null/absent
  - [x]2.2: Modify Section 1.2 point 3 (`status: paused` handling): After setting `status: running`, check if `checkpointFeedback` is present and non-null
  - [x]2.3: If `checkpointFeedback` IS present: this is a REVISION flow:
    - Identify the completed stage that triggered the pause (last entry in `completedStages`)
    - Remove that stage from `completedStages` (it needs to be re-run)
    - Set `currentStage` back to the completed stage (rewind)
    - Construct `{{failure_context}}` from the feedback: "Checkpoint feedback from user: [feedback text]. Revise the stage output to address this feedback."
    - Clear `checkpointFeedback` from state after consuming it (prevent re-processing on next loop iteration)
    - Proceed to Stage Execution (Section 2) with the rewound `currentStage`
  - [x]2.4: If `checkpointFeedback` is NOT present: this is an APPROVAL flow (existing behavior — advance to next stage normally, no changes needed)
  - [x]2.5: CRITICAL: After revision stage completes and passes verification, the checkpoint gate logic (Section 8) will AUTOMATICALLY re-pause at the same gate because the completed stage is still in the `gates` array. This means AC #3 is handled by existing gate logic with NO additional code needed. Verify this flow works correctly.
  - [x]2.6: Ensure the stage template receives the feedback via `{{failure_context}}` injection point (Section 4.2 Template Variable Injection already handles this field). The sub-agent will see the feedback and incorporate it during revision.

- [x]Task 3: Record checkpoint revisions in failures array (AC: #5)
  - [x]3.1: When processing checkpoint feedback (Task 2.3), before re-running the stage, append a record to the `failures` array:
    ```yaml
    - stage: "<completed-stage>"
      attempt: 0
      error: "Checkpoint revision: <truncated feedback>"
      timestamp: "<ISO-8601>"
      type: "checkpoint-revision"
    ```
  - [x]3.2: Use `attempt: 0` and add `type: checkpoint-revision` to distinguish from actual failures. The `type` field is new but safe — existing failure parsing treats it as additional metadata.
  - [x]3.3: Ensure the feedback is captured in the error field as a single-line summary (per architecture: single-line error messages only). Truncate long feedback to first 200 characters.

- [x]Task 4: Write bats tests for checkpoint feedback functionality (AC: #1, #2, #3, #4, #5)
  - [x]4.1: Add tests to `tests/orchestrator-agent.bats` validating orchestrator feedback handling:
    - Agent describes `checkpointFeedback` field in state file
    - Agent describes feedback-aware resume from `status: paused` (revision flow)
    - Agent describes rewinding `currentStage` and removing from `completedStages` on feedback
    - Agent describes injecting feedback into `{{failure_context}}`
    - Agent describes clearing `checkpointFeedback` after consuming it
    - Agent describes approval flow (no feedback → advance normally)
    - Agent describes re-pause at same gate after revision completes (via existing gate logic)
    - Agent describes `checkpoint-revision` type in failures array
  - [x]4.2: Add tests validating slash command feedback handling:
    - Slash command describes `--feedback` flag parsing
    - Slash command describes `checkpointFeedback` field in state on resume
    - Slash command describes `--feedback` requires `--resume` (error if used alone)
    - Slash command describes approval resume (no feedback, no `checkpointFeedback` field)
  - [x]4.3: Use test naming pattern: `@test "Feedback 4.2-N: description"` for all tests
  - [x]4.4: Verify all existing tests still pass (zero regressions on all 377 existing tests)

- [x]Task 5: Manual verification (AC: #1, #2, #3, #4, #5) -- MANUAL
  - [x]5.1: Trace the complete feedback revision flow end-to-end:
    - `/bmad-orchestrate --resume --feedback "PRD is missing refresh token handling"` → slash command writes `checkpointFeedback` to state → loop.sh launches agent → agent reads state → detects `status: paused` + `checkpointFeedback` → rewinds `currentStage` to completed stage → removes from `completedStages` → constructs `{{failure_context}}` → clears feedback → runs stage with feedback context → sub-agent revises → verification passes → Section 7.1 advances `currentStage` → Section 8 detects gate → re-pauses → exit code 3
  - [x]5.2: Trace the approval flow: `/bmad-orchestrate --resume` (no feedback) → state updated → agent resumes → `status: paused` detected → no feedback → advance normally
  - [x]5.3: Verify feedback error validation: `/bmad-orchestrate --feedback "text"` without `--resume` → error
  - [x]5.4: Verify failures array records checkpoint revision correctly with `type: checkpoint-revision`

## Dev Notes

### Architecture Compliance

**This story modifies 2-3 files and creates 0 new files:**
- `.claude/commands/bmad-orchestrate.md` — **MODIFIED** — Add `--feedback` flag parsing and `checkpointFeedback` state field on resume
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add feedback-aware checkpoint resume logic in Section 1.2 point 3: rewind `currentStage`, construct `{{failure_context}}`, record checkpoint revision
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add checkpoint feedback, revision, approval, and error validation tests (~20-30 new tests)

**No new files created.** Story 4.2 builds directly on Story 4.1's checkpoint gate infrastructure.

### What Makes This Story UNIQUE

**Story 4.2 adds FEEDBACK LOOPS to checkpoint mode.** Story 4.1 established:
- Gate pausing (orchestrator stops at defined points)
- Summary presentation (what the user sees)
- Clean resume (approval to continue)

**Story 4.2 adds:**
- Feedback delivery mechanism (`--feedback` flag on resume)
- Stage rewinding (rewind `currentStage` to re-run with feedback)
- Automatic re-pause after revision (existing gate logic handles this — no new code)
- Checkpoint revision recording (distinct from failures in the `failures` array)

### Critical Design Decision: Feedback Delivery via `--feedback` Flag

The epics describe: "the user resumes with feedback (e.g., `/bmad-orchestrate --resume` with the orchestrator detecting user-provided feedback)." The mechanism for delivering feedback needs a design decision:

**Chosen approach:** New `--feedback "text"` flag on the slash command.
- Clean and explicit: `/bmad-orchestrate --resume --feedback "PRD is missing refresh token handling"`
- Stored as `checkpointFeedback` field in state.yaml (camelCase per architecture rules)
- Consumed by orchestrator on next launch, then cleared from state
- No feedback = approval flow (existing behavior, no changes)

**Why this approach:**
- Aligns with existing flag-based CLI pattern (`--checkpoint`, `--quick`, `--full`, `--resume`)
- State file remains the only communication channel between slash command and orchestrator
- Feedback text is preserved across Ralph Loop restarts
- Simple to validate and test

### Critical Design Decision: Stage Rewinding

When feedback is provided, the orchestrator must re-run the completed stage:
- **Before checkpoint pause:** Section 7.1 already advanced `currentStage` to the next stage and appended the completed stage to `completedStages`
- **On feedback resume:** The orchestrator must UNDO this: remove the completed stage from `completedStages` and set `currentStage` back to it
- **After revision:** Normal flow resumes — Section 7.1 advances `currentStage` again, and Section 8 gate logic re-pauses at the same gate

**Why rewinding is correct:**
- The stage output is being revised — it should not remain in `completedStages` until the revision passes
- The verification pattern (Section 5) runs after the revision, ensuring the revised output meets quality standards
- The gate logic (Section 8) automatically re-pauses, giving the user another review opportunity

### Interaction with Story 4.1 (Previous Story)

**What Story 4.1 established (DO NOT re-implement):**
- Section 8 Checkpoint Gate Logic: detects gate stages, pauses with summary
- Section 8.1 Checkpoint Summary Generation: formatted summary output
- Section 1.2 point 3: `status: paused` → `running`, proceed
- `read_last_completed_stage()` in loop.sh
- Gates array in slash command Step 4

**What Story 4.2 adds on top:**
- `--feedback` flag in slash command
- `checkpointFeedback` field in state schema
- Feedback-aware branching in Section 1.2 point 3 (revision vs. approval)
- Stage rewind logic (remove from `completedStages`, reset `currentStage`)
- `{{failure_context}}` injection with user feedback
- `checkpoint-revision` type in failures array

### Key Insight: AC #3 (Re-pause After Revision) Is FREE

The most elegant aspect: after the orchestrator rewinds and re-runs the stage with feedback, the existing gate logic in Section 8 will automatically detect that the completed stage is in the `gates` array and pause again. **No additional code is needed for AC #3.** The developer must verify this flow works correctly but should NOT add redundant gate-checking code.

### State File Schema Impact

New field added to state schema:
```yaml
checkpointFeedback: "User feedback text" # Optional, present only during feedback revision
```

- **camelCase** per architecture naming rules
- **Optional field** — absent/null when no feedback
- **Transient** — consumed by orchestrator then cleared from state
- Does NOT change existing fields or break backward compatibility

### Failures Array Extension

New `type` field for checkpoint revisions:
```yaml
failures:
  - stage: "prd"
    attempt: 0
    error: "Checkpoint revision: PRD is missing refresh token handling"
    timestamp: "2026-02-03T10:00:00Z"
    type: "checkpoint-revision"
```

- `attempt: 0` distinguishes from retry attempts (which start at 1)
- `type: checkpoint-revision` explicitly separates from failure records
- Existing failure parsing is not broken — `type` is an additive field

### Previous Story Intelligence (Story 4.1)

**Key learnings:**
- Validation-focused story: most logic already existed, story was about validation + gap-filling + testing
- Three-tier approach: validate existing → fill gaps → write tests
- 44 tests added (333 → 377), zero regressions
- Test naming: `@test "Checkpoint 4.1-N: description"` — Story 4.2 uses `@test "Feedback 4.2-N: description"`
- Code review found 4 issues: error message alignment, safety net check severity, test scoping, test assertion strength
- Section 8 clarified to check completed stage (last in `completedStages`), NOT `currentStage`
- `read_last_completed_stage()` function added to loop.sh with sed-based YAML parsing

**Patterns to follow:**
- Validate existing checkpoint infrastructure before modifying
- Keep changes minimal and surgical — build on 4.1's foundation
- Test agent documentation describes the behavior (bats tests grep the agent file)
- Expect ~20-30 new tests

### Git Intelligence

- Recent commit: `feat: add checkpoint gate pausing and approval (story 4-1)`
- Files modified in 4.1: orchestrator agent (+32 lines), loop.sh (+20 lines), tests (+297 lines)
- Commit pattern: `feat: <description> (story X-Y)`
- Total tests: 377, all passing
- Loop.sh now has `read_last_completed_stage()` function — may be useful for identifying the stage to rewind

### Anti-Patterns to Avoid

- Adding redundant gate-checking code for re-pause after revision (existing Section 8 handles this automatically)
- Storing feedback in a separate file instead of state.yaml (state file is the single communication channel)
- Making `--feedback` work without `--resume` (feedback only makes sense in checkpoint resume context)
- Forgetting to clear `checkpointFeedback` after consuming it (would cause infinite revision loops)
- Multi-line feedback in the failures array error field (truncate to single-line, max 200 chars)
- Breaking the existing `status: paused` → `running` flow for the approval case (no feedback = existing behavior)
- Modifying Section 8 gate logic (it already works correctly for re-pause)
- Direct writes to state.yaml (always temp-then-rename per Section 7.2)
- Breaking existing test patterns or renumbering existing tests

### Project Structure Notes

- `.claude/commands/bmad-orchestrate.md` — MODIFIED: Add `--feedback` flag parsing, update Step 2 resume handling
- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Add `checkpointFeedback` to Section 1.1, modify Section 1.2 point 3 with feedback-aware branching, add checkpoint revision recording
- `tests/orchestrator-agent.bats` — MODIFIED: Add ~20-30 new tests for feedback flag, revision flow, approval flow, re-pause, error validation
- No new files created
- All changes in existing files per architecture boundaries

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.2] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4] — Checkpoint Mode & Party Mode epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR29 maps to 4.2 (user feedback at checkpoint)
- [Source: _bmad-output/planning-artifacts/prd.md#FR29] — "User can provide feedback at a checkpoint that the orchestrator incorporates before proceeding"
- [Source: _bmad-output/planning-artifacts/prd.md#Checkpoint Mode] — Checkpoint mode with feedback handling
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — camelCase fields, atomic writes, failures array
- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] — Exit code convention
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] — `{{failure_context}}` injection point
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns] — Naming, atomic writes, error format
- [Source: _bmad-output/project-context.md#State File Rules] — Never write directly to state.yaml
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — Exact stage strings
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.1] — State file field list (add `checkpointFeedback`)
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] — `status: paused` handling (modify point 3)
- [Source: .claude/agents/bmad-orchestrator.md#Section 4.2] — Template variable injection (`{{failure_context}}`)
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.1] — State update: advances `currentStage`, appends `completedStages`
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.2] — Atomic write pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 8] — Checkpoint Gate Logic (completed stage check)
- [Source: .claude/agents/bmad-orchestrator.md#Section 8.1] — Checkpoint Summary Generation
- [Source: .claude/commands/bmad-orchestrate.md#Input Parsing] — Flag extraction (add `--feedback`)
- [Source: .claude/commands/bmad-orchestrate.md#Step 2] — Resume handling (modify for feedback)
- [Source: _bmad-output/implementation-artifacts/4-1-checkpoint-gate-pausing-approval.md] — Previous story: 377 tests, checkpoint summary, gate clarification, read_last_completed_stage()

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

### Completion Notes List

- Task 1: Added `--feedback "text"` flag parsing to slash command Input Parsing section. Modified Step 2 Resume Handling with feedback-aware branching: writes `checkpointFeedback` to state when feedback provided, omits when not. Added error validation requiring `--resume`. Added distinct output message for feedback resume.
- Task 2: Added `checkpointFeedback` to Section 1.1 state field list. Modified Section 1.2 point 3 with REVISION flow (rewind `currentStage`, remove from `completedStages`, construct `{{failure_context}}`, record checkpoint-revision in failures, clear feedback) and APPROVAL flow (existing behavior, no changes). AC #3 (re-pause) handled by existing Section 8 gate logic. Template injection handled by existing Section 3.4/4.2.
- Task 3: Checkpoint revision recording embedded in Task 2.3 revision flow — failures array entry with `type: checkpoint-revision`, `attempt: 0`, truncated feedback (max 200 chars), ISO-8601 timestamp.
- Task 4: Added 31 new bats tests (Feedback 4.2-1 through 4.2-31). All 408 tests pass (377 existing + 31 new), zero regressions.
- Task 5: Manual verification traces confirmed: feedback revision flow, approval flow, error validation, failures array recording.

### Change Log

- 2026-02-03: Implemented checkpoint feedback & revision (Story 4.2) — 31 new tests, 3 files modified
- 2026-02-03: Code review fixes — H1: consolidated double atomic write into single write in revision flow; M1: strengthened test 4.2-9 to validate rewind-to-execution flow; M2: differentiated duplicate tests 4.2-26 and 4.2-30; M3: tightened regex in test 4.2-13

### File List

- `.claude/commands/bmad-orchestrate.md` — MODIFIED — Added `--feedback` flag parsing, feedback-aware Step 2 resume handling, error validation
- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added `checkpointFeedback` to Section 1.1, feedback-aware revision/approval branching in Section 1.2 point 3, checkpoint-revision failures recording
- `tests/orchestrator-agent.bats` — MODIFIED — Added 31 new tests (Feedback 4.2-1 through 4.2-31)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated
- `_bmad-output/implementation-artifacts/4-2-checkpoint-feedback-revision.md` — MODIFIED — Story file updated with task completion

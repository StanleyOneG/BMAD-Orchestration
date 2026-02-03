# Story 4.1: Checkpoint Gate Pausing & Approval

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to pause at key decision points when I use `--checkpoint`,
so that I can review artifacts before the pipeline continues and catch issues early.

## Acceptance Criteria

1. **Given** `state.yaml` has `mode: checkpoint` and the `gates` array contains `[prd, architecture, epics-stories, readiness, code-review]`
   **When** the orchestrator completes a stage that matches a gate
   **Then** it presents a summary of what was produced, sets `status: paused`, and exits with code 3

2. **Given** the orchestrator pauses at a gate
   **When** the summary is presented
   **Then** it includes: stage name, artifacts produced, key decisions or outputs from the stage, and instructions to resume

3. **Given** the loop script receives exit code 3
   **When** the loop stops
   **Then** it displays a message: "Checkpoint reached after [stage]. Review artifacts and run `--resume` to continue."

4. **Given** the user runs `/bmad-orchestrate --resume` after a checkpoint pause
   **When** `state.yaml` has `status: paused`
   **Then** the status is set back to `running` and the pipeline advances to the next stage

5. **Given** `state.yaml` has `mode: autonomous`
   **When** the orchestrator completes a stage that matches a gate
   **Then** it does NOT pause — it continues to the next stage automatically

## Tasks / Subtasks

- [x] Task 1: Validate existing checkpoint gate logic in orchestrator agent (AC: #1, #5)
  - [x] 1.1: Review Section 8 (Exit Code Protocol) — confirm checkpoint gate logic exists: `mode: checkpoint` AND completed stage in `gates` array → `status: paused`, exit code 3
  - [x] 1.2: Review Section 1.2 (Determine What To Do) — confirm `status: paused` handling exists: updates `status` to `running` via atomic write, then proceeds to Stage Execution
  - [x] 1.3: Review Section 7.1 (Construct Updated State) — confirm state update flow: does it check `mode: checkpoint` and `gates` before choosing exit code 0 vs 3?
  - [x] 1.4: Trace the complete checkpoint pause flow end-to-end: stage completes → verification passes → Section 7 state update → Section 8 exit code check → checkpoint gate detected → `status: paused` → atomic write → exit code 3 → loop.sh stops with PAUSED report
  - [x] 1.5: Verify `mode: autonomous` causes gates to be ignored (Section 8 Checkpoint Gate Logic already states this)
  - [x] 1.6: If any gaps found in 1.1-1.5, update `.claude/agents/bmad-orchestrator.md` to close them

- [x] Task 2: Implement checkpoint summary presentation (AC: #2)
  - [x] 2.1: Review Section 5.4 (On Verification Pass) and Section 8 — determine where summary generation should occur. The summary must be generated BEFORE the agent exits with code 3.
  - [x] 2.2: Add a checkpoint summary section to the orchestrator agent (new subsection in Section 8 or Section 5.4). The summary must include:
    - Stage name (from `currentStage`)
    - Artifacts produced (from template frontmatter `producedArtifacts`)
    - Key decisions or outputs from the stage (read produced artifacts and extract a brief summary)
    - Instructions to resume: "Review artifacts and run `/bmad-orchestrate --resume` then `.bmad-orchestrator/loop.sh` to continue."
  - [x] 2.3: The summary should be written to `.bmad-orchestrator/status-report.md` (append, per Section 7.3) with outcome `PAUSED (CHECKPOINT)` and the summary details in the Details field
  - [x] 2.4: The summary should ALSO be output to the console/conversation so the user sees it directly (the agent outputs text before executing the final `exit 3` bash command)

- [x] Task 3: Enhance loop.sh checkpoint messaging (AC: #3)
  - [x] 3.1: Review `handle_exit_code` function in `loop.sh` — exit code 3 already handled. Current message: "Checkpoint pause. Review results and resume when ready."
  - [x] 3.2: Enhance the exit code 3 message to include the stage name. Read `currentStage` from state.yaml and display: "Checkpoint reached after [stage]. Review artifacts and run `--resume` to continue."
  - [x] 3.3: Verify `write_status_report` is called with "PAUSED" status (already done) and the details include the stage name

- [x] Task 4: Validate resume from checkpoint pause (AC: #4)
  - [x] 4.1: Review `.claude/commands/bmad-orchestrate.md` Step 2 (Resume Handling) — confirm it handles `status: paused` correctly: sets `status: running`, preserves `currentStage`, `completedStages`, `storyLoop`, etc.
  - [x] 4.2: Review Section 1.2 point 3 — confirm the orchestrator handles `status: paused` on cold start: updates `status` to `running` then proceeds to execute `currentStage`
  - [x] 4.3: CRITICAL: Verify the resume flow correctly ADVANCES `currentStage` to the next stage. After checkpoint pause, the completed stage was appended to `completedStages` before pausing. On resume, `currentStage` should still point to the NEXT stage (set during Section 7.1 state update). Trace the exact state transitions:
    - Stage completes → Section 7.1: `currentStage` advanced to next stage, completed stage appended to `completedStages` → Section 8: gate detected, `status: paused` → exit code 3
    - Resume → Section 1.2 point 3: `status: paused` → update `status` to `running` → proceed to execute `currentStage` (which is already the NEXT stage)
  - [x] 4.4: If the flow in 4.3 reveals that `currentStage` is NOT advanced before pausing (i.e., `currentStage` still points to the completed stage), then the orchestrator needs to advance it on resume. Document the correct behavior and implement if needed.

- [x] Task 5: Write bats tests for checkpoint gate functionality (AC: #1, #2, #3, #4, #5)
  - [x] 5.1: Add tests to `tests/orchestrator-agent.bats` validating checkpoint gate logic in orchestrator agent:
    - Agent describes `mode: checkpoint` gate checking
    - Agent describes `gates` array for checkpoint stages
    - Agent describes `status: paused` on checkpoint gate
    - Agent describes exit code 3 for checkpoint pause
    - Agent describes checkpoint summary with stage name, artifacts, and resume instructions
    - Agent describes autonomous mode ignoring gates
  - [x] 5.2: Add tests validating `status: paused` handling on cold start:
    - Agent describes `status: paused` as a cold start state
    - Agent describes updating `status: paused` to `status: running` on resume
    - Agent describes proceeding to execute currentStage after resume from pause
  - [x] 5.3: Add tests validating loop.sh checkpoint handling:
    - Loop script handles exit code 3 (stop with PAUSED status report)
    - Loop script displays checkpoint stage information
    - Loop script includes resume instructions in output
    - Loop script does NOT relaunch after exit code 3
  - [x] 5.4: Add tests validating slash command resume from paused state:
    - Slash command Step 2 handles `status: paused` (sets to `running`)
    - Slash command preserves state fields on resume from pause
  - [x] 5.5: Add tests validating the default `gates` array in slash command:
    - Slash command Step 4 creates state with gates array
    - Gates array contains expected checkpoint stages: prd, architecture, epics-stories, readiness, code-review
  - [x] 5.6: Use test naming pattern: `@test "Checkpoint 4.1-N: description"` for all tests
  - [x] 5.7: Verify all existing tests still pass (zero regressions on all 333 existing tests)

- [x] Task 6: Manual verification (AC: #1, #2, #3, #4, #5) -- MANUAL
  - [x] 6.1: Verify the orchestrator agent describes complete checkpoint pause flow from gate detection through exit code 3
  - [x] 6.2: Verify the checkpoint summary includes stage name, artifacts produced, key decisions, and resume instructions
  - [x] 6.3: Verify loop.sh displays checkpoint stage in its pause message
  - [x] 6.4: Trace a hypothetical checkpoint resume scenario end-to-end through documentation
  - [x] 6.5: Verify autonomous mode correctly ignores all gates

## Dev Notes

### Architecture Compliance

**This story modifies 2-3 existing files and creates 0 new files:**
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add checkpoint summary generation logic (new subsection in Section 8 or Section 5.4). May also need to clarify the exact timing of `status: paused` setting relative to `currentStage` advancement in Section 7.1.
- `.bmad-orchestrator/loop.sh` — **MODIFIED** — Enhance exit code 3 handling to include stage name from state.yaml in the message.
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add checkpoint gate, summary, resume, and autonomous-mode tests (~25-35 new tests).

**No new files created.** Checkpoint gate logic is largely ALREADY described in the orchestrator agent (Section 8, Checkpoint Gate Logic). The primary work is:
- Validating completeness and closing any documentation gaps
- Adding checkpoint summary generation
- Enhancing loop.sh messaging
- Comprehensive testing

### What Makes This Story UNIQUE

**Story 4.1 is the foundation of checkpoint mode.** It establishes:
1. **Gate pausing** — the mechanism by which the pipeline stops at defined points
2. **Summary presentation** — what the user sees at each gate
3. **Clean resume** — continuing from a pause without losing progress

**Story 4.2 (Checkpoint Feedback & Revision)** builds ON TOP of 4.1 by adding the ability to provide feedback that revises the paused stage. Story 4.1 only handles simple approve-and-continue flow.

**Most of the checkpoint gate logic ALREADY EXISTS** in the orchestrator agent:
- Section 1.2 point 3: `status: paused` → update to `running`, proceed
- Section 8 Checkpoint Gate Logic: `mode: checkpoint` → check if stage in `gates` → `status: paused`, exit 3
- Section 8 also states: `mode: autonomous` → gates ignored
- Slash command Step 4: creates `gates` array with `[prd, architecture, epics-stories, readiness, code-review]`

### Current Implementation — What Already Exists

**Checkpoint gate logic (orchestrator agent Section 8):**
- Checkpoint Gate Logic subsection: `mode: checkpoint` → check stage in `gates` → `status: paused`, exit 3 — COMPLETE
- Autonomous mode: "Gates are ignored, all stages continue automatically with exit code 0" — COMPLETE

**Cold start handling of paused status (orchestrator agent Section 1.2):**
- Point 3: `status: paused` → update `status` to `running` via atomic write → proceed to Stage Execution — COMPLETE

**Loop.sh exit code 3 handling:**
- `handle_exit_code` function: case 3 → log "Checkpoint pause" → write_status_report "PAUSED" → return 3 — COMPLETE
- Status report includes resume instructions — COMPLETE

**Slash command gates array:**
- Step 4 creates gates: `[prd, architecture, epics-stories, readiness, code-review]` — COMPLETE

**Slash command resume handling:**
- Step 2: handles resume by setting `status: running`, preserving all other state fields — COMPLETE

**What's MISSING (the gaps this story fills):**
- No checkpoint summary generation — the agent just sets `status: paused` and exits, without presenting a human-readable summary of what was produced (AC #2)
- Loop.sh message doesn't include the specific stage name — just generic "Checkpoint pause" (AC #3)
- Need to verify the exact timing: does Section 7.1 advance `currentStage` BEFORE or AFTER the checkpoint pause? This affects resume behavior (AC #4)
- No dedicated tests for checkpoint gate functionality

### GAP — Checkpoint Summary Generation

**The key enhancement:** The current orchestrator agent (Section 8) sets `status: paused` and exits with code 3, but does NOT present a summary to the user. The AC says "it presents a summary of what was produced." This requires:

1. **Between verification pass (Section 5.4) and exit (Section 8)**, when a checkpoint gate is detected, the agent should:
   - Read the produced artifacts (from template frontmatter `producedArtifacts`)
   - Generate a brief summary of what was produced and key decisions
   - Output the summary to the conversation
   - Append the summary to `status-report.md` with outcome `PAUSED (CHECKPOINT)`
   - Then set `status: paused` and exit code 3

2. **The summary should include:**
   - Stage name (e.g., "PRD Creation")
   - Artifacts produced (e.g., "`_bmad-output/planning-artifacts/prd.md`")
   - Key decisions or outputs (brief, 2-3 bullet points extracted from reading the artifact)
   - Resume instructions

### GAP — Loop.sh Stage Name in Message

**Current:** `log "Checkpoint pause. Review results and resume when ready."`
**Expected:** `log "Checkpoint reached after [stage]. Review artifacts and run --resume to continue."`

Enhancement: read `currentStage` from state.yaml using the existing `read_state` function and include it in the message.

### GAP — currentStage Advancement Timing

**CRITICAL INVESTIGATION:** The checkpoint pause flow needs careful analysis of when `currentStage` advances:

**Scenario:** PRD stage completes in checkpoint mode.
1. Section 5.4: Verification passes
2. Section 7.1: Build updated state — `currentStage` advanced to `architecture`, `prd` appended to `completedStages`
3. Section 8: Check if stage (just completed = `prd`) is in `gates` — YES
4. Section 8: Set `status: paused`, exit code 3

**On resume:**
1. Section 1.2 point 3: `status: paused` → set `status: running`
2. Proceed to execute `currentStage` which is `architecture` (already advanced)

**This flow appears correct.** The completed stage was `prd`, the `currentStage` was already advanced to `architecture` in Section 7.1. On resume, the orchestrator executes `architecture`. The gate check in Section 8 should check against the COMPLETED stage (the one just finished), not `currentStage` (which is already the next stage).

**Potential issue:** Section 8 says "check if the stage identifier is in the `gates` array." But after Section 7.1, `currentStage` is the NEXT stage, not the completed one. The gate check must use the completed stage identifier. Need to verify this is clear in the documentation or add clarification.

### Interaction with Previous Stories

**Story 1.1 (Slash Command):**
- Created the slash command with `gates` array in Step 4
- Created `--checkpoint` flag handling (sets `mode: checkpoint`)
- Story 4.1 validates the gates array and checkpoint mode setup

**Story 1.2 (Loop Script):**
- Created `loop.sh` with exit code 3 handling
- Story 4.1 enhances the exit code 3 message to include stage name

**Story 1.3 (Cold Start & State Management):**
- Established Section 1.2 with `status: paused` handling
- Story 4.1 validates the resume-from-pause flow

**Story 3.3 (Terminal Failure & Artifact Protection):**
- Last completed story, established patterns for validation + gap-filling + testing approach
- 333 tests currently passing

### Previous Story Intelligence (Story 3.3)

**Key learnings from Story 3.3:**
- Validation-focused story: most logic already implemented, story is about validation + gap-filling + testing
- Three-tier approach worked well: validate existing → fill gaps → write tests
- 35 tests added, total went from 298 to 333
- Test naming: `@test "Terminal 3.3-N: description"`
- Code review found 4 issues: error message alignment, safety net check severity, test scoping, test assertion strength

**Pattern to follow for Story 4.1:**
- Validate existing checkpoint logic before adding anything new
- Add checkpoint summary generation (new capability — the main enhancement)
- Enhance loop.sh messaging (relatively small change)
- Tests should validate agent documentation describes the behavior
- Use `@test "Checkpoint 4.1-N: description"` naming pattern
- Expect ~25-35 new tests

### Git Intelligence

- Recent commits follow pattern: `feat: <description> (story X-Y)`
- Story 3.3 modified 3 files: orchestrator agent, slash command, tests
- Total tests: 333, all passing
- Orchestrator agent has been modified in stories 1-3, 1-4, 2-3, 2-4, 2-5, 2-7, 3-1, 3-2, 3-3
- Loop.sh has NOT been modified since initial creation (Story 1.2)
- Slash command modified in Story 3.3 (artifact overwrite protection enhancement)

### Anti-Patterns to Avoid

- Rewriting existing checkpoint gate logic (it's likely already correct — validate first)
- Adding checkpoint summary to the wrong section (must be AFTER verification pass, BEFORE exit)
- Confusing the completed stage with `currentStage` when checking gates (after Section 7.1, `currentStage` is already the NEXT stage)
- Breaking existing section numbering in bmad-orchestrator.md
- Changing existing bats tests (only add new ones)
- Multi-line error messages in the failures array (single-line summaries only per architecture)
- Direct writes to state.yaml (always temp-then-rename per Section 7.2)
- Making checkpoint summary too verbose — keep it brief and actionable
- Forgetting to handle the edge case where the LAST stage in the pipeline is also a gate (pipeline complete vs checkpoint pause — `code-review` could be last stage AND a gate)

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Add checkpoint summary generation (Section 8 enhancement or new Section 8.1)
- `.bmad-orchestrator/loop.sh` — MODIFIED: Enhance exit code 3 message to include stage name from state.yaml
- `tests/orchestrator-agent.bats` — MODIFIED: Add ~25-35 new tests for checkpoint gate, summary, resume, and autonomous mode
- `.claude/commands/bmad-orchestrate.md` — POTENTIALLY READ-ONLY: Validate gates array, no changes expected
- No new files created
- All changes in existing files per architecture boundaries

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.1] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4] — Checkpoint Mode & Party Mode epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR28 maps to 4.1 (gate pausing with summary), FR30 maps to 4.1 (checkpoint approval to continue)
- [Source: _bmad-output/planning-artifacts/prd.md#FR28] — "Orchestrator can pause execution at defined gate points and present a summary to the user"
- [Source: _bmad-output/planning-artifacts/prd.md#FR30] — "User can approve a checkpoint to continue the pipeline"
- [Source: _bmad-output/planning-artifacts/prd.md#FR5] — "User can select execution mode: autonomous (default) or checkpoint (--checkpoint)"
- [Source: _bmad-output/planning-artifacts/prd.md#Journey 3] — Checkpoint Mode user journey: pause, review, feedback, approve
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — gates array, mode field, status: paused
- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] — Exit code 3 = checkpoint pause, loop stops
- [Source: _bmad-output/planning-artifacts/architecture.md#Checkpoint Gate Configuration] — Important decision shaping architecture
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] — Error messages, atomic writes, camelCase YAML
- [Source: _bmad-output/project-context.md#Exit Code Convention] — 0/1/2/3 mapping, code 3 = checkpoint pause
- [Source: _bmad-output/project-context.md#State File Rules] — Atomic writes, camelCase fields
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] — Cold start: `status: paused` → update to `running`, proceed
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.4] — On Verification Pass: update state, write status report
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.1] — State update: currentStage advanced, completedStages appended
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.2] — Atomic write: temp-then-rename pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.3] — Status report: append stage entry
- [Source: .claude/agents/bmad-orchestrator.md#Section 8] — Exit Code Protocol: code 3 = checkpoint pause; Checkpoint Gate Logic subsection
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] — Boundary Rules: append to status-report.md
- [Source: .claude/commands/bmad-orchestrate.md#Step 2] — Resume handling: sets `status: running`, preserves state
- [Source: .claude/commands/bmad-orchestrate.md#Step 4] — State creation: gates array with prd, architecture, epics-stories, readiness, code-review
- [Source: .bmad-orchestrator/loop.sh#handle_exit_code] — Exit code 3 → PAUSED status report → stop loop
- [Source: .bmad-orchestrator/loop.sh#preflight_check] — Checks for completed/failed status only (paused not blocked)
- [Source: _bmad-output/implementation-artifacts/3-3-terminal-failure-artifact-protection.md] — Previous story: validation + gap-filling + testing pattern, 333 tests
- [Source: tests/orchestrator-agent.bats] — 333 existing tests, naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

- Task 1.3/1.6: Found gap in Section 8 — checkpoint gate check was ambiguous about which stage identifier to use. Clarified that the gate check must use the **completed stage** (last entry in `completedStages`), NOT `currentStage` (which has already been advanced by Section 7.1).
- Task 2: Added Section 8.1 (Checkpoint Summary Generation) to orchestrator agent with full summary format: stage name, produced artifacts, key decisions, resume instructions.
- Task 3: Added `read_last_completed_stage()` function to loop.sh to correctly read the completed stage name from the `completedStages` YAML array (not `currentStage` which is already the next stage). Enhanced exit code 3 handler message.
- Task 5: Test 4.1-16 initially failed due to grep pattern matching the inline mention of `status: paused` in the gate check description (line 489) before the summary generation steps (line 499). Fixed pattern to target the explicit "Then" step in Section 8.1.

### Completion Notes List

- ✅ Task 1: Validated all checkpoint gate logic. Found and closed 1 gap: Section 8 clarified to check completed stage, not currentStage.
- ✅ Task 2: Added Section 8.1 (Checkpoint Summary Generation) with formatted summary output including stage name, artifacts, key decisions, resume instructions. Summary output to both conversation and status-report.md.
- ✅ Task 3: Enhanced loop.sh exit code 3 handler with `read_last_completed_stage()` function and stage-specific message: "Checkpoint reached after [stage]. Review artifacts and run --resume to continue."
- ✅ Task 4: Validated resume flow end-to-end. Confirmed `currentStage` is correctly advanced BEFORE checkpoint pause, so resume executes the next stage immediately.
- ✅ Task 5: Added 42 new tests (333 → 375). Zero regressions. All tests pass.
- ✅ Task 6: Manual verification completed by tracing flows through documentation.

### Change Log

- 2026-02-02: Implemented checkpoint gate pausing and approval (Story 4.1). Added Section 8.1 checkpoint summary generation to orchestrator agent, clarified gate check uses completed stage. Enhanced loop.sh with read_last_completed_stage() and stage-specific checkpoint message. Added 42 bats tests.
- 2026-02-02: Code review fixes. Fixed H1 bug in `read_last_completed_stage()` — sed-based parsing to isolate `completedStages` entries from subsequent YAML arrays. Hardened test 4.1-16 grep pattern. Replaced test 4.1-25 with behavioral test. Added tests 4.1-43 (flow-style) and 4.1-44 (empty array). Total: 377 tests, 0 failures.

### File List

- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Clarified Section 8 Checkpoint Gate Logic to use completed stage identifier; added Section 8.1 Checkpoint Summary Generation
- `.bmad-orchestrator/loop.sh` — MODIFIED — Added `read_last_completed_stage()` function; enhanced exit code 3 handler with stage name in message; code review fix: sed-based YAML parsing to prevent cross-array contamination
- `tests/orchestrator-agent.bats` — MODIFIED — Added 44 new tests (Checkpoint 4.1-1 through 4.1-44); code review: replaced grep test with behavioral tests for read_last_completed_stage
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated
- `_bmad-output/implementation-artifacts/4-1-checkpoint-gate-pausing-approval.md` — MODIFIED — Story file updated with task completions and code review fixes

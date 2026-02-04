# Story 5.1: Stage-Level Status Logging

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want each pipeline stage to log its outcome as it completes,
so that the status report builds incrementally and I can see progress even during a run.

## Acceptance Criteria

1. **Given** a pipeline stage completes successfully
   **When** the orchestrator updates state
   **Then** it also appends an entry to `.bmad-orchestrator/status-report.md` with: stage name, outcome (PASS), artifacts produced, and timestamp

2. **Given** a pipeline stage fails
   **When** the orchestrator logs the failure
   **Then** it appends an entry to `status-report.md` with: stage name, outcome (FAIL), error summary, retry attempt number, and timestamp

3. **Given** a stage is retried and succeeds on a subsequent attempt
   **When** the orchestrator logs the outcome
   **Then** both the failure entries and the eventual success entry are present in `status-report.md`, showing the full history

4. **Given** `status-report.md` does not yet exist
   **When** the first stage completes
   **Then** the file is created with a header section including task description, route, mode, and start timestamp

5. **Given** the status report is append-only
   **When** multiple stages write to it
   **Then** entries are never overwritten or reordered — each new entry is appended at the end

## Tasks / Subtasks

- [x] Task 1: Audit existing status report implementation in orchestrator agent and loop.sh (AC: #1-#5)
  - [x] 1.1: Review Section 7.3 "Status Report" in `.claude/agents/bmad-orchestrator.md` — current format: `## Stage: <stage-name>` with Outcome, Timestamp, Details fields. **GAP:** Missing `Artifacts Produced` field (AC #1). Missing `Retry Attempt` field for failures (AC #2).
  - [x] 1.2: Review Section 5.4 "On Verification Pass" — calls Section 7.3 to write stage outcome. Confirm this is the correct trigger point for PASS entries.
  - [x] 1.3: Review Section 5.5 "On Verification Fail" and Section 6 "Failure Handling" — currently logs to `failures` array in state.yaml but does NOT write to status-report.md on failure. **GAP:** No FAIL entry written to status report (AC #2).
  - [x] 1.4: Review Section 8.1 "Checkpoint Summary Generation" — writes PAUSED (CHECKPOINT) entries to status report. Confirm this doesn't conflict.
  - [x] 1.5: Review `loop.sh` `write_status_report` function — creates header + run summary at loop termination. **GAP:** Header is created by loop.sh only at the end, not at the beginning. If orchestrator appends stage entries first, the file would lack a header until the loop finishes (AC #4).

- [x] Task 2: Enhance Section 7.3 to include produced artifacts (AC: #1)
  - [x] 2.1: Update the Section 7.3 status report entry format to include an `Artifacts` field listing files from the template's `producedArtifacts` frontmatter
  - [x] 2.2: The enhanced format should be:
    ```markdown
    ## Stage: <stage-name>
    - **Outcome:** PASS | PASS (CONCERNS)
    - **Timestamp:** <ISO-8601>
    - **Artifacts:** <comma-separated list of producedArtifacts paths>
    - **Details:** <one-line summary, include concern details if CONCERNS>
    ```
  - [x] 2.3: Verify that `producedArtifacts` is accessible at Section 7.3 — it's parsed from template frontmatter in Section 3.2, so it should be available in the session

- [x] Task 3: Add FAIL entry logging to status report (AC: #2, #3)
  - [x] 3.1: In Section 6 "Failure Handling" (after step 1 — appending to failures array), add a new step to also append a FAIL entry to `.bmad-orchestrator/status-report.md`
  - [x] 3.2: The FAIL entry format:
    ```markdown
    ## Stage: <stage-name>
    - **Outcome:** FAIL
    - **Timestamp:** <ISO-8601>
    - **Attempt:** <attempt-number> of <maxRetries>
    - **Error:** <single-line error summary from failures array>
    ```
  - [x] 3.3: CRITICAL: Both FAIL and eventual PASS entries must be present for retried stages (AC #3). Since entries are append-only, this happens naturally — FAIL entries from earlier attempts remain, and the PASS entry from the successful attempt is appended after them.
  - [x] 3.4: Also add FAIL logging for the upstream re-routing case in Section 6.5 — when readiness fails and re-routes, the FAIL entry should include the re-route target:
    ```markdown
    ## Stage: <stage-name>
    - **Outcome:** FAIL (RE-ROUTED)
    - **Timestamp:** <ISO-8601>
    - **Attempt:** <attempt-number> of <maxRetries>
    - **Error:** <single-line error summary>
    - **Re-routed to:** <upstream-stage>
    ```

- [x] Task 4: Add header creation to orchestrator agent (AC: #4)
  - [x] 4.1: Add a new Section 7.4 "Status Report Initialization" (or integrate into Section 7.3) that checks if `status-report.md` exists before appending
  - [x] 4.2: If the file does NOT exist, create it with a header section BEFORE appending the stage entry:
    ```markdown
    # BMAD Orchestrator — Status Report

    - **Task:** <task description from state.yaml>
    - **Route:** <route from state.yaml>
    - **Mode:** <mode from state.yaml>
    - **Started:** <ISO-8601 timestamp>
    - **Branch:** <branch from state.yaml>

    ---

    ```
  - [x] 4.3: Update `loop.sh` `write_status_report` function to NOT create the header if the file already exists (it already has this check: `if [[ ! -f "${STATUS_REPORT}" ]]; then`). Verify the header format is aligned between orchestrator and loop.sh — the orchestrator's header should be the authoritative one since it runs first.
  - [x] 4.4: The `loop.sh` header creation should remain as a fallback for edge cases where the orchestrator crashes before writing any stage entry, but the primary header creation is now the orchestrator's responsibility.

- [x] Task 5: Ensure append-only behavior (AC: #5)
  - [x] 5.1: Add explicit instruction in Section 7.3 (or new Section 7.4): "The status report file is APPEND-ONLY. Never read and rewrite the file. Never use Write tool to overwrite the entire file. Always use Edit tool to append at the end, or use Bash to append via `>>` operator."
  - [x] 5.2: Verify that Section 8.1 (Checkpoint Summary) also follows append-only pattern — currently says "Append to status report" which is correct.
  - [x] 5.3: Add anti-pattern to Section 9 "Boundary Rules": "Never overwrite or reorder `.bmad-orchestrator/status-report.md` — it is append-only"

- [x] Task 6: Write bats tests for stage-level status logging (AC: #1-#5)
  - [x] 6.1: Add tests to `tests/orchestrator-agent.bats` validating status report entry format:
    - Agent describes PASS entry format with stage name, outcome, timestamp, artifacts, details
    - Agent describes FAIL entry format with stage name, outcome, timestamp, attempt, error
    - Agent describes RE-ROUTED entry format with re-route target
  - [x] 6.2: Add tests validating header creation:
    - Agent describes creating status-report.md header if file doesn't exist
    - Agent describes header includes task, route, mode, started timestamp
  - [x] 6.3: Add tests validating append-only behavior:
    - Agent describes append-only status report writes
    - Agent describes never overwriting or reordering entries
  - [x] 6.4: Add tests validating retry history visibility:
    - Agent describes both failure and success entries present for retried stages
    - Agent describes full history showing all attempts
  - [x] 6.5: Add tests validating failure logging:
    - Agent describes writing FAIL entry to status report on verification failure
    - Agent describes attempt number in FAIL entries
  - [x] 6.6: Use test naming pattern: `@test "StatusLog 5.1-N: description"` for all tests
  - [x] 6.7: Verify all existing tests still pass (zero regressions on all 439 existing tests)

- [x] Task 7: Manual verification (AC: #1-#5) -- MANUAL
  - [x] 7.1: Trace the complete stage logging flow for a successful stage: stage completes → verification passes (Section 5.4) → state update (Section 7.1) → status report entry appended (Section 7.3) → exit
  - [x] 7.2: Trace the complete stage logging flow for a failed stage: verification fails (Section 5.5) → failure handling (Section 6) → FAIL entry appended to status report → retry or stop
  - [x] 7.3: Trace the retry-then-succeed flow: first attempt fails → FAIL entry appended → retry → second attempt succeeds → PASS entry appended → status report shows both entries
  - [x] 7.4: Verify header creation on first stage of a fresh run
  - [x] 7.5: Verify header is NOT recreated on subsequent stages (append-only)

## Dev Notes

### Architecture Compliance

**This story modifies 2 source files and creates 0 new files:**
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Enhance Section 7.3 (status report format), add FAIL logging to Section 6, add header creation logic, add append-only anti-pattern to Section 9
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add ~15-25 new tests for status report logging

**No changes to `.bmad-orchestrator/loop.sh`.** The loop script's `write_status_report` function already creates headers and summaries correctly. The orchestrator enhancements complement rather than replace the loop script's behavior. The loop.sh header fallback remains for crash recovery.

**No changes to `.claude/commands/bmad-orchestrate.md`.** No new flags or slash command changes needed.

**No new files created.** Story 5.1 enhances existing status report mechanics that are already partially implemented in the orchestrator agent.

### What Makes This Story UNIQUE

**Story 5.1 is the FIRST story in Epic 5.** It adds incremental, per-stage logging to the status report — currently the orchestrator has a basic stage entry format (Section 7.3) but it's missing key fields (artifacts, retry attempts) and doesn't log failures to the status report at all.

**Key distinction from Stories 5.2 and 5.3:**
- Story 5.1: per-stage incremental logging (happens during pipeline execution)
- Story 5.2: final summary report (happens at pipeline completion/failure — modifies loop.sh primarily)
- Story 5.3: task report generation (human knowledge transfer document — new template)

**Story 5.1 provides the foundation for Stories 5.2 and 5.3.** The per-stage entries written by Story 5.1 are the data that Story 5.2 summarizes. Without complete stage logging, the final summary would lack detail.

### Current Implementation — What Already Exists

**Section 7.3 (Status Report) already contains:**
```markdown
## Stage: <stage-name>
- **Outcome:** PASS | PASS (CONCERNS) | FAIL
- **Timestamp:** <ISO-8601>
- **Details:** <one-line summary, include concern details if CONCERNS>
```

**Section 5.4 (On Verification Pass) already says:**
- "Write stage outcome to `.bmad-orchestrator/status-report.md`"

**Section 8.1 (Checkpoint Summary) already appends PAUSED (CHECKPOINT) entries.**

**loop.sh `write_status_report` already:**
- Creates header with task, route, mode, start timestamp (if file doesn't exist)
- Appends run summary with overall status, iterations, timestamp, details
- Adds recovery instructions for FAILED/PAUSED statuses

**What's MISSING (the gaps this story fills):**
- No `Artifacts` field in PASS entries (AC #1) — template `producedArtifacts` not included
- No FAIL entries written to status report (AC #2) — failures only logged to `state.yaml` failures array
- No retry attempt number in failure entries (AC #2)
- Header creation is only in loop.sh, not orchestrator (AC #4) — first stage entry could precede header
- No explicit append-only instruction (AC #5) — implied but not enforced
- No re-route information in failure entries

### Critical Design Decision: Orchestrator Creates Header, Loop.sh Provides Fallback

**Execution order:** Orchestrator runs first (writes stage entries) → exits → loop.sh runs (writes summary). If the orchestrator creates the header on first stage entry, the file will have proper structure from the start. If the orchestrator crashes before any stage completes, loop.sh creates the header as fallback when writing the CRASHED summary.

**Why this matters:** Without this change, a multi-stage run could produce a status report with stage entries appearing before the header section — making it unreadable.

### Critical Design Decision: FAIL Entries in Status Report

**Current behavior:** When a stage fails verification, the failure is logged ONLY to the `failures` array in `state.yaml`. The status report gets no FAIL entries — only eventual PASS entries or the final loop.sh summary.

**New behavior:** On each verification failure, the orchestrator writes a FAIL entry to the status report BEFORE incrementing retries and exiting. This means:
- The status report shows the full progression: FAIL (attempt 1) → FAIL (attempt 2) → PASS (on attempt 3)
- Users can monitor progress in real-time by reading the status report during execution
- Story 5.2 can reference these entries when building the final summary

### Critical Design Decision: Append-Only Pattern

The status report must be append-only for data integrity:
- Multiple Ralph Loop iterations write to the same file
- The orchestrator writes stage entries; loop.sh writes summaries
- If either party overwrites the file, the other's entries are lost
- Append-only ensures all stage history is preserved regardless of crashes

**Implementation:** The orchestrator should use the Edit tool to append at the end of the file, or use Bash `echo ... >> status-report.md`. NEVER use the Write tool which overwrites the entire file.

### Interaction with Existing Sections

**Section 5.4 (On Verification Pass):**
- Already calls Section 7.3 — no change to trigger, just enhance the format

**Section 5.5 (On Verification Fail):**
- Currently triggers Section 6 (Failure Handling) — needs to ALSO write FAIL entry to status report

**Section 6 (Failure Handling):**
- Step 1 appends to failures array in state.yaml
- NEW step needed after step 1: append FAIL entry to status report
- Steps 2-4 (retry logic) remain unchanged

**Section 6.5 (Upstream Re-Routing):**
- Step 3 appends re-route entry to failures array
- NEW step needed: append FAIL (RE-ROUTED) entry to status report

**Section 8.1 (Checkpoint Summary):**
- Already writes PAUSED (CHECKPOINT) entries — no changes needed

**Section 9 (Boundary Rules):**
- Add new anti-pattern: overwriting status report

### Previous Story Intelligence (Story 4.3)

**Key learnings from Story 4.3:**
- 31 new tests added, total went from 408 to 439
- Test naming: `@test "PartyMode 4.3-N: description"` — Story 5.1 uses `@test "StatusLog 5.1-N: description"`
- Code review found 4 MEDIUM issues: overly broad regex, false-positive risk, near-duplicate tests, unscoped grep
- Tests validate that agent documentation describes the behavior (bats tests grep the agent file)
- Section 4 was the only section modified in 4.3 — Story 5.1 modifies Sections 6, 7, and 9

**Patterns to follow:**
- Add new content as natural extensions of existing sections (not separate documents)
- Tests should validate agent documentation describes the behavior
- Expect ~15-25 new tests
- Ensure regexes in tests are specific enough to avoid false positives
- Differentiate tests that check similar but distinct behaviors

### Git Intelligence

- Recent commit: `feat: add party mode integration (story 4-3)`
- Commit pattern: `feat: <description> (story X-Y)`
- Total tests: 439, all passing
- Files modified in 4.3: orchestrator agent, tests
- Orchestrator agent Section 7.3 has NOT been modified since Story 2.5 (original implementation)
- Section 6 (Failure Handling) was last modified in Story 3.1 (retry logic) and 3.2 (re-routing)
- loop.sh was last modified in Story 4.1 (checkpoint exit handling)

### Anti-Patterns to Avoid

- Using Write tool to create/overwrite status-report.md (it's append-only — use Edit to append or Bash `>>`)
- Adding stage-level logging to loop.sh instead of the orchestrator agent (per architecture, loop reads state but doesn't track stage outcomes)
- Creating a separate log file for stage entries (architecture mandates single `status-report.md`)
- Modifying the `failures` array format in state.yaml (that's separate from status report entries)
- Adding status report logic to prompt templates (that's orchestrator agent responsibility, not sub-agent responsibility)
- Breaking existing Section 7.3 format rather than extending it
- Modifying Section 5.4/5.5 trigger logic (only extend, don't change when they fire)

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Enhance Section 7.3, add FAIL logging to Section 6, add header creation, add append-only anti-pattern to Section 9
- `tests/orchestrator-agent.bats` — MODIFIED: Add ~15-25 StatusLog 5.1-N tests
- No changes to `.bmad-orchestrator/loop.sh` (existing header fallback sufficient)
- No changes to `.claude/commands/bmad-orchestrate.md` (no new flags)
- No new files created
- All changes in existing files per architecture boundaries

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.1] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 5] — Status Reporting & Run Observability epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR38 maps to 5.2 (final status report), FR39 maps to 5.2 (failure details), FR40 maps to 5.2 (artifact inventory). Story 5.1 provides the incremental foundation.
- [Source: _bmad-output/planning-artifacts/prd.md#FR38] — "Orchestrator can generate a final status report showing all stages run and their outcomes"
- [Source: _bmad-output/planning-artifacts/prd.md#FR39] — "Status report can display the failure point, error details, and recovery instructions when a run fails"
- [Source: _bmad-output/planning-artifacts/prd.md#NFR2] — "A failed run must always produce a readable status report — no silent failures"
- [Source: _bmad-output/planning-artifacts/architecture.md#Logging] — "All logs consolidated into .bmad-orchestrator/status-report.md. No separate log files. Status report is append-friendly"
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] — Step 4 (Pass): "Update state, write stage outcome to status report, exit 0". Step 5 (Fail): "Log failure to state file failures array"
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns] — "Logging: All logs consolidated into .bmad-orchestrator/status-report.md. No separate log files. Status report is append-friendly — each stage writes its outcome as it completes."
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.3] — Current status report entry format (Outcome, Timestamp, Details — missing Artifacts and retry attempt)
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.4] — On Verification Pass: "Write stage outcome to .bmad-orchestrator/status-report.md"
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.5] — On Verification Fail: logs to failures array, no status report entry
- [Source: .claude/agents/bmad-orchestrator.md#Section 6] — Failure Handling: appends to failures array, increments currentRetries — no status report entry
- [Source: .claude/agents/bmad-orchestrator.md#Section 6.5] — Upstream Re-Routing: appends re-route entry to failures array — no status report entry
- [Source: .claude/agents/bmad-orchestrator.md#Section 8.1] — Checkpoint Summary: appends PAUSED (CHECKPOINT) to status report — already correct
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] — Boundary Rules: "You append to .bmad-orchestrator/status-report.md for stage-level logging" — already correct but needs append-only anti-pattern
- [Source: .bmad-orchestrator/loop.sh#write_status_report] — Creates header if file doesn't exist, appends run summary — remains as fallback
- [Source: _bmad-output/project-context.md#Boundary Rules] — "Loop script reads state but NEVER writes to it" — confirms loop.sh header creation as fallback only
- [Source: _bmad-output/implementation-artifacts/4-3-party-mode-integration.md] — Previous story: 439 tests, Section 4 modified, test naming pattern established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None required.

### Completion Notes List

- Enhanced Section 7.3 with PASS entry format including Artifacts field from producedArtifacts (AC #1)
- Added new step 2 to Section 6 Failure Handling to write FAIL entries to status-report.md with Attempt and Error fields (AC #2)
- Added step 4 to Section 6.5 Upstream Re-Routing to write FAIL (RE-ROUTED) entries with re-route target (AC #2)
- Retry history preserved naturally via append-only pattern — FAIL entries from earlier attempts remain alongside eventual PASS (AC #3)
- Created Section 7.4 Status Report Initialization for header creation on first stage entry, with loop.sh as crash recovery fallback (AC #4)
- Added append-only instruction to Section 7.3 and anti-pattern to Section 9 Boundary Rules (AC #5)
- 28 new tests added (StatusLog 5.1-1 through 5.1-28), total: 467, zero regressions
- No changes to loop.sh — existing header fallback is sufficient
- Section 8.1 Checkpoint Summary unchanged — already follows append-only pattern

### Change Log

- 2026-02-02: Implemented stage-level status logging — enhanced Section 7.3 PASS format, added FAIL/RE-ROUTED logging to Section 6/6.5, added Section 7.4 header initialization, added append-only anti-pattern to Section 9, added 28 bats tests
- 2026-02-04: Code review fixes — (H1) Replaced Section 5.5 inline steps with Section 6 reference to prevent FAIL logging bypass, (M1) Fixed Section 6.5 step numbering gap (5 was skipped), (M2) Added FAIL entry cross-reference in Section 7.3, (M3) Simplified test 5.1-14 regex to reduce false-positive risk, (M4) Strengthened test 5.1-26 with append-only co-existence check

### File List

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Enhanced Section 7.3 (PASS entry with Artifacts), added Section 7.4 (header initialization), added FAIL entry logging to Section 6 step 2, added FAIL (RE-ROUTED) entry to Section 6.5 step 4, added append-only anti-pattern to Section 9
- `tests/orchestrator-agent.bats` — MODIFIED: Added 28 new StatusLog 5.1-N tests (tests 440-467)

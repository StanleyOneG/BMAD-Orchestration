# Story 5.3: Task Report Generation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want a human-readable knowledge transfer document after an autonomous run,
so that I understand what was built, why key decisions were made, and anything I should know about the autonomously-produced work.

## Acceptance Criteria

1. **Given** the pipeline completes successfully
   **When** the loop script detects exit code 2
   **Then** it launches the orchestrator one final time with a "generate-task-report" directive before terminating

2. **Given** the orchestrator is launched with the "generate-task-report" directive
   **When** it executes
   **Then** it reads all produced artifacts in `_bmad-output/`, the `state.yaml` file, and `status-report.md`

3. **Given** the orchestrator has read all run context
   **When** it generates the task report
   **Then** it writes `.bmad-orchestrator/task-report.md` containing:
   - Summary of work accomplished
   - Key decisions made during execution and their rationale
   - Important code implemented: what it does, why, and how it works
   - Architecture and design choices sub-agents made autonomously
   - Anything unexpected or noteworthy from the run

4. **Given** the task report is generated
   **When** the orchestrator completes
   **Then** it exits with code 2 and the loop script terminates

5. **Given** the pipeline failed (not completed)
   **When** the loop script handles the failure
   **Then** it does NOT launch the task report generation -- task reports are only for successful completions

## Tasks / Subtasks

- [x] Task 1: Create `stage-task-report.md` prompt template (AC: #2, #3)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-task-report.md` following the standard template format with YAML frontmatter: `stage: task-report`, `agent: bmad-orchestrator`, `command: generate-task-report`, `requiredArtifacts: [state.yaml, status-report.md]`, `producedArtifacts: [task-report.md]`
  - [x] 1.2: Add Context Injection section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` per project-context.md template standard (placeholders present for consistency, unused at runtime since this stage only runs on success)
  - [x] 1.3: Add Stage Instructions section directing the orchestrator to:
    - Read ALL files in `_bmad-output/` (planning and implementation artifacts)
    - Read `.bmad-orchestrator/state.yaml` for pipeline metadata (task, route, mode, completedStages, storyLoop)
    - Read `.bmad-orchestrator/status-report.md` for stage outcomes and timing
    - Synthesize a human-readable report with the 5 required sections (AC #3)
  - [x] 1.4: Add Verification section: confirm `task-report.md` exists at `.bmad-orchestrator/task-report.md`, contains all 5 required content sections, and is non-trivial (>500 characters)

- [x] Task 2: Add task report directive handling to orchestrator agent (AC: #2, #3, #4)
  - [x] 2.1: Add a new Section 11 "Task Report Generation" to `.claude/agents/bmad-orchestrator.md` that handles the `generate-task-report` directive
  - [x] 2.2: In Section 1.2 "Determine What To Do", add a new check (BEFORE the existing terminal state checks): If `currentStage` is `task-report`, proceed to Section 11 (Task Report Generation) instead of normal Stage Execution
  - [x] 2.3: Section 11 steps:
    - 11.1: Load the `stage-task-report.md` template from `.bmad-orchestrator/templates/`
    - 11.2: Read all artifacts in `_bmad-output/` (glob for `*.md`, `*.yaml`, `*.yml`) — read complete contents, not just existence checks
    - 11.3: Read `.bmad-orchestrator/state.yaml` for pipeline metadata
    - 11.4: Read `.bmad-orchestrator/status-report.md` for stage outcomes
    - 11.5: Synthesize the task report with these sections:
      - **Summary of Work Accomplished:** What was built, what problem it solves, what the pipeline produced end-to-end
      - **Key Decisions Made:** Significant choices made during execution (routing, architecture, technology selections, trade-offs resolved) with rationale
      - **Important Code Implemented:** What code was written, which files, what each component does, how they work together
      - **Architecture and Design Choices:** Patterns chosen, structural decisions, integration approaches — especially anything sub-agents decided autonomously
      - **Notable Observations:** Anything unexpected, retries that happened, concerns raised, Party Mode brainstorming results, or caveats the developer should know
    - 11.6: Write the report to `.bmad-orchestrator/task-report.md`
    - 11.7: Exit with code 2 (pipeline complete — this is the final action)
  - [x] 2.4: The task report generation does NOT go through normal verification (Section 5) — it is a self-contained final step. The orchestrator writes the file directly (this is an exception to the boundary rule because no sub-agent is involved)

- [x] Task 3: Modify loop.sh to launch task report generation after successful completion (AC: #1, #4, #5)
  - [x] 3.1: In `handle_exit_code` case `2` (COMPLETED): AFTER writing the status report, add task report generation launch. The flow becomes:
    1. Write COMPLETED status report (existing)
    2. Log "Generating task report..."
    3. Launch orchestrator one more time (same `launch_agent` function)
    4. Capture exit code (expect 2 — task report complete)
    5. If exit code is NOT 2, log warning but do NOT fail — status report is already written, task report is best-effort
    6. Return 2 (pipeline complete)
  - [x] 3.2: CRITICAL: Before launching the task report agent, update `state.yaml` to set `currentStage: task-report`. This is the ONE exception to the "loop script NEVER writes state" boundary rule. Alternative: have the orchestrator detect "I just completed successfully, check if task-report is needed" — but this is less clean because the orchestrator would need to distinguish between "pipeline just completed" vs "task report already done". The cleaner approach: modify state in loop.sh to signal the directive.
  - [x] 3.3: **WAIT — Reconsider 3.2.** The architecture says "Loop script reads state but NEVER writes to it" (Boundary Rule). Instead of loop.sh modifying state: Pass the directive via the agent launch mechanism. The loop script already launches the agent via `claude --agent bmad-orchestrator`. Modify `launch_agent` to accept an optional prompt parameter: `launch_agent "generate-task-report"`. Pipe the directive as a prompt to the agent: `echo "generate-task-report" | claude --agent bmad-orchestrator`. The orchestrator then reads this initial prompt to know its purpose, AND reads state.yaml for context.
  - [x] 3.4: Modify `launch_agent` to accept an optional prompt parameter. Default behavior (no parameter) launches normally. With parameter, pipes it to the agent command. This maintains the boundary rule.
  - [x] 3.5: Only launch task report for exit code 2 (COMPLETED). Exit codes 1 (FAILED), 3 (PAUSED), and * (CRASHED) do NOT trigger task report generation — per AC #5.

- [x] Task 4: Write bats tests for task report generation (AC: #1-#5)
  - [x] 4.1: Add tests to `tests/orchestrator-agent.bats` validating orchestrator task report handling:
    - Agent describes task-report stage handling in Section 11
    - Agent describes reading all _bmad-output/ artifacts for task report
    - Agent describes reading state.yaml and status-report.md for task report context
    - Agent describes writing task-report.md with required content sections
    - Agent describes exiting with code 2 after task report generation
    - Agent describes task-report stage check in Section 1.2
  - [x] 4.2: Add tests to `tests/orchestrator-agent.bats` validating template:
    - Template exists at .bmad-orchestrator/templates/stage-task-report.md
    - Template contains correct frontmatter (stage: task-report, producedArtifacts)
    - Template contains Context Injection section
    - Template contains Stage Instructions section
    - Template contains Verification section
  - [x] 4.3: Add tests to `tests/loop.bats` validating loop.sh task report launch:
    - Loop script launches task report agent on COMPLETED (exit code 2)
    - Loop script does NOT launch task report on FAILED (exit code 1)
    - Loop script does NOT launch task report on PAUSED (exit code 3)
    - Loop script does NOT launch task report on CRASHED (unexpected exit code)
    - launch_agent function accepts optional prompt parameter
  - [x] 4.4: Use test naming pattern: `@test "TaskReport 5.3-N: description"` for all tests
  - [x] 4.5: Verify all existing tests still pass (zero regressions on all 546 existing tests)

- [ ] Task 5: Manual verification (AC: #1-#5) -- MANUAL
  - [ ] 5.1: Trace COMPLETED flow: all stages pass -> exit 2 -> handle_exit_code -> write COMPLETED status report -> launch task report agent -> orchestrator reads artifacts -> writes task-report.md -> exits 2 -> loop terminates
  - [ ] 5.2: Trace FAILED flow: stage fails -> exit 1 -> handle_exit_code -> write FAILED status report -> NO task report launch -> loop terminates
  - [ ] 5.3: Verify task-report.md contains all 5 required content sections
  - [ ] 5.4: Verify boundary rule compliance: loop.sh does NOT write to state.yaml

## Dev Notes

### Architecture Compliance

**This story creates 1 new file and modifies 3 existing files:**
- `.bmad-orchestrator/templates/stage-task-report.md` -- **NEW** -- Task report prompt template following standard frontmatter format
- `.claude/agents/bmad-orchestrator.md` -- **MODIFIED** -- Add Section 11 (Task Report Generation), add task-report check in Section 1.2
- `.bmad-orchestrator/loop.sh` -- **MODIFIED** -- Add task report launch after COMPLETED, modify `launch_agent` to accept optional prompt parameter
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add ~15-25 TaskReport 5.3-N tests
- `tests/loop.bats` -- **MODIFIED** -- Add ~5-10 TaskReport 5.3-N tests

### What Makes This Story UNIQUE

**Story 5.3 is the FINAL story in Epic 5 and the FINAL story in the entire project.** It adds the human knowledge transfer document that makes autonomous runs actually useful — without it, the developer gets working code but no understanding of what happened.

**Key distinction from Stories 5.1 and 5.2:**
- Story 5.1: per-stage incremental logging (during pipeline execution, in orchestrator agent)
- Story 5.2: final summary report (after pipeline completion/failure, in loop.sh)
- Story 5.3: task report generation (human knowledge transfer document, post-completion only)

**Story 5.3 is architecturally unique because:**
- It's the ONLY stage where the orchestrator writes a file directly (not via sub-agent) — justified because the orchestrator itself is synthesizing knowledge, not delegating to a BMAD workflow
- The loop.sh must break its normal dispatch pattern to launch a second agent iteration after COMPLETED
- It introduces a new communication pattern: loop.sh passes a directive to the orchestrator (not via state.yaml)

### Current Implementation — What Already Exists

**loop.sh exit code 2 handling currently does:**
```bash
2)
  log "Pipeline complete. All stages finished successfully."
  local artifact_inventory
  artifact_inventory="$(generate_artifact_inventory "_bmad-output")"
  write_status_report "COMPLETED" "${ITERATION:-0}" "${elapsed_time}" "${completed_stages}" "${artifact_inventory}"
  return 2
  ;;
```

**What's MISSING (the gaps this story fills):**
- No task report template exists (`stage-task-report.md`)
- No task report handling in orchestrator agent (no Section 11, no `task-report` stage check)
- No task report launch in loop.sh after COMPLETED
- No mechanism for loop.sh to pass a directive to the orchestrator (currently launches with no arguments)

### Critical Design Decision: Directive Communication via Piped Prompt

**Challenge:** How does loop.sh tell the orchestrator to generate a task report instead of running the next pipeline stage?

**Rejected approach:** Modify `state.yaml` to set `currentStage: task-report`. This violates the "loop script NEVER writes state" boundary rule.

**Chosen approach:** Pipe a directive string to the agent via stdin. Modify `launch_agent` to accept an optional parameter:
```bash
launch_agent() {
  local prompt="${1:-}"
  if [[ -n "${prompt}" ]]; then
    log "Launching orchestrator agent with directive: ${prompt}"
    echo "${prompt}" | claude --agent bmad-orchestrator
  else
    log "Launching orchestrator agent..."
    claude --agent bmad-orchestrator
  fi
}
```

The orchestrator then checks for this directive in Section 1.2 (before terminal state checks). This maintains the boundary rule while providing clean communication.

### Critical Design Decision: Task Report Is Self-Contained

**The task report stage does NOT use the normal verification flow (Section 5).** The orchestrator reads all artifacts, synthesizes the report, writes it, and exits. No sub-agent is involved. No producedArtifacts verification loop.

**Why:** The task report is a knowledge synthesis task, not a BMAD workflow delegation. The orchestrator is the right entity to synthesize across all artifacts. Launching a sub-agent just to read files and write a summary would add complexity without value.

**Boundary rule exception:** The orchestrator normally "NEVER directly writes BMAD artifacts" (Section 9). The task report is NOT a BMAD artifact — it lives in `.bmad-orchestrator/task-report.md`, which is the orchestrator's own runtime directory. This is consistent with the orchestrator's existing writes to `state.yaml` and `status-report.md` in the same directory.

### Critical Design Decision: Best-Effort Task Report

**If the task report generation fails (agent crashes, template missing, etc.), the pipeline is still COMPLETED.** The status report is already written, all artifacts exist, all stages passed. The task report is supplementary.

**Implementation:** loop.sh captures the task report agent's exit code. If it's not 2, log a warning but still exit 0 (success). The status report and all artifacts are already safely written.

### Critical Design Decision: Orchestrator Detects Directive

**The orchestrator needs to distinguish between:**
1. Normal launch (read state, execute currentStage)
2. Task report directive (read all artifacts, write task-report.md)

**Approach in Section 1.2:** Add check before terminal state checks:
- If `currentStage` is `task-report` OR the initial prompt contains "generate-task-report" → goto Section 11
- This dual-detection (state file OR prompt) provides robustness

**Alternative considered:** Only check the piped prompt. Rejected because: if the agent crashes mid-task-report and loop.sh re-detects exit code 2 from the status already written, it might re-launch without the directive. Having `task-report` as a recognizable stage in state provides idempotency.

**Resolution:** The orchestrator checks both. On first task report launch, the piped prompt triggers Section 11. The orchestrator updates state to `currentStage: task-report` atomically before writing the report (consistent with state always reflecting true pipeline state). If relaunched, it detects `currentStage: task-report` from state.

**Wait — this means the orchestrator DOES update state for task-report.** Yes, and this is correct behavior. The orchestrator has always been the entity that updates state (per boundary rules). Setting `currentStage: task-report` is the orchestrator's job, not loop.sh's.

### Previous Story Intelligence (Story 5.2)

**Key learnings from Story 5.2:**
- 45 new tests added (FinalReport 5.2-1 through 5.2-45), total went from 467 to 512
- Test naming pattern: `@test "FinalReport 5.2-N: description"` -> Story 5.3 uses `@test "TaskReport 5.3-N: description"`
- Story 5.2 modified `loop.sh` extensively (6 new functions, rewrote write_status_report and handle_exit_code)
- Story 5.2 modified `tests/loop.bats` to update 5 tests for new write_status_report signature
- Code review found 6 regressions in loop.bats from signature change — be careful with function signature changes
- The `generate_artifact_inventory` function in loop.sh lists all files in `_bmad-output/` — can be referenced for understanding artifact structure
- `write_status_report` now takes 5 parameters: overall_status, iterations, elapsed_time, completed_stages, extra_details

**Patterns to follow:**
- Tests validate that agent documentation describes the behavior (bats tests grep agent/template files)
- Tests validate that loop.sh functions contain expected logic
- Expect ~20-35 new tests total across both test files
- Maintain zero regressions on all 512 existing tests

### Git Intelligence

- Latest commit: `feat: add final status report and failure details (story 5-2)` (457b76d)
- Previous: `feat: add stage-level status logging (story 5-1)` (7f11ef8)
- Commit pattern: `feat: <description> (story X-Y)`
- Total tests: 512, all passing
- `loop.sh` was extensively modified in Story 5.2 (6 new functions, enhanced handle_exit_code and write_status_report)
- Orchestrator agent was modified in Story 5.1 (Sections 6, 7.3, 7.4, 9)
- Neither file has been modified for task report functionality yet

### Bash Standards (from project-context.md)

- `set -euo pipefail` already present in loop.sh
- All variables must be quoted: `"${var}"`
- All local variables declared with `local`
- Functions use `snake_case`
- ShellCheck compliant
- Exit codes documented at top of script

### Template Format (from architecture.md)

Every template must have:
```markdown
---
stage: <identifier>
agent: <agent-name>
command: <command>
requiredArtifacts: [<paths>]
producedArtifacts: [<paths>]
---

## Context Injection
{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions
[Instructions]

## Verification
[Validation criteria]
```

### Anti-Patterns to Avoid

- Loop.sh writing to `state.yaml` directly — boundary rule violation (orchestrator updates state, not loop.sh)
- Making task report generation block pipeline success — it's best-effort, supplementary
- Launching a sub-agent for task report — the orchestrator itself synthesizes the knowledge
- Running task report on failed pipelines — AC #5 explicitly forbids this
- Skipping the template file — even though the orchestrator doesn't delegate to a sub-agent, the template provides structure and documentation
- Modifying `write_status_report` signature again — Story 5.2's code review found regressions from this; avoid unnecessary signature changes
- Adding `task-report` to the frozen stage identifiers list — it's a special directive, not a pipeline stage in the normal sequence

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-task-report.md` -- NEW: Task report prompt template
- `.claude/agents/bmad-orchestrator.md` -- MODIFIED: Add Section 11, add task-report check in Section 1.2
- `.bmad-orchestrator/loop.sh` -- MODIFIED: Add task report launch in handle_exit_code case 2, modify launch_agent to accept optional prompt
- `tests/orchestrator-agent.bats` -- MODIFIED: Add ~15-25 TaskReport 5.3-N tests
- `tests/loop.bats` -- MODIFIED: Add ~5-10 TaskReport 5.3-N tests
- No changes to `.claude/commands/bmad-orchestrate.md`
- `.bmad-orchestrator/task-report.md` is a RUNTIME file (not checked in, produced during execution)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.3] -- Full acceptance criteria: task report after successful completion with 5 content sections
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 5] -- Status Reporting & Run Observability epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] -- No FRs directly map to 5.3 (it's derived from the architecture's data flow)
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Flow] -- "loop.sh launches orchestrator with 'generate-task-report' directive -> Orchestrator reads all produced artifacts, state file, status report -> Orchestrator synthesizes human-readable Task Report -> Writes .bmad-orchestrator/task-report.md"
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- `stage-task-report.md` listed in templates directory, `task-report.md` listed as runtime file
- [Source: _bmad-output/planning-artifacts/architecture.md#Boundary Rules] -- "Loop script reads state but NEVER writes to it", "Orchestrator agent reads/writes state"
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] -- Standard template structure with frontmatter, Context Injection, Stage Instructions, Verification
- [Source: _bmad-output/planning-artifacts/architecture.md#Logging] -- "All logs consolidated into .bmad-orchestrator/status-report.md"
- [Source: _bmad-output/planning-artifacts/prd.md#FR38-40] -- Status reporting FRs (task report extends these)
- [Source: _bmad-output/project-context.md#Boundary Rules] -- "Loop script reads state but NEVER writes to it"
- [Source: _bmad-output/project-context.md#Bash Scripting Rules] -- set -euo pipefail, quoted variables, snake_case, ShellCheck
- [Source: _bmad-output/project-context.md#File Naming Rules] -- kebab-case, stage-{identifier}.md template pattern
- [Source: _bmad-output/project-context.md#Exit Code Convention] -- 0/1/2/3 convention
- [Source: .bmad-orchestrator/loop.sh#handle_exit_code] -- Current exit 2 handling: writes COMPLETED status report, returns 2
- [Source: .bmad-orchestrator/loop.sh#launch_agent] -- Current implementation: `claude --agent bmad-orchestrator` with no parameters
- [Source: .bmad-orchestrator/loop.sh#main] -- Loop flow: preflight -> iteration loop -> launch_agent -> handle_exit_code
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] -- "Determine What To Do" — terminal state checks, routing, stage execution dispatch
- [Source: .claude/agents/bmad-orchestrator.md#Section 2] -- Pipeline stage sequences — task-report is NOT in these sequences (special directive)
- [Source: .claude/agents/bmad-orchestrator.md#Section 8] -- Exit code protocol: code 2 = pipeline complete
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] -- Boundary rules: orchestrator reads/writes state, never writes BMAD artifacts, appends to status-report.md
- [Source: _bmad-output/implementation-artifacts/5-2-final-status-report-failure-details.md] -- Previous story: 512 tests, loop.sh extensively modified, write_status_report rewritten with 5-arg signature, handle_exit_code enhanced
- [Source: _bmad-output/implementation-artifacts/5-1-stage-level-status-logging.md] -- Orchestrator agent modification patterns, Section 7.3/7.4/6/9 modified, 467->512 tests via 5.2

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

### Completion Notes List

- Task 1: Created `.bmad-orchestrator/templates/stage-task-report.md` with YAML frontmatter (stage: task-report, agent: bmad-orchestrator, command: generate-task-report), Context Injection with {{task_description}} only (no failure_context/mode_instructions per AC), Stage Instructions for reading all artifacts and synthesizing 5 required sections, and Verification section with existence/content/length checks.
- Task 2: Added Section 11 "Task Report Generation" to orchestrator agent with subsections 11.1-11.7 covering template loading, artifact reading, metadata reading, status reading, report synthesis, file writing, and exit code 2. Added task-report/generate-task-report check as item 0 in Section 1.2 (before terminal state checks) with idempotency via atomic state update. Updated execution flow summary to include step 12 for task report.
- Task 3: Modified `launch_agent` to accept optional prompt parameter — pipes directive via stdin when provided, maintains normal launch when no parameter. Added task report generation to `handle_exit_code` case 2: logs "Generating task report...", launches agent with "generate-task-report" directive, captures exit code, warns on non-2 exit (best-effort). Added BATS_TESTING guard to launch_agent to prevent test hangs. Boundary rule maintained: loop.sh does NOT write to state.yaml.
- Task 4: Added 36 tests in orchestrator-agent.bats (24 template: 5.3-1 to 5.3-24, 12 agent: 5.3-25 to 5.3-36), plus 10 tests in loop.bats (5.3-37 to 5.3-46). All 592 tests pass (zero regressions on 546 pre-existing tests). Test naming follows pattern `@test "TaskReport 5.3-N: description"`.

### File List

- `.bmad-orchestrator/templates/stage-task-report.md` — NEW: Task report prompt template
- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Added Section 11 (Task Report Generation), added task-report check in Section 1.2
- `.bmad-orchestrator/loop.sh` — MODIFIED: Modified launch_agent to accept optional prompt, added task report launch in handle_exit_code case 2, added BATS_TESTING guard
- `tests/orchestrator-agent.bats` — MODIFIED: Added 36 TaskReport 5.3-N tests (template + agent validation)
- `tests/loop.bats` — MODIFIED: Added 9 TaskReport 5.3-N tests (loop.sh validation)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED: Updated 5-3-task-report-generation status
- `_bmad-output/implementation-artifacts/5-3-task-report-generation.md` — MODIFIED: Task checkboxes, Dev Agent Record, File List, Change Log, Status

## Change Log

- 2026-02-04: Implemented task report generation (Story 5.3) — created template, added Section 11 to orchestrator agent, modified loop.sh for task report launch, added 45 new tests (591 total, zero regressions)
- 2026-02-04: Code review fixes — (M1) corrected pre-existing test baseline from 512 to 546, (M2) added {{failure_context}} and {{mode_instructions}} to template for project-context.md compliance, updated tests 5.3-10/5.3-11 to verify presence, (M3) added behavioral test 5.3-45 with launch_agent spy verifying generate-task-report directive, renumbered ShellCheck test to 5.3-46. Total: 592 tests, zero regressions.

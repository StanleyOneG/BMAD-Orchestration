# Story 1.2: Ralph Loop Script

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want a loop script that manages the agent lifecycle,
so that each pipeline stage runs with fresh context and the pipeline progresses automatically.

## Acceptance Criteria

1. **Given** `state.yaml` exists with `status: running`
   **When** `loop.sh` is executed
   **Then** the script launches the orchestrator agent via `claude --agent bmad-orchestrator`
   **And** the script waits for the agent to exit

2. **Given** the agent exits with code 0 (stage completed)
   **When** the loop script detects the exit
   **Then** the script relaunches the agent with fresh context for the next stage

3. **Given** the agent exits with code 1 (failed after retries)
   **When** the loop script detects the exit
   **Then** the loop stops and reports the failure

4. **Given** the agent exits with code 2 (pipeline complete)
   **When** the loop script detects the exit
   **Then** the loop stops and reports success

5. **Given** the agent exits with code 3 (checkpoint pause)
   **When** the loop script detects the exit
   **Then** the loop stops and instructs the user to review and resume

6. **Given** the agent crashes with an unexpected exit code
   **When** the loop script detects a non-clean exit
   **Then** the crash is logged to `status-report.md`
   **And** the loop stops rather than silently restarting

7. **Given** `loop.sh` is run
   **When** the script starts
   **Then** it verifies it is NOT on `main` or `master` branch before launching the agent

8. **Given** the script follows bash best practices
   **When** reviewed
   **Then** the script starts with `set -euo pipefail`, all variables are quoted, functions use `snake_case` with `local` declarations, and it passes ShellCheck

## Tasks / Subtasks

- [x] Task 1: Create the loop script file (AC: #1, #7, #8)
  - [x] 1.1: Create `.bmad-orchestrator/loop.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 1.2: Document exit codes at top of script in a comment block
  - [x] 1.3: Implement `check_branch_safety` function -- detect `main`/`master` and exit with error
  - [x] 1.4: Implement `read_state` function -- read `.bmad-orchestrator/state.yaml` and extract `status` field
  - [x] 1.5: Implement pre-flight check: verify `state.yaml` exists before entering loop, fail with clear error if missing

- [x] Task 2: Implement agent launch and exit code handling (AC: #1, #2, #3, #4, #5, #6)
  - [x] 2.1: Implement `launch_agent` function -- invokes `claude --agent bmad-orchestrator` with prompt piped for state context
  - [x] 2.2: Capture exit code from agent process (use `set +e` around agent call, then `set -e` after capturing `$?`)
  - [x] 2.3: Implement exit code 0 handler -- log "Stage completed", relaunch (continue loop)
  - [x] 2.4: Implement exit code 1 handler -- log "Pipeline failed", write failure to status report, break loop
  - [x] 2.5: Implement exit code 2 handler -- log "Pipeline complete", write success to status report, break loop
  - [x] 2.6: Implement exit code 3 handler -- log "Checkpoint pause", instruct user to review and `--resume`, break loop
  - [x] 2.7: Implement unexpected exit code handler -- log crash to `status-report.md` with exit code, break loop (NEVER silently restart)

- [x] Task 3: Implement status report writing (AC: #3, #4, #5, #6)
  - [x] 3.1: Implement `write_status_report` function -- appends entries to `.bmad-orchestrator/status-report.md`
  - [x] 3.2: If `status-report.md` doesn't exist, create it with header (task description, route, mode, start timestamp)
  - [x] 3.3: On pipeline completion (exit 2): append summary with overall status COMPLETED and total iterations
  - [x] 3.4: On pipeline failure (exit 1): append summary with overall status FAILED, failure stage, and recovery instructions (`--resume` command)
  - [x] 3.5: On checkpoint pause (exit 3): append summary with overall status PAUSED, checkpoint stage, and resume instructions
  - [x] 3.6: On agent crash (unexpected exit): append crash entry with exit code and "Agent terminated unexpectedly" message

- [x] Task 4: Main loop implementation and script finalization (AC: #1, #2, #7, #8)
  - [x] 4.1: Implement main loop: `while true` with agent launch and exit code dispatch
  - [x] 4.2: Add iteration counter to prevent infinite loops (safety valve, e.g., max 100 iterations)
  - [x] 4.3: Make script executable (`chmod +x`)
  - [x] 4.4: Run ShellCheck and fix any warnings (no suppressed warnings without explanatory comment)
  - [x] 4.5: Verify all variables are quoted with `"${var}"` pattern

## Dev Notes

### Architecture Compliance

**This story creates exactly 1 file:**
- `.bmad-orchestrator/loop.sh` -- The Ralph Loop bash script

**This is a bash script, NOT a Claude Code agent or slash command.** It is the outer control layer of the Ralph Loop pattern. The loop script manages the agent lifecycle; the agent (Story 1.3) handles the actual workflow execution.

### Exit Code Convention (from Architecture -- use EXACTLY)

| Code | Meaning | Loop Behavior |
|------|---------|---------------|
| 0 | Stage completed, continue | Relaunch agent |
| 1 | Failed after retries, stop | Stop loop, report failure |
| 2 | Pipeline complete, stop | Stop loop, report success |
| 3 | Checkpoint pause, stop | Stop loop, instruct review |
| * | Unexpected crash | Stop loop, log crash |

### Agent Invocation Pattern

The agent is launched via: `claude --agent bmad-orchestrator`

The orchestrator agent definition (`.claude/agents/bmad-orchestrator.md`) will be created in Story 1.3. For this story, the loop script must correctly invoke it even if the agent file doesn't exist yet -- focus on the loop mechanics, exit code handling, and status reporting.

### Boundary Rules (CRITICAL)

- **Loop script reads state but NEVER writes to it** -- state file updates are the orchestrator agent's responsibility
- Loop script reads `state.yaml` ONLY to check if `status` is already `completed` or `failed` before launching (pre-flight check)
- Loop script NEVER modifies `_bmad-output/` artifacts
- Loop script's only write target is `.bmad-orchestrator/status-report.md` (the operational run report)

### Bash Standards (from Architecture and project-context.md)

- Script starts with `set -euo pipefail`
- All variables quoted: `"${var}"` not `$var`
- Functions use `snake_case`: `check_branch_safety`, `read_state`, `launch_agent`, `write_status_report`
- All function variables declared with `local`
- ShellCheck compliant -- no suppressed warnings without a comment explaining why
- Exit codes documented at the top of the script

### Status Report Format

`.bmad-orchestrator/status-report.md` is append-only. Each entry follows this general pattern:

```markdown
## Run Started
- **Task:** <task from state.yaml>
- **Route:** <route from state.yaml>
- **Mode:** <mode from state.yaml>
- **Started:** <ISO-8601 timestamp>

## Stage: <stage-name>
- **Outcome:** PASS | FAIL | CRASH
- **Timestamp:** <ISO-8601>
- **Details:** <one-line summary>

## Run Summary
- **Overall Status:** COMPLETED | FAILED | PAUSED | CRASHED
- **Total Iterations:** <count>
- **Details:** <summary>
```

Note: The loop script creates the header and writes the final summary. Stage-level entries may also be written by the orchestrator agent (Story 1.3+). The loop script appends crash/completion entries.

### Reading state.yaml from Bash

The state file uses camelCase YAML fields. To extract values in bash without introducing a Python/yq dependency, use `grep` and simple parsing:

```bash
# Example pattern for reading a field
local status
status=$(grep '^status:' "${STATE_FILE}" | awk '{print $2}' | tr -d '"')
```

Alternatively, if `yq` is available, that's cleaner but adds a dependency. Keep it simple -- `grep`/`awk` is sufficient for the few fields the loop script needs to read.

### Previous Story Intelligence (Story 1.1)

**What was built:**
- `.claude/commands/bmad-orchestrate.md` -- Claude Code slash command that creates the initial `state.yaml`
- State file uses atomic write pattern (write to `.tmp`, then `mv`)
- State file schema is defined with all fields in camelCase

**Key learnings:**
- The slash command is a markdown prompt template, not a bash script
- Slash command does NOT launch `loop.sh` -- it only creates state and tells the user to run `loop.sh` manually
- This is the handoff: slash command creates state.yaml, user runs loop.sh, loop.sh launches orchestrator agent

**Implications for this story:**
- `loop.sh` is the user's entry point AFTER running `/bmad-orchestrate`
- The state file will already exist with `status: running` when `loop.sh` is first invoked
- The `.bmad-orchestrator/` directory will already exist (created by the slash command)

### Git Intelligence

Recent commits show Story 1.1 was implemented creating the slash command file. The implementation followed all architecture conventions (atomic writes, camelCase fields, branch safety). No unexpected patterns or deviations.

### Project Structure Notes

- `.bmad-orchestrator/loop.sh` is a checked-in file (part of the project, not runtime-generated)
- `.bmad-orchestrator/status-report.md` is a runtime file (generated during execution, not checked in)
- `.bmad-orchestrator/state.yaml` already exists at runtime (created by slash command in Story 1.1)
- The orchestrator agent (`.claude/agents/bmad-orchestrator.md`) does NOT exist yet (Story 1.3)

### Anti-Patterns to Avoid

- Loop script modifying `state.yaml` -- NEVER do this
- Silently restarting on unexpected exit codes -- ALWAYS log and stop
- Unquoted variables in bash -- ALWAYS use `"${var}"`
- Direct writes to `_bmad-output/` -- the loop script NEVER writes there
- Suppressing ShellCheck warnings without explanatory comments
- Using `$var` instead of `"${var}"`
- Multi-line error messages (keep all log entries as single-line summaries)

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] -- Exit code convention and loop responsibilities
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] -- How orchestrator interacts with sub-agents
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- Where loop.sh lives
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] -- Bash standards, naming
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries] -- Loop script boundary (reads state, never writes)
- [Source: _bmad-output/planning-artifacts/prd.md#Execution Architecture -- Ralph Loop Pattern] -- Ralph Loop definition and anti-patterns
- [Source: _bmad-output/planning-artifacts/prd.md#Status Reporting] -- FR38-FR40 status report requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.2] -- Full acceptance criteria
- [Source: _bmad-output/project-context.md#Bash Scripting Rules] -- All bash implementation rules
- [Source: _bmad-output/project-context.md#Exit Code Convention] -- Exit code definitions
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Loop script never modifies state
- [Source: _bmad-output/implementation-artifacts/1-1-slash-command-state-file-initialization.md] -- Previous story context and learnings

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

N/A - clean implementation, no debug issues encountered.

### Completion Notes List

- Implemented `.bmad-orchestrator/loop.sh` with all 4 tasks (22 subtasks) completed
- Script follows all bash standards: `set -euo pipefail`, quoted variables, `snake_case` functions, `local` declarations
- ShellCheck passes with zero warnings
- `check_branch_safety()` - rejects `main`/`master`, allows feature branches
- `read_state()` - extracts YAML fields via grep/sed (no external dependencies)
- `preflight_check()` - validates state.yaml exists and status is not completed/failed
- `launch_agent()` - invokes `claude --agent bmad-orchestrator`; exit code captured via `set +e`/`set -e` in main()
- `handle_exit_code()` - full dispatch: 0=relaunch, 1=fail, 2=complete, 3=pause, *=crash
- `write_status_report()` - creates header on first call, appends run summary with status/iterations/details, adds resume instructions for FAILED/PAUSED
- Main loop uses `while true` with iteration counter and MAX_ITERATIONS=100 safety valve
- `BATS_TESTING` env var guard prevents main() execution during test sourcing
- `TEST_BMAD_DIR` env var allows tests to override paths for isolation
- Boundary rules respected: script reads state.yaml but NEVER writes to it; only writes to status-report.md
- 34 bats tests covering all tasks, subtasks, and acceptance criteria

### Change Log

- 2026-02-03: Initial implementation of all tasks (Task 1-4) with 29 passing tests
- 2026-02-03: Code review fixes — 3 HIGH and 4 MEDIUM issues resolved, test count 29→34

### File List

- `.bmad-orchestrator/loop.sh` (MODIFIED) - Ralph Loop bash script
- `tests/loop.bats` (MODIFIED) - 34 bats tests for loop.sh
- `package.json` (NEW) - bats test runner dependency
- `package-lock.json` (NEW) - lockfile for bats dependency

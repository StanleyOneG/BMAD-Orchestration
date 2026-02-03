# Story 2.7: File Reference Detection & Resume Capability

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to pick up file references in my task description and resume failed runs from where they left off,
so that I can provide richer context and never lose completed work.

## Acceptance Criteria

1. **Given** a task description containing a file path like "implement the feature described in docs/feature-spec.md"
   **When** the orchestrator processes the task
   **Then** it detects the file reference, reads the file contents, and includes them as additional context when launching sub-agents

2. **Given** a task description with multiple file references
   **When** the orchestrator processes the task
   **Then** all referenced files are detected and loaded as context

3. **Given** a task description references a file that does not exist
   **When** the orchestrator processes the task
   **Then** it logs a warning but continues with the available context rather than failing

4. **Given** the user runs `/bmad-orchestrate --resume`
   **When** `state.yaml` exists with `status: running` or `status: failed`
   **Then** `state.yaml` is updated with `runType: resume` and the orchestrator continues from the last completed stage

5. **Given** the user runs `/bmad-orchestrate --resume`
   **When** no `state.yaml` exists
   **Then** the command fails with a clear error: "No previous run found to resume."

6. **Given** a resumed run
   **When** the orchestrator launches
   **Then** it respects all existing artifacts and completed stages, picking up exactly where the previous run stopped

## Tasks / Subtasks

- [x] Task 1: Implement file reference detection in the orchestrator agent (AC: #1, #2, #3)
  - [x] 1.1: Add a new Section 1.3 "File Reference Detection" to `.claude/agents/bmad-orchestrator.md` that executes AFTER Section 1.2 (Determine What To Do) and BEFORE Section 3 (Template Loading). This section:
    - Reads the `task` field from `state.yaml`
    - Scans the task text for file path patterns using these heuristics:
      - Explicit paths: strings matching common file patterns like `path/to/file.ext`, `./relative/path`, `../parent/path`, `docs/something.md`
      - Quoted paths: strings inside quotes that look like file paths
      - Common extensions: `.md`, `.yaml`, `.yml`, `.json`, `.txt`, `.ts`, `.js`, `.py`, `.sh`, `.toml`, `.cfg`
      - Exclude: URLs (http://, https://), email addresses, CLI flags (--flag)
    - For each detected file reference:
      - Attempt to read the file from disk
      - If file exists: store its contents in a `fileContext` session variable (map of path → content)
      - If file does NOT exist: log a warning message to the console (e.g., "Warning: Referenced file not found: docs/feature-spec.md — continuing without it") but do NOT fail or halt
    - Store the `fileContext` as a state-agnostic session variable (NOT persisted to `state.yaml` — file contents are re-read on each cold start from the `task` field)
  - [x] 1.2: In Section 4 (Sub-Agent Interaction), add documentation that when `fileContext` is populated, the orchestrator includes the referenced file contents as additional context alongside the task description when launching sub-agents. Format: "Referenced file: {path}\n{contents}" appended after `{{task_description}}`
  - [x] 1.3: Ensure renumbering of existing sections is handled cleanly. Current sections: 1 (Cold Start), 2 (Pipeline Stage Sequences), 3 (Template Loading), 4 (Sub-Agent Interaction), 5 (Verification), 6 (Failure Handling), 7 (State Update Protocol), 8 (Exit Code Protocol), 9 (Boundary Rules), 10 (Execution Flow Summary). The new file reference detection fits as a substep within Section 1 (after 1.2) or as Section 1.3, preserving existing numbering

- [x] Task 2: Verify and document resume capability in orchestrator agent (AC: #4, #6)
  - [x] 2.1: Verify the orchestrator agent already handles resume correctly by reviewing Section 1.2 (Determine What To Do). The existing logic:
    - `status: running` with `currentStage` set → proceeds to Stage Execution (Section 2) — this correctly handles resumed runs where the previous stage completed
    - `status: paused` → updates to `running` and proceeds — handles checkpoint resume
    - `status: failed` → exits with code 1 — BUT this needs attention: on `--resume` the slash command sets `status: running`, so by the time the orchestrator sees it, it's already `running`
    - `storyLoop` populated with stories at various statuses → correctly picks up the first non-completed story — handles mid-story-loop resume
  - [x] 2.2: Verify the slash command (`bmad-orchestrate.md`) already handles `--resume` correctly:
    - Step 2: Resume Handling — reads existing `state.yaml`, updates `runType: resume`, `status: running`, `updatedAt`
    - If no `state.yaml`: fails with clear error (AC #5)
    - Atomic write pattern used
    - **VERIFY:** The slash command sets `status: running` even when the previous status was `failed` — this is correct because on resume, the orchestrator should retry from where it left off, not exit immediately
  - [x] 2.3: Add explicit documentation in the orchestrator agent about resume behavior. In Section 1 or as a note after Section 1.2, add:
    - "**Resume Behavior:** When `runType: resume`, the orchestrator's cold-start logic in Section 1.2 handles resume transparently. The slash command has already set `status: running` and preserved `currentStage` and `completedStages`. The orchestrator simply reads the current state and continues from `currentStage`. No special resume branching is needed in the orchestrator — the state file IS the resume mechanism."
    - "**Artifact Respect on Resume:** On resume runs, the orchestrator does not regenerate completed stages. `completedStages` tracks what's done, `currentStage` tracks what's next, and `storyLoop` tracks individual story progress. The orchestrator trusts these and picks up exactly where the previous run stopped."

- [x] Task 3: Verify slash command resume handles edge cases (AC: #4, #5)
  - [x] 3.1: Review `bmad-orchestrate.md` Step 2 (Resume Handling) for correctness:
    - Already handles: `state.yaml` exists → update runType + status + updatedAt → atomic write
    - Already handles: no `state.yaml` → error message
    - **VERIFY:** Works when previous `status` was `failed` (sets to `running` so orchestrator retries)
    - **VERIFY:** Works when previous `status` was `paused` (sets to `running` so orchestrator continues from checkpoint)
    - **VERIFY:** Works when previous `status` was `running` (e.g., crash — sets to `running`, no change needed)
    - **VERIFY:** `currentStage` and `storyLoop` are preserved (slash command only modifies `runType`, `status`, `updatedAt`)
  - [x] 3.2: If any edge cases are missing, document and fix them in `bmad-orchestrate.md`

- [x] Task 4: Write bats tests for file reference detection and resume capability (AC: #1, #2, #3, #4, #5, #6)
  - [x] 4.1: Add tests to `tests/orchestrator-agent.bats` validating file reference detection in orchestrator agent:
    - Agent describes file reference detection from task description
    - Agent mentions scanning for file paths in the task text
    - Agent describes handling when referenced file exists (read and include as context)
    - Agent describes handling when referenced file does NOT exist (warning, continue)
    - Agent describes including file context when launching sub-agents
    - Agent mentions NOT persisting file contents to state.yaml
  - [x] 4.2: Add tests validating resume behavior documentation in orchestrator agent:
    - Agent describes resume behavior (transparent via state file)
    - Agent describes artifact respect on resume (completed stages honored)
  - [x] 4.3: Add tests validating slash command resume handling:
    - Slash command describes `--resume` flag handling
    - Slash command reads existing `state.yaml` on resume
    - Slash command sets `runType: resume` on resume
    - Slash command sets `status: running` on resume
    - Slash command fails with error when no `state.yaml` exists for resume
    - Slash command uses atomic write for resume update
  - [x] 4.4: Use test naming pattern: `@test "FileRef 2.7-N: description"` for file reference tests, `@test "Resume 2.7-N: description"` for resume tests
  - [x] 4.5: Verify all existing tests still pass (zero regressions on all 208 existing tests)

- [ ] Task 5: Manual verification (AC: #1, #2, #3, #4, #5, #6) — MANUAL
  - [ ] 5.1: Verify the orchestrator agent describes file reference detection
  - [ ] 5.2: Verify the orchestrator correctly describes including file context in sub-agent launches
  - [ ] 5.3: Verify `/bmad-orchestrate --resume` updates state.yaml correctly
  - [ ] 5.4: Verify orchestrator resumes from correct stage after `--resume`

## Dev Notes

### Architecture Compliance

**This story modifies 2 existing files and creates 0 new files:**
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add file reference detection (new Section 1.3) and resume behavior documentation
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add file reference detection and resume tests

**No new templates are created.** This is the first story in Epic 2 that does NOT create stage template files. It adds capabilities to the orchestrator agent and validates existing slash command behavior.

**No slash command modifications expected.** The resume capability is already fully implemented in `bmad-orchestrate.md` (Step 2: Resume Handling). This story validates and tests it, not reimplements it.

### What Makes This Story UNIQUE

**File Reference Detection is an ORCHESTRATOR-LEVEL feature, not a template feature.** Unlike stories 2.1–2.6 which created stage templates, this story adds intelligence to the orchestrator agent itself — specifically its ability to parse the `task` field and extract enrichment context before delegating to sub-agents.

**Resume capability is ALREADY IMPLEMENTED but not documented or tested.** The slash command's Step 2 handles `--resume` flag parsing, state.yaml update, and atomic write. The orchestrator's Section 1.2 cold-start logic naturally handles resumed state (reads `currentStage`, `completedStages`, `storyLoop` and picks up). This story is primarily about:
1. **Documenting** the resume flow explicitly in the orchestrator agent
2. **Testing** that both components work correctly
3. **Verifying** edge cases (failed→resume, paused→resume, crash→resume)

**File context is SESSION-SCOPED, not state-persisted.** File contents extracted from the task description are NOT stored in `state.yaml`. They are re-read from disk on each cold start by re-parsing the `task` field. This keeps the state file lean and avoids staleness issues.

### File Reference Detection Design

**Detection heuristics (from the task description text):**
- Look for patterns that match file paths: `word/word.ext`, `./path`, `../path`
- Common extensions: `.md`, `.yaml`, `.yml`, `.json`, `.txt`, `.ts`, `.js`, `.py`, `.sh`, `.toml`, `.cfg`
- Exclude URLs (`http://`, `https://`), email addresses (`@`), and CLI flags (`--`)
- Handle both quoted and unquoted paths

**Examples:**
- `"Build the feature described in docs/feature-spec.md"` → detects `docs/feature-spec.md`
- `"Implement the API from specs/api.yaml and tests/api-test.md"` → detects `specs/api.yaml`, `tests/api-test.md`
- `"Fix the login bug on https://example.com/login"` → NO detection (URL excluded)
- `"Deploy with --verbose flag"` → NO detection (CLI flag excluded)

**Context injection flow:**
```
task field in state.yaml
  → Parse for file references
  → Read each referenced file from disk
  → Store in session fileContext map
  → When launching sub-agent (Section 4):
    → Include fileContext contents alongside {{task_description}}
    → Format: "Referenced file: {path}\n---\n{contents}\n---"
```

### Resume Flow (End-to-End)

```
User runs: /bmad-orchestrate --resume
  → Slash command Step 2:
    → Read existing state.yaml
    → Update: runType=resume, status=running, updatedAt=now
    → Atomic write
  → User runs: .bmad-orchestrator/loop.sh
    → loop.sh: preflight_check passes (status=running)
    → loop.sh: launches agent
      → Orchestrator Section 1.1: reads state.yaml
      → Orchestrator Section 1.2: status=running, currentStage set → proceed
      → Orchestrator Section 3+: loads template for currentStage, continues pipeline
```

**Key insight:** The orchestrator doesn't need special resume logic because its cold-start orientation (Section 1) inherently handles any valid state. The `--resume` flag's only job is to change `status` back to `running` so the orchestrator doesn't immediately exit on `failed` or `paused` states.

### Previous Story Intelligence

**Story 2.6 (Quick Flow Pipeline):**
- Created 2 templates + 27 bats tests = 208 total tests
- No orchestrator agent modifications needed (Quick Flow already supported)
- Test naming: `@test "Template 2.6-N: description"` and `@test "QuickFlow 2.6-N: description"`
- Clean implementation, no issues

**Story 2.5 (Dev Story & Code Review Templates):**
- Created 2 templates + modified orchestrator + 35 bats tests
- Added dev-story/code-review phase transitions, git commit expectations, fresh sub-agent requirement
- Key learning: code-review failure re-routes within same story (not upstream)
- Key learning: validation stages need tri-state quality gates

### Git Intelligence

Recent commits follow pattern: `feat: <description> (story X-Y)`
- `1d9fb8a feat: add quick-spec and quick-dev stage templates (story 2-6)`
- `19ae508 feat: add dev-story and code-review stage templates with phase handling (story 2-5)`
- `4e54013 feat: add create-story template and story loop phase init (story 2-4)`
- 208 existing tests, all passing.

### Existing Code That Already Supports Resume

**Slash command (`bmad-orchestrate.md`):**
- Step 2: Full `--resume` handling already implemented
- Checks for `state.yaml` existence, updates `runType`, `status`, `updatedAt`
- Uses atomic write pattern
- Fails with clear error if no previous run

**Orchestrator agent (`bmad-orchestrator.md`):**
- Section 1.1: Reads ALL state fields
- Section 1.2: Dispatches based on `status` and `currentStage`
- `status: running` + `currentStage: <set>` → proceeds to Stage Execution
- `storyLoop` tracking naturally resumes from any story state

**Loop script (`loop.sh`):**
- `preflight_check`: validates state exists and status is `running`
- After `--resume`, status is `running`, so preflight passes
- No resume-specific logic needed in loop script

### Anti-Patterns to Avoid

- Persisting file contents in `state.yaml` (too large, goes stale on resume)
- Modifying the slash command for resume (it already works correctly)
- Adding resume-specific branches to the orchestrator's cold-start (state file IS the resume mechanism)
- Breaking existing section numbering in bmad-orchestrator.md (add 1.3, don't renumber everything)
- Detecting file paths too aggressively (exclude URLs, emails, flags)
- Failing the pipeline when a referenced file doesn't exist (warn and continue)
- Changing existing bats tests (only add new ones)
- Direct writes to state.yaml (always temp-then-rename)

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: add Section 1.3 (file reference detection) + resume documentation
- `tests/orchestrator-agent.bats` — MODIFIED: add file reference + resume tests
- No new files created in this story
- No template files created (unique among Epic 2 stories)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.7] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2] — Full Pipeline & Quick Flow Orchestration epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR2 maps to 2.7 (file reference detection), FR6 maps to 2.7 (resume)
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] — Task tool launch + resume, orchestrator as expert human
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — All fields including runType
- [Source: _bmad-output/planning-artifacts/architecture.md#Artifact Validation] — Orchestrator validates artifacts exist, doesn't write them
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] — Complete project structure
- [Source: _bmad-output/planning-artifacts/prd.md#FR2] — "Orchestrator can detect and read files referenced within the task description"
- [Source: _bmad-output/planning-artifacts/prd.md#FR6] — "User can resume a previously failed run with --resume"
- [Source: _bmad-output/planning-artifacts/prd.md#FR37] — "Orchestrator can respect existing artifacts and continue from them on --resume runs"
- [Source: _bmad-output/planning-artifacts/prd.md#Artifact Overwrite Protection] — Fresh vs resume distinction
- [Source: _bmad-output/planning-artifacts/prd.md#Agent Context Recovery] — Cold start from state file only
- [Source: _bmad-output/project-context.md#State File Rules] — Atomic temp-then-rename pattern
- [Source: _bmad-output/project-context.md#Boundary Rules] — Orchestrator never writes BMAD artifacts directly
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — Exact strings to use
- [Source: .claude/agents/bmad-orchestrator.md#Section 1] — Cold Start Orientation with state reading and dispatch
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] — Determine What To Do — handles running/paused/failed/null states
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] — Sub-Agent Interaction — where file context would be injected
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.2] — Atomic Write pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] — Boundary Rules (critical)
- [Source: .claude/commands/bmad-orchestrate.md#Step 2] — Resume Handling — already fully implemented
- [Source: .claude/commands/bmad-orchestrate.md#Step 3] — Artifact Overwrite Protection for fresh runs
- [Source: .bmad-orchestrator/loop.sh] — Loop script with preflight_check, exit code handling
- [Source: _bmad-output/implementation-artifacts/2-6-quick-flow-pipeline.md] — Previous story patterns, 208 tests
- [Source: _bmad-output/implementation-artifacts/2-5-dev-story-code-review-templates-with-git-commits.md] — Orchestrator modification patterns, phase handling
- [Source: tests/orchestrator-agent.bats] — 208 existing tests, naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None — clean implementation with no failures.

### Completion Notes List

- Task 1: Added Section 1.3 "File Reference Detection" to `bmad-orchestrator.md` after Section 1.2, covering task text scanning with file path heuristics, file reading with warning on missing files, session-scoped fileContext storage (not persisted to state.yaml), and URL/email/flag exclusion. Documented fileContext injection in Section 4 (Sub-Agent Interaction). All 10 existing sections preserved with no renumbering.
- Task 2: Verified orchestrator Section 1.2 correctly handles resume (status=running after slash command sets it). Verified slash command Step 2 handles --resume with atomic write, runType update, and clear error on missing state. Added "Resume Behavior" and "Artifact Respect on Resume" documentation to Section 1.3.
- Task 3: Verified all edge cases in slash command resume: failed→running, paused→running, running→running (crash), currentStage/storyLoop preserved. No fixes needed — all cases handled.
- Task 4: Added 20 new bats tests (FileRef 2.7-1 through 2.7-11, Resume 2.7-1 through 2.7-9). All 228 tests pass (208 existing + 20 new), zero regressions.
- Task 5: MANUAL — left unchecked for user verification.
- Code Review Fixes: (1) Moved resume behavior docs from Section 1.3 to new Section 1.4 — separation of concerns. (2) Updated Execution Flow Summary (Section 10) to include file reference detection step and fileContext injection — was missing from summary. (3) Added structural test FileRef 2.7-11 verifying fileContext injection is documented inside Section 4. Renumbered old 2.7-11 → 2.7-12. Total: 229 tests, all passing.

### Change Log

- 2026-02-02: Implemented file reference detection and resume documentation (Story 2.7)
- 2026-02-02: Code review fixes — moved resume docs to Section 1.4, updated Execution Flow Summary, added structural test for Section 4 fileContext

### File List

- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added Section 1.3 (File Reference Detection) with full heuristics and fileContext injection in Section 4. Added Section 1.4 (Resume Behavior). Updated Section 10 (Execution Flow Summary) with file reference detection step.
- `tests/orchestrator-agent.bats` — MODIFIED — Added 21 new bats tests for file reference detection (12 tests) and resume capability (9 tests)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Updated story status ready-for-dev → in-progress → review
- `_bmad-output/implementation-artifacts/2-7-file-reference-detection-resume-capability.md` — MODIFIED — Updated task checkboxes, dev agent record, file list, status

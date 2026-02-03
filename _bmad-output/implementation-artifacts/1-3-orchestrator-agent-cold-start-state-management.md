# Story 1.3: Orchestrator Agent — Cold Start & State Management

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator agent to orient itself from disk state alone on every launch,
so that it can resume the pipeline from any point without relying on conversation history.

## Acceptance Criteria

1. **Given** the orchestrator agent is launched by the loop script
   **When** the agent starts
   **Then** it reads `.bmad-orchestrator/state.yaml` to determine the current pipeline stage, completed stages, and mode

2. **Given** `state.yaml` shows `completedStages: [prd]` and `currentStage: architecture`
   **When** the agent orients itself
   **Then** it identifies that the architecture stage is next and loads the corresponding template from `.bmad-orchestrator/templates/`

3. **Given** the agent completes a workflow stage successfully
   **When** updating state
   **Then** it writes the updated state to `state.yaml.tmp` first, then atomically renames to `state.yaml`
   **And** `currentStage` is advanced to the next stage
   **And** the completed stage is appended to `completedStages`

4. **Given** the agent needs to update `state.yaml`
   **When** the write occurs
   **Then** the state file is never partially written -- either the complete new state is written or the old state remains unchanged

5. **Given** the orchestrator agent completes its work for the current stage
   **When** exiting
   **Then** it exits with the appropriate code: 0 (stage done), 1 (failed), 2 (pipeline complete), or 3 (checkpoint pause)

6. **Given** the agent launches a sub-agent via the Task tool
   **When** interacting with the sub-agent
   **Then** the orchestrator acts as an expert human user, responding to menus, questions, and prompts as a product/engineering expert would

## Tasks / Subtasks

- [x] Task 1: Create the orchestrator agent definition file (AC: #1, #2, #6)
  - [x] 1.1: Create `.claude/agents/bmad-orchestrator.md` as a Claude Code agent definition
  - [x] 1.2: Define the agent's core identity: BMAD Orchestrator that reads state and executes pipeline stages
  - [x] 1.3: Implement the cold-start orientation section -- instructions to read `state.yaml` on every launch and determine what to do next
  - [x] 1.4: Implement stage identification logic -- map `currentStage` to the correct template file in `.bmad-orchestrator/templates/`
  - [x] 1.5: Implement the "first launch" case -- when `currentStage` is `null` and routing hasn't happened yet, recognize that routing (Story 1.4) is needed
  - [x] 1.6: Implement sub-agent interaction instructions -- how to use the Task tool to launch BMAD agents and respond as an expert human user

- [x] Task 2: Implement state management logic in agent definition (AC: #3, #4)
  - [x] 2.1: Define the state update protocol -- after completing a stage, construct the full updated state YAML
  - [x] 2.2: Implement atomic write instructions -- always write to `state.yaml.tmp` then `mv` to `state.yaml`
  - [x] 2.3: Implement `completedStages` append logic -- add completed stage to the array
  - [x] 2.4: Implement `currentStage` advancement -- determine the next stage in the pipeline sequence
  - [x] 2.5: Implement `updatedAt` timestamp update on every state write
  - [x] 2.6: Implement `currentRetries` reset to 0 when advancing to a new stage (successful completion resets retry count)

- [x] Task 3: Implement exit code handling (AC: #5)
  - [x] 3.1: Define exit code protocol in agent instructions -- after state update, exit with the correct code
  - [x] 3.2: Implement exit code 0: stage completed, pipeline continues (more stages remain)
  - [x] 3.3: Implement exit code 1: stage failed after `maxRetries` reached
  - [x] 3.4: Implement exit code 2: pipeline complete -- all stages in the pipeline track have been completed
  - [x] 3.5: Implement exit code 3: checkpoint pause -- current stage matches a gate in `gates` array AND mode is `checkpoint`

- [x] Task 4: Implement pipeline stage sequence and template loading (AC: #2)
  - [x] 4.1: Define the Full Method pipeline stage sequence: `prd` -> `architecture` -> `epics-stories` -> `readiness` -> `sprint-planning` -> `create-story` -> `dev-story` -> `code-review`
  - [x] 4.2: Define the Quick Flow pipeline stage sequence: `quick-spec` -> `quick-dev`
  - [x] 4.3: Implement template loading -- read `.bmad-orchestrator/templates/stage-{currentStage}.md` to get stage instructions
  - [x] 4.4: Implement template frontmatter parsing -- extract `agent`, `command`, `requiredArtifacts`, `producedArtifacts` from template
  - [x] 4.5: Implement artifact pre-validation -- before launching a sub-agent, verify all `requiredArtifacts` exist on disk

- [x] Task 5: Implement verification pattern (AC: #3, #5)
  - [x] 5.1: After sub-agent workflow completes, verify all `producedArtifacts` from template frontmatter exist on disk
  - [x] 5.2: Compare stage output against original `task` from state file for goal alignment
  - [x] 5.3: For validation stages (readiness, code-review), check the result (PASS/CONCERNS/FAIL)
  - [x] 5.4: On verification pass: update state, write stage outcome to status report, prepare exit code 0
  - [x] 5.5: On verification fail: log failure to `failures` array, increment `currentRetries`, determine exit code (0 for retry, 1 if max retries exceeded)

## Dev Notes

### Architecture Compliance

**This story creates exactly 1 file:**
- `.claude/agents/bmad-orchestrator.md` -- The orchestrator agent definition

**This is a Claude Code agent definition, NOT a bash script.** Claude Code agent definitions are markdown files that define an agent's identity, capabilities, and instructions. When the loop script runs `claude --agent bmad-orchestrator`, Claude Code loads this file and uses it as the agent's system instructions.

The agent definition must be comprehensive enough that a freshly launched Claude Code instance can:
1. Read the state file
2. Know exactly what pipeline stage to execute
3. Load the right template
4. Launch the right sub-agent
5. Interact as an expert human
6. Run verification
7. Update state atomically
8. Exit with the correct code

### State File Schema (from Architecture -- use EXACTLY)

```yaml
# .bmad-orchestrator/state.yaml
task: "Original task description string"
route: quick | full
mode: autonomous | checkpoint
status: running | paused | completed | failed
runType: fresh | resume
branch: "current-git-branch-name"
createdAt: "ISO-8601 timestamp"
updatedAt: "ISO-8601 timestamp"
maxRetries: 3

currentStage: "prd"
completedStages:
  - prd
  - architecture

gates:
  - prd
  - architecture
  - epics-stories
  - readiness
  - code-review

storyLoop:
  epics:
    - id: "epic-01"
      status: "in-progress"
      stories:
        - id: "story-01-login"
          status: "completed"
        - id: "story-02-signup"
          status: "in-progress"
          phase: "code-review"

failures:
  - stage: "readiness"
    attempt: 1
    error: "Connection pooling not addressed"
    timestamp: "2026-02-03T10:03:00Z"
currentRetries: 0
```

### Pipeline Stage Sequences (FROZEN -- use EXACTLY)

**Full Method Track:**
`prd` -> `architecture` -> `epics-stories` -> `readiness` -> `sprint-planning` -> `create-story` -> `dev-story` -> `code-review`

Note: `create-story` -> `dev-story` -> `code-review` repeat per story within the story loop. The orchestrator iterates through `storyLoop.epics[].stories[]`.

**Quick Flow Track:**
`quick-spec` -> `quick-dev`

### Frozen Stage Identifiers (from Architecture)

These exact strings must be used everywhere -- no aliases, no variations:
`prd`, `architecture`, `epics-stories`, `readiness`, `sprint-planning`, `create-story`, `dev-story`, `code-review`, `quick-spec`, `quick-dev`

### Exit Code Convention (from Architecture -- use EXACTLY)

| Code | Meaning | When |
|------|---------|------|
| 0 | Stage completed, continue | Stage done, more stages remain |
| 1 | Failed after retries, stop | `currentRetries` >= `maxRetries` |
| 2 | Pipeline complete, stop | All stages in pipeline track completed |
| 3 | Checkpoint pause, stop | `mode: checkpoint` AND completed stage is in `gates` array |

### Agent Communication Pattern (CRITICAL)

The orchestrator uses Claude Code's **Task tool** with resume mechanism:
1. Orchestrator launches sub-agent via Task tool with the stage prompt template
2. Sub-agent runs its BMAD workflow, returns output at interaction points
3. Orchestrator reads output, makes expert-level decisions (responds to menus, answers questions, provides specifications)
4. Orchestrator resumes sub-agent (same agent ID) with its response
5. Repeat until sub-agent workflow completes
6. One Ralph Loop iteration = one complete pipeline stage with ALL back-and-forth

**Expert Human Simulation:** The orchestrator acts as a knowledgeable product/engineering expert:
- Selects menu options that match the stage goal
- Answers workflow questions using the task description and available artifacts
- Provides context from previously completed stages
- Triggers Party Mode when it detects competing approaches, ambiguity, or trade-offs (FR31-FR32)

### Verification Pattern (NEVER SKIP)

After every sub-agent workflow completes, before updating state:
1. **Artifact check:** Verify all `producedArtifacts` from the template frontmatter exist on disk
2. **Goal alignment:** Compare stage output against the original `task` from state file
3. **Quality gate:** For validation stages (readiness, code-review), check PASS/CONCERNS/FAIL
4. **Pass:** Update state, write stage outcome to status report, exit 0
5. **Fail:** Log failure to `failures` array, increment `currentRetries`, exit 0 (retry) or 1 (max retries)

### Atomic Write Pattern (CRITICAL)

**NEVER write directly to `state.yaml`.** Always:
1. Write complete state to `state.yaml.tmp`
2. Rename: `mv .bmad-orchestrator/state.yaml.tmp .bmad-orchestrator/state.yaml`

This ensures the state file is never partially written. Either the complete new state exists, or the old state remains.

### Template Loading Pattern

Templates live at `.bmad-orchestrator/templates/stage-{stage-identifier}.md`. Each template has:

```markdown
---
stage: prd
agent: bmad-pm
command: CA
requiredArtifacts: []
producedArtifacts: [prd.md]
---

## Context Injection
{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions
[What the orchestrator tells the sub-agent to do]

## Verification
[How the orchestrator validates this stage's output]
```

The orchestrator reads the template, extracts frontmatter values, validates required artifacts exist, then launches the sub-agent with the template content as context.

**Note:** Templates do not exist yet (created in Story 1.5+). For this story, the agent definition must correctly reference the template loading mechanism so it works when templates are added later.

### Checkpoint Gate Logic

When `mode: checkpoint`:
- After completing a stage, check if the stage identifier is in the `gates` array
- If it IS a gate: set `status: paused` in state, exit with code 3
- If it is NOT a gate: continue normally, exit with code 0

When `mode: autonomous`:
- Gates are ignored, all stages continue automatically

### Failure Handling (for this story -- basic retry)

When verification fails:
1. Append to `failures` array: `{stage, attempt, error, timestamp}`
2. Increment `currentRetries`
3. If `currentRetries` < `maxRetries`: keep `currentStage` unchanged, exit 0 (loop relaunches for retry)
4. If `currentRetries` >= `maxRetries`: set `status: failed`, exit 1

The failure context from previous attempts should be injected into `{{failure_context}}` in the template on retry. Epic 3 extends this with upstream re-routing.

### Status Report Writing

The agent should append stage-level entries to `.bmad-orchestrator/status-report.md`:

```markdown
## Stage: <stage-name>
- **Outcome:** PASS | FAIL
- **Timestamp:** <ISO-8601>
- **Details:** <one-line summary>
```

The loop script creates the header and writes the final summary. The agent writes individual stage outcomes.

### Boundary Rules (CRITICAL)

- **The orchestrator agent reads/writes `state.yaml`** -- this is its primary state mechanism
- **The orchestrator agent NEVER directly writes BMAD artifacts** (`_bmad-output/`) -- sub-agents produce artifacts through their own workflows
- **The orchestrator agent reads templates** from `.bmad-orchestrator/templates/` but NEVER modifies them
- **The orchestrator agent reads `_bmad-output/`** only for artifact verification (checking files exist)
- **The orchestrator agent appends to `status-report.md`** for stage-level logging

### Previous Story Intelligence

**Story 1.1 (Slash Command):**
- Created `.claude/commands/bmad-orchestrate.md` -- prompt template that creates initial `state.yaml`
- Uses atomic write pattern (write to `.tmp`, then `mv`)
- State file schema defined with all fields in camelCase
- **Key learning:** Slash commands are markdown prompt templates, not bash scripts
- **Handoff:** Slash command creates state.yaml -> user runs loop.sh -> loop.sh launches this agent

**Story 1.2 (Ralph Loop):**
- Created `.bmad-orchestrator/loop.sh` -- bash script managing agent lifecycle
- Exit code dispatch: 0=relaunch, 1=fail stop, 2=complete stop, 3=pause stop, *=crash stop
- Branch safety check at startup
- Preflight: validates state.yaml exists and status is not completed/failed
- Agent invoked via: `claude --agent bmad-orchestrator`
- `BATS_TESTING` env var guard for test isolation
- `TEST_BMAD_DIR` env var for path overrides in tests
- 34 bats tests covering all acceptance criteria
- **Key learning:** The loop script reads state but NEVER writes to it; this agent is responsible for all state writes
- **Key learning:** `write_status_report` function creates header if file doesn't exist, appends run summary
- **Key learning:** `read_state` uses grep/sed for YAML field extraction (no external deps)

**Implications for this story:**
- The agent MUST write to state.yaml (the loop script depends on it)
- The agent MUST exit with the correct exit code (the loop script dispatches on it)
- The agent MUST be able to orient from state.yaml alone on EVERY launch (no conversation history persists)
- The `.bmad-orchestrator/` directory already exists at runtime
- `state.yaml` already has `status: running` when this agent is first launched

### Git Intelligence

Recent commits:
- `dcd48a7` added gitignore
- `d2d8545` feat: implement Ralph Loop script (story 1-2)
- `c3ca604` fix orchestrate command
- `58b1dd1` added orchestrate claude command
- `f7d2f5c` added pre-dev documentation

**Patterns established:**
- Agent definitions go in `.claude/agents/` (e.g., `bmad-pm.md`, `bmad-dev.md`)
- Slash commands go in `.claude/commands/`
- Bash scripts follow all project-context rules (ShellCheck, quoted vars, snake_case)
- Code review resulted in fixes applied cleanly (story 1-2)
- Tests use bats framework

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` -- Created by this story (checked into repo)
- This file joins existing agents: `bmad-pm.md`, `bmad-dev.md`, `bmad-architect.md`, `bmad-sm.md`, etc.
- The orchestrator agent is unique -- it is the ONLY agent that manages the pipeline state and launches other BMAD agents as sub-agents
- No conflicts with existing `.claude/agents/` files -- `bmad-orchestrator.md` is a new file

### Anti-Patterns to Avoid

- Writing to `state.yaml` directly (without temp-then-rename) -- ALWAYS use atomic writes
- Inventing new stage identifiers not in the frozen list
- Skipping the verification step after sub-agent completion
- Multi-line error messages in the state file failures array -- ALWAYS single-line
- The orchestrator agent writing directly to `_bmad-output/` -- NEVER, sub-agents do this
- Persisting sub-agent IDs in state file -- sub-agent IDs are transient
- Relying on conversation history -- EVERY launch must orient from state.yaml alone
- Hardcoding stage sequences without checking the `route` field (quick vs full)

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] -- Complete state.yaml schema
- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] -- Exit code convention
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] -- Task tool resume mechanism
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] -- Template format and verification
- [Source: _bmad-output/planning-artifacts/architecture.md#Routing Logic] -- Quick vs Full track selection
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- Where agent file lives
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] -- Naming, atomic writes, verification
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries] -- Agent boundary rules
- [Source: _bmad-output/planning-artifacts/architecture.md#Party Mode Triggering] -- When to invoke brainstorming
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3] -- Full acceptance criteria
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4] -- Routing logic (next story, informs currentStage=null handling)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5] -- First template (next next story, templates don't exist yet)
- [Source: _bmad-output/project-context.md] -- All implementation rules and anti-patterns
- [Source: _bmad-output/project-context.md#State File Rules] -- Atomic writes, camelCase, single-line errors
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] -- Exact stage strings
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Agent boundary constraints
- [Source: _bmad-output/project-context.md#Verification Pattern] -- Post-stage verification steps
- [Source: _bmad-output/implementation-artifacts/1-1-slash-command-state-file-initialization.md] -- Previous story context
- [Source: _bmad-output/implementation-artifacts/1-2-ralph-loop-script.md] -- Previous story context, loop.sh patterns

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None required — clean implementation with no debugging issues.

### Completion Notes List

- Created `.claude/agents/bmad-orchestrator.md` — comprehensive Claude Code agent definition (290 lines) covering all 6 acceptance criteria
- Agent definition structured in 10 sections: Cold Start Orientation, Pipeline Stage Sequences, Template Loading, Sub-Agent Interaction, Verification, Failure Handling, State Update Protocol, Exit Code Protocol, Boundary Rules, Execution Flow Summary
- All frozen stage identifiers used exactly as specified (prd, architecture, epics-stories, readiness, sprint-planning, create-story, dev-story, code-review, quick-spec, quick-dev)
- All state file fields referenced with correct camelCase naming
- Atomic write pattern (state.yaml.tmp → mv → state.yaml) explicitly documented
- Exit codes 0/1/2/3 with checkpoint gate logic fully specified
- Sub-agent interaction via Task tool with expert human simulation documented
- Verification pattern (artifact check, goal alignment, quality gate) fully specified
- Boundary rules clearly stated (never write _bmad-output, never modify templates, etc.)
- 37 bats tests created covering all 5 tasks and cross-cutting concerns
- All 34 existing loop.bats tests pass (zero regressions)

### Code Review Fixes Applied

- **[H1] Added `paused` status handling** in cold-start orientation (Section 1.2) — agent now recognizes `paused` status and transitions to `running` before proceeding
- **[H2] Clarified exit code mechanism** (Section 8) — exit must be issued as final Bash tool call, not embedded in agent markdown
- **[H3] Added story loop iteration logic** (Section 2) — 7-step algorithm for iterating through epics/stories in `storyLoop`
- **[M1] Added CONCERNS quality gate handling** (Section 5.3, 7.3) — CONCERNS treated as PASS with concern details logged in status report as `PASS (CONCERNS)`
- **[M2] Documented `runType` usage** (Section 1.1) — clarified as read-and-preserve for routing logic in Story 1.4
- **[M3] Added 9 structural validation tests** — frontmatter validation, section ordering, pipeline sequence correctness, exit code table, paused handling, template-not-found, CONCERNS handling, story loop logic
- **[L1] Added template-not-found handling** (Section 3.1) — graceful error with failure handling protocol
- All 46 tests pass (37 original + 9 structural), all 34 loop.bats tests pass (zero regressions)

### Change Log

- 2026-02-03: Created `.claude/agents/bmad-orchestrator.md` — orchestrator agent definition
- 2026-02-03: Created `tests/orchestrator-agent.bats` — 37 tests validating agent definition content
- 2026-02-03: Code review fixes — 6 issues fixed (3 HIGH, 3 MEDIUM), 9 structural tests added

### File List

- `.claude/agents/bmad-orchestrator.md` (MODIFIED) — Orchestrator agent definition with review fixes
- `tests/orchestrator-agent.bats` (MODIFIED) — 46 bats tests (37 original + 9 structural)
- `_bmad-output/implementation-artifacts/1-3-orchestrator-agent-cold-start-state-management.md` (MODIFIED) — Story file updates
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (MODIFIED) — Status tracking update

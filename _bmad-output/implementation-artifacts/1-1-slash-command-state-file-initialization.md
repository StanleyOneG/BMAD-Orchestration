# Story 1.1: Slash Command & State File Initialization

Status: dev-complete

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want to run `/bmad-orchestrate` with a task description and optional flags,
so that the orchestrator initializes a pipeline run with the correct configuration.

## Acceptance Criteria

1. **Given** the user runs `/bmad-orchestrate "Build a notification system"`
   **When** the command is invoked
   **Then** a `state.yaml` file is created at `.bmad-orchestrator/state.yaml` with:
   - `task`: the task description string
   - `route: null` (pending analysis)
   - `mode: autonomous`
   - `status: running`
   - `runType: fresh`
   **And** the user is instructed to run `.bmad-orchestrator/loop.sh` to begin execution

2. **Given** the user runs `/bmad-orchestrate --checkpoint "Add OAuth"`
   **When** the `--checkpoint` flag is present
   **Then** `state.yaml` is created with `mode: checkpoint`

3. **Given** the user runs `/bmad-orchestrate --quick "Fix login bug"`
   **When** the `--quick` flag is present
   **Then** `state.yaml` is created with `route: quick` (skipping auto-routing)

4. **Given** the user runs `/bmad-orchestrate --full "Add caching layer"`
   **When** the `--full` flag is present
   **Then** `state.yaml` is created with `route: full` (skipping auto-routing)

5. **Given** the user is on the `main` or `master` branch
   **When** `/bmad-orchestrate` is invoked
   **Then** the command fails immediately with a clear error: "Cannot run orchestrator on a protected branch. Switch to a feature branch first."
   **And** no `state.yaml` is created

6. **Given** the user is on a branch named `feature/notifications`
   **When** `/bmad-orchestrate` is invoked
   **Then** the branch name is recorded in `state.yaml` as `branch: feature/notifications`

7. **Given** the `.bmad-orchestrator/` directory does not exist
   **When** `/bmad-orchestrate` is invoked
   **Then** the directory is created before writing `state.yaml`

## Tasks / Subtasks

- [x] Task 1: Create the slash command file (AC: #1, #2, #3, #4, #5, #6, #7)
  - [x] 1.1: Create `.claude/commands/bmad-orchestrate.md` slash command definition
  - [x] 1.2: Implement task description parsing from the slash command argument
  - [x] 1.3: Implement flag parsing (`--checkpoint`, `--quick`, `--full`, `--resume`)
  - [x] 1.4: Implement git branch safety check — detect `main`/`master` and fail fast with clear error
  - [x] 1.5: Implement `.bmad-orchestrator/` directory creation if it doesn't exist
  - [x] 1.6: Implement state.yaml generation using atomic write pattern (write to `.tmp`, then rename)
  - [x] 1.7: Implement existing artifact detection — fail if `state.yaml` or `_bmad-output/` artifacts already exist on fresh runs (FR36)
  - [x] 1.8: Implement `--resume` handling — update existing `state.yaml` with `runType: resume` instead of creating new (FR6, FR37)
  - [x] 1.9: Output clear instructions to user: "Run `.bmad-orchestrator/loop.sh` to begin execution"

- [x] Task 2: Validate state.yaml schema compliance (AC: #1, #2, #3, #4, #6)
  - [x] 2.1: Verify all state.yaml fields use camelCase naming
  - [x] 2.2: Verify state.yaml matches the architecture-defined schema exactly
  - [x] 2.3: Verify `createdAt` and `updatedAt` timestamps are included
  - [x] 2.4: Verify default `gates` array is populated: `[prd, architecture, epics-stories, readiness, code-review]`
  - [x] 2.5: Verify `maxRetries: 3` default is set
  - [x] 2.6: Verify `currentRetries: 0` is initialized
  - [x] 2.7: Verify `completedStages: []` is initialized empty
  - [x] 2.8: Verify `failures: []` is initialized empty
  - [x] 2.9: Verify `storyLoop` is initialized as empty/null

## Dev Notes

### Architecture Compliance

**This story creates exactly 1 file:**
- `.claude/commands/bmad-orchestrate.md` — Claude Code slash command definition

**This is a Claude Code slash command, NOT a bash script.** Claude Code slash commands are markdown files that act as prompt templates. When the user types `/bmad-orchestrate`, Claude Code reads this markdown file and uses it as instructions for what the agent should do. The slash command file must instruct the AI agent to:
1. Parse the user's input (task description + flags)
2. Run git branch check
3. Create the directory and state file
4. Output instructions

### State File Schema (from Architecture — use EXACTLY)

```yaml
# .bmad-orchestrator/state.yaml
task: "Original task description string"
route: null | quick | full
mode: autonomous | checkpoint
status: running | paused | completed | failed
runType: fresh | resume
branch: "current-git-branch-name"
createdAt: "ISO-8601 timestamp"
updatedAt: "ISO-8601 timestamp"
maxRetries: 3

currentStage: null
completedStages: []

gates:
  - prd
  - architecture
  - epics-stories
  - readiness
  - code-review

storyLoop: null

failures: []
currentRetries: 0
```

### Critical Implementation Rules

1. **Atomic writes ONLY** — Never write directly to `state.yaml`. Always write to `state.yaml.tmp` then `mv state.yaml.tmp state.yaml`
2. **camelCase for all YAML fields** — `currentStage` not `current_stage`, `runType` not `run_type`
3. **Frozen stage identifiers** — Use EXACTLY: `prd`, `architecture`, `epics-stories`, `readiness`, `sprint-planning`, `create-story`, `dev-story`, `code-review`, `quick-spec`, `quick-dev`
4. **Branch safety** — Check current git branch. If `main` or `master`, fail immediately with clear error. No state file created.
5. **Artifact overwrite protection** — On fresh runs, if `.bmad-orchestrator/state.yaml` already exists OR `_bmad-output/` contains artifacts, fail with: "Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first."
6. **Route defaults to null** — Route is null unless `--quick` or `--full` flag is used. The orchestrator agent (Story 1.4) handles auto-routing later.
7. **currentStage defaults to null** — The routing logic (Story 1.4) sets the first stage based on route decision.

### Flag Parsing Rules

| Flag | Effect on state.yaml |
|------|---------------------|
| (none) | `mode: autonomous`, `route: null` |
| `--checkpoint` | `mode: checkpoint` |
| `--quick` | `route: quick` |
| `--full` | `route: full` |
| `--resume` | `runType: resume` (modifies existing state, does NOT create new) |

Flags can be combined: `--checkpoint --full` → `mode: checkpoint`, `route: full`

### Boundary Rules (CRITICAL)

- The slash command creates the initial state file and stops. It does NOT launch `loop.sh`.
- The slash command does NOT invoke any BMAD agents or workflows.
- The slash command instructs the user to manually run `.bmad-orchestrator/loop.sh`.
- This is the handoff point: slash command → user → loop script → orchestrator agent.

### File Structure Context

```
.bmad-orchestrator/          ← Created by this story if not exists
├── state.yaml               ← Created by this story (runtime, not checked in)
├── loop.sh                  ← Created by Story 1.2
├── templates/               ← Created by Story 1.5+
└── ...

.claude/
├── commands/
│   └── bmad-orchestrate.md  ← Created by this story
└── agents/
    └── bmad-orchestrator.md ← Created by Story 1.3
```

### Project Structure Notes

- Alignment with unified project structure: `.claude/commands/` for slash commands per Claude Code conventions
- `.bmad-orchestrator/` at project root for orchestrator-specific runtime files per architecture decision
- State file location `.bmad-orchestrator/state.yaml` is a frozen architectural decision

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — Complete state.yaml schema
- [Source: _bmad-output/planning-artifacts/architecture.md#Loop Script Design] — Exit code convention
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] — Complete directory layout
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] — Naming conventions, atomic writes, bash standards
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries] — Slash command to loop script handoff
- [Source: _bmad-output/planning-artifacts/prd.md#Command Interface] — Flag definitions and defaults
- [Source: _bmad-output/planning-artifacts/prd.md#Artifact Overwrite Protection] — Fresh vs resume behavior
- [Source: _bmad-output/planning-artifacts/prd.md#Git Safety] — Branch check requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1] — Full acceptance criteria
- [Source: _bmad-output/project-context.md] — All implementation rules and anti-patterns

## Dev Agent Record

### Agent Model Used
Claude Opus 4.5

### Debug Log References
N/A

### Completion Notes List
- Slash command is a markdown prompt template per Claude Code conventions — NOT a bash script
- All 7 ACs covered: fresh run fields, --checkpoint, --quick, --full, protected branch check, branch recording, directory creation
- Atomic write pattern enforced (write to .tmp, then mv)
- All state.yaml fields match architecture schema exactly with camelCase naming
- Resume flow updates existing state rather than creating new
- Artifact overwrite protection prevents fresh runs when state/artifacts exist
- Boundary rules respected: command creates state file and stops, does NOT launch loop.sh or invoke agents

### File List
- `.claude/commands/bmad-orchestrate.md` (created)

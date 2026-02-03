---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
---

# BMAD Orchestrator - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for BMAD Orchestrator, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: User can invoke the orchestrator via a single slash command with a natural language task description
FR2: Orchestrator can detect and read files referenced within the task description
FR3: Orchestrator can analyze the task description and automatically route to Quick Flow or Full Method track
FR4: User can override routing with `--quick` or `--full` flags
FR5: User can select execution mode: autonomous (default) or checkpoint (`--checkpoint`)
FR6: User can resume a previously failed run with `--resume`
FR7: Orchestrator can execute the PRD workflow autonomously (YOLO mode, simulating expert user input)
FR8: Orchestrator can execute the Architecture workflow using the PRD as input
FR9: Orchestrator can execute the Epics & Stories workflow using PRD and Architecture as input
FR10: Orchestrator can execute the Implementation Readiness check using all planning artifacts
FR11: Orchestrator can execute Sprint Planning using the epics
FR12: Orchestrator can execute Create Story for each story in each epic
FR13: Orchestrator can execute Dev Story for each created story
FR14: Orchestrator can execute Code Review for each implemented story
FR15: Orchestrator can loop through all epics and all stories within each epic automatically
FR16: Orchestrator can execute Quick Spec workflow autonomously
FR17: Orchestrator can execute Quick Dev workflow using the tech spec as input
FR18: A loop script can launch the orchestrator agent with fresh context on each iteration
FR19: Orchestrator agent can read its state from a YAML state file on every launch
FR20: Orchestrator agent can update the state file after completing each workflow stage
FR21: Loop script can detect agent exit and relaunch if pipeline is not complete
FR22: Orchestrator agent can orient itself from a cold start using only the state file and disk artifacts
FR23: Orchestrator can detect when a validation stage fails (e.g., implementation readiness returns CONCERNS/FAIL)
FR24: Orchestrator can identify which upstream stage needs revision based on the failure report
FR25: Orchestrator can re-route to the appropriate stage with specific remediation instructions
FR26: Orchestrator can retry a failed stage with a configurable maximum retry count
FR27: Orchestrator can transition to FAILED status when retry limit is exhausted
FR28: Orchestrator can pause execution at defined gate points and present a summary to the user
FR29: User can provide feedback at a checkpoint that the orchestrator incorporates before proceeding
FR30: User can approve a checkpoint to continue the pipeline
FR31: Orchestrator can detect when a task would benefit from brainstorming based on concrete triggers
FR32: Orchestrator can invoke Party Mode internally as part of the pipeline when any FR31 trigger is detected
FR33: Orchestrator can verify it is running on a non-main/non-master branch before starting
FR34: Orchestrator can fail fast with a clear error if on a protected branch
FR35: Orchestrator can make commits to the current worktree branch during implementation stages
FR36: Orchestrator can detect existing artifacts and prevent accidental overwrite on fresh runs
FR37: Orchestrator can respect existing artifacts and continue from them on `--resume` runs
FR38: Orchestrator can generate a final status report showing all stages run and their outcomes
FR39: Status report can display the failure point, error details, and recovery instructions when a run fails
FR40: Status report can show the complete artifact inventory produced during the run
FR41: Orchestrator can identify workflow stages that have no dependencies and can run concurrently (DEFERRED - post-MVP)
FR42: Orchestrator can launch multiple agents in parallel where the workflow graph allows it (DEFERRED - post-MVP)

### NonFunctional Requirements

NFR1: The orchestrator must never silently corrupt the state file -- every write must be atomic (write complete state or don't write at all)
NFR2: A failed run must always produce a readable status report -- no silent failures
NFR3: The state file must always reflect the true pipeline state -- if a stage completed, it's recorded; if it didn't, it's not
NFR4: The loop script must detect agent crashes (non-clean exits) and log them to the status report rather than silently restarting
NFR5: Partial artifacts from a failed stage must not be treated as complete by subsequent stages
NFR6: The orchestrator must work with Claude Code's native agent system (Task tool, `.claude/agents/` conventions) as of the current version
NFR7: The orchestrator must follow BMAD's file conventions for `_bmad-output/` artifact paths, naming, and structure
NFR8: BMAD workflow changes (new steps, renamed artifacts) should require only state file and prompt updates, not architectural changes to the orchestrator
NFR9: Git operations must use standard git CLI commands compatible with worktree setups

### Additional Requirements

**From Architecture - Execution Patterns:**
- Ralph Loop pattern: bash script outer loop, stateless agent inner worker. Each iteration gets fresh context.
- State file location: `.bmad-orchestrator/state.yaml` with write-to-temp-then-rename atomic writes
- Exit code convention: 0 (stage done, continue), 1 (failed after retries, stop), 2 (pipeline complete, stop), 3 (checkpoint pause, stop)
- Agent invocation via `claude --agent bmad-orchestrator` with prompt piped for state context

**From Architecture - Agent Communication:**
- Orchestrator uses Task tool resume mechanism to interact with sub-agents as expert human
- Sub-agent workflows run exactly as designed (interactive, with menus and questions)
- Sub-agent IDs are transient -- not persisted across Ralph Loop restarts
- Party Mode triggered by orchestrator during back-and-forth when brainstorming would help

**From Architecture - Prompt Templates:**
- Located in `.bmad-orchestrator/templates/` -- one per pipeline stage
- Each template has frontmatter (stage, agent, command, requiredArtifacts, producedArtifacts)
- Each template has Context Injection, Stage Instructions, and Verification sections
- Verification section is mandatory -- orchestrator validates output before marking stage complete

**From Architecture - Naming Conventions:**
- YAML fields: camelCase
- Files/directories: kebab-case
- Bash functions: snake_case
- Frozen stage identifiers: prd, architecture, epics-stories, readiness, sprint-planning, create-story, dev-story, code-review, quick-spec, quick-dev

**From Architecture - Bash Standards:**
- All scripts start with `set -euo pipefail`
- ShellCheck compliant
- All variables quoted: `"${var}"`
- Functions use snake_case with local variable declarations

**From Architecture - File Structure:**
- `.bmad-orchestrator/` directory for loop script, templates, hooks, runtime state
- `.claude/agents/bmad-orchestrator.md` for agent definition
- `.claude/commands/bmad-orchestrate.md` for slash command entry point
- Slash command creates initial state file, instructs user to run `loop.sh` manually

**From Architecture - Verification Pattern:**
- After every sub-agent completion: artifact check → goal alignment → quality gate → pass/fail
- Failed verification enters retry flow with failure logged to state file

**From Architecture - Deferred Items (Post-MVP):**
- FR41-FR42: Parallel execution
- Run history and success rate tracking
- Custom workflow step injection

### FR Coverage Map

| FR | Epic | Story | Description |
|----|------|-------|-------------|
| FR1 | Epic 1 | 1.1 | Slash command entry point |
| FR2 | Epic 2 | 2.7 | File reference detection in task description |
| FR3 | Epic 1 | 1.4 | Auto-routing (Quick Flow vs Full Method) |
| FR4 | Epic 1 | 1.1 | Routing override flags |
| FR5 | Epic 1 | 1.1 | Mode selection (autonomous/checkpoint) |
| FR6 | Epic 2 | 2.7 | Resume from failed run |
| FR7 | Epic 2 | 2.1 | PRD workflow execution (via Epic 1 Story 1.5) |
| FR8 | Epic 2 | 2.1 | Architecture workflow execution |
| FR9 | Epic 2 | 2.1 | Epics & Stories workflow execution |
| FR10 | Epic 2 | 2.2 | Implementation Readiness execution |
| FR11 | Epic 2 | 2.3 | Sprint Planning execution |
| FR12 | Epic 2 | 2.4 | Create Story execution |
| FR13 | Epic 2 | 2.5 | Dev Story execution |
| FR14 | Epic 2 | 2.5 | Code Review execution |
| FR15 | Epic 2 | 2.4 | Multi-epic/story loop |
| FR16 | Epic 2 | 2.6 | Quick Spec execution |
| FR17 | Epic 2 | 2.6 | Quick Dev execution |
| FR18 | Epic 1 | 1.2 | Loop script launches agent with fresh context |
| FR19 | Epic 1 | 1.3 | Agent reads state from YAML |
| FR20 | Epic 1 | 1.3 | Agent updates state after stage completion |
| FR21 | Epic 1 | 1.2 | Loop detects exit and relaunches |
| FR22 | Epic 1 | 1.3 | Cold-start orientation from state file |
| FR23 | Epic 3 | 3.1 | Validation failure detection |
| FR24 | Epic 3 | 3.2 | Upstream stage identification |
| FR25 | Epic 3 | 3.2 | Re-routing with remediation instructions |
| FR26 | Epic 3 | 3.1 | Configurable retry count |
| FR27 | Epic 3 | 3.3 | Terminal FAILED status |
| FR28 | Epic 4 | 4.1 | Gate pausing with summary |
| FR29 | Epic 4 | 4.2 | User feedback at checkpoint |
| FR30 | Epic 4 | 4.1 | Checkpoint approval to continue |
| FR31 | Epic 4 | 4.3 | Brainstorming trigger detection |
| FR32 | Epic 4 | 4.3 | Party Mode invocation |
| FR33 | Epic 1 | 1.1 | Branch safety check |
| FR34 | Epic 1 | 1.1 | Fail fast on protected branch |
| FR35 | Epic 2 | 2.5 | Git commits during implementation |
| FR36 | Epic 3 | 3.3 | Artifact overwrite protection (fresh runs) |
| FR37 | Epic 3 | 3.3 | Artifact respect on resume runs |
| FR38 | Epic 5 | 5.2 | Final status report generation |
| FR39 | Epic 5 | 5.2 | Failure details and recovery instructions |
| FR40 | Epic 5 | 5.2 | Artifact inventory in report |
| FR41 | Deferred | — | Parallel stage identification |
| FR42 | Deferred | — | Parallel agent execution |

## Epic List

### Epic 1: Single-Stage Autonomous Execution
User can invoke `/bmad-orchestrate`, have the task analyzed and routed, and execute a single pipeline stage (PRD) end-to-end autonomously via the Ralph Loop.
**FRs covered:** FR1, FR3, FR4, FR5, FR18, FR19, FR20, FR21, FR22, FR33, FR34

### Epic 2: Full Pipeline & Quick Flow Orchestration
User can run the orchestrator and have it execute the entire Full Method pipeline (PRD → Architecture → Epics → Readiness → Sprint → Story Loop) or Quick Flow (Spec → Dev) from start to finish, with git commits during implementation.
**FRs covered:** FR2, FR6, FR7, FR8, FR9, FR10, FR11, FR12, FR13, FR14, FR15, FR16, FR17, FR35

### Epic 3: Failure Recovery & Artifact Safety
When a stage fails, the orchestrator detects it, identifies the problem, re-routes to fix it, retries, and protects existing work. Failures never lose progress.
**FRs covered:** FR23, FR24, FR25, FR26, FR27, FR36, FR37

### Epic 4: Checkpoint Mode & Party Mode
User can opt into human-in-the-loop mode with gate pausing, feedback loops, and brainstorming when the orchestrator detects it would help.
**FRs covered:** FR28, FR29, FR30, FR31, FR32

### Epic 5: Status Reporting & Run Observability
Every run produces a comprehensive report -- what stages ran, what passed, what failed, recovery instructions, and a full artifact inventory.
**FRs covered:** FR38, FR39, FR40

### Deferred (Post-MVP)
Parallel execution capabilities.
**FRs covered:** FR41, FR42

## Epic 1: Single-Stage Autonomous Execution

User can invoke `/bmad-orchestrate`, have the task analyzed and routed, and execute a single pipeline stage (PRD) end-to-end autonomously via the Ralph Loop.

### Story 1.1: Slash Command & State File Initialization

As a solo developer,
I want to run `/bmad-orchestrate` with a task description and optional flags,
So that the orchestrator initializes a pipeline run with the correct configuration.

**Acceptance Criteria:**

**Given** the user runs `/bmad-orchestrate "Build a notification system"`
**When** the command is invoked
**Then** a `state.yaml` file is created at `.bmad-orchestrator/state.yaml` with the task description, `route: null` (pending analysis), `mode: autonomous`, `status: running`, `runType: fresh`
**And** the user is instructed to run `.bmad-orchestrator/loop.sh` to begin execution

**Given** the user runs `/bmad-orchestrate --checkpoint "Add OAuth"`
**When** the `--checkpoint` flag is present
**Then** `state.yaml` is created with `mode: checkpoint`

**Given** the user runs `/bmad-orchestrate --quick "Fix login bug"`
**When** the `--quick` flag is present
**Then** `state.yaml` is created with `route: quick` (skipping auto-routing)

**Given** the user runs `/bmad-orchestrate --full "Add caching layer"`
**When** the `--full` flag is present
**Then** `state.yaml` is created with `route: full` (skipping auto-routing)

**Given** the user is on the `main` or `master` branch
**When** `/bmad-orchestrate` is invoked
**Then** the command fails immediately with a clear error: "Cannot run orchestrator on a protected branch. Switch to a feature branch first."
**And** no `state.yaml` is created

**Given** the user is on a branch named `feature/notifications`
**When** `/bmad-orchestrate` is invoked
**Then** the branch name is recorded in `state.yaml` as `branch: feature/notifications`

**Given** the `.bmad-orchestrator/` directory does not exist
**When** `/bmad-orchestrate` is invoked
**Then** the directory is created before writing `state.yaml`

### Story 1.2: Ralph Loop Script

As a solo developer,
I want a loop script that manages the agent lifecycle,
So that each pipeline stage runs with fresh context and the pipeline progresses automatically.

**Acceptance Criteria:**

**Given** `state.yaml` exists with `status: running`
**When** `loop.sh` is executed
**Then** the script launches the orchestrator agent via `claude --agent bmad-orchestrator`
**And** the script waits for the agent to exit

**Given** the agent exits with code 0 (stage completed)
**When** the loop script detects the exit
**Then** the script relaunches the agent with fresh context for the next stage

**Given** the agent exits with code 1 (failed after retries)
**When** the loop script detects the exit
**Then** the loop stops and reports the failure

**Given** the agent exits with code 2 (pipeline complete)
**When** the loop script detects the exit
**Then** the loop stops and reports success

**Given** the agent exits with code 3 (checkpoint pause)
**When** the loop script detects the exit
**Then** the loop stops and instructs the user to review and resume

**Given** the agent crashes with an unexpected exit code
**When** the loop script detects a non-clean exit
**Then** the crash is logged to `status-report.md`
**And** the loop stops rather than silently restarting

**Given** `loop.sh` is run
**When** the script starts
**Then** it verifies it is NOT on `main` or `master` branch before launching the agent

**Given** the script follows bash best practices
**When** reviewed
**Then** the script starts with `set -euo pipefail`, all variables are quoted, functions use `snake_case` with `local` declarations, and it passes ShellCheck

### Story 1.3: Orchestrator Agent — Cold Start & State Management

As a solo developer,
I want the orchestrator agent to orient itself from disk state alone on every launch,
So that it can resume the pipeline from any point without relying on conversation history.

**Acceptance Criteria:**

**Given** the orchestrator agent is launched by the loop script
**When** the agent starts
**Then** it reads `.bmad-orchestrator/state.yaml` to determine the current pipeline stage, completed stages, and mode

**Given** `state.yaml` shows `completedStages: [prd]` and `currentStage: architecture`
**When** the agent orients itself
**Then** it identifies that the architecture stage is next and loads the corresponding template from `.bmad-orchestrator/templates/`

**Given** the agent completes a workflow stage successfully
**When** updating state
**Then** it writes the updated state to `state.yaml.tmp` first, then atomically renames to `state.yaml`
**And** `currentStage` is advanced to the next stage
**And** the completed stage is appended to `completedStages`

**Given** the agent needs to update `state.yaml`
**When** the write occurs
**Then** the state file is never partially written — either the complete new state is written or the old state remains unchanged

**Given** the orchestrator agent completes its work for the current stage
**When** exiting
**Then** it exits with the appropriate code: 0 (stage done), 1 (failed), 2 (pipeline complete), or 3 (checkpoint pause)

**Given** the agent launches a sub-agent via the Task tool
**When** interacting with the sub-agent
**Then** the orchestrator acts as an expert human user, responding to menus, questions, and prompts as a product/engineering expert would

### Story 1.4: Task Routing Logic

As a solo developer,
I want the orchestrator to intelligently decide between Quick Flow and Full Method,
So that simple tasks don't get over-engineered and complex tasks get proper planning.

**Acceptance Criteria:**

**Given** `state.yaml` has `route: null` (no override flag was used)
**When** the orchestrator agent launches for the first time
**Then** it analyzes the task description and sets `route` to either `quick` or `full`

**Given** a task description like "Fix the login button styling on the dashboard"
**When** the routing analysis runs
**Then** the route is set to `quick` (single-file, well-defined, narrow scope)

**Given** a task description like "Build a notification system with email and push support, batching, and user preferences"
**When** the routing analysis runs
**Then** the route is set to `full` (multi-component, architectural impact, ambiguous scope)

**Given** `state.yaml` already has `route: quick` or `route: full` (override flag was used)
**When** the orchestrator agent launches
**Then** it skips routing analysis and respects the existing route value

**Given** routing is determined
**When** the orchestrator updates state
**Then** `state.yaml` reflects the route decision and `currentStage` is set to the first stage of the chosen track (`prd` for full, `quick-spec` for quick)

### Story 1.5: First Stage Template & End-to-End Proof

As a solo developer,
I want to run the orchestrator end-to-end for a single stage,
So that I can verify the entire Ralph Loop execution architecture works before building the full pipeline.

**Acceptance Criteria:**

**Given** the `stage-prd.md` template exists in `.bmad-orchestrator/templates/`
**When** reviewed
**Then** it contains frontmatter with `stage: prd`, `agent: bmad-pm`, `command: CP`, `requiredArtifacts: []`, `producedArtifacts: [prd.md]`
**And** it contains Context Injection, Stage Instructions, and Verification sections

**Given** the user runs `/bmad-orchestrate "Build a task management app"` on a feature branch
**When** `loop.sh` is executed
**Then** the orchestrator agent launches, reads state, routes to `full`, loads `stage-prd.md`, launches the PM sub-agent via Task tool, drives the PRD workflow by responding as an expert user, and produces `_bmad-output/planning-artifacts/prd.md`

**Given** the sub-agent completes the PRD workflow
**When** the orchestrator runs verification
**Then** it confirms `prd.md` exists on disk
**And** it validates the output aligns with the original task description
**And** it updates `state.yaml` with `completedStages: [prd]` and advances `currentStage`

**Given** the orchestrator has completed verification and state update
**When** it exits
**Then** it exits with code 0
**And** the loop script detects the exit and would relaunch (but since only PRD template exists, the next stage is not yet available — this validates the loop mechanism)

**Given** the stage-prd template's Verification section
**When** the orchestrator checks output
**Then** it verifies produced artifacts exist on disk, output aligns with the task description, and no critical gaps exist between task intent and PRD content

## Epic 2: Full Pipeline & Quick Flow Orchestration

User can run the orchestrator and have it execute the entire Full Method pipeline (PRD → Architecture → Epics → Readiness → Sprint → Story Loop) or Quick Flow (Spec → Dev) from start to finish, with git commits during implementation.

**Stories:** 2.1 Architecture & Epics-Stories Templates | 2.2 Readiness Template | 2.3 Sprint Planning & Story Loop Init | 2.4 Story Loop & Create Story | 2.5 Dev Story & Code Review | 2.6 Quick Flow | 2.7 File Reference & Resume

### Story 2.1: Architecture & Epics-Stories Stage Templates

As a solo developer,
I want the orchestrator to drive the Architecture and Epics & Stories stages autonomously,
So that I get a complete Architecture and Epic breakdown from the PRD without manual intervention.

**Acceptance Criteria:**

**Given** the `stage-architecture.md` template exists
**When** the orchestrator reaches the `architecture` stage
**Then** it launches the Architect sub-agent via Task tool, passes the task description and references `prd.md` as input, drives the workflow as an expert user, and produces `_bmad-output/planning-artifacts/architecture.md`

**Given** the `stage-epics-stories.md` template exists
**When** the orchestrator reaches the `epics-stories` stage
**Then** it launches the PM sub-agent via Task tool, passes PRD and Architecture as input, drives the workflow as an expert user, and produces epic files in `_bmad-output/`

**Given** each template follows the Architecture's prompt template format
**When** reviewed
**Then** each contains frontmatter with `stage`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
**And** each contains Context Injection, Stage Instructions, and Verification sections

**Given** a planning stage completes successfully
**When** the orchestrator runs verification
**Then** it confirms all `producedArtifacts` exist on disk, validates output aligns with the original task, and updates `state.yaml` atomically

**Given** the orchestrator transitions between planning stages
**When** each stage completes
**Then** `completedStages` is updated, `currentStage` advances to the next stage in sequence, and the agent exits with code 0

### Story 2.2: Implementation Readiness Stage Template

As a solo developer,
I want the orchestrator to run the Implementation Readiness check autonomously and interpret its results,
So that planning quality is validated before any code is written.

**Acceptance Criteria:**

**Given** the `stage-readiness.md` template exists
**When** the orchestrator reaches the `readiness` stage
**Then** it launches the appropriate sub-agent via Task tool, passes all planning artifacts (PRD, Architecture, Epics), drives the implementation readiness check, and records the result (PASS/CONCERNS/FAIL)

**Given** the readiness stage template follows the Architecture's prompt template format
**When** reviewed
**Then** it contains frontmatter with `stage: readiness`, `agent`, `command: IR`, `requiredArtifacts: [prd.md, architecture.md, epics.md]`, `producedArtifacts: [implementation-readiness-report.md]`
**And** it contains Context Injection, Stage Instructions, and Verification sections

**Given** the readiness check completes with PASS
**When** the orchestrator runs verification
**Then** it confirms the readiness report exists on disk, reads the overall status as PASS, updates `state.yaml` atomically, and advances to the next stage

**Given** the readiness check completes with CONCERNS or FAIL
**When** the orchestrator reads the result
**Then** the stage is treated as a failure, the specific concerns from the readiness report are captured in the `failures` array for downstream re-routing (Epic 3), and the orchestrator follows the standard failure/retry flow

**Given** the readiness stage completes
**When** the orchestrator updates state
**Then** `completedStages` is updated, `currentStage` advances, and the agent exits with code 0

### Story 2.3: Sprint Planning & Story Loop Initialization

As a solo developer,
I want the orchestrator to set up sprint planning and discover all stories automatically,
So that the implementation phase knows exactly which epics and stories to execute and in what order.

**Acceptance Criteria:**

**Given** the `epics-stories` stage has completed and epic files exist on disk
**When** the orchestrator prepares for the implementation phase
**Then** it parses the produced epic files, discovers all epics and stories within them, and builds the `storyLoop` structure in `state.yaml`

**Given** the `storyLoop` structure is built
**When** reviewing `state.yaml`
**Then** each epic has an `id`, `status: pending`, and a `stories` array with each story having an `id` and `status: pending`

**Given** the `stage-sprint-planning.md` template exists
**When** the orchestrator reaches the `sprint-planning` stage
**Then** it launches the SM sub-agent via Task tool, passes the epics as input, drives sprint planning, and produces `_bmad-output/implementation-artifacts/sprint-status.yaml`

**Given** sprint planning completes
**When** the orchestrator runs verification
**Then** it confirms `sprint-status.yaml` exists on disk and updates `state.yaml` atomically

### Story 2.4: Story Loop Iteration & Create Story Template

As a solo developer,
I want the orchestrator to iterate through every story in every epic and create detailed story files,
So that the implementation phase has a clear execution order and each story is fully specified before development begins.

**Acceptance Criteria:**

**Given** `state.yaml` has a populated `storyLoop` with epics and stories
**When** the orchestrator enters the story execution phase
**Then** it processes stories sequentially: first story of first epic, then second story, and so on through all epics

**Given** the `stage-create-story.md` template exists
**When** the orchestrator reaches a story with `status: pending`
**Then** it launches the PM sub-agent to create the detailed story file, updates the story's `status` to `created` and `phase` to `create-story`

**Given** the create-story template follows the Architecture's prompt template format
**When** reviewed
**Then** it contains frontmatter with `stage: create-story`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
**And** it contains Context Injection, Stage Instructions, and Verification sections

**Given** a story file is created successfully
**When** the orchestrator runs verification
**Then** it confirms the story file exists on disk, validates it contains acceptance criteria, and updates `state.yaml` atomically

**Given** all stories in an epic are completed
**When** the orchestrator checks the epic
**Then** the epic's `status` is set to `completed` and the orchestrator moves to the next epic

**Given** all epics and all stories are completed
**When** the orchestrator checks the pipeline
**Then** it recognizes the pipeline is complete and exits with code 2

**Given** each story loop iteration
**When** the orchestrator updates `state.yaml`
**Then** the update uses atomic write (temp file then rename) and accurately reflects which story is in progress and which phase it's in

### Story 2.5: Dev Story & Code Review Templates with Git Commits

As a solo developer,
I want the orchestrator to implement each created story and run code review with automatic git commits,
So that every story results in working code, passing tests, reviewed commits, and a completed story file.

**Acceptance Criteria:**

**Given** the `stage-dev-story.md` template exists
**When** a story has `status: created`
**Then** it launches the Dev sub-agent to implement the story, updates `phase` to `dev-story`
**And** the sub-agent makes git commits to the current worktree branch during implementation

**Given** the `stage-code-review.md` template exists
**When** a story has been implemented
**Then** it launches a review sub-agent to perform code review, updates `phase` to `code-review`

**Given** each template follows the Architecture's prompt template format
**When** reviewed
**Then** each contains frontmatter with `stage`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
**And** each contains Context Injection, Stage Instructions, and Verification sections

**Given** the dev-story template's Verification section
**When** the orchestrator checks output
**Then** it verifies code changes exist, tests pass, and git commits were made to the current worktree branch

**Given** a story passes code review
**When** the orchestrator updates state
**Then** the story's `status` is set to `completed` and the orchestrator moves to the next story

**Given** code review returns issues
**When** the orchestrator reads the review result
**Then** the stage is treated as a failure and the orchestrator follows the standard retry flow, injecting review feedback into `{{failure_context}}` for the dev-story retry

**Given** each story loop iteration
**When** the orchestrator updates `state.yaml`
**Then** the update uses atomic write (temp file then rename) and accurately reflects which story is in progress and which phase it's in

### Story 2.6: Quick Flow Pipeline

As a solo developer,
I want to run a two-stage Quick Flow for simple tasks,
So that bug fixes and small utilities get built fast without full planning overhead.

**Acceptance Criteria:**

**Given** `state.yaml` has `route: quick`
**When** the orchestrator launches
**Then** it follows the Quick Flow track: `quick-spec` → `quick-dev`

**Given** the `stage-quick-spec.md` template exists
**When** the orchestrator reaches the `quick-spec` stage
**Then** it launches the appropriate sub-agent, drives the Quick Spec workflow, and produces a tech spec artifact

**Given** the `stage-quick-dev.md` template exists
**When** the orchestrator reaches the `quick-dev` stage
**Then** it launches the Dev sub-agent with the tech spec as input, drives the Quick Dev workflow, and produces implemented code with passing tests

**Given** Quick Flow completes both stages
**When** the orchestrator checks the pipeline
**Then** it recognizes the pipeline is complete and exits with code 2

**Given** each Quick Flow template
**When** reviewed
**Then** each follows the standard template format with frontmatter, Context Injection, Stage Instructions, and Verification sections

### Story 2.7: File Reference Detection & Resume Capability

As a solo developer,
I want the orchestrator to pick up file references in my task description and resume failed runs from where they left off,
So that I can provide richer context and never lose completed work.

**Acceptance Criteria:**

**Given** a task description containing a file path like "implement the feature described in docs/feature-spec.md"
**When** the orchestrator processes the task
**Then** it detects the file reference, reads the file contents, and includes them as additional context when launching sub-agents

**Given** a task description with multiple file references
**When** the orchestrator processes the task
**Then** all referenced files are detected and loaded as context

**Given** a task description references a file that does not exist
**When** the orchestrator processes the task
**Then** it logs a warning but continues with the available context rather than failing

**Given** the user runs `/bmad-orchestrate --resume`
**When** `state.yaml` exists with `status: running` or `status: failed`
**Then** `state.yaml` is updated with `runType: resume` and the orchestrator continues from the last completed stage

**Given** the user runs `/bmad-orchestrate --resume`
**When** no `state.yaml` exists
**Then** the command fails with a clear error: "No previous run found to resume."

**Given** a resumed run
**When** the orchestrator launches
**Then** it respects all existing artifacts and completed stages, picking up exactly where the previous run stopped

## Epic 3: Failure Recovery & Artifact Safety

When a stage fails, the orchestrator detects it, identifies the problem, re-routes to fix it, retries, and protects existing work. Failures never lose progress.

### Story 3.1: Stage Failure Detection & Retry Logic

As a solo developer,
I want the orchestrator to detect failures and automatically retry,
So that transient issues or fixable problems don't kill the entire pipeline.

**Acceptance Criteria:**

**Given** a sub-agent completes a workflow stage
**When** the orchestrator's verification step finds that produced artifacts are missing or output doesn't align with the task
**Then** the stage is treated as a failure

**Given** a validation stage (readiness, code-review) returns CONCERNS or FAIL
**When** the orchestrator reads the validation result
**Then** the stage is treated as a failure

**Given** a stage failure occurs
**When** the orchestrator logs the failure
**Then** it appends an entry to the `failures` array in `state.yaml` with `stage`, `attempt` number, a single-line `error` summary, and `timestamp`

**Given** a stage failure occurs and `currentRetries` is less than `maxRetries`
**When** the orchestrator decides the next action
**Then** it increments `currentRetries`, keeps `currentStage` unchanged, and exits with code 0 so the loop relaunches for a retry

**Given** `maxRetries` defaults to 3
**When** no override is provided
**Then** up to 3 retry attempts are made before the stage is considered terminally failed

**Given** a retry attempt
**When** the orchestrator relaunches for the same stage
**Then** the previous failure context from the `failures` array is injected into the stage template's `{{failure_context}}` so the sub-agent can address the specific issue

### Story 3.2: Upstream Re-routing & Remediation

As a solo developer,
I want the orchestrator to fix the root cause when a downstream validation fails,
So that issues like "architecture didn't address connection pooling" get fixed at the source rather than retrying the same broken stage.

**Acceptance Criteria:**

**Given** implementation readiness returns CONCERNS or FAIL with a report identifying gaps
**When** the orchestrator analyzes the failure report
**Then** it identifies which upstream stage produced the artifact with the gap (e.g., architecture, PRD)

**Given** an upstream stage is identified as needing revision
**When** the orchestrator re-routes
**Then** it sets `currentStage` back to the upstream stage, constructs specific remediation instructions from the failure report, and injects them into the stage template's `{{failure_context}}`

**Given** the orchestrator re-routes to an upstream stage
**When** the sub-agent runs the revision
**Then** the sub-agent receives clear instructions like "Address connection pooling concerns raised in the implementation readiness report" rather than re-running the entire workflow from scratch

**Given** the upstream revision completes
**When** the orchestrator advances the pipeline
**Then** it re-runs the validation stage that originally failed to verify the fix

**Given** a re-routing occurs
**When** the orchestrator updates state
**Then** the `failures` array captures the full chain: original failure, re-route decision, and the re-routed stage attempt

### Story 3.3: Terminal Failure & Artifact Protection

As a solo developer,
I want the pipeline to stop cleanly when recovery is impossible and my existing work to be protected from accidental overwrite,
So that I never lose completed artifacts and always know when to intervene manually.

**Acceptance Criteria:**

**Given** `currentRetries` reaches `maxRetries` for a stage
**When** the orchestrator evaluates the retry count
**Then** it sets `status: failed` in `state.yaml` and exits with code 1

**Given** the pipeline transitions to `status: failed`
**When** the agent exits
**Then** `state.yaml` accurately reflects all completed stages, the failed stage, and the complete failure history

**Given** a fresh run (`runType: fresh`) is initiated via `/bmad-orchestrate`
**When** existing artifacts are detected in `_bmad-output/` or an existing `state.yaml` is found
**Then** the command fails with a clear error: "Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first."

**Given** a resume run (`runType: resume`) is initiated
**When** existing artifacts and `state.yaml` are found
**Then** the orchestrator respects all existing artifacts, does not overwrite them, and continues from the last completed stage

**Given** a stage partially completed before failure
**When** the orchestrator evaluates artifacts on resume
**Then** partial artifacts from the failed stage are not treated as complete — the stage is re-run from the beginning

## Epic 4: Checkpoint Mode & Party Mode

User can opt into human-in-the-loop mode with gate pausing, feedback loops, and brainstorming when the orchestrator detects it would help.

### Story 4.1: Checkpoint Gate Pausing & Approval

As a solo developer,
I want the orchestrator to pause at key decision points when I use `--checkpoint`,
So that I can review artifacts before the pipeline continues and catch issues early.

**Acceptance Criteria:**

**Given** `state.yaml` has `mode: checkpoint` and the `gates` array contains `[prd, architecture, epics-stories, readiness, code-review]`
**When** the orchestrator completes a stage that matches a gate
**Then** it presents a summary of what was produced, sets `status: paused`, and exits with code 3

**Given** the orchestrator pauses at a gate
**When** the summary is presented
**Then** it includes: stage name, artifacts produced, key decisions or outputs from the stage, and instructions to resume

**Given** the loop script receives exit code 3
**When** the loop stops
**Then** it displays a message: "Checkpoint reached after [stage]. Review artifacts and run `--resume` to continue."

**Given** the user runs `/bmad-orchestrate --resume` after a checkpoint pause
**When** `state.yaml` has `status: paused`
**Then** the status is set back to `running` and the pipeline advances to the next stage

**Given** `state.yaml` has `mode: autonomous`
**When** the orchestrator completes a stage that matches a gate
**Then** it does NOT pause — it continues to the next stage automatically

### Story 4.2: Checkpoint Feedback & Revision

As a solo developer,
I want to provide feedback at a checkpoint that the orchestrator incorporates before moving on,
So that I can steer the output without manually editing artifacts.

**Acceptance Criteria:**

**Given** the orchestrator has paused at a checkpoint gate
**When** the user resumes with feedback (e.g., `/bmad-orchestrate --resume` with the orchestrator detecting user-provided feedback)
**Then** the orchestrator re-runs the paused stage with the feedback injected as additional context

**Given** user feedback like "PRD is missing refresh token handling"
**When** the orchestrator processes the feedback
**Then** it constructs remediation instructions from the feedback and injects them into the stage template's `{{failure_context}}` field

**Given** the orchestrator revises a stage based on feedback
**When** the revised stage completes
**Then** it pauses again at the same gate with an updated summary for the user to re-review

**Given** the user approves after revision (resumes without feedback)
**When** the orchestrator detects no feedback
**Then** it advances to the next stage normally

**Given** feedback is provided at a checkpoint
**When** the orchestrator logs the interaction
**Then** the feedback and revision are recorded in the `failures` array as a checkpoint revision (distinct from an actual failure)

### Story 4.3: Party Mode Integration

As a solo developer,
I want the orchestrator to invoke brainstorming when it detects ambiguity or competing approaches,
So that autonomous runs benefit from multi-perspective analysis at critical decision points.

**Acceptance Criteria:**

**Given** the orchestrator is interacting with a sub-agent via Task tool resume
**When** the sub-agent's output or the task description contains competing approaches or trade-offs (e.g., "should we use WebSockets or SSE?")
**Then** the orchestrator detects this as a Party Mode trigger

**Given** the task scope spans multiple architectural domains
**When** the orchestrator evaluates the sub-agent interaction
**Then** it detects this as a Party Mode trigger

**Given** the task contains undefined or ambiguous technical terms
**When** the orchestrator evaluates the sub-agent interaction
**Then** it detects this as a Party Mode trigger

**Given** the task has unspecified elements that would normally benefit from human verification
**When** running in autonomous mode with no human in the loop
**Then** the orchestrator detects this as a Party Mode trigger (brainstorming substitutes for human input)

**Given** any FR31 trigger is detected
**When** the orchestrator decides to invoke Party Mode
**Then** it instructs the current sub-agent to invoke Party Mode for the specific question or decision point

**Given** Party Mode completes
**When** the sub-agent returns with brainstorming results
**Then** the orchestrator incorporates the results and continues the normal workflow interaction

## Epic 5: Status Reporting & Run Observability

Every run produces a comprehensive report -- what stages ran, what passed, what failed, recovery instructions, and a full artifact inventory. Plus a human-readable task report for knowledge transfer.

### Story 5.1: Stage-Level Status Logging

As a solo developer,
I want each pipeline stage to log its outcome as it completes,
So that the status report builds incrementally and I can see progress even during a run.

**Acceptance Criteria:**

**Given** a pipeline stage completes successfully
**When** the orchestrator updates state
**Then** it also appends an entry to `.bmad-orchestrator/status-report.md` with: stage name, outcome (PASS), artifacts produced, and timestamp

**Given** a pipeline stage fails
**When** the orchestrator logs the failure
**Then** it appends an entry to `status-report.md` with: stage name, outcome (FAIL), error summary, retry attempt number, and timestamp

**Given** a stage is retried and succeeds on a subsequent attempt
**When** the orchestrator logs the outcome
**Then** both the failure entries and the eventual success entry are present in `status-report.md`, showing the full history

**Given** `status-report.md` does not yet exist
**When** the first stage completes
**Then** the file is created with a header section including task description, route, mode, and start timestamp

**Given** the status report is append-only
**When** multiple stages write to it
**Then** entries are never overwritten or reordered — each new entry is appended at the end

### Story 5.2: Final Status Report & Failure Details

As a solo developer,
I want a clear final summary when the pipeline completes or fails,
So that I immediately know the outcome, what was produced, and what to do next if something went wrong.

**Acceptance Criteria:**

**Given** the pipeline completes successfully (agent exits with code 2)
**When** the loop script finalizes the report
**Then** it appends a summary section to `status-report.md` with: overall status (COMPLETED), total stages run, total time elapsed, and a complete artifact inventory listing every file produced in `_bmad-output/`

**Given** the pipeline fails (agent exits with code 1)
**When** the loop script finalizes the report
**Then** it appends a summary section with: overall status (FAILED), the failure point (stage name and story if applicable), error details from the `failures` array, completed stages, and recovery instructions including the exact `--resume` command to run

**Given** the pipeline pauses at a checkpoint (agent exits with code 3)
**When** the loop script finalizes the report
**Then** it appends a summary section with: overall status (PAUSED), the checkpoint stage, what was completed so far, and instructions to review and resume

**Given** the agent crashed with an unexpected exit code
**When** the loop script detects the crash
**Then** it appends a crash entry to `status-report.md` with the exit code and a message that the agent terminated unexpectedly

**Given** the final summary includes an artifact inventory
**When** the inventory is generated
**Then** it lists every file in `_bmad-output/` with its path and which stage produced it

### Story 5.3: Task Report Generation

As a solo developer,
I want a human-readable knowledge transfer document after an autonomous run,
So that I understand what was built, why key decisions were made, and anything I should know about the autonomously-produced work.

**Acceptance Criteria:**

**Given** the pipeline completes successfully
**When** the loop script detects exit code 2
**Then** it launches the orchestrator one final time with a "generate-task-report" directive before terminating

**Given** the orchestrator is launched with the "generate-task-report" directive
**When** it executes
**Then** it reads all produced artifacts in `_bmad-output/`, the `state.yaml` file, and `status-report.md`

**Given** the orchestrator has read all run context
**When** it generates the task report
**Then** it writes `.bmad-orchestrator/task-report.md` containing:
- Summary of work accomplished
- Key decisions made during execution and their rationale
- Important code implemented: what it does, why, and how it works
- Architecture and design choices sub-agents made autonomously
- Anything unexpected or noteworthy from the run

**Given** the task report is generated
**When** the orchestrator completes
**Then** it exits with code 2 and the loop script terminates

**Given** the pipeline failed (not completed)
**When** the loop script handles the failure
**Then** it does NOT launch the task report generation — task reports are only for successful completions

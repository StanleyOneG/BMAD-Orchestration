---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete']
inputDocuments: []
workflowType: 'prd'
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 0
  projectDocs: 0
classification:
  projectType: developer_tool
  domain: developer_tooling_ai_orchestration
  complexity: medium
  projectContext: greenfield
---

# Product Requirements Document - BMAD Orchestrator

**Author:** Stanley
**Date:** 2026-02-02

## Executive Summary

**Product:** BMAD Orchestrator -- an autonomous pipeline runner that drives the entire BMAD Method workflow from a single Claude Code slash command.

**Problem:** Running BMAD manually requires hopping between agents across fresh chat sessions, remembering workflow order, passing context between stages, and managing the full planning-to-implementation lifecycle by hand. This cognitive overhead adds friction to every project.

**Solution:** A meta-agent powered by a Ralph Loop pattern (self-restarting stateless agent loop) that takes a task description, decides the appropriate workflow track (Quick Flow vs Full Method), and autonomously drives every BMAD stage end-to-end -- producing planning artifacts, architecture, stories, working code, passing tests, and commits without human intervention.

**Differentiator:** No existing tool combines a structured software development methodology with fully autonomous AI agent orchestration. "Vibe coding" tools skip planning. Agent frameworks skip methodology. BMAD Orchestrator enforces proven development rigor autonomously.

**Target User:** Solo developer already familiar with the BMAD Method, using Claude Code daily.

## Success Criteria

### User Success
- Run a single slash command with a task description and walk away
- Return to find: all BMAD artifacts in `_bmad-output/`, code implemented, tests passing, story files completed, commits made
- Output indistinguishable from manually driving each BMAD agent
- Autonomous mode requires zero human input from start to finish

### Business Success
- Used daily as a personal productivity tool
- 90% of tasks complete fully autonomously without manual intervention
- Remaining 10% surface clear, actionable errors with recovery instructions
- Replaces the cognitive overhead of manually orchestrating BMAD workflows

### Technical Success
- Correct routing: Quick Flow vs Full Method based on task analysis -- no misroutes
- Artifact chain integrity: every workflow reads correct upstream artifacts from disk
- Failure recovery: orchestrator autonomously loops back to the correct stage when validation fails
- No hanging: process either completes or fails with a clear report -- never stalls silently
- Checkpoint mode available via flag for human-in-the-loop when desired

### Measurable Outcomes
- 9 out of 10 tasks complete end-to-end without human intervention
- All BMAD artifacts match the quality of manual agent-driven workflows
- Failed runs produce a clear status report identifying the failure point and suggested recovery

## Product Scope

### MVP (Phase 1)

**MVP Approach:** Problem-solving MVP -- replace the entire manual BMAD orchestration workflow with a single command. The bar is feature parity with manual BMAD usage, not a stripped-down subset.

**Resource Requirements:** Solo developer (Stanley), existing BMAD installation, Claude Code with subscription access.

**Must-Have Capabilities:**
- Single slash command entry point (`/bmad-orchestrate`)
- Task analysis and routing logic (Quick Flow vs Full Method)
- Full Method orchestration: PRD → Architecture → Epics & Stories → Implementation Readiness → Sprint Planning → Create Story → Dev Story → Code Review
- Quick Flow orchestration: Quick Spec → Quick Dev
- Ralph Loop execution architecture with YAML state file
- Autonomous mode (default) with YOLO-style agent prompting
- Checkpoint mode (`--checkpoint`) with gate pausing and feedback handling
- Failure recovery with autonomous stage re-routing
- Resume capability (`--resume`) from last completed stage
- Routing override flags (`--quick`, `--full`)
- Party Mode invocation when orchestrator detects brainstorming would help
- Multi-epic support: loop through all epics/stories automatically
- Parallel agent execution where workflow allows
- Git branch safety check (fail if on main/master)
- Artifact overwrite protection
- Final status report on completion or failure

**Core User Journeys Supported:** Autonomous happy path, failure recovery, checkpoint mode, failed run investigation.

### Growth (Phase 2)
- Retrospective auto-run after epic completion
- Course correction detection and autonomous re-planning
- Custom workflow step injection
- Run history and success rate tracking

### Vision (Phase 3)
- Contribution back to BMAD as an official module
- Configurable workflow graphs (skip phases, add custom steps)
- Learning from past runs to improve routing decisions
- Multi-project orchestration

### Risk Mitigation

**Technical Risks:**
- Context window degradation → Mitigated by Ralph Loop pattern (fresh context each stage)
- Agent produces low-quality output silently → Mitigated by BMAD's own validation steps (implementation readiness, code review) and retry logic
- State file corruption → Mitigated by human-readable YAML format, easy to manually edit/fix

**Resource Risks:**
- Solo developer building and using → Mitigated by lean file-drop installation, no complex infrastructure
- Orchestrator quality disappoints → Checkpoint mode as immediate fallback, can always revert to manual BMAD

## User Journeys

### Journey 1: Autonomous Mode -- Happy Path

Stanley opens his terminal and types:

`/bmad-orchestrate "Build a notification system that sends email and push notifications when users receive new messages. Should support batching and user preferences for notification frequency."`

He hits enter and walks away. The orchestrator analyzes the task -- multi-epic feature, not a quick fix -- and routes to Full Method. It spins up the PM agent, drives through PRD creation in YOLO mode, saves `prd.md`. Launches the Architect, feeds it the PRD, produces `architecture.md`. Detects the batching strategy could benefit from brainstorming, runs Party Mode internally. Back to PM for epics and stories. Architect for implementation readiness -- passes. SM for sprint planning. Then the story loop: create story, dev story, code review, next story.

Stanley returns to find: all artifacts in `_bmad-output/`, code implemented, all tests green, story files complete, clean commit history, and a final status report showing every stage and its outcome.

**Capabilities revealed:** Task analysis, routing, full pipeline orchestration, YOLO-mode agent prompting, artifact chain, commit automation, status reporting.

### Journey 2: Autonomous Mode -- Failure Recovery

Stanley kicks off the orchestrator for adding a real-time WebSocket layer. The orchestrator routes to Full Method, completes PRD and Architecture. Implementation Readiness returns CONCERNS -- architecture didn't address connection pooling.

The orchestrator reads the readiness report, identifies the gap in the architecture document, loops back to the Architect with specific instructions: "Address connection pooling concerns raised in the implementation readiness report." The Architect revises `architecture.md`. Re-runs readiness -- PASS. Continues through the rest of the pipeline.

Status report shows: "Implementation readiness failed on first attempt. Auto-recovered: architecture revised to address connection pooling. Second attempt passed. Pipeline completed successfully."

**Capabilities revealed:** Failure detection, readiness report parsing, stage-specific re-routing, recovery prompting, recovery logging, retry limits.

### Journey 3: Checkpoint Mode -- Reviewing at Gates

Stanley runs:

`/bmad-orchestrate --checkpoint "Implement OAuth2 authentication with Google and GitHub providers, including role-based access control"`

The orchestrator completes PRD creation autonomously, then pauses. Presents the PRD summary: "PRD complete. Review and approve to continue, or provide feedback." Stanley spots missing refresh token handling, provides feedback. Orchestrator revises and re-presents. Stanley approves.

Continues to Architecture (pause, approve), Epics & Stories (pause, Stanley adjusts priority), Implementation Readiness (pause, PASS, approve). Runs through implementation stories, pausing after each code review for sign-off.

**Capabilities revealed:** Checkpoint gate definitions, feedback handling, revision loops, summary presentation, checkpoint vs autonomous mode differences.

### Journey 4: Investigating a Failed Run

The orchestrator ran overnight and failed. Stanley sees:

```
BMAD Orchestrator - Run Status: FAILED
Task: "Add CSV export to all report pages"
Route: Full Method
Completed: PRD ✓ | Architecture ✓ | Epics ✓ | Readiness ✓ | Sprint ✓
Failed at: dev-story (Story 3 of 5 - "Export with custom column selection")
Error: Tests failing after 2 retry attempts
Artifacts: All planning docs complete, Stories 1-2 implemented, Story 3 partial
Recovery: Run `/bmad-orchestrate --resume` to retry from Story 3
```

Stanley reads Story 3's file, identifies a missing dependency, installs it, runs `--resume`. The orchestrator picks up from Story 3 and completes the remaining work.

**Capabilities revealed:** Status report format, failure categorization, resume functionality, artifact preservation on failure, actionable recovery instructions.

### Journey Requirements Summary

| Journey | Key Capabilities |
|---------|-----------------|
| Autonomous Happy Path | Task analysis, routing, full pipeline orchestration, YOLO-mode prompting, artifact chain, commit automation, status reporting |
| Failure Recovery | Readiness report parsing, stage re-routing, recovery prompts, retry limits, recovery logging |
| Checkpoint Mode | Gate definitions, pause/resume, feedback handling, revision loops, summary presentation |
| Failed Run Investigation | Status report format, resume flag, artifact preservation, failure categorization, actionable errors |

## Domain-Specific Requirements

### Execution Architecture -- Ralph Loop Pattern
- The orchestrator is a shell script loop that repeatedly launches a fresh agent instance -- NOT a single long-running agent
- Each agent instance reads a state tracking file from disk to determine current pipeline position
- Agent executes the current workflow stage, updates the state file, and exits cleanly
- Loop script detects the exit, checks state, and relaunches if pipeline is not complete
- Eliminates context window degradation across long pipelines
- State file is the single source of truth for orchestration progress, not conversation memory

### State File Design
- Tracks: task description, routing decision (Quick Flow vs Full Method), current stage, completed stages, failure history, mode (autonomous vs checkpoint)
- Updated after every workflow stage completion (PRD done, Architecture done, Story N done, etc.)
- Intra-stage granularity handled by `_bmad-output` artifacts and BMAD's own continuation protocols
- Must survive agent restarts -- plain YAML file on disk

### Agent Context Recovery
- On every launch, agent reads the state file and orients itself
- Agent consults `_bmad-output` artifacts to understand what exists and what's next
- No dependency on previous conversation context -- fully stateless between launches
- Agent prompt engineered to handle cold-start orientation from state file alone

### Git Safety
- Orchestrator verifies it is running on a non-main branch before starting
- All commits go to the current worktree branch only
- User responsible for creating the git worktree before invoking the orchestrator
- Fails fast with clear error if on main/master branch

### Artifact Overwrite Protection
- Orchestrator detects existing artifacts from prior runs
- Fresh runs: fail if artifacts already exist (prevent accidental overwrite)
- `--resume` runs: respect existing artifacts and continue from last completed stage
- State file distinguishes between "fresh run" and "resumed run"

## Innovation & Novel Patterns

### Detected Innovation Areas
- **Stateless autonomous methodology orchestration.** No existing tool combines a structured software development methodology with fully autonomous AI agent orchestration using a self-restarting loop pattern
- **Ralph Loop applied to multi-agent pipelines.** Cold-start-from-state-file pattern applied to drive an entire multi-stage, multi-agent development pipeline
- **Methodology-as-automation.** Existing AI coding tools skip process and go straight to code generation. This orchestrator enforces BMAD's proven planning rigor autonomously

### Market Context & Competitive Landscape
- "Vibe coding" tools (Cursor, Copilot agent mode) generate code from prompts but skip planning, architecture, and validation
- Agent frameworks (CrewAI, AutoGen) chain LLM calls but don't enforce a software development methodology
- No existing tool occupies the intersection of "structured methodology" + "fully autonomous execution" + "self-healing loop pattern"

### Validation Approach
- Evidence exists from manual BMAD usage that the structured approach produces higher quality output than single-shot prompting
- Orchestrator output directly comparable against manually-driven BMAD runs on identical tasks
- 90% autonomous success rate is the measurable validation target

### Risk Mitigation
- Checkpoint mode as fallback when autonomous execution doesn't produce quality results
- Same BMAD validation steps (implementation readiness, code review) catch issues as in manual runs
- Resume capability means failures don't lose completed work

## Developer Tool Specific Requirements

### Project-Type Overview
- Claude Code native extension: shell loop script, agent definition files (markdown/YAML), workflow state files, Claude Code hooks
- Manual file drop into `.claude/` and `_bmad/` directories -- not a distributed package
- Personal tooling: no multi-user installation, no version compatibility matrix

### Command Interface
- Entry point: `/bmad-orchestrate` slash command
- Task description passed as natural language string argument
- Agent detects and reads file references within the task description (e.g., "implement the feature described in docs/feature-spec.md")
- Optional flags:
  - `--checkpoint` -- pause at key gates for human approval
  - `--resume` -- continue from last completed stage after failure
  - `--quick` -- force Quick Flow routing
  - `--full` -- force Full Method routing
- Default: autonomous mode, auto-routing based on task analysis

### Technical Components
- **Loop script (bash):** The Ralph Loop -- manages agent lifecycle, checks state file, relaunches agent with fresh context
- **Main orchestrator agent (.claude/agents/):** Reads state file, executes current workflow stage, updates state, exits
- **State file (_bmad-output/):** YAML file tracking pipeline progress, routing decision, failure history
- **Claude Code hooks (.claude/hooks/):** Lifecycle automation, potentially using Python via `uv run`
- **Workflow reference data:** Files the orchestrator consults for routing decisions, agent prompts, stage sequencing

### Implementation Considerations
- No build step, no compilation, no dependency management beyond existing BMAD requirements
- Works with existing BMAD installation structure
- Agent files follow BMAD's own patterns (agent YAML/markdown with persona, workflows, steps)
- State file must be human-readable YAML for debugging

## Functional Requirements

### Task Intake & Routing
- FR1: User can invoke the orchestrator via a single slash command with a natural language task description
- FR2: Orchestrator can detect and read files referenced within the task description
- FR3: Orchestrator can analyze the task description and automatically route to Quick Flow or Full Method track
- FR4: User can override routing with `--quick` or `--full` flags
- FR5: User can select execution mode: autonomous (default) or checkpoint (`--checkpoint`)
- FR6: User can resume a previously failed run with `--resume`

### Pipeline Orchestration -- Full Method
- FR7: Orchestrator can execute the PRD workflow autonomously (YOLO mode, simulating expert user input)
- FR8: Orchestrator can execute the Architecture workflow using the PRD as input
- FR9: Orchestrator can execute the Epics & Stories workflow using PRD and Architecture as input
- FR10: Orchestrator can execute the Implementation Readiness check using all planning artifacts
- FR11: Orchestrator can execute Sprint Planning using the epics
- FR12: Orchestrator can execute Create Story for each story in each epic
- FR13: Orchestrator can execute Dev Story for each created story
- FR14: Orchestrator can execute Code Review for each implemented story
- FR15: Orchestrator can loop through all epics and all stories within each epic automatically

### Pipeline Orchestration -- Quick Flow
- FR16: Orchestrator can execute Quick Spec workflow autonomously
- FR17: Orchestrator can execute Quick Dev workflow using the tech spec as input

### Execution Architecture
- FR18: A loop script can launch the orchestrator agent with fresh context on each iteration
- FR19: Orchestrator agent can read its state from a YAML state file on every launch
- FR20: Orchestrator agent can update the state file after completing each workflow stage
- FR21: Loop script can detect agent exit and relaunch if pipeline is not complete
- FR22: Orchestrator agent can orient itself from a cold start using only the state file and disk artifacts

### Failure Recovery
- FR23: Orchestrator can detect when a validation stage fails (e.g., implementation readiness returns CONCERNS/FAIL)
- FR24: Orchestrator can identify which upstream stage needs revision based on the failure report
- FR25: Orchestrator can re-route to the appropriate stage with specific remediation instructions
- FR26: Orchestrator can retry a failed stage with a configurable maximum retry count
- FR27: Orchestrator can transition to FAILED status when retry limit is exhausted

### Checkpoint Mode
- FR28: Orchestrator can pause execution at defined gate points and present a summary to the user
- FR29: User can provide feedback at a checkpoint that the orchestrator incorporates before proceeding
- FR30: User can approve a checkpoint to continue the pipeline

### Party Mode Integration
- FR31: Orchestrator can detect when a task would benefit from brainstorming (based on task complexity or ambiguity signals)
- FR32: Orchestrator can invoke Party Mode internally as part of the pipeline when brainstorming is warranted

### Git & Artifact Management
- FR33: Orchestrator can verify it is running on a non-main/non-master branch before starting
- FR34: Orchestrator can fail fast with a clear error if on a protected branch
- FR35: Orchestrator can make commits to the current worktree branch during implementation stages
- FR36: Orchestrator can detect existing artifacts and prevent accidental overwrite on fresh runs
- FR37: Orchestrator can respect existing artifacts and continue from them on `--resume` runs

### Status Reporting
- FR38: Orchestrator can generate a final status report showing all stages run and their outcomes
- FR39: Status report can display the failure point, error details, and recovery instructions when a run fails
- FR40: Status report can show the complete artifact inventory produced during the run

### Parallel Execution
- FR41: Orchestrator can identify workflow stages that have no dependencies and can run concurrently
- FR42: Orchestrator can launch multiple agents in parallel where the workflow graph allows it

## Non-Functional Requirements

### Reliability
- The orchestrator must never silently corrupt the state file -- every write must be atomic (write complete state or don't write at all)
- A failed run must always produce a readable status report -- no silent failures
- The state file must always reflect the true pipeline state -- if a stage completed, it's recorded; if it didn't, it's not
- The loop script must detect agent crashes (non-clean exits) and log them to the status report rather than silently restarting
- Partial artifacts from a failed stage must not be treated as complete by subsequent stages

### Integration
- The orchestrator must work with Claude Code's native agent system (Task tool, `.claude/agents/` conventions) as of the current version
- The orchestrator must follow BMAD's file conventions for `_bmad-output/` artifact paths, naming, and structure
- BMAD workflow changes (new steps, renamed artifacts) should require only state file and prompt updates, not architectural changes to the orchestrator
- Git operations must use standard git CLI commands compatible with worktree setups

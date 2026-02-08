---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
status: 'complete'
completedAt: '2026-02-03'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/prd-validation-report.md'
workflowType: 'architecture'
project_name: 'bmad_testing'
user_name: 'Stanley'
date: '2026-02-03'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
42 FRs across 10 capability groups. The architecture must support:
- **Intake & Routing (FR1-FR6):** Single entry point that analyzes task descriptions and routes to the correct pipeline track. Supports flags for mode and route overrides, plus resume from failure.
- **Full Method Pipeline (FR7-FR15):** Sequential orchestration of 8 BMAD workflow stages with a nested story loop (per-epic, per-story: create → dev → code-review). Each stage invokes a different BMAD agent with specific upstream artifacts.
- **Quick Flow Pipeline (FR16-FR17):** Two-stage pipeline (spec → dev) as an alternative track for simple tasks.
- **Execution Architecture (FR18-FR22):** Ralph Loop pattern -- bash loop launches stateless agent instances that orient from a YAML state file. No in-memory state persists between iterations.
- **Failure Recovery (FR23-FR27):** Detection of validation failures, upstream stage identification, re-routing with remediation context, configurable retry limits, and terminal FAILED status.
- **Checkpoint Mode (FR28-FR30):** Gate-based pausing, summary presentation, user feedback incorporation, and approval to continue.
- **Party Mode (FR31-FR32):** Conditional brainstorming invocation based on task analysis triggers (competing approaches, ambiguous scope, undefined terms).
- **Git & Artifacts (FR33-FR37):** Branch safety checks, commit automation, artifact overwrite protection, and resume-aware artifact handling.
- **Status Reporting (FR38-FR40):** Final run report with stage outcomes, failure details, recovery instructions, and artifact inventory.
- **Parallel Execution (FR41-FR42):** Concurrent agent launches where workflow graph permits independent stages.

**Non-Functional Requirements:**
9 NFRs focused on reliability and integration. Per the validation report, all lack measurable metrics -- architecturally we should design for:
- Atomic state file writes (no partial/corrupt state)
- Crash detection and logging (no silent failures)
- State file as single source of truth (always reflects actual pipeline state)
- Compatibility with Claude Code's native agent system and BMAD file conventions
- Loose coupling to BMAD workflow definitions (prompt/config changes, not code changes)

**Scale & Complexity:**

- Primary domain: CLI tooling / developer automation
- Complexity level: Medium
- Estimated architectural components: 5 (loop script, orchestrator agent, state file schema, routing logic, workflow stage definitions)

### Technical Constraints & Dependencies

- **Platform locked:** Claude Code agent system, bash shell, git CLI
- **No external infrastructure:** No databases, APIs, cloud services, or package managers
- **File-drop installation:** Must work by copying files into `.claude/` and `_bmad/` directories
- **BMAD compatibility:** Must consume and produce artifacts following BMAD's existing `_bmad-output/` conventions
- **Context window management:** Ralph Loop pattern is a hard constraint -- each agent invocation starts fresh, state recovery is from disk only
- **Single user:** No multi-tenancy, no concurrent runs, no authentication

### Cross-Cutting Concerns Identified

- **State consistency:** Every component reads/writes the YAML state file -- corruption or stale reads break the entire pipeline
- **Artifact chain integrity:** Each workflow stage depends on specific upstream artifacts existing and being valid. Missing or malformed artifacts cascade failures.
- **Mode awareness:** Autonomous vs checkpoint mode affects control flow at every gate point -- must be cleanly separated from pipeline logic
- **Error propagation:** Failures can occur at any stage. The architecture must ensure failures are always captured, never swallowed, and produce actionable output.
- **Agent prompt engineering:** Each stage invocation must construct the right prompt with the right artifacts loaded -- this is the primary integration surface

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- State file schema and lifecycle
- Loop script design and agent invocation
- Agent-to-sub-agent communication pattern
- Prompt template approach

**Important Decisions (Shape Architecture):**
- Routing logic placement
- Party Mode triggering mechanism
- File and directory structure
- Checkpoint gate configuration

**Deferred Decisions (Post-MVP):**
- Parallel execution specifics (FR41-FR42) -- defer until core pipeline works
- Run history and success rate tracking (Phase 2)
- Custom workflow step injection (Phase 2)

### State File Schema

**Location:** `.bmad-orchestrator/state.yaml`
**Write strategy:** Write-to-temp-then-rename (atomic POSIX writes)
**State ownership:** Agent updates state before exiting; loop script reads state and relaunches

```yaml
# .bmad-orchestrator/state.yaml
task: "Original task description string"
route: quick | full
mode: autonomous | checkpoint
status: running | paused | completed | failed
runType: fresh | resume
branch: "feature/my-branch"
createdAt: "2026-02-03T10:00:00Z"
updatedAt: "2026-02-03T10:05:00Z"
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

### Loop Script Design

**Agent invocation:** `claude --agent bmad-orchestrator` with prompt piped to inject state context
**Exit code convention:**
- 0 = stage completed, loop continues
- 1 = stage failed after retries, loop stops
- 2 = pipeline complete, loop stops
- 3 = checkpoint pause, loop stops (user re-invokes with `--resume`)

**Loop script responsibilities:**
- Read state file to check if pipeline is done
- Verify git branch safety (not on main/master)
- Launch agent with fresh context
- Detect non-clean exits (crash vs intentional)
- Write final status report on completion or failure

### Agent Communication Pattern

**Pattern:** Orchestrator acts as the human via Task tool resume mechanism

**Mechanics:**
1. Orchestrator launches sub-agent via Task tool with stage prompt template
2. Sub-agent runs its BMAD workflow, returns output at interaction points
3. Orchestrator reads output, makes expert-level decisions
4. Orchestrator resumes sub-agent (same agent ID) with its response
5. Repeat until sub-agent workflow completes
6. One Ralph Loop iteration = one complete pipeline stage with all back-and-forth

**Implications:**
- Sub-agent workflows run exactly as designed (interactive, with menus and questions)
- Quality matches manual BMAD usage -- the stated PRD goal
- Party Mode triggered by orchestrator during back-and-forth when it judges brainstorming would help
- Sub-agent IDs are transient -- not persisted across Ralph Loop restarts

### Routing Logic

**Location:** In the orchestrator agent prompt, not a config file
**Method:** LLM judgment call analyzing the task description
**Guidelines embedded in prompt:**
- Quick Flow: single-file changes, bug fixes, small utilities, well-defined narrow tasks
- Full Method: multi-component features, new systems, architectural changes, ambiguous scope
**Overrides:** `--quick` and `--full` flags bypass LLM routing entirely

### Party Mode Triggering

**Owner:** Orchestrator agent (not sub-agents)
**Mechanism:** During back-and-forth with a sub-agent, the orchestrator judges whether brainstorming would benefit the current decision point and instructs the sub-agent to invoke Party Mode
**Triggers (from PRD FR31):** Competing approaches, multiple architectural domains, undefined terms, ambiguous elements

### Prompt Templates

**Location:** `.bmad-orchestrator/templates/` -- one file per pipeline stage
**Content:** Each template includes:
- Which BMAD workflow/command to run
- Task description injection point
- Mode-specific instructions (autonomous responses vs checkpoint pausing)
- Failure context injection (for retries)
- Permission for Party Mode invocation

### Artifact Validation

**Strategy:** Orchestrator validates upstream artifacts exist on disk before invoking a stage. Artifact loading stays with the sub-agents -- they discover and load artifacts as part of their own workflow initialization.

### File & Directory Structure

```
.bmad-orchestrator/
  loop.sh
  templates/
    stage-prd.md
    stage-architecture.md
    stage-epics-stories.md
    stage-readiness.md
    stage-sprint-planning.md
    stage-create-story.md
    stage-dev-story.md
    stage-code-review.md
    stage-quick-spec.md
    stage-quick-dev.md
  hooks/
  state.yaml
  status-report.md

.claude/
  agents/
    bmad-orchestrator.md
  commands/
    bmad-orchestrate.md
```

### Decision Impact Analysis

**Implementation Sequence:**
1. State file schema (everything depends on this)
2. Loop script (`loop.sh`)
3. Orchestrator agent definition (`.claude/agents/bmad-orchestrator.md`)
4. Slash command entry point (`.claude/commands/bmad-orchestrate.md`)
5. Stage prompt templates (one at a time, starting with PRD)
6. Routing logic (embedded in orchestrator agent)
7. Checkpoint gate handling
8. Failure recovery and retry logic
9. Status report generation

**Cross-Component Dependencies:**
- Loop script depends on state file schema (reads it) and exit code convention
- Orchestrator agent depends on state file schema (reads/writes it) and prompt templates (loads them)
- Prompt templates depend on understanding each BMAD workflow's interaction points
- Checkpoint gates depend on state file `gates` array and mode field

## Implementation Patterns & Consistency Rules

### Naming Patterns

**YAML State File:** `camelCase` for all field names
- `currentStage`, `storyLoop`, `runType`, `completedStages`, `maxRetries`, `currentRetries`

**File Naming:** `kebab-case` for all files and directories
- `loop.sh`, `state.yaml`, `status-report.md`, `stage-prd.md`, `stage-create-story.md`

**Stage Identifiers (frozen -- must use these exact strings everywhere):**
`prd`, `architecture`, `epics-stories`, `readiness`, `sprint-planning`, `create-story`, `dev-story`, `code-review`, `quick-spec`, `quick-dev`

**Bash Functions:** `snake_case`
- `check_branch_safety`, `read_state`, `launch_agent`, `write_status_report`

### Structure Patterns

**Prompt Template Format:**

Every template file in `.bmad-orchestrator/templates/` must follow this structure:

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
[How the orchestrator validates this stage's output against the original task]
- Verify produced artifacts exist on disk
- Verify output aligns with original task description
- Verify no critical gaps between task intent and stage output
- Stage-specific validation criteria
```

The **Verification** section is critical. After the sub-agent completes its workflow, the orchestrator reads this section and validates the output before marking the stage complete. If verification fails, the orchestrator treats it as a stage failure and enters the retry flow.

**Logging:** All logs consolidated into `.bmad-orchestrator/status-report.md`. No separate log files. Status report is append-friendly -- each stage writes its outcome as it completes.

### Process Patterns

**Error Messages in State File:** Single-line summaries only.
- Good: `"Architecture did not address connection pooling requirements from PRD"`
- Bad: Multi-line stack traces or verbose explanations

**Atomic State Write Pattern (exact implementation):**

```bash
# All state file writes MUST use this pattern
write_state() {
  local state_file=".bmad-orchestrator/state.yaml"
  local tmp_file="${state_file}.tmp"

  # Write complete state to temp file
  cat > "$tmp_file"

  # Atomic rename
  mv "$tmp_file" "$state_file"
}
```

The agent must use this same pattern when updating state from within Claude Code -- write to `state.yaml.tmp`, then rename. No direct writes to `state.yaml`.

**Bash Script Standards:**
- All scripts start with `set -euo pipefail`
- ShellCheck compliant (no suppressed warnings without comment explaining why)
- All variables quoted: `"${var}"` not `$var`
- Functions use `snake_case`
- Local variables declared with `local`
- Exit codes documented at top of script

**Verification Pattern (orchestrator behavior after each stage):**

After every sub-agent workflow completes, before updating state:

1. **Artifact check:** Verify all `producedArtifacts` from the template frontmatter exist on disk
2. **Goal alignment:** Compare stage output against the original `task` from state file -- does the output serve the stated goal?
3. **Quality gate:** For stages with BMAD validation (readiness, code-review), check the validation result (PASS/CONCERNS/FAIL)
4. **Pass:** Update state, write stage outcome to status report, exit 0
5. **Fail:** Log failure to state file `failures` array, increment `currentRetries`, exit with retry or failure code

### Enforcement Guidelines

**All AI agents implementing stories MUST:**
- Use the exact stage identifiers listed above -- no aliases, no variations
- Follow the prompt template format including the Verification section
- Use the atomic write pattern for all state file updates
- Write single-line error summaries to the failures array
- Follow bash best practices (`set -euo pipefail`, quoted variables, ShellCheck compliance)

**Anti-Patterns:**
- Writing to `state.yaml` directly without temp-file-then-rename
- Inventing new stage identifiers not in the frozen list
- Skipping the verification step after sub-agent completion
- Multi-line error messages in the state file
- Unquoted variables in bash scripts

## Project Structure & Boundaries

### Complete Project Directory Structure

**Orchestrator files (checked into repo):**

```
.bmad-orchestrator/
├── loop.sh                          # Ralph Loop - outer control script
├── templates/
│   ├── stage-prd.md                 # PRD creation stage template
│   ├── stage-architecture.md        # Architecture creation stage template
│   ├── stage-epics-stories.md       # Epics & stories stage template
│   ├── stage-readiness.md           # Implementation readiness stage template
│   ├── stage-sprint-planning.md     # Sprint planning stage template
│   ├── stage-create-story.md        # Story creation stage template
│   ├── stage-dev-story.md           # Story implementation stage template
│   ├── stage-code-review.md         # Code review stage template
│   ├── stage-quick-spec.md          # Quick Flow spec stage template
│   ├── stage-quick-dev.md           # Quick Flow dev stage template
│   └── stage-task-report.md         # Task report generation template
└── hooks/                           # Python hooks via uv run (if needed)

.claude/
├── agents/
│   └── bmad-orchestrator.md         # Orchestrator agent definition
└── commands/
    └── bmad-orchestrate.md          # /bmad-orchestrate slash command
```

**Runtime files (produced during execution, not checked in):**

```
.bmad-orchestrator/
├── state.yaml                       # Pipeline state file
├── status-report.md                 # Operational run report (stages passed/failed)
└── task-report.md                   # Human knowledge transfer document
```

**BMAD output artifacts (produced by sub-agents via existing BMAD conventions):**

```
_bmad-output/
├── planning-artifacts/
│   ├── prd.md                       # ← stage: prd
│   ├── architecture.md              # ← stage: architecture
│   └── ...
├── implementation-artifacts/
│   ├── epics/                       # ← stage: epics-stories
│   ├── sprint-status.yaml           # ← stage: sprint-planning
│   └── stories/                     # ← stage: create-story, dev-story
└── ...
```

### Architectural Boundaries

**Boundary 1: Loop Script ↔ Orchestrator Agent**
- Communication: Loop reads `state.yaml` to decide whether to relaunch. Agent reads/writes `state.yaml` to track progress. Agent exits with code 0/1/2/3.
- Contract: State file schema is the interface. Exit codes are the signal protocol.
- The loop script never modifies state. The agent never controls the loop.

**Boundary 2: Orchestrator Agent ↔ Sub-Agents (BMAD agents)**
- Communication: Task tool launch + resume. Orchestrator sends prompts, reads sub-agent output, responds as expert user.
- Contract: Prompt templates define what the orchestrator sends. Sub-agent output is natural language (menus, questions, results).
- The orchestrator never directly modifies BMAD artifacts. Sub-agents produce artifacts through their own workflows.

**Boundary 3: Orchestrator ↔ Filesystem**
- State file: `.bmad-orchestrator/state.yaml` (atomic writes only)
- Status report: `.bmad-orchestrator/status-report.md` (append only during run)
- Task report: `.bmad-orchestrator/task-report.md` (written once at pipeline end)
- Artifact validation: Orchestrator reads `_bmad-output/` to verify artifacts exist, never writes to it directly.
- Templates: Orchestrator reads `.bmad-orchestrator/templates/` -- never modifies them at runtime.

### Requirements to Structure Mapping

| FR Group | Component | Files |
|----------|-----------|-------|
| FR1-FR6 (Intake & Routing) | Orchestrator agent + slash command | `.claude/agents/bmad-orchestrator.md`, `.claude/commands/bmad-orchestrate.md` |
| FR7-FR15 (Full Method Pipeline) | Stage templates + orchestrator logic | `.bmad-orchestrator/templates/stage-*.md` (8 files) |
| FR16-FR17 (Quick Flow) | Quick Flow templates | `stage-quick-spec.md`, `stage-quick-dev.md` |
| FR18-FR22 (Execution Architecture) | Loop script + state file | `loop.sh`, `state.yaml` |
| FR23-FR27 (Failure Recovery) | Orchestrator agent + state file | `bmad-orchestrator.md` (retry logic), `state.yaml` (failures array) |
| FR28-FR30 (Checkpoint Mode) | Orchestrator agent + state file | `bmad-orchestrator.md` (gate logic), `state.yaml` (gates array, mode) |
| FR31-FR32 (Party Mode) | Orchestrator agent | `bmad-orchestrator.md` (trigger detection during sub-agent interaction) |
| FR33-FR37 (Git & Artifacts) | Loop script + orchestrator agent | `loop.sh` (branch check), `bmad-orchestrator.md` (artifact validation) |
| FR38-FR40 (Status Reporting) | Loop script + status report | `loop.sh` (final report), `status-report.md` |

### Data Flow

```
User invokes /bmad-orchestrate "task description"
  → .claude/commands/bmad-orchestrate.md (parses flags, creates initial state)
  → .bmad-orchestrator/loop.sh (reads state, launches agent)
    → .claude/agents/bmad-orchestrator.md (reads state + template, launches sub-agent)
      → Sub-agent (e.g., bmad-pm) runs workflow
      ← Sub-agent returns output
      → Orchestrator responds (resume), repeats until workflow complete
      → Orchestrator runs verification against task
    ← Orchestrator updates state.yaml, appends to status-report.md, exits
  → loop.sh checks state, relaunches if not done
  ...repeat until pipeline complete or failed...
  → loop.sh writes final status report
  → loop.sh launches orchestrator with "generate-task-report" directive
    → Orchestrator reads all produced artifacts, state file, status report
    → Orchestrator synthesizes human-readable Task Report:
      - Summary of work accomplished
      - Key decisions made during execution and their rationale
      - Important code implemented: what it does, why, and how it works
      - Architecture and design choices sub-agents made autonomously
      - Anything unexpected or noteworthy from the run
    → Writes .bmad-orchestrator/task-report.md
  → Pipeline complete
```

## Architecture Validation Results

### Coherence Validation

**Decision Compatibility:** All architectural decisions are internally consistent. Ralph Loop + Task tool resume + state file form a clean, non-conflicting execution model. Atomic write pattern is compatible with the loop-reads/agent-writes contract. Exit codes map to all pipeline states without ambiguity.

**Pattern Consistency:** Naming conventions (`camelCase` YAML, `kebab-case` files, `snake_case` bash) each match their domain idiom. Frozen stage identifiers used consistently across state schema, template filenames, and data flow. Verification pattern uniformly embedded in all templates.

**Structure Alignment:** Three boundaries (loop↔agent, agent↔sub-agents, orchestrator↔filesystem) are cleanly separated with no overlap. Template frontmatter directly supports the verification pattern. Task report fits naturally as a final loop iteration.

### Requirements Coverage Validation

**Functional Requirements:** 40 of 42 FRs fully covered. FR41-FR42 (parallel execution) explicitly deferred to post-MVP.

| FR Group | Status |
|----------|--------|
| FR1-FR6 (Intake & Routing) | Covered |
| FR7-FR15 (Full Method Pipeline) | Covered |
| FR16-FR17 (Quick Flow) | Covered |
| FR18-FR22 (Execution Architecture) | Covered |
| FR23-FR27 (Failure Recovery) | Covered |
| FR28-FR30 (Checkpoint Mode) | Covered |
| FR31-FR32 (Party Mode) | Covered |
| FR33-FR37 (Git & Artifacts) | Covered |
| FR38-FR40 (Status Reporting) | Covered |
| FR41-FR42 (Parallel Execution) | Deferred (post-MVP) |

**Non-Functional Requirements:** All 9 NFRs addressed architecturally (atomic writes, crash detection, state as source of truth, Claude Code compatibility, loose BMAD coupling). PRD validation report notes NFRs lack measurable metrics -- that is a PRD-level issue, not an architecture gap.

### Implementation Readiness Validation

**Decision Completeness:** All critical decisions documented with rationale. No external dependency versions to track. Concrete examples provided for state schema, atomic write pattern, template format, and naming conventions.

**Structure Completeness:** Full directory tree specified. Checked-in vs runtime files clearly separated. All three architectural boundaries defined with communication contracts.

**Pattern Completeness:** Naming, process, enforcement, and anti-pattern rules all documented. Verification pattern specified as mandatory for every stage.

### Gap Analysis Results

**Critical Gaps:** None.

**Important Gaps Identified and Resolved:**

1. **Story loop population (resolved):** After the `epics-stories` stage completes, the orchestrator agent parses the produced epic files, discovers all stories within them, and builds the `storyLoop` structure in the state file. This is an orchestrator agent responsibility executed between the `epics-stories` and `sprint-planning` stages.

2. **Slash command to loop script handoff (resolved):** The slash command (`.claude/commands/bmad-orchestrate.md`) creates the initial state file with task description, flags, mode, and routing decision, then instructs the user to run `.bmad-orchestrator/loop.sh` manually. The slash command does not invoke the loop script directly.

**Nice-to-Have Gaps (deferred):**
- Parallel execution strategy (FR41-FR42) -- post-MVP
- Run history tracking -- Phase 2
- Custom workflow injection -- Phase 2

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**
- [x] Critical decisions documented (state schema, loop design, communication pattern)
- [x] Technology preferences established (bash, Python hooks via uv run)
- [x] Integration patterns defined (Task tool launch + resume)
- [x] Reliability considerations addressed (atomic writes, crash detection)

**Implementation Patterns**
- [x] Naming conventions established (YAML, files, bash, stage identifiers)
- [x] Structure patterns defined (template format with verification)
- [x] Process patterns documented (atomic writes, error format, bash standards)
- [x] Enforcement guidelines and anti-patterns listed

**Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete
- [x] Data flow documented end-to-end

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Clean separation of concerns across three boundaries
- Ralph Loop eliminates context window degradation -- the hardest problem in long-running AI pipelines
- Task tool resume enables high-quality sub-agent interaction without compromising the stateless pattern
- Verification pattern catches drift at every stage
- Configurable gates and frozen stage identifiers make the system maintainable
- Task Report provides human understanding of autonomous work

**Areas for Future Enhancement:**
- Parallel execution for independent stages (Phase 2)
- Run history and success rate tracking (Phase 2)
- Custom workflow step injection (Phase 2)
- Measurable NFR metrics (requires PRD revision)

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Use implementation patterns consistently across all components
- Respect project structure and boundaries
- Use frozen stage identifiers -- no aliases or variations
- Every state file write uses atomic temp-then-rename pattern
- Every stage template includes a Verification section

**First Implementation Priority:**
1. Define state file schema as a reference YAML file
2. Implement `loop.sh` with branch safety, agent launch, exit code handling
3. Create orchestrator agent definition (`.claude/agents/bmad-orchestrator.md`)
4. Create slash command (`.claude/commands/bmad-orchestrate.md`)
5. Build first stage template (`stage-prd.md`) and test single-stage execution

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow:** COMPLETED
**Total Steps Completed:** 8
**Date Completed:** 2026-02-03
**Document Location:** `_bmad-output/planning-artifacts/architecture.md`

### Final Architecture Deliverables

**Complete Architecture Document**
- All architectural decisions documented with rationale
- Implementation patterns ensuring AI agent consistency
- Complete project structure with all files and directories
- Requirements to architecture mapping (40/42 FRs covered, 2 deferred)
- Validation confirming coherence and completeness

**Implementation Ready Foundation**
- 12 architectural decisions made (state schema, loop design, communication pattern, routing, Party Mode, templates, artifact validation, file structure, verification, gates, story loop population, slash command handoff)
- 8 implementation patterns defined (naming, template format, error format, atomic writes, bash standards, verification, enforcement, anti-patterns)
- 3 architectural boundaries specified (loop↔agent, agent↔sub-agents, orchestrator↔filesystem)
- 40 functional requirements fully supported

**AI Agent Implementation Guide**
- Technology: bash (loop script), Claude Code agents (orchestrator + sub-agents), Python via uv run (hooks)
- Consistency rules that prevent implementation conflicts
- Project structure with clear boundaries
- Data flow documented end-to-end including Task Report generation

### Quality Assurance Checklist

**Architecture Coherence**
- [x] All decisions work together without conflicts
- [x] Ralph Loop + Task tool resume + state file form coherent execution model
- [x] Patterns support the architectural decisions
- [x] Structure aligns with all choices

**Requirements Coverage**
- [x] 40/42 functional requirements supported (2 deferred to post-MVP)
- [x] All 9 non-functional requirements addressed architecturally
- [x] Cross-cutting concerns handled (state consistency, artifact integrity, mode awareness, error propagation)
- [x] Integration points defined across all three boundaries

**Implementation Readiness**
- [x] Decisions are specific and actionable
- [x] Patterns prevent agent conflicts
- [x] Structure is complete and unambiguous
- [x] Examples provided (state schema, atomic write, template format)

---

**Architecture Status:** READY FOR IMPLEMENTATION

**Next Phase:** Begin implementation using the architectural decisions and patterns documented herein.

**Document Maintenance:** Update this architecture when major technical decisions are made during implementation.

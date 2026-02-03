# Story 2.1: Architecture & Epics-Stories Stage Templates

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to drive the Architecture and Epics & Stories stages autonomously,
so that I get a complete Architecture and Epic breakdown from the PRD without manual intervention.

## Acceptance Criteria

1. **Given** the `stage-architecture.md` template exists in `.bmad-orchestrator/templates/`
   **When** reviewed
   **Then** it contains frontmatter with `stage: architecture`, `agent: bmad-architect`, `command`, `requiredArtifacts: [prd.md]`, `producedArtifacts: [architecture.md]`
   **And** it contains Context Injection, Stage Instructions, and Verification sections

2. **Given** the `stage-epics-stories.md` template exists in `.bmad-orchestrator/templates/`
   **When** reviewed
   **Then** it contains frontmatter with `stage: epics-stories`, `agent: bmad-pm`, `command`, `requiredArtifacts: [prd.md, architecture.md]`, `producedArtifacts: [epics.md]`
   **And** it contains Context Injection, Stage Instructions, and Verification sections

3. **Given** the orchestrator reaches the `architecture` stage
   **When** it loads `stage-architecture.md`
   **Then** it launches the Architect sub-agent via Task tool, passes the task description and references `prd.md` as input, drives the workflow as an expert user, and produces `_bmad-output/planning-artifacts/architecture.md`

4. **Given** a planning stage completes successfully
   **When** the orchestrator runs verification
   **Then** it confirms all `producedArtifacts` exist on disk, validates output aligns with the original task, and updates `state.yaml` atomically

5. **Given** the orchestrator transitions between planning stages
   **When** each stage completes
   **Then** `completedStages` is updated, `currentStage` advances to the next stage in sequence, and the agent exits with code 0

## Tasks / Subtasks

- [x] Task 1: Create `stage-architecture.md` prompt template (AC: #1, #3, #4, #5)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-architecture.md` with YAML frontmatter:
    ```yaml
    ---
    stage: architecture
    agent: bmad-architect
    command: CA
    requiredArtifacts:
      - _bmad-output/planning-artifacts/prd.md
    producedArtifacts:
      - _bmad-output/planning-artifacts/architecture.md
    ---
    ```
  - [x] 1.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` placeholders (bare placeholders, matching stage-prd.md pattern)
  - [x] 1.3: Write `## Stage Instructions` section that tells the orchestrator how to drive the Architect agent's workflow:
    - Launch Architect agent via Task tool
    - Send the `CA` command (Create Architecture) to trigger the architecture workflow
    - Respond to all architecture questions as an expert engineering lead using the task description AND the produced PRD as context
    - Reference `_bmad-output/planning-artifacts/prd.md` as the primary input document the architect should use
    - Use YOLO mode when offered to drive the workflow to completion autonomously
    - Ensure the architecture is saved to `_bmad-output/planning-artifacts/architecture.md`
  - [x] 1.4: Write Failure Recovery subsection covering retry strategies:
    - If architecture not saved: ensure Architect agent completes full workflow including save
    - If content misaligned with PRD: provide more explicit guidance referencing specific PRD sections
    - If readiness feedback is present in failure_context: address specific architectural gaps identified
  - [x] 1.5: Write `## Verification` section with specific checks:
    - Verify `_bmad-output/planning-artifacts/architecture.md` exists on disk
    - Verify architecture content addresses the core PRD requirements
    - Verify architecture contains key sections (decisions, patterns, project structure)
    - Verify architecture could serve as input to the epics-stories stage

- [x] Task 2: Create `stage-epics-stories.md` prompt template (AC: #2, #4, #5)
  - [x] 2.1: Create `.bmad-orchestrator/templates/stage-epics-stories.md` with YAML frontmatter:
    ```yaml
    ---
    stage: epics-stories
    agent: bmad-pm
    command: CE
    requiredArtifacts:
      - _bmad-output/planning-artifacts/prd.md
      - _bmad-output/planning-artifacts/architecture.md
    producedArtifacts:
      - _bmad-output/planning-artifacts/epics.md
    ---
    ```
  - [x] 2.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` placeholders (bare placeholders, matching stage-prd.md pattern)
  - [x] 2.3: Write `## Stage Instructions` section that tells the orchestrator how to drive the PM agent's Epics & Stories workflow:
    - Launch PM agent via Task tool
    - Send the `CE` command (Create Epics & Stories) to trigger the workflow
    - Respond to all workflow questions as an expert product manager
    - Reference both `_bmad-output/planning-artifacts/prd.md` and `_bmad-output/planning-artifacts/architecture.md` as input documents
    - Use YOLO mode when offered to drive the workflow to completion autonomously
    - Ensure epics are saved to `_bmad-output/planning-artifacts/epics.md`
  - [x] 2.4: Write Failure Recovery subsection covering retry strategies:
    - If epics file not saved: ensure PM agent completes full workflow including save
    - If stories don't cover all PRD requirements: guide PM to review FR coverage map
    - If architectural constraints missing from stories: explicitly reference architecture decisions
  - [x] 2.5: Write `## Verification` section with specific checks:
    - Verify `_bmad-output/planning-artifacts/epics.md` exists on disk
    - Verify epics cover the major feature areas from the PRD
    - Verify stories have acceptance criteria (BDD format)
    - Verify stories reference relevant architectural decisions where applicable
    - Verify the document could serve as input to implementation readiness and sprint planning

- [x] Task 3: Write bats tests for both templates (AC: #1, #2)
  - [x] 3.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-architecture.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-architecture.md`
    - Template has valid YAML frontmatter with `stage: architecture`
    - Template frontmatter contains `agent: bmad-architect`
    - Template frontmatter contains `requiredArtifacts` with `prd.md`
    - Template frontmatter contains `producedArtifacts` with `architecture.md`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 3.2: Add tests to `tests/orchestrator-agent.bats` validating `stage-epics-stories.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-epics-stories.md`
    - Template has valid YAML frontmatter with `stage: epics-stories`
    - Template frontmatter contains `agent: bmad-pm`
    - Template frontmatter contains `requiredArtifacts` with `prd.md` AND `architecture.md`
    - Template frontmatter contains `producedArtifacts` with `epics.md`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 3.3: Verify all existing tests still pass (zero regressions on all 67 existing tests)

- [x] Task 4: Verify orchestrator agent handles stage transitions correctly (AC: #5) -- MANUAL
  - [x] 4.1: After Tasks 1-3, verify the orchestrator can load `stage-architecture.md` when `currentStage: architecture`
  - [x] 4.2: Verify stage sequencing: after architecture completes, `currentStage` advances to `epics-stories`; after epics-stories completes, `currentStage` advances to `readiness`

## Dev Notes

### Architecture Compliance

**This story creates exactly 2 new files and modifies 1 existing file:**
- `.bmad-orchestrator/templates/stage-architecture.md` -- **NEW** -- Architecture stage prompt template
- `.bmad-orchestrator/templates/stage-epics-stories.md` -- **NEW** -- Epics & Stories stage prompt template
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add template-specific tests for both new templates

**This is NOT a code story.** Like story 1-5, these are markdown prompt templates that the orchestrator agent reads and uses to drive sub-agents. No bash scripting or code changes are needed. The "implementation" is writing well-structured prompt templates following the exact format established by `stage-prd.md`.

### Prompt Template Format (from Architecture -- MUST follow exactly)

Every template file MUST follow this exact structure (established in story 1-5):

```markdown
---
stage: {frozen-stage-identifier}
agent: {agent-name}
command: {command-trigger}
requiredArtifacts:
  - path/to/required/artifact
producedArtifacts:
  - path/to/produced/artifact
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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). This was corrected during story 1-5 code review.

### How the Orchestrator Uses These Templates

Per `.claude/agents/bmad-orchestrator.md` Sections 3-5 (established in stories 1-3 and 1-4):

1. **Section 3 (Template Loading):** Orchestrator reads `stage-{currentStage}.md`, parses frontmatter to get `agent`, `command`, `requiredArtifacts`, `producedArtifacts`. Pre-validates that all required artifacts exist on disk before launching sub-agent.

2. **Section 4 (Sub-Agent Interaction):** Orchestrator launches the specified agent via Task tool. Passes the Stage Instructions content along with `task` from state.yaml and any `failure_context`. Acts as expert human user -- selects menu options, answers workflow questions.

3. **Section 5 (Verification):** After sub-agent completes, orchestrator checks all `producedArtifacts` exist on disk, verifies goal alignment with original task, and checks quality gate criteria.

### Stage Sequencing (Full Method Pipeline)

The Full Method pipeline stages in order:
```
prd → architecture → epics-stories → readiness → sprint-planning → create-story → dev-story → code-review
```

After `architecture` completes: `completedStages: [prd, architecture]`, `currentStage: epics-stories`
After `epics-stories` completes: `completedStages: [prd, architecture, epics-stories]`, `currentStage: readiness`

### Agent Command Triggers

**Architecture Stage:**
- Agent: `bmad-architect` (the BMAD Architect agent)
- Command: `CA` (Create Architecture workflow)
- The architect expects PRD as input and produces `architecture.md`
- The orchestrator acts as an expert engineering lead, providing technical context from the task description and PRD

**Epics & Stories Stage:**
- Agent: `bmad-pm` (the BMAD PM agent)
- Command: `CE` (Create Epics & Stories workflow)
- The PM expects PRD + Architecture as input and produces epic files
- The orchestrator acts as an expert product manager, guiding story decomposition
- **Note:** The PM agent produces `epics.md` in the planning-artifacts folder; the exact filename may vary by BMAD version. Verification should check for `*epic*` pattern if exact path fails.

### Required Artifacts Pre-Validation

The orchestrator's Section 3 (Template Loading) pre-validates `requiredArtifacts` before launching a sub-agent:

- `stage-architecture.md` requires: `_bmad-output/planning-artifacts/prd.md` (produced by PRD stage)
- `stage-epics-stories.md` requires: `_bmad-output/planning-artifacts/prd.md` AND `_bmad-output/planning-artifacts/architecture.md` (produced by PRD and Architecture stages)

If any required artifact is missing, the orchestrator enters failure handling without launching the sub-agent. This ensures the artifact chain integrity defined in the architecture.

### Previous Story Intelligence

**Story 1.5 (PRD Stage Template):**
- Established the exact template format: frontmatter + Context Injection + Stage Instructions + Verification
- Context Injection uses bare placeholders (corrected during code review)
- Stage Instructions organized as: Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery
- Verification organized as: Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome
- 12 bats tests added for the PRD template (Template 1.5-1 through 1.5-12)
- Test pattern: check file existence, parse frontmatter fields, verify sections exist, verify placeholders exist
- 67 total tests passing after story 1-5

**Story 1.4 (Task Routing Logic):**
- Routing sets `currentStage` to first stage of chosen track (`prd` for full, `quick-spec` for quick)
- After routing, execution continues to Section 3 (Template Loading) in the SAME Ralph Loop iteration
- Routing + first stage = one iteration; subsequent stages = one iteration each

**Story 1.3 (Orchestrator Agent):**
- Section 3 documents template loading: read `stage-{currentStage}.md`, parse frontmatter, pre-validate artifacts
- Section 4.1: launching sub-agents via Task tool
- Section 4.2: acting as expert human user
- Section 7: state update protocol with atomic writes

### Git Intelligence

Recent commits follow the pattern: `feat: <description> (story X-Y)`

Files changed in each story:
- Story 1-5: `stage-prd.md` (NEW), `orchestrator-agent.bats` (MODIFIED), `sprint-status.yaml` (MODIFIED)
- Story 1-4: `bmad-orchestrator.md` (MODIFIED), `orchestrator-agent.bats` (MODIFIED)
- Story 1-3: `bmad-orchestrator.md` (NEW), `orchestrator-agent.bats` (MODIFIED)
- Story 1-2: `loop.sh` (NEW), `orchestrator-agent.bats` (NEW)

Established test naming: `@test "Template X.Y-N: description"` (e.g., `@test "Template 1.5-1: stage-prd template exists"`)

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-architecture.md` -- NEW file in existing templates directory
- `.bmad-orchestrator/templates/stage-epics-stories.md` -- NEW file in existing templates directory
- `tests/orchestrator-agent.bats` -- MODIFIED, add tests for both new templates
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifiers are frozen: `architecture` and `epics-stories` (note the hyphen in `epics-stories`)

### Anti-Patterns to Avoid

- Using wrong stage identifiers (must be `architecture` and `epics-stories` exactly -- from the frozen list)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` -- camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare, per story 1-5 code review)
- Skipping `{{failure_context}}` or `{{mode_instructions}}` placeholders -- retries and checkpoint mode depend on these
- Creating additional files beyond the two templates and test modifications
- Modifying `bmad-orchestrator.md` -- the agent definition already handles template loading for any stage
- Modifying `loop.sh` -- the loop script is not touched by this story
- Modifying the slash command -- it already handles state initialization correctly
- Using wrong commands: verify the actual BMAD agent command triggers before writing templates

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1] -- Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] -- Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] -- Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] -- Post-stage verification steps (artifact check -> goal alignment -> quality gate -> pass/fail)
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] -- Task tool resume mechanism
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- templates/ directory location
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] -- `architecture`, `epics-stories`
- [Source: _bmad-output/project-context.md#Prompt Template Rules] -- Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] -- Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Orchestrator never writes BMAD artifacts directly
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] -- Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] -- Sub-agent interaction protocol
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] -- Verification (NEVER SKIP)
- [Source: .bmad-orchestrator/templates/stage-prd.md] -- Reference template (exact format to follow)
- [Source: _bmad-output/implementation-artifacts/1-5-first-stage-template-end-to-end-proof.md] -- Previous story with template creation patterns and learnings
- [Source: tests/orchestrator-agent.bats] -- 67 existing tests, test naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

### Completion Notes List

- Created `stage-architecture.md` following exact format from `stage-prd.md`: frontmatter (stage/agent/command/requiredArtifacts/producedArtifacts), bare Context Injection placeholders, Stage Instructions with Launch Sequence/Interaction Protocol/Output Requirements/Failure Recovery, and Verification with Artifact Existence/Content Alignment/Quality Baseline/Verification Outcome
- Created `stage-epics-stories.md` following same format: requires both `prd.md` and `architecture.md` as inputs, produces `epics.md`, drives `bmad-pm` agent with `CE` command
- Added 22 bats tests (Template 2.1-1 through 2.1-22): 11 for architecture template, 11 for epics-stories template
- All 89 tests pass (67 existing + 22 new), zero regressions
- Task 4 (MANUAL): Verified template filenames match `stage-{currentStage}.md` pattern per orchestrator Section 3; pipeline sequence `prd -> architecture -> epics-stories -> readiness` confirmed in agent definition
- [Code Review] Added 2 missing `command` field tests (Template 2.1-4: `command: CA`, Template 2.1-16: `command: CE`) — matching story 1-5 pattern. Renumbered to 2.1-1 through 2.1-24 (12 per template). Fixed "BDD format preferred" → "BDD format" in epics-stories Verification. All 91 tests pass (67 existing + 24 new).

### Change Log

- 2026-02-03: Implemented story 2-1 - created architecture and epics-stories stage templates with 22 bats tests
- 2026-02-03: Code review fixes — added command field tests, fixed BDD verification wording, renumbered tests (24 total)

### File List

- `.bmad-orchestrator/templates/stage-architecture.md` -- NEW -- Architecture stage prompt template
- `.bmad-orchestrator/templates/stage-epics-stories.md` -- NEW -- Epics & Stories stage prompt template (code review: fixed "preferred" wording)
- `tests/orchestrator-agent.bats` -- MODIFIED -- Added 24 tests for both new templates (Template 2.1-1 through 2.1-24, code review: added command tests)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- MODIFIED -- Story status updated
- `_bmad-output/implementation-artifacts/2-1-architecture-epics-stories-stage-templates.md` -- MODIFIED -- Story file updated

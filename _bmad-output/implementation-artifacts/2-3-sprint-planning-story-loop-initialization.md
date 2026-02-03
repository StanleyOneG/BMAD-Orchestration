# Story 2.3: Sprint Planning & Story Loop Initialization

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to set up sprint planning and discover all stories automatically,
so that the implementation phase knows exactly which epics and stories to execute and in what order.

## Acceptance Criteria

1. **Given** the `epics-stories` stage has completed and epic files exist on disk
   **When** the orchestrator prepares for the implementation phase
   **Then** it parses the produced epic files, discovers all epics and stories within them, and builds the `storyLoop` structure in `state.yaml`

2. **Given** the `storyLoop` structure is built
   **When** reviewing `state.yaml`
   **Then** each epic has an `id`, `status: pending`, and a `stories` array with each story having an `id` and `status: pending`

3. **Given** the `stage-sprint-planning.md` template exists
   **When** the orchestrator reaches the `sprint-planning` stage
   **Then** it launches the SM sub-agent via Task tool, passes the epics as input, drives sprint planning, and produces `_bmad-output/implementation-artifacts/sprint-status.yaml`

4. **Given** sprint planning completes
   **When** the orchestrator runs verification
   **Then** it confirms `sprint-status.yaml` exists on disk and updates `state.yaml` atomically

5. **Given** the sprint planning stage template follows the Architecture's prompt template format
   **When** reviewed
   **Then** it contains frontmatter with `stage: sprint-planning`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
   **And** it contains `## Context Injection` with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}` bare placeholders
   **And** `## Stage Instructions` with Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery subsections
   **And** `## Verification` with Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome subsections

## Tasks / Subtasks

- [x] Task 1: Add storyLoop population logic to orchestrator agent definition (AC: #1, #2)
  - [x] 1.1: In `.claude/agents/bmad-orchestrator.md`, add a new section (or subsection under Section 2) for **storyLoop population** that executes between the `epics-stories` and `sprint-planning` stages
  - [x] 1.2: Logic must:
    - Detect when `currentStage` is `sprint-planning` and `storyLoop` is `null` (or empty)
    - Read the produced epic files from disk (glob `_bmad-output/planning-artifacts/*epic*.md`)
    - Parse all epics and stories from the document structure (## Epic N → ### Story N.M)
    - Build the `storyLoop` structure in state.yaml with format:
      ```yaml
      storyLoop:
        epics:
          - id: "epic-01"
            status: "pending"
            stories:
              - id: "story-01-slug"
                status: "pending"
              - id: "story-02-slug"
                status: "pending"
          - id: "epic-02"
            status: "pending"
            stories:
              - id: "story-01-slug"
                status: "pending"
      ```
    - Write the updated state atomically (temp-then-rename pattern)
  - [x] 1.3: Ensure the storyLoop population happens BEFORE the sprint-planning sub-agent is launched (it's a pre-step, not part of the template interaction)
  - [x] 1.4: Handle edge case: if storyLoop is already populated (e.g., resume scenario), skip population and proceed directly to sprint-planning template

- [x] Task 2: Create `stage-sprint-planning.md` prompt template (AC: #3, #4, #5)
  - [x] 2.1: Create `.bmad-orchestrator/templates/stage-sprint-planning.md` with YAML frontmatter:
    ```yaml
    ---
    stage: sprint-planning
    agent: bmad-sm
    command: SP
    requiredArtifacts:
      - _bmad-output/planning-artifacts/epics.md
    producedArtifacts:
      - _bmad-output/implementation-artifacts/sprint-status.yaml
    ---
    ```
  - [x] 2.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders (no markdown wrapping — per story 1-5 code review learning)
  - [x] 2.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-sm` agent via Task tool, send `SP` command to trigger Sprint Planning workflow
    - **Interaction Protocol:** Act as expert engineering lead. The SM agent will analyze the epic files and generate/regenerate `sprint-status.yaml`. Answer questions about priority order, epic sequencing, and story dependencies. Reference the epics file and architecture for context. Use YOLO mode when offered.
    - **Output Requirements:** Sprint status saved to `_bmad-output/implementation-artifacts/sprint-status.yaml`. Must contain all epics and stories extracted from epic files with status tracking.
    - **Failure Recovery:** If sprint-status not saved: ensure workflow completes including save. If previous failure context present: address specific issues. If stale data: regenerate from current epic files.
  - [x] 2.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify `_bmad-output/implementation-artifacts/sprint-status.yaml` exists on disk
    - **Content Alignment:** Read the sprint status file and verify it contains all epics and stories from the epic files. Verify each epic has a status field. Verify each story has a status field.
    - **Quality Baseline:** Verify the sprint status is substantive (not empty/stub), contains proper YAML structure, and could serve as a tracking file for the story loop implementation phase
    - **Verification Outcome:** PASS: Sprint status exists, contains all epics/stories from epic files, has valid structure. FAIL: File missing, empty, or missing epics/stories that exist in the epic files.

- [x] Task 3: Write bats tests for sprint-planning template and storyLoop logic (AC: #1, #2, #5)
  - [x] 3.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-sprint-planning.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-sprint-planning.md`
    - Template has valid YAML frontmatter with `stage: sprint-planning`
    - Template frontmatter contains `agent: bmad-sm`
    - Template frontmatter contains `command: SP`
    - Template frontmatter contains `requiredArtifacts` with `epics.md`
    - Template frontmatter contains `producedArtifacts` with `sprint-status.yaml`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 3.2: Add tests validating storyLoop population logic in orchestrator agent:
    - Agent definition mentions `storyLoop` population/building
    - Agent definition handles `storyLoop` being `null` or empty
    - Agent definition references parsing epic files for storyLoop construction
    - Agent definition specifies atomic write after storyLoop population
  - [x] 3.3: Use test naming pattern: `@test "Template 2.3-N: description"` for template tests, `@test "StoryLoop 2.3-N: description"` for storyLoop logic tests
  - [x] 3.4: Verify all existing tests still pass (zero regressions on all 106 existing tests)

- [x] Task 4: Verify orchestrator handles sprint-planning stage transitions correctly (AC: #4) -- MANUAL
  - [x] 4.1: Verify the orchestrator can load `stage-sprint-planning.md` when `currentStage: sprint-planning`
  - [x] 4.2: Verify stage sequencing: after sprint-planning completes, `currentStage` advances to `create-story`
  - [x] 4.3: Verify storyLoop population triggers when transitioning from `epics-stories` → `sprint-planning` with null storyLoop

## Dev Notes

### Architecture Compliance

**This story creates 1 new file and modifies 2 existing files:**
- `.bmad-orchestrator/templates/stage-sprint-planning.md` -- **NEW** -- Sprint Planning stage prompt template
- `.claude/agents/bmad-orchestrator.md` -- **MODIFIED** -- Add storyLoop population logic
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add template + storyLoop logic tests

**This story has TWO components** — unlike previous template-only stories (1-5, 2-1, 2-2), this one also modifies the orchestrator agent to add storyLoop population logic. The agent definition already has storyLoop ITERATION logic (Section 2), but it does NOT yet have the logic to POPULATE the storyLoop structure from epic files. This is a critical gap that this story fills.

### What Makes Sprint Planning UNIQUE vs Other Templates

This is the **transition point between planning and implementation phases.** It has two distinct responsibilities:

1. **storyLoop Population (orchestrator agent logic):** Before launching the sprint-planning sub-agent, the orchestrator must parse epic files and build the `storyLoop` structure in state.yaml. This is a pre-step that happens INSIDE the orchestrator, NOT via a sub-agent.

2. **Sprint Planning Template (sub-agent interaction):** Standard template-driven sub-agent interaction with the SM agent.

The architecture explicitly calls this out: *"After the `epics-stories` stage completes, the orchestrator agent parses the produced epic files, discovers all stories within them, and builds the `storyLoop` structure in the state file. This is an orchestrator agent responsibility executed between the `epics-stories` and `sprint-planning` stages."*

### storyLoop Population — Implementation Detail

**When:** The orchestrator reaches `currentStage: sprint-planning` and `storyLoop` is null/empty.

**How:**
1. Glob for epic files: `_bmad-output/planning-artifacts/*epic*.md`
2. Read the epic files and parse the structure
3. Extract all `## Epic N: Title` sections and their `### Story N.M: Title` subsections
4. Build the storyLoop YAML structure:
   ```yaml
   storyLoop:
     epics:
       - id: "epic-01"
         status: "pending"
         stories:
           - id: "story-01-slug"
             status: "pending"
           - id: "story-02-slug"
             status: "pending"
   ```
5. Write updated state atomically

**Where in the agent definition:** This should be added as a new subsection within or after Section 2 (Pipeline Stage Sequences), or as part of Section 3 (Template Loading) as a pre-step before loading `stage-sprint-planning.md`. The key: it must execute BEFORE the sub-agent is launched.

**Resume handling:** If storyLoop is already populated (resume scenario), skip population and proceed directly to template loading.

### Prompt Template Format (from Architecture — MUST follow exactly)

Every template file MUST follow this exact structure (established in story 1-5, used in stories 2-1, 2-2):

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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). This was corrected during story 1-5 code review and confirmed in stories 2-1 and 2-2.

### How the Orchestrator Uses This Template

Per `.claude/agents/bmad-orchestrator.md` Sections 3-5:

1. **Section 3 (Template Loading):** Orchestrator reads `stage-sprint-planning.md`, parses frontmatter to get `agent: bmad-sm`, `command: SP`, and `requiredArtifacts: [epics.md]`. Pre-validates that the epics file exists on disk.

2. **storyLoop Population (NEW for this story):** BEFORE launching the sub-agent, the orchestrator checks if `storyLoop` is null. If so, it reads the epic files, parses all epics and stories, and builds the storyLoop structure in state.yaml via atomic write.

3. **Section 4 (Sub-Agent Interaction):** Orchestrator launches `bmad-sm` via Task tool. Sends `SP` command. Acts as expert user — the SM agent will analyze epics and generate sprint-status.yaml. Uses YOLO mode when offered.

4. **Section 5 (Verification):** After sub-agent completes, orchestrator checks `sprint-status.yaml` exists on disk, validates it contains all expected epics/stories, and updates state.yaml atomically.

### Agent & Command Selection

**Agent:** `bmad-sm` -- the SM (Scrum Master) agent owns sprint planning. The SM agent has the `SP` command for Sprint Planning.

**Command:** `SP` -- triggers the Sprint Planning workflow which generates/regenerates `sprint-status.yaml` from epic files.

### Stage Sequencing (Full Method Pipeline)

```
prd → architecture → epics-stories → readiness → sprint-planning → create-story → dev-story → code-review
```

After `readiness` completes: `completedStages: [prd, architecture, epics-stories, readiness]`, `currentStage: sprint-planning`
After `sprint-planning` completes: `completedStages: [prd, architecture, epics-stories, readiness, sprint-planning]`, `currentStage: create-story`

### Previous Story Intelligence

**Story 2.2 (Implementation Readiness Stage Template):**
- Created 1 template + 15 bats tests
- Test naming: `@test "Template 2.2-N: description"`
- 103 → 104 tests (based on final count — story 2-2 notes say 103/103 but may have had the count from before 2.2-13 through 2.2-15 extras)
- Template follows exact format from stage-prd.md
- First validation stage template with PASS/CONCERNS/FAIL quality gate
- Code review learning: include `command` field test from the start
- Context Injection bare placeholders confirmed
- Stage Instructions organized as: Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery
- Verification organized as: Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome

**Story 2.1 (Architecture & Epics-Stories Templates):**
- Created 2 templates + 24 bats tests
- Key learning: bare placeholders, include command tests from start

### Git Intelligence

Recent commits follow the pattern: `feat: <description> (story X-Y)`

Files changed in story 2-2: `stage-readiness.md` (NEW), `orchestrator-agent.bats` (MODIFIED), `sprint-status.yaml` (MODIFIED)
Files changed in story 2-1: `stage-architecture.md` (NEW), `stage-epics-stories.md` (NEW), `orchestrator-agent.bats` (MODIFIED)

### Test Pattern (from stories 2-1, 2-2 — follow exactly)

**Template tests (12 per template):**
1. Template file exists
2. Valid YAML frontmatter with correct stage identifier
3. Frontmatter contains correct agent
4. Frontmatter contains correct command
5. Frontmatter contains requiredArtifacts with expected artifacts
6. Frontmatter contains producedArtifacts with expected artifacts
7. Contains `## Context Injection` section
8. Contains `## Stage Instructions` section
9. Contains `## Verification` section
10. Contains `{{task_description}}` placeholder
11. Contains `{{failure_context}}` placeholder
12. Contains `{{mode_instructions}}` placeholder

**storyLoop logic tests (additional — NEW for this story):**
- Agent mentions storyLoop population/building
- Agent handles null/empty storyLoop
- Agent references epic file parsing
- Agent specifies atomic write after population

### Anti-Patterns to Avoid

- Using wrong stage identifier (must be `sprint-planning` exactly — from the frozen list)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` — camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare, per story 1-5 code review)
- Forgetting to test the `command: SP` field (caught in story 2-1 code review)
- Confusing storyLoop POPULATION (new, this story) with storyLoop ITERATION (already exists in Section 2)
- Populating storyLoop AFTER launching the sub-agent instead of BEFORE
- Direct writes to state.yaml without temp-then-rename atomic pattern
- Modifying `loop.sh` — the loop script is not touched by this story
- Putting storyLoop population logic in the template instead of the orchestrator agent

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-sprint-planning.md` -- NEW file in existing templates directory
- `.claude/agents/bmad-orchestrator.md` -- MODIFIED, add storyLoop population logic
- `tests/orchestrator-agent.bats` -- MODIFIED, add tests for template + storyLoop logic
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifier is frozen: `sprint-planning`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3] -- Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] -- storyLoop structure definition with example YAML
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] -- Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] -- Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Gap Analysis Results] -- storyLoop population gap (resolved) — "After the epics-stories stage completes, the orchestrator agent parses the produced epic files..."
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] -- Post-stage verification steps
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- templates/ directory location, stage-sprint-planning.md listed
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] -- `sprint-planning`
- [Source: _bmad-output/project-context.md#Prompt Template Rules] -- Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] -- Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Orchestrator never writes BMAD artifacts directly
- [Source: _bmad-output/project-context.md#State File Rules] -- Atomic temp-then-rename pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 2] -- Pipeline Stage Sequences, story loop iteration logic (already exists)
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] -- Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] -- Sub-agent interaction protocol
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] -- Verification (NEVER SKIP)
- [Source: .claude/agents/bmad-orchestrator.md#Section 7] -- State Update Protocol with atomic write
- [Source: .bmad-orchestrator/templates/stage-readiness.md] -- Most recent reference template (exact format to follow)
- [Source: .bmad-orchestrator/templates/stage-prd.md] -- Original reference template
- [Source: _bmad-output/implementation-artifacts/2-2-implementation-readiness-stage-template.md] -- Previous story with template creation patterns and learnings
- [Source: tests/orchestrator-agent.bats] -- 104 existing tests, test naming patterns established
- [Source: _bmad-output/planning-artifacts/prd.md#FR11] -- "Orchestrator can execute Sprint Planning using the epics"
- [Source: _bmad-output/planning-artifacts/prd.md#FR15] -- "Orchestrator can loop through all epics and all stories within each epic automatically"

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None — clean implementation with no failures.

### Completion Notes List

- Task 1: Added "storyLoop Population (Pre-Step Before Sprint Planning)" subsection to orchestrator agent Section 2. Covers trigger condition (currentStage == sprint-planning AND storyLoop null/empty), skip condition (resume), epic file globbing/parsing, storyLoop YAML structure building, and atomic state write.
- Task 2: Created `stage-sprint-planning.md` template following exact format from previous templates. Frontmatter: stage/agent/command/requiredArtifacts/producedArtifacts. Context Injection with bare placeholders. Stage Instructions with Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery. Verification with Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome.
- Task 3: Added 19 new bats tests (12 template + 7 storyLoop logic). All 125 tests pass (106 existing + 19 new). Zero regressions. Test naming: `Template 2.3-N` and `StoryLoop 2.3-N`.
- Task 4: Manual verification confirmed template loading pattern resolves `stage-sprint-planning.md`, pipeline sequence defines `sprint-planning` → `create-story`, and storyLoop population subsection triggers on null storyLoop.

### Change Log

- Story 2.3 implementation complete (Date: 2026-02-03)
- Code review fixes applied (Date: 2026-02-03): Added slugification rules to orchestrator storyLoop population, added architecture.md to sprint-planning template requiredArtifacts, added 3 structural storyLoop tests (ordering + co-location + slugification), fixed File List to include sprint-status.yaml, corrected test baseline count from 104 to 106

### File List

- `.bmad-orchestrator/templates/stage-sprint-planning.md` — **NEW** — Sprint Planning stage prompt template
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Added storyLoop population subsection in Section 2 with slugification rules
- `tests/orchestrator-agent.bats` — **MODIFIED** — Added 19 new tests (Template 2.3-1 through 2.3-12, StoryLoop 2.3-1 through 2.3-7)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — **MODIFIED** — Sprint status updated for story 2-3

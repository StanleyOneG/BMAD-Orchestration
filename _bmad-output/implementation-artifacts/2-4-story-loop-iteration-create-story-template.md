# Story 2.4: Story Loop Iteration & Create Story Template

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to iterate through every story in every epic and create detailed story files,
so that the implementation phase has a clear execution order and each story is fully specified before development begins.

## Acceptance Criteria

1. **Given** `state.yaml` has a populated `storyLoop` with epics and stories
   **When** the orchestrator enters the story execution phase
   **Then** it processes stories sequentially: first story of first epic, then second story, and so on through all epics

2. **Given** the `stage-create-story.md` template exists
   **When** the orchestrator reaches a story with `status: pending`
   **Then** it launches the SM sub-agent to create the detailed story file, updates the story's `status` to `created` and `phase` to `create-story`

3. **Given** the create-story template follows the Architecture's prompt template format
   **When** reviewed
   **Then** it contains frontmatter with `stage: create-story`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
   **And** it contains `## Context Injection` with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}` bare placeholders
   **And** `## Stage Instructions` with Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery subsections
   **And** `## Verification` with Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome subsections

4. **Given** a story file is created successfully
   **When** the orchestrator runs verification
   **Then** it confirms the story file exists on disk, validates it contains acceptance criteria, and updates `state.yaml` atomically

5. **Given** all stories in an epic are completed
   **When** the orchestrator checks the epic
   **Then** the epic's `status` is set to `completed` and the orchestrator moves to the next epic

6. **Given** all epics and all stories are completed
   **When** the orchestrator checks the pipeline
   **Then** it recognizes the pipeline is complete and exits with code 2

7. **Given** each story loop iteration
   **When** the orchestrator updates `state.yaml`
   **Then** the update uses atomic write (temp file then rename) and accurately reflects which story is in progress and which phase it's in

## Tasks / Subtasks

- [x] Task 1: Create `stage-create-story.md` prompt template (AC: #2, #3, #4)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-create-story.md` with YAML frontmatter:
    ```yaml
    ---
    stage: create-story
    agent: bmad-sm
    command: CS
    requiredArtifacts:
      - _bmad-output/planning-artifacts/epics.md
      - _bmad-output/implementation-artifacts/sprint-status.yaml
    producedArtifacts:
      - _bmad-output/implementation-artifacts/{{story_key}}.md
    ---
    ```
  - [x] 1.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders (no markdown wrapping -- per established pattern from stories 1-5, 2-1, 2-2, 2-3)
  - [x] 1.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-sm` agent via Task tool, send `CS` command to trigger Create Story workflow
    - **Interaction Protocol:** Act as expert engineering lead. The SM agent will analyze the epics file, identify the target story from `sprint-status.yaml`, and create a comprehensive story file with acceptance criteria, tasks, dev notes, and references. Provide the specific story key (e.g., `2-4-story-loop-iteration-create-story-template`) so the SM agent knows WHICH story to create. Use YOLO mode when offered. Answer questions about technical context by referencing architecture, previous story files, and project-context.md.
    - **Output Requirements:** Story file saved to `_bmad-output/implementation-artifacts/{{story_key}}.md`. Must contain acceptance criteria, tasks/subtasks, dev notes with architecture compliance, and references.
    - **Failure Recovery:** If story file not saved: ensure workflow completes including save. If previous failure context present: address specific issues. If wrong story created: provide correct story key explicitly.
  - [x] 1.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify story file exists at expected path in `_bmad-output/implementation-artifacts/`
    - **Content Alignment:** Read story file, verify it contains the correct story ID, acceptance criteria from the epics file, tasks/subtasks breakdown, and dev notes section
    - **Quality Baseline:** Verify the story file is substantive (not empty/stub), contains actionable tasks, and has architecture compliance notes
    - **Verification Outcome:** PASS: Story file exists, contains correct story with acceptance criteria and tasks. FAIL: File missing, empty, wrong story, or missing acceptance criteria/tasks.

- [x] Task 2: Update orchestrator agent for story loop phase initialization (AC: #1, #2, #7)
  - [x] 2.1: In `.claude/agents/bmad-orchestrator.md` Section 2, add handling for the initial story loop entry. When the orchestrator reaches `currentStage: create-story` and finds a story in `storyLoop` with `status: pending` and NO `phase` field, it should:
    - Default `phase` to `create-story` (the first phase in the story lifecycle)
    - This handles the transition from `sprint-planning` → `create-story` when stories are freshly populated
  - [x] 2.2: Add context injection logic. Before launching the create-story sub-agent, the orchestrator must:
    - Identify the current story from `storyLoop` (first non-completed story in first non-completed epic)
    - Extract the story key (e.g., `2-4-story-loop-iteration-create-story-template`)
    - Inject the story key into the template's `{{story_key}}` placeholder so the SM agent knows which story to create
    - Inject the story key into `producedArtifacts` path resolution for verification
  - [x] 2.3: Add documentation clarifying that `currentStage` remains `create-story` throughout the entire story loop's create-story phases (the storyLoop object tracks which specific story is active, not currentStage)
  - [x] 2.4: Ensure the phase transition logic correctly handles: after create-story verification passes for a story, update that story's `phase` to `dev-story` and `status` to `created`

- [x] Task 3: Write bats tests for create-story template and story loop handling (AC: #1, #2, #3, #7)
  - [x] 3.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-create-story.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-create-story.md`
    - Template has valid YAML frontmatter with `stage: create-story`
    - Template frontmatter contains `agent: bmad-sm`
    - Template frontmatter contains `command: CS`
    - Template frontmatter contains `requiredArtifacts` with `epics.md`
    - Template frontmatter contains `requiredArtifacts` with `sprint-status.yaml`
    - Template frontmatter contains `producedArtifacts`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 3.2: Add tests validating story loop phase handling in orchestrator agent:
    - Agent definition describes default phase assignment for stories with no phase field
    - Agent definition describes story key injection/extraction for create-story stage
    - Agent definition describes phase transition from create-story to dev-story after story creation
    - Agent definition mentions status update to `created` after create-story completes
  - [x] 3.3: Use test naming pattern: `@test "Template 2.4-N: description"` for template tests, `@test "StoryLoop 2.4-N: description"` for story loop logic tests
  - [x] 3.4: Verify all existing tests still pass (zero regressions on all 125 existing tests)

- [x] Task 4: Verify orchestrator handles create-story stage transitions correctly (AC: #1, #5, #6, #7) -- MANUAL
  - [x] 4.1: Verify the orchestrator can load `stage-create-story.md` when `currentStage: create-story`
  - [x] 4.2: Verify story loop iteration: orchestrator picks correct story from storyLoop, launches create-story, then advances phase
  - [x] 4.3: Verify epic completion detection when all stories in an epic reach `completed`
  - [x] 4.4: Verify pipeline completion detection when all epics are `completed` (exit code 2)

## Dev Notes

### Architecture Compliance

**This story creates 1 new file and modifies 2 existing files:**
- `.bmad-orchestrator/templates/stage-create-story.md` -- **NEW** -- Create Story stage prompt template
- `.claude/agents/bmad-orchestrator.md` -- **MODIFIED** -- Add story loop phase initialization and story key injection logic
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add template + story loop phase handling tests

**This story has TWO components** -- similar to story 2-3, this one creates a template AND modifies the orchestrator agent. The agent already has story loop ITERATION logic (Section 2), but it does NOT yet have:
1. Default phase assignment for newly-entered stories (pending → create-story)
2. Story key extraction and injection into the template for the SM sub-agent
3. Phase transition logic after create-story completes (phase → dev-story, status → created)

### What Makes Create Story UNIQUE vs Other Templates

This is the **first story-loop-level template.** Unlike all previous templates (prd, architecture, epics-stories, readiness, sprint-planning) which execute ONCE in the pipeline, create-story executes MULTIPLE TIMES -- once per story in the storyLoop. This has critical implications:

1. **Dynamic artifact paths:** The `producedArtifacts` path contains `{{story_key}}` -- it's different for every iteration. The orchestrator must resolve this per-story.

2. **`currentStage` stays `create-story`:** Unlike linear stages where `currentStage` advances after completion, during the story loop `currentStage` remains `create-story` for ALL stories. The `storyLoop` object tracks which specific story is active.

3. **Phase cycling:** After create-story completes for a story, the orchestrator doesn't advance `currentStage` to `dev-story`. Instead it updates the story's `phase` to `dev-story`. On the next Ralph Loop iteration, it sees `currentStage: dev-story` (or still uses storyLoop to determine the active phase).

4. **Story key injection:** The SM sub-agent needs to know WHICH story to create. The orchestrator must extract the current story's key from storyLoop and pass it to the template.

### Story Loop Phase Lifecycle

Per orchestrator Section 2, the story lifecycle is:

```
Story starts with: status: "pending", phase: undefined
  → create-story completes: status: "created", phase: "dev-story"
  → dev-story completes: status: "implemented", phase: "code-review"
  → code-review completes: status: "completed", phase: null
```

**Initial entry:** When transitioning from sprint-planning to create-story, stories have `status: pending` and no `phase` field. The orchestrator must detect this and default phase to `create-story`.

### Agent & Command Selection

**Agent:** `bmad-sm` -- the SM (Scrum Master) agent owns story creation. The SM agent has the `CS` command for Create Story.

**Command:** `CS` -- triggers the Create Story workflow which analyzes epics, architecture, previous stories, and produces a comprehensive story file.

### Stage Sequencing (Story Loop)

```
sprint-planning → [create-story → dev-story → code-review] × N stories × M epics → pipeline complete
```

Within the story loop, `currentStage` reflects the active story-level stage. The `storyLoop` object tracks which epic and story is being processed.

### Previous Story Intelligence

**Story 2.3 (Sprint Planning & Story Loop Initialization):**
- Created 1 template + modified orchestrator + 19 bats tests
- Test naming: `@test "Template 2.3-N: description"` and `@test "StoryLoop 2.3-N: description"`
- Total tests after 2.3: 125 (106 existing + 19 new)
- Added storyLoop POPULATION logic to orchestrator (pre-step before sprint-planning)
- Slugification rules for story IDs established
- Code review fix: added `architecture.md` to requiredArtifacts, added 3 structural storyLoop tests
- Key learning: storyLoop population is an orchestrator-internal responsibility, NOT a sub-agent task

**Story 2.2 (Implementation Readiness Stage Template):**
- First validation stage with PASS/CONCERNS/FAIL quality gate
- Stage Instructions organized as: Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery
- Verification organized as: Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome

### Git Intelligence

Recent commits follow pattern: `feat: <description> (story X-Y)`

Files changed in story 2-3: `stage-sprint-planning.md` (NEW), `bmad-orchestrator.md` (MODIFIED), `orchestrator-agent.bats` (MODIFIED), `sprint-status.yaml` (MODIFIED)

Most recent commit: `05e3856 feat: add sprint-planning template and storyLoop population (story 2-3)`

### Prompt Template Format (from Architecture -- MUST follow exactly)

Every template file MUST follow this exact structure:

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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). Confirmed in stories 1-5, 2-1, 2-2, 2-3.

### How the Orchestrator Uses This Template

Per `.claude/agents/bmad-orchestrator.md` Sections 2-5:

1. **Section 2 (Story Loop):** Orchestrator finds the current story from `storyLoop.epics[].stories[]` -- first non-completed story in first non-completed epic. Checks its `phase` field to determine which stage template to load.

2. **Story Key Extraction (NEW for this story):** Before loading the template, the orchestrator extracts the story key (e.g., `2-4-story-loop-iteration-create-story-template`) from the storyLoop. This key is injected into the template for both the SM sub-agent interaction AND the `producedArtifacts` path resolution.

3. **Section 3 (Template Loading):** Loads `stage-create-story.md`, parses frontmatter. Pre-validates `requiredArtifacts` exist (epics.md, sprint-status.yaml).

4. **Section 4 (Sub-Agent Interaction):** Launches `bmad-sm` via Task tool. Sends `CS` command with the story key. Acts as expert user -- provides story context from epics, architecture, previous stories.

5. **Section 5 (Verification):** Confirms story file exists at `_bmad-output/implementation-artifacts/{story_key}.md`, validates it has acceptance criteria and tasks, updates storyLoop entry atomically.

### Test Pattern (from stories 2-1, 2-2, 2-3 -- follow exactly)

**Template tests (13 per template):**
1. Template file exists
2. Valid YAML frontmatter with correct stage identifier
3. Frontmatter contains correct agent
4. Frontmatter contains correct command
5. Frontmatter contains requiredArtifacts with expected artifact 1 (epics.md)
6. Frontmatter contains requiredArtifacts with expected artifact 2 (sprint-status.yaml)
7. Frontmatter contains producedArtifacts
8. Contains `## Context Injection` section
9. Contains `## Stage Instructions` section
10. Contains `## Verification` section
11. Contains `{{task_description}}` placeholder
12. Contains `{{failure_context}}` placeholder
13. Contains `{{mode_instructions}}` placeholder

**Story loop phase tests (additional -- NEW for this story):**
- Agent describes default phase assignment for pending stories
- Agent describes story key extraction/injection
- Agent describes phase transition create-story → dev-story
- Agent describes status update to `created`

### Anti-Patterns to Avoid

- Using wrong stage identifier (must be `create-story` exactly -- from the frozen list)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` -- camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare)
- Forgetting to test the `command: CS` field
- Confusing storyLoop POPULATION (story 2-3) with storyLoop ITERATION (this story)
- Hardcoding story keys in the template (must use `{{story_key}}` variable)
- Advancing `currentStage` to `dev-story` after create-story (instead, update story's `phase` field)
- Not handling the initial `phase: undefined` case for pending stories
- Direct writes to state.yaml without temp-then-rename atomic pattern

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-create-story.md` -- NEW file in existing templates directory
- `.claude/agents/bmad-orchestrator.md` -- MODIFIED, add story loop phase initialization and key injection
- `tests/orchestrator-agent.bats` -- MODIFIED, add tests for template + story loop phase handling
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifier is frozen: `create-story`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4] -- Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2] -- Full Pipeline & Quick Flow Orchestration epic context
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] -- storyLoop structure with phase and status fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] -- Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] -- Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] -- `create-story`
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] -- Post-stage verification steps
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- templates/ directory, stage-create-story.md listed
- [Source: _bmad-output/project-context.md#Prompt Template Rules] -- Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] -- Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Orchestrator never writes BMAD artifacts directly
- [Source: _bmad-output/project-context.md#State File Rules] -- Atomic temp-then-rename pattern
- [Source: .claude/agents/bmad-orchestrator.md#Section 2] -- Pipeline Stage Sequences, story loop iteration logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] -- Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] -- Sub-agent interaction protocol
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] -- Verification (NEVER SKIP)
- [Source: .claude/agents/bmad-orchestrator.md#Section 7] -- State Update Protocol with atomic write
- [Source: .bmad-orchestrator/templates/stage-sprint-planning.md] -- Most recent reference template (exact format to follow)
- [Source: .bmad-orchestrator/templates/stage-readiness.md] -- Validation stage reference template
- [Source: _bmad-output/implementation-artifacts/2-3-sprint-planning-story-loop-initialization.md] -- Previous story with template + agent modification patterns
- [Source: tests/orchestrator-agent.bats] -- 125 existing tests, test naming patterns established
- [Source: _bmad-output/planning-artifacts/prd.md#FR12] -- "Orchestrator can execute Create Story for each story in each epic"
- [Source: _bmad-output/planning-artifacts/prd.md#FR15] -- "Orchestrator can loop through all epics and all stories within each epic automatically"

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None required — clean implementation.

### Completion Notes List

- Task 1: Created `stage-create-story.md` template with YAML frontmatter (`stage: create-story`, `agent: bmad-sm`, `command: CS`), Context Injection with bare placeholders, Stage Instructions (Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery), and Verification (Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome). Template uses `{{story_key}}` in producedArtifacts for dynamic path resolution.
- Task 2: Added "Story Loop Phase Initialization" subsection to orchestrator agent Section 2, covering: default phase assignment (`create-story`) for pending stories with no phase field, story key extraction/injection into template `{{story_key}}` placeholder and producedArtifacts resolution, phase transition logic (phase → `dev-story`, status → `created` after create-story verification passes), and documentation that `currentStage` stays at the story-level stage while `storyLoop` tracks the active story.
- Task 3: Added 17 new bats tests (13 template tests + 4 story loop phase tests) following `Template 2.4-N` and `StoryLoop 2.4-N` naming patterns. All 142 tests pass (125 existing + 17 new, zero regressions).
- Task 4 (MANUAL): Verified orchestrator agent definition covers template loading for `create-story` stage, story loop iteration with correct story selection, epic completion detection, and pipeline completion detection — all documented in Section 2 story loop logic.

### File List

- `.bmad-orchestrator/templates/stage-create-story.md` — NEW — Create Story stage prompt template
- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added Story Loop Phase Initialization subsection to Section 2
- `tests/orchestrator-agent.bats` — MODIFIED — Added 17 new tests (Template 2.4-1 through 2.4-13, StoryLoop 2.4-1 through 2.4-4)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated
- `_bmad-output/implementation-artifacts/2-4-story-loop-iteration-create-story-template.md` — MODIFIED — Task checkboxes, Dev Agent Record, File List, Change Log, Status

### Change Log

- 2026-02-03: Implemented story 2-4 — created stage-create-story.md template, added story loop phase initialization logic to orchestrator, added 17 bats tests (142 total, zero regressions)

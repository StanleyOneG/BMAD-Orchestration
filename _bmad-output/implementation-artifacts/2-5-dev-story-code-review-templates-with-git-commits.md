# Story 2.5: Dev Story & Code Review Templates with Git Commits

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to implement each created story and run code review with automatic git commits,
so that every story results in working code, passing tests, reviewed commits, and a completed story file.

## Acceptance Criteria

1. **Given** the `stage-dev-story.md` template exists
   **When** a story has `status: created`
   **Then** it launches the Dev sub-agent to implement the story, updates `phase` to `dev-story`
   **And** the sub-agent makes git commits to the current worktree branch during implementation

2. **Given** the `stage-code-review.md` template exists
   **When** a story has been implemented
   **Then** it launches a review sub-agent to perform code review, updates `phase` to `code-review`

3. **Given** each template follows the Architecture's prompt template format
   **When** reviewed
   **Then** each contains frontmatter with `stage`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
   **And** each contains `## Context Injection` with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}` bare placeholders
   **And** `## Stage Instructions` with Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery subsections
   **And** `## Verification` with Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome subsections

4. **Given** the dev-story template's Verification section
   **When** the orchestrator checks output
   **Then** it verifies code changes exist, tests pass, and git commits were made to the current worktree branch

5. **Given** a story passes code review
   **When** the orchestrator updates state
   **Then** the story's `status` is set to `completed` and the orchestrator moves to the next story

6. **Given** code review returns issues
   **When** the orchestrator reads the review result
   **Then** the stage is treated as a failure and the orchestrator follows the standard retry flow, injecting review feedback into `{{failure_context}}` for the dev-story retry

7. **Given** each story loop iteration
   **When** the orchestrator updates `state.yaml`
   **Then** the update uses atomic write (temp file then rename) and accurately reflects which story is in progress and which phase it's in

## Tasks / Subtasks

- [x] Task 1: Create `stage-dev-story.md` prompt template (AC: #1, #3, #4, #7)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-dev-story.md` with YAML frontmatter:
    ```yaml
    ---
    stage: dev-story
    agent: bmad-dev
    command: DS
    requiredArtifacts:
      - _bmad-output/implementation-artifacts/{{story_key}}.md
      - _bmad-output/planning-artifacts/architecture.md
    producedArtifacts:
      - _bmad-output/implementation-artifacts/{{story_key}}.md
    ---
    ```
  - [x] 1.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders (no markdown wrapping — per established pattern from stories 1-5, 2-1, 2-2, 2-3, 2-4)
  - [x] 1.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-dev` agent via Task tool, send `DS` command to trigger Dev Story workflow
    - **Interaction Protocol:** Act as expert engineering lead. The Dev agent will read the story file, implement all tasks/subtasks, write tests, make git commits. Provide the specific story key so the Dev agent knows WHICH story to implement. When asked about technical decisions, reference architecture.md, project-context.md, and previous story files. Use YOLO mode when offered. Ensure git commits happen on the current worktree branch (FR35). Ensure the Dev agent references project-context.md for bash standards, naming conventions, and anti-patterns
    - **Output Requirements:** Story file updated in-place at `_bmad-output/implementation-artifacts/{{story_key}}.md` with task checkboxes checked, Dev Agent Record populated. Git commits made to current worktree branch. Tests pass
    - **Failure Recovery:** If code review feedback injected via `{{failure_context}}`: address specific issues. If tests don't pass: fix failing tests. If no git commits: ensure commits happen during implementation. If story file not updated: ensure Dev agent marks tasks complete and populates Dev Agent Record
  - [x] 1.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify story file exists at expected path (it should already exist from create-story). Verify git log shows new commits on current branch since stage started
    - **Content Alignment:** Read story file, verify task checkboxes are checked, Dev Agent Record section is populated with agent model, completion notes, and file list
    - **Quality Baseline:** Verify tests pass (run test suite if applicable). Verify git commits were made to current worktree branch. Verify story file is substantive (tasks checked, completion notes present)
    - **Verification Outcome:** PASS: Story file updated with checked tasks and Dev Agent Record, git commits exist, tests pass. FAIL: No git commits, tests failing, story file not updated, or tasks not checked

- [x] Task 2: Create `stage-code-review.md` prompt template (AC: #2, #3, #5, #6)
  - [x] 2.1: Create `.bmad-orchestrator/templates/stage-code-review.md` with YAML frontmatter:
    ```yaml
    ---
    stage: code-review
    agent: bmad-dev
    command: CR
    requiredArtifacts:
      - _bmad-output/implementation-artifacts/{{story_key}}.md
      - _bmad-output/planning-artifacts/architecture.md
    producedArtifacts:
      - _bmad-output/implementation-artifacts/{{story_key}}.md
    ---
    ```
  - [x] 2.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders
  - [x] 2.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch a **NEW, FRESH** `bmad-dev` sub-agent via Task tool — this MUST be a separate Task tool invocation from the dev-story agent, creating a **clean context window** with zero carry-over from the implementation phase. Do NOT resume or reuse the dev-story sub-agent ID. The reviewer must approach the code with no prior assumptions or biases from writing it. Send `CR` command to trigger Code Review workflow
    - **Interaction Protocol:** Act as expert engineering lead. **CRITICAL: The code review agent operates with a clean context window — it has NOT seen the dev-story implementation conversation.** This is by design: the reviewer must independently assess the code from disk artifacts alone, preventing confirmation bias. The code review agent performs an ADVERSARIAL review that finds specific problems: code quality, test coverage, architecture compliance, security, performance. Provide the specific story key. Provide the `git diff` of commits made during the dev-story phase so the reviewer can see exactly what changed. When issues are found, the orchestrator should collect the feedback. Use YOLO mode when offered. A different LLM is recommended for fresh perspective but not required by the architecture
    - **Output Requirements:** Code review result captured. If issues found, the specific issues are available for injection into `{{failure_context}}` on dev-story retry. Story file may be updated with review notes
    - **Failure Recovery:** If review stalls: use YOLO mode. If review finds issues: this is NOT a recovery failure — it means dev-story needs to re-run with the review feedback. If review produces no output: ensure the workflow completes with a clear verdict
  - [x] 2.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify story file still exists at expected path
    - **Content Alignment:** Read story file or review output. Determine if code review PASSED or FAILED
    - **Quality Gate Interpretation:** This is a validation stage with a quality gate:
      - **PASS:** Code review found no blocking issues. Story is complete. Set story status to `completed` in storyLoop
      - **CONCERNS:** Code review found minor issues but nothing blocking. Proceed with PASS but log concern details
      - **FAIL:** Code review found blocking issues. Capture the specific issues in the failure error summary. The orchestrator re-routes back to `dev-story` phase for this story (NOT standard upstream re-routing — stays on same story, reverts phase to `dev-story`) with review feedback injected into `{{failure_context}}`
    - **Verification Outcome:** PASS: Review completed with PASS or CONCERNS verdict, story marked completed. FAIL: Review found blocking issues, or review output is missing/empty

- [x] Task 3: Update orchestrator agent for dev-story and code-review phase handling (AC: #1, #2, #5, #6, #7)
  - [x] 3.1: In `.claude/agents/bmad-orchestrator.md` Section 2, add documentation for the dev-story phase transition. After dev-story verification passes for a story:
    - Update the story's `phase` to `code-review`
    - Update the story's `status` to `implemented`
    - Perform atomic state update (Section 7.2)
  - [x] 3.2: Add documentation for code-review phase handling. After code-review verification passes:
    - Update the story's `status` to `completed`
    - Clear the story's `phase` (set to `null` or remove)
    - Perform atomic state update (Section 7.2)
    - Move to next story (or complete epic if all stories done)
  - [x] 3.3: Add documentation for code-review FAILURE re-routing. When code-review fails:
    - Revert the story's `phase` back to `dev-story` (NOT standard upstream re-routing)
    - The story's `status` stays as `implemented`
    - Inject review feedback into `{{failure_context}}` for the dev-story retry
    - This is a special case: failure stays within the same story's phase cycle
  - [x] 3.4: Add documentation clarifying git commit expectations during dev-story. The Dev sub-agent makes git commits during implementation. The orchestrator verifies commits exist but does NOT make commits itself (per Boundary Rules — sub-agents produce artifacts through their own workflows)
  - [x] 3.5: Add documentation clarifying code-review MUST use a fresh Task tool sub-agent with a clean context window. The orchestrator must NOT resume the dev-story sub-agent for code review. Sub-agent IDs are transient (per Section 9) and the code-review agent must approach code cold from disk artifacts and git diffs only, ensuring genuine adversarial review without confirmation bias from the implementation conversation

- [x] Task 4: Write bats tests for dev-story and code-review templates + phase handling (AC: #1, #2, #3, #5, #6, #7)
  - [x] 4.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-dev-story.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-dev-story.md`
    - Template has valid YAML frontmatter with `stage: dev-story`
    - Template frontmatter contains `agent: bmad-dev`
    - Template frontmatter contains `command: DS`
    - Template frontmatter contains `requiredArtifacts` with `{{story_key}}.md`
    - Template frontmatter contains `requiredArtifacts` with `architecture.md`
    - Template frontmatter contains `producedArtifacts`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 4.2: Add tests validating `stage-code-review.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-code-review.md`
    - Template has valid YAML frontmatter with `stage: code-review`
    - Template frontmatter contains `agent: bmad-dev`
    - Template frontmatter contains `command: CR`
    - Template frontmatter contains `requiredArtifacts` with `{{story_key}}.md`
    - Template frontmatter contains `requiredArtifacts` with `architecture.md`
    - Template frontmatter contains `producedArtifacts`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
    - Template contains tri-state quality gate (PASS/CONCERNS/FAIL)
    - Template contains Quality Gate Interpretation section
  - [x] 4.3: Add tests validating phase handling in orchestrator agent:
    - Agent describes phase transition from dev-story to code-review
    - Agent describes status update to `implemented` after dev-story
    - Agent describes status update to `completed` after code-review
    - Agent describes code-review failure re-routing back to dev-story phase
    - Agent describes git commit expectations during dev-story
    - Agent describes code-review requiring fresh/new Task sub-agent with clean context window
  - [x] 4.4: Add test validating code-review template explicitly requires fresh/new sub-agent launch (not resuming dev-story agent):
    - Template Stage Instructions mention fresh/new Task tool invocation or clean context window
  - [x] 4.5: Use test naming pattern: `@test "Template 2.5-N: description"` for template tests, `@test "StoryLoop 2.5-N: description"` for story loop logic tests
  - [x] 4.6: Verify all existing tests still pass (zero regressions on all 142 existing tests)

- [x] Task 5: Verify orchestrator handles dev-story and code-review stage transitions correctly (AC: #1, #2, #5, #6, #7) — MANUAL
  - [x] 5.1: Verify the orchestrator can load `stage-dev-story.md` when `currentStage: dev-story`
  - [x] 5.2: Verify the orchestrator can load `stage-code-review.md` when `currentStage: code-review`
  - [x] 5.3: Verify phase transition: dev-story → code-review (phase update, status to `implemented`)
  - [x] 5.4: Verify phase transition: code-review → completed (status to `completed`, phase cleared)
  - [x] 5.5: Verify code-review failure re-routing: phase reverts to `dev-story` with review feedback injected

## Dev Notes

### Architecture Compliance

**This story creates 2 new files and modifies 2 existing files:**
- `.bmad-orchestrator/templates/stage-dev-story.md` — **NEW** — Dev Story stage prompt template
- `.bmad-orchestrator/templates/stage-code-review.md` — **NEW** — Code Review stage prompt template
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add dev-story and code-review phase handling + git commit documentation
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add template + phase handling tests

**This story creates TWO templates** — the largest template story so far. Both templates are story-loop-level (like `stage-create-story.md` from story 2-4), meaning they execute MULTIPLE TIMES per pipeline run.

### What Makes These Templates UNIQUE

**Dev Story Template (`stage-dev-story.md`):**
- This is the **first template that produces git commits**. FR35 requires "git commits to the current worktree branch during implementation." The Dev sub-agent makes the commits — the orchestrator only verifies they happened
- The produced artifact is the **same file as the input** (story file updated in-place). The Dev agent reads the story file, implements tasks, then updates the same file with completion notes, file list, etc
- Verification must check **both** file content AND git history — checking only the story file is insufficient

**Code Review Template (`stage-code-review.md`):**
- **CRITICAL: Must be launched as a FRESH Task sub-agent with a CLEAN context window.** The orchestrator must create a NEW Task tool invocation — never resume or reuse the dev-story sub-agent. The reviewer must approach the code cold, from disk artifacts only, with zero carry-over from the implementation conversation. This prevents confirmation bias and ensures genuine adversarial review
- This is a **validation stage** (like `stage-readiness.md`) with a tri-state quality gate: PASS / CONCERNS / FAIL
- **Unique failure routing:** When code-review FAILS, it does NOT trigger standard upstream re-routing (going back to a different stage). Instead, it reverts the **same story's** phase back to `dev-story`. The Dev agent re-runs for the same story, with review feedback injected via `{{failure_context}}`
- The produced artifact is again the same story file (possibly updated with review notes)
- A different LLM is **recommended** for fresh perspective but not required by the architecture. However a fresh context window is **mandatory**

### Story Loop Phase Lifecycle (COMPLETE — Adding Dev-Story and Code-Review)

Per orchestrator Section 2, the full story lifecycle:

```
Story starts with: status: "pending", phase: undefined
  → create-story completes: status: "created", phase: "dev-story"     (from story 2-4)
  → dev-story completes:    status: "implemented", phase: "code-review" (THIS STORY)
  → code-review PASS:       status: "completed", phase: null            (THIS STORY)
  → code-review FAIL:       status: "implemented", phase: "dev-story"   (THIS STORY — re-route)
```

### Agent & Command Selection

**Dev Story:**
- **Agent:** `bmad-dev` — the Dev agent owns story implementation
- **Command:** `DS` — triggers the Dev Story workflow which implements tasks, writes tests, makes commits

**Code Review:**
- **Agent:** `bmad-dev` — the Dev agent also owns code review (uses a different command/workflow)
- **Command:** `CR` — triggers the Code Review workflow which performs adversarial review

### Git Commit Expectations (FR35)

- The **Dev sub-agent** makes git commits during implementation, NOT the orchestrator
- The orchestrator boundary rules (Section 9) prohibit direct BMAD artifact creation — this extends to git operations. The orchestrator only **verifies** that commits were made
- Verification: check `git log` for new commits on the current branch since the dev-story stage started
- The current branch is stored in `state.yaml` as `branch: feature/my-branch`

### Code Review Failure Re-routing Pattern

Standard failure handling (Section 6) increments `currentRetries` and re-runs the same stage. Code review failure is **different**:

1. Code review detects issues
2. The orchestrator captures the specific issues as failure context
3. The story's `phase` is reverted to `dev-story` (NOT `code-review` retry)
4. On next Ralph Loop iteration, the orchestrator sees `phase: dev-story` and loads `stage-dev-story.md`
5. The `{{failure_context}}` includes the code review feedback
6. The Dev agent addresses the specific issues
7. After dev-story completes again, phase advances back to `code-review`

This means a story can cycle between dev-story and code-review multiple times until code review passes.

### Previous Story Intelligence

**Story 2.4 (Story Loop Iteration & Create Story Template):**
- Created 1 template + modified orchestrator + 17 bats tests
- Test naming: `@test "Template 2.4-N: description"` and `@test "StoryLoop 2.4-N: description"`
- Total tests after 2.4: 142 (125 existing + 17 new)
- Added story loop Phase Initialization to orchestrator (default phase assignment, key injection, phase transition after create-story)
- Key learning: `currentStage` stays at the story-level stage; `storyLoop` tracks which story is active
- Code review fix from 2.4: added `architecture.md` to requiredArtifacts

**Story 2.2 (Implementation Readiness Stage Template):**
- First validation stage with PASS/CONCERNS/FAIL quality gate
- Has a `### Quality Gate Interpretation` section — `stage-code-review.md` should follow this pattern
- Stage Instructions organized as: Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery
- Verification organized as: Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome

### Git Intelligence

Recent commits follow pattern: `feat: <description> (story X-Y)`

Most recent commit: `4e54013 feat: add create-story template and story loop phase init (story 2-4)`

Files changed in story 2-4: `stage-create-story.md` (NEW), `bmad-orchestrator.md` (MODIFIED), `orchestrator-agent.bats` (MODIFIED), `sprint-status.yaml` (MODIFIED), `2-4-story-loop-iteration-create-story-template.md` (NEW)

### Prompt Template Format (from Architecture — MUST follow exactly)

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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). Confirmed in stories 1-5, 2-1, 2-2, 2-3, 2-4.

### How the Orchestrator Uses These Templates

Per `.claude/agents/bmad-orchestrator.md` Sections 2-5:

1. **Section 2 (Story Loop):** After create-story completes, story has `phase: dev-story`, `status: created`. Orchestrator finds this story, loads `stage-dev-story.md`

2. **Story Key Injection:** Same as create-story — orchestrator extracts story key from storyLoop, injects into template `{{story_key}}` placeholder and `producedArtifacts` path resolution

3. **Section 3 (Template Loading):** Loads `stage-dev-story.md` or `stage-code-review.md`, parses frontmatter. Pre-validates `requiredArtifacts` exist

4. **Section 4 (Sub-Agent Interaction):** Launches `bmad-dev` via Task tool. Sends `DS` or `CR` command. Acts as expert user

5. **Section 5 (Verification):** For dev-story: confirms story file updated, git commits exist, tests pass. For code-review: checks review result (PASS/CONCERNS/FAIL)

### Test Pattern (from stories 2-1, 2-2, 2-3, 2-4 — follow exactly)

**Template tests (13 per template, ~26 total for two templates):**
1. Template file exists
2. Valid YAML frontmatter with correct stage identifier
3. Frontmatter contains correct agent
4. Frontmatter contains correct command
5. Frontmatter contains requiredArtifacts with expected artifact 1 (`{{story_key}}.md`)
6. Frontmatter contains requiredArtifacts with expected artifact 2 (`architecture.md`)
7. Frontmatter contains producedArtifacts
8. Contains `## Context Injection` section
9. Contains `## Stage Instructions` section
10. Contains `## Verification` section
11. Contains `{{task_description}}` placeholder
12. Contains `{{failure_context}}` placeholder
13. Contains `{{mode_instructions}}` placeholder

**Additional code-review-specific tests:**
- Contains tri-state quality gate (PASS/CONCERNS/FAIL)
- Contains Quality Gate Interpretation section

**Story loop phase tests (additional — NEW for this story):**
- Agent describes phase transition from dev-story to code-review
- Agent describes status update to `implemented` after dev-story
- Agent describes status update to `completed` after code-review
- Agent describes code-review failure re-routing back to dev-story
- Agent describes git commit expectations during dev-story
- Agent describes code-review requiring fresh/new Task sub-agent with clean context window

**Code-review template-specific tests:**
- Template explicitly mentions fresh/new sub-agent launch or clean context window

### Anti-Patterns to Avoid

- Using wrong stage identifiers (must be `dev-story` and `code-review` exactly — from the frozen list)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` — camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare)
- Orchestrator making git commits directly (violates boundary rules — sub-agents make commits)
- Treating code-review failure as standard upstream re-routing (it re-routes within the same story's phase cycle)
- Advancing `currentStage` after dev-story or code-review (instead, update story's `phase` and `status` fields)
- Direct writes to state.yaml without temp-then-rename atomic pattern
- Forgetting that code-review is a validation stage with a quality gate (like readiness)
- Hardcoding story keys in templates (must use `{{story_key}}` variable)
- **Reusing the dev-story sub-agent for code review** — code review MUST be a fresh Task tool invocation with a clean context window. Resuming the dev-story agent defeats the purpose of adversarial review
- Providing the code-review agent with the dev-story conversation context (it should only see disk artifacts and git diffs)

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-dev-story.md` — NEW file in existing templates directory
- `.bmad-orchestrator/templates/stage-code-review.md` — NEW file in existing templates directory
- `.claude/agents/bmad-orchestrator.md` — MODIFIED, add dev-story/code-review phase handling and git documentation
- `tests/orchestrator-agent.bats` — MODIFIED, add tests for both templates + phase handling
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifiers are frozen: `dev-story`, `code-review`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2] — Full Pipeline & Quick Flow Orchestration epic context
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4] — Previous story context (create-story template pattern)
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — storyLoop structure with phase and status fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] — Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] — Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] — `dev-story`, `code-review`
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] — Post-stage verification steps (artifact check, goal alignment, quality gate, pass/fail)
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] — templates/ directory, stage-dev-story.md and stage-code-review.md listed
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] — Task tool resume, orchestrator as expert human
- [Source: _bmad-output/project-context.md#Prompt Template Rules] — Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] — Orchestrator never writes BMAD artifacts directly
- [Source: _bmad-output/project-context.md#State File Rules] — Atomic temp-then-rename pattern
- [Source: _bmad-output/project-context.md#Verification Pattern] — Never skip verification after sub-agent completes
- [Source: .claude/agents/bmad-orchestrator.md#Section 2] — Pipeline Stage Sequences, story loop iteration logic, phase transitions
- [Source: .claude/agents/bmad-orchestrator.md#Section 2 Story Loop Phase Initialization] — Default phase assignment, key extraction/injection, phase transition after create-story
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] — Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] — Sub-agent interaction protocol
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] — Verification (NEVER SKIP), quality gate interpretation for validation stages
- [Source: .claude/agents/bmad-orchestrator.md#Section 6] — Failure handling, retry flow
- [Source: .claude/agents/bmad-orchestrator.md#Section 7] — State Update Protocol with atomic write
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] — Boundary Rules (critical)
- [Source: .bmad-orchestrator/templates/stage-create-story.md] — Most recent story-loop template (exact format to follow for dev-story)
- [Source: .bmad-orchestrator/templates/stage-readiness.md] — Validation stage reference template (exact format to follow for code-review quality gate)
- [Source: _bmad-output/implementation-artifacts/2-4-story-loop-iteration-create-story-template.md] — Previous story with template + agent modification patterns, test counts
- [Source: tests/orchestrator-agent.bats] — 142 existing tests, test naming patterns established
- [Source: _bmad-output/planning-artifacts/prd.md#FR13] — "Orchestrator can execute Dev Story for each created story"
- [Source: _bmad-output/planning-artifacts/prd.md#FR14] — "Orchestrator can execute Code Review for each implemented story"
- [Source: _bmad-output/planning-artifacts/prd.md#FR35] — "Orchestrator can make commits to the current worktree branch during implementation stages"

## Dev Agent Record

### Agent Model Used

Claude Opus 4 (claude-opus-4-20250514)

### Debug Log References

None

### Completion Notes List

- Created `stage-dev-story.md` template with YAML frontmatter (stage: dev-story, agent: bmad-dev, command: DS), Context Injection with bare placeholders, Stage Instructions (Launch Sequence, Interaction Protocol with git commit expectations, Output Requirements, Failure Recovery), and Verification (Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome, State Update)
- Created `stage-code-review.md` template with YAML frontmatter (stage: code-review, agent: bmad-dev, command: CR), Context Injection with bare placeholders, Stage Instructions (Launch Sequence requiring fresh/new sub-agent, Interaction Protocol with clean context window mandate, Output Requirements, Failure Recovery), and Verification (Artifact Existence, Content Alignment, Quality Gate Interpretation with tri-state PASS/CONCERNS/FAIL, Verification Outcome, State Update for both pass and fail scenarios)
- Updated `bmad-orchestrator.md` Section 2 with: Phase Transition Dev-Story to Code-Review (status→implemented, phase→code-review), Git Commit Expectations (sub-agent commits, orchestrator verifies), Phase Transition Code-Review to Completed (status→completed, phase cleared), Code-Review Failure Re-Routing (reverts phase to dev-story within same story cycle), Code-Review Requires Fresh Sub-Agent (clean context window mandate)
- Added 35 new bats tests (Template 2.5-1 through 2.5-29, StoryLoop 2.5-1 through 2.5-6) covering both templates and phase handling logic
- All 181 tests pass (146 existing + 35 new), zero regressions
- Task 5 manual verification confirmed: templates loadable by stage identifier, phase transitions documented correctly, failure re-routing pattern documented

### Change Log

- 2026-02-03: Story 2.5 implementation complete — created dev-story and code-review templates, updated orchestrator with phase handling, added 35 bats tests
- 2026-02-03: Code review fixes — corrected test count (146+35=181), fixed agent model ID, added devStoryStartCommit tracking to orchestrator and code-review template for reliable git diff computation, committed all changes

### File List

- `.bmad-orchestrator/templates/stage-dev-story.md` — NEW — Dev Story stage prompt template
- `.bmad-orchestrator/templates/stage-code-review.md` — NEW — Code Review stage prompt template
- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added dev-story/code-review phase transitions, git commit expectations, failure re-routing, fresh sub-agent requirement
- `tests/orchestrator-agent.bats` — MODIFIED — Added 39 new tests (Template 2.5-1 to 2.5-29, StoryLoop 2.5-1 to 2.5-6)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Status updated to in-progress then review
- `_bmad-output/implementation-artifacts/2-5-dev-story-code-review-templates-with-git-commits.md` — MODIFIED — Task checkboxes checked, Dev Agent Record populated

# Story 2.6: Quick Flow Pipeline

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want to run a two-stage Quick Flow for simple tasks,
so that bug fixes and small utilities get built fast without full planning overhead.

## Acceptance Criteria

1. **Given** `state.yaml` has `route: quick`
   **When** the orchestrator launches
   **Then** it follows the Quick Flow track: `quick-spec` → `quick-dev`

2. **Given** the `stage-quick-spec.md` template exists
   **When** the orchestrator reaches the `quick-spec` stage
   **Then** it launches the appropriate sub-agent, drives the Quick Spec workflow, and produces a tech spec artifact

3. **Given** the `stage-quick-dev.md` template exists
   **When** the orchestrator reaches the `quick-dev` stage
   **Then** it launches the Dev sub-agent with the tech spec as input, drives the Quick Dev workflow, and produces implemented code with passing tests

4. **Given** Quick Flow completes both stages
   **When** the orchestrator checks the pipeline
   **Then** it recognizes the pipeline is complete and exits with code 2

5. **Given** each Quick Flow template
   **When** reviewed
   **Then** each follows the standard template format with frontmatter (`stage`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`), `## Context Injection` with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}` bare placeholders, `## Stage Instructions`, and `## Verification`

## Tasks / Subtasks

- [x] Task 1: Create `stage-quick-spec.md` prompt template (AC: #2, #5)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-quick-spec.md` with YAML frontmatter:
    ```yaml
    ---
    stage: quick-spec
    agent: bmad-quick-flow
    command: TS
    requiredArtifacts: []
    producedArtifacts:
      - _bmad-output/planning-artifacts/tech-spec.md
    ---
    ```
  - [x] 1.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders (no markdown wrapping — per established pattern from all previous templates)
  - [x] 1.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-quick-flow` agent via Task tool, send `TS` command to trigger Quick Spec workflow
    - **Interaction Protocol:** Act as expert product/engineering lead. The Quick Flow agent runs a conversational spec engineering workflow: it asks discovery questions, investigates existing code, then generates a tech-spec. Provide clear, decisive answers using the task description. When asked about technical decisions, keep scope narrow and focused on the specific task. Use YOLO mode when offered. The Quick Spec workflow produces a tech-spec file (markdown) that serves as the implementation blueprint for quick-dev
    - **Output Requirements:** Tech spec saved to `_bmad-output/planning-artifacts/tech-spec.md` (or the path the workflow produces). Must contain implementation-ready specification with clear scope, technical approach, and acceptance criteria
    - **Failure Recovery:** If tech spec not saved: ensure the workflow completes including the save step. If content misaligned: provide more explicit answers steering toward the task intent. If workflow stalls: use YOLO mode earlier
  - [x] 1.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify tech spec file exists on disk (glob for `_bmad-output/planning-artifacts/*tech-spec*` or `_bmad-output/*tech-spec*`)
    - **Content Alignment:** Read the tech spec, verify it addresses the core intent of the task description. Verify it contains implementation-ready content (not a stub)
    - **Quality Baseline:** Verify the spec is substantive, contains a technical approach, and could serve as input to the quick-dev stage
    - **Verification Outcome:** PASS: Tech spec exists, aligns with task, and is substantive. FAIL: Missing, empty, misaligned, or a stub

- [x] Task 2: Create `stage-quick-dev.md` prompt template (AC: #3, #5)
  - [x] 2.1: Create `.bmad-orchestrator/templates/stage-quick-dev.md` with YAML frontmatter:
    ```yaml
    ---
    stage: quick-dev
    agent: bmad-quick-flow
    command: QD
    requiredArtifacts:
      - _bmad-output/planning-artifacts/tech-spec.md
    producedArtifacts:
      - _bmad-output/planning-artifacts/tech-spec.md
    ---
    ```
    Note: The produced artifact is the same tech-spec file updated in-place (Quick Dev updates the spec with completion status). The actual code artifacts are produced on disk by the sub-agent but are verified via git commits, not as BMAD artifacts.
  - [x] 2.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders
  - [x] 2.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-quick-flow` agent via Task tool, send `QD` command to trigger Quick Dev workflow
    - **Interaction Protocol:** Act as expert engineering lead. The Quick Dev agent reads the tech spec, gathers context from the codebase, implements the solution, runs self-checks, performs adversarial review, and resolves findings. Provide the path to the tech-spec file so the agent knows what to implement. When asked about technical decisions, reference the tech-spec and task description. Use YOLO mode when offered. Ensure git commits happen on the current worktree branch (FR35). The Quick Dev agent handles its own code review internally (adversarial review step)
    - **Output Requirements:** Code implemented per tech spec. Git commits made to current worktree branch. Tests pass. Tech-spec file updated with completion status
    - **Failure Recovery:** If code not implemented: ensure QD workflow completes all steps. If tests fail: the workflow's self-check and adversarial review should catch this. If no git commits: ensure commits happen during implementation. If failure context present: address the specific issues
  - [x] 2.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify tech-spec file still exists (it should have been updated). Verify git log shows new commits on current branch since stage started
    - **Content Alignment:** Read the tech spec, verify it reflects completed implementation. Verify code changes align with the original task description
    - **Quality Baseline:** Verify tests pass (if applicable). Verify git commits were made to current worktree branch. Verify the implementation is substantive (not empty or placeholder)
    - **Verification Outcome:** PASS: Code implemented, git commits exist, tests pass, tech spec updated. FAIL: No commits, tests failing, no code changes, or tech spec not updated

- [x] Task 3: Verify orchestrator Quick Flow routing works end-to-end (AC: #1, #4)
  - [x] 3.1: Verify the orchestrator agent definition (`.claude/agents/bmad-orchestrator.md`) already handles Quick Flow track correctly:
    - Section 1.2 routing sets `currentStage: quick-spec` when `route: quick`
    - Section 2 Quick Flow Track defines `quick-spec` → `quick-dev` sequence
    - Next Stage Determination logic works for Quick Flow stages
    - Pipeline completion (exit code 2) triggers when both quick-flow stages complete
  - [x] 3.2: Verify no orchestrator agent modifications are needed for Quick Flow — the existing routing and stage sequencing logic should already support it (quick-spec and quick-dev are already in the frozen stage identifiers list and Quick Flow Track is already documented in Section 2)
  - [x] 3.3: If any gaps are found in the orchestrator agent's Quick Flow handling, document and fix them

- [x] Task 4: Write bats tests for quick-spec and quick-dev templates (AC: #1, #2, #3, #4, #5)
  - [x] 4.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-quick-spec.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-quick-spec.md`
    - Template has valid YAML frontmatter with `stage: quick-spec`
    - Template frontmatter contains `agent: bmad-quick-flow`
    - Template frontmatter contains `command: TS`
    - Template frontmatter contains `requiredArtifacts` (empty array)
    - Template frontmatter contains `producedArtifacts` with `tech-spec`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 4.2: Add tests validating `stage-quick-dev.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-quick-dev.md`
    - Template has valid YAML frontmatter with `stage: quick-dev`
    - Template frontmatter contains `agent: bmad-quick-flow`
    - Template frontmatter contains `command: QD`
    - Template frontmatter contains `requiredArtifacts` with `tech-spec`
    - Template frontmatter contains `producedArtifacts`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 4.3: Add tests validating Quick Flow routing support in orchestrator:
    - Agent mentions `quick-spec` → `quick-dev` sequence
    - Agent describes Quick Flow track for `route: quick`
    - Agent routes to `quick-spec` as first stage when route is `quick`
  - [x] 4.4: Use test naming pattern: `@test "Template 2.6-N: description"` for template tests, `@test "QuickFlow 2.6-N: description"` for routing tests
  - [x] 4.5: Verify all existing tests still pass (zero regressions on all 181 existing tests)

- [ ] Task 5: Manual verification (AC: #1, #2, #3, #4) — MANUAL
  - [ ] 5.1: Verify the orchestrator can load `stage-quick-spec.md` when `currentStage: quick-spec`
  - [ ] 5.2: Verify the orchestrator can load `stage-quick-dev.md` when `currentStage: quick-dev`
  - [ ] 5.3: Verify Quick Flow sequence: `quick-spec` → `quick-dev` → pipeline complete (exit code 2)
  - [ ] 5.4: Verify routing: `route: quick` sets `currentStage: quick-spec`

## Dev Notes

### Architecture Compliance

**This story creates 2 new files and modifies 1 existing file:**
- `.bmad-orchestrator/templates/stage-quick-spec.md` — **NEW** — Quick Spec stage prompt template
- `.bmad-orchestrator/templates/stage-quick-dev.md` — **NEW** — Quick Dev stage prompt template
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add template + routing tests

**No orchestrator agent modifications expected.** Unlike stories 2.1–2.5 which each added new orchestrator logic (storyLoop population, phase transitions, etc.), Quick Flow routing and stage sequencing are already fully documented in `bmad-orchestrator.md`:
- Section 1.2: Routes `quick` → `currentStage: quick-spec`
- Section 2: Quick Flow Track `quick-spec` → `quick-dev`
- Section 2: Frozen stage identifiers include `quick-spec` and `quick-dev`

### What Makes Quick Flow Templates UNIQUE

**Quick Flow does NOT use the storyLoop.** Unlike Full Method templates (`stage-create-story.md`, `stage-dev-story.md`, `stage-code-review.md`) which iterate through `storyLoop.epics[].stories[]`, Quick Flow is a simple two-stage linear pipeline:
1. `quick-spec` produces a tech spec
2. `quick-dev` consumes the tech spec and produces code

**Quick Flow uses a DIFFERENT agent.** All Full Method templates use either `bmad-pm`, `bmad-sm`, `bmad-architect`, or `bmad-dev`. Quick Flow uses `bmad-quick-flow` — a solo-dev agent that handles both spec creation and development. The commands are `TS` (tech-spec) and `QD` (quick-dev).

**Quick Dev includes its own adversarial review.** Unlike Full Method where `dev-story` and `code-review` are separate stages with separate sub-agents, Quick Dev's workflow has built-in self-check and adversarial review steps (steps 4-6 in its workflow). There is no separate `code-review` stage in Quick Flow.

**Quick Dev makes git commits.** Like `stage-dev-story.md`, the Quick Dev stage produces git commits. The orchestrator verifies they exist but doesn't make them (per Boundary Rules).

### Agent & Command Selection

**Quick Spec:**
- **Agent:** `bmad-quick-flow` — the Quick Flow solo-dev agent
- **Command:** `TS` — triggers the Quick Spec workflow (conversational spec engineering)
- **Workflow path:** `_bmad/bmm/workflows/bmad-quick-flow/quick-spec/workflow.md`

**Quick Dev:**
- **Agent:** `bmad-quick-flow` — same agent, different command
- **Command:** `QD` — triggers the Quick Dev workflow (implement tech spec end-to-end)
- **Workflow path:** `_bmad/bmm/workflows/bmad-quick-flow/quick-dev/workflow.md`

### Quick Flow Pipeline Lifecycle

```
User runs /bmad-orchestrate --quick "Fix login bug"
  → state.yaml created with route: quick
  → Routing: quick → currentStage: quick-spec
  → Load stage-quick-spec.md → launch bmad-quick-flow → TS command
  → Tech spec produced → verification → stage complete
  → Next stage: quick-dev
  → Load stage-quick-dev.md → launch bmad-quick-flow → QD command
  → Code implemented, tests pass, git commits made → verification
  → All Quick Flow stages complete → exit code 2 (pipeline complete)
```

### Tech Spec Artifact Path

The Quick Spec workflow produces a tech-spec file. The exact output path depends on the workflow's configuration, but it typically saves to `_bmad-output/planning-artifacts/` or a user-specified location. The template should use `_bmad-output/planning-artifacts/tech-spec.md` as the expected path, with verification using a glob pattern (`*tech-spec*`) to handle slight naming variations.

### Previous Story Intelligence

**Story 2.5 (Dev Story & Code Review Templates):**
- Created 2 templates + modified orchestrator + 35 bats tests
- Total tests after 2.5: 181
- Test naming: `@test "Template 2.5-N: description"` and `@test "StoryLoop 2.5-N: description"`
- Key learning: validation stages (like code-review) need tri-state quality gates (PASS/CONCERNS/FAIL)
- Key learning: templates that produce git commits need verification of both file content AND git history

**Story 2.4 (Create Story Template):**
- Created 1 template + modified orchestrator + 17 bats tests
- Added story loop Phase Initialization to orchestrator
- Key learning: `currentStage` stays at the story-level stage; `storyLoop` tracks which story is active
- Quick Flow does NOT use storyLoop, so this pattern doesn't apply

### Git Intelligence

Recent commits follow pattern: `feat: <description> (story X-Y)`
Most recent commit: `19ae508 feat: add dev-story and code-review stage templates with phase handling (story 2-5)`
181 existing tests, all passing.

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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). Confirmed in ALL previous templates (stories 1-5, 2-1, 2-2, 2-3, 2-4, 2-5).

### Test Pattern (from previous stories — follow exactly)

**Template tests (12-13 per template, ~24-26 total for two templates):**
1. Template file exists
2. Valid YAML frontmatter with correct stage identifier
3. Frontmatter contains correct agent (`bmad-quick-flow`)
4. Frontmatter contains correct command (`TS` or `QD`)
5. Frontmatter contains requiredArtifacts
6. Frontmatter contains producedArtifacts
7. Contains `## Context Injection` section
8. Contains `## Stage Instructions` section
9. Contains `## Verification` section
10. Contains `{{task_description}}` placeholder
11. Contains `{{failure_context}}` placeholder
12. Contains `{{mode_instructions}}` placeholder

**Quick Flow routing tests (additional):**
- Agent mentions `quick-spec` → `quick-dev` sequence
- Agent describes Quick Flow track
- Agent routes to `quick-spec` as first stage for quick route

### Anti-Patterns to Avoid

- Using wrong stage identifiers (must be `quick-spec` and `quick-dev` exactly — from the frozen list)
- Using wrong agent name (must be `bmad-quick-flow`, NOT `bmad-pm` or `bmad-dev`)
- Using wrong commands (must be `TS` for quick-spec and `QD` for quick-dev)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` — camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare)
- Adding storyLoop logic to Quick Flow (Quick Flow is linear, no story loop)
- Orchestrator making git commits directly during quick-dev (violates boundary rules)
- Direct writes to state.yaml without temp-then-rename atomic pattern

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-quick-spec.md` — NEW file in existing templates directory
- `.bmad-orchestrator/templates/stage-quick-dev.md` — NEW file in existing templates directory
- `tests/orchestrator-agent.bats` — MODIFIED, add tests for both templates + routing
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifiers are frozen: `quick-spec`, `quick-dev`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.6] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2] — Full Pipeline & Quick Flow Orchestration epic context
- [Source: _bmad-output/planning-artifacts/architecture.md#Quick Flow Track] — `quick-spec` → `quick-dev` sequence
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] — Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] — Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] — `quick-spec`, `quick-dev`
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] — Post-stage verification steps
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] — templates/ directory, stage-quick-spec.md and stage-quick-dev.md listed
- [Source: _bmad-output/planning-artifacts/architecture.md#Routing Logic] — Quick Flow: single-file changes, bug fixes, small utilities
- [Source: _bmad-output/planning-artifacts/prd.md#FR16] — "Orchestrator can execute Quick Spec workflow autonomously"
- [Source: _bmad-output/planning-artifacts/prd.md#FR17] — "Orchestrator can execute Quick Dev workflow using the tech spec as input"
- [Source: _bmad-output/project-context.md#Prompt Template Rules] — Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] — Orchestrator never writes BMAD artifacts directly
- [Source: _bmad-output/project-context.md#Verification Pattern] — Never skip verification after sub-agent completes
- [Source: .claude/agents/bmad-orchestrator.md#Section 1.2] — Routing Protocol, quick route → quick-spec
- [Source: .claude/agents/bmad-orchestrator.md#Section 2] — Quick Flow Track: quick-spec → quick-dev
- [Source: .claude/agents/bmad-orchestrator.md#Section 2 Frozen Stage Identifiers] — quick-spec, quick-dev in frozen list
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] — Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] — Verification (NEVER SKIP)
- [Source: .claude/agents/bmad-quick-flow.md] — Quick Flow agent definition, TS and QD commands
- [Source: .claude/commands/bmad/bmm/workflows/quick-spec.md] — Quick Spec slash command
- [Source: .claude/commands/bmad/bmm/workflows/quick-dev.md] — Quick Dev slash command
- [Source: _bmad/bmm/workflows/bmad-quick-flow/quick-spec/workflow.md] — Quick Spec workflow definition
- [Source: _bmad/bmm/workflows/bmad-quick-flow/quick-dev/workflow.md] — Quick Dev workflow definition
- [Source: _bmad-output/implementation-artifacts/2-5-dev-story-code-review-templates-with-git-commits.md] — Previous story with template + test patterns
- [Source: tests/orchestrator-agent.bats] — 181 existing tests, test naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None — clean implementation with no issues.

### Completion Notes List

- Created `stage-quick-spec.md` template with correct frontmatter (stage: quick-spec, agent: bmad-quick-flow, command: TS, requiredArtifacts: [], producedArtifacts: tech-spec.md), bare Context Injection placeholders, Stage Instructions with Launch Sequence/Interaction Protocol/Output Requirements/Failure Recovery, and Verification with Artifact Existence/Content Alignment/Quality Baseline/Verification Outcome
- Created `stage-quick-dev.md` template with correct frontmatter (stage: quick-dev, agent: bmad-quick-flow, command: QD, requiredArtifacts: tech-spec.md, producedArtifacts: tech-spec.md), bare Context Injection placeholders, Stage Instructions covering git commits and internal adversarial review, and Verification covering code + commits + tests
- Verified orchestrator agent (`bmad-orchestrator.md`) already fully supports Quick Flow: Section 1.2 routes quick → quick-spec, Section 2 defines quick-spec → quick-dev sequence, frozen identifiers include both, Next Stage Determination and exit code 2 logic work. No orchestrator modifications needed
- Added 27 bats tests: 12 for quick-spec template, 12 for quick-dev template, 3 for Quick Flow routing. Test naming follows established pattern (Template 2.6-N, QuickFlow 2.6-N)
- All 208 tests pass (181 existing + 27 new), zero regressions
- Task 5 (manual verification) left unchecked — requires manual orchestrator execution

### Change Log

- 2026-02-03: Implemented story 2-6 — created Quick Flow pipeline templates and tests

### File List

- `.bmad-orchestrator/templates/stage-quick-spec.md` — **NEW** — Quick Spec stage prompt template
- `.bmad-orchestrator/templates/stage-quick-dev.md` — **NEW** — Quick Dev stage prompt template
- `tests/orchestrator-agent.bats` — **MODIFIED** — Added 27 tests for Quick Flow templates and routing
- `_bmad-output/implementation-artifacts/2-6-quick-flow-pipeline.md` — **MODIFIED** — Story file updated
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — **MODIFIED** — Status updated

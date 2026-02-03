# Story 2.2: Implementation Readiness Stage Template

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to run the Implementation Readiness check autonomously and interpret its results,
so that planning quality is validated before any code is written.

## Acceptance Criteria

1. **Given** the `stage-readiness.md` template exists in `.bmad-orchestrator/templates/`
   **When** reviewed
   **Then** it contains frontmatter with `stage: readiness`, `agent: bmad-pm`, `command: IR`, `requiredArtifacts: [prd.md, architecture.md, epics.md]`, `producedArtifacts: [implementation-readiness-report.md]`
   **And** it contains Context Injection, Stage Instructions, and Verification sections

2. **Given** the readiness stage template follows the Architecture's prompt template format
   **When** reviewed
   **Then** it contains `## Context Injection` with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}` bare placeholders
   **And** `## Stage Instructions` with Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery subsections
   **And** `## Verification` with Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome subsections

3. **Given** the readiness check completes with PASS
   **When** the orchestrator runs verification
   **Then** it confirms the readiness report exists on disk, reads the overall status as PASS, updates `state.yaml` atomically, and advances to the next stage (`sprint-planning`)

4. **Given** the readiness check completes with CONCERNS or FAIL
   **When** the orchestrator reads the result
   **Then** the stage is treated as a failure, the specific concerns from the readiness report are captured in the `failures` array for downstream re-routing (Epic 3), and the orchestrator follows the standard failure/retry flow

5. **Given** the readiness stage completes
   **When** the orchestrator updates state
   **Then** `completedStages` is updated to include `readiness`, `currentStage` advances to `sprint-planning`, and the agent exits with code 0

## Tasks / Subtasks

- [x] Task 1: Create `stage-readiness.md` prompt template (AC: #1, #2, #3, #4, #5)
  - [x] 1.1: Create `.bmad-orchestrator/templates/stage-readiness.md` with YAML frontmatter:
    ```yaml
    ---
    stage: readiness
    agent: bmad-pm
    command: IR
    requiredArtifacts:
      - _bmad-output/planning-artifacts/prd.md
      - _bmad-output/planning-artifacts/architecture.md
      - _bmad-output/planning-artifacts/epics.md
    producedArtifacts:
      - _bmad-output/planning-artifacts/implementation-readiness-report.md
    ---
    ```
  - [x] 1.2: Write `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, and `{{mode_instructions}}` bare placeholders (matching stage-prd.md pattern exactly -- no markdown wrapping)
  - [x] 1.3: Write `## Stage Instructions` section organized as:
    - **Launch Sequence:** Launch `bmad-pm` agent via Task tool, send `IR` command to trigger Implementation Readiness Review workflow
    - **Interaction Protocol:** Act as expert engineering lead. The IR workflow is adversarial -- it checks PRD, Architecture, and Epics for completeness and alignment. Answer any questions referencing all three planning artifacts. Use YOLO mode when offered.
    - **Output Requirements:** Report saved to `_bmad-output/planning-artifacts/implementation-readiness-report.md`. Must contain overall PASS/CONCERNS/FAIL verdict.
    - **Failure Recovery:** If readiness report not saved: ensure workflow completes including save. If previous concerns identified in failure_context: provide explicit remediation guidance targeting those specific concerns. If upstream re-routing feedback present: explain which upstream artifact was revised and what changed.
  - [x] 1.4: Write `## Verification` section organized as:
    - **Artifact Existence:** Verify `_bmad-output/planning-artifacts/implementation-readiness-report.md` exists on disk
    - **Content Alignment:** Read the report and extract the overall verdict (PASS/CONCERNS/FAIL). Verify report covers PRD requirements, architecture decisions, and epic/story completeness
    - **Quality Baseline:** Verify the report is substantive (not a stub), contains specific findings, and could serve as a quality gate for implementation
    - **Quality Gate Interpretation:** This is a validation stage. PASS = proceed. CONCERNS = proceed but log concern details. FAIL = trigger failure handling (Section 6 of orchestrator agent). Capture the specific concerns/failures from the report in the failure error summary for downstream re-routing.
    - **Verification Outcome:** PASS: Report exists, verdict is PASS or CONCERNS, advance to `sprint-planning`. FAIL: Report missing, verdict is FAIL, or report is stub/placeholder.

- [x] Task 2: Write bats tests for readiness template (AC: #1, #2)
  - [x] 2.1: Add tests to `tests/orchestrator-agent.bats` validating `stage-readiness.md`:
    - Template file exists at `.bmad-orchestrator/templates/stage-readiness.md`
    - Template has valid YAML frontmatter with `stage: readiness`
    - Template frontmatter contains `agent: bmad-pm`
    - Template frontmatter contains `command: IR`
    - Template frontmatter contains `requiredArtifacts` with `prd.md`, `architecture.md`, and `epics.md`
    - Template frontmatter contains `producedArtifacts` with `implementation-readiness-report.md`
    - Template contains `## Context Injection` section
    - Template contains `## Stage Instructions` section
    - Template contains `## Verification` section
    - Template contains `{{task_description}}` placeholder
    - Template contains `{{failure_context}}` placeholder
    - Template contains `{{mode_instructions}}` placeholder
  - [x] 2.2: Use test naming pattern: `@test "Template 2.2-N: description"` (e.g., `@test "Template 2.2-1: stage-readiness template exists"`)
  - [x] 2.3: Verify all existing tests still pass (zero regressions on all 91 existing tests)

- [x] Task 3: Verify orchestrator handles readiness stage transitions correctly (AC: #3, #5) -- MANUAL
  - [x] 3.1: Verify the orchestrator can load `stage-readiness.md` when `currentStage: readiness`
  - [x] 3.2: Verify stage sequencing: after readiness completes, `currentStage` advances to `sprint-planning`

## Dev Notes

### Architecture Compliance

**This story creates exactly 1 new file and modifies 1 existing file:**
- `.bmad-orchestrator/templates/stage-readiness.md` -- **NEW** -- Implementation Readiness stage prompt template
- `tests/orchestrator-agent.bats` -- **MODIFIED** -- Add template-specific tests for the new template

**This is NOT a code story.** Like stories 1-5 and 2-1, this is a markdown prompt template that the orchestrator agent reads and uses to drive a sub-agent. No bash scripting or code changes are needed. The "implementation" is writing a well-structured prompt template following the exact format established by `stage-prd.md`.

### Prompt Template Format (from Architecture -- MUST follow exactly)

Every template file MUST follow this exact structure (established in story 1-5, used in story 2-1):

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

**Critical:** Context Injection uses bare placeholders (not wrapped in markdown formatting). This was corrected during story 1-5 code review and confirmed in story 2-1.

### What Makes Readiness UNIQUE vs Other Templates

This is the **first validation stage template** in the pipeline. Unlike PRD, Architecture, and Epics-Stories templates which simply produce artifacts, the readiness template:

1. **Has a tri-state quality gate:** PASS/CONCERNS/FAIL -- not just "artifact exists or not"
2. **Drives an adversarial review:** The IR workflow actively looks for gaps and problems
3. **Is the trigger for upstream re-routing (Epic 3):** When readiness fails, the orchestrator needs specific concern details to re-route back to the right upstream stage
4. **Its failure error summaries feed `{{failure_context}}`:** Not just for its own retries, but also for upstream stages when re-routing occurs

The orchestrator agent's Section 5.3 (Quality Gate) already handles PASS/CONCERNS/FAIL for validation stages. The readiness template's Verification section must clearly explain how to extract the verdict and map it to these outcomes.

### How the Orchestrator Uses This Template

Per `.claude/agents/bmad-orchestrator.md` Sections 3-5 (established in stories 1-3 and 1-4):

1. **Section 3 (Template Loading):** Orchestrator reads `stage-readiness.md`, parses frontmatter to get `agent: bmad-pm`, `command: IR`, and three `requiredArtifacts`. Pre-validates that PRD, Architecture, AND Epics all exist on disk before launching the sub-agent.

2. **Section 4 (Sub-Agent Interaction):** Orchestrator launches `bmad-pm` via Task tool. Sends `IR` command. Acts as expert user -- the IR workflow may ask questions about priorities, acceptable risk levels, etc. Uses YOLO mode when offered.

3. **Section 5 (Verification):** After sub-agent completes, orchestrator checks `implementation-readiness-report.md` exists on disk, reads the verdict, and maps it: PASS → advance, CONCERNS → advance with logged warnings, FAIL → failure handling with specific concerns captured.

### Stage Sequencing (Full Method Pipeline)

The Full Method pipeline stages in order:
```
prd → architecture → epics-stories → readiness → sprint-planning → create-story → dev-story → code-review
```

After `epics-stories` completes: `completedStages: [prd, architecture, epics-stories]`, `currentStage: readiness`
After `readiness` completes: `completedStages: [prd, architecture, epics-stories, readiness]`, `currentStage: sprint-planning`

### Agent & Command Selection

**Agent:** `bmad-pm` -- the PM agent has the IR (Implementation Readiness) command at menu item 8. The Architect also has IR at menu item 5. Either could run it. Using `bmad-pm` because:
- The PM owns the PRD and epics -- the primary artifacts being validated
- The PM has broader product context for evaluating readiness
- Consistent with using PM for product-facing workflows

**Command:** `IR` -- triggers the Implementation Readiness Review workflow at `_bmad/bmm/workflows/3-solutioning/check-implementation-readiness/workflow.md`

### Required Artifacts Pre-Validation

The orchestrator's Section 3 (Template Loading) pre-validates `requiredArtifacts` before launching a sub-agent:

- `stage-readiness.md` requires: `_bmad-output/planning-artifacts/prd.md` AND `_bmad-output/planning-artifacts/architecture.md` AND `_bmad-output/planning-artifacts/epics.md`

This is the first template requiring THREE artifacts. All three must exist or the orchestrator enters failure handling without launching the sub-agent.

### Previous Story Intelligence

**Story 2.1 (Architecture & Epics-Stories Templates):**
- Created 2 templates following exact format from `stage-prd.md`
- Added 24 bats tests (12 per template)
- Test naming: `@test "Template 2.1-N: description"`
- Key learning: bare placeholders in Context Injection (no markdown wrapping)
- Code review added `command` field tests (originally missed) -- make sure to include command test from the start
- 91 total tests passing after story 2-1
- Stage Instructions organized as: Launch Sequence, Interaction Protocol, Output Requirements, Failure Recovery
- Verification organized as: Artifact Existence, Content Alignment, Quality Baseline, Verification Outcome

**Story 1.5 (PRD Stage Template):**
- Established the template format -- all subsequent templates follow this exactly
- Context Injection bare placeholder pattern was corrected during code review

### Git Intelligence

Recent commits follow the pattern: `feat: <description> (story X-Y)`

Files changed in each story:
- Story 2-1: `stage-architecture.md` (NEW), `stage-epics-stories.md` (NEW), `orchestrator-agent.bats` (MODIFIED)
- Story 1-5: `stage-prd.md` (NEW), `orchestrator-agent.bats` (MODIFIED)

Established test naming: `@test "Template X.Y-N: description"` (e.g., `@test "Template 2.2-1: stage-readiness template exists"`)

### Test Pattern (from story 2-1 -- follow exactly)

Each template gets 12 tests:
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

For readiness, test #5 must check for ALL THREE required artifacts (prd.md, architecture.md, epics.md).

### Anti-Patterns to Avoid

- Using wrong stage identifier (must be `readiness` exactly -- from the frozen list)
- Using different frontmatter field names than established (must be `requiredArtifacts`, `producedArtifacts` -- camelCase)
- Missing the `## Verification` section (architecture mandates it for EVERY template)
- Wrapping Context Injection placeholders in markdown formatting (must be bare, per story 1-5 code review)
- Skipping `{{failure_context}}` or `{{mode_instructions}}` placeholders
- Creating additional files beyond the template and test modifications
- Modifying `bmad-orchestrator.md` -- the agent definition already handles template loading for any stage
- Modifying `loop.sh` -- the loop script is not touched by this story
- Forgetting to test the `command: IR` field (was missed in story 2-1 initial implementation, caught in code review)
- Treating CONCERNS as a hard failure -- CONCERNS means PASS with warnings, not FAIL

### Project Structure Notes

- `.bmad-orchestrator/templates/stage-readiness.md` -- NEW file in existing templates directory
- `tests/orchestrator-agent.bats` -- MODIFIED, add tests for the new template
- The templates directory already exists (created in story 1-5)
- File naming follows `kebab-case` and `stage-{identifier}.md` pattern
- Stage identifier is frozen: `readiness`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2] -- Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] -- Template format specification
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Template Format] -- Exact structural requirements with example
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] -- Post-stage verification steps (artifact check -> goal alignment -> quality gate -> pass/fail)
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] -- Task tool resume mechanism
- [Source: _bmad-output/planning-artifacts/architecture.md#File & Directory Structure] -- templates/ directory location
- [Source: _bmad-output/planning-artifacts/architecture.md#Frozen Stage Identifiers] -- `readiness`
- [Source: _bmad-output/project-context.md#Prompt Template Rules] -- Frontmatter fields, section requirements
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] -- Exact strings to use
- [Source: _bmad-output/project-context.md#Boundary Rules] -- Orchestrator never writes BMAD artifacts directly
- [Source: .claude/agents/bmad-orchestrator.md#Section 3] -- Template loading logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 4] -- Sub-agent interaction protocol
- [Source: .claude/agents/bmad-orchestrator.md#Section 5] -- Verification (NEVER SKIP), Section 5.3 Quality Gate for PASS/CONCERNS/FAIL
- [Source: .claude/agents/bmad-orchestrator.md#Section 6] -- Failure Handling
- [Source: .bmad-orchestrator/templates/stage-prd.md] -- Reference template (exact format to follow)
- [Source: .bmad-orchestrator/templates/stage-architecture.md] -- Another reference template
- [Source: _bmad-output/implementation-artifacts/2-1-architecture-epics-stories-stage-templates.md] -- Previous story with template creation patterns, test patterns, and learnings
- [Source: tests/orchestrator-agent.bats] -- 91 existing tests, test naming patterns established
- [Source: .claude/agents/bmad-pm.md#IR command] -- PM agent's Implementation Readiness command at menu item 8

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

None required — clean implementation with no issues.

### Completion Notes List

- Created `stage-readiness.md` following exact template format from `stage-prd.md` and `stage-epics-stories.md`
- Template includes tri-state quality gate (PASS/CONCERNS/FAIL) in Verification section — unique to this validation stage
- CONCERNS mapped to PASS with warnings (not FAIL), per orchestrator Section 5.3
- Failure Recovery includes upstream re-routing guidance for Epic 3 compatibility
- Context Injection uses bare placeholders (no markdown wrapping) per story 1-5 code review learning
- All 12 bats tests follow established `Template 2.2-N:` naming pattern
- Test #5 validates all THREE requiredArtifacts (prd.md, architecture.md, epics.md)
- `command: IR` test included from the start (lesson from story 2-1 code review)
- 103/103 tests pass — 91 existing + 12 new, zero regressions
- Task 3 (manual): Orchestrator uses `stage-{currentStage}.md` pattern, so `stage-readiness.md` loads when `currentStage: readiness`. Pipeline sequence confirms `readiness` → `sprint-planning`.

### Change Log

- Created `.bmad-orchestrator/templates/stage-readiness.md` — Implementation Readiness stage prompt template
- Modified `tests/orchestrator-agent.bats` — Added 12 bats tests for readiness template (tests 92-103)
- Updated `_bmad-output/implementation-artifacts/sprint-status.yaml` — Story status: ready-for-dev → in-progress → review

### File List

- `.bmad-orchestrator/templates/stage-readiness.md` (NEW)
- `tests/orchestrator-agent.bats` (MODIFIED)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (MODIFIED)
- `_bmad-output/implementation-artifacts/2-2-implementation-readiness-stage-template.md` (MODIFIED)

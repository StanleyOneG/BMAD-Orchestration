# Story 3.2: Upstream Re-routing & Remediation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to fix the root cause when a downstream validation fails,
so that issues like "architecture didn't address connection pooling" get fixed at the source rather than retrying the same broken stage.

## Acceptance Criteria

1. **Given** implementation readiness returns CONCERNS or FAIL with a report identifying gaps
   **When** the orchestrator analyzes the failure report
   **Then** it identifies which upstream stage produced the artifact with the gap (e.g., architecture, PRD)

2. **Given** an upstream stage is identified as needing revision
   **When** the orchestrator re-routes
   **Then** it sets `currentStage` back to the upstream stage, constructs specific remediation instructions from the failure report, and injects them into the stage template's `{{failure_context}}`

3. **Given** the orchestrator re-routes to an upstream stage
   **When** the sub-agent runs the revision
   **Then** the sub-agent receives clear instructions like "Address connection pooling concerns raised in the implementation readiness report" rather than re-running the entire workflow from scratch

4. **Given** the upstream revision completes
   **When** the orchestrator advances the pipeline
   **Then** it re-runs the validation stage that originally failed to verify the fix

5. **Given** a re-routing occurs
   **When** the orchestrator updates state
   **Then** the `failures` array captures the full chain: original failure, re-route decision, and the re-routed stage attempt

## Tasks / Subtasks

- [x] Task 1: Design and implement upstream re-routing logic in orchestrator agent (AC: #1, #2, #3)
  - [x] 1.1: Add new Section 6.5 "Upstream Re-Routing" to `.claude/agents/bmad-orchestrator.md` after the existing failure handling logic (Section 6)
  - [x] 1.2: Define the re-routing trigger: when `readiness` stage FAILS, instead of simple retry, analyze the failure report to identify the upstream source
  - [x] 1.3: Implement upstream stage identification logic: parse the readiness report's specific findings to map gaps to the originating stage (`prd`, `architecture`, or `epics-stories`)
  - [x] 1.4: Implement the re-route state update: set `currentStage` to the identified upstream stage, preserve the original failed stage in a new `reRouteOrigin` field so the orchestrator knows to re-validate after the fix
  - [x] 1.5: Implement remediation context construction: extract specific failure findings from the readiness report and format them as targeted remediation instructions for `{{failure_context}}`
  - [x] 1.6: Ensure the re-routed sub-agent receives targeted instructions (e.g., "Revise architecture to address: connection pooling not specified") NOT a full re-run of the workflow

- [x] Task 2: Implement re-validation after upstream revision (AC: #4)
  - [x] 2.1: After the upstream revision stage completes verification, check if `reRouteOrigin` is set in state
  - [x] 2.2: If `reRouteOrigin` is set, route back to the original validation stage (e.g., `readiness`) instead of advancing to the next stage in the normal pipeline sequence
  - [x] 2.3: Clear `reRouteOrigin` after the re-validation stage completes successfully
  - [x] 2.4: Handle the case where re-validation ALSO fails: follow normal retry/re-route logic again (recursive re-routing is valid)

- [x] Task 3: Implement failure chain tracking in state file (AC: #5)
  - [x] 3.1: When a re-route decision is made, append a re-route entry to the `failures` array with a distinct format: `{stage: "<validation-stage>", attempt: N, error: "<original error>", timestamp: "<ISO>", reRoutedTo: "<upstream-stage>"}`
  - [x] 3.2: When the re-routed upstream stage completes or fails, append its own failure/success entry to the `failures` array as a normal entry
  - [x] 3.3: Ensure the full chain is readable: original failure → re-route decision → upstream attempt → re-validation result

- [x] Task 4: Update stage-readiness template for re-routing support (AC: #1, #3)
  - [x] 4.1: Enhance the Failure Recovery section of `.bmad-orchestrator/templates/stage-readiness.md` to include guidance for when the orchestrator re-routes after a readiness FAIL
  - [x] 4.2: Add a note in the Quality Gate Interpretation section explaining that FAIL triggers upstream re-routing (not just simple retry) — reference the new Section 6.5

- [x] Task 5: Write bats tests for upstream re-routing logic (AC: #1, #2, #3, #4, #5)
  - [x] 5.1: Add tests to `tests/orchestrator-agent.bats` validating re-routing logic in orchestrator agent:
    - Agent describes upstream stage identification from readiness failure
    - Agent describes re-routing to upstream stage (currentStage set back)
    - Agent describes remediation context construction from failure report
    - Agent describes targeted instructions (not full re-run)
  - [x] 5.2: Add tests validating re-validation after upstream revision:
    - Agent describes reRouteOrigin field usage
    - Agent describes routing back to validation stage after upstream fix
    - Agent describes clearing reRouteOrigin on re-validation success
  - [x] 5.3: Add tests validating failure chain tracking:
    - Agent describes re-route entry format in failures array (with reRoutedTo field)
    - Agent describes full chain: failure → re-route → upstream attempt → re-validation
  - [x] 5.4: Add tests validating re-routing interaction with existing failure handling:
    - Re-routing respects maxRetries (re-route counts as an attempt)
    - Re-routing interacts correctly with currentRetries tracking
    - Terminal failure still triggers when maxRetries exhausted including re-route attempts
  - [x] 5.5: Use test naming pattern: `@test "ReRoute 3.2-N: description"` for all tests
  - [x] 5.6: Verify all existing tests still pass (zero regressions on all 263 existing tests)

- [x] Task 6: Manual verification (AC: #1, #2, #3, #4, #5) — MANUAL
  - [x] 6.1: Verify the orchestrator agent describes complete re-routing flow from readiness FAIL to upstream revision to re-validation
  - [x] 6.2: Verify remediation context is described as targeted (not full re-run)
  - [x] 6.3: Verify failure chain captures the full re-routing decision trail
  - [x] 6.4: Trace a hypothetical re-routing scenario end-to-end through the documentation

## Dev Notes

### Architecture Compliance

**This story modifies 2 existing files and creates 0 new files:**
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add Section 6.5 (Upstream Re-Routing) with re-route logic, reRouteOrigin field, remediation context construction, and re-validation routing
- `.bmad-orchestrator/templates/stage-readiness.md` — **MODIFIED** — Enhance Failure Recovery section and Quality Gate Interpretation to reference upstream re-routing
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add re-routing tests (~20-30 new tests)

**No new files created.** Re-routing is an enhancement to existing orchestrator logic, not a new component.

### What Makes This Story UNIQUE

**Story 3.1 implemented "same-stage retry" — Story 3.2 implements "upstream re-routing."** These are fundamentally different failure recovery strategies:

- **Story 3.1 (done):** Stage fails → retry the SAME stage with failure context → hope the sub-agent does better
- **Story 3.2 (this story):** Validation stage fails → analyze the failure report → identify which UPSTREAM stage produced the broken artifact → re-route to that upstream stage with targeted remediation → re-validate after the fix

The key insight: retrying the readiness check doesn't fix an architecture that forgot connection pooling. You need to re-route to the architecture stage with explicit instructions to address the gap.

### Current Implementation — What Already Exists

**Failure detection (Story 3.1):**
- Section 5 (Verification): Artifact check, goal alignment, quality gate tri-state
- Section 5.3: FAIL triggers Section 5.5 (failure handling)
- Section 5.5: Log failure, increment retries, exit 0 for retry or exit 1 for terminal
- Section 6: Failure array format, retry logic, failure context injection
- Section 3.4: Failure context construction (extracting failures and building {{failure_context}})

**Code-review re-routing (Story 2.5):**
- "Code-Review Failure Re-Routing" section in orchestrator agent
- Code-review FAIL → revert phase to `dev-story` (within same story)
- This is INTRA-STORY re-routing, NOT upstream pipeline re-routing
- Different pattern from what 3.2 needs (code-review stays within story loop; readiness re-routes across pipeline stages)

**What's MISSING (the gap this story fills):**
- No logic exists for analyzing a readiness FAIL report and mapping findings to upstream stages
- No `reRouteOrigin` field exists in the state schema
- No logic to route back to the validation stage after an upstream fix
- No re-route entry format in the failures array
- Section 6 currently only handles simple retry (same stage) or terminal failure

### State File Schema Addition

The `reRouteOrigin` field must be added to the state schema:

```yaml
# New field — only present during re-routing
reRouteOrigin: "readiness"  # The validation stage that triggered the re-route
```

- Set when re-routing is triggered (after readiness FAIL analysis)
- Read during Section 7.1 (Construct Updated State) to determine whether to return to the validation stage or advance normally
- Cleared after re-validation completes successfully
- Uses `camelCase` per state file naming convention

### Upstream Stage Identification Logic

When readiness returns FAIL, the orchestrator must:

1. Read the readiness report from `_bmad-output/planning-artifacts/implementation-readiness-report.md`
2. Parse the specific findings (organized by artifact: PRD, Architecture, Epics)
3. Map each finding to its source stage:
   - PRD findings → route to `prd` stage
   - Architecture findings → route to `architecture` stage
   - Epics/Stories findings → route to `epics-stories` stage
4. If findings span multiple stages, prioritize the earliest stage in the pipeline sequence (fixing upstream artifacts cascades fixes downstream)
5. Construct targeted remediation instructions from the specific findings

### Re-Routing Flow (End-to-End)

```
1. Readiness stage FAILS (verification Section 5.3 → FAIL)
2. Section 5.5: Log failure to failures array
3. NEW Section 6.5: Analyze readiness report
4. Identify upstream stage (e.g., "architecture")
5. Append re-route entry to failures: {stage: "readiness", attempt: 1, error: "...", reRoutedTo: "architecture"}
6. Set reRouteOrigin: "readiness"
7. Set currentStage: "architecture"
8. Construct remediation failure_context from readiness findings
9. Exit code 0 (loop relaunches)
10. Next iteration: cold start → reads state → currentStage: "architecture" → loads architecture template
11. Section 3.4: Failure context includes targeted remediation instructions
12. Sub-agent revises architecture with specific guidance
13. Verification passes for architecture
14. Section 7.1: Check reRouteOrigin → set currentStage back to "readiness" (not "epics-stories")
15. Exit code 0
16. Next iteration: re-runs readiness with revised artifacts
17. If PASS: clear reRouteOrigin, advance to sprint-planning
18. If FAIL again: re-route again (respecting maxRetries)
```

### Interaction with Existing Retry Logic

**Critical design decision: re-routing counts against `maxRetries`.**
- Each re-route attempt (including the re-validation) counts as attempts against the original stage's retry limit
- This prevents infinite re-routing loops
- Example: maxRetries=3, readiness fails → re-route to architecture (attempt 1) → re-validate readiness (attempt 2) → if fails again, re-route (attempt 3) → if fails, terminal FAILED
- `currentRetries` tracks total attempts including re-routes

### DISCREPANCY — CONCERNS Handling in AC #1

**Epic AC says:** "implementation readiness returns CONCERNS or FAIL"
**Architecture and Story 3.1 established:** CONCERNS is a qualified PASS (not a failure)
**Resolution:** Only FAIL triggers upstream re-routing. CONCERNS proceeds with warnings. This aligns with the architecture and Story 3.1's resolution. The AC should be read as: "when readiness identifies gaps" — but only FAIL-level gaps trigger re-routing.

### Previous Story Intelligence (Story 3.1)

**Key learnings from Story 3.1:**
- Most failure handling was already implemented but scattered; 3.1 was primarily validation + gap-filling + testing
- Section 3.4 (Failure Context Construction) was the primary enhancement added
- 34 new bats tests added (3.1-1 through 3.1-34), total now 263
- Code review found an edge case: empty filter result when no failures match currentStage → guard added
- Test naming pattern: `@test "Failure 3.1-N: description"`
- No regressions on any existing tests
- Agent file (bmad-orchestrator.md) was modified with 22 new lines (Section 3.4)

**Pattern to follow for Story 3.2:**
- Add new section (6.5) to orchestrator agent, don't restructure existing sections
- Modify Section 7.1 to check reRouteOrigin before advancing stage
- Keep all existing section numbering intact
- Tests should validate agent documentation describes the behavior
- Use `@test "ReRoute 3.2-N: description"` naming pattern

### Git Intelligence

- Recent commits follow pattern: `feat: <description> (story X-Y)`
- Story 3.1 modified 4 files: orchestrator agent (+22 lines), story file (new), sprint-status, tests (+197 lines)
- Total tests: 263, all passing
- Orchestrator agent has been modified in stories 1-3, 1-4, 2-3, 2-4, 2-5, 2-7, 3-1

### Anti-Patterns to Avoid

- Modifying existing Section 6 retry logic (add Section 6.5 alongside it, don't merge)
- Breaking the Code-Review Failure Re-Routing pattern (that's intra-story, this is inter-stage)
- Making re-routing infinite (must count against maxRetries)
- Multi-line error messages in the failures array (single-line summaries only per architecture)
- Storing readiness report content in state.yaml (read it fresh from disk on each cold start)
- Writing directly to state.yaml (always temp-then-rename per Section 7.2)
- Changing existing bats tests (only add new ones)
- Breaking existing section numbering in bmad-orchestrator.md

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Add Section 6.5, modify Section 7.1
- `.bmad-orchestrator/templates/stage-readiness.md` — MODIFIED: Enhance Failure Recovery and Quality Gate sections
- `tests/orchestrator-agent.bats` — MODIFIED: Add ~20-30 re-routing tests
- No new files created
- All changes in existing files per architecture boundaries
- `reRouteOrigin` field added to state schema (camelCase, per convention)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.2] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 3] — Failure Recovery & Artifact Safety epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR24 maps to 3.2 (upstream stage identification), FR25 maps to 3.2 (re-routing with remediation)
- [Source: _bmad-output/planning-artifacts/architecture.md#Verification Pattern] — 5-step verification flow including quality gate
- [Source: _bmad-output/planning-artifacts/architecture.md#State File Schema] — failures array, currentRetries, maxRetries fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules] — Error messages single-line, atomic writes, camelCase YAML fields
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns] — Error message format and atomic write pattern
- [Source: _bmad-output/planning-artifacts/prd.md#FR24] — "Orchestrator can identify which upstream stage needs revision based on the failure report"
- [Source: _bmad-output/planning-artifacts/prd.md#FR25] — "Orchestrator can re-route to the appropriate stage with specific remediation instructions"
- [Source: _bmad-output/project-context.md#State File Rules] — Atomic writes, camelCase fields, single-line errors
- [Source: _bmad-output/project-context.md#Frozen Stage Identifiers] — Exact stage strings for re-routing targets
- [Source: _bmad-output/project-context.md#Verification Pattern] — Quality gate tri-state handling
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.3] — Quality Gate: FAIL triggers Section 5.5
- [Source: .claude/agents/bmad-orchestrator.md#Section 5.5] — On Verification Fail: current retry/terminal logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 6] — Failure Handling: failures array format, retry logic
- [Source: .claude/agents/bmad-orchestrator.md#Section 3.4] — Failure Context Construction: how {{failure_context}} is built
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.1] — Construct Updated State: where reRouteOrigin check must be added
- [Source: .claude/agents/bmad-orchestrator.md#Section 7.2] — Atomic Write pattern
- [Source: .claude/agents/bmad-orchestrator.md#Code-Review Failure Re-Routing] — Intra-story re-routing (different pattern, do not conflate)
- [Source: .claude/agents/bmad-orchestrator.md#Section 2 Pipeline Stage Sequences] — Full Method stage order for "earliest upstream" logic
- [Source: .bmad-orchestrator/templates/stage-readiness.md#Quality Gate Interpretation] — FAIL triggers failure handling, reference to upstream re-routing needed
- [Source: .bmad-orchestrator/templates/stage-readiness.md#Failure Recovery] — Already mentions "upstream re-routing feedback" — enhance this section
- [Source: _bmad-output/implementation-artifacts/3-1-stage-failure-detection-retry-logic.md] — Previous story patterns, 263 tests, Section 3.4 addition
- [Source: _bmad-output/implementation-artifacts/3-1-stage-failure-detection-retry-logic.md#Dev Notes] — Validation-focused story pattern, gap analysis approach
- [Source: tests/orchestrator-agent.bats] — 263 existing tests, naming patterns established

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

- 298/298 bats tests passing (35 new + 263 existing, zero regressions)
- 34/34 loop.bats tests passing

### Completion Notes List

- Added Section 6.5 "Upstream Re-Routing" to orchestrator agent (~40 lines) covering: trigger condition, upstream stage identification logic (PRD→prd, Architecture→architecture, Epics→epics-stories), re-route entry format with `reRoutedTo` field, `reRouteOrigin` state field, targeted remediation context construction, maxRetries enforcement, and failure chain readability
- Modified Section 7.1 to check `reRouteOrigin` before advancing stage: routes back to validation stage after upstream fix, clears `reRouteOrigin` on re-validation success
- Enhanced stage-readiness.md Failure Recovery section with upstream re-routing guidance and re-validation context
- Enhanced stage-readiness.md Quality Gate Interpretation to explain FAIL triggers upstream re-routing (Section 6.5 reference)
- Added 30 new bats tests (ReRoute 3.2-1 through 3.2-30) covering all 5 ACs
- Manual verification completed: traced full re-routing flow end-to-end through documentation
- Code review (adversarial) found 5 fixable issues, all resolved:
  - Added `reRouteOrigin` to Section 1.1 state field enumeration
  - Added explicit scoping in Section 6.5 trigger (readiness-only, not code-review)
  - Fixed `completedStages` duplicate avoidance during re-routing in Section 7.1
  - Fixed `currentRetries` reset carve-out during re-routing in Section 7.1
  - Removed orchestrator-internal `reRouteOrigin` reference from readiness template
- Added 5 code-review-fix tests (ReRoute 3.2-31 through 3.2-35), updated test 3.2-29

### Change Log

- 2026-02-03: Implemented upstream re-routing and remediation (Story 3.2)
- 2026-02-03: Code review fixes — 5 issues resolved, 5 new tests added (298 total)

### File List

- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added Section 6.5 (Upstream Re-Routing), modified Section 1.1 and 7.1 (reRouteOrigin)
- `.bmad-orchestrator/templates/stage-readiness.md` — MODIFIED — Enhanced Failure Recovery and Quality Gate Interpretation sections
- `tests/orchestrator-agent.bats` — MODIFIED — Added 35 new re-routing tests (3.2-1 through 3.2-35)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated
- `_bmad-output/implementation-artifacts/3-2-upstream-re-routing-remediation.md` — MODIFIED — Story file updated

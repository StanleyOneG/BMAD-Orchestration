# Story 4.3: Party Mode Integration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a solo developer,
I want the orchestrator to invoke brainstorming when it detects ambiguity or competing approaches,
so that autonomous runs benefit from multi-perspective analysis at critical decision points.

## Acceptance Criteria

1. **Given** the orchestrator is interacting with a sub-agent via Task tool resume
   **When** the sub-agent's output or the task description contains competing approaches or trade-offs (e.g., "should we use WebSockets or SSE?")
   **Then** the orchestrator detects this as a Party Mode trigger

2. **Given** the task scope spans multiple architectural domains
   **When** the orchestrator evaluates the sub-agent interaction
   **Then** it detects this as a Party Mode trigger

3. **Given** the task contains undefined or ambiguous technical terms
   **When** the orchestrator evaluates the sub-agent interaction
   **Then** it detects this as a Party Mode trigger

4. **Given** the task has unspecified elements that would normally benefit from human verification
   **When** running in autonomous mode with no human in the loop
   **Then** the orchestrator detects this as a Party Mode trigger (brainstorming substitutes for human input)

5. **Given** any FR31 trigger is detected
   **When** the orchestrator decides to invoke Party Mode
   **Then** it instructs the current sub-agent to invoke Party Mode for the specific question or decision point

6. **Given** Party Mode completes
   **When** the sub-agent returns with brainstorming results
   **Then** the orchestrator incorporates the results and continues the normal workflow interaction

## Tasks / Subtasks

- [x] Task 1: Audit existing Party Mode references in orchestrator agent (AC: #1-#6)
  - [x] 1.1: Review Section 4.2 (Act as Expert Human User) — confirm existing bullet: "Trigger Party Mode when you detect competing approaches, ambiguity, or trade-offs that benefit from multi-perspective brainstorming"
  - [x] 1.2: Review architecture document — confirm Party Mode ownership: orchestrator agent (not sub-agents). Mechanism: during back-and-forth, orchestrator judges whether brainstorming would help and instructs sub-agent to invoke Party Mode
  - [x] 1.3: Identify gaps: the existing Section 4.2 bullet is vague — it lacks concrete trigger criteria (FR31 a-d), invocation instructions, and result handling. This story formalizes these.

- [x] Task 2: Add formal Party Mode trigger detection to orchestrator agent (AC: #1, #2, #3, #4)
  - [x] 2.1: Add a new Section 4.4 "Party Mode Trigger Detection" to `.claude/agents/bmad-orchestrator.md` (after Section 4.3 Resume Pattern)
  - [x] 2.2: Define the four concrete trigger categories from FR31:
    - **Trigger A — Competing Approaches:** Sub-agent output presents alternatives, trade-offs, "should we use X or Y?", pros/cons comparisons, or explicitly asks the orchestrator to choose between options
    - **Trigger B — Multi-Domain Scope:** The task description or sub-agent interaction spans multiple architectural domains (e.g., frontend + backend + database, or authentication + authorization + API design) and a single-domain decision could create cross-domain conflicts
    - **Trigger C — Ambiguous Terms:** Sub-agent output or task description uses undefined, vague, or domain-specific technical terms that could be interpreted multiple ways (e.g., "real-time" without latency specification, "scalable" without defining scale targets)
    - **Trigger D — Unspecified Elements (Autonomous Only):** During `mode: autonomous`, the sub-agent asks a question or presents an element that would normally require human input/verification — since no human is in the loop, Party Mode brainstorming substitutes for that human input
  - [x] 2.3: Add clear judgment guidelines: triggers are NOT automatic — the orchestrator uses LLM judgment to assess whether the trigger is significant enough to warrant brainstorming. Minor trade-offs (e.g., "tabs vs spaces") do NOT warrant Party Mode. Only invoke when the decision has meaningful architectural, design, or implementation impact.
  - [x] 2.4: Add `mode: checkpoint` exception: when running in checkpoint mode, the orchestrator should prefer pausing at the gate to let the human decide rather than auto-invoking Party Mode. Trigger D specifically does NOT apply in checkpoint mode (the human IS in the loop). Triggers A-C still apply in checkpoint mode when they occur BETWEEN gates.

- [x] Task 3: Add Party Mode invocation mechanism to orchestrator agent (AC: #5)
  - [x] 3.1: In Section 4.4, add the invocation protocol: when a trigger is detected, the orchestrator's next resume message to the sub-agent should include a Party Mode instruction
  - [x] 3.2: Define the invocation format — the orchestrator tells the sub-agent: "Before proceeding, invoke Party Mode to brainstorm: [specific question or decision point]. Include perspectives from relevant BMAD agents (architect, analyst, PM, etc.). After Party Mode completes, incorporate the consensus into your response and continue."
  - [x] 3.3: CRITICAL: The orchestrator does NOT directly invoke Party Mode itself — it instructs the sub-agent to do so. The orchestrator remains the "expert human" and the sub-agent is the one with access to Party Mode. This aligns with the architecture boundary: orchestrator drives sub-agents, sub-agents execute workflows.
  - [x] 3.4: Add scope constraint: Party Mode should be invoked at most ONCE per sub-agent interaction to prevent brainstorming loops. If multiple triggers are detected, bundle them into a single Party Mode invocation with multiple questions.

- [x] Task 4: Add Party Mode result handling to orchestrator agent (AC: #6)
  - [x] 4.1: In Section 4.4, add result handling: after the sub-agent returns with Party Mode results, the orchestrator evaluates whether the brainstorming produced a clear consensus
  - [x] 4.2: If consensus is clear: the orchestrator acknowledges the result and continues the normal workflow interaction, letting the sub-agent proceed with the consensus approach
  - [x] 4.3: If consensus is unclear or conflicting: the orchestrator makes a judgment call as the expert human user, picks the approach that best aligns with the task description and existing architecture, and instructs the sub-agent to proceed with that choice
  - [x] 4.4: The orchestrator does NOT re-invoke Party Mode on the same decision — one round of brainstorming per decision point is sufficient

- [x] Task 5: Update Section 4.2 to cross-reference new Section 4.4 (AC: #1-#6)
  - [x] 5.1: Modify the existing Party Mode bullet in Section 4.2 to reference Section 4.4 for detailed trigger criteria and invocation protocol
  - [x] 5.2: Keep Section 4.2 concise — it's the high-level "how to act as expert human" guidance, while Section 4.4 has the detailed Party Mode mechanics

- [x] Task 6: Write bats tests for Party Mode integration (AC: #1, #2, #3, #4, #5, #6)
  - [x] 6.1: Add tests to `tests/orchestrator-agent.bats` validating Party Mode trigger detection:
    - Agent describes Trigger A: competing approaches detection
    - Agent describes Trigger B: multi-domain scope detection
    - Agent describes Trigger C: ambiguous terms detection
    - Agent describes Trigger D: unspecified elements in autonomous mode
    - Agent describes Trigger D exception: not applicable in checkpoint mode
  - [x] 6.2: Add tests validating Party Mode invocation mechanism:
    - Agent describes instructing sub-agent to invoke Party Mode (NOT invoking directly)
    - Agent describes specific question/decision point in invocation
    - Agent describes once-per-interaction limit on Party Mode
    - Agent describes bundling multiple triggers into single invocation
  - [x] 6.3: Add tests validating Party Mode result handling:
    - Agent describes evaluating brainstorming consensus
    - Agent describes continuing workflow after Party Mode results
    - Agent describes making judgment call when consensus is unclear
    - Agent describes no re-invocation on same decision
  - [x] 6.4: Add tests validating Party Mode judgment guidelines:
    - Agent describes LLM judgment for trigger significance
    - Agent describes Party Mode as non-automatic (judgment-based)
    - Agent describes meaningful impact threshold for invocation
  - [x] 6.5: Use test naming pattern: `@test "PartyMode 4.3-N: description"` for all tests
  - [x] 6.6: Verify all existing tests still pass (zero regressions on all 408 existing tests)

- [ ] Task 7: Manual verification (AC: #1, #2, #3, #4, #5, #6) -- MANUAL
  - [ ] 7.1: Trace the complete Party Mode trigger-to-invocation flow:
    - Orchestrator interacting with sub-agent via Task tool resume → sub-agent output contains competing approaches → orchestrator evaluates trigger significance → trigger is significant → orchestrator constructs Party Mode instruction → orchestrator resumes sub-agent with Party Mode instruction → sub-agent invokes Party Mode → brainstorming completes → sub-agent returns results → orchestrator evaluates consensus → orchestrator continues normal interaction
  - [ ] 7.2: Verify all four trigger categories are documented with clear examples
  - [ ] 7.3: Verify checkpoint mode exception for Trigger D
  - [ ] 7.4: Verify once-per-interaction limit prevents brainstorming loops
  - [ ] 7.5: Verify orchestrator does NOT directly invoke Party Mode (sub-agent does)

## Dev Notes

### Architecture Compliance

**This story modifies 2 source files and creates 0 new files:**
- `.claude/agents/bmad-orchestrator.md` — **MODIFIED** — Add Section 4.4 (Party Mode Trigger Detection), update Section 4.2 cross-reference
- `tests/orchestrator-agent.bats` — **MODIFIED** — Add ~20-30 new tests for Party Mode triggers, invocation, result handling, and judgment guidelines

**No new files created.** Story 4.3 formalizes the Party Mode integration that was already hinted at in Section 4.2 but lacked concrete trigger criteria and invocation mechanics.

### What Makes This Story UNIQUE

**Story 4.3 is the LAST story in Epic 4.** It adds intelligent brainstorming to the orchestrator's sub-agent interaction loop. Unlike Stories 4.1 and 4.2 (which added checkpoint gate mechanics — pausing, summaries, feedback, revision), Story 4.3 operates WITHIN the sub-agent interaction itself (Section 4.2-4.3 Resume Pattern).

**Key distinction from Stories 4.1/4.2:**
- Stories 4.1/4.2: modify the gate/exit/pause flow (Sections 7, 8, 1.2)
- Story 4.3: modifies the sub-agent interaction loop (Section 4) — completely different code path

**Party Mode is NOT a gate mechanism.** It's an inline brainstorming invocation during sub-agent back-and-forth. The orchestrator doesn't pause or exit — it instructs the sub-agent mid-conversation.

### Current Implementation — What Already Exists

**Section 4.2 (Act as Expert Human User) already contains:**
```
- **Trigger Party Mode** when you detect competing approaches, ambiguity, or trade-offs that benefit from multi-perspective brainstorming
```

**What's MISSING (the gaps this story fills):**
- No concrete trigger categories (FR31 defines 4 specific triggers — a, b, c, d)
- No judgment guidelines (when is a trigger "significant enough"?)
- No invocation protocol (HOW does the orchestrator tell the sub-agent to brainstorm?)
- No result handling (what happens AFTER Party Mode completes?)
- No checkpoint mode exception (Trigger D shouldn't apply when human IS in the loop)
- No once-per-interaction limit (prevent infinite brainstorming loops)
- No tests

### Critical Design Decision: Orchestrator Instructs, Sub-Agent Invokes

From the Architecture document:
> **Owner:** Orchestrator agent (not sub-agents)
> **Mechanism:** During back-and-forth with a sub-agent, the orchestrator judges whether brainstorming would benefit the current decision point and instructs the sub-agent to invoke Party Mode

This means:
- The orchestrator DETECTS triggers and DECIDES to invoke Party Mode
- The orchestrator INSTRUCTS the sub-agent to invoke Party Mode via its resume response
- The SUB-AGENT actually invokes Party Mode (it has access to the Party Mode workflow)
- The orchestrator does NOT directly run Party Mode — that would violate the boundary rules (Section 9)

**Why this matters for implementation:**
- No new tools or capabilities needed for the orchestrator
- The invocation is purely through the existing Task tool resume mechanism
- The orchestrator's resume message includes "invoke Party Mode for [question]"
- The sub-agent sees this as expert-user guidance and follows it

### Critical Design Decision: Judgment-Based, Not Rule-Based

Party Mode triggers are LLM judgment calls, NOT regex matching or keyword detection. The orchestrator reads the sub-agent's output and uses its understanding of the task, architecture, and current context to judge whether brainstorming would produce meaningfully better outcomes.

**This is intentional because:**
- Sub-agent output is natural language — keyword matching would be brittle
- Context matters: "WebSockets vs SSE" might be trivial for a chat app but critical for a real-time dashboard
- The orchestrator is already making expert judgment calls throughout Section 4.2 — Party Mode detection is another judgment in the same category

### Critical Design Decision: Once Per Interaction Limit

Party Mode is invoked at most ONCE per sub-agent interaction (one complete pipeline stage). This prevents:
- Brainstorming loops where every sub-agent response triggers more brainstorming
- Context window bloat from multiple Party Mode sessions within a single Ralph Loop iteration
- Diminishing returns from over-brainstorming

If multiple triggers are detected, they should be bundled into a single Party Mode invocation with multiple questions.

### Interaction with Previous Stories (4.1 and 4.2)

**Story 4.1 (Checkpoint Gate Pausing):**
- Added Section 8.1 (Checkpoint Summary Generation)
- Added gate-based pausing and resume
- Story 4.3 adds Trigger D exception: in checkpoint mode, human is in the loop, so Trigger D doesn't apply

**Story 4.2 (Checkpoint Feedback & Revision):**
- Added `--feedback` flag and stage rewinding
- Story 4.3 is independent — Party Mode is inline during sub-agent interaction, not related to gates or feedback

**No conflicts:** Stories 4.1/4.2 modify Sections 1.2, 7, 8. Story 4.3 modifies Section 4 only.

### Previous Story Intelligence (Story 4.2)

**Key learnings from Story 4.2:**
- 31 new tests added, total went from 377 to 408
- Test naming: `@test "Feedback 4.2-N: description"` — Story 4.3 uses `@test "PartyMode 4.3-N: description"`
- Code review found 4 issues: consolidated atomic writes, strengthened test assertions, differentiated duplicate tests, tightened regex
- Checkpoint feedback stored in `checkpointFeedback` state field — not related to Party Mode
- Section 1.2 point 3 now has revision and approval flows — Party Mode is unrelated

**Patterns to follow:**
- Validate existing Party Mode reference before adding new content
- Add new subsection (Section 4.4) rather than expanding Section 4.2 excessively
- Tests should validate agent documentation describes the behavior (bats tests grep the agent file)
- Expect ~20-30 new tests

### Git Intelligence

- Recent commit: `feat: add checkpoint feedback and revision (story 4-2)`
- Commit pattern: `feat: <description> (story X-Y)`
- Total tests: 408, all passing
- Files modified in 4.2: orchestrator agent, slash command, tests
- Orchestrator agent was last modified in Story 4.2 (checkpoint feedback revision logic in Section 1.2)
- Section 4 (Sub-Agent Interaction) has NOT been modified since Story 2.5

### Anti-Patterns to Avoid

- Adding Party Mode as a gate mechanism (it's inline during sub-agent interaction, not a pause/exit flow)
- Making the orchestrator invoke Party Mode directly (it INSTRUCTS the sub-agent to do so)
- Keyword/regex-based trigger detection (use LLM judgment)
- Allowing multiple Party Mode invocations per interaction (once per interaction limit)
- Modifying Sections 7, 8, or 1.2 (those are gate/exit/pause mechanics — Party Mode is Section 4 only)
- Adding Party Mode state to `state.yaml` (Party Mode is transient within a single Ralph Loop iteration — no state persistence needed)
- Applying Trigger D in checkpoint mode (the human IS in the loop, so the exception applies)
- Breaking existing test patterns or renumbering existing tests
- Over-engineering trigger detection with structured rules — keep it judgment-based per the architecture

### Project Structure Notes

- `.claude/agents/bmad-orchestrator.md` — MODIFIED: Add Section 4.4 (Party Mode Trigger Detection), update Section 4.2 cross-reference
- `tests/orchestrator-agent.bats` — MODIFIED: Add ~20-30 new tests for Party Mode triggers, invocation, result handling, judgment guidelines
- No changes to `.claude/commands/bmad-orchestrate.md` (no new flags or slash command changes)
- No changes to `.bmad-orchestrator/loop.sh` (Party Mode is inline, no new exit codes or loop behavior)
- No new files created
- All changes in existing files per architecture boundaries

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3] — Full acceptance criteria and story definition
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4] — Checkpoint Mode & Party Mode epic context
- [Source: _bmad-output/planning-artifacts/epics.md#FR Coverage Map] — FR31 maps to 4.3 (brainstorming trigger detection), FR32 maps to 4.3 (Party Mode invocation)
- [Source: _bmad-output/planning-artifacts/prd.md#FR31] — "Orchestrator can detect when a task would benefit from brainstorming based on concrete triggers: (a) competing approaches, (b) multi-domain scope, (c) ambiguous terms, (d) unspecified elements needing human verification"
- [Source: _bmad-output/planning-artifacts/prd.md#FR32] — "Orchestrator can invoke Party Mode internally as part of the pipeline when any FR31 trigger is detected"
- [Source: _bmad-output/planning-artifacts/prd.md#Journey 1] — Autonomous happy path mentions Party Mode: "Detects the batching strategy could benefit from brainstorming, runs Party Mode internally"
- [Source: _bmad-output/planning-artifacts/architecture.md#Party Mode Triggering] — Owner: orchestrator agent. Mechanism: during back-and-forth, instructs sub-agent. Triggers from PRD FR31.
- [Source: _bmad-output/planning-artifacts/architecture.md#Agent Communication Pattern] — "Party Mode triggered by orchestrator during back-and-forth when it judges brainstorming would help"
- [Source: _bmad-output/planning-artifacts/architecture.md#Prompt Templates] — Each template includes "Permission for Party Mode invocation"
- [Source: _bmad-output/project-context.md#Agent Communication Pattern] — "One Ralph Loop iteration = one complete pipeline stage with all back-and-forth"
- [Source: _bmad-output/project-context.md#Boundary Rules] — "Sub-agents produce artifacts through their own workflows — the orchestrator never bypasses them"
- [Source: .claude/agents/bmad-orchestrator.md#Section 4.2] — Existing Party Mode bullet: "Trigger Party Mode when you detect competing approaches, ambiguity, or trade-offs"
- [Source: .claude/agents/bmad-orchestrator.md#Section 4.3] — Resume Pattern: launch → read output → respond → resume → repeat
- [Source: .claude/agents/bmad-orchestrator.md#Section 9] — Boundary Rules: sub-agent IDs are transient, orchestrator never directly writes BMAD artifacts
- [Source: _bmad-output/implementation-artifacts/4-2-checkpoint-feedback-revision.md] — Previous story: 408 tests, checkpoint revision, Section 4 unmodified
- [Source: _bmad-output/implementation-artifacts/4-1-checkpoint-gate-pausing-approval.md] — Story 4.1: 377 tests, gate logic in Section 8

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

### Completion Notes List

- Task 1: Audited existing Party Mode reference in Section 4.2 (line 354). Confirmed single vague bullet. Architecture confirms orchestrator-owns, sub-agent-invokes pattern. Gaps: no FR31 triggers, no judgment guidelines, no invocation protocol, no result handling, no checkpoint exception, no loop prevention.
- Tasks 2-4: Added Section 4.4 "Party Mode Trigger Detection" to `.claude/agents/bmad-orchestrator.md` with: 4 trigger categories (A-D), judgment guidelines, checkpoint mode exception, invocation protocol (orchestrator instructs sub-agent), once-per-interaction limit, result handling (clear consensus vs. judgment call), no re-invocation rule.
- Task 5: Updated Section 4.2 Party Mode bullet to cross-reference Section 4.4 for detailed trigger criteria and invocation protocol. Section 4.2 remains concise.
- Task 6: Added 30 new bats tests (PartyMode 4.3-1 through 4.3-30) covering all trigger categories, invocation mechanism, result handling, judgment guidelines, section structure, and cross-references. All 438 tests pass (408 existing + 30 new). Zero regressions.
- Task 7: MANUAL — left unchecked per story convention.
- Code Review: Fixed 4 MEDIUM issues (M1: overly broad regex in 4.3-21, M2: false-positive risk in 4.3-4, M3: differentiated near-duplicate 4.3-20/4.3-28, M4: noted unscoped grep as accepted pattern). Fixed 2 LOW issues (L1: doc count "1 file" → "2 source files", L2: added test 4.3-31 for non-trigger example). Total: 439 tests, 0 failures.

### Change Log

- 2026-02-04: Implemented Party Mode integration (Story 4.3) — added Section 4.4, updated Section 4.2 cross-reference, added 30 tests
- 2026-02-04: Code review fixes — tightened 4 test regexes (M1-M3), added test 4.3-31 (L2), fixed doc count (L1). 439 tests, 0 failures.

### File List

- `.claude/agents/bmad-orchestrator.md` — MODIFIED — Added Section 4.4 (Party Mode Trigger Detection), updated Section 4.2 cross-reference
- `tests/orchestrator-agent.bats` — MODIFIED — Added 31 PartyMode 4.3-N tests (tests 409-439), including review fixes
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED — Story status updated to review
- `_bmad-output/implementation-artifacts/4-3-party-mode-integration.md` — MODIFIED — Tasks marked complete, Dev Agent Record populated

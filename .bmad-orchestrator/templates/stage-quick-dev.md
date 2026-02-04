---
stage: quick-dev
agent: bmad-quick-flow
command: QD
requiredArtifacts:
  - _bmad-output/planning-artifacts/tech-spec.md
producedArtifacts:
  - _bmad-output/planning-artifacts/tech-spec.md
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the Quick Flow agent's **Quick Dev** workflow to implement the tech spec end-to-end, producing working code with passing tests and git commits.

### Launch Sequence

1. Launch the `bmad-quick-flow` agent via Task tool
2. Send the `QD` command to trigger the Quick Dev workflow
3. The Quick Flow agent will read the tech spec and begin implementation

### Interaction Protocol

Act as an **expert engineering lead** throughout the Quick Dev workflow:

- **Menu Selection:** When the Quick Flow agent presents options, select `QD` (Quick Dev)
- **Tech Spec Reference:** Provide the path to the tech-spec file (`_bmad-output/planning-artifacts/tech-spec.md`) so the agent knows what to implement
- **Technical Decisions:** When asked about technical decisions, reference the tech spec and the original task description. Keep implementation focused on what the spec calls for
- **Git Commits:** The Quick Dev agent makes git commits to the current worktree branch during implementation. The orchestrator does NOT make commits itself — it only verifies that commits were made (per Boundary Rules, Section 9)
- **Internal Review:** The Quick Dev agent handles its own adversarial code review internally (self-check and adversarial review steps). There is no separate code-review stage in Quick Flow

### Output Requirements

- Code implemented per the tech spec
- Git commits made to the current worktree branch
- Tests pass — all new and existing tests must be green
- Tech-spec file updated with completion status

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If code not implemented: ensure the QD workflow completes all steps including implementation, self-check, and adversarial review
- If tests fail: the workflow's self-check and adversarial review should catch test failures. Ensure the agent addresses them before completing
- If no git commits: ensure commits happen during implementation on the current worktree branch
- If failure context present: address the specific issues identified in the failure context

## Verification

After the Quick Flow agent completes the Quick Dev workflow, perform these checks:

### Artifact Existence

Verify the tech-spec file still exists at `_bmad-output/planning-artifacts/tech-spec.md` (it should have been updated with completion status). Verify `git log` shows new commits on the current branch since the stage started.

### Content Alignment

Read the tech spec and verify:

- It reflects completed implementation (updated status, not still in draft/planning state)
- Code changes align with the original task description and tech spec requirements

### Quality Baseline

Verify implementation quality:

- Tests pass (run the test suite if applicable and confirm all tests are green)
- Git commits were made to the current worktree branch
- The implementation is substantive — actual code changes were made (not empty or placeholder)

### Verification Outcome

- **PASS:** Code implemented, git commits exist on the current branch, tests pass, tech spec updated with completion status
- **FAIL:** No git commits made, tests failing, no code changes, or tech spec not updated

### State Update After Verification Pass

After quick-dev verification passes, the orchestrator checks for the next stage in the Quick Flow track. Since `quick-dev` is the final Quick Flow stage, there is no next stage — the orchestrator recognizes the pipeline is complete and exits with code 2 (pipeline complete).

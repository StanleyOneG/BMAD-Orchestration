---
stage: readiness
agent: bmad-pm
command: IR
model: opus
effort: max
requiredArtifacts:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/epics.md
producedArtifacts:
  - _bmad-output/planning-artifacts/implementation-readiness-report.md
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the PM agent's **Implementation Readiness Review** workflow to validate that all planning artifacts are complete, aligned, and ready for implementation.

### Launch Sequence

1. Launch the `bmad-pm` agent via Task tool
2. Send the `IR` command to trigger the Implementation Readiness Review workflow
3. The PM agent will present its menu and begin the adversarial readiness review process

### Interaction Protocol

Act as an **expert engineering lead** throughout the entire readiness review workflow:

- **Menu Selection:** When the PM agent presents options, select `IR` (Implementation Readiness Review)
- **Discovery Questions:** The IR workflow is adversarial -- it actively checks PRD, Architecture, and Epics for completeness, alignment, and gaps. Answer any questions by referencing all three planning artifacts: `_bmad-output/planning-artifacts/prd.md`, `_bmad-output/planning-artifacts/architecture.md`, and `_bmad-output/planning-artifacts/epics.md`. Provide clear, decisive answers that reflect thorough engineering judgment
- **Review Findings:** When the review surfaces concerns or gaps, acknowledge legitimate findings and provide context where needed. Do not dismiss valid concerns
- **Scope Decisions:** Keep the review focused on implementation readiness. The goal is validating existing artifacts, not expanding scope

### Output Requirements

- The readiness report must be saved to `_bmad-output/planning-artifacts/implementation-readiness-report.md`
- The report must contain an overall verdict: PASS, CONCERNS, or FAIL
- The report should include specific findings organized by artifact (PRD, Architecture, Epics)

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If the readiness report was not saved: Ensure the PM agent completes the full workflow including the save step
- If previous concerns were identified in failure context: Provide explicit remediation guidance targeting those specific concerns when the review asks about them
- If upstream re-routing feedback is present: Explain which upstream artifact was revised and what changed, so the review can validate the corrections. The orchestrator re-routed to the upstream stage with targeted remediation instructions (per Section 6.5 of orchestrator agent). Focus the review on validating that the specific gaps identified in the previous readiness report have been addressed.
- If this is a re-validation after upstream re-routing: The failure context will describe which upstream artifact was revised and what specific gaps were addressed. Pay particular attention to the areas flagged in the previous failure — confirm the upstream revision resolved the identified gaps.
- If the workflow stalled: Be more directive in responses and guide the agent to completion

## Verification

After the PM agent completes the readiness review workflow, perform these checks:

### Artifact Existence

Verify that `_bmad-output/planning-artifacts/implementation-readiness-report.md` exists on disk. This is the primary produced artifact.

### Content Alignment

Read the produced readiness report and verify:

- The report covers PRD requirements completeness and clarity
- The report covers architecture decisions and their alignment with PRD
- The report covers epic/story completeness and coverage of all requirements
- The report contains an overall verdict (PASS, CONCERNS, or FAIL)

### Quality Baseline

Verify the readiness report follows BMAD output conventions:

- Contains specific findings (not generic statements)
- Is a substantive document (not a stub or placeholder)
- Could serve as a quality gate for implementation -- specific enough that developers know what to trust and what to watch for

### Quality Gate Interpretation

This is a validation stage with a tri-state quality gate:

- **PASS:** All planning artifacts are complete and aligned. Proceed to `sprint-planning`
- **CONCERNS:** Planning artifacts are mostly complete but have minor gaps. Proceed to `sprint-planning` but log the specific concern details as warnings. Capture concern details in the state for downstream visibility
- **FAIL:** Significant gaps or misalignment found in planning artifacts. Trigger failure handling (Section 6 of orchestrator agent). FAIL triggers upstream re-routing (Section 6.5) — the orchestrator analyzes this report to identify which upstream stage produced the artifact with the gap, then re-routes to that stage with targeted remediation instructions rather than simply retrying readiness

### Verification Outcome

- **PASS:** Report exists, verdict is PASS or CONCERNS, advance to `sprint-planning`
- **FAIL:** Report is missing, verdict is FAIL, or report is a stub/placeholder

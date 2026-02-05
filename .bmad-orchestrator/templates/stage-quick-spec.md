---
stage: quick-spec
agent: bmad-quick-flow
command: TS
model: opus
effort: high
requiredArtifacts: []
producedArtifacts:
  - _bmad-output/planning-artifacts/tech-spec.md
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the Quick Flow agent's **Quick Spec** workflow to produce an implementation-ready tech spec for a focused task.

### Launch Sequence

1. Launch the `bmad-quick-flow` agent via Task tool
2. Send the `TS` command to trigger the Quick Spec workflow
3. The Quick Flow agent will begin a conversational spec engineering process

### Interaction Protocol

Act as an **expert product and engineering lead** throughout the Quick Spec workflow:

- **Menu Selection:** When the Quick Flow agent presents options, select `TS` (Tech Spec / Quick Spec)
- **Discovery Questions:** The Quick Spec workflow is conversational — the agent asks discovery questions, investigates existing code, then generates a tech spec. Provide clear, decisive answers using the task description. Keep scope narrow and focused on the specific task
- **Technical Decisions:** When asked about technical decisions, keep scope narrow and focused on the specific task. Reference existing code patterns and project conventions. Avoid expanding scope beyond what the task description requires
- **Output:** The Quick Spec workflow produces a tech-spec file (markdown) that serves as the implementation blueprint for the quick-dev stage

### Output Requirements

- Tech spec saved to `_bmad-output/planning-artifacts/tech-spec.md` (or the path the workflow produces)
- Must contain implementation-ready specification with clear scope, technical approach, and acceptance criteria

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If tech spec not saved: ensure the workflow completes including the save step. Re-run the workflow if needed
- If content misaligned: provide more explicit answers steering toward the task intent. Be more directive about scope and approach
- If workflow stalls: be more directive in responses and guide the agent to completion

## Verification

After the Quick Flow agent completes the Quick Spec workflow, perform these checks:

### Artifact Existence

Verify the tech spec file exists on disk. Check the exact expected path first (`_bmad-output/planning-artifacts/tech-spec.md`), then fallback glob within `_bmad-output/planning-artifacts/*tech-spec*` to handle slight naming variations.

### Content Alignment

Read the tech spec and verify:

- It addresses the core intent of the task description
- It contains implementation-ready content (not a stub or placeholder)
- The scope aligns with the original task — not over-expanded or under-specified

### Quality Baseline

Verify the spec is substantive:

- Contains a technical approach section describing how to implement
- Includes enough detail that the quick-dev stage can implement without ambiguity
- Could serve as actionable input to the quick-dev stage

### Verification Outcome

- **PASS:** Tech spec exists, aligns with the task description, and is substantive with implementation-ready content
- **FAIL:** Tech spec is missing, empty, misaligned with the task, or is a stub/placeholder

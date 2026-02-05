---
stage: sprint-planning
agent: bmad-sm
command: SP
model: opus
effort: medium
requiredArtifacts:
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/architecture.md
producedArtifacts:
  - _bmad-output/implementation-artifacts/sprint-status.yaml
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the SM agent's **Sprint Planning** workflow to analyze all epic files and generate a comprehensive sprint status tracking file.

### Launch Sequence

1. Launch the `bmad-sm` agent via Task tool
2. Send the `SP` command to trigger the Sprint Planning workflow
3. The SM agent will present its menu and begin the sprint planning process

### Interaction Protocol

Act as an **expert engineering lead** throughout the sprint planning workflow:

- **Menu Selection:** When the SM agent presents options, select `SP` (Sprint Planning)
- **Epic Analysis:** The SM agent will analyze the epic files and extract all epics and stories. Reference `_bmad-output/planning-artifacts/epics.md` and `_bmad-output/planning-artifacts/architecture.md` for context on priority order, epic sequencing, and story dependencies
- **Priority Decisions:** When asked about priority order or sequencing, make decisive engineering judgments based on dependency chains, risk, and value delivery. Earlier epics should deliver foundational capabilities that later epics build upon
- **Story Dependencies:** Identify and communicate cross-epic dependencies that affect story ordering within sprints
- **Scope Decisions:** Keep planning focused on organizing and sequencing existing stories from the epic files. Do not expand scope or add new stories during sprint planning

### Output Requirements

- Sprint status saved to `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Must contain all epics and stories extracted from the epic files
- Each epic must have a status field for tracking progress
- Each story must have a status field for tracking progress
- The sprint status file must have valid YAML structure suitable for the story loop implementation phase

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If sprint-status not saved: Ensure the SM agent completes the full workflow including the save step. Verify the file is written to `_bmad-output/implementation-artifacts/sprint-status.yaml`
- If previous failure context is present: Address the specific issues identified in the failure context when interacting with the SM agent
- If stale data: Regenerate the sprint status from the current epic files to ensure all epics and stories are represented
- If the workflow stalled: Be more directive in responses and guide the agent to completion

## Verification

After the SM agent completes the sprint planning workflow, perform these checks:

### Artifact Existence

Verify that `_bmad-output/implementation-artifacts/sprint-status.yaml` exists on disk. This is the primary produced artifact.

### Content Alignment

Read the produced sprint status file and verify:

- The file contains all epics from the epic files
- Each epic has a status field
- The file contains all stories from within each epic
- Each story has a status field
- The epic and story identifiers match those found in the source epic files

### Quality Baseline

Verify the sprint status file meets quality standards:

- Contains valid YAML structure (not malformed or truncated)
- Is substantive content (not empty, stub, or placeholder)
- Contains proper status tracking fields for both epics and stories
- Could serve as a tracking file for the story loop implementation phase — specific enough that the orchestrator can iterate through epics and stories in order

### Verification Outcome

- **PASS:** Sprint status exists on disk, contains all epics and stories from the epic files, has valid YAML structure with status fields for every entry
- **FAIL:** File is missing, empty, has invalid YAML, or is missing epics/stories that exist in the epic files

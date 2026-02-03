---
stage: create-story
agent: bmad-sm
command: CS
requiredArtifacts:
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/implementation-artifacts/sprint-status.yaml
producedArtifacts:
  - _bmad-output/implementation-artifacts/{{story_key}}.md
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the SM agent's **Create Story** workflow to produce a comprehensive, implementation-ready story file for the current story in the story loop.

### Launch Sequence

1. Launch the `bmad-sm` agent via Task tool
2. Send the `CS` command to trigger the Create Story workflow
3. The SM agent will present its menu and begin the story creation process

### Interaction Protocol

Act as an **expert engineering lead** throughout the create story workflow:

- **Menu Selection:** When the SM agent presents options, select `CS` (Create Story)
- **Story Identification:** Provide the specific story key (e.g., `2-4-story-loop-iteration-create-story-template`) so the SM agent knows WHICH story to create. The story key is injected by the orchestrator from the current `storyLoop` entry
- **Context Provision:** The SM agent will analyze the epics file, identify the target story from `sprint-status.yaml`, and create a comprehensive story file with acceptance criteria, tasks, dev notes, and references. Reference `_bmad-output/planning-artifacts/epics.md` for story requirements and `_bmad-output/planning-artifacts/architecture.md` for technical context
- **Technical Decisions:** When asked about technical context, reference architecture decisions, previous story files in `_bmad-output/implementation-artifacts/`, and `_bmad-output/project-context.md` for coding standards and patterns
- **YOLO Mode:** When offered the option to enter YOLO mode (typically presented as `[y] YOLO`), select it to drive the workflow to completion autonomously
- **Scope Decisions:** Keep story creation focused on the specific story from the epics file. Do not expand scope or merge stories

### Output Requirements

- Story file saved to `_bmad-output/implementation-artifacts/{{story_key}}.md`
- Must contain acceptance criteria derived from the epics file
- Must contain tasks/subtasks breakdown for implementation
- Must contain dev notes with architecture compliance guidance and references
- Must be substantive and actionable — not a stub or placeholder

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If story file not saved: Ensure the SM agent completes the full workflow including the save step. Verify the file is written to `_bmad-output/implementation-artifacts/{{story_key}}.md`
- If previous failure context is present: Address the specific issues identified in the failure context when interacting with the SM agent
- If wrong story created: Provide the correct story key explicitly so the SM agent targets the right story from the epics file
- If story is missing sections: Ensure the SM agent includes acceptance criteria, tasks/subtasks, dev notes, and references in the output

## Verification

After the SM agent completes the create story workflow, perform these checks:

### Artifact Existence

Verify that the story file exists at the expected path: `_bmad-output/implementation-artifacts/{{story_key}}.md`. This is the primary produced artifact.

### Content Alignment

Read the produced story file and verify:

- The file contains the correct story ID matching the target story from the epics file
- The file contains acceptance criteria that align with the story definition in the epics file
- The file contains a tasks/subtasks breakdown for implementation
- The file contains a dev notes section with architecture compliance guidance

### Quality Baseline

Verify the story file meets quality standards:

- Contains substantive content (not empty, stub, or placeholder)
- Contains actionable tasks that a developer can execute
- Contains architecture compliance notes referencing relevant architectural decisions
- Acceptance criteria are specific and testable

### Verification Outcome

- **PASS:** Story file exists at the expected path, contains the correct story with acceptance criteria, tasks/subtasks, dev notes, and is substantive and actionable
- **FAIL:** File is missing, empty, contains the wrong story, or is missing acceptance criteria, tasks, or dev notes

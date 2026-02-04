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

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the Dev agent's **Dev Story** workflow to implement all tasks in the current story, write tests, make git commits, and update the story file with completion records.

### Launch Sequence

1. Launch the `bmad-dev` agent via Task tool
2. Send the `DS` command to trigger the Dev Story workflow
3. The Dev agent will present its menu and begin the story implementation process

### Interaction Protocol

Act as an **expert engineering lead** throughout the dev story workflow:

- **Menu Selection:** When the Dev agent presents options, select `DS` (Dev Story)
- **Story Identification:** Provide the specific story key (e.g., `2-5-dev-story-code-review-templates-with-git-commits`) so the Dev agent knows WHICH story to implement. The story key is injected by the orchestrator from the current `storyLoop` entry
- **Context Provision:** The Dev agent will read the story file, implement all tasks/subtasks, write tests, and make git commits. Reference `_bmad-output/planning-artifacts/architecture.md` for architectural decisions and `_bmad-output/project-context.md` for bash standards, naming conventions, and anti-patterns
- **Technical Decisions:** When asked about technical decisions, reference architecture.md, project-context.md, and previous story files in `_bmad-output/implementation-artifacts/` for established patterns
- **Git Commits:** The Dev agent makes git commits to the current worktree branch during implementation. The orchestrator does NOT make commits itself — it only verifies that commits were made (per Boundary Rules, Section 9). Ensure the Dev agent references project-context.md for bash standards, naming conventions, and anti-patterns

### Output Requirements

- Story file updated in-place at `_bmad-output/implementation-artifacts/{{story_key}}.md` with task checkboxes checked, Dev Agent Record populated (agent model, completion notes, file list)
- Git commits made to the current worktree branch during implementation
- Tests pass — all new and existing tests must be green

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If code review feedback injected via failure context: Address the specific issues identified by the code reviewer. The Dev agent should fix the flagged problems and re-run tests
- If tests don't pass: Fix failing tests before marking tasks complete. Ensure all existing tests still pass (zero regressions)
- If no git commits: Ensure the Dev agent makes commits during implementation. Verify commits happen on the current worktree branch
- If story file not updated: Ensure the Dev agent marks tasks complete with [x] and populates the Dev Agent Record section with agent model, completion notes, and file list

## Verification

After the Dev agent completes the dev story workflow, perform these checks:

### Artifact Existence

Verify that the story file exists at the expected path: `_bmad-output/implementation-artifacts/{{story_key}}.md`. The story file should already exist from the create-story phase — this stage updates it in-place. Verify that `git log` shows new commits on the current branch since the dev-story stage started.

### Content Alignment

Read the produced story file and verify:

- Task checkboxes are checked (marked with `[x]`)
- Dev Agent Record section is populated with agent model, completion notes, and file list
- The implementation aligns with the story's acceptance criteria and task descriptions

### Quality Baseline

Verify the implementation meets quality standards:

- Tests pass — run the test suite if applicable and confirm all tests are green
- Git commits were made to the current worktree branch during implementation
- Story file is substantive — tasks are checked, completion notes are present, file list documents all changed files

### Verification Outcome

- **PASS:** Story file updated with checked tasks and populated Dev Agent Record, git commits exist on the current branch, tests pass
- **FAIL:** No git commits made, tests failing, story file not updated, or tasks not checked

### State Update After Verification Pass

After dev-story verification passes, the orchestrator updates state (Section 7.2 atomic write):

- Update the story's `phase` to `code-review` (next phase in the story lifecycle)
- Update the story's `status` to `implemented`
- `currentStage` remains at the story-level stage — the `storyLoop` object tracks which specific story is active

---
stage: code-review
agent: bmad-dev
command: CR
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

You are driving the Dev agent's **Code Review** workflow to perform an adversarial review of the implemented story code, ensuring quality, correctness, and architecture compliance.

### Launch Sequence

1. Launch a **NEW, FRESH** `bmad-dev` sub-agent via Task tool — this MUST be a separate Task tool invocation from the dev-story agent, creating a **clean context window** with zero carry-over from the implementation phase
2. Do NOT resume or reuse the dev-story sub-agent ID. The reviewer must approach the code with no prior assumptions or biases from writing it
3. Send the `CR` command to trigger the Code Review workflow
4. The Dev agent will present its menu and begin the adversarial code review process

### Interaction Protocol

Act as an **expert engineering lead** throughout the code review workflow:

- **Menu Selection:** When the Dev agent presents options, select `CR` (Code Review)
- **CRITICAL — Clean Context Window:** The code review agent operates with a clean context window — it has NOT seen the dev-story implementation conversation. This is by design: the reviewer must independently assess the code from disk artifacts alone, preventing confirmation bias. Sub-agent IDs are transient (per Section 9) and the code-review agent must approach code cold from disk artifacts and git diffs only, ensuring genuine adversarial review without confirmation bias from the implementation conversation
- **Story Identification:** Provide the specific story key so the review agent knows WHICH story to review
- **Git Diff Context:** Provide the `git diff` of commits made during the dev-story phase so the reviewer can see exactly what changed. Use the `devStoryStartCommit` hash from `state.yaml` (recorded before dev-story launched) to compute the diff: `git diff <devStoryStartCommit>..HEAD`. If `devStoryStartCommit` is absent, fall back to `git log --since=<updatedAt>` to approximate the commit range. This helps the reviewer focus on the actual changes rather than scanning the entire codebase
- **Review Expectations:** The code review agent performs an ADVERSARIAL review that finds specific problems: code quality, test coverage, architecture compliance, security, performance. When issues are found, collect the feedback for potential injection into `{{failure_context}}` on dev-story retry
- **YOLO Mode:** When offered the option to enter YOLO mode (typically presented as `[y] YOLO`), select it to drive the workflow to completion autonomously
- **LLM Selection:** A different LLM is recommended for fresh perspective but not required by the architecture. However, a fresh context window is mandatory

### Output Requirements

- Code review result captured with a clear verdict (PASS, CONCERNS, or FAIL)
- If issues found, the specific issues are available for injection into `{{failure_context}}` on dev-story retry
- Story file may be updated with review notes in the Senior Developer Review section

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If review stalls: Use YOLO mode earlier to push through interaction-heavy sections
- If review finds issues: This is NOT a recovery failure — it means dev-story needs to re-run with the review feedback. Capture the specific issues for `{{failure_context}}` injection
- If review produces no output: Ensure the workflow completes with a clear verdict (PASS, CONCERNS, or FAIL)

## Verification

After the Dev agent completes the code review workflow, perform these checks:

### Artifact Existence

Verify that the story file still exists at the expected path: `_bmad-output/implementation-artifacts/{{story_key}}.md`. The story file should not have been deleted during review.

### Content Alignment

Read the story file or review output. Determine if the code review produced a clear verdict:

- Check for a PASS, CONCERNS, or FAIL determination
- If review notes were added to the story file, verify they contain specific findings (not generic statements)

### Quality Gate Interpretation

This is a validation stage with a tri-state quality gate:

- **PASS:** Code review found no blocking issues. Story is complete. Set story `status` to `completed` in storyLoop, clear the story's `phase` (set to `null` or remove). Advance to the next story in the story loop (or complete the epic if all stories are done)
- **CONCERNS:** Code review found minor issues but nothing blocking. Proceed with PASS but log concern details in the status report entry (Section 7.3) with outcome `PASS (CONCERNS)` and the concern summary in the Details field. Set story `status` to `completed`
- **FAIL:** Code review found blocking issues. Capture the specific issues in the failure error summary. The orchestrator re-routes back to `dev-story` phase for this story (NOT standard upstream re-routing — stays on same story, reverts phase to `dev-story`) with review feedback injected into `{{failure_context}}`. The story's `status` stays as `implemented`

### Verification Outcome

- **PASS:** Review completed with PASS or CONCERNS verdict, story marked completed, phase cleared
- **FAIL:** Review found blocking issues (FAIL verdict), or review output is missing/empty

### State Update After Verification

**On PASS/CONCERNS:** After code-review verification passes, the orchestrator updates state (Section 7.2 atomic write):

- Update the story's `status` to `completed`
- Clear the story's `phase` (set to `null` or remove)
- Move to the next story in the story loop (or complete the epic if all stories are done)

**On FAIL:** The orchestrator re-routes within the same story's phase cycle:

- Revert the story's `phase` back to `dev-story` (NOT standard upstream re-routing)
- The story's `status` stays as `implemented`
- Inject the review feedback into `{{failure_context}}` for the dev-story retry
- On next Ralph Loop iteration, the orchestrator sees `phase: dev-story` and loads `stage-dev-story.md` with the review feedback

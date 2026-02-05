---
stage: task-report
agent: bmad-orchestrator
command: generate-task-report
model: opus
effort: medium
requiredArtifacts:
  - .bmad-orchestrator/state.yaml
  - .bmad-orchestrator/status-report.md
producedArtifacts:
  - .bmad-orchestrator/task-report.md
---

## Context Injection

{{task_description}}

{{failure_context}}

{{mode_instructions}}

## Stage Instructions

You are generating a **human-readable knowledge transfer document** that helps the developer understand what was built during this autonomous pipeline run, why key decisions were made, and anything noteworthy about the work produced.

### Data Collection

1. **Read ALL files in `_bmad-output/`** — glob for `*.md`, `*.yaml`, `*.yml` across both `planning-artifacts/` and `implementation-artifacts/` subdirectories. Read complete contents of every file, not just existence checks.
2. **Read `.bmad-orchestrator/state.yaml`** for pipeline metadata: task description, route, mode, completedStages, storyLoop progress, and any failure/retry history.
3. **Read `.bmad-orchestrator/status-report.md`** for stage-by-stage outcomes, timing, and any concerns or re-routing that occurred.

### Report Synthesis

Using all collected context, synthesize a comprehensive task report with these 5 required sections:

1. **Summary of Work Accomplished:** What was built, what problem it solves, and what the pipeline produced end-to-end. Provide a high-level narrative a developer can read in 2 minutes to understand the full scope of work.

2. **Key Decisions Made:** Significant choices made during execution — routing decisions, architecture selections, technology trade-offs resolved, scope decisions — with rationale for each. Focus on decisions that shaped the final output.

3. **Important Code Implemented:** What code was written, which files were created or modified, what each component does, and how they work together. Include enough detail that a developer can navigate the codebase confidently.

4. **Architecture and Design Choices:** Patterns chosen, structural decisions, integration approaches, and data flow designs — especially anything sub-agents decided autonomously without human input. Highlight where the pipeline made judgment calls.

5. **Notable Observations:** Anything unexpected that happened during the run — retries, re-routing, concerns raised during validation, Party Mode brainstorming results, edge cases discovered, or caveats the developer should be aware of.

### Output

Write the complete report to `.bmad-orchestrator/task-report.md` with a clear markdown structure using the 5 sections above as level-2 headings.

## Verification

After writing the task report, verify:

1. **File exists:** Confirm `task-report.md` exists at `.bmad-orchestrator/task-report.md`
2. **All 5 required sections present:** The report contains all required content sections (Summary of Work Accomplished, Key Decisions Made, Important Code Implemented, Architecture and Design Choices, Notable Observations)
3. **Non-trivial content:** The report is substantive — at least 500 characters in length, not a stub or placeholder

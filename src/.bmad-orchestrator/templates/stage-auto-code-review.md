---
stage: auto-code-review
agent: bmad-dev
command: CR
model: opus
effort: max
requiredArtifacts: []
producedArtifacts:
  - _bmad-output/implementation-artifacts/auto-code-review-report.md
---

## Context Injection

{{task_description}}
{{failure_context}}
{{mode_instructions}}

## Stage Instructions

You are driving the Dev agent's **Code Review** workflow to perform an adversarial review of human-written merge request code, ensuring quality, correctness, security, and best-practice compliance.

### Pre-Launch Context Gathering

Before launching the sub-agent, the orchestrator must gather all relevant context:

1. **Parse commit range from task description:** Extract the commit range or branch comparison from the task description. Look for patterns like:
   - `origin/main..HEAD`, `main..HEAD`, `main...feat/branch`
   - `feat/branch vs main`, `branch-a vs branch-b`
   - Specific commit SHAs (e.g., `abc1234..def5678`)
   - If no explicit range is found, default to `origin/main..HEAD` and note this fallback in the sub-agent prompt

2. **Run git commands to collect change context:**
   - `git diff <commit-range>` -- full diff of all changes
   - `git log --oneline <commit-range>` -- commit history summary
   - `git diff --stat <commit-range>` -- file change summary (files changed, insertions, deletions)

3. **Read available documentation (if exists):**
   - Check for `_bmad-output/planning-artifacts/architecture.md` and read if present
   - Check for `**/project-context.md` and read if present
   - Check for `README.md` and read if present

### Launch Sequence

1. Launch a **NEW, FRESH** `bmad-dev` sub-agent via Task tool -- this MUST be a separate Task tool invocation creating a **clean context window** with zero carry-over from any previous interaction
2. Send the `CR` command to trigger the Code Review workflow
3. The Dev agent will present its menu and begin the adversarial code review process

### Interaction Protocol

Act as an **expert engineering lead** throughout the code review workflow:

- **Menu Selection:** When the Dev agent presents options, select `CR` (Code Review)
- **CRITICAL -- Fresh Context Window:** The review agent operates with a clean context window. This is by design: the reviewer must independently assess the code from disk artifacts and git diffs only, preventing confirmation bias. The code-review agent must approach code cold, ensuring genuine adversarial review
- **Provide Change Context:** Supply the git diff output, commit log, and file change summary as the review context. Frame this as: "Review the following merge request changes for code quality, security, performance, error handling, test coverage, architecture compliance, and best practices"
- **Documentation Context:** Include any architecture, project-context, or README content gathered during pre-launch as additional context for the reviewer to assess compliance against
- **Best Practices Lookup:** Instruct the agent to leverage Context7 MCP and web search (if available) to look up best practices for any libraries, frameworks, or patterns observed in the diff. If these tools are not available, fall back to local documentation analysis
- **Review Scope:** Instruct the agent to review ALL changed files for:
  - Code quality and readability
  - Security vulnerabilities
  - Performance issues
  - Error handling completeness
  - Test coverage adequacy
  - Architecture compliance
  - Best practice adherence
  - Naming conventions and code style consistency
- **Report Output:** Instruct the agent to produce a structured review report at `_bmad-output/implementation-artifacts/auto-code-review-report.md` containing:
  - **Summary:** Overview of the changes reviewed and overall assessment
  - **File-by-File Findings:** Specific issues per file with severity levels (CRITICAL, HIGH, MEDIUM, LOW)
  - **Verdict:** Clear PASS, CONCERNS, or FAIL determination
  - **Recommendations:** Actionable improvement suggestions

### CRITICAL — Report File Persistence

**The report FILE is the ONLY deliverable.** Findings discussed in conversation but not written to disk are LOST — the task-report generator and human reviewers can only read what is on disk.

When instructing the sub-agent, you MUST explicitly state:

> "You MUST save your complete review report — including ALL numbered findings with their severity, description, code references, and recommendations — to the file `_bmad-output/implementation-artifacts/auto-code-review-report.md`. Conversation output alone is NOT sufficient. The file must be self-contained: a reader who has not seen this conversation must be able to understand every finding from the report file alone."

This instruction must be included in the **initial prompt** to the sub-agent, not deferred to a later interaction. Do not assume the sub-agent will save findings to a file unprompted — it must be explicitly told.

### Output Requirements

- Review report MUST be saved to `_bmad-output/implementation-artifacts/auto-code-review-report.md` as a complete, self-contained document
- Report must contain a clear verdict: PASS, CONCERNS, or FAIL
- ALL individual findings must be in the report file with: finding number, severity level (CRITICAL/HIGH/MEDIUM/LOW), description, affected code location, and recommendation
- Report must cover all changed files from the commit range
- Conversation-only output is NOT acceptable — if findings exist in conversation but not in the file, the report is incomplete

### Failure Recovery

If this is a retry attempt (failure context is provided above), focus on addressing the specific issues from the previous attempt. Common recovery strategies:

- If review stalls: Be more directive in responses and guide the agent to completion
- If report not saved: Ensure the workflow completes including the save step
- If report lacks verdict: Explicitly request a PASS/CONCERNS/FAIL determination
- If report is incomplete: Guide the agent to cover all changed files

## Verification

After the Dev agent completes the code review workflow, perform these checks:

### Artifact Existence

Verify that `_bmad-output/implementation-artifacts/auto-code-review-report.md` exists on disk.

### Content Alignment

Read the review report file from disk and verify ALL of the following:

- It contains numbered review findings with specific details (not a stub, placeholder, or summary-only)
- Each finding includes: severity level (CRITICAL/HIGH/MEDIUM/LOW), description, affected file/code location, and recommendation
- It addresses the changes from the commit range specified in the task description
- It includes a clear verdict (PASS, CONCERNS, or FAIL)
- The report is self-contained — a reader who has not seen the sub-agent conversation can understand every finding

### Report Completeness Recovery

**If the report file is missing, incomplete, or lacks detailed findings:** Do NOT proceed to the quality gate. Instead:

1. Resume the sub-agent (same agent ID) and explicitly instruct it: "Your review findings were not saved to the report file. Write the COMPLETE review report — including ALL numbered findings with severity, description, code references, and recommendations — to `_bmad-output/implementation-artifacts/auto-code-review-report.md` now."
2. After the sub-agent responds, re-check the file on disk
3. If still incomplete after one recovery attempt, treat as a verification FAIL

### Quality Gate Interpretation

This is a validation stage with a tri-state quality gate:

- **PASS:** Review found no blocking issues. Pipeline complete (exit code 2). The `auto-code-review` stage is the only stage in the `review` route, so after PASS the pipeline is done.
- **CONCERNS:** Minor issues found but nothing blocking. Proceed as PASS but log concern details in the status report entry (Section 7.3) with outcome `PASS (CONCERNS)` and the concern summary in the Details field. Pipeline complete (exit code 2).
- **FAIL:** Blocking issues found. Capture the specific issues in the failure error summary. The orchestrator follows standard failure handling (Section 6): logs to `failures` array, increments `currentRetries`, and exits with code 0 for retry (or code 1 if `maxRetries` exceeded).

### State Update After Verification

**On PASS/CONCERNS:** After verification passes:

- Add `auto-code-review` to `completedStages`
- Since `auto-code-review` is the only stage in the `review` route, all stages are now complete
- Pipeline is done -- exit with code 2

**On FAIL:** Follow standard failure handling (Section 6):

- Log failure to `failures` array with specific review issues
- Increment `currentRetries`
- If retries remain, exit with code 0 for retry with failure context
- If `maxRetries` exceeded, set `status: failed` and exit with code 1

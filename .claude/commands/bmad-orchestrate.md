# BMAD Orchestrate — Slash Command

You are initializing a BMAD orchestrator pipeline run. Parse the user's input, validate the environment, and create the state file.

## Input Parsing

The user's input is: `$ARGUMENTS`

Extract from the input:
1. **Task description** — the quoted or unquoted text describing what to build (e.g., `"Build a notification system"`)
2. **Flags** — any combination of the following:
   - `--checkpoint` → sets `mode: checkpoint` (default is `autonomous`)
   - `--quick` → sets `route: quick` (skips auto-routing)
   - `--full` → sets `route: full` (skips auto-routing)
   - `--resume` → modifies existing state with `runType: resume` instead of creating new
   - `--feedback "text"` → provides checkpoint feedback for revision (MUST be combined with `--resume`)

If `--feedback` is used without `--resume`, fail immediately with: "Error: --feedback can only be used with --resume after a checkpoint pause."

If no task description is provided and `--resume` is NOT set, fail with: "Error: Task description is required. Usage: /bmad-orchestrate \"Your task description\" [--checkpoint] [--quick] [--full] [--resume]"

## Step 1: Git Branch Safety Check

Run `git rev-parse --abbrev-ref HEAD` to get the current branch name.

- If the branch is `main` or `master`, **STOP IMMEDIATELY** and output:
  > **Error:** Cannot run orchestrator on a protected branch. Switch to a feature branch first.
- Do NOT create any files or directories. End here.

## Step 2: Resume Handling (if --resume flag)

If `--resume` is set:
1. Check that `.bmad-orchestrator/state.yaml` exists. If not, fail with: "Error: No existing state.yaml found. Cannot resume without a previous run."
2. Read the existing `state.yaml`
3. Update ONLY these fields:
   - `runType: resume`
   - `updatedAt:` current ISO-8601 timestamp
   - `status: running`
   - If `--feedback` flag is present: set `checkpointFeedback: "<feedback text>"` in state
   - If `--feedback` flag is NOT present: ensure `checkpointFeedback` is absent/null in state (do not write the field)
4. Write the updated content to `.bmad-orchestrator/state.yaml.tmp`, then rename it to `.bmad-orchestrator/state.yaml` (atomic write)
5. If `--feedback` was provided: Output: "Resumed pipeline with feedback. Run `.bmad-orchestrator/loop.sh` to continue."
   If no `--feedback`: Output: "Resumed existing pipeline run. Run `.bmad-orchestrator/loop.sh` to continue execution."
6. **STOP HERE** — do not proceed to Steps 3-5.

## Step 3: Artifact Overwrite Protection (fresh runs only)

Before creating anything, check for evidence of a previous orchestrator run. Multiple signals are checked to prevent accidental overwrite of existing work.

**Primary check — state file:**
Check if `.bmad-orchestrator/state.yaml` exists. This is the definitive signal that a previous orchestrator run exists.

**Secondary check — status report:**
Check if `.bmad-orchestrator/status-report.md` exists. This indicates a previous run produced stage outcomes.

If either `.bmad-orchestrator/state.yaml` OR `.bmad-orchestrator/status-report.md` exists, **STOP** and output:
> **Error:** Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first.

**Safety net check — known orchestrator artifacts:**
If neither primary nor secondary signal is found, check if `_bmad-output/planning-artifacts/prd.md` exists (a well-known orchestrator-produced artifact). If it exists, **STOP** and output:
> **Error:** Existing artifacts detected. Use `--resume` to continue a previous run, or remove existing artifacts first. (Note: these artifacts may be from manual BMAD usage rather than a previous orchestrator run — if so, move or remove them before starting a fresh run.)

## Step 4: Create Directory & State File

1. Create `.bmad-orchestrator/` directory if it does not exist:
   ```bash
   mkdir -p .bmad-orchestrator
   ```

2. Determine field values from parsed flags:
   - `mode`: `checkpoint` if `--checkpoint` flag present, otherwise `autonomous`
   - `route`: `quick` if `--quick`, `full` if `--full`, otherwise `null`
   - `runType`: always `fresh` for new runs
   - `branch`: the branch name from Step 1

3. Write the state file using **atomic write pattern** — write to `.bmad-orchestrator/state.yaml.tmp` first, then rename:

   ```yaml
   task: "<the task description>"
   route: <null | quick | full>
   mode: <autonomous | checkpoint>
   status: running
   runType: fresh
   branch: "<current-git-branch-name>"
   createdAt: "<current ISO-8601 timestamp>"
   updatedAt: "<current ISO-8601 timestamp>"
   maxRetries: 3

   currentStage: null
   completedStages: []

   gates:
     - prd
     - architecture
     - epics-stories
     - readiness
     - code-review

   storyLoop: null

   failures: []
   currentRetries: 0
   ```

4. Rename the temp file to the final location:
   ```bash
   mv .bmad-orchestrator/state.yaml.tmp .bmad-orchestrator/state.yaml
   ```

## Step 5: Output Instructions

After successful state file creation, output:

> **BMAD Orchestrator initialized.**
>
> - **Task:** <task description>
> - **Mode:** <autonomous|checkpoint>
> - **Route:** <null|quick|full>
> - **Branch:** <branch name>
>
> Run `.bmad-orchestrator/loop.sh` to begin execution.

## Critical Rules

- **Atomic writes ONLY** — Never write directly to `state.yaml`. Always write to `state.yaml.tmp` then `mv` to `state.yaml`.
- **camelCase for all YAML fields** — `currentStage` not `current_stage`, `runType` not `run_type`.
- **Do NOT launch loop.sh** — only instruct the user to run it manually.
- **Do NOT invoke any BMAD agents or workflows** — this command only creates the state file.
- **The slash command creates the initial state file and stops.** This is the handoff point: slash command → user → loop script → orchestrator agent.

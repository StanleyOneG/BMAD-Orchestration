#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
# BMAD Orchestrator Loop Script (Ralph Loop)
#
# Exit Code Convention:
#   0 = Stage completed, continue pipeline (relaunch agent)
#   1 = Failed after retries, stop pipeline
#   2 = Pipeline complete, stop with success
#   3 = Checkpoint pause, stop and instruct user to review
#   * = Unexpected crash, stop and log
#
# This script manages the agent lifecycle. It launches the
# orchestrator agent, waits for exit, and dispatches on exit
# code. The loop script reads state but NEVER writes to it.
# ──────────────────────────────────────────────────────────

# Safety valve: maximum loop iterations to prevent runaway
readonly MAX_ITERATIONS=100

# Resolve paths relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BMAD_DIR="${TEST_BMAD_DIR:-${SCRIPT_DIR}}"
STATE_FILE="${BMAD_DIR}/state.yaml"
STATUS_REPORT="${BMAD_DIR}/status-report.md"

# ──────────────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────────────

log() {
  local message="${1}"
  echo "[ralph-loop] ${message}"
}

check_branch_safety() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "${branch}" == "main" || "${branch}" == "master" ]]; then
    log "ERROR: Cannot run orchestrator on protected branch '${branch}'. Switch to a feature branch first."
    return 1
  fi
  log "Branch safety check passed: ${branch}"
  return 0
}

read_state() {
  local field="${1}"
  local value
  value="$(grep "^${field}:" "${STATE_FILE}" | head -1 | sed "s/^${field}:[[:space:]]*//" | tr -d '"')"
  echo "${value}"
}

read_last_completed_stage() {
  local last_stage
  # Block style: extract only entries between completedStages: and the next top-level key
  last_stage="$(sed -n '/^completedStages:/,/^[a-zA-Z]/{/^  - /p}' "${STATE_FILE}" | tail -1 | sed 's/^  - //' | tr -d '"' | tr -d "'" | xargs)"
  if [[ -z "${last_stage}" ]]; then
    # Fallback to flow style: completedStages: [prd, architecture]
    last_stage="$(grep "^completedStages:" "${STATE_FILE}" | sed 's/.*\[//' | sed 's/\]//' | tr ',' '\n' | tail -1 | tr -d '"' | tr -d "'" | xargs)"
  fi
  echo "${last_stage}"
}

format_elapsed_time() {
  local seconds="${1}"
  local hours minutes secs
  hours=$((seconds / 3600))
  minutes=$(( (seconds % 3600) / 60 ))
  secs=$((seconds % 60))
  if [[ "${hours}" -gt 0 ]]; then
    echo "${hours}h ${minutes}m ${secs}s"
  elif [[ "${minutes}" -gt 0 ]]; then
    echo "${minutes}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

read_completed_stages() {
  local stages=""
  local in_block=0
  # Try block style first: lines between completedStages: and next top-level key
  while IFS= read -r line; do
    if [[ "${line}" =~ ^completedStages: ]]; then
      # Check for flow style: completedStages: [a, b, c]
      if [[ "${line}" =~ \[ ]]; then
        stages="$(echo "${line}" | sed 's/.*\[//' | sed 's/\]//' | tr -d '"' | tr -d "'" | sed 's/[[:space:]]*,[[:space:]]*/,/g' | xargs | sed 's/,/, /g')"
        echo "${stages}"
        return 0
      fi
      in_block=1
      continue
    fi
    if [[ "${in_block}" -eq 1 ]]; then
      if [[ "${line}" =~ ^[a-zA-Z] ]]; then
        # Reached next top-level key, stop
        break
      fi
      if [[ "${line}" =~ ^[[:space:]]*-[[:space:]] ]]; then
        local entry
        entry="$(echo "${line}" | sed 's/^[[:space:]]*- //' | tr -d '"' | tr -d "'" | xargs)"
        if [[ -n "${entry}" ]]; then
          if [[ -n "${stages}" ]]; then
            stages="${stages}, ${entry}"
          else
            stages="${entry}"
          fi
        fi
      fi
    fi
  done < "${STATE_FILE}"
  echo "${stages}"
}

read_failure_details() {
  # Extract the LAST failure entry from state.yaml failures array
  # Returns: stage|error|attempt|reRoutedTo (pipe-delimited)
  local in_failures=0
  local current_stage="" current_error="" current_attempt="" current_rerouted=""
  local last_stage="" last_error="" last_attempt="" last_rerouted=""
  while IFS= read -r line; do
    if [[ "${line}" =~ ^failures: ]]; then
      in_failures=1
      continue
    fi
    if [[ "${in_failures}" -eq 1 ]]; then
      if [[ "${line}" =~ ^[a-zA-Z] ]]; then
        # Reached next top-level key, stop
        break
      fi
      if [[ "${line}" =~ ^[[:space:]]*-[[:space:]] ]]; then
        # New failure entry - save previous if exists
        if [[ -n "${current_stage}" ]]; then
          last_stage="${current_stage}"
          last_error="${current_error}"
          last_attempt="${current_attempt}"
          last_rerouted="${current_rerouted}"
        fi
        current_stage=""
        current_error=""
        current_attempt=""
        current_rerouted=""
        # Check if this line also has a field (e.g., "- stage: prd")
        if [[ "${line}" =~ stage:[[:space:]]*(.*) ]]; then
          current_stage="$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'" | xargs)"
        fi
      elif [[ "${line}" =~ ^[[:space:]]+stage:[[:space:]]*(.*) ]]; then
        current_stage="$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'" | xargs)"
      elif [[ "${line}" =~ ^[[:space:]]+error:[[:space:]]*(.*) ]]; then
        current_error="$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'" | xargs)"
      elif [[ "${line}" =~ ^[[:space:]]+attempt:[[:space:]]*(.*) ]]; then
        current_attempt="$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'" | xargs)"
      elif [[ "${line}" =~ ^[[:space:]]+reRoutedTo:[[:space:]]*(.*) ]]; then
        current_rerouted="$(echo "${BASH_REMATCH[1]}" | tr -d '"' | tr -d "'" | xargs)"
      fi
    fi
  done < "${STATE_FILE}"
  # Save the last entry
  if [[ -n "${current_stage}" ]]; then
    last_stage="${current_stage}"
    last_error="${current_error}"
    last_attempt="${current_attempt}"
    last_rerouted="${current_rerouted}"
  fi
  echo "${last_stage}|${last_error}|${last_attempt}|${last_rerouted}"
}

read_story_context() {
  # Extract story ID from storyLoop if failure occurred during a story-level stage
  local current_stage
  current_stage="$(read_state "currentStage")"
  if [[ "${current_stage}" == "create-story" || "${current_stage}" == "dev-story" || "${current_stage}" == "code-review" ]]; then
    local story_id
    # Try top-level currentStoryId first, then storyLoop block
    story_id="$(read_state "currentStoryId")"
    if [[ -z "${story_id}" ]]; then
      story_id="$(sed -n '/^storyLoop:/,/^[a-zA-Z]/{/currentStoryId/p}' "${STATE_FILE}" | head -1 | sed 's/.*currentStoryId:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs)"
    fi
    echo "${story_id}"
  fi
}

generate_artifact_inventory() {
  local output_dir="${1}"
  if [[ ! -d "${output_dir}" ]]; then
    echo "  - No artifacts directory found"
    return 0
  fi
  find "${output_dir}" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | sort | while IFS= read -r filepath; do
    local stage="unknown"
    case "${filepath}" in
      */planning-artifacts/prd*.md)          stage="prd" ;;
      */planning-artifacts/architecture*.md) stage="architecture" ;;
      */planning-artifacts/*epic*.md)        stage="epics-stories" ;;
      */planning-artifacts/*readiness*.md)   stage="readiness" ;;
      */implementation-artifacts/sprint-status.yaml) stage="sprint-planning" ;;
      */implementation-artifacts/[0-9]*-[0-9]*-*.md) stage="create-story" ;;
    esac
    echo "  - ${filepath} (stage: ${stage})"
  done
}

preflight_check() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    log "ERROR: state.yaml not found at ${STATE_FILE}. Run /bmad-orchestrate first to initialize."
    return 1
  fi

  local status
  status="$(read_state "status")"
  if [[ "${status}" == "completed" ]]; then
    log "ERROR: Pipeline already completed. Use --resume or delete state.yaml to start fresh."
    return 1
  fi
  if [[ "${status}" == "failed" ]]; then
    log "ERROR: Pipeline previously failed. Use --resume to retry or delete state.yaml to start fresh."
    return 1
  fi

  check_branch_safety
}

launch_agent() {
  local prompt="${1:-}"
  local bootstrap="Read the file .claude/agents/bmad-orchestrator.md — it contains your complete instructions. Follow them exactly as your system prompt. Then execute the pipeline."
  if [[ "${BATS_TESTING:-}" == "1" ]]; then
    log "Launching orchestrator agent (test mode, skipping)..."
    return 0
  fi
  if [[ -n "${prompt}" ]]; then
    log "Launching orchestrator agent with directive: ${prompt}"
    echo "${bootstrap} Directive: ${prompt}" | claude --dangerously-skip-permissions
  else
    log "Launching orchestrator agent..."
    echo "${bootstrap}" | claude --dangerously-skip-permissions
  fi
}

write_status_report() {
  local overall_status="${1}"
  local iterations="${2}"
  local elapsed_time="${3}"
  local completed_stages="${4}"
  local extra_details="${5:-}"

  # Create header if file does not exist
  if [[ ! -f "${STATUS_REPORT}" ]]; then
    local task route mode
    task="$(read_state "task")"
    route="$(read_state "route")"
    mode="$(read_state "mode")"

    cat > "${STATUS_REPORT}" <<EOF
## Run Started
- **Task:** ${task}
- **Route:** ${route}
- **Mode:** ${mode}
- **Started:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

EOF
  fi

  # Count completed stages
  local stage_count=0
  if [[ -n "${completed_stages}" ]]; then
    stage_count="$(echo "${completed_stages}" | tr ',' '\n' | grep -c '[a-z]' || true)"
  fi

  # Append run summary - common fields
  cat >> "${STATUS_REPORT}" <<EOF
## Run Summary
- **Overall Status:** ${overall_status}
- **Total Iterations:** ${iterations}
- **Total Stages Run:** ${stage_count}
- **Elapsed Time:** ${elapsed_time}
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  # Status-specific fields
  case "${overall_status}" in
    COMPLETED)
      cat >> "${STATUS_REPORT}" <<EOF
- **Completed Stages:** ${completed_stages}

### Artifact Inventory
${extra_details}
EOF
      ;;
    FAILED)
      # extra_details format: failed_at|error|attempts|rerouted
      local failed_at error_msg attempts rerouted
      failed_at="$(echo "${extra_details}" | cut -d'|' -f1)"
      error_msg="$(echo "${extra_details}" | cut -d'|' -f2)"
      attempts="$(echo "${extra_details}" | cut -d'|' -f3)"
      rerouted="$(echo "${extra_details}" | cut -d'|' -f4)"

      cat >> "${STATUS_REPORT}" <<EOF
- **Failed At:** ${failed_at}
- **Error:** ${error_msg}
- **Attempts:** ${attempts}
- **Completed Stages:** ${completed_stages}
- **Recovery:** Run \`/bmad-orchestrate --resume\` then \`.bmad-orchestrator/loop.sh\`
EOF
      if [[ -n "${rerouted}" ]]; then
        cat >> "${STATUS_REPORT}" <<EOF
- **Re-routed to:** ${rerouted}
EOF
      fi
      ;;
    PAUSED)
      cat >> "${STATUS_REPORT}" <<EOF
- **Paused At:** ${extra_details}
- **Completed Stages:** ${completed_stages}
- **Resume:** Review artifacts, then run \`/bmad-orchestrate --resume\` then \`.bmad-orchestrator/loop.sh\`
EOF
      ;;
    CRASHED)
      cat >> "${STATUS_REPORT}" <<EOF
- **Exit Code:** ${extra_details}
- **Details:** Agent terminated unexpectedly
- **Completed Stages:** ${completed_stages}
- **Recovery:** Run \`/bmad-orchestrate --resume\` then \`.bmad-orchestrator/loop.sh\`
EOF
      ;;
  esac

  echo "" >> "${STATUS_REPORT}"
}

handle_exit_code() {
  local code="${1}"
  local elapsed_time="${2:-0s}"
  local completed_stages="${3:-}"

  case "${code}" in
    0)
      log "Stage completed. Relaunching agent with fresh context..."
      return 0
      ;;
    1)
      log "Pipeline failed after retries. Stopping loop."
      local failure_details failed_at failure_error failure_attempt failure_rerouted story_context
      failure_details="$(read_failure_details)"
      failed_at="$(echo "${failure_details}" | cut -d'|' -f1)"
      failure_error="$(echo "${failure_details}" | cut -d'|' -f2)"
      failure_attempt="$(echo "${failure_details}" | cut -d'|' -f3)"
      failure_rerouted="$(echo "${failure_details}" | cut -d'|' -f4)"
      story_context="$(read_story_context)"
      if [[ -n "${story_context}" ]]; then
        failed_at="${failed_at} (${story_context})"
      fi
      local max_retries
      max_retries="$(read_state "maxRetries")"
      if [[ -n "${max_retries}" ]]; then
        failure_attempt="${failure_attempt} of ${max_retries}"
      fi
      write_status_report "FAILED" "${ITERATION:-0}" "${elapsed_time}" "${completed_stages}" "${failed_at}|${failure_error}|${failure_attempt}|${failure_rerouted}"
      return 1
      ;;
    2)
      log "Pipeline complete. All stages finished successfully."
      local artifact_inventory
      artifact_inventory="$(generate_artifact_inventory "_bmad-output")"
      write_status_report "COMPLETED" "${ITERATION:-0}" "${elapsed_time}" "${completed_stages}" "${artifact_inventory}"

      # Task report generation (best-effort, does not block pipeline success)
      log "Generating task report..."
      local task_report_exit_code
      set +e
      launch_agent "generate-task-report"
      task_report_exit_code=$?
      set -e
      if [[ "${task_report_exit_code}" -ne 2 ]]; then
        log "WARNING: Task report generation returned exit code ${task_report_exit_code} (expected 2). Task report is best-effort; pipeline is still complete."
      else
        log "Task report generated successfully."
      fi

      return 2
      ;;
    3)
      local checkpoint_stage
      checkpoint_stage="$(read_last_completed_stage)"
      if [[ -z "${checkpoint_stage}" ]]; then
        checkpoint_stage="unknown"
      fi
      log "Checkpoint reached after ${checkpoint_stage}. Review artifacts and run --resume to continue."
      write_status_report "PAUSED" "${ITERATION:-0}" "${elapsed_time}" "${completed_stages}" "${checkpoint_stage}"
      return 3
      ;;
    *)
      log "Unexpected crash with exit code ${code}. Agent terminated unexpectedly. Stopping loop."
      write_status_report "CRASHED" "${ITERATION:-0}" "${elapsed_time}" "${completed_stages}" "${code}"
      return "${code}"
      ;;
  esac
}

main() {
  log "Starting Ralph Loop..."

  # Capture pipeline start time for elapsed time calculation (AC #1)
  local START_TIME
  START_TIME="$(date +%s)"

  preflight_check

  local task
  task="$(read_state "task")"
  log "Task: ${task}"

  local ITERATION=0
  local agent_exit_code
  local handler_result

  while true; do
    ITERATION=$((ITERATION + 1))

    if [[ "${ITERATION}" -gt "${MAX_ITERATIONS}" ]]; then
      log "Safety valve triggered: exceeded ${MAX_ITERATIONS} iterations. Stopping."
      local end_time elapsed_seconds elapsed_formatted completed_stages_list
      end_time="$(date +%s)"
      elapsed_seconds=$((end_time - START_TIME))
      elapsed_formatted="$(format_elapsed_time "${elapsed_seconds}")"
      completed_stages_list="$(read_completed_stages)"
      write_status_report "FAILED" "${ITERATION}" "${elapsed_formatted}" "${completed_stages_list}" "safety-valve|Exceeded ${MAX_ITERATIONS} iterations|${ITERATION}|"
      exit 1
    fi

    log "--- Iteration ${ITERATION} ---"

    set +e
    launch_agent
    agent_exit_code=$?
    set -e

    # Calculate elapsed time and completed stages for status report
    local end_time elapsed_seconds elapsed_formatted completed_stages_list
    end_time="$(date +%s)"
    elapsed_seconds=$((end_time - START_TIME))
    elapsed_formatted="$(format_elapsed_time "${elapsed_seconds}")"
    completed_stages_list="$(read_completed_stages)"

    set +e
    handle_exit_code "${agent_exit_code}" "${elapsed_formatted}" "${completed_stages_list}"
    handler_result=$?
    set -e

    if [[ "${handler_result}" -ne 0 ]]; then
      # Any non-zero handler result means stop the loop
      if [[ "${handler_result}" -eq 2 ]]; then
        log "Pipeline completed successfully after ${ITERATION} iterations."
        exit 0
      else
        log "Loop stopped after ${ITERATION} iterations."
        exit "${handler_result}"
      fi
    fi

    # Exit code 0: continue loop (agent will be relaunched)
  done
}

# Allow sourcing for testing without running main
if [[ "${BATS_TESTING:-}" != "1" ]]; then
  main "$@"
fi

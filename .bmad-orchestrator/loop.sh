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
  log "Launching orchestrator agent..."
  claude --agent bmad-orchestrator
}

write_status_report() {
  local overall_status="${1}"
  local details="${2}"
  local iterations="${3}"

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

  # Append run summary
  cat >> "${STATUS_REPORT}" <<EOF
## Run Summary
- **Overall Status:** ${overall_status}
- **Total Iterations:** ${iterations}
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Details:** ${details}
EOF

  # Add recovery instructions for relevant statuses
  if [[ "${overall_status}" == "FAILED" || "${overall_status}" == "PAUSED" ]]; then
    cat >> "${STATUS_REPORT}" <<EOF
- **Resume:** Run \`/bmad-orchestrate --resume\` then \`.bmad-orchestrator/loop.sh\`
EOF
  fi

  echo "" >> "${STATUS_REPORT}"
}

handle_exit_code() {
  local code="${1}"

  case "${code}" in
    0)
      log "Stage completed. Relaunching agent with fresh context..."
      return 0
      ;;
    1)
      log "Pipeline failed after retries. Stopping loop."
      write_status_report "FAILED" "Pipeline failed at current stage" "${ITERATION:-0}"
      return 1
      ;;
    2)
      log "Pipeline complete. All stages finished successfully."
      write_status_report "COMPLETED" "Pipeline finished successfully" "${ITERATION:-0}"
      return 2
      ;;
    3)
      local checkpoint_stage
      checkpoint_stage="$(read_last_completed_stage)"
      if [[ -z "${checkpoint_stage}" ]]; then
        checkpoint_stage="unknown"
      fi
      log "Checkpoint reached after ${checkpoint_stage}. Review artifacts and run --resume to continue."
      write_status_report "PAUSED" "Checkpoint reached after ${checkpoint_stage} - review required" "${ITERATION:-0}"
      return 3
      ;;
    *)
      log "Unexpected crash with exit code ${code}. Agent terminated unexpectedly. Stopping loop."
      write_status_report "CRASHED" "Agent terminated unexpectedly with exit code ${code}" "${ITERATION:-0}"
      return "${code}"
      ;;
  esac
}

main() {
  log "Starting Ralph Loop..."

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
      write_status_report "FAILED" "Safety valve: exceeded ${MAX_ITERATIONS} iterations" "${ITERATION}"
      exit 1
    fi

    log "--- Iteration ${ITERATION} ---"

    set +e
    launch_agent
    agent_exit_code=$?
    set -e

    set +e
    handle_exit_code "${agent_exit_code}"
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

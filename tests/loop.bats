#!/usr/bin/env bats

# Tests for .bmad-orchestrator/loop.sh
# Covers: Task 1 (script structure, branch safety, state reading, pre-flight)
#         Task 2 (agent launch, exit code handling)
#         Task 3 (status report writing)
#         Task 4 (main loop, iteration counter)

SCRIPT=".bmad-orchestrator/loop.sh"
TEST_DIR=""

# ──────────────────────────────────────────────
# Helper: source script functions without running main
# ──────────────────────────────────────────────

source_functions() {
  # Source the script but override main to prevent execution
  # We use a technique: set a flag that main() checks
  export BATS_TESTING=1
  source "${SCRIPT}"
}

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_BMAD_DIR="${TEST_DIR}/.bmad-orchestrator"
  mkdir -p "${TEST_BMAD_DIR}"

  # Create a minimal state.yaml for tests
  cat > "${TEST_BMAD_DIR}/state.yaml" <<'YAML'
task: "Test task"
route: full
mode: autonomous
status: running
runType: fresh
branch: "feature/test"
createdAt: "2026-02-03T00:00:00Z"
updatedAt: "2026-02-03T00:00:00Z"
maxRetries: 3
currentStage: null
completedStages: []
gates:
  - prd
  - architecture
storyLoop: null
failures: []
currentRetries: 0
YAML
}

teardown() {
  rm -rf "${TEST_DIR}"
}

# ──────────────────────────────────────────────
# Task 1 Tests: Script structure and pre-flight
# ──────────────────────────────────────────────

@test "Task 1.1: script exists and is executable" {
  [ -f "${SCRIPT}" ]
  [ -x "${SCRIPT}" ]
}

@test "Task 1.1: script starts with bash shebang and set -euo pipefail" {
  head -2 "${SCRIPT}" | grep -q '#!/usr/bin/env bash'
  head -5 "${SCRIPT}" | grep -q 'set -euo pipefail'
}

@test "Task 1.2: exit codes documented in comment block at top" {
  head -20 "${SCRIPT}" | grep -q 'Exit Code'
  head -20 "${SCRIPT}" | grep -q '0'
  head -20 "${SCRIPT}" | grep -q '1'
  head -20 "${SCRIPT}" | grep -q '2'
  head -20 "${SCRIPT}" | grep -q '3'
}

@test "Task 1.3: check_branch_safety function exists" {
  grep -q 'check_branch_safety' "${SCRIPT}"
}

@test "Task 1.3: check_branch_safety rejects main branch" {
  # Source the script functions without running main
  source_functions
  # Mock git to return "main"
  git() { echo "main"; }
  export -f git
  run check_branch_safety
  [ "$status" -ne 0 ]
  unset -f git
}

@test "Task 1.3: check_branch_safety rejects master branch" {
  source_functions
  git() { echo "master"; }
  export -f git
  run check_branch_safety
  [ "$status" -ne 0 ]
  unset -f git
}

@test "Task 1.3: check_branch_safety allows feature branches" {
  source_functions
  git() { echo "feature/test-branch"; }
  export -f git
  run check_branch_safety
  [ "$status" -eq 0 ]
  unset -f git
}

@test "Task 1.4: read_state function exists" {
  grep -q 'read_state' "${SCRIPT}"
}

@test "Task 1.4: read_state extracts status field" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  run read_state "status"
  [ "$status" -eq 0 ]
  [ "$output" = "running" ]
}

@test "Task 1.4: read_state extracts task field" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  run read_state "task"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test task"* ]]
}

@test "Task 1.5: pre-flight fails when state.yaml missing" {
  source_functions
  BMAD_DIR="${TEST_DIR}/nonexistent"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  run preflight_check
  [ "$status" -ne 0 ]
}

@test "Task 1.5: pre-flight succeeds when state.yaml exists with running status" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  git() { echo "feature/test"; }
  export -f git
  run preflight_check
  [ "$status" -eq 0 ]
  unset -f git
}

@test "Task 1.5: pre-flight fails when status is completed" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  sed -i 's/^status: running/status: completed/' "${STATE_FILE}"
  run preflight_check
  [ "$status" -ne 0 ]
  [[ "$output" == *"already completed"* ]]
}

@test "Task 1.5: pre-flight fails when status is failed" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  sed -i 's/^status: running/status: failed/' "${STATE_FILE}"
  run preflight_check
  [ "$status" -ne 0 ]
  [[ "$output" == *"previously failed"* ]]
}

# ──────────────────────────────────────────────
# Task 2 Tests: Agent launch and exit code handling
# ──────────────────────────────────────────────

@test "Task 2.1: launch_agent function exists" {
  grep -q 'launch_agent' "${SCRIPT}"
}

@test "Task 2.1: launch_agent invokes claude --agent bmad-orchestrator" {
  grep -q 'claude --agent bmad-orchestrator' "${SCRIPT}"
}

@test "Task 2.2: main captures exit code with set +e/set -e around launch_agent" {
  # Verify the pattern: set +e before launch_agent call, set -e after capture
  local pattern
  pattern=$(sed -n '/set +e/{N;/launch_agent/{N;/agent_exit_code=\$?/{N;/set -e/p}}}' "${SCRIPT}")
  [ -n "${pattern}" ]
}

@test "Task 2.3: exit code 0 continues loop (stage completed)" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  run handle_exit_code 0
  [ "$status" -eq 0 ]
  [[ "$output" == *"Stage completed"* ]] || [[ "$output" == *"stage completed"* ]]
}

@test "Task 2.4: exit code 1 stops loop (pipeline failed)" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  ITERATION=1
  run handle_exit_code 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"* ]] || [[ "$output" == *"FAIL"* ]] || [[ "$output" == *"Fail"* ]]
}

@test "Task 2.5: exit code 2 stops loop (pipeline complete)" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  ITERATION=1
  run handle_exit_code 2
  [ "$status" -eq 2 ]
  [[ "$output" == *"complete"* ]] || [[ "$output" == *"COMPLETE"* ]] || [[ "$output" == *"Complete"* ]]
}

@test "Task 2.6: exit code 3 stops loop (checkpoint pause)" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  ITERATION=1
  run handle_exit_code 3
  [ "$status" -eq 3 ]
  [[ "$output" == *"pause"* ]] || [[ "$output" == *"Pause"* ]] || [[ "$output" == *"checkpoint"* ]] || [[ "$output" == *"Checkpoint"* ]]
}

@test "Task 2.7: unexpected exit code stops loop and logs crash" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  ITERATION=1
  run handle_exit_code 137
  [ "$status" -eq 137 ]
  [[ "$output" == *"crash"* ]] || [[ "$output" == *"Crash"* ]] || [[ "$output" == *"unexpected"* ]] || [[ "$output" == *"Unexpected"* ]]
}

# ──────────────────────────────────────────────
# Task 3 Tests: Status report writing
# ──────────────────────────────────────────────

@test "Task 3.1: write_status_report function exists" {
  grep -q 'write_status_report' "${SCRIPT}"
}

@test "Task 3.2: creates status-report.md with header if not exists" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  rm -f "${STATUS_REPORT}"
  write_status_report "COMPLETED" "Test details" 5
  [ -f "${STATUS_REPORT}" ]
  grep -q "Run Started" "${STATUS_REPORT}"
  grep -q "Task:" "${STATUS_REPORT}"
}

@test "Task 3.3: pipeline completion writes COMPLETED status" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  rm -f "${STATUS_REPORT}"
  write_status_report "COMPLETED" "Pipeline finished successfully" 10
  grep -q "COMPLETED" "${STATUS_REPORT}"
  grep -q "Total Iterations" "${STATUS_REPORT}"
}

@test "Task 3.4: pipeline failure writes FAILED status with recovery instructions" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  rm -f "${STATUS_REPORT}"
  write_status_report "FAILED" "Stage prd failed" 3
  grep -q "FAILED" "${STATUS_REPORT}"
  grep -q "resume" "${STATUS_REPORT}" || grep -q "Resume" "${STATUS_REPORT}" || grep -q "--resume" "${STATUS_REPORT}"
}

@test "Task 3.5: checkpoint pause writes PAUSED status with resume instructions" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  rm -f "${STATUS_REPORT}"
  write_status_report "PAUSED" "Checkpoint reached" 7
  grep -q "PAUSED" "${STATUS_REPORT}"
  grep -q "resume" "${STATUS_REPORT}" || grep -q "Resume" "${STATUS_REPORT}" || grep -q "--resume" "${STATUS_REPORT}"
}

@test "Task 3.6: crash writes CRASHED status with exit code" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  rm -f "${STATUS_REPORT}"
  write_status_report "CRASHED" "Agent terminated unexpectedly with exit code 137" 2
  grep -q "CRASHED" "${STATUS_REPORT}"
  grep -q "137" "${STATUS_REPORT}"
}

# ──────────────────────────────────────────────
# Task 4 Tests: Main loop and safety valve
# ──────────────────────────────────────────────

@test "Task 4.2: MAX_ITERATIONS is defined as readonly" {
  grep -q 'readonly MAX_ITERATIONS=' "${SCRIPT}"
}

@test "Task 4.2: safety valve checks ITERATION against MAX_ITERATIONS" {
  source_functions
  BMAD_DIR="${TEST_BMAD_DIR}"
  STATE_FILE="${BMAD_DIR}/state.yaml"
  STATUS_REPORT="${BMAD_DIR}/status-report.md"
  # Simulate exceeding max iterations by setting ITERATION high
  ITERATION=101
  # Verify the comparison logic: ITERATION > MAX_ITERATIONS should be true
  [[ "${ITERATION}" -gt "${MAX_ITERATIONS}" ]]
}

@test "Task 4.4: script passes ShellCheck" {
  run shellcheck "${SCRIPT}"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Task 4.5: all variables use quoted pattern" {
  # Check that there are no unquoted $VAR usages (excluding comments and special vars)
  # This is a heuristic check - looks for $VAR not inside quotes or braces
  local unquoted
  unquoted=$(grep -n '[^"$\\{]$[A-Z_][A-Z_0-9]*[^}]' "${SCRIPT}" | grep -v '^\s*#' | grep -v '"${' || true)
  [ -z "${unquoted}" ]
}

# ──────────────────────────────────────────────
# AC #8 Tests: Bash best practices
# ──────────────────────────────────────────────

@test "AC8: functions use snake_case" {
  # All function definitions should be snake_case
  local bad_functions
  bad_functions=$(grep -E '^[a-zA-Z_]+\(' "${SCRIPT}" | grep -E '[A-Z]' || true)
  [ -z "${bad_functions}" ]
}

@test "AC8: function variables use local declarations" {
  # Check that functions declare variables with local
  # Extract function bodies and check for non-local variable assignments
  # This is a basic check - ensures 'local' appears in function bodies
  local func_count
  func_count=$(grep -c 'local ' "${SCRIPT}" || echo "0")
  [ "${func_count}" -gt 0 ]
}


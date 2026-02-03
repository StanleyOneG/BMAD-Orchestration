#!/usr/bin/env bats

# Tests for .claude/agents/bmad-orchestrator.md
# Story 1.3: Orchestrator Agent — Cold Start & State Management
#
# These tests validate that the agent definition file contains all
# required sections, patterns, and identifiers per acceptance criteria.

AGENT_FILE=".claude/agents/bmad-orchestrator.md"

# ──────────────────────────────────────────────
# Task 1 Tests: Agent definition file structure (AC: #1, #2, #6)
# ──────────────────────────────────────────────

@test "Task 1.1: agent definition file exists" {
  [ -f "${AGENT_FILE}" ]
}

@test "Task 1.1: agent definition has Claude Code agent frontmatter" {
  head -10 "${AGENT_FILE}" | grep -q '^---'
  grep -q 'name: bmad-orchestrator' "${AGENT_FILE}"
}

@test "Task 1.2: agent defines core identity as BMAD Orchestrator" {
  grep -qi 'orchestrator' "${AGENT_FILE}"
  grep -qi 'pipeline' "${AGENT_FILE}"
}

@test "Task 1.3: agent has cold-start orientation — reads state.yaml on launch" {
  grep -q 'state\.yaml' "${AGENT_FILE}"
  grep -qi 'cold.start\|orientation\|orient\|launch\|every.*launch' "${AGENT_FILE}"
}

@test "Task 1.3: agent reads currentStage from state.yaml" {
  grep -q 'currentStage' "${AGENT_FILE}"
}

@test "Task 1.3: agent reads completedStages from state.yaml" {
  grep -q 'completedStages' "${AGENT_FILE}"
}

@test "Task 1.3: agent reads mode from state.yaml" {
  grep -q 'mode' "${AGENT_FILE}"
}

@test "Task 1.4: agent maps currentStage to template file" {
  grep -q 'stage-.*\.md\|stage-{.*}\.md\|stage-.*currentStage' "${AGENT_FILE}"
}

@test "Task 1.5: agent handles first launch — currentStage is null" {
  grep -q 'null' "${AGENT_FILE}"
  grep -qi 'routing\|route\|first.*launch\|Story 1\.4' "${AGENT_FILE}"
}

@test "Task 1.6: agent uses Task tool for sub-agent interaction" {
  grep -qi 'Task tool\|sub-agent\|sub.agent' "${AGENT_FILE}"
}

@test "Task 1.6: agent acts as expert human user" {
  grep -qi 'expert.*human\|expert.*user\|human.*expert\|product.*expert\|engineering.*expert' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Task 2 Tests: State management logic (AC: #3, #4)
# ──────────────────────────────────────────────

@test "Task 2.1: agent defines state update protocol" {
  grep -qi 'state.*update\|update.*state\|write.*state' "${AGENT_FILE}"
}

@test "Task 2.2: agent uses atomic write — state.yaml.tmp then mv" {
  grep -q 'state\.yaml\.tmp' "${AGENT_FILE}"
  grep -q 'mv.*state\.yaml' "${AGENT_FILE}"
}

@test "Task 2.3: agent appends to completedStages" {
  grep -q 'completedStages' "${AGENT_FILE}"
  grep -qi 'append\|add.*completed' "${AGENT_FILE}"
}

@test "Task 2.4: agent advances currentStage to next stage" {
  grep -qi 'advance\|next.*stage\|currentStage' "${AGENT_FILE}"
}

@test "Task 2.5: agent updates updatedAt timestamp" {
  grep -q 'updatedAt' "${AGENT_FILE}"
}

@test "Task 2.6: agent resets currentRetries to 0 on stage advance" {
  grep -q 'currentRetries' "${AGENT_FILE}"
  grep -qi 'reset.*0\|currentRetries.*0\|0.*currentRetries' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Task 3 Tests: Exit code handling (AC: #5)
# ──────────────────────────────────────────────

@test "Task 3.1: agent defines exit code protocol" {
  grep -qi 'exit.*code\|exit code' "${AGENT_FILE}"
}

@test "Task 3.2: exit code 0 — stage completed, continue" {
  grep -q '0' "${AGENT_FILE}"
  grep -qi 'stage.*completed\|stage.*done\|continue' "${AGENT_FILE}"
}

@test "Task 3.3: exit code 1 — failed after maxRetries" {
  grep -q 'maxRetries' "${AGENT_FILE}"
  grep -qi 'fail' "${AGENT_FILE}"
}

@test "Task 3.4: exit code 2 — pipeline complete" {
  grep -qi 'pipeline.*complete\|all.*stages.*completed' "${AGENT_FILE}"
}

@test "Task 3.5: exit code 3 — checkpoint pause" {
  grep -qi 'checkpoint.*pause\|checkpoint' "${AGENT_FILE}"
  grep -q 'gates' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Task 4 Tests: Pipeline stage sequences (AC: #2)
# ──────────────────────────────────────────────

@test "Task 4.1: Full Method pipeline sequence defined" {
  grep -q 'prd' "${AGENT_FILE}"
  grep -q 'architecture' "${AGENT_FILE}"
  grep -q 'epics-stories' "${AGENT_FILE}"
  grep -q 'readiness' "${AGENT_FILE}"
  grep -q 'sprint-planning' "${AGENT_FILE}"
  grep -q 'create-story' "${AGENT_FILE}"
  grep -q 'dev-story' "${AGENT_FILE}"
  grep -q 'code-review' "${AGENT_FILE}"
}

@test "Task 4.2: Quick Flow pipeline sequence defined" {
  grep -q 'quick-spec' "${AGENT_FILE}"
  grep -q 'quick-dev' "${AGENT_FILE}"
}

@test "Task 4.3: template loading uses stage-{currentStage}.md pattern" {
  grep -q 'stage-' "${AGENT_FILE}"
  grep -q '\.bmad-orchestrator/templates' "${AGENT_FILE}"
}

@test "Task 4.4: template frontmatter parsing — agent, command, requiredArtifacts, producedArtifacts" {
  grep -q 'agent' "${AGENT_FILE}"
  grep -q 'command' "${AGENT_FILE}"
  grep -q 'requiredArtifacts' "${AGENT_FILE}"
  grep -q 'producedArtifacts' "${AGENT_FILE}"
}

@test "Task 4.5: artifact pre-validation before launching sub-agent" {
  grep -qi 'requiredArtifacts.*exist\|verify.*required\|pre-validation\|validate.*artifacts\|required.*artifacts.*exist' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Task 5 Tests: Verification pattern (AC: #3, #5)
# ──────────────────────────────────────────────

@test "Task 5.1: verify producedArtifacts exist after sub-agent completes" {
  grep -qi 'producedArtifacts.*exist\|verify.*produced\|check.*produced\|produced.*artifacts.*exist' "${AGENT_FILE}"
}

@test "Task 5.2: goal alignment — compare against task from state file" {
  grep -qi 'goal.*alignment\|task.*alignment\|compare.*task\|align' "${AGENT_FILE}"
}

@test "Task 5.3: validation stages check PASS/CONCERNS/FAIL" {
  grep -q 'PASS' "${AGENT_FILE}"
  grep -q 'FAIL' "${AGENT_FILE}"
}

@test "Task 5.4: on verification pass — update state and exit 0" {
  grep -qi 'verification.*pass\|pass.*update.*state\|verification.*succeed' "${AGENT_FILE}"
}

@test "Task 5.5: on verification fail — log to failures array and increment retries" {
  grep -q 'failures' "${AGENT_FILE}"
  grep -qi 'increment.*retries\|currentRetries' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Cross-cutting: Boundary rules and anti-patterns
# ──────────────────────────────────────────────

@test "Agent never writes to _bmad-output directly" {
  grep -qi 'never.*write.*_bmad-output\|never.*directly.*_bmad-output\|never.*_bmad-output\|do not.*write.*artifacts' "${AGENT_FILE}"
}

@test "Agent never modifies templates" {
  grep -qi 'never.*modif.*template\|read.only.*template\|templates.*read\|NEVER modify them' "${AGENT_FILE}"
}

@test "Agent writes status-report.md" {
  grep -q 'status-report\.md' "${AGENT_FILE}"
}

@test "Agent references state.yaml location correctly" {
  grep -q '\.bmad-orchestrator/state\.yaml' "${AGENT_FILE}"
}

@test "Agent uses camelCase field names" {
  grep -q 'currentStage' "${AGENT_FILE}"
  grep -q 'completedStages' "${AGENT_FILE}"
  grep -q 'currentRetries' "${AGENT_FILE}"
  grep -q 'maxRetries' "${AGENT_FILE}"
  grep -q 'runType' "${AGENT_FILE}"
  grep -q 'storyLoop' "${AGENT_FILE}"
  grep -q 'updatedAt' "${AGENT_FILE}"
  grep -q 'createdAt' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Structural validation tests (code review additions)
# ──────────────────────────────────────────────

@test "Structural: frontmatter is valid YAML block with name and tools" {
  # First line must be ---
  head -1 "${AGENT_FILE}" | grep -q '^---$'
  # Frontmatter closes before line 20
  local close_line
  close_line=$(tail -n +2 "${AGENT_FILE}" | grep -n '^---$' | head -1 | cut -d: -f1)
  [ "${close_line}" -lt 20 ]
  # Contains required frontmatter keys
  head -"${close_line}" "${AGENT_FILE}" | grep -q 'name:'
  head -"${close_line}" "${AGENT_FILE}" | grep -q 'tools:'
}

@test "Structural: sections appear in correct order (1-10)" {
  local s1 s2 s3 s4 s5 s6 s7 s8 s9 s10
  s1=$(grep -n '## 1\. Cold Start' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s2=$(grep -n '## 2\. Pipeline Stage' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s3=$(grep -n '## 3\. Template Loading' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s4=$(grep -n '## 4\. Sub-Agent' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s5=$(grep -n '## 5\. Verification' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s6=$(grep -n '## 6\. Failure' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s7=$(grep -n '## 7\. State Update' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s8=$(grep -n '## 8\. Exit Code' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s9=$(grep -n '## 9\. Boundary' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s10=$(grep -n '## 10\. Execution Flow' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  # All sections must exist
  [ -n "${s1}" ] && [ -n "${s2}" ] && [ -n "${s3}" ] && [ -n "${s4}" ] && [ -n "${s5}" ]
  [ -n "${s6}" ] && [ -n "${s7}" ] && [ -n "${s8}" ] && [ -n "${s9}" ] && [ -n "${s10}" ]
  # Sections must be in ascending order
  [ "${s1}" -lt "${s2}" ]
  [ "${s2}" -lt "${s3}" ]
  [ "${s3}" -lt "${s4}" ]
  [ "${s4}" -lt "${s5}" ]
  [ "${s5}" -lt "${s6}" ]
  [ "${s6}" -lt "${s7}" ]
  [ "${s7}" -lt "${s8}" ]
  [ "${s8}" -lt "${s9}" ]
  [ "${s9}" -lt "${s10}" ]
}

@test "Structural: full pipeline sequence appears on a single line in correct order" {
  # The full pipeline must appear as a connected sequence on one line
  grep -q 'prd.*architecture.*epics-stories.*readiness.*sprint-planning.*create-story.*dev-story.*code-review' "${AGENT_FILE}"
}

@test "Structural: quick pipeline sequence appears on a single line" {
  grep -q 'quick-spec.*quick-dev' "${AGENT_FILE}"
}

@test "Structural: exit code table has all 4 codes with correct meanings" {
  # Exit code table must contain all 4 rows
  grep -q '| 0 |.*Stage completed' "${AGENT_FILE}"
  grep -q '| 1 |.*Failed' "${AGENT_FILE}"
  grep -q '| 2 |.*Pipeline complete' "${AGENT_FILE}"
  grep -q '| 3 |.*Checkpoint pause' "${AGENT_FILE}"
}

@test "Structural: agent handles paused status on cold start" {
  grep -qi 'paused.*running\|paused.*proceed\|paused.*resume' "${AGENT_FILE}"
}

@test "Structural: agent handles template not found gracefully" {
  grep -qi 'template.*not.*exist\|template.*not found\|template.*does not exist' "${AGENT_FILE}"
}

@test "Structural: CONCERNS quality gate has explicit handling" {
  grep -q 'CONCERNS' "${AGENT_FILE}"
  grep -qi 'PASS (CONCERNS)\|PASS.*CONCERNS' "${AGENT_FILE}"
}

@test "Structural: story loop iteration logic is defined" {
  grep -qi 'stories\[\]' "${AGENT_FILE}"
  grep -qi 'epic.*completed\|story.*completed' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 1.4 Tests: Task Routing Logic (AC: #1-#5)
# ──────────────────────────────────────────────

@test "Routing 1.4-1: agent definition contains routing decision logic (not old placeholder)" {
  # The old placeholder text should be gone
  ! grep -q 'Routing not yet implemented' "${AGENT_FILE}"
  ! grep -q 'Run routing first (Story 1.4)' "${AGENT_FILE}"
  # Routing protocol should be present
  grep -q 'Routing Protocol' "${AGENT_FILE}"
}

@test "Routing 1.4-2: Quick Flow routing guidelines are present" {
  grep -qi 'single-file.*changes\|bug.*fix' "${AGENT_FILE}"
  grep -qi 'small.*utilit\|narrow.*task\|well-defined' "${AGENT_FILE}"
  grep -qi 'styling.*fix\|typo.*correction\|simple.*refactor' "${AGENT_FILE}"
}

@test "Routing 1.4-3: Full Method routing guidelines are present" {
  grep -qi 'multi-component.*feature' "${AGENT_FILE}"
  grep -qi 'architectural.*change' "${AGENT_FILE}"
  grep -qi 'ambiguous.*scope\|broad.*scope' "${AGENT_FILE}"
  grep -qi 'database.*schema\|API.*design' "${AGENT_FILE}"
}

@test "Routing 1.4-4: override bypass logic skips routing when route is already set" {
  grep -qi 'route.*already.*set\|override\|skip.*routing.*analysis' "${AGENT_FILE}"
  grep -qi 'not.*null\|quick.*or.*full' "${AGENT_FILE}"
}

@test "Routing 1.4-5: first stage mapping — full -> prd, quick -> quick-spec" {
  grep -q 'full.*prd\|route.*is.*full.*currentStage.*prd' "${AGENT_FILE}"
  grep -q 'quick.*quick-spec\|route.*is.*quick.*currentStage.*quick-spec' "${AGENT_FILE}"
}

@test "Routing 1.4-6: atomic state update after routing sets route, currentStage, updatedAt" {
  grep -qi 'atomic.*state.*update\|Section 7\.2' "${AGENT_FILE}"
  grep -q 'route.*determined.*value\|Set.*route' "${AGENT_FILE}"
  grep -q 'currentStage.*first.*stage\|Set.*currentStage' "${AGENT_FILE}"
  grep -q 'updatedAt.*ISO-8601\|Set.*updatedAt' "${AGENT_FILE}"
}

@test "Routing 1.4-7: after routing, proceeds to template loading — does NOT exit" {
  grep -qi 'proceed.*Template Loading\|proceed.*Section 3' "${AGENT_FILE}"
  grep -qi 'do NOT exit\|do not exit\|NOT exit' "${AGENT_FILE}"
}

@test "Routing 1.4-8: default to full when uncertain — safety heuristic present" {
  grep -qi 'uncertain.*prefer.*full\|when uncertain.*full' "${AGENT_FILE}"
}

@test "Routing 1.4-9: terminal states checked before routing (failed/completed before null stage)" {
  # completed and failed checks must appear BEFORE the currentStage null routing check
  local completed_line failed_line routing_line
  completed_line=$(grep -n 'status.*is.*completed\|completed.*Pipeline.*done' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  failed_line=$(grep -n 'status.*is.*failed\|failed.*Pipeline.*previously' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  routing_line=$(grep -n 'currentStage.*is.*null.*Routing is needed' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${completed_line}" ] && [ -n "${failed_line}" ] && [ -n "${routing_line}" ]
  [ "${completed_line}" -lt "${routing_line}" ]
  [ "${failed_line}" -lt "${routing_line}" ]
}

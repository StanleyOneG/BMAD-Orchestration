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

# ──────────────────────────────────────────────
# Story 1.5 Tests: First Stage Template — stage-prd.md (AC: #1, #5)
# ──────────────────────────────────────────────

TEMPLATE_FILE=".bmad-orchestrator/templates/stage-prd.md"

@test "Template 1.5-1: stage-prd.md template file exists" {
  [ -f "${TEMPLATE_FILE}" ]
}

@test "Template 1.5-2: template has valid YAML frontmatter with stage: prd" {
  head -1 "${TEMPLATE_FILE}" | grep -q '^---$'
  grep -q 'stage: prd' "${TEMPLATE_FILE}"
}

@test "Template 1.5-3: template frontmatter contains agent: bmad-pm" {
  grep -q 'agent: bmad-pm' "${TEMPLATE_FILE}"
}

@test "Template 1.5-4: template frontmatter contains command: CP" {
  grep -q 'command: CP' "${TEMPLATE_FILE}"
}

@test "Template 1.5-5: template frontmatter contains requiredArtifacts: []" {
  grep -q 'requiredArtifacts: \[\]' "${TEMPLATE_FILE}"
}

@test "Template 1.5-6: template frontmatter contains producedArtifacts with prd.md" {
  grep -q 'producedArtifacts' "${TEMPLATE_FILE}"
  grep -q 'prd\.md' "${TEMPLATE_FILE}"
}

@test "Template 1.5-7: template contains Context Injection section" {
  grep -q '## Context Injection' "${TEMPLATE_FILE}"
}

@test "Template 1.5-8: template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${TEMPLATE_FILE}"
}

@test "Template 1.5-9: template contains Verification section" {
  grep -q '## Verification' "${TEMPLATE_FILE}"
}

@test "Template 1.5-10: template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${TEMPLATE_FILE}"
}

@test "Template 1.5-11: template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${TEMPLATE_FILE}"
}

@test "Template 1.5-12: template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${TEMPLATE_FILE}"
}

# ──────────────────────────────────────────────
# Story 2.1 Tests: Architecture Stage Template — stage-architecture.md (AC: #1)
# ──────────────────────────────────────────────

ARCH_TEMPLATE=".bmad-orchestrator/templates/stage-architecture.md"

@test "Template 2.1-1: stage-architecture.md template file exists" {
  [ -f "${ARCH_TEMPLATE}" ]
}

@test "Template 2.1-2: architecture template has valid YAML frontmatter with stage: architecture" {
  head -1 "${ARCH_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: architecture' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-3: architecture template frontmatter contains agent: bmad-architect" {
  grep -q 'agent: bmad-architect' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-4: architecture template frontmatter contains command: CA" {
  grep -q 'command: CA' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-5: architecture template frontmatter contains requiredArtifacts with prd.md" {
  grep -q 'requiredArtifacts' "${ARCH_TEMPLATE}"
  grep -q 'prd\.md' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-6: architecture template frontmatter contains producedArtifacts with architecture.md" {
  grep -q 'producedArtifacts' "${ARCH_TEMPLATE}"
  grep -q 'architecture\.md' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-7: architecture template contains Context Injection section" {
  grep -q '## Context Injection' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-8: architecture template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-9: architecture template contains Verification section" {
  grep -q '## Verification' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-10: architecture template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-11: architecture template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${ARCH_TEMPLATE}"
}

@test "Template 2.1-12: architecture template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${ARCH_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.1 Tests: Epics-Stories Stage Template — stage-epics-stories.md (AC: #2)
# ──────────────────────────────────────────────

EPICS_TEMPLATE=".bmad-orchestrator/templates/stage-epics-stories.md"

@test "Template 2.1-13: stage-epics-stories.md template file exists" {
  [ -f "${EPICS_TEMPLATE}" ]
}

@test "Template 2.1-14: epics-stories template has valid YAML frontmatter with stage: epics-stories" {
  head -1 "${EPICS_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: epics-stories' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-15: epics-stories template frontmatter contains agent: bmad-pm" {
  grep -q 'agent: bmad-pm' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-16: epics-stories template frontmatter contains command: CE" {
  grep -q 'command: CE' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-17: epics-stories template frontmatter contains requiredArtifacts with prd.md AND architecture.md" {
  grep -q 'requiredArtifacts' "${EPICS_TEMPLATE}"
  grep -q 'prd\.md' "${EPICS_TEMPLATE}"
  grep -q 'architecture\.md' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-18: epics-stories template frontmatter contains producedArtifacts with epics.md" {
  grep -q 'producedArtifacts' "${EPICS_TEMPLATE}"
  grep -q 'epics\.md' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-19: epics-stories template contains Context Injection section" {
  grep -q '## Context Injection' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-20: epics-stories template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-21: epics-stories template contains Verification section" {
  grep -q '## Verification' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-22: epics-stories template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-23: epics-stories template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${EPICS_TEMPLATE}"
}

@test "Template 2.1-24: epics-stories template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${EPICS_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.2 Tests: Implementation Readiness Stage Template — stage-readiness.md (AC: #1, #2)
# ──────────────────────────────────────────────

READINESS_TEMPLATE=".bmad-orchestrator/templates/stage-readiness.md"

@test "Template 2.2-1: stage-readiness template exists" {
  [ -f "${READINESS_TEMPLATE}" ]
}

@test "Template 2.2-2: readiness template has valid YAML frontmatter with stage: readiness" {
  head -1 "${READINESS_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: readiness' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-3: readiness template frontmatter contains agent: bmad-pm" {
  grep -q 'agent: bmad-pm' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-4: readiness template frontmatter contains command: IR" {
  grep -q 'command: IR' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-5: readiness template frontmatter contains requiredArtifacts with prd.md, architecture.md, and epics.md" {
  grep -q 'requiredArtifacts' "${READINESS_TEMPLATE}"
  grep -q 'prd\.md' "${READINESS_TEMPLATE}"
  grep -q 'architecture\.md' "${READINESS_TEMPLATE}"
  grep -q 'epics\.md' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-6: readiness template frontmatter contains producedArtifacts with implementation-readiness-report.md" {
  grep -q 'producedArtifacts' "${READINESS_TEMPLATE}"
  grep -q 'implementation-readiness-report\.md' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-7: readiness template contains Context Injection section" {
  grep -q '## Context Injection' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-8: readiness template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-9: readiness template contains Verification section" {
  grep -q '## Verification' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-10: readiness template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-11: readiness template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-12: readiness template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-13: readiness template contains tri-state quality gate (PASS/CONCERNS/FAIL)" {
  grep -q 'PASS' "${READINESS_TEMPLATE}"
  grep -q 'CONCERNS' "${READINESS_TEMPLATE}"
  grep -q 'FAIL' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-14: readiness template contains Quality Gate Interpretation section" {
  grep -q '### Quality Gate Interpretation' "${READINESS_TEMPLATE}"
}

@test "Template 2.2-15: readiness template references sprint-planning as next stage" {
  grep -q 'sprint-planning' "${READINESS_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.3 Tests: Sprint Planning Stage Template — stage-sprint-planning.md (AC: #3, #4, #5)
# ──────────────────────────────────────────────

SPRINT_TEMPLATE=".bmad-orchestrator/templates/stage-sprint-planning.md"

@test "Template 2.3-1: stage-sprint-planning.md template file exists" {
  [ -f "${SPRINT_TEMPLATE}" ]
}

@test "Template 2.3-2: sprint-planning template has valid YAML frontmatter with stage: sprint-planning" {
  head -1 "${SPRINT_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: sprint-planning' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-3: sprint-planning template frontmatter contains agent: bmad-sm" {
  grep -q 'agent: bmad-sm' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-4: sprint-planning template frontmatter contains command: SP" {
  grep -q 'command: SP' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-5: sprint-planning template frontmatter contains requiredArtifacts with epics.md and architecture.md" {
  grep -q 'requiredArtifacts' "${SPRINT_TEMPLATE}"
  grep -q 'epics\.md' "${SPRINT_TEMPLATE}"
  grep -q 'architecture\.md' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-6: sprint-planning template frontmatter contains producedArtifacts with sprint-status.yaml" {
  grep -q 'producedArtifacts' "${SPRINT_TEMPLATE}"
  grep -q 'sprint-status\.yaml' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-7: sprint-planning template contains Context Injection section" {
  grep -q '## Context Injection' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-8: sprint-planning template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-9: sprint-planning template contains Verification section" {
  grep -q '## Verification' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-10: sprint-planning template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-11: sprint-planning template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${SPRINT_TEMPLATE}"
}

@test "Template 2.3-12: sprint-planning template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${SPRINT_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.3 Tests: storyLoop Population Logic in Orchestrator Agent (AC: #1, #2)
# ──────────────────────────────────────────────

@test "StoryLoop 2.3-1: agent definition mentions storyLoop population or building" {
  grep -qi 'storyLoop.*populat\|populat.*storyLoop\|build.*storyLoop\|storyLoop.*build' "${AGENT_FILE}"
}

@test "StoryLoop 2.3-2: agent definition handles storyLoop being null or empty" {
  grep -qi 'storyLoop.*null\|null.*storyLoop\|storyLoop.*empty\|empty.*storyLoop' "${AGENT_FILE}"
}

@test "StoryLoop 2.3-3: agent definition references parsing epic files for storyLoop construction" {
  grep -qi 'epic.*file\|epic.*pars\|pars.*epic' "${AGENT_FILE}"
  grep -qi 'storyLoop' "${AGENT_FILE}"
}

@test "StoryLoop 2.3-4: agent definition specifies atomic write after storyLoop population" {
  grep -qi 'atomic.*state\|state\.yaml\.tmp' "${AGENT_FILE}"
  grep -qi 'storyLoop' "${AGENT_FILE}"
}

@test "StoryLoop 2.3-5: storyLoop population subsection appears before Template Loading section" {
  local pop_line tl_line
  pop_line=$(grep -n 'storyLoop Population' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  tl_line=$(grep -n '## 3\. Template Loading' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${pop_line}" ] && [ -n "${tl_line}" ]
  [ "${pop_line}" -lt "${tl_line}" ]
}

@test "StoryLoop 2.3-6: storyLoop population subsection is inside Section 2 (Pipeline Stage Sequences)" {
  local s2_line pop_line s3_line
  s2_line=$(grep -n '## 2\. Pipeline Stage' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  pop_line=$(grep -n 'storyLoop Population' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s3_line=$(grep -n '## 3\. Template Loading' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s2_line}" ] && [ -n "${pop_line}" ] && [ -n "${s3_line}" ]
  [ "${s2_line}" -lt "${pop_line}" ]
  [ "${pop_line}" -lt "${s3_line}" ]
}

@test "StoryLoop 2.3-7: storyLoop population defines deterministic ID slugification rules" {
  grep -qi 'slugif\|deterministic.*ID\|slug.*rule' "${AGENT_FILE}"
  grep -qi 'epic-.*{N}\|story.*slug' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 2.4 Tests: Create Story Stage Template — stage-create-story.md (AC: #2, #3, #4)
# ──────────────────────────────────────────────

CREATE_STORY_TEMPLATE=".bmad-orchestrator/templates/stage-create-story.md"

@test "Template 2.4-1: stage-create-story.md template file exists" {
  [ -f "${CREATE_STORY_TEMPLATE}" ]
}

@test "Template 2.4-2: create-story template has valid YAML frontmatter with stage: create-story" {
  head -1 "${CREATE_STORY_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: create-story' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-3: create-story template frontmatter contains agent: bmad-sm" {
  grep -q 'agent: bmad-sm' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-4: create-story template frontmatter contains command: CS" {
  grep -q 'command: CS' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-5: create-story template frontmatter contains requiredArtifacts with epics.md" {
  grep -q 'requiredArtifacts' "${CREATE_STORY_TEMPLATE}"
  grep -q 'epics\.md' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-6: create-story template frontmatter contains requiredArtifacts with sprint-status.yaml" {
  grep -q 'requiredArtifacts' "${CREATE_STORY_TEMPLATE}"
  grep -q 'sprint-status\.yaml' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-7: create-story template frontmatter contains producedArtifacts with {{story_key}} dynamic placeholder" {
  grep -q 'producedArtifacts' "${CREATE_STORY_TEMPLATE}"
  grep -q '{{story_key}}' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-7b: create-story template frontmatter contains requiredArtifacts with architecture.md" {
  grep -q 'requiredArtifacts' "${CREATE_STORY_TEMPLATE}"
  grep -q 'architecture\.md' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-8: create-story template contains Context Injection section" {
  grep -q '## Context Injection' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-9: create-story template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-10: create-story template contains Verification section" {
  grep -q '## Verification' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-11: create-story template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-12: create-story template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${CREATE_STORY_TEMPLATE}"
}

@test "Template 2.4-13: create-story template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${CREATE_STORY_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.4 Tests: Story Loop Phase Handling in Orchestrator Agent (AC: #1, #2, #7)
# ──────────────────────────────────────────────

@test "StoryLoop 2.4-1: agent describes default phase assignment for stories with no phase field" {
  grep -qi 'default.*phase\|phase.*create-story\|default phase assignment' "${AGENT_FILE}"
  grep -qi 'pending.*phase\|phase.*null\|phase.*undefined\|phase.*missing' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-2: agent describes story key extraction/injection for create-story stage" {
  grep -qi 'story.*key.*extract\|extract.*story.*key\|story key.*inject\|inject.*story key' "${AGENT_FILE}"
  grep -qi '{{story_key}}' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-2b: Phase Initialization subsection references producedArtifacts resolution with story key" {
  grep -qi 'producedArtifacts.*{{story_key}}\|{{story_key}}.*producedArtifacts\|Resolve.*producedArtifacts.*story key\|producedArtifacts.*replacing.*{{story_key}}' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-2c: Phase Initialization subsection defines skip condition for already-phased stories" {
  grep -qi 'skip.*phase.*assignment\|already.*has.*valid.*phase\|skip condition' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-3: agent describes phase transition from create-story to dev-story" {
  grep -qi 'phase.*dev-story\|create-story.*dev-story\|phase transition' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-4: agent describes status update to created after create-story completes" {
  grep -qi 'status.*created\|created.*status' "${AGENT_FILE}"
}

@test "StoryLoop 2.4-5: agent documents storyLoop vs sprint-status.yaml as separate status vocabularies" {
  grep -qi 'intentionally separate' "${AGENT_FILE}"
  grep -qi 'sprint-status\.yaml.*vocabulary\|status.*vocabulary.*sprint-status' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 2.5 Tests: Dev Story Stage Template — stage-dev-story.md (AC: #1, #3, #4)
# ──────────────────────────────────────────────

DEV_STORY_TEMPLATE=".bmad-orchestrator/templates/stage-dev-story.md"

@test "Template 2.5-1: stage-dev-story.md template file exists" {
  [ -f "${DEV_STORY_TEMPLATE}" ]
}

@test "Template 2.5-2: dev-story template has valid YAML frontmatter with stage: dev-story" {
  head -1 "${DEV_STORY_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: dev-story' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-3: dev-story template frontmatter contains agent: bmad-dev" {
  grep -q 'agent: bmad-dev' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-4: dev-story template frontmatter contains command: DS" {
  grep -q 'command: DS' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-5: dev-story template frontmatter contains requiredArtifacts with {{story_key}}.md" {
  grep -q 'requiredArtifacts' "${DEV_STORY_TEMPLATE}"
  grep -q '{{story_key}}\.md' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-6: dev-story template frontmatter contains requiredArtifacts with architecture.md" {
  grep -q 'requiredArtifacts' "${DEV_STORY_TEMPLATE}"
  grep -q 'architecture\.md' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-7: dev-story template frontmatter contains producedArtifacts" {
  grep -q 'producedArtifacts' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-8: dev-story template contains Context Injection section" {
  grep -q '## Context Injection' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-9: dev-story template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-10: dev-story template contains Verification section" {
  grep -q '## Verification' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-11: dev-story template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-12: dev-story template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${DEV_STORY_TEMPLATE}"
}

@test "Template 2.5-13: dev-story template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${DEV_STORY_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.5 Tests: Code Review Stage Template — stage-code-review.md (AC: #2, #3, #5, #6)
# ──────────────────────────────────────────────

CODE_REVIEW_TEMPLATE=".bmad-orchestrator/templates/stage-code-review.md"

@test "Template 2.5-14: stage-code-review.md template file exists" {
  [ -f "${CODE_REVIEW_TEMPLATE}" ]
}

@test "Template 2.5-15: code-review template has valid YAML frontmatter with stage: code-review" {
  head -1 "${CODE_REVIEW_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: code-review' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-16: code-review template frontmatter contains agent: bmad-dev" {
  grep -q 'agent: bmad-dev' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-17: code-review template frontmatter contains command: CR" {
  grep -q 'command: CR' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-18: code-review template frontmatter contains requiredArtifacts with {{story_key}}.md" {
  grep -q 'requiredArtifacts' "${CODE_REVIEW_TEMPLATE}"
  grep -q '{{story_key}}\.md' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-19: code-review template frontmatter contains requiredArtifacts with architecture.md" {
  grep -q 'requiredArtifacts' "${CODE_REVIEW_TEMPLATE}"
  grep -q 'architecture\.md' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-20: code-review template frontmatter contains producedArtifacts" {
  grep -q 'producedArtifacts' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-21: code-review template contains Context Injection section" {
  grep -q '## Context Injection' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-22: code-review template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-23: code-review template contains Verification section" {
  grep -q '## Verification' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-24: code-review template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-25: code-review template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-26: code-review template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-27: code-review template contains tri-state quality gate (PASS/CONCERNS/FAIL)" {
  grep -q 'PASS' "${CODE_REVIEW_TEMPLATE}"
  grep -q 'CONCERNS' "${CODE_REVIEW_TEMPLATE}"
  grep -q 'FAIL' "${CODE_REVIEW_TEMPLATE}"
}

@test "Template 2.5-28: code-review template contains Quality Gate Interpretation section" {
  grep -q '### Quality Gate Interpretation' "${CODE_REVIEW_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.5 Tests: Phase Handling in Orchestrator Agent (AC: #1, #2, #5, #6, #7)
# ──────────────────────────────────────────────

@test "StoryLoop 2.5-1: agent describes phase transition from dev-story to code-review" {
  grep -qi 'phase.*dev-story.*code-review\|dev-story.*to.*code-review\|Phase Transition.*Dev-Story.*Code-Review' "${AGENT_FILE}"
}

@test "StoryLoop 2.5-2: agent describes status update to implemented after dev-story" {
  grep -qi 'status.*implemented\|implemented.*status' "${AGENT_FILE}"
}

@test "StoryLoop 2.5-3: agent describes status update to completed after code-review" {
  grep -qi 'status.*completed\|completed.*status' "${AGENT_FILE}"
  grep -qi 'code-review.*completed\|Code-Review.*Completed' "${AGENT_FILE}"
}

@test "StoryLoop 2.5-4: agent describes code-review failure re-routing back to dev-story phase" {
  grep -qi 'revert.*phase.*dev-story\|phase.*back.*dev-story\|re-rout.*dev-story' "${AGENT_FILE}"
  grep -qi 'NOT standard.*re-routing\|NOT standard upstream\|not standard failure' "${AGENT_FILE}"
}

@test "StoryLoop 2.5-5: agent describes git commit expectations during dev-story" {
  grep -qi 'git.*commit.*dev-story\|dev.*sub-agent.*git.*commit\|Dev.*sub-agent.*commit' "${AGENT_FILE}"
  grep -qi 'orchestrator.*NOT.*commit\|orchestrator.*verif.*commit\|does NOT make commits' "${AGENT_FILE}"
}

@test "StoryLoop 2.5-6: agent describes code-review requiring fresh/new Task sub-agent with clean context window" {
  grep -qi 'fresh.*Task.*sub-agent\|NEW.*Task tool.*sub-agent\|FRESH.*Task tool\|fresh.*sub-agent\|NEW.*FRESH.*Task' "${AGENT_FILE}"
  grep -qi 'clean context window\|clean.*context' "${AGENT_FILE}"
}

@test "Template 2.5-29: code-review template explicitly requires fresh/new sub-agent launch" {
  grep -qi 'fresh.*sub-agent\|NEW.*FRESH.*sub-agent\|new.*Task tool invocation\|clean context window' "${CODE_REVIEW_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.6 Tests: Quick Spec Stage Template — stage-quick-spec.md (AC: #2, #5)
# ──────────────────────────────────────────────

QUICK_SPEC_TEMPLATE=".bmad-orchestrator/templates/stage-quick-spec.md"

@test "Template 2.6-1: stage-quick-spec.md template file exists" {
  [ -f "${QUICK_SPEC_TEMPLATE}" ]
}

@test "Template 2.6-2: quick-spec template has valid YAML frontmatter with stage: quick-spec" {
  head -1 "${QUICK_SPEC_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: quick-spec' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-3: quick-spec template frontmatter contains agent: bmad-quick-flow" {
  grep -q 'agent: bmad-quick-flow' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-4: quick-spec template frontmatter contains command: TS" {
  grep -q 'command: TS' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-5: quick-spec template frontmatter contains requiredArtifacts (empty array)" {
  grep -q 'requiredArtifacts: \[\]' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-6: quick-spec template frontmatter contains producedArtifacts with tech-spec" {
  grep -q 'producedArtifacts' "${QUICK_SPEC_TEMPLATE}"
  grep -q 'tech-spec\.md' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-7: quick-spec template contains Context Injection section" {
  grep -q '## Context Injection' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-8: quick-spec template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-9: quick-spec template contains Verification section" {
  grep -q '## Verification' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-10: quick-spec template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-11: quick-spec template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${QUICK_SPEC_TEMPLATE}"
}

@test "Template 2.6-12: quick-spec template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${QUICK_SPEC_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.6 Tests: Quick Dev Stage Template — stage-quick-dev.md (AC: #3, #5)
# ──────────────────────────────────────────────

QUICK_DEV_TEMPLATE=".bmad-orchestrator/templates/stage-quick-dev.md"

@test "Template 2.6-13: stage-quick-dev.md template file exists" {
  [ -f "${QUICK_DEV_TEMPLATE}" ]
}

@test "Template 2.6-14: quick-dev template has valid YAML frontmatter with stage: quick-dev" {
  head -1 "${QUICK_DEV_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: quick-dev' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-15: quick-dev template frontmatter contains agent: bmad-quick-flow" {
  grep -q 'agent: bmad-quick-flow' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-16: quick-dev template frontmatter contains command: QD" {
  grep -q 'command: QD' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-17: quick-dev template frontmatter contains requiredArtifacts with tech-spec" {
  grep -q 'requiredArtifacts' "${QUICK_DEV_TEMPLATE}"
  grep -q 'tech-spec\.md' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-18: quick-dev template frontmatter contains producedArtifacts with tech-spec" {
  grep -q 'producedArtifacts' "${QUICK_DEV_TEMPLATE}"
  grep -q 'tech-spec\.md' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-19: quick-dev template contains Context Injection section" {
  grep -q '## Context Injection' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-20: quick-dev template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-21: quick-dev template contains Verification section" {
  grep -q '## Verification' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-22: quick-dev template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-23: quick-dev template contains {{failure_context}} placeholder" {
  grep -q '{{failure_context}}' "${QUICK_DEV_TEMPLATE}"
}

@test "Template 2.6-24: quick-dev template contains {{mode_instructions}} placeholder" {
  grep -q '{{mode_instructions}}' "${QUICK_DEV_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 2.6 Tests: Quick Flow Routing Support in Orchestrator (AC: #1, #4)
# ──────────────────────────────────────────────

@test "QuickFlow 2.6-1: agent mentions quick-spec to quick-dev sequence" {
  grep -q 'quick-spec.*quick-dev' "${AGENT_FILE}"
}

@test "QuickFlow 2.6-2: agent describes Quick Flow track for route: quick" {
  grep -qi 'Quick Flow Track\|Quick Flow' "${AGENT_FILE}"
  grep -q 'route: quick' "${AGENT_FILE}"
}

@test "QuickFlow 2.6-3: agent routes to quick-spec as first stage when route is quick" {
  grep -q 'quick.*quick-spec\|route.*is.*quick.*currentStage.*quick-spec' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 2.7 Tests: File Reference Detection in Orchestrator Agent (AC: #1, #2, #3)
# ──────────────────────────────────────────────

SLASH_CMD_FILE=".claude/commands/bmad-orchestrate.md"

@test "FileRef 2.7-1: agent describes file reference detection from task description" {
  grep -qi 'file.*reference.*detection\|file reference' "${AGENT_FILE}"
  grep -qi 'task.*field\|task.*text\|task.*description' "${AGENT_FILE}"
}

@test "FileRef 2.7-2: agent mentions scanning for file paths in the task text" {
  grep -qi 'scan.*task.*file.*path\|file.*path.*pattern\|scan.*task.*text' "${AGENT_FILE}"
}

@test "FileRef 2.7-3: agent describes handling when referenced file exists (read and include as context)" {
  grep -qi 'file.*exists.*store\|file exists.*content\|If file exists' "${AGENT_FILE}"
  grep -qi 'fileContext' "${AGENT_FILE}"
}

@test "FileRef 2.7-4: agent describes handling when referenced file does NOT exist (warning, continue)" {
  grep -qi 'file.*not.*exist.*warning\|not found.*warning\|Warning.*Referenced file not found\|does NOT exist.*warning\|NOT exist.*log.*warning' "${AGENT_FILE}"
  grep -qi 'do NOT fail\|not fail\|continuing without' "${AGENT_FILE}"
}

@test "FileRef 2.7-5: agent describes including file context when launching sub-agents" {
  grep -qi 'fileContext.*populated\|fileContext.*sub-agent\|file.*context.*alongside\|Referenced file.*path' "${AGENT_FILE}"
}

@test "FileRef 2.7-6: agent mentions NOT persisting file contents to state.yaml" {
  grep -qi 'NOT.*persisted.*state\.yaml\|not.*persist.*state\|session variable only' "${AGENT_FILE}"
}

@test "FileRef 2.7-7: agent describes excluding URLs from file reference detection" {
  grep -qi 'http://\|https://\|Exclude.*URL\|URL.*exclude' "${AGENT_FILE}"
}

@test "FileRef 2.7-8: agent describes excluding CLI flags from file reference detection" {
  grep -qi 'CLI.*flag\|--flag\|Exclude.*flag' "${AGENT_FILE}"
}

@test "FileRef 2.7-9: agent describes excluding email addresses from file reference detection" {
  grep -qi 'email.*address\|containing.*@\|Exclude.*email' "${AGENT_FILE}"
}

@test "FileRef 2.7-10: agent describes common file extensions for detection" {
  grep -qi '\.md.*\.yaml\|\.json.*\.txt\|common.*extension' "${AGENT_FILE}"
}

@test "FileRef 2.7-11: fileContext injection documented in Section 4 (Sub-Agent Interaction)" {
  local s4_line fc_line
  s4_line=$(grep -n '## 4\. Sub-Agent' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  fc_line=$(grep -n 'fileContext.*populated' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s4_line}" ] && [ -n "${fc_line}" ]
  [ "${fc_line}" -gt "${s4_line}" ]
}

@test "FileRef 2.7-12: file reference detection section appears after Section 1.2 and before Section 2" {
  local fr_line s2_line
  fr_line=$(grep -n 'File Reference Detection' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s2_line=$(grep -n '## 2\. Pipeline Stage' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${fr_line}" ] && [ -n "${s2_line}" ]
  [ "${fr_line}" -lt "${s2_line}" ]
}

# ──────────────────────────────────────────────
# Story 2.7 Tests: Resume Behavior Documentation in Orchestrator Agent (AC: #4, #6)
# ──────────────────────────────────────────────

@test "Resume 2.7-1: agent describes resume behavior (transparent via state file)" {
  grep -qi 'Resume Behavior\|resume.*transparent\|state file IS the resume mechanism\|state file.*IS.*resume' "${AGENT_FILE}"
}

@test "Resume 2.7-2: agent describes artifact respect on resume (completed stages honored)" {
  grep -qi 'Artifact Respect on Resume\|artifact.*respect.*resume\|does not regenerate completed stages\|completedStages.*tracks' "${AGENT_FILE}"
}

@test "Resume 2.7-3: agent mentions orchestrator trusts state and picks up where stopped" {
  grep -qi 'picks up exactly where\|trusts these\|picks up.*where.*stopped\|picks up.*previous.*run' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 2.7 Tests: Slash Command Resume Handling (AC: #4, #5)
# ──────────────────────────────────────────────

@test "Resume 2.7-4: slash command describes --resume flag handling" {
  grep -qi '\-\-resume' "${SLASH_CMD_FILE}"
  grep -qi 'resume' "${SLASH_CMD_FILE}"
}

@test "Resume 2.7-5: slash command reads existing state.yaml on resume" {
  grep -qi 'Read.*existing.*state\.yaml\|existing.*state\.yaml.*exist\|state\.yaml.*exists' "${SLASH_CMD_FILE}"
}

@test "Resume 2.7-6: slash command sets runType: resume on resume" {
  grep -q 'runType: resume\|runType.*resume' "${SLASH_CMD_FILE}"
}

@test "Resume 2.7-7: slash command sets status: running on resume" {
  grep -q 'status: running' "${SLASH_CMD_FILE}"
}

@test "Resume 2.7-8: slash command fails with error when no state.yaml exists for resume" {
  grep -qi 'No existing state\.yaml found\|Cannot resume without a previous run\|No.*state\.yaml.*Cannot resume' "${SLASH_CMD_FILE}"
}

@test "Resume 2.7-9: slash command uses atomic write for resume update" {
  grep -q 'state\.yaml\.tmp' "${SLASH_CMD_FILE}"
  grep -qi 'rename\|mv.*state\.yaml\|atomic write' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Failure Detection in Orchestrator Agent (AC: #1, #2)
# ──────────────────────────────────────────────

@test "Failure 3.1-1: agent describes verification failure detection for missing artifacts" {
  grep -qi 'producedArtifacts.*exist\|verify.*producedArtifacts\|Artifact Check' "${AGENT_FILE}"
  grep -qi 'exist on disk\|Check each file path' "${AGENT_FILE}"
}

@test "Failure 3.1-2: agent describes goal alignment check as part of verification" {
  grep -qi 'Goal Alignment\|goal.*alignment\|compare.*output.*against.*task' "${AGENT_FILE}"
}

@test "Failure 3.1-3: agent describes quality gate tri-state (PASS/CONCERNS/FAIL)" {
  grep -q 'PASS' "${AGENT_FILE}"
  grep -q 'CONCERNS' "${AGENT_FILE}"
  grep -q 'FAIL' "${AGENT_FILE}"
  grep -qi 'Quality Gate' "${AGENT_FILE}"
}

@test "Failure 3.1-4: agent describes FAIL triggering failure handling (Section 6)" {
  grep -qi 'FAIL.*trigger.*failure\|FAIL.*failure handling\|FAIL.*Section 5\.5\|FAIL.*Section 6' "${AGENT_FILE}"
}

@test "Failure 3.1-5: agent describes CONCERNS as pass-with-warnings (not failure)" {
  grep -qi 'CONCERNS.*pass\|CONCERNS.*proceed\|CONCERNS.*warning' "${AGENT_FILE}"
  grep -qi 'PASS (CONCERNS)\|PASS.*CONCERNS' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Retry Logic in Orchestrator Agent (AC: #3, #4, #5)
# ──────────────────────────────────────────────

@test "Failure 3.1-6: agent describes failures array format (stage, attempt, error, timestamp)" {
  grep -q 'stage:' "${AGENT_FILE}"
  grep -q 'attempt:' "${AGENT_FILE}"
  grep -q 'error:' "${AGENT_FILE}"
  grep -q 'timestamp:' "${AGENT_FILE}"
  grep -qi 'failures.*array\|failures' "${AGENT_FILE}"
}

@test "Failure 3.1-7: agent describes single-line error summaries in failures array" {
  grep -qi 'single-line.*error\|single.line.*error.*summar\|error.*single.line' "${AGENT_FILE}"
}

@test "Failure 3.1-8: agent describes currentRetries increment on failure" {
  grep -qi 'increment.*currentRetries\|Increment.*currentRetries\|currentRetries.*increment' "${AGENT_FILE}"
}

@test "Failure 3.1-9: agent describes currentStage unchanged on retry (stays on failed stage)" {
  grep -qi 'currentStage.*unchanged\|keep.*currentStage\|currentStage.*unchanged' "${AGENT_FILE}"
}

@test "Failure 3.1-10: agent describes exit code 0 for retry" {
  grep -qi 'Exit code 0.*retry\|exit code 0\|exit.*0.*retry\|code 0' "${AGENT_FILE}"
}

@test "Failure 3.1-11: agent describes currentRetries reset to 0 on success" {
  grep -qi 'currentRetries.*reset.*0\|reset.*currentRetries.*0\|currentRetries.*0.*success' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Terminal Failure Logic (AC: #5)
# ──────────────────────────────────────────────

@test "Failure 3.1-12: agent describes maxRetries check for terminal failure" {
  grep -qi 'currentRetries.*>=.*maxRetries\|maxRetries.*terminal\|currentRetries.*maxRetries' "${AGENT_FILE}"
}

@test "Failure 3.1-13: agent describes status: failed when retries exhausted" {
  grep -qi 'status.*failed\|status: failed' "${AGENT_FILE}"
  grep -qi 'maxRetries' "${AGENT_FILE}"
}

@test "Failure 3.1-14: agent describes exit code 1 for terminal failure" {
  grep -qi 'Exit code 1\|exit code 1\|exit.*1.*stop\|code 1.*fail' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Failure Context Injection (AC: #6)
# ──────────────────────────────────────────────

@test "Failure 3.1-15: agent describes failure_context injection into template" {
  grep -qi 'failure_context.*inject\|inject.*failure_context\|{{failure_context}}.*template\|failure.*context.*inject' "${AGENT_FILE}"
}

@test "Failure 3.1-16: agent describes extracting previous failure info from failures array" {
  grep -qi 'failure.*entries.*match\|Filter.*failures\|Extract.*entries.*failures\|failures.*array.*match.*currentStage' "${AGENT_FILE}"
}

@test "Failure 3.1-17: agent describes failure context construction mechanism (Section 3.4)" {
  grep -qi 'Failure Context Construction\|failure.*context.*construct\|Build.*context.*string' "${AGENT_FILE}"
}

@test "Failure 3.1-18: agent describes checking currentRetries before constructing failure context" {
  grep -qi 'currentRetries.*0\|Check retry state\|currentRetries is 0' "${AGENT_FILE}"
}

@test "Failure 3.1-19: agent describes failure context format (attempt number and error)" {
  grep -qi 'Attempt.*error\|attempt.*error.*summary\|Attempt <attempt>: <error>' "${AGENT_FILE}"
}

@test "Failure 3.1-20: failure context construction section appears between Template Loading and Sub-Agent Interaction" {
  local fc_line s4_line s3_line
  s3_line=$(grep -n '## 3\. Template Loading' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  fc_line=$(grep -n 'Failure Context Construction' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s4_line=$(grep -n '## 4\. Sub-Agent' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s3_line}" ] && [ -n "${fc_line}" ] && [ -n "${s4_line}" ]
  [ "${s3_line}" -lt "${fc_line}" ]
  [ "${fc_line}" -lt "${s4_line}" ]
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Loop.sh Failure Handling (AC: #4, #5)
# ──────────────────────────────────────────────

LOOP_SCRIPT=".bmad-orchestrator/loop.sh"

@test "Failure 3.1-21: loop script handles exit code 0 (relaunch for retry)" {
  grep -q 'return 0' "${LOOP_SCRIPT}"
  grep -qi 'Stage completed.*Relaunching\|relaunch\|fresh context' "${LOOP_SCRIPT}"
}

@test "Failure 3.1-22: loop script handles exit code 1 (stop with FAILED)" {
  grep -q 'return 1' "${LOOP_SCRIPT}"
  grep -qi 'failed.*retries\|Pipeline failed\|FAILED' "${LOOP_SCRIPT}"
}

@test "Failure 3.1-23: loop script writes FAILED status report on exit code 1" {
  grep -qi 'write_status_report.*FAILED' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Slash Command Failure-Related Initialization (AC: #5)
# ──────────────────────────────────────────────

@test "Failure 3.1-24: slash command initializes maxRetries: 3" {
  grep -q 'maxRetries: 3' "${SLASH_CMD_FILE}"
}

@test "Failure 3.1-25: slash command initializes failures: []" {
  grep -q 'failures: \[\]' "${SLASH_CMD_FILE}"
}

@test "Failure 3.1-26: slash command initializes currentRetries: 0" {
  grep -q 'currentRetries: 0' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Template Failure Recovery Sections (AC: #6)
# ──────────────────────────────────────────────

@test "Failure 3.1-27: all 10 templates contain {{failure_context}} in Context Injection" {
  local template_dir=".bmad-orchestrator/templates"
  local count
  count=$(grep -rl '{{failure_context}}' "${template_dir}" | wc -l)
  [ "${count}" -ge 10 ]
}

@test "Failure 3.1-28: all 10 templates contain Failure Recovery section" {
  local template_dir=".bmad-orchestrator/templates"
  local count
  count=$(grep -rl 'Failure Recovery' "${template_dir}" | wc -l)
  [ "${count}" -ge 10 ]
}

@test "Failure 3.1-29: stage-prd template has failure_context and Failure Recovery" {
  grep -q '{{failure_context}}' ".bmad-orchestrator/templates/stage-prd.md"
  grep -q 'Failure Recovery' ".bmad-orchestrator/templates/stage-prd.md"
}

@test "Failure 3.1-30: stage-readiness template has failure_context and Failure Recovery" {
  grep -q '{{failure_context}}' ".bmad-orchestrator/templates/stage-readiness.md"
  grep -q 'Failure Recovery' ".bmad-orchestrator/templates/stage-readiness.md"
}

@test "Failure 3.1-31: stage-code-review template has failure_context and Failure Recovery" {
  grep -q '{{failure_context}}' ".bmad-orchestrator/templates/stage-code-review.md"
  grep -q 'Failure Recovery' ".bmad-orchestrator/templates/stage-code-review.md"
}

# ──────────────────────────────────────────────
# Story 3.1 Tests: Code Review Fixes — Format and Edge Cases
# ──────────────────────────────────────────────

@test "Failure 3.1-32: agent documents exact failure context header format" {
  grep -q 'Previous failures on this stage:' "${AGENT_FILE}"
}

@test "Failure 3.1-33: agent documents exact failure context footer format" {
  grep -q 'Address these specific issues in this retry\.' "${AGENT_FILE}"
}

@test "Failure 3.1-34: agent handles empty filter result when no failures match currentStage" {
  grep -qi 'no entries match.*empty string\|If no entries match' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Upstream Re-Routing Logic in Orchestrator Agent (AC: #1, #2, #3)
# ──────────────────────────────────────────────

@test "ReRoute 3.2-1: agent describes upstream re-routing as distinct from same-stage retry" {
  grep -qi 'Upstream Re-Routing' "${AGENT_FILE}"
  grep -qi 'instead of simple.*retry\|instead of.*same-stage retry' "${AGENT_FILE}"
}

@test "ReRoute 3.2-2: agent describes upstream stage identification from readiness failure" {
  grep -qi 'Identify upstream stage\|identify.*upstream.*stage' "${AGENT_FILE}"
  grep -qi 'readiness report.*findings\|parse.*readiness.*report\|readiness.*report.*specific.*findings' "${AGENT_FILE}"
}

@test "ReRoute 3.2-3: agent maps PRD findings to prd stage" {
  grep -qi 'PRD findings.*prd\|PRD.*route.*prd' "${AGENT_FILE}"
}

@test "ReRoute 3.2-4: agent maps Architecture findings to architecture stage" {
  grep -qi 'Architecture findings.*architecture\|Architecture.*route.*architecture' "${AGENT_FILE}"
}

@test "ReRoute 3.2-5: agent maps Epics/Stories findings to epics-stories stage" {
  grep -qi 'Epics.*findings.*epics-stories\|Epics.*route.*epics-stories' "${AGENT_FILE}"
}

@test "ReRoute 3.2-6: agent prioritizes earliest upstream stage when findings span multiple stages" {
  grep -qi 'earliest.*stage.*pipeline\|prioritize.*earliest' "${AGENT_FILE}"
}

@test "ReRoute 3.2-7: agent describes re-routing to upstream stage (currentStage set back)" {
  grep -qi 'currentStage.*upstream stage\|Set.*currentStage.*to.*identified upstream\|currentStage.*to the identified upstream' "${AGENT_FILE}"
}

@test "ReRoute 3.2-8: agent describes remediation context construction from failure report" {
  grep -qi 'targeted remediation.*failure_context\|remediation.*{{failure_context}}\|targeted remediation instructions' "${AGENT_FILE}"
}

@test "ReRoute 3.2-9: agent describes targeted instructions (not full re-run)" {
  grep -qi 'NOT a full re-run\|not.*full re-run\|NOT.*full.*re-run.*workflow' "${AGENT_FILE}"
}

@test "ReRoute 3.2-10: Section 6.5 appears between Section 6 and Section 7" {
  local s6_line s65_line s7_line
  s6_line=$(grep -n '## 6\. Failure' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s65_line=$(grep -n '### 6\.5 Upstream Re-Routing' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s7_line=$(grep -n '## 7\. State Update' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s6_line}" ] && [ -n "${s65_line}" ] && [ -n "${s7_line}" ]
  [ "${s6_line}" -lt "${s65_line}" ]
  [ "${s65_line}" -lt "${s7_line}" ]
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Re-Validation After Upstream Revision (AC: #4)
# ──────────────────────────────────────────────

@test "ReRoute 3.2-11: agent describes reRouteOrigin field usage in state" {
  grep -qi 'reRouteOrigin' "${AGENT_FILE}"
  grep -qi 'reRouteOrigin.*validation.*stage\|reRouteOrigin.*readiness' "${AGENT_FILE}"
}

@test "ReRoute 3.2-12: agent describes routing back to validation stage after upstream fix" {
  grep -qi 'reRouteOrigin.*set.*currentStage.*back\|set.*currentStage.*back.*reRouteOrigin\|currentStage.*back to.*value.*reRouteOrigin' "${AGENT_FILE}"
}

@test "ReRoute 3.2-13: agent describes clearing reRouteOrigin on re-validation success" {
  grep -qi 'clear.*reRouteOrigin\|Clear.*reRouteOrigin\|reRouteOrigin.*clear\|remove.*reRouteOrigin' "${AGENT_FILE}"
}

@test "ReRoute 3.2-14: Section 7.1 checks reRouteOrigin before advancing stage" {
  local s71_line rro_line
  s71_line=$(grep -n '### 7\.1 Construct Updated State' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  rro_line=$(grep -n 'reRouteOrigin' "${AGENT_FILE}" | grep -v '6\.5\|6_5' | tail -1 | cut -d: -f1)
  [ -n "${s71_line}" ] && [ -n "${rro_line}" ]
  [ "${rro_line}" -gt "${s71_line}" ]
}

@test "ReRoute 3.2-15: agent describes re-validation advancing normally after reRouteOrigin cleared" {
  grep -qi 'advance.*currentStage.*next.*stage.*pipeline.*after.*validation\|advance.*normal.*pipeline' "${AGENT_FILE}"
}

@test "ReRoute 3.2-16: agent handles recursive re-routing (re-validation also fails)" {
  grep -qi 'maxRetries.*prevent.*infinite\|prevent infinite re-routing\|infinite re-routing loop' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Failure Chain Tracking (AC: #5)
# ──────────────────────────────────────────────

@test "ReRoute 3.2-17: agent describes re-route entry format with reRoutedTo field" {
  grep -q 'reRoutedTo' "${AGENT_FILE}"
  grep -qi 'reRoutedTo.*upstream.*stage\|reRoutedTo.*<upstream' "${AGENT_FILE}"
}

@test "ReRoute 3.2-18: re-route entry includes stage, attempt, error, timestamp, and reRoutedTo" {
  grep -q 'stage:' "${AGENT_FILE}"
  grep -q 'attempt:' "${AGENT_FILE}"
  grep -q 'error:' "${AGENT_FILE}"
  grep -q 'timestamp:' "${AGENT_FILE}"
  grep -q 'reRoutedTo:' "${AGENT_FILE}"
}

@test "ReRoute 3.2-19: agent describes full chain: failure -> re-route -> upstream attempt -> re-validation" {
  grep -qi 'original failure.*re-route\|failure.*re-route decision.*upstream' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Re-Routing Interaction with Existing Failure Handling (AC: #1, #3, #4, #5)
# ──────────────────────────────────────────────

@test "ReRoute 3.2-20: re-routing respects maxRetries (counts as an attempt)" {
  grep -qi 're-routing counts against.*maxRetries\|Re-routing counts against\|counts against.*maxRetries' "${AGENT_FILE}"
}

@test "ReRoute 3.2-21: re-routing increments currentRetries" {
  grep -qi 'Increment.*currentRetries.*re-rout\|re-rout.*counts.*attempts\|re-route attempt.*counts' "${AGENT_FILE}"
}

@test "ReRoute 3.2-22: terminal failure triggers when maxRetries exhausted including re-route attempts" {
  grep -qi 'prevent infinite re-routing\|infinite re-routing loop\|maxRetries.*prevent' "${AGENT_FILE}"
}

@test "ReRoute 3.2-23: re-routing uses exit code 0 (loop relaunches)" {
  grep -qi 'Exit code 0.*loop relaunches\|exit code 0.*relaunches\|Exit code 0' "${AGENT_FILE}"
}

@test "ReRoute 3.2-24: re-routing is distinct from code-review failure re-routing" {
  grep -qi 'distinct from.*Code-Review Failure Re-Routing\|distinct from the Code-Review' "${AGENT_FILE}"
  grep -qi 'inter-stage\|inter.stage' "${AGENT_FILE}"
}

@test "ReRoute 3.2-25: agent reads readiness report from disk for re-routing analysis" {
  grep -qi 'implementation-readiness-report\.md.*disk\|Load.*implementation-readiness-report\|Read.*readiness report' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Stage-Readiness Template Re-Routing Support (AC: #1, #3)
# ──────────────────────────────────────────────

READINESS_TEMPLATE=".bmad-orchestrator/templates/stage-readiness.md"

@test "ReRoute 3.2-26: readiness template Failure Recovery mentions upstream re-routing" {
  grep -qi 'upstream re-routing\|re-routed.*upstream\|upstream.*stage.*revised' "${READINESS_TEMPLATE}"
}

@test "ReRoute 3.2-27: readiness template Quality Gate mentions FAIL triggers upstream re-routing" {
  grep -qi 'FAIL.*triggers.*upstream re-routing\|FAIL.*upstream re-routing\|FAIL triggers upstream' "${READINESS_TEMPLATE}"
}

@test "ReRoute 3.2-28: readiness template references Section 6.5 of orchestrator agent" {
  grep -qi 'Section 6\.5' "${READINESS_TEMPLATE}"
}

@test "ReRoute 3.2-29: readiness template mentions re-validation context for upstream re-routing" {
  grep -qi 're-validation after upstream re-routing\|upstream.*revised\|upstream artifact was revised' "${READINESS_TEMPLATE}"
}

@test "ReRoute 3.2-30: readiness template describes targeted remediation (not full re-run)" {
  grep -qi 'targeted remediation\|targeted.*instructions\|specific gaps' "${READINESS_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 3.2 Tests: Code Review Fixes (Issues 1, 2, 3, 5, 6)
# ──────────────────────────────────────────────

@test "ReRoute 3.2-31: Section 1.1 lists reRouteOrigin as a state field" {
  local s11_line s12_line
  s11_line=$(grep -n '### 1\.1 Read State File' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s12_line=$(grep -n '### 1\.2 Determine What To Do' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  local rro_line
  rro_line=$(awk "NR>=${s11_line} && NR<=${s12_line}" "${AGENT_FILE}" | grep -n 'reRouteOrigin' | head -1 | cut -d: -f1)
  [ -n "${rro_line}" ]
}

@test "ReRoute 3.2-32: Section 6.5 explicitly scopes to readiness stage only (not code-review)" {
  grep -qi 'This section applies only to the.*readiness.*validation stage\|applies only to.*readiness' "${AGENT_FILE}"
}

@test "ReRoute 3.2-33: Section 7.1 addresses completedStages duplicate avoidance during re-routing" {
  grep -qi 'skip if already present\|avoid duplicates\|already exists.*completedStages\|duplicate.*re-routing' "${AGENT_FILE}"
}

@test "ReRoute 3.2-34: Section 7.1 preserves currentRetries during re-routing (no reset on upstream completion)" {
  grep -qi 'do NOT reset.*currentRetries\|NOT reset currentRetries\|must continue counting.*maxRetries' "${AGENT_FILE}"
}

@test "ReRoute 3.2-35: readiness template does NOT reference reRouteOrigin field directly" {
  ! grep -q 'reRouteOrigin' "${READINESS_TEMPLATE}"
}

# ──────────────────────────────────────────────
# Story 3.3 Tests: Terminal Failure in Orchestrator Agent (AC: #1, #2)
# ──────────────────────────────────────────────

@test "Terminal 3.3-1: agent describes maxRetries check triggering terminal failure" {
  grep -qi 'currentRetries.*>=.*maxRetries' "${AGENT_FILE}"
  grep -qi 'status.*failed' "${AGENT_FILE}"
}

@test "Terminal 3.3-2: agent describes status: failed on retry exhaustion in Section 5.5" {
  grep -qi 'currentRetries.*>=.*maxRetries.*status.*failed\|maxRetries.*set.*status.*failed\|maxRetries.*status: failed' "${AGENT_FILE}"
}

@test "Terminal 3.3-3: agent describes exit code 1 for terminal failure in Section 5.5" {
  grep -qi 'currentRetries.*>=.*maxRetries.*exit code 1\|maxRetries.*exit code 1' "${AGENT_FILE}"
}

@test "Terminal 3.3-4: agent describes exit code 1 for terminal failure in Section 6" {
  local s6_line s7_line
  s6_line=$(grep -n '## 6\. Failure' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s7_line=$(grep -n '## 7\. State Update' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  awk "NR>=${s6_line} && NR<=${s7_line}" "${AGENT_FILE}" | grep -qi 'exit code 1.*stop\|Exit code 1'
}

@test "Terminal 3.3-5: agent describes status: failed in Section 6 step 4" {
  local s6_line s7_line
  s6_line=$(grep -n '## 6\. Failure' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s7_line=$(grep -n '## 7\. State Update' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  awk "NR>=${s6_line} && NR<=${s7_line}" "${AGENT_FILE}" | grep -qi 'status.*failed'
}

@test "Terminal 3.3-6: agent describes state preservation on failure — all fields preserved" {
  # Section 6 keeps currentStage unchanged AND Section 7.1 preserves all other fields
  grep -qi 'Keep.*currentStage.*unchanged\|currentStage.*unchanged' "${AGENT_FILE}"
  grep -qi 'All other fields preserved as-is' "${AGENT_FILE}"
}

@test "Terminal 3.3-7: agent describes failures array appended on verification fail" {
  grep -qi 'Log failure.*failures array\|Append to.*failures.*array\|failures array.*stage.*attempt.*error' "${AGENT_FILE}"
}

@test "Terminal 3.3-8: agent describes currentRetries increment on failure" {
  grep -qi 'Increment.*currentRetries' "${AGENT_FILE}"
}

@test "Terminal 3.3-9: agent handles failed status on cold start (Section 1.2 exits code 1)" {
  grep -qi 'status.*is.*failed.*Exit.*code 1\|status.*failed.*Pipeline previously failed.*Exit.*code 1\|failed.*exit.*code 1' "${AGENT_FILE}"
}

@test "Terminal 3.3-10: agent preserves all state fields via Section 7.1 (all other fields preserved)" {
  grep -qi 'All other fields preserved as-is\|all other fields preserved' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.3 Tests: Artifact Overwrite Protection in Slash Command (AC: #3)
# ──────────────────────────────────────────────

@test "Terminal 3.3-11: slash command describes Step 3 artifact overwrite protection" {
  grep -qi 'Artifact Overwrite Protection' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-12: slash command checks for state.yaml existence (primary check)" {
  grep -qi 'state\.yaml.*exists\|state\.yaml.*definitive signal' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-13: slash command checks for status-report.md existence (secondary check)" {
  grep -qi 'status-report\.md.*exists\|Secondary check.*status report' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-14: slash command describes error message for existing artifacts on fresh run" {
  grep -qi 'Existing artifacts detected\|Error.*Existing artifacts detected' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-15: slash command uses OR logic for primary and secondary checks" {
  grep -qi 'state\.yaml.*OR.*status-report\.md\|either.*state\.yaml.*OR.*status-report' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-16: slash command describes safety net check for _bmad-output/ artifacts" {
  grep -qi 'Safety net check\|safety net' "${SLASH_CMD_FILE}"
  grep -qi 'prd\.md.*exists\|_bmad-output.*planning-artifacts.*prd\.md' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-17: slash command safety net is a hard block on fresh run" {
  # Safety net check for prd.md uses STOP (hard block), not a warning
  grep -qi 'prd\.md.*exists.*STOP\|If it exists.*STOP' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-18: slash command describes --resume as recovery path" {
  grep -qi '\-\-resume.*continue.*previous run\|Use.*--resume.*continue' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-19: slash command enhanced Step 3 checks multiple signals" {
  grep -qi 'Multiple signals.*checked\|multiple signals' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.3 Tests: Resume Artifact Respect (AC: #4)
# ──────────────────────────────────────────────

@test "Terminal 3.3-20: orchestrator describes resume behavior respecting existing artifacts" {
  grep -qi 'Artifact Respect on Resume\|artifact.*respect.*resume' "${AGENT_FILE}"
  grep -qi 'does not regenerate completed stages' "${AGENT_FILE}"
}

@test "Terminal 3.3-21: orchestrator describes completedStages trust on resume" {
  grep -qi 'completedStages.*tracks what.*done\|trusts these' "${AGENT_FILE}"
}

@test "Terminal 3.3-22: slash command preserves state fields on resume (only modifies runType, updatedAt, status)" {
  grep -qi 'Update ONLY these fields' "${SLASH_CMD_FILE}"
  grep -q 'runType: resume' "${SLASH_CMD_FILE}"
  grep -q 'status: running' "${SLASH_CMD_FILE}"
}

@test "Terminal 3.3-23: orchestrator picks up exactly where previous run stopped on resume" {
  grep -qi 'picks up exactly where the previous run stopped' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 3.3 Tests: Partial Artifact Handling (AC: #5)
# ──────────────────────────────────────────────

@test "Terminal 3.3-24: orchestrator describes partial artifact handling on resume" {
  grep -qi 'Partial Artifact Handling on Resume\|partial artifact' "${AGENT_FILE}"
}

@test "Terminal 3.3-25: orchestrator describes that failed stages are re-run (currentStage unchanged)" {
  grep -qi 'currentStage still points to the failed stage\|re-runs it from the beginning\|re-run.*from the beginning' "${AGENT_FILE}"
}

@test "Terminal 3.3-26: orchestrator describes that completedStages never includes a stage that didn't pass verification" {
  grep -qi 'never marks a stage as completed unless verification has passed\|never marks a stage as completed unless verification' "${AGENT_FILE}"
}

@test "Terminal 3.3-27: orchestrator describes implicit partial artifact handling through re-execution" {
  grep -qi 'handled implicitly\|implicit.*through.*normal.*resume\|implicitly through the normal resume' "${AGENT_FILE}"
}

@test "Terminal 3.3-28: orchestrator describes sub-agents overwriting partial artifacts on retry" {
  grep -qi 'overwriting any partial artifacts\|sub-agent workflow re-executes fully\|overwrite.*partial' "${AGENT_FILE}"
}

@test "Terminal 3.3-29: orchestrator states no special partial artifact detection logic needed" {
  grep -qi 'No special partial artifact detection logic\|no special partial artifact' "${AGENT_FILE}"
}

@test "Terminal 3.3-30: partial artifact documentation is in Section 1.4 (Resume Behavior)" {
  local s14_line pa_line s2_line
  s14_line=$(grep -n '### 1\.4 Resume Behavior' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  pa_line=$(grep -n 'Partial Artifact Handling on Resume' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  s2_line=$(grep -n '## 2\. Pipeline Stage' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s14_line}" ] && [ -n "${pa_line}" ] && [ -n "${s2_line}" ]
  [ "${s14_line}" -lt "${pa_line}" ]
  [ "${pa_line}" -lt "${s2_line}" ]
}

# ──────────────────────────────────────────────
# Story 3.3 Tests: Loop.sh Terminal Failure Handling (AC: #1, #2)
# ──────────────────────────────────────────────

@test "Terminal 3.3-31: loop script handles exit code 1 (stop with FAILED status report)" {
  grep -q 'return 1' "${LOOP_SCRIPT}"
  grep -qi 'FAILED' "${LOOP_SCRIPT}"
  grep -qi 'write_status_report.*FAILED' "${LOOP_SCRIPT}"
}

@test "Terminal 3.3-32: loop script captures failure details in status report" {
  grep -qi 'Pipeline failed at current stage\|Pipeline failed' "${LOOP_SCRIPT}"
}

@test "Terminal 3.3-33: loop script does NOT relaunch after exit code 1" {
  # Exit code 1 case in handle_exit_code specifically returns 1
  local hec_line main_line
  hec_line=$(grep -n 'handle_exit_code()' "${LOOP_SCRIPT}" | head -1 | cut -d: -f1)
  main_line=$(grep -n 'main()' "${LOOP_SCRIPT}" | head -1 | cut -d: -f1)
  awk "NR>=${hec_line} && NR<=${main_line}" "${LOOP_SCRIPT}" | grep -q 'return 1'
  # handler_result -ne 0 stops the loop
  grep -qi 'handler_result.*-ne 0' "${LOOP_SCRIPT}"
}

@test "Terminal 3.3-34: loop script preflight check refuses to run on failed status" {
  grep -qi 'status.*failed.*ERROR\|Pipeline previously failed\|failed.*Use --resume' "${LOOP_SCRIPT}"
}

@test "Terminal 3.3-35: loop script exit code dispatch matches orchestrator exit code protocol" {
  # Verify all 4 exit codes are handled
  grep -q '0)' "${LOOP_SCRIPT}"
  grep -q '1)' "${LOOP_SCRIPT}"
  grep -q '2)' "${LOOP_SCRIPT}"
  grep -q '3)' "${LOOP_SCRIPT}"
  grep -q '\*)' "${LOOP_SCRIPT}"
}

# ══════════════════════════════════════════════════════════
# Story 4.1 Tests: Checkpoint Gate Pausing & Approval
# ══════════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# 4.1 Task 1: Checkpoint gate logic in orchestrator agent (AC: #1, #5)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-1: agent describes mode: checkpoint gate checking" {
  grep -qi 'mode.*checkpoint' "${AGENT_FILE}"
  grep -qi 'checkpoint.*gate\|gate.*checkpoint' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-2: agent describes gates array for checkpoint stages" {
  grep -q 'gates' "${AGENT_FILE}"
  grep -qi 'gates.*array\|array.*gates' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-3: agent describes status: paused on checkpoint gate" {
  grep -q 'status.*paused\|paused.*status' "${AGENT_FILE}"
  grep -qi 'checkpoint.*paused\|paused.*checkpoint' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-4: agent describes exit code 3 for checkpoint pause" {
  grep -q 'exit.*code 3\|code.*3.*checkpoint\|3.*checkpoint.*pause' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-5: agent checkpoint gate checks the completed stage not currentStage" {
  grep -qi 'completed stage.*gates\|completed.*stage.*identifier.*gates' "${AGENT_FILE}"
  grep -qi 'NOT.*currentStage\|not.*currentStage' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-6: agent describes autonomous mode ignoring gates" {
  grep -qi 'autonomous' "${AGENT_FILE}"
  grep -qi 'gates.*ignored\|ignored.*gates\|gates are ignored' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-7: checkpoint gate logic is in Section 8" {
  # Verify checkpoint gate logic appears after Section 8 heading
  local s8_line gate_line
  s8_line=$(grep -n '## 8\.' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  gate_line=$(grep -n 'Checkpoint Gate Logic' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ -n "${s8_line}" ]
  [ -n "${gate_line}" ]
  [ "${gate_line}" -ge "${s8_line}" ]
}

# ──────────────────────────────────────────────
# 4.1 Task 2: Checkpoint summary presentation (AC: #2)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-8: agent describes checkpoint summary generation" {
  grep -qi 'checkpoint.*summary\|summary.*checkpoint' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-9: checkpoint summary includes stage name" {
  grep -qi 'stage.*name\|Stage Name' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-10: checkpoint summary includes artifacts produced" {
  grep -qi 'producedArtifacts\|artifact.*produced\|Artifacts produced' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-11: checkpoint summary includes key decisions or outputs" {
  grep -qi 'key.*decision\|key.*output\|Key decisions' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-12: checkpoint summary includes resume instructions" {
  grep -q '\-\-resume' "${AGENT_FILE}"
  grep -qi 'resume.*instruction\|To continue\|resume.*to continue' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-13: checkpoint summary is output to conversation before exit" {
  grep -qi 'output.*summary.*conversation\|Output summary to conversation\|Display.*checkpoint.*summary' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-14: checkpoint summary appended to status-report.md" {
  grep -qi 'status-report.*PAUSED.*CHECKPOINT\|PAUSED (CHECKPOINT)\|PAUSED.*CHECKPOINT' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-15: Section 8.1 exists for checkpoint summary generation" {
  grep -q '### 8\.1' "${AGENT_FILE}"
  grep -qi '8\.1.*Checkpoint Summary\|8\.1.*checkpoint.*summary' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-16: checkpoint summary generation happens before status: paused" {
  # Section 8.1 must describe generating summary BEFORE setting paused and exiting
  # Find the first summary step (Read produced artifacts) and the paused+exit step
  local summary_line paused_line
  summary_line=$(grep -n 'Read produced artifacts\|Extract key decisions' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  paused_line=$(grep -n 'status.*paused.*exit.*code 3\|status.*paused.*exit with code 3\|set.*status.*paused.*and exit' "${AGENT_FILE}" | tail -1 | cut -d: -f1)
  [ -n "${summary_line}" ]
  [ -n "${paused_line}" ]
  [ "${summary_line}" -lt "${paused_line}" ]
}

# ──────────────────────────────────────────────
# 4.1 Task 2: Checkpoint summary reads produced artifacts (AC: #2)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-17: checkpoint summary reads producedArtifacts from template frontmatter" {
  grep -qi 'producedArtifacts.*template\|template.*frontmatter.*producedArtifacts\|producedArtifacts.*list.*template' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-18: checkpoint summary extracts brief summary from artifacts" {
  grep -qi 'brief.*summary\|2-3.*bullet\|bullet.*point' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# 4.1 Task 3: Loop.sh checkpoint messaging (AC: #3)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-19: loop script handles exit code 3 (stop with PAUSED status report)" {
  grep -q 'return 3' "${LOOP_SCRIPT}"
  grep -qi 'write_status_report.*PAUSED' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-20: loop script displays checkpoint stage name in message" {
  grep -qi 'Checkpoint reached after' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-21: loop script reads completed stage from state for checkpoint message" {
  grep -qi 'read_last_completed_stage\|completedStage\|checkpoint_stage' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-22: loop script includes resume instructions in checkpoint message" {
  grep -qi '\-\-resume.*to continue\|resume.*to continue' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-23: loop script does NOT relaunch after exit code 3" {
  # Exit code 3 returns 3, and handler_result -ne 0 stops loop
  local hec_line main_line
  hec_line=$(grep -n 'handle_exit_code()' "${LOOP_SCRIPT}" | head -1 | cut -d: -f1)
  main_line=$(grep -n 'main()' "${LOOP_SCRIPT}" | head -1 | cut -d: -f1)
  awk "NR>=${hec_line} && NR<=${main_line}" "${LOOP_SCRIPT}" | grep -q 'return 3'
}

@test "Checkpoint 4.1-24: loop script has read_last_completed_stage function" {
  grep -q 'read_last_completed_stage()' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-25: read_last_completed_stage parses block-style completedStages correctly" {
  # Behavioral test: create a state file with block-style completedStages followed by gates array
  # The function must return the last completed stage, NOT entries from gates
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages:
  - prd
  - architecture
gates:
  - prd
  - architecture
  - epics-stories
  - readiness
  - code-review
YAML
  # Source loop script with TEST_BMAD_DIR to control STATE_FILE path
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_last_completed_stage)"
  rm -rf "${tmp_dir}"
  [ "${result}" = "architecture" ]
}

@test "Checkpoint 4.1-26: loop script checkpoint message includes stage name from state" {
  # The exit code 3 handler should use read_last_completed_stage
  grep -qi 'read_last_completed_stage' "${LOOP_SCRIPT}"
  grep -qi 'checkpoint_stage' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-43: read_last_completed_stage handles flow-style completedStages" {
  # Behavioral test: flow-style [prd, architecture] should return architecture
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages: [prd, architecture]
gates:
  - prd
  - architecture
  - epics-stories
  - readiness
  - code-review
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_last_completed_stage)"
  rm -rf "${tmp_dir}"
  [ "${result}" = "architecture" ]
}

@test "Checkpoint 4.1-44: read_last_completed_stage returns empty for empty completedStages" {
  # Behavioral test: empty array should return empty string
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages: []
gates:
  - prd
  - architecture
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_last_completed_stage)"
  rm -rf "${tmp_dir}"
  [ -z "${result}" ]
}

# ──────────────────────────────────────────────
# 4.1 Task 4: Resume from checkpoint pause (AC: #4)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-27: slash command Step 2 handles status: paused (sets to running)" {
  grep -q 'status: running' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-28: slash command preserves state fields on resume from pause" {
  # Step 2 says update ONLY specific fields, preserving everything else
  grep -qi 'Update ONLY\|preserve\|preserving' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-29: orchestrator handles status: paused on cold start" {
  grep -qi 'status.*paused\|paused.*checkpoint\|paused.*gate' "${AGENT_FILE}"
  # Section 1.2 point 3 handles paused status
  grep -qi 'paused.*update.*running\|paused.*resumed' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-30: orchestrator updates status from paused to running" {
  grep -qi 'status.*running\|update.*status.*running' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-31: orchestrator proceeds to currentStage after resume from pause" {
  # Section 1.2 point 3: proceed to Stage Execution for currentStage
  grep -qi 'proceed.*Stage Execution\|proceed.*currentStage' "${AGENT_FILE}"
}

@test "Checkpoint 4.1-32: currentStage is already advanced before checkpoint pause" {
  # Section 7.1 advances currentStage, then Section 8 checks gates on completed stage
  # On resume, currentStage is already the next stage
  grep -qi 'currentStage.*advanced\|advance.*currentStage\|currentStage.*next' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# 4.1 Task 5.5: Default gates array in slash command (AC: #1)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-33: slash command Step 4 creates state with gates array" {
  grep -q 'gates:' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-34: gates array contains prd" {
  grep -q 'prd' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-35: gates array contains architecture" {
  grep -q 'architecture' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-36: gates array contains epics-stories" {
  grep -q 'epics-stories' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-37: gates array contains readiness" {
  grep -q 'readiness' "${SLASH_CMD_FILE}"
}

@test "Checkpoint 4.1-38: gates array contains code-review" {
  grep -q 'code-review' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# 4.1 Integration: Checkpoint flow end-to-end validation (AC: #1, #2, #3, #4, #5)
# ──────────────────────────────────────────────

@test "Checkpoint 4.1-39: exit code 3 in agent matches exit code 3 in loop script" {
  grep -q 'exit.*3\|code 3\|code.*3' "${AGENT_FILE}"
  grep -q '3)' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-40: agent and loop both reference checkpoint pause" {
  grep -qi 'checkpoint.*pause\|pause.*checkpoint' "${AGENT_FILE}"
  grep -qi 'checkpoint\|Checkpoint' "${LOOP_SCRIPT}"
}

@test "Checkpoint 4.1-41: gates array in slash command matches gates referenced in agent" {
  # Both files reference the same gate stages
  for gate in prd architecture epics-stories readiness code-review; do
    grep -q "${gate}" "${SLASH_CMD_FILE}"
    grep -q "${gate}" "${AGENT_FILE}"
  done
}

@test "Checkpoint 4.1-42: status: paused is consistently handled across agent and slash command" {
  grep -q 'paused' "${AGENT_FILE}"
  grep -q 'paused\|status: running' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# Story 4.2: Checkpoint Feedback & Revision
# ──────────────────────────────────────────────

# ── Task 4.1: Orchestrator agent feedback handling tests ──

@test "Feedback 4.2-1: agent describes checkpointFeedback field in state file" {
  grep -q 'checkpointFeedback' "${AGENT_FILE}"
}

@test "Feedback 4.2-2: agent describes checkpointFeedback as optional field" {
  grep -qi 'optional\|absent.*null\|null.*absent' "${AGENT_FILE}"
  grep -q 'checkpointFeedback' "${AGENT_FILE}"
}

@test "Feedback 4.2-3: agent describes feedback-aware resume from status: paused (revision flow)" {
  grep -qi 'REVISION flow\|revision flow' "${AGENT_FILE}"
}

@test "Feedback 4.2-4: agent describes rewinding currentStage on feedback" {
  grep -qi 'rewind\|Set.*currentStage.*back\|currentStage.*back' "${AGENT_FILE}"
}

@test "Feedback 4.2-5: agent describes removing completed stage from completedStages on feedback" {
  grep -qi 'Remove.*completedStages\|remove.*from.*completedStages' "${AGENT_FILE}"
}

@test "Feedback 4.2-6: agent describes injecting feedback into failure_context" {
  grep -q 'failure_context.*feedback\|feedback.*failure_context\|Checkpoint feedback from user' "${AGENT_FILE}"
}

@test "Feedback 4.2-7: agent describes clearing checkpointFeedback after consuming it" {
  grep -qi 'Clear.*checkpointFeedback\|clear.*checkpointFeedback\|remove.*checkpointFeedback' "${AGENT_FILE}"
}

@test "Feedback 4.2-8: agent describes approval flow (no feedback, advance normally)" {
  grep -qi 'APPROVAL flow\|approval flow\|approval.*resume' "${AGENT_FILE}"
}

@test "Feedback 4.2-9: agent describes re-pause at same gate after revision (via existing gate logic)" {
  # AC #3: After revision completes, existing Section 8 gate logic re-pauses automatically
  # The revision flow rewinds currentStage; after re-execution, Section 7.1 advances and
  # Section 8 checks the completed stage against gates array — triggering re-pause.
  # Verify the agent describes the rewind-to-stage-execution flow that leads back to Section 8.
  grep -qi 'Proceed to Stage Execution.*rewound' "${AGENT_FILE}"
}

@test "Feedback 4.2-10: agent describes checkpoint-revision type in failures array" {
  grep -q 'checkpoint-revision' "${AGENT_FILE}"
}

@test "Feedback 4.2-11: agent describes attempt: 0 for checkpoint revisions" {
  grep -q 'attempt: 0\|attempt.*0' "${AGENT_FILE}"
}

@test "Feedback 4.2-12: agent describes truncated feedback in error field (max 200 chars)" {
  grep -qi 'truncat\|max 200' "${AGENT_FILE}"
}

@test "Feedback 4.2-13: agent checkpoint revision record includes stage field" {
  # Verify the failures array entry in the checkpoint revision record references the completed stage
  grep -q 'stage:.*"<completed-stage>"' "${AGENT_FILE}"
}

@test "Feedback 4.2-14: agent checkpoint revision record includes timestamp" {
  grep -q 'timestamp.*ISO-8601\|ISO-8601.*timestamp' "${AGENT_FILE}"
}

@test "Feedback 4.2-15: agent checkpoint revision record includes type field" {
  grep -q 'type:.*checkpoint-revision\|type.*checkpoint-revision' "${AGENT_FILE}"
}

@test "Feedback 4.2-16: agent identifies completed stage from last entry in completedStages" {
  grep -qi 'last.*entry.*completedStages\|last.*completedStages' "${AGENT_FILE}"
}

@test "Feedback 4.2-17: agent performs atomic state update after consuming feedback" {
  # Verify atomic write (Section 7.2) is referenced in the feedback flow
  grep -qi 'atomic.*state.*update\|Section 7\.2' "${AGENT_FILE}"
}

@test "Feedback 4.2-18: agent constructs failure_context with user feedback text" {
  grep -q 'Checkpoint feedback from user' "${AGENT_FILE}"
}

@test "Feedback 4.2-19: agent prevents re-processing by clearing feedback from state" {
  grep -qi 'prevent.*re-processing\|prevent.*reprocess' "${AGENT_FILE}"
}

# ── Task 4.2: Slash command feedback handling tests ──

@test "Feedback 4.2-20: slash command describes --feedback flag" {
  grep -q '\-\-feedback' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-21: slash command describes --feedback with quoted text" {
  grep -q '\-\-feedback.*text\|feedback.*text' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-22: slash command describes checkpointFeedback field in state on resume" {
  grep -q 'checkpointFeedback' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-23: slash command describes --feedback requires --resume (error if used alone)" {
  grep -qi '\-\-feedback.*can only be used with.*\-\-resume\|feedback.*only.*resume' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-24: slash command describes approval resume (no feedback, no checkpointFeedback)" {
  grep -qi 'NOT present\|absent.*null\|no.*feedback\|not.*present' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-25: slash command outputs distinct message when feedback is provided on resume" {
  grep -q 'Resumed pipeline with feedback' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-26: slash command --feedback flag includes quoted text parameter" {
  # Verify --feedback is documented with its "text" parameter format (distinct from 4.2-20 which just checks flag existence)
  grep -q '\-\-feedback.*"text"' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-27: slash command writes checkpointFeedback to state when --feedback present" {
  grep -q 'checkpointFeedback.*feedback text\|checkpointFeedback:' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-28: slash command ensures checkpointFeedback absent when no --feedback" {
  grep -qi 'absent.*null\|NOT present.*checkpointFeedback\|not write the field' "${SLASH_CMD_FILE}"
}

# ── Cross-file consistency tests ──

@test "Feedback 4.2-29: checkpointFeedback field referenced in both agent and slash command" {
  grep -q 'checkpointFeedback' "${AGENT_FILE}"
  grep -q 'checkpointFeedback' "${SLASH_CMD_FILE}"
}

@test "Feedback 4.2-30: checkpoint-revision type uses attempt 0 to distinguish from real failures" {
  # Verify the agent documents both type AND attempt:0 together in the checkpoint revision record
  # (distinct from 4.2-10 which only checks checkpoint-revision string exists)
  grep -q 'attempt: 0' "${AGENT_FILE}"
  grep -q 'type:.*checkpoint-revision' "${AGENT_FILE}"
}

@test "Feedback 4.2-31: agent and slash command both handle status: paused with feedback awareness" {
  grep -q 'paused' "${AGENT_FILE}"
  grep -q 'checkpointFeedback' "${AGENT_FILE}"
  grep -q 'checkpointFeedback' "${SLASH_CMD_FILE}"
}

# ──────────────────────────────────────────────
# Story 4.3: Party Mode Integration
# Tests for Party Mode trigger detection, invocation, result handling
# ──────────────────────────────────────────────

# ── Trigger Detection (AC: #1, #2, #3, #4) ──

@test "PartyMode 4.3-1: agent describes Trigger A — competing approaches detection" {
  grep -qi 'Trigger A.*Competing Approaches' "${AGENT_FILE}"
  grep -qi 'alternatives\|trade-offs\|should we use X or Y' "${AGENT_FILE}"
}

@test "PartyMode 4.3-2: agent describes Trigger B — multi-domain scope detection" {
  grep -qi 'Trigger B.*Multi-Domain Scope' "${AGENT_FILE}"
  grep -qi 'multiple architectural domains' "${AGENT_FILE}"
}

@test "PartyMode 4.3-3: agent describes Trigger C — ambiguous terms detection" {
  grep -qi 'Trigger C.*Ambiguous Terms' "${AGENT_FILE}"
  grep -qi 'undefined.*vague\|vague.*domain-specific' "${AGENT_FILE}"
}

@test "PartyMode 4.3-4: agent describes Trigger D — unspecified elements in autonomous mode" {
  grep -qi 'Trigger D.*Unspecified Elements.*Autonomous' "${AGENT_FILE}"
  grep -qi 'mode.*autonomous.*human input/verification' "${AGENT_FILE}"
}

@test "PartyMode 4.3-5: agent describes Trigger D exception — not applicable in checkpoint mode" {
  grep -qi 'Trigger D.*does NOT apply in checkpoint mode\|Trigger D specifically does NOT apply in checkpoint' "${AGENT_FILE}"
}

# ── Invocation Mechanism (AC: #5) ──

@test "PartyMode 4.3-6: agent describes instructing sub-agent to invoke Party Mode (NOT invoking directly)" {
  grep -qi 'orchestrator does NOT directly invoke Party Mode.*instructs the sub-agent' "${AGENT_FILE}"
}

@test "PartyMode 4.3-7: agent describes specific question/decision point in invocation" {
  grep -qi 'invoke Party Mode to brainstorm:.*specific question or decision point' "${AGENT_FILE}"
}

@test "PartyMode 4.3-8: agent describes once-per-interaction limit on Party Mode" {
  grep -qi 'at most ONCE per sub-agent interaction' "${AGENT_FILE}"
}

@test "PartyMode 4.3-9: agent describes bundling multiple triggers into single invocation" {
  grep -qi 'bundle.*single Party Mode invocation.*multiple questions' "${AGENT_FILE}"
}

# ── Result Handling (AC: #6) ──

@test "PartyMode 4.3-10: agent describes evaluating brainstorming consensus" {
  grep -qi 'evaluates whether the brainstorming produced a clear consensus' "${AGENT_FILE}"
}

@test "PartyMode 4.3-11: agent describes continuing workflow after clear consensus" {
  grep -qi 'consensus is clear.*continues the normal workflow' "${AGENT_FILE}"
}

@test "PartyMode 4.3-12: agent describes making judgment call when consensus is unclear" {
  grep -qi 'consensus is unclear.*judgment call' "${AGENT_FILE}"
}

@test "PartyMode 4.3-13: agent describes no re-invocation on same decision" {
  grep -qi 'does NOT re-invoke Party Mode on the same decision' "${AGENT_FILE}"
}

# ── Judgment Guidelines ──

@test "PartyMode 4.3-14: agent describes LLM judgment for trigger significance" {
  grep -qi 'LLM judgment to assess.*significant\|LLM judgment to assess significance' "${AGENT_FILE}"
}

@test "PartyMode 4.3-15: agent describes Party Mode as non-automatic (judgment-based)" {
  grep -qi 'Triggers are NOT automatic' "${AGENT_FILE}"
}

@test "PartyMode 4.3-16: agent describes meaningful impact threshold for invocation" {
  grep -qi 'meaningful architectural.*design.*implementation impact' "${AGENT_FILE}"
}

@test "PartyMode 4.3-17: agent describes judgment-based not rule-based trigger detection" {
  grep -qi 'judgment-based.*not rule-based' "${AGENT_FILE}"
}

# ── Section Structure and Cross-References ──

@test "PartyMode 4.3-18: agent has Section 4.4 for Party Mode Trigger Detection" {
  grep -q '### 4\.4 Party Mode Trigger Detection' "${AGENT_FILE}"
}

@test "PartyMode 4.3-19: Section 4.2 cross-references Section 4.4 for detailed trigger criteria" {
  grep -qi 'Section 4\.4.*trigger criteria\|Section 4\.4.*invocation protocol' "${AGENT_FILE}"
}

@test "PartyMode 4.3-20: agent describes invocation via resume message to sub-agent" {
  grep -qi 'resume message to the sub-agent.*Party Mode instruction' "${AGENT_FILE}"
  grep -qi 'next resume message.*includes a Party Mode instruction\|resume message to the sub-agent includes' "${AGENT_FILE}"
}

@test "PartyMode 4.3-21: agent describes architecture boundary compliance for Party Mode" {
  grep -qi 'architecture boundary.*orchestrator drives sub-agents.*sub-agents execute workflows' "${AGENT_FILE}"
}

@test "PartyMode 4.3-22: agent describes Trigger A with pros/cons comparisons" {
  grep -qi 'pros/cons comparisons' "${AGENT_FILE}"
}

@test "PartyMode 4.3-23: agent describes Trigger B with cross-domain conflict risk" {
  grep -qi 'cross-domain conflicts' "${AGENT_FILE}"
}

@test "PartyMode 4.3-24: agent describes Trigger C with real-time and scalable examples" {
  grep -qi '"real-time".*latency\|"scalable".*scale targets' "${AGENT_FILE}"
}

@test "PartyMode 4.3-25: agent describes Trigger D substitutes brainstorming for human input" {
  grep -qi 'Party Mode brainstorming substitutes for.*human input' "${AGENT_FILE}"
}

@test "PartyMode 4.3-26: agent describes checkpoint mode — prefer pausing at gate for human" {
  grep -qi 'prefer pausing at the gate.*human decide' "${AGENT_FILE}"
}

@test "PartyMode 4.3-27: agent describes Triggers A-C still apply in checkpoint mode between gates" {
  grep -qi 'Triggers A.*C still apply in checkpoint mode' "${AGENT_FILE}"
}

@test "PartyMode 4.3-28: agent describes preventing brainstorming loops via once-per-interaction limit" {
  grep -qi 'ONCE per sub-agent interaction.*prevent brainstorming loops' "${AGENT_FILE}"
}

@test "PartyMode 4.3-29: agent describes invocation includes relevant BMAD agents" {
  grep -qi 'relevant BMAD agents.*architect.*analyst.*PM' "${AGENT_FILE}"
}

@test "PartyMode 4.3-30: agent describes incorporate consensus into response and continue" {
  grep -qi 'incorporate the consensus into your response and continue' "${AGENT_FILE}"
}

@test "PartyMode 4.3-31: agent describes non-trigger example (tabs vs spaces) for judgment threshold" {
  grep -qi 'tabs vs spaces.*do NOT warrant Party Mode' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Story 5.1 Tests: Stage-Level Status Logging (AC: #1-#5)
# ──────────────────────────────────────────────

# ── PASS Entry Format (AC #1) ──

@test "StatusLog 5.1-1: agent describes PASS entry format with stage name in status report" {
  grep -q '## Stage: <stage-name>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-2: agent describes PASS outcome in status report entry" {
  grep -q '\*\*Outcome:\*\* PASS | PASS (CONCERNS)' "${AGENT_FILE}"
}

@test "StatusLog 5.1-3: agent describes timestamp in PASS entry format" {
  grep -q '\*\*Timestamp:\*\* <ISO-8601>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-4: agent describes artifacts field in PASS entry format" {
  grep -q '\*\*Artifacts:\*\* <comma-separated list of producedArtifacts paths>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-5: agent describes details field in PASS entry format" {
  grep -q '\*\*Details:\*\* <one-line summary, include concern details if CONCERNS>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-6: agent describes producedArtifacts as source for artifacts field" {
  grep -qi "template's \`producedArtifacts\` frontmatter" "${AGENT_FILE}"
}

# ── FAIL Entry Format (AC #2) ──

@test "StatusLog 5.1-7: agent describes FAIL entry with outcome FAIL in status report" {
  grep -q '\*\*Outcome:\*\* FAIL$' "${AGENT_FILE}"
}

@test "StatusLog 5.1-8: agent describes attempt number in FAIL entry format" {
  grep -q '\*\*Attempt:\*\* <attempt-number> of <maxRetries>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-9: agent describes error field in FAIL entry format" {
  grep -q '\*\*Error:\*\* <single-line error summary' "${AGENT_FILE}"
}

@test "StatusLog 5.1-10: agent describes writing FAIL entry to status report in Section 6" {
  grep -qi 'Append a FAIL entry to.*status-report\.md' "${AGENT_FILE}"
}

# ── RE-ROUTED Entry Format (AC #2) ──

@test "StatusLog 5.1-11: agent describes FAIL (RE-ROUTED) outcome in status report" {
  grep -q '\*\*Outcome:\*\* FAIL (RE-ROUTED)' "${AGENT_FILE}"
}

@test "StatusLog 5.1-12: agent describes re-route target field in RE-ROUTED entry" {
  grep -q '\*\*Re-routed to:\*\* <upstream-stage>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-13: agent describes RE-ROUTED entry in Section 6.5" {
  grep -qi 'Append a FAIL (RE-ROUTED) entry to.*status-report\.md' "${AGENT_FILE}"
}

# ── Header Creation (AC #4) ──

@test "StatusLog 5.1-14: agent describes status report header creation if file does not exist" {
  # Section 7.4 checks file existence and creates header — match the specific instruction
  grep -qi 'check if the file exists.*does NOT exist.*create it with a header' "${AGENT_FILE}"
}

@test "StatusLog 5.1-15: agent describes header includes task description from state.yaml" {
  grep -q '\*\*Task:\*\* <task description from state\.yaml>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-16: agent describes header includes route from state.yaml" {
  grep -q '\*\*Route:\*\* <route from state\.yaml>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-17: agent describes header includes mode from state.yaml" {
  grep -q '\*\*Mode:\*\* <mode from state\.yaml>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-18: agent describes header includes started timestamp" {
  grep -q '\*\*Started:\*\* <ISO-8601 timestamp>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-19: agent describes header includes branch from state.yaml" {
  grep -q '\*\*Branch:\*\* <branch from state\.yaml>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-20: agent has Section 7.4 for Status Report Initialization" {
  grep -q '### 7\.4 Status Report Initialization' "${AGENT_FILE}"
}

@test "StatusLog 5.1-21: agent describes loop.sh header as fallback for crash recovery" {
  grep -qi "loop\.sh.*header.*remains as a fallback\|loop\.sh.*header creation remains as a fallback" "${AGENT_FILE}"
}

# ── Append-Only Behavior (AC #5) ──

@test "StatusLog 5.1-22: agent describes status report as append-only in Section 7.3" {
  grep -qi 'status report file is.*APPEND-ONLY' "${AGENT_FILE}"
}

@test "StatusLog 5.1-23: agent describes never using Write tool to overwrite status report" {
  grep -qi 'Never use Write tool to overwrite the entire file' "${AGENT_FILE}"
}

@test "StatusLog 5.1-24: agent describes using Edit tool or Bash append for status report" {
  grep -qi 'Edit tool to append at the end.*Bash.*>>' "${AGENT_FILE}"
}

@test "StatusLog 5.1-25: agent describes append-only anti-pattern in Section 9 Boundary Rules" {
  grep -qi 'Never overwrite or reorder.*status-report\.md.*append-only' "${AGENT_FILE}"
}

# ── Retry History Visibility (AC #3) ──

@test "StatusLog 5.1-26: agent describes both FAIL and PASS entries present for retried stages" {
  # FAIL entry is written in Section 6 step 2, PASS entry in Section 7.3 — both append to same file
  # Verify FAIL entries are appended to status report
  grep -qi 'Append a FAIL entry to.*status-report\.md' "${AGENT_FILE}"
  # Verify PASS entries are appended to status report
  grep -qi 'Append a stage-level entry to.*status-report\.md' "${AGENT_FILE}"
  # Verify append-only guarantees co-existence: FAIL entries from earlier attempts are never removed
  grep -qi 'APPEND-ONLY.*Never read and rewrite' "${AGENT_FILE}"
}

@test "StatusLog 5.1-27: agent describes FAIL entry written before retry increment in Section 6" {
  # Step 2 (FAIL entry) comes before Step 3 (increment currentRetries) within Section 6
  local fail_line increment_line
  fail_line=$(grep -n 'Append a FAIL entry to' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  increment_line=$(grep -n '^3\. Increment `currentRetries`' "${AGENT_FILE}" | head -1 | cut -d: -f1)
  [ "${fail_line}" -lt "${increment_line}" ]
}

# ── Section 8.1 Checkpoint Compatibility ──

@test "StatusLog 5.1-28: agent describes checkpoint summary append to status report unchanged" {
  grep -qi 'Append to status report.*PAUSED (CHECKPOINT)' "${AGENT_FILE}"
}

# ══════════════════════════════════════════════════════════
# Story 5.2 Tests: Final Status Report & Failure Details (AC: #1-#5)
# ══════════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# 5.2 Task 11.1: COMPLETED summary format (AC: #1)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-1: loop script COMPLETED summary includes Total Stages Run" {
  grep -q 'Total Stages Run' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-2: loop script COMPLETED summary includes Elapsed Time" {
  grep -q 'Elapsed Time' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-3: loop script COMPLETED summary includes Artifact Inventory section" {
  grep -q 'Artifact Inventory' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-4: loop script COMPLETED summary includes Completed Stages" {
  grep -q 'Completed Stages' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-5: loop script generates artifact inventory for COMPLETED status" {
  grep -q 'generate_artifact_inventory' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# 5.2 Task 11.2: FAILED summary format (AC: #2)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-6: loop script FAILED summary includes Failed At field" {
  grep -q 'Failed At' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-7: loop script FAILED summary includes Error field" {
  grep -q '\*\*Error:\*\*' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-8: loop script FAILED summary includes Attempts field" {
  grep -q '\*\*Attempts:\*\*' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-9: loop script FAILED summary includes Recovery instructions" {
  grep -q 'Recovery.*bmad-orchestrate.*--resume' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-10: loop script FAILED summary includes story ID when in story loop" {
  grep -q 'read_story_context' "${LOOP_SCRIPT}"
  grep -q 'story_context' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-11: loop script FAILED summary includes Re-routed to when applicable" {
  grep -q 'Re-routed to' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# 5.2 Task 11.3: PAUSED summary format (AC: #3)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-12: loop script PAUSED summary includes Paused At field" {
  grep -q 'Paused At' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-13: loop script PAUSED summary includes Completed Stages" {
  # PAUSED case in write_status_report includes Completed Stages
  grep -q 'PAUSED' "${LOOP_SCRIPT}"
  grep -q 'Completed Stages' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-14: loop script PAUSED summary includes Resume instructions" {
  grep -q 'Resume.*Review artifacts' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# 5.2 Task 11.4: CRASHED summary format (AC: #4)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-15: loop script CRASHED summary includes Exit Code field" {
  grep -q '\*\*Exit Code:\*\*' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-16: loop script CRASHED summary includes Agent terminated unexpectedly" {
  grep -q 'Agent terminated unexpectedly' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-17: loop script CRASHED summary includes Recovery instructions" {
  # The CRASHED case in write_status_report includes Recovery
  grep -q 'CRASHED' "${LOOP_SCRIPT}"
  grep -q 'Recovery' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# 5.2 Task 11.5: Artifact inventory generation (AC: #1, #5)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-18: loop script has generate_artifact_inventory function" {
  grep -q 'generate_artifact_inventory()' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-19: artifact inventory maps planning-artifacts/prd to prd stage" {
  grep -q 'prd\*.md.*stage="prd"\|planning-artifacts/prd.*prd' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-20: artifact inventory maps architecture files to architecture stage" {
  grep -q 'architecture\*.md.*architecture\|planning-artifacts/architecture' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-21: artifact inventory maps epic files to epics-stories stage" {
  grep -q 'epic.*epics-stories' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-22: artifact inventory maps sprint-status.yaml to sprint-planning stage" {
  grep -q 'sprint-status.yaml.*sprint-planning' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-23: artifact inventory maps story files to create-story stage" {
  grep -q 'create-story' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-24: generate_artifact_inventory produces correct output format" {
  # Behavioral test: create mock _bmad-output directory
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  mkdir -p "${tmp_dir}/_bmad-output/planning-artifacts"
  mkdir -p "${tmp_dir}/_bmad-output/implementation-artifacts"
  touch "${tmp_dir}/_bmad-output/planning-artifacts/prd.md"
  touch "${tmp_dir}/_bmad-output/planning-artifacts/architecture.md"
  touch "${tmp_dir}/_bmad-output/planning-artifacts/epics.md"
  touch "${tmp_dir}/_bmad-output/implementation-artifacts/sprint-status.yaml"
  touch "${tmp_dir}/_bmad-output/implementation-artifacts/1-1-test-story.md"

  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(generate_artifact_inventory "${tmp_dir}/_bmad-output")"
  rm -rf "${tmp_dir}"

  echo "${result}" | grep -q 'prd.md (stage: prd)'
  echo "${result}" | grep -q 'architecture.md (stage: architecture)'
  echo "${result}" | grep -q 'epics.md (stage: epics-stories)'
  echo "${result}" | grep -q 'sprint-status.yaml (stage: sprint-planning)'
  echo "${result}" | grep -q '1-1-test-story.md (stage: create-story)'
}

# ──────────────────────────────────────────────
# 5.2 Task 11.6: Elapsed time tracking (AC: #1)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-25: loop script captures START_TIME at beginning of main" {
  grep -q 'START_TIME' "${LOOP_SCRIPT}"
  grep -q 'date +%s' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-26: loop script has format_elapsed_time function" {
  grep -q 'format_elapsed_time()' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-27: format_elapsed_time formats seconds correctly" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: running
completedStages: []
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  rm -rf "${tmp_dir}"
  [ "$(format_elapsed_time 45)" = "45s" ]
  [ "$(format_elapsed_time 125)" = "2m 5s" ]
  [ "$(format_elapsed_time 3725)" = "1h 2m 5s" ]
}

@test "FinalReport 5.2-28: loop script calculates elapsed time for summary" {
  grep -q 'elapsed_seconds.*end_time.*START_TIME\|end_time - START_TIME' "${LOOP_SCRIPT}"
}

# ──────────────────────────────────────────────
# 5.2 Task 11.7: Failure details extraction (AC: #2)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-29: loop script has read_failure_details function" {
  grep -q 'read_failure_details()' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-30: read_failure_details extracts last failure entry from state.yaml" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
currentStage: architecture
failures:
  - stage: prd
    error: "Verification failed"
    attempt: 1
  - stage: architecture
    error: "Sub-agent timeout"
    attempt: 2
completedStages:
  - prd
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_failure_details)"
  rm -rf "${tmp_dir}"
  echo "${result}" | grep -q 'architecture|Sub-agent timeout|2|'
}

@test "FinalReport 5.2-31: read_failure_details extracts reRoutedTo when present" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
failures:
  - stage: epics-stories
    error: "Upstream dependency failed"
    attempt: 1
    reRoutedTo: architecture
completedStages: []
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_failure_details)"
  rm -rf "${tmp_dir}"
  echo "${result}" | grep -q 'epics-stories|Upstream dependency failed|1|architecture'
}

@test "FinalReport 5.2-32: loop script includes story ID when failure occurs during story loop" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
currentStage: dev-story
currentStoryId: "2-3-sprint-planning"
failures:
  - stage: dev-story
    error: "Test failures"
    attempt: 3
completedStages:
  - prd
  - architecture
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_story_context)"
  rm -rf "${tmp_dir}"
  [ "${result}" = "2-3-sprint-planning" ]
}

# ──────────────────────────────────────────────
# 5.2 Task 11.8: Completed stages extraction (AC: #1-#3)
# ──────────────────────────────────────────────

@test "FinalReport 5.2-33: loop script has read_completed_stages function" {
  grep -q 'read_completed_stages()' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-34: read_completed_stages extracts block-style stages" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages:
  - prd
  - architecture
  - epics-stories
gates:
  - prd
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_completed_stages)"
  rm -rf "${tmp_dir}"
  [ "${result}" = "prd, architecture, epics-stories" ]
}

@test "FinalReport 5.2-35: read_completed_stages extracts flow-style stages" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages: [prd, architecture]
gates:
  - prd
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_completed_stages)"
  rm -rf "${tmp_dir}"
  [ "${result}" = "prd, architecture" ]
}

@test "FinalReport 5.2-36: read_completed_stages returns empty for empty list" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
completedStages: []
gates:
  - prd
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_completed_stages)"
  rm -rf "${tmp_dir}"
  [ -z "${result}" ]
}

@test "FinalReport 5.2-37: completed stages listed in summary for all terminal statuses" {
  # Verify Completed Stages appears in COMPLETED, FAILED, PAUSED, CRASHED cases
  grep -c 'Completed Stages' "${LOOP_SCRIPT}" | grep -q '[3-9]\|[0-9][0-9]'
}

# ──────────────────────────────────────────────
# 5.2 Task 11.9: Behavioral integration tests
# ──────────────────────────────────────────────

@test "FinalReport 5.2-38: write_status_report COMPLETED produces correct format" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: completed
task: "Build a SaaS app"
route: "full"
mode: "autonomous"
completedStages:
  - prd
  - architecture
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "COMPLETED" "5" "3m 22s" "prd, architecture" "  - _bmad-output/planning-artifacts/prd.md (stage: prd)"
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Overall Status.*COMPLETED'
  echo "${content}" | grep -q 'Total Stages Run.*2'
  echo "${content}" | grep -q 'Elapsed Time.*3m 22s'
  echo "${content}" | grep -q 'Completed Stages.*prd, architecture'
  echo "${content}" | grep -q 'Artifact Inventory'
  echo "${content}" | grep -q 'prd.md (stage: prd)'
}

@test "FinalReport 5.2-39: write_status_report FAILED produces correct format" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
task: "Build a SaaS app"
route: "full"
mode: "autonomous"
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "FAILED" "3" "1m 5s" "prd" "architecture|Sub-agent timeout|2 of 3|"
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Overall Status.*FAILED'
  echo "${content}" | grep -q 'Failed At.*architecture'
  echo "${content}" | grep -q 'Error.*Sub-agent timeout'
  echo "${content}" | grep -q 'Attempts.*2 of 3'
  echo "${content}" | grep -q 'Recovery.*bmad-orchestrate.*--resume'
}

@test "FinalReport 5.2-40: write_status_report PAUSED produces correct format" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: paused
task: "Build app"
route: "full"
mode: "checkpoint"
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "PAUSED" "2" "45s" "prd, architecture" "architecture"
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Overall Status.*PAUSED'
  echo "${content}" | grep -q 'Paused At.*architecture'
  echo "${content}" | grep -q 'Completed Stages.*prd, architecture'
  echo "${content}" | grep -q 'Resume.*Review artifacts'
}

@test "FinalReport 5.2-41: write_status_report CRASHED produces correct format" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: running
task: "Build app"
route: "full"
mode: "autonomous"
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "CRASHED" "1" "12s" "prd" "137"
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Overall Status.*CRASHED'
  echo "${content}" | grep -q 'Exit Code.*137'
  echo "${content}" | grep -q 'Agent terminated unexpectedly'
  echo "${content}" | grep -q 'Recovery.*bmad-orchestrate.*--resume'
}

@test "FinalReport 5.2-42: write_status_report FAILED includes Re-routed to when present" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
task: "Build app"
route: "full"
mode: "autonomous"
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "FAILED" "3" "2m 10s" "prd" "epics-stories|Upstream fail|1 of 3|architecture"
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Re-routed to.*architecture'
}

@test "FinalReport 5.2-43: loop script has read_story_context function" {
  grep -q 'read_story_context()' "${LOOP_SCRIPT}"
}

@test "FinalReport 5.2-44: read_story_context returns empty for non-story stages" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: failed
currentStage: architecture
completedStages:
  - prd
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  local result
  result="$(read_story_context)"
  rm -rf "${tmp_dir}"
  [ -z "${result}" ]
}

@test "FinalReport 5.2-45: write_status_report counts completed stages correctly" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  cat > "${tmp_dir}/state.yaml" <<'YAML'
status: completed
task: "Build app"
route: "full"
mode: "autonomous"
YAML
  BATS_TESTING=1 TEST_BMAD_DIR="${tmp_dir}" source "${LOOP_SCRIPT}"
  STATUS_REPORT="${tmp_dir}/status-report.md"
  write_status_report "COMPLETED" "8" "10m 5s" "prd, architecture, epics-stories, readiness, sprint-planning" ""
  local content
  content="$(cat "${STATUS_REPORT}")"
  rm -rf "${tmp_dir}"
  echo "${content}" | grep -q 'Total Stages Run.*5'
}

# ══════════════════════════════════════════════════════════
# Story 5.3 Tests: Task Report Generation (AC: #1-#5)
# ══════════════════════════════════════════════════════════

TASK_REPORT_TEMPLATE=".bmad-orchestrator/templates/stage-task-report.md"
LOOP_SCRIPT=".bmad-orchestrator/loop.sh"

# ──────────────────────────────────────────────
# 5.3 Task 4.2: Template validation (AC: #2, #3)
# ──────────────────────────────────────────────

@test "TaskReport 5.3-1: stage-task-report.md template file exists" {
  [ -f "${TASK_REPORT_TEMPLATE}" ]
}

@test "TaskReport 5.3-2: task-report template has valid YAML frontmatter with stage: task-report" {
  head -1 "${TASK_REPORT_TEMPLATE}" | grep -q '^---$'
  grep -q 'stage: task-report' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-3: task-report template frontmatter contains agent: bmad-orchestrator" {
  grep -q 'agent: bmad-orchestrator' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-4: task-report template frontmatter contains command: generate-task-report" {
  grep -q 'command: generate-task-report' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-5: task-report template frontmatter contains requiredArtifacts with state.yaml" {
  grep -q 'requiredArtifacts' "${TASK_REPORT_TEMPLATE}"
  grep -q 'state\.yaml' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-6: task-report template frontmatter contains requiredArtifacts with status-report.md" {
  grep -q 'status-report\.md' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-7: task-report template frontmatter contains producedArtifacts with task-report.md" {
  grep -q 'producedArtifacts' "${TASK_REPORT_TEMPLATE}"
  grep -q 'task-report\.md' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-8: task-report template contains Context Injection section" {
  grep -q '## Context Injection' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-9: task-report template contains {{task_description}} placeholder" {
  grep -q '{{task_description}}' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-10: task-report template contains {{failure_context}} per project-context.md standard" {
  grep -q '{{failure_context}}' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-11: task-report template contains {{mode_instructions}} per project-context.md standard" {
  grep -q '{{mode_instructions}}' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-12: task-report template contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-13: task-report template instructs reading all _bmad-output/ artifacts" {
  grep -q '_bmad-output' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-14: task-report template instructs reading state.yaml for pipeline metadata" {
  grep -q 'state\.yaml' "${TASK_REPORT_TEMPLATE}"
  grep -qi 'pipeline.*metadata\|metadata.*pipeline\|task.*route.*mode\|completedStages' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-15: task-report template instructs reading status-report.md for stage outcomes" {
  grep -q 'status-report\.md' "${TASK_REPORT_TEMPLATE}"
  grep -qi 'stage.*outcome\|outcome' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-16: task-report template requires Summary of Work Accomplished section" {
  grep -qi 'Summary of Work Accomplished' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-17: task-report template requires Key Decisions Made section" {
  grep -qi 'Key Decisions Made' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-18: task-report template requires Important Code Implemented section" {
  grep -qi 'Important Code Implemented' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-19: task-report template requires Architecture and Design Choices section" {
  grep -qi 'Architecture and Design Choices' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-20: task-report template requires Notable Observations section" {
  grep -qi 'Notable Observations' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-21: task-report template contains Verification section" {
  grep -q '## Verification' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-22: task-report template verification checks task-report.md existence" {
  grep -q 'task-report\.md' "${TASK_REPORT_TEMPLATE}"
  grep -qi 'exist\|verify\|confirm\|check' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-23: task-report template verification checks for 5 required content sections" {
  grep -qi '5.*section\|five.*section\|all.*section\|required.*section' "${TASK_REPORT_TEMPLATE}"
}

@test "TaskReport 5.3-24: task-report template verification checks minimum content length" {
  grep -qi '500.*character\|non-trivial\|minimum.*length\|substantive' "${TASK_REPORT_TEMPLATE}"
}

# ──────────────────────────────────────────────
# 5.3 Task 4.1: Orchestrator agent task report handling (AC: #2, #3, #4)
# ──────────────────────────────────────────────

@test "TaskReport 5.3-25: agent describes task-report stage handling in Section 11" {
  grep -qi 'Section 11\|Task Report Generation' "${AGENT_FILE}"
  grep -q '## 11\.\|## 11 ' "${AGENT_FILE}"
}

@test "TaskReport 5.3-26: agent describes reading all _bmad-output/ artifacts for task report" {
  grep -qi '_bmad-output.*artifact\|artifact.*_bmad-output\|read.*_bmad-output\|_bmad-output.*read' "${AGENT_FILE}"
}

@test "TaskReport 5.3-27: agent describes reading state.yaml for task report context" {
  grep -qi 'state\.yaml' "${AGENT_FILE}"
}

@test "TaskReport 5.3-28: agent describes reading status-report.md for task report context" {
  grep -qi 'status-report\.md' "${AGENT_FILE}"
}

@test "TaskReport 5.3-29: agent describes writing task-report.md with required content sections" {
  grep -qi 'task-report\.md' "${AGENT_FILE}"
  grep -qi 'Summary of Work Accomplished\|Key Decisions Made\|Important Code Implemented\|Architecture and Design Choices\|Notable Observations' "${AGENT_FILE}"
}

@test "TaskReport 5.3-30: agent describes exiting with code 2 after task report generation" {
  # Section 11 should mention exit code 2 in context of task report
  grep -qi 'exit.*code.*2\|code 2\|exit with.*2' "${AGENT_FILE}"
}

@test "TaskReport 5.3-31: agent describes task-report stage check in Section 1.2" {
  # Section 1.2 should have a check for task-report/generate-task-report before terminal states
  grep -qi 'task-report.*Section 11\|generate-task-report.*Section 11\|task-report.*goto.*11\|generate-task-report' "${AGENT_FILE}"
}

@test "TaskReport 5.3-32: agent describes loading stage-task-report.md template in Section 11" {
  grep -qi 'stage-task-report\.md' "${AGENT_FILE}"
}

@test "TaskReport 5.3-33: agent task report does NOT use normal verification flow (Section 5)" {
  grep -qi 'NOT.*normal.*verification\|NOT.*Section 5\|self-contained\|does NOT go through.*verification\|skip.*verification' "${AGENT_FILE}"
}

@test "TaskReport 5.3-34: agent describes synthesizing 5 report sections for task report" {
  grep -qi 'Summary of Work Accomplished' "${AGENT_FILE}"
  grep -qi 'Key Decisions Made' "${AGENT_FILE}"
  grep -qi 'Important Code Implemented' "${AGENT_FILE}"
  grep -qi 'Architecture and Design Choices' "${AGENT_FILE}"
  grep -qi 'Notable Observations' "${AGENT_FILE}"
}

@test "TaskReport 5.3-35: agent describes orchestrator writing task-report.md directly (not via sub-agent)" {
  grep -qi 'orchestrator.*write.*task-report\|write.*task-report.*directly\|writes the report\|writes the file directly\|write.*report.*directly' "${AGENT_FILE}"
}

@test "TaskReport 5.3-36: agent describes updating state to currentStage task-report" {
  grep -qi 'currentStage.*task-report\|task-report.*currentStage' "${AGENT_FILE}"
}

# ──────────────────────────────────────────────
# Auto Code Review Route Tests
# ──────────────────────────────────────────────

REVIEW_TEMPLATE=".bmad-orchestrator/templates/stage-auto-code-review.md"

@test "Review route: orchestrator agent recognizes route: review" {
  grep -q 'review' "${AGENT_FILE}"
  grep -qi 'route.*review\|review.*route' "${AGENT_FILE}"
}

@test "Review route: auto-code-review stage sequence defined" {
  grep -q 'auto-code-review' "${AGENT_FILE}"
}

@test "Review route: auto-code-review in frozen identifiers list" {
  grep -q 'quick-dev.*auto-code-review' "${AGENT_FILE}"
}

@test "Review route: route review maps to auto-code-review" {
  grep -qi 'review.*auto-code-review' "${AGENT_FILE}"
}

@test "Template: stage-auto-code-review.md exists" {
  [ -f "${REVIEW_TEMPLATE}" ]
}

@test "Template: auto-code-review has valid frontmatter with stage: auto-code-review" {
  head -20 "${REVIEW_TEMPLATE}" | grep -q 'stage: auto-code-review'
}

@test "Template: auto-code-review frontmatter contains agent: bmad-dev" {
  head -20 "${REVIEW_TEMPLATE}" | grep -q 'agent: bmad-dev'
}

@test "Template: auto-code-review frontmatter contains command: CR" {
  head -20 "${REVIEW_TEMPLATE}" | grep -q 'command: CR'
}

@test "Template: auto-code-review contains Context Injection section" {
  grep -q '## Context Injection' "${REVIEW_TEMPLATE}"
}

@test "Template: auto-code-review contains Stage Instructions section" {
  grep -q '## Stage Instructions' "${REVIEW_TEMPLATE}"
}

@test "Template: auto-code-review contains Verification section" {
  grep -q '## Verification' "${REVIEW_TEMPLATE}"
}

@test "Template: auto-code-review contains producedArtifacts with auto-code-review-report.md" {
  grep -q 'auto-code-review-report\.md' "${REVIEW_TEMPLATE}"
}

@test "Template: auto-code-review contains PASS/CONCERNS/FAIL quality gate" {
  grep -q 'PASS' "${REVIEW_TEMPLATE}"
  grep -q 'CONCERNS' "${REVIEW_TEMPLATE}"
  grep -q 'FAIL' "${REVIEW_TEMPLATE}"
}

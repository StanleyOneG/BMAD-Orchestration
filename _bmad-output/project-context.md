---
project_name: 'bmad_testing'
user_name: 'Stanley'
date: '2026-02-03'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'critical_rules']
existing_patterns_found: 8
status: 'complete'
rule_count: 35
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Bash** -- loop script, primary execution shell (`set -euo pipefail` required)
- **Claude Code** -- agent system (`.claude/agents/`, `.claude/commands/`, Task tool with resume)
- **YAML** -- state file format, configuration
- **Markdown** -- agent definitions, prompt templates, artifacts
- **Python via `uv run`** -- complex hooks only (not core logic)

## Critical Implementation Rules

### Bash Scripting Rules

- Every script starts with `set -euo pipefail`
- All variables quoted: `"${var}"` not `$var`
- All local variables declared with `local`
- Functions use `snake_case`: `check_branch_safety`, `read_state`, `launch_agent`
- ShellCheck compliant -- no suppressed warnings without a comment explaining why
- Exit codes documented at top of every script

### State File Rules

- **Location:** `.bmad-orchestrator/state.yaml`
- **NEVER write directly to `state.yaml`** -- always write to `state.yaml.tmp` then `mv state.yaml.tmp state.yaml` (atomic rename)
- All field names use `camelCase`: `currentStage`, `storyLoop`, `runType`, `completedStages`
- Error messages in the `failures` array are single-line summaries only
- The state file is the single source of truth -- if it says a stage completed, it completed; if it doesn't, it didn't

### Frozen Stage Identifiers

These exact strings must be used everywhere -- in state files, template filenames, orchestrator logic. No aliases, no variations:

`prd`, `architecture`, `epics-stories`, `readiness`, `sprint-planning`, `create-story`, `dev-story`, `code-review`, `quick-spec`, `quick-dev`

### File Naming Rules

- All files and directories use `kebab-case`: `loop.sh`, `state.yaml`, `stage-prd.md`, `status-report.md`
- Template files follow pattern: `stage-{identifier}.md`
- Runtime files (not checked in): `state.yaml`, `status-report.md`, `task-report.md`

### Prompt Template Rules

Every template in `.bmad-orchestrator/templates/` must have:
- YAML frontmatter with: `stage`, `agent`, `command`, `requiredArtifacts`, `producedArtifacts`
- `## Context Injection` section with `{{task_description}}`, `{{failure_context}}`, `{{mode_instructions}}`
- `## Stage Instructions` section
- `## Verification` section -- mandatory, never skip

### Boundary Rules (Critical)

- **Loop script** reads state but NEVER writes to it
- **Orchestrator agent** reads/writes state but NEVER directly writes BMAD artifacts (`_bmad-output/`)
- **Sub-agents** produce artifacts through their own workflows -- the orchestrator never bypasses them
- **Templates** are read-only at runtime -- never modified by the orchestrator

### Agent Communication Pattern

- Orchestrator launches sub-agents via Task tool, then resumes them (same agent ID) to respond to questions
- One Ralph Loop iteration = one complete pipeline stage with all back-and-forth
- Sub-agent IDs are transient -- never persisted in state file
- After sub-agent completes, orchestrator runs verification before marking stage complete

### Verification Pattern (Never Skip)

After every sub-agent workflow completes:
1. Check all `producedArtifacts` exist on disk
2. Compare output against original `task` from state file
3. For validation stages (readiness, code-review), check PASS/CONCERNS/FAIL result
4. Only then update state and exit

### Exit Code Convention

- `0` = stage completed, loop continues
- `1` = stage failed after retries, loop stops
- `2` = pipeline complete, loop stops
- `3` = checkpoint pause, loop stops

### Anti-Patterns

- Writing to `state.yaml` directly (without temp-then-rename)
- Inventing new stage identifiers not in the frozen list
- Skipping the verification step after sub-agent completion
- Multi-line error messages in the state file failures array
- Unquoted variables in bash scripts
- Loop script modifying state file
- Orchestrator writing directly to `_bmad-output/`

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Refer to `_bmad-output/planning-artifacts/architecture.md` for full architectural context

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack or patterns change
- Remove rules that become obvious over time

Last Updated: 2026-02-03

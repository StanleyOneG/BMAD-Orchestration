# BMad Native Agent Generator

Converts BMad 6.x agent skills into native agent files for Claude Code and Pi.

After BMad is installed, agent personas live as skills (e.g. `.claude/skills/bmad-agent-pm/`). This script reads those skill definitions and produces native agent files that the host tool can discover and delegate to directly. The source agent skill directories are automatically removed after generation to avoid duplication.

## Prerequisites

- Node.js (no npm dependencies required)
- A project with BMad 6.x installed (agent skills present in the skills directory)

## Quick Start

```bash
# Generate Claude Code agents (default)
node src/generate-claude-agents.js

# Generate Pi agents
node src/generate-claude-agents.js --target pi

# Generate for both platforms
node src/generate-claude-agents.js --target both

# Preview without writing anything
node src/generate-claude-agents.js --dry-run
```

## Command Reference

```
node src/generate-claude-agents.js [options]
```

### Options

| Flag | Value | Default | Description |
|------|-------|---------|-------------|
| `--target` | `claude`, `pi`, or `both` | `claude` | Which platform(s) to generate agents for |
| `--project-root` | directory path | current directory | Root of the project containing `.claude/` or `.pi/` |
| `--skills-dir` | directory path | auto-detected | Override the skills directory to scan (ignored when `--target both`) |
| `--dry-run` | _(none)_ | off | Print what would happen without writing or deleting anything |
| `--help`, `-h` | _(none)_ | | Show usage information |

### How `--skills-dir` Auto-Detection Works

When `--skills-dir` is not provided, the script resolves it from `--target` and `--project-root`:

| Target | Skills directory scanned | Agents written to |
|--------|--------------------------|-------------------|
| `claude` | `{project-root}/.claude/skills/` | `{project-root}/.claude/agents/` |
| `pi` | `{project-root}/.pi/skills/` | `{project-root}/.pi/agents/` |
| `both` | Both of the above (each independently) | Both of the above |

When `--target both` is used, `--skills-dir` is ignored because each platform needs its own skills directory.

## What the Script Does

For each platform target, the script performs these steps in order:

1. **Discover** -- Scans the skills directory for subdirectories containing a `bmad-skill-manifest.yaml` with `type: agent`. Skills with other types (e.g. `workflow`) or without a manifest are skipped.

2. **Generate** -- For each discovered agent, creates a native agent file in the platform's agents directory (`{platform}/agents/`). Each file contains:
   - Platform-specific YAML frontmatter (name, description, tools)
   - The full body content from the agent's `SKILL.md`, passed through unmodified

3. **Clean up** -- Removes the source agent skill directories from the skills folder. Only directories that were successfully processed as agents are removed. All non-agent skills (workflows, tools, etc.) are left untouched.

4. **Suggest** -- Prints a suggested snippet for `CLAUDE.md` or `PI.md` listing the generated agents with their display names and capabilities.

In `--dry-run` mode, steps 2 and 3 are skipped -- nothing is written or deleted.

## Platform Differences

The generated agent files differ per platform in their YAML frontmatter format:

**Claude Code** -- tools as a YAML list (PascalCase names):
```yaml
---
name: bmad-pm
description: "John - Product manager for PRD creation and requirements discovery."
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Write
  - Edit
  - WebSearch
---
```

**Pi** -- tools as a comma-separated string (lowercase names):
```yaml
---
name: bmad-pm
description: "John - Product manager for PRD creation and requirements discovery."
tools: read,write,edit,bash,grep,find,ls
---
```

Key differences:
- Pi uses `find` instead of `Glob`, and adds `ls`
- Pi does not support `WebSearch` or `WebFetch`
- Tool names are lowercase in Pi, PascalCase in Claude Code

## Generated Agents

| Output file | Display name | Persona focus |
|-------------|--------------|---------------|
| `bmad-analyst.md` | Mary | Business analysis, research, product briefs |
| `bmad-architect.md` | Winston | Technical architecture design |
| `bmad-dev.md` | Amelia | Story implementation with TDD |
| `bmad-pm.md` | John | PRD creation/validation, epics and stories |
| `bmad-sm.md` | Bob | Sprint planning, story creation, retrospectives |
| `bmad-ux-designer.md` | Sally | UX design, wireframes, diagrams |
| `bmad-quick-flow.md` | Barry | Quick spec + dev for simple tasks |
| `bmad-qa.md` | Quinn | Test automation |
| `bmad-tech-writer.md` | Paige | Documentation |
| `bmad-tea.md` | Murat | Test architecture, ATDD, CI/CD quality gates |

## Input Format

The script reads two files from each agent skill directory:

**`bmad-skill-manifest.yaml`** -- flat YAML with agent metadata:
```yaml
type: agent
name: bmad-agent-pm
displayName: John
title: Product Manager
icon: "📋"
capabilities: "PRD creation, requirements discovery"
module: bmm
```

**`SKILL.md`** -- standard markdown with YAML frontmatter:
```markdown
---
name: bmad-agent-pm
description: Product manager for PRD creation and requirements discovery.
---

# John

## Overview
...
```

Only skills where `type: agent` in the manifest are processed. The `SKILL.md` body (everything below its frontmatter) becomes the native agent body verbatim.

## Running Tests

```bash
node --test src/generate-claude-agents.test.js
```

Tests use isolated filesystem fixtures and cover discovery, generation, cleanup, platform formatting, dry-run safety, and CLI argument handling.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Skills directory does not exist | Exits with error (single target) or warns and continues (when using `--target both` and one dir is missing) |
| No agent-type skills found | Exits with non-zero code and error message |
| Agent manifest present but no `SKILL.md` | Warns and skips that agent |
| Unknown CLI flag | Warns and continues |
| Flag missing required value | Exits with error |
| Invalid `--target` value | Exits with error |

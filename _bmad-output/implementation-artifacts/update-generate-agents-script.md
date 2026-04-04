# Story: Update `generate-claude-agents.js` for BMad 6.x Skills-Based Architecture + Pi Support

**Status:** Ready for Dev
**File:** `src/generate-claude-agents.js`

---

## Context

Stanley maintains a custom script (`src/generate-claude-agents.js`) that generates native coding-agent agents from BMad persona definitions. This allows agent-aware tools (Claude Code, Pi) to discover and auto-delegate to BMad agents natively, rather than requiring manual skill invocation.

**BMad has changed its installation structure.** Previously, agents lived in `_bmad/[module]/agents/` as `.agent.yaml` or compiled `.md` files with XML blocks. Now (v6.2.x), all agents and workflows are installed as **skills** in the IDE's skills directory (`.claude/skills/` or `.pi/skills/`). Agent skills are distinguished from workflow skills by a `bmad-skill-manifest.yaml` with `type: agent`.

## What Changed (Old vs New)

| Aspect | Old (pre-6.x) | New (6.2.x) |
|--------|---------------|-------------|
| **Agent location** | `_bmad/[module]/agents/*.agent.yaml` or compiled `.md` | `.claude/skills/bmad-agent-*/SKILL.md` + `bmad-skill-manifest.yaml` |
| **Agent format** | Custom YAML with nested sections (`agent: > metadata: > persona: > menu:`) or XML blocks in markdown | Standard markdown with frontmatter + sections (Identity, Communication Style, Principles, Capabilities table, On Activation) |
| **Capabilities** | `<menu>` XML items with `workflow=`, `exec=`, `action=`, `data=` attributes pointing to `_bmad/` paths | Markdown table with `Code \| Description \| Skill` columns, referencing skill names directly |
| **Routing** | `module-help.csv` and `workflow-manifest.csv` | `bmad-skill-manifest.yaml` per skill, `agent-manifest.csv` and `skill-manifest.csv` in `_bmad/_config/` |
| **Config loading** | Direct read of `_bmad/[module]/config.yaml` in activation step | Via `bmad-init` skill (handles discovery + module resolution) |

## Objective

Rewrite the script to:
1. **Discover** agent skills from the skills directory by scanning for `bmad-skill-manifest.yaml` where `type: agent`
2. **Parse** the new `SKILL.md` + manifest format (much simpler than old XML/YAML parsing)
3. **Generate** native agent files with platform-specific frontmatter and tool declarations
4. **Support multi-target** via a `--target` flag (`claude`, `pi`, or `both`)

## Input Sources

For each agent, read two files from the skills directory:

**`bmad-skill-manifest.yaml`** — structured metadata:
```yaml
type: agent
name: bmad-agent-pm
displayName: John
title: Product Manager
icon: "📋"
capabilities: "PRD creation, requirements discovery..."
role: "Product Manager specializing in..."
identity: "Product management veteran..."
communicationStyle: "Asks 'WHY?' relentlessly..."
principles: "Channel expert product manager thinking..."
module: bmm
```

**`SKILL.md`** — the full agent definition with frontmatter, persona sections, capabilities table, activation instructions, and critical actions. This is already well-structured markdown. Example structure:

```markdown
---
name: bmad-agent-pm
description: Product manager for PRD creation and requirements discovery...
---

# John

## Overview
This skill provides a Product Manager who drives PRD creation...

## Identity
Product management veteran with 8+ years...

## Communication Style
Asks "WHY?" relentlessly...

## Principles
- Channel expert product manager thinking...

## Critical Actions
- READ the entire story file BEFORE any implementation...

## Capabilities
| Code | Description | Skill |
|------|-------------|-------|
| CP | Expert led facilitation to produce your PRD | bmad-create-prd |
| VP | Validate a PRD | bmad-validate-prd |

## On Activation
1. Load config via bmad-init skill...
2. Load project context...
3. Greet and present capabilities...
```

## Platform Tool Mapping

Claude Code and Pi have different tool sets, naming conventions, and frontmatter formats. The script must handle this per-platform.

### Tool Availability Comparison

| Claude Code Tool | Pi Equivalent | Notes |
|---|---|---|
| `Read` | `read` | Direct match |
| `Write` | `write` | Direct match |
| `Edit` | `edit` | Direct match |
| `Bash` | `bash` | Direct match |
| `Grep` | `grep` | Both ripgrep-backed |
| `Glob` | `find` | Pi uses `find` for file pattern matching |
| `WebSearch` | **n/a** | Not available in Pi natively |
| `WebFetch` | **n/a** | Not available in Pi natively |
| -- | `ls` | Pi-specific, useful for exploration agents |

### Claude Tool Maps (PascalCase, YAML list in frontmatter)

```javascript
const CLAUDE_TOOL_MAP = {
  analyst:               ['Read', 'Grep', 'Glob', 'Bash', 'WebSearch', 'WebFetch', 'Write', 'Edit'],
  architect:             ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  dev:                   ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  pm:                    ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  sm:                    ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'ux-designer':         ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'quick-flow-solo-dev': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  qa:                    ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'tech-writer':         ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  tea:                   ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
};
```

### Pi Tool Maps (lowercase, comma-separated string in frontmatter)

```javascript
const PI_TOOL_MAP = {
  analyst:               'read,write,edit,bash,grep,find,ls',
  architect:             'read,write,edit,bash,grep,find,ls',
  dev:                   'read,write,edit,bash,grep,find,ls',
  pm:                    'read,write,edit,bash,grep,find,ls',
  sm:                    'read,write,edit,bash,grep,find,ls',
  'ux-designer':         'read,write,edit,bash,grep,find,ls',
  'quick-flow-solo-dev': 'read,write,edit,bash,grep,find,ls',
  qa:                    'read,write,edit,bash,grep,find,ls',
  'tech-writer':         'read,write,edit,bash,grep,find,ls',
  tea:                   'read,write,edit,bash,grep,find,ls',
};
```

Note: All Pi agents get the full tool set since Pi has no WebSearch/WebFetch equivalents. BMad agent skills self-constrain via their instructions, not tool restrictions. The WebSearch/WebFetch gap is an accepted limitation -- research-phase tools whose absence does not break core BMad workflows.

### Frontmatter Format Differences

**Claude Code** -- YAML list:
```yaml
---
name: bmad-pm
description: "John - Product manager for PRD creation and requirements discovery..."
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

**Pi** -- comma-separated string:
```yaml
---
name: bmad-pm
description: "John - Product manager for PRD creation and requirements discovery..."
tools: read,write,edit,bash,grep,find,ls
---
```

## Output

For each discovered agent, generate a native agent file:

- **Claude target:** `.claude/agents/{agent-name}.md`
- **Pi target:** `.pi/agents/{agent-name}.md`

Key decisions for the output:
- **Frontmatter `name`** -- short filename form (e.g., `bmad-pm` not `bmad-agent-pm`), using `FILENAME_MAP`
- **Frontmatter `description`** -- composed from manifest `displayName` + SKILL.md `description`
- **Frontmatter `tools`** -- platform-specific format and tool names from the maps above
- **Body** is the SKILL.md content below its own frontmatter, unmodified -- the activation steps, persona, capabilities table, and critical actions are all already correct for the new BMad format
- **Do NOT** inject old-style menu command handlers (workflow/exec/action/data) -- the new format uses skill references, which the host tool resolves natively

## CLI Interface

```
node src/generate-claude-agents.js [options]

Options:
  --skills-dir PATH    Skills directory to scan (default: auto-detect from --target)
  --target TARGET      claude | pi | both (default: claude)
  --project-root PATH  Project root (default: cwd)
  --dry-run            Print what would be generated without writing
  --help, -h           Show usage
```

Auto-detection logic for `--skills-dir`:
- `claude` -> `{project-root}/.claude/skills`
- `pi` -> `{project-root}/.pi/skills`
- `both` -> scan both, generate to respective agent dirs

Output directories (not configurable, derived from target):
- `claude` -> `{project-root}/.claude/agents/`
- `pi` -> `{project-root}/.pi/agents/`

## Acceptance Criteria

```gherkin
GIVEN a project with BMad 6.x installed (.claude/skills/ containing agent skills)
WHEN I run `node src/generate-claude-agents.js --target claude`
THEN native agent files are created in .claude/agents/ for each skill with type: agent in its manifest
AND each generated file has YAML frontmatter with name, description, and tools as a YAML list (PascalCase)
AND each generated file contains the SKILL.md body content unmodified
AND the script reports what it generated to stdout

GIVEN a project with BMad installed for Pi (.pi/skills/)
WHEN I run `node src/generate-claude-agents.js --target pi`
THEN native agent files are created in .pi/agents/
AND each generated file has YAML frontmatter with tools as a comma-separated lowercase string
AND WebSearch/WebFetch are NOT included in Pi tool declarations
AND Glob is replaced with find, and ls is added

GIVEN --target both
WHEN I run the script
THEN agents are generated in BOTH .claude/agents/ and .pi/agents/
AND each uses its platform-specific frontmatter format and tool names

GIVEN --dry-run flag
WHEN I run the script
THEN it prints what would be generated but writes nothing

GIVEN a skills directory with no agent-type manifests
WHEN I run the script
THEN it exits with a clear error message and non-zero exit code

GIVEN an agent skill without a bmad-skill-manifest.yaml
WHEN the script scans
THEN that skill is skipped (not treated as an agent)
```

## What to Keep from the Old Script

- **`FILENAME_MAP`** -- agent-name to output-filename mapping (e.g., `bmad-agent-pm` -> `bmad-pm`). Review and update for any new agents in 6.x (e.g., `bmad-tea`)
- **`DESCRIPTION_MAP`** -- delegation descriptions for when to route to each agent
- **`AGENT_INFO`** -- display names and summaries
- **No-dependency approach** -- Node.js only, no npm packages
- **`parseSimpleYaml()`** -- reuse for parsing `bmad-skill-manifest.yaml`
- **`generateClaudeMdSnippet()`** -- the suggested CLAUDE.md output (extend with Pi equivalent)

## What to Remove

- All XML parsing (`extractXmlTag`, `extractXmlAttr`, `extractAllXmlItems`, `parseAgentXml`, `parseCompiledAgent`)
- The complex YAML agent parser (`parseAgentYaml` and its helpers -- `collectBlock`, `collectList`, section state machine)
- `discoverAgents()` and `findAgentFiles()` -- replace with skills-directory scanner
- `readModuleHelp()` -- CSV-based workflow routing no longer needed
- `buildWorkflowTable()` -- old menu-item-to-command mapping
- `getUsedHandlerTypes()` -- handler detection for old menu system
- The entire "Menu Command Handlers" generation section in `generateAgentMarkdown()`
- `rewriteAgentCommands()` -- old `.claude/commands/` rewriting (commands directory is no longer used this way)
- `removeAgentDirectories()` -- old `_bmad/agents/` cleanup
- The single `TOOL_MAP` -- replaced by platform-specific `CLAUDE_TOOL_MAP` and `PI_TOOL_MAP`

## Technical Notes

- The `bmad-skill-manifest.yaml` is simple flat YAML -- the existing `parseSimpleYaml()` can handle it
- SKILL.md frontmatter is standard `---` delimited -- split on second `---` to get the body
- For `--target both`, if one skills dir does not exist, warn but proceed with the other
- Preserve any non-bmad agent files already in the output directory (e.g., `bmad-orchestrator.md`)
- Pi's WebSearch/WebFetch gap is an accepted limitation -- these are research-phase tools and their absence does not break core BMad workflows. If needed later, Pi extensions can be built separately.

## Reference Files

The dev agent should read these files for full context:

- **Current script:** `src/generate-claude-agents.js` -- the existing implementation to be rewritten
- **Example SKILL.md:** `.claude/skills/bmad-agent-pm/SKILL.md` -- representative agent skill file
- **Example manifest:** `.claude/skills/bmad-agent-pm/bmad-skill-manifest.yaml` -- agent manifest format
- **Pi agent example:** See `.pi/agents/` in `/workspaces/picodingsetup/indidevdan_pi/main/` for Pi native agent format reference
- **Pi skills install:** `/workspaces/picodingsetup/pi_with_bmad/.pi/skills/` -- how BMad installs for Pi

---

## Status

**Status:** done

---

## Dev Agent Record

### Implementation Plan

Complete rewrite of `src/generate-claude-agents.js` from old `_bmad/` XML/YAML agent format to BMad 6.x skills-based architecture. Key decisions:
- Kept `parseSimpleYaml()` for manifest parsing (flat YAML, works perfectly)
- Kept `FILENAME_MAP`, `DESCRIPTION_MAP`, `AGENT_INFO` (updated for 6.x agents)
- Replaced single `TOOL_MAP` with `CLAUDE_TOOL_MAP` + `PI_TOOL_MAP`
- New `parseSkillMd()` extracts frontmatter and passes body through unmodified
- New `discoverAgentSkills()` scans skills dir for `bmad-skill-manifest.yaml` where `type: agent`
- New `generateAgentFile()` produces platform-specific frontmatter + unmodified body
- Added `--target` flag (claude/pi/both) with auto-detection of skills/output dirs
- Added `--dry-run` flag
- Exports functions via `module.exports` for testing (guarded by `require.main === module`)

### Removed (as specified in story)
- All XML parsing functions
- Complex YAML agent parser (`parseAgentYaml`, `collectBlock`, `collectList`, state machine)
- `discoverAgents()`, `findAgentFiles()` (old `_bmad/` scanner)
- `readModuleHelp()`, `parseCsv()`, CSV parsing helpers
- `buildWorkflowTable()`, `getUsedHandlerTypes()`
- Old `generateAgentMarkdown()` (menu handlers, activation steps, persona sections)
- `rewriteAgentCommands()`, `removeAgentDirectories()`

### Completion Notes

- 40 tests pass across 12 test suites (node:test)
- All 10 agents discovered and generated correctly (analyst, architect, dev, pm, qa, quick-flow, sm, tech-writer, ux-designer, tea)
- Claude frontmatter: YAML list tools (PascalCase), includes WebSearch/WebFetch where appropriate
- Pi frontmatter: comma-separated lowercase string, no WebSearch/WebFetch, find replaces Glob, ls added
- `--target both` warns about missing dir but proceeds with available target
- `--dry-run` prints actions without writing
- Non-existent skills dir and no-agents-found both exit with clear error and non-zero code
- Skills without manifest or with non-agent manifest type are correctly skipped

---

### Review Findings

- [x] [Review][Patch] `--skills-dir` silently ignored with `--target both` — warn or reject the combination [generate-claude-agents.js:414]
- [x] [Review][Patch] Unrecognized/misspelled CLI flags silently ignored — add unknown-flag warning [generate-claude-agents.js:41-61]
- [x] [Review][Patch] Value-taking flags consume following flags as values (e.g. `--project-root --dry-run`) [generate-claude-agents.js:42-47]
- [x] [Review][Patch] Value-taking flags at end of args with no value silently use defaults [generate-claude-agents.js:42-47]
- [x] [Review][Patch] `escapeYamlString` only escapes double quotes — backslashes and newlines pass through [generate-claude-agents.js:299-301]
- [x] [Review][Patch] CLI integration test uses real project directory, not isolated fixtures [generate-claude-agents.test.js:413]
- [x] [Review][Patch] Test fixture race — shared `FIXTURES_DIR` across describe blocks with independent setup/teardown [generate-claude-agents.test.js:25-28]
- [x] [Review][Patch] Missing test: `DESCRIPTION_MAP` completeness against `FILENAME_MAP` [generate-claude-agents.test.js]
- [x] [Review][Patch] Missing test: `AGENT_INFO` completeness against `FILENAME_MAP` [generate-claude-agents.test.js]
- [x] [Review][Patch] Missing CLI test: `--target both` scenario (AC3) [generate-claude-agents.test.js]
- [x] [Review][Patch] Missing CLI test: "no agents found" exit behavior (AC5) [generate-claude-agents.test.js]
- [x] [Review][Patch] Missing test: `escapeYamlString` with backslash input [generate-claude-agents.test.js]
- [x] [Review][Defer] `parseSimpleYaml` doesn't handle YAML block scalars — deferred, by-design flat YAML parser
- [x] [Review][Defer] `parseSkillMd` frontmatter `---` extraction is positional, not line-boundary — deferred, works with all current SKILL.md files
- [x] [Review][Defer] `parseSimpleYaml` list items not indentation-checked — deferred, only parses flat manifest YAML
- [x] [Review][Defer] Partial failure exit code 0 with `--target both` when one target errors — deferred, spec says warn-and-proceed

---

## File List

- `src/generate-claude-agents.js` -- complete rewrite
- `src/generate-claude-agents.test.js` -- new test file (40 tests, 12 suites)

---

## Change Log

- 2026-04-04: Complete rewrite of generate-claude-agents.js for BMad 6.x skills-based architecture + Pi support
- 2026-04-04: Code review — 12 patches applied (CLI arg hardening, escapeYamlString fix, test isolation + coverage gaps)

#!/usr/bin/env node

// BMAD -> Claude Code Native Agent Generator
//
// Reads an installed _bmad/ directory and generates .claude/agents/*.md files
// compatible with Claude Code's native agent system. Each BMAD agent becomes a
// proper Claude Code subagent with YAML frontmatter and a system prompt body.
//
// Usage:
//   node tools/generate-claude-agents.js [--bmad-dir ./_bmad] [--output-dir ./.claude/agents]
//
// What it does:
//   1. Reads agent YAML source files from _bmad/[module]/agents/
//   2. Reads module-help.csv files for workflow-agent routing
//   3. Generates .claude/agents/bmad-*.md files with proper frontmatter
//   4. Removes _bmad agent directories to avoid overlap
//   5. Prints suggested CLAUDE.md snippet to stdout
//
// Requirements:
//   - Node.js (no extra dependencies)
//   - An installed _bmad/ directory (from npx bmad-method@alpha install)

const fs = require('node:fs');
const path = require('node:path');

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    bmadDir: './_bmad',
    outputDir: './.claude/agents',
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--bmad-dir' && args[i + 1]) {
      opts.bmadDir = args[++i];
    } else if (args[i] === '--output-dir' && args[i + 1]) {
      opts.outputDir = args[++i];
    } else if (args[i] === '--help' || args[i] === '-h') {
      console.log(`Usage: node generate-claude-agents.js [--bmad-dir PATH] [--output-dir PATH]`);
      console.log(`  --bmad-dir   Path to installed _bmad/ directory (default: ./_bmad)`);
      console.log(`  --output-dir Path to output .claude/agents/ directory (default: ./.claude/agents)`);
      process.exit(0);
    }
  }

  return opts;
}

// ---------------------------------------------------------------------------
// CSV parsing (lightweight, no dependencies)
// ---------------------------------------------------------------------------
function parseCsv(content) {
  const lines = content.split('\n').filter((l) => l.trim());
  if (lines.length === 0) return [];

  const headers = parseCSVLine(lines[0]);
  const rows = [];

  for (let i = 1; i < lines.length; i++) {
    const values = parseCSVLine(lines[i]);
    const row = {};
    for (let j = 0; j < headers.length; j++) {
      row[headers[j].trim()] = (values[j] || '').trim();
    }
    rows.push(row);
  }

  return rows;
}

/**
 * Parse a single CSV line handling quoted fields
 */
function parseCSVLine(line) {
  const fields = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      fields.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  fields.push(current);
  return fields;
}

// ---------------------------------------------------------------------------
// XML parsing helpers (regex-based, for small compiled agent files)
// ---------------------------------------------------------------------------
function extractXmlTag(xml, tag) {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)</${tag}>`, 'i');
  const m = xml.match(re);
  return m ? m[1].trim() : '';
}

function extractXmlAttr(xml, tag, attr) {
  const re = new RegExp(`<${tag}[^>]*\\s${attr}="([^"]*)"`, 'i');
  const m = xml.match(re);
  return m ? m[1] : '';
}

function extractAllXmlItems(xml, tag) {
  const items = [];
  const re = new RegExp(`<${tag}([^>]*)>([\\s\\S]*?)</${tag}>`, 'gi');
  let m;
  while ((m = re.exec(xml)) !== null) {
    items.push({ attrs: m[1], content: m[2].trim() });
  }
  return items;
}

// ---------------------------------------------------------------------------
// YAML parsing (minimal, for agent.yaml frontmatter + simple structures)
// ---------------------------------------------------------------------------
function parseSimpleYaml(content) {
  // Very lightweight: parse key: value pairs and simple lists
  // Used for agent YAML files which have known structure
  const result = {};
  const lines = content.split('\n');
  let currentKey = null;
  let currentIndent = 0;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const indent = line.length - line.trimStart().length;
    const kvMatch = trimmed.match(/^(\w[\w_-]*)\s*:\s*(.*)$/);

    if (kvMatch) {
      const key = kvMatch[1];
      let val = kvMatch[2].trim();
      // Remove surrounding quotes
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      result[key] = val || null;
      currentKey = key;
      currentIndent = indent;
    } else if (trimmed.startsWith('- ') && currentKey) {
      if (!Array.isArray(result[currentKey])) {
        result[currentKey] = result[currentKey] ? [result[currentKey]] : [];
      }
      let val = trimmed.slice(2).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      result[currentKey].push(val);
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Agent source file reader
// ---------------------------------------------------------------------------

/**
 * Parse a compiled agent .md file (contains XML in fenced code block)
 */
function parseCompiledAgent(content) {
  const agent = {
    name: '',
    personaName: '',
    title: '',
    icon: '',
    role: '',
    identity: '',
    communicationStyle: '',
    principles: '',
    criticalActions: [],
    menuItems: [],
    prompts: [],
    memories: [],
  };

  // Extract frontmatter
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (fmMatch) {
    const fm = parseSimpleYaml(fmMatch[1]);
    agent.name = fm.name || '';
    agent.personaName = fm.name || '';
    agent.title = fm.description || '';
  }

  // Extract the XML block (inside code fence)
  const xmlMatch = content.match(/```xml\s*\n([\s\S]*?)```/);
  if (!xmlMatch) {
    // Try without code fence - some agents might be plain XML
    return parseAgentXml(content, agent);
  }

  return parseAgentXml(xmlMatch[1], agent);
}

function parseAgentXml(xml, agent) {
  // Agent attributes
  agent.name = agent.name || extractXmlAttr(xml, 'agent', 'name');
  agent.personaName = agent.personaName || agent.name;
  agent.title = agent.title || extractXmlAttr(xml, 'agent', 'title');
  agent.icon = extractXmlAttr(xml, 'agent', 'icon');

  // Persona
  const persona = extractXmlTag(xml, 'persona');
  if (persona) {
    agent.role = extractXmlTag(persona, 'role');
    agent.identity = extractXmlTag(persona, 'identity');
    agent.communicationStyle = extractXmlTag(persona, 'communication_style');
    agent.principles = extractXmlTag(persona, 'principles');
  }

  // Critical actions from activation block
  const activation = extractXmlTag(xml, 'activation');
  if (activation) {
    const critItems = extractAllXmlItems(activation, 'critical_action');
    agent.criticalActions = critItems.map((i) => i.content);
    // Also try as list items
    if (agent.criticalActions.length === 0) {
      const critBlock = extractXmlTag(activation, 'critical_actions');
      if (critBlock) {
        const items = extractAllXmlItems(critBlock, 'action');
        agent.criticalActions = items.map((i) => i.content);
      }
    }
  }

  // Menu items
  const menu = extractXmlTag(xml, 'menu');
  if (menu) {
    const items = extractAllXmlItems(menu, 'item');
    agent.menuItems = items.map((item) => {
      const cmdMatch = item.attrs.match(/cmd="([^"]*)"/);
      const execMatch = item.attrs.match(/exec="([^"]*)"/);
      const workflowMatch = item.attrs.match(/workflow="([^"]*)"/);
      const actionMatch = item.attrs.match(/action="([^"]*)"/);
      const dataMatch = item.attrs.match(/data="([^"]*)"/);
      return {
        cmd: cmdMatch ? cmdMatch[1] : '',
        exec: execMatch ? execMatch[1] : '',
        workflow: workflowMatch ? workflowMatch[1] : '',
        action: actionMatch ? actionMatch[1] : '',
        data: dataMatch ? dataMatch[1] : '',
        description: item.content,
      };
    });
  }

  // Prompts
  const prompts = extractXmlTag(xml, 'prompts');
  if (prompts) {
    const promptItems = extractAllXmlItems(prompts, 'prompt');
    agent.prompts = promptItems.map((p) => {
      const idMatch = p.attrs.match(/id="([^"]*)"/);
      return {
        id: idMatch ? idMatch[1] : '',
        content: extractXmlTag(p.content, 'content') || p.content,
      };
    });
  }

  // Memories
  const memories = extractXmlTag(xml, 'memories');
  if (memories) {
    const memItems = extractAllXmlItems(memories, 'memory');
    agent.memories = memItems.map((m) => m.content);
  }

  return agent;
}

/**
 * Parse an agent YAML source file directly.
 * Handles: metadata fields, persona with block scalars and lists,
 * critical_actions list, menu items, prompts with block content, memories.
 */
function parseAgentYaml(content) {
  const agent = {
    name: '',
    personaName: '',
    title: '',
    icon: '',
    role: '',
    identity: '',
    communicationStyle: '',
    principles: '',
    criticalActions: [],
    menuItems: [],
    prompts: [],
    memories: [],
    hasSidecar: false,
    webskip: false,
  };

  const lines = content.split('\n');

  // Helper: collect a block scalar starting after a "key: |" line at lineIdx.
  // baseIndent is the indent of the key line. Block content has indent > baseIndent.
  function collectBlock(startIdx, baseIndent) {
    const collected = [];
    let j = startIdx;
    while (j < lines.length) {
      const l = lines[j];
      if (l.trim() === '') {
        collected.push('');
        j++;
        continue;
      }
      const ind = l.length - l.trimStart().length;
      if (ind > baseIndent) {
        collected.push(l.trim());
        j++;
      } else {
        break;
      }
    }
    // Trim trailing empty lines
    while (collected.length > 0 && collected[collected.length - 1] === '') collected.pop();
    return { text: collected.join('\n'), endIdx: j };
  }

  // Helper: collect a YAML list starting at startIdx, each item at "- " with indent > baseIndent
  function collectList(startIdx, baseIndent) {
    const items = [];
    let j = startIdx;
    while (j < lines.length) {
      const l = lines[j];
      const trimmed = l.trim();
      if (trimmed === '') { j++; continue; }
      const ind = l.length - l.trimStart().length;
      if (ind <= baseIndent) break;
      if (trimmed.startsWith('- ')) {
        let val = trimmed.slice(2).trim();
        val = stripQuotes(val);
        items.push(val);
        j++;
      } else {
        // Continuation of previous item or unknown
        if (items.length > 0) {
          items[items.length - 1] += ' ' + trimmed;
        }
        j++;
      }
    }
    return { items, endIdx: j };
  }

  let i = 0;
  let section = null;

  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();
    const indent = line.length - line.trimStart().length;

    // Skip comments and empty lines
    if (trimmed === '' || (trimmed.startsWith('#') && indent === 0)) { i++; continue; }

    // Top-level: "agent:" at indent 0
    if (indent === 0 && trimmed === 'agent:') { i++; continue; }

    // webskip at agent level (indent 2)
    if (indent === 2 && trimmed.startsWith('webskip:')) {
      agent.webskip = trimmed.includes('true');
      i++;
      continue;
    }

    // Section headers at indent 2
    if (indent === 2) {
      const sectionMatch = trimmed.match(/^(\w[\w_-]*)\s*:$/);
      if (sectionMatch) {
        section = sectionMatch[1];
        i++;
        continue;
      }
    }

    // METADATA section (indent 4)
    if (section === 'metadata' && indent === 4) {
      const kv = trimmed.match(/^(\w[\w_-]*)\s*:\s*(.+)$/);
      if (kv) {
        const key = kv[1];
        const val = stripQuotes(kv[2].trim());
        if (key === 'name') { agent.name = val; agent.personaName = val; }
        else if (key === 'title') agent.title = val;
        else if (key === 'icon') agent.icon = val;
        else if (key === 'hasSidecar') agent.hasSidecar = val === 'true';
      }
      i++;
      continue;
    }

    // PERSONA section (indent 4)
    if (section === 'persona' && indent === 4) {
      const kv = trimmed.match(/^(\w[\w_-]*)\s*:\s*(.*)$/);
      if (kv) {
        const key = kv[1];
        let val = kv[2].trim();

        if (val === '|') {
          // Block scalar
          const block = collectBlock(i + 1, indent);
          val = block.text;
          i = block.endIdx;
        } else if (val === '' || val === '>') {
          // Could be a list (principles:) or folded scalar
          if (key === 'principles') {
            // Check next lines for list items
            const list = collectList(i + 1, indent);
            if (list.items.length > 0) {
              val = list.items.map((item) => `- ${item}`).join('\n');
              i = list.endIdx;
            } else {
              i++;
              continue;
            }
          } else {
            const block = collectBlock(i + 1, indent);
            val = block.text;
            i = block.endIdx;
          }
        } else {
          val = stripQuotes(val);
          i++;
        }

        if (key === 'role') agent.role = val;
        else if (key === 'identity') agent.identity = val;
        else if (key === 'communication_style') agent.communicationStyle = val;
        else if (key === 'principles') agent.principles = val;
        continue;
      }
      // Could be a list item under principles
      if (trimmed.startsWith('- ') && agent.principles !== '') {
        agent.principles += '\n' + trimmed;
        i++;
        continue;
      }
    }

    // Handle principles as a list at indent 6 (under persona > principles:)
    if (section === 'persona' && indent === 6 && trimmed.startsWith('- ')) {
      const val = stripQuotes(trimmed.slice(2).trim());
      if (agent.principles) {
        agent.principles += '\n- ' + val;
      } else {
        agent.principles = '- ' + val;
      }
      i++;
      continue;
    }

    // CRITICAL_ACTIONS section
    if (section === 'critical_actions' && trimmed.startsWith('- ')) {
      let val = trimmed.slice(2).trim();
      val = stripQuotes(val);
      agent.criticalActions.push(val);
      i++;
      continue;
    }

    // MEMORIES section
    if (section === 'memories' && trimmed.startsWith('- ')) {
      let val = trimmed.slice(2).trim();
      val = stripQuotes(val);
      agent.memories.push(val);
      i++;
      continue;
    }

    // MENU section
    if (section === 'menu') {
      if (trimmed.startsWith('- trigger:') || trimmed.startsWith('- trigger :')) {
        const trigVal = trimmed.replace(/^- trigger\s*:\s*/, '').trim();
        const menuItem = {
          cmd: stripQuotes(trigVal),
          exec: '',
          workflow: '',
          action: '',
          data: '',
          description: '',
        };
        // Read subsequent fields for this menu item (indent > current item indent)
        const itemIndent = indent;
        let j = i + 1;
        while (j < lines.length) {
          const mLine = lines[j];
          const mTrimmed = mLine.trim();
          const mIndent = mLine.length - mLine.trimStart().length;
          if (mTrimmed === '') { j++; continue; }
          if (mIndent <= itemIndent) break;
          const mkv = mTrimmed.match(/^(\w[\w_-]*)\s*:\s*(.+)$/);
          if (mkv) {
            const mkey = mkv[1];
            let mval = stripQuotes(mkv[2].trim());
            if (mkey === 'exec') menuItem.exec = mval;
            else if (mkey === 'workflow') menuItem.workflow = mval;
            else if (mkey === 'action') menuItem.action = mval;
            else if (mkey === 'data') menuItem.data = mval;
            else if (mkey === 'description') menuItem.description = mval;
          }
          j++;
        }
        agent.menuItems.push(menuItem);
        i = j;
        continue;
      }
    }

    // PROMPTS section
    if (section === 'prompts') {
      if (trimmed.startsWith('- id:')) {
        const promptId = stripQuotes(trimmed.replace(/^- id\s*:\s*/, '').trim());
        const promptItem = { id: promptId, content: '' };
        const itemIndent = indent;
        let j = i + 1;
        while (j < lines.length) {
          const pLine = lines[j];
          const pTrimmed = pLine.trim();
          const pIndent = pLine.length - pLine.trimStart().length;
          if (pTrimmed === '') { j++; continue; }
          if (pIndent <= itemIndent) break;
          const pkv = pTrimmed.match(/^content\s*:\s*(.*)$/);
          if (pkv) {
            const pval = pkv[1].trim();
            if (pval === '|') {
              const block = collectBlock(j + 1, pIndent);
              promptItem.content = block.text;
              j = block.endIdx;
            } else {
              promptItem.content = stripQuotes(pval);
              j++;
            }
          } else {
            j++;
          }
        }
        agent.prompts.push(promptItem);
        i = j;
        continue;
      }
    }

    i++;
  }

  return agent;
}

function stripQuotes(s) {
  if (!s) return '';
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    return s.slice(1, -1);
  }
  return s;
}

// ---------------------------------------------------------------------------
// Agent discovery - find agents in _bmad/ directory
// ---------------------------------------------------------------------------
function discoverAgents(bmadDir) {
  const agents = [];

  // Walk _bmad/ looking for agents/ directories in each module
  const entries = fs.readdirSync(bmadDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith('_') || entry.name.startsWith('.')) continue;

    const moduleName = entry.name;
    const agentsDir = path.join(bmadDir, moduleName, 'agents');

    if (!fs.existsSync(agentsDir)) continue;

    // Find agent files - could be compiled .md or source .agent.yaml
    findAgentFiles(agentsDir, moduleName, agents, agentsDir);
  }

  return agents;
}

function findAgentFiles(dir, moduleName, agents, baseDir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      // Check for agent YAML inside directory (e.g., tech-writer/tech-writer.agent.yaml)
      const yamlInDir = path.join(fullPath, `${entry.name}.agent.yaml`);
      const mdInDir = path.join(fullPath, `${entry.name}.md`);

      if (fs.existsSync(yamlInDir)) {
        agents.push({
          name: entry.name,
          module: moduleName,
          path: yamlInDir,
          type: 'yaml',
          dir: fullPath,
        });
      } else if (fs.existsSync(mdInDir)) {
        agents.push({
          name: entry.name,
          module: moduleName,
          path: mdInDir,
          type: 'compiled',
          dir: fullPath,
        });
      } else {
        // Recurse
        findAgentFiles(fullPath, moduleName, agents, baseDir);
      }
    } else if (entry.name.endsWith('.agent.yaml')) {
      const agentName = entry.name.replace('.agent.yaml', '');
      agents.push({
        name: agentName,
        module: moduleName,
        path: fullPath,
        type: 'yaml',
        dir: dir,
      });
    } else if (entry.name.endsWith('.md') && !entry.name.startsWith('README')) {
      // Could be a compiled agent - check if it contains <agent tag
      const content = fs.readFileSync(fullPath, 'utf8');
      if (content.includes('<agent ')) {
        const agentName = entry.name.replace('.md', '');
        agents.push({
          name: agentName,
          module: moduleName,
          path: fullPath,
          type: 'compiled',
          dir: dir,
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Read module-help.csv files
// ---------------------------------------------------------------------------
function readModuleHelp(bmadDir) {
  const allHelp = [];
  const entries = fs.readdirSync(bmadDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith('_') || entry.name.startsWith('.')) continue;

    const helpPath = path.join(bmadDir, entry.name, 'module-help.csv');
    if (fs.existsSync(helpPath)) {
      const content = fs.readFileSync(helpPath, 'utf8');
      const rows = parseCsv(content);
      allHelp.push(...rows);
    }
  }

  // Also check _config for merged manifests
  const workflowManifest = path.join(bmadDir, '_config', 'workflow-manifest.csv');
  if (allHelp.length === 0 && fs.existsSync(workflowManifest)) {
    const content = fs.readFileSync(workflowManifest, 'utf8');
    allHelp.push(...parseCsv(content));
  }

  return allHelp;
}

// ---------------------------------------------------------------------------
// Tool assignments per agent
// ---------------------------------------------------------------------------
const TOOL_MAP = {
  analyst: ['Read', 'Grep', 'Glob', 'Bash', 'WebSearch', 'WebFetch', 'Write', 'Edit'],
  architect: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  dev: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  pm: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  sm: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'ux-designer': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'quick-flow-solo-dev': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  quinn: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'tech-writer': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'bmad-master': ['Read', 'Grep', 'Glob'],
};

// Description map: when Claude should delegate to each agent
const DESCRIPTION_MAP = {
  analyst:
    'Business analysis, market research, competitive analysis, requirements elicitation, product briefs, and project documentation. Delegate when the user needs research, analysis, brainstorming, or wants to create a product brief.',
  architect:
    'Technical architecture design, system design, technology selection, and implementation readiness checks. Delegate when the user needs to design system architecture or validate technical decisions.',
  dev: 'Story implementation, code writing, test-driven development, and code review. Delegate when the user needs to implement a user story, write code following a spec, or perform code review.',
  pm: 'Product requirements documents (PRDs), epics and stories creation, product strategy, and implementation readiness. Delegate when the user needs to create or validate PRDs, define epics/stories, or check implementation readiness.',
  sm: 'Sprint planning, story preparation, sprint status, course correction, and retrospectives. Delegate when the user needs agile ceremony facilitation, sprint management, or story creation.',
  'ux-designer':
    'UX design, wireframes, user research, interaction design, and visual diagrams (Excalidraw). Delegate when the user needs UX artifacts, wireframes, flowcharts, or data flow diagrams.',
  'quick-flow-solo-dev':
    'Quick technical specs and rapid implementation for simple tasks, small changes, or utilities without extensive planning. Delegate when the user wants a fast spec-to-code workflow without full BMAD ceremony.',
  quinn:
    'QA test automation - generating API and E2E tests for implemented code. Delegate when the user needs automated test generation using standard test framework patterns.',
  'tech-writer':
    'Technical documentation, writing documents, mermaid diagrams, documentation validation, and concept explanations. Delegate when the user needs documentation authored or reviewed.',
  'bmad-master':
    'BMAD workflow orchestration, listing available tasks and workflows, and guiding users through the BMAD method. Delegate when the user asks for BMAD help, wants to see available workflows, or needs guidance on what to do next.',
};

// Agent display info for CLAUDE.md snippet
const AGENT_INFO = {
  analyst: { displayName: 'Mary', summary: 'Business analysis, research, product briefs' },
  architect: { displayName: 'Winston', summary: 'Technical architecture design' },
  dev: { displayName: 'Amelia', summary: 'Story implementation with TDD' },
  pm: { displayName: 'John', summary: 'PRD creation/validation, epics & stories' },
  sm: { displayName: 'Bob', summary: 'Sprint planning, story creation, retrospectives' },
  'ux-designer': { displayName: 'Sally', summary: 'UX design, wireframes, diagrams' },
  'quick-flow-solo-dev': { displayName: 'Barry', summary: 'Quick spec + dev for simple tasks' },
  quinn: { displayName: 'Quinn', summary: 'Test automation' },
  'tech-writer': { displayName: 'Paige', summary: 'Documentation' },
  'bmad-master': { displayName: 'BMad Master', summary: 'Workflow routing and help' },
};

// Map from agent name → output filename (without .md)
const FILENAME_MAP = {
  analyst: 'bmad-analyst',
  architect: 'bmad-architect',
  dev: 'bmad-dev',
  pm: 'bmad-pm',
  sm: 'bmad-sm',
  'ux-designer': 'bmad-ux-designer',
  'quick-flow-solo-dev': 'bmad-quick-flow',
  quinn: 'bmad-qa',
  'tech-writer': 'bmad-tech-writer',
  'bmad-master': 'bmad-master',
};

// ---------------------------------------------------------------------------
// Build workflow commands table from module-help.csv and agent menu items
// ---------------------------------------------------------------------------
function buildWorkflowTable(agentName, agentData, helpRows) {
  const commands = [];

  // From agent menu items
  for (const item of agentData.menuItems) {
    // Skip system menu items (MH, CH, DA, PM)
    if (['MH or fuzzy match on menu or help', 'CH or fuzzy match on chat', 'DA or fuzzy match on exit, leave, goodbye or dismiss agent', 'PM or fuzzy match on party-mode'].includes(item.cmd)) {
      continue;
    }

    const trigger = extractTriggerCode(item.cmd);
    const workflowPath = normalizeWorkflowPath(item.exec || item.workflow);
    const description = cleanDescription(item.description || item.action);

    if (trigger && (workflowPath || item.action)) {
      commands.push({
        trigger,
        fuzzyMatch: extractFuzzyMatch(item.cmd),
        workflowPath: workflowPath || '(inline action)',
        description,
        action: item.action || '',
      });
    }
  }

  // Enrich with help rows if commands are sparse
  if (commands.length === 0 && helpRows.length > 0) {
    const agentRows = helpRows.filter((r) => r.agent === agentName);
    for (const row of agentRows) {
      commands.push({
        trigger: row.code || '',
        fuzzyMatch: row.name || '',
        workflowPath: normalizeWorkflowPath(row['workflow-file'] || ''),
        description: row.description || '',
        action: '',
      });
    }
  }

  return commands;
}

function extractTriggerCode(cmd) {
  if (!cmd) return '';
  // Extract the short code before " or "
  const parts = cmd.split(' or ');
  return parts[0].trim();
}

function extractFuzzyMatch(cmd) {
  if (!cmd) return '';
  const match = cmd.match(/fuzzy match on\s+(.+)/i);
  return match ? match[1].trim() : '';
}

function normalizeWorkflowPath(p) {
  if (!p) return '';
  // Replace {project-root}/_bmad/ with _bmad/
  return p
    .replace(/\{project-root\}\/?/g, '')
    .replace(/^_bmad\//, '_bmad/')
    .trim();
}

function cleanDescription(desc) {
  if (!desc) return '';
  // Remove [CODE] prefix if present
  return desc.replace(/^\[[\w-]+\]\s*/, '').trim();
}

// ---------------------------------------------------------------------------
// Determine which handler types an agent uses based on its menu items
// ---------------------------------------------------------------------------
function getUsedHandlerTypes(agentData) {
  const types = new Set();
  for (const item of agentData.menuItems) {
    if (item.workflow) types.add('workflow');
    if (item.exec) types.add('exec');
    if (item.action) types.add('action');
    if (item.data) types.add('data');
    // tmpl and validate-workflow are rarer, include if present
  }
  return types;
}

// ---------------------------------------------------------------------------
// Generate Claude Code agent markdown
// ---------------------------------------------------------------------------
function generateAgentMarkdown(agentName, agentData, commands, allAgents, moduleName) {
  const outputName = FILENAME_MAP[agentName] || `bmad-${agentName}`;
  const tools = TOOL_MAP[agentName] || ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'];
  const description = DESCRIPTION_MAP[agentName] || `BMAD ${agentData.title || agentName} agent`;
  const modName = moduleName || 'bmm';

  let md = '';

  // Resolve persona name: prefer parsed personaName from agentData, fall back to AGENT_INFO displayName
  const personaName = agentData.personaName || (AGENT_INFO[agentName] && AGENT_INFO[agentName].displayName) || '';

  // YAML frontmatter
  md += '---\n';
  md += `name: ${outputName}\n`;
  const descWithName = personaName ? `${personaName} - ${description}` : description;
  md += `description: "${escapeYamlString(descWithName)}"\n`;
  md += `tools:\n`;
  for (const tool of tools) {
    md += `  - ${tool}\n`;
  }
  md += '---\n\n';

  // Title
  const displayName = personaName || agentData.name || agentName;
  md += `# ${displayName} - ${agentData.title || 'BMAD Agent'} ${agentData.icon || ''}\n\n`;

  // Character instruction
  md += 'You must fully embody this agent\'s persona and follow all activation instructions, steps and rules exactly as specified. NEVER break character until given an exit command.\n\n';

  // =========================================================================
  // ACTIVATION (mirrors the compiled agent's <activation critical="MANDATORY">)
  // =========================================================================
  md += '## Activation (MANDATORY)\n\n';
  md += 'Follow these steps in order when this agent is activated:\n\n';

  let stepNum = 1;

  // Step 1: Persona already loaded
  md += `**Step ${stepNum}.** Load persona from this agent file (already in context).\n\n`;
  stepNum++;

  // Step 2: Load config
  md += `**Step ${stepNum}.** IMMEDIATE ACTION REQUIRED - BEFORE ANY OUTPUT:\n`;
  md += `- Read \`_bmad/${modName}/config.yaml\` NOW\n`;
  md += '- Store ALL fields as session variables: `{user_name}`, `{communication_language}`, `{output_folder}`\n';
  md += '- VERIFY: If config not loaded, STOP and report error to user\n';
  md += `- DO NOT PROCEED to step ${stepNum + 1} until config is successfully loaded and variables stored\n\n`;
  stepNum++;

  // Step 3: Remember user name
  md += `**Step ${stepNum}.** Remember: user's name is \`{user_name}\`.\n\n`;
  stepNum++;

  // Agent-specific critical actions as activation steps
  if (agentData.criticalActions && agentData.criticalActions.length > 0) {
    for (const action of agentData.criticalActions) {
      md += `**Step ${stepNum}.** ${action}\n\n`;
      stepNum++;
    }
  }

  // Show greeting and menu
  md += `**Step ${stepNum}.** Show greeting using \`{user_name}\` from config, communicate in \`{communication_language}\`, then display numbered list of ALL menu items from the Available Commands section below.\n\n`;
  stepNum++;

  // Mention bmad-help
  md += `**Step ${stepNum}.** Let \`{user_name}\` know they can type command \`/bmad-help\` at any time to get advice on what to do next, and that they can combine it with what they need help with (example: \`/bmad-help where should I start with an idea I have that does XYZ\`).\n\n`;
  stepNum++;

  // STOP and wait
  md += `**Step ${stepNum}.** STOP and WAIT for user input - do NOT execute menu items automatically - accept number or cmd trigger or fuzzy command match.\n\n`;
  stepNum++;

  // Input handling
  md += `**Step ${stepNum}.** On user input: Number → process menu item[n] | Text → case-insensitive substring match | Multiple matches → ask user to clarify | No match → show "Not recognized".\n\n`;
  stepNum++;

  // Execute menu item
  md += `**Step ${stepNum}.** When processing a menu item: Check the Menu Command Handlers section below - extract any attributes from the selected menu item (workflow, exec, data, action) and follow the corresponding handler instructions.\n\n`;

  // =========================================================================
  // PERSONA
  // =========================================================================
  md += '## Persona\n\n';
  if (agentData.role) md += `**Role:** ${agentData.role}\n\n`;
  if (agentData.identity) md += `**Identity:** ${agentData.identity}\n\n`;
  if (agentData.communicationStyle) md += `**Communication Style:** ${agentData.communicationStyle}\n\n`;

  // Principles
  if (agentData.principles) {
    md += '## Principles\n\n';
    const principlesText = agentData.principles.trim();
    if (principlesText.startsWith('-') || principlesText.startsWith('*')) {
      md += principlesText + '\n\n';
    } else {
      md += principlesText + '\n\n';
    }
  }

  // =========================================================================
  // PROMPTS (welcome and others)
  // =========================================================================
  if (agentData.prompts && agentData.prompts.length > 0) {
    const welcome = agentData.prompts.find((p) => p.id === 'welcome');
    if (welcome) {
      md += '## Welcome Message\n\n';
      md += 'When first activated, greet the user with:\n\n';
      md += welcome.content.trim() + '\n\n';
    }
    // Non-welcome prompts as reference for action handler
    const otherPrompts = agentData.prompts.filter((p) => p.id !== 'welcome');
    if (otherPrompts.length > 0) {
      md += '## Agent Prompts\n\n';
      md += 'These prompts are referenced by action commands (action="#id"):\n\n';
      for (const p of otherPrompts) {
        md += `### Prompt: ${p.id}\n\n`;
        md += p.content.trim() + '\n\n';
      }
    }
  }

  // =========================================================================
  // MEMORIES
  // =========================================================================
  if (agentData.memories && agentData.memories.length > 0) {
    md += '## Agent Memories\n\n';
    for (const mem of agentData.memories) {
      md += `- ${mem}\n`;
    }
    md += '\n';
  }

  // =========================================================================
  // AVAILABLE COMMANDS (MENU) - includes system items
  // =========================================================================
  md += '## Available Commands\n\n';
  md += 'Display these as a numbered list when greeting the user. Accept number, command code, or fuzzy text match.\n\n';

  // System items first
  md += '| # | Command | Trigger | Target | Description |\n';
  md += '|---|---------|---------|--------|-------------|\n';

  let menuNum = 1;

  // MH - always present
  md += `| ${menuNum} | MH | \`MH\` or "menu" or "help" | (system) | Redisplay Menu Help |\n`;
  menuNum++;

  // CH - always present
  md += `| ${menuNum} | CH | \`CH\` or "chat" | (system) | Chat with the Agent about anything |\n`;
  menuNum++;

  // Agent-specific commands
  for (const cmd of commands) {
    const trigger = cmd.fuzzyMatch ? `\`${cmd.trigger}\` or "${cmd.fuzzyMatch}"` : `\`${cmd.trigger}\``;
    let target;
    if (cmd.workflowPath && cmd.workflowPath.includes('_bmad/')) {
      target = `\`${cmd.workflowPath}\``;
    } else if (cmd.action) {
      target = '(action)';
    } else {
      target = `\`${cmd.workflowPath || '(inline)'}\``;
    }
    md += `| ${menuNum} | ${cmd.trigger} | ${trigger} | ${target} | ${cmd.description} |\n`;
    menuNum++;
  }

  // PM - party mode, always present
  md += `| ${menuNum} | PM | \`PM\` or "party-mode" | \`_bmad/core/workflows/party-mode/workflow.md\` | Start Party Mode |\n`;
  menuNum++;

  // DA - dismiss agent, always present
  md += `| ${menuNum} | DA | \`DA\` or "exit" or "leave" or "goodbye" or "dismiss agent" | (system) | Dismiss Agent |\n`;
  md += '\n';

  // Inline actions (for tech-writer style agents with action-based commands)
  const inlineActions = commands.filter((c) => c.action);
  if (inlineActions.length > 0) {
    md += '### Inline Action Details\n\n';
    md += 'When a command has an action instead of a file path, follow these instructions directly:\n\n';
    for (const cmd of inlineActions) {
      md += `**${cmd.trigger}:** ${cmd.action}\n\n`;
    }
  }

  // =========================================================================
  // MENU COMMAND HANDLERS (mirrors <menu-handlers> from compiled agents)
  // =========================================================================
  md += '## Menu Command Handlers\n\n';
  md += 'When executing a menu item, check which attributes it has and follow the matching handler:\n\n';

  const usedTypes = getUsedHandlerTypes(agentData);

  // Workflow handler
  if (usedTypes.has('workflow')) {
    md += '### Handler: workflow\n\n';
    md += 'When menu item has `workflow="path/to/workflow.yaml"`:\n\n';
    md += '1. **CRITICAL:** Always read `_bmad/core/tasks/workflow.xml` first\n';
    md += '2. Read the complete file - this is the CORE OS for processing BMAD workflows\n';
    md += '3. Pass the yaml path as the `workflow-config` parameter to those instructions\n';
    md += '4. Follow workflow.xml instructions precisely following all steps\n';
    md += '5. Save outputs after completing EACH workflow step (never batch multiple steps together)\n';
    md += '6. If workflow.yaml path is "todo", inform user the workflow has not been implemented yet\n\n';
  }

  // Exec handler
  if (usedTypes.has('exec')) {
    md += '### Handler: exec\n\n';
    md += 'When menu item has `exec="path/to/file.md"`:\n\n';
    md += '1. Read the entire file at that path and execute its instructions - do not improvise\n';
    md += '2. Read the complete file and follow all instructions within it\n';
    md += '3. If there is `data="some/path/data-foo.md"` with the same item, pass that data path to the executed file as context\n\n';
  }

  // Action handler
  if (usedTypes.has('action')) {
    md += '### Handler: action\n\n';
    md += 'When menu item has `action`:\n\n';
    md += '- If `action="#id"`: Find the prompt with that id in the Agent Prompts section above, follow its content\n';
    md += '- If `action="text"`: Follow the text directly as an inline instruction\n\n';
  }

  // Data handler
  if (usedTypes.has('data')) {
    md += '### Handler: data\n\n';
    md += 'When menu item has `data="path/to/file"`:\n\n';
    md += '1. Load the file first, parse according to extension (json/yaml/csv/xml)\n';
    md += '2. Make available as `{data}` variable to subsequent handler operations\n\n';
  }

  // Always include these even if not detected (they may be used by system items)
  if (!usedTypes.has('workflow') && !usedTypes.has('exec')) {
    md += '### Handler: workflow\n\n';
    md += 'When menu item has `workflow="path/to/workflow.yaml"`:\n\n';
    md += '1. **CRITICAL:** Always read `_bmad/core/tasks/workflow.xml` first\n';
    md += '2. Read the complete file - this is the CORE OS for processing BMAD workflows\n';
    md += '3. Pass the yaml path as the `workflow-config` parameter to those instructions\n';
    md += '4. Follow workflow.xml instructions precisely following all steps\n';
    md += '5. Save outputs after completing EACH workflow step (never batch multiple steps together)\n\n';

    md += '### Handler: exec\n\n';
    md += 'When menu item has `exec="path/to/file.md"`:\n\n';
    md += '1. Read the entire file at that path and execute its instructions - do not improvise\n';
    md += '2. Read the complete file and follow all instructions within it\n\n';
  }

  // =========================================================================
  // RULES (mirrors <rules> from compiled agents)
  // =========================================================================
  md += '## Rules\n\n';
  md += '- ALWAYS communicate in `{communication_language}` UNLESS contradicted by communication_style.\n';
  md += '- Stay in character until exit is selected.\n';
  md += '- Display Menu items as the item dictates and in the order given.\n';
  md += '- Load files ONLY when executing a user-chosen workflow or a command requires it. EXCEPTION: agent activation step 2 config.yaml.\n';
  md += '\n';

  // =========================================================================
  // BMAD MASTER: agent routing summary
  // =========================================================================
  if (agentName === 'bmad-master' && allAgents) {
    md += '## Available BMAD Agents\n\n';
    md += 'You can help route users to the right agent. Here are all available agents:\n\n';
    for (const [name, info] of Object.entries(AGENT_INFO)) {
      if (name === 'bmad-master') continue;
      const fname = FILENAME_MAP[name] || `bmad-${name}`;
      md += `- **${fname}** (${info.displayName}): ${info.summary}\n`;
    }
    md += '\n';
    md += '### BMAD Method Workflow Sequence\n\n';
    md += '1. **Analysis** (bmad-analyst): Brainstorm → Research → Product Brief\n';
    md += '2. **Planning** (bmad-pm, bmad-ux-designer): PRD → UX Design\n';
    md += '3. **Solutioning** (bmad-architect, bmad-pm): Architecture → Epics & Stories → Readiness Check\n';
    md += '4. **Implementation** (bmad-sm, bmad-dev, bmad-qa): Sprint Planning → Story Creation → Development → Code Review → QA → Retrospective\n';
    md += '\nFor quick tasks, route to **bmad-quick-flow** (Barry) instead of the full workflow.\n\n';
  }

  // =========================================================================
  // PROJECT CONTEXT
  // =========================================================================
  md += '## Project Context\n\n';
  md += '- Read `_bmad/_config/config.yaml` for user preferences (name, language, skill level)\n';
  md += `- Read \`_bmad/${modName}/config.yaml\` for project-specific paths (planning_artifacts, implementation_artifacts)\n`;
  md += '- Check for `project-context.md` in the project for coding standards and patterns\n';

  return md;
}

function escapeYamlString(s) {
  return s.replace(/"/g, '\\"');
}

// ---------------------------------------------------------------------------
// Rewrite .claude/commands/ agent launchers to point to native agents
// ---------------------------------------------------------------------------

// Build a mapping from _bmad agent paths to native agent names.
// Handles both dash-format filenames and hierarchical paths in .claude/commands/.
function buildAgentPathMap(processedAgents) {
  const map = {};
  for (const agent of processedAgents) {
    const nativeName = FILENAME_MAP[agent.name] || `bmad-${agent.name}`;
    // Map various path patterns that could appear in command files
    // Pattern 1: _bmad/{module}/agents/{name}.md (compiled agent path)
    map[`_bmad/${agent.module}/agents/${agent.name}.md`] = nativeName;
    // Pattern 2: @_bmad/{module}/agents/{name}.md (with @ prefix)
    map[`@_bmad/${agent.module}/agents/${agent.name}.md`] = nativeName;
    // For tech-writer nested path
    if (agent.name === 'tech-writer') {
      map[`_bmad/${agent.module}/agents/tech-writer/tech-writer.md`] = nativeName;
      map[`@_bmad/${agent.module}/agents/tech-writer/tech-writer.md`] = nativeName;
    }
  }
  return map;
}

// Scan .claude/commands/ for agent launcher files that reference
// _bmad agents and rewrite them to delegate to native agents.
function rewriteAgentCommands(projectDir, processedAgents) {
  const commandsDir = path.join(projectDir, '.claude', 'commands');
  if (!fs.existsSync(commandsDir)) return [];

  const pathMap = buildAgentPathMap(processedAgents);
  const rewritten = [];

  // Recursively scan for .md files in commands dir
  rewriteCommandsInDir(commandsDir, pathMap, rewritten);

  return rewritten;
}

function rewriteCommandsInDir(dir, pathMap, rewritten) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      rewriteCommandsInDir(fullPath, pathMap, rewritten);
      continue;
    }

    if (!entry.name.endsWith('.md')) continue;

    const content = fs.readFileSync(fullPath, 'utf8');

    // Check if this is an agent launcher (references _bmad/*/agents/)
    if (!content.includes('/agents/')) continue;

    // Determine which native agent this maps to
    let nativeAgent = null;
    for (const [agentPath, nativeName] of Object.entries(pathMap)) {
      if (content.includes(agentPath)) {
        nativeAgent = nativeName;
        break;
      }
    }

    if (!nativeAgent) continue;

    // Extract existing frontmatter
    const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
    let name = entry.name.replace('.md', '');
    let description = '';

    if (fmMatch) {
      const nameMatch = fmMatch[1].match(/name:\s*['"]?([^'"\n]+)/);
      const descMatch = fmMatch[1].match(/description:\s*['"]?([^'"\n]+)/);
      if (nameMatch) name = nameMatch[1].trim();
      if (descMatch) description = descMatch[1].trim();
    }

    // Rewrite the file to delegate to the native agent
    const newContent = `---
name: '${name}'
description: '${description}'
---

This command delegates to the **${nativeAgent}** native Claude Code agent.

<agent-activation CRITICAL="TRUE">
1. Activate the **${nativeAgent}** agent (located at .claude/agents/${nativeAgent}.md)
2. The native agent contains the full persona, menu, and workflow instructions
3. Follow all instructions from the native agent exactly
4. Stay in character throughout the session
</agent-activation>
`;

    fs.writeFileSync(fullPath, newContent, 'utf8');
    rewritten.push({ file: path.relative(path.join(dir, '..', '..'), fullPath), agent: nativeAgent });
  }
}

// ---------------------------------------------------------------------------
// Remove old agent directories
// ---------------------------------------------------------------------------
function removeAgentDirectories(bmadDir) {
  const removed = [];
  const entries = fs.readdirSync(bmadDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith('_') || entry.name.startsWith('.')) continue;

    const agentsDir = path.join(bmadDir, entry.name, 'agents');
    if (fs.existsSync(agentsDir)) {
      fs.rmSync(agentsDir, { recursive: true, force: true });
      removed.push(`${entry.name}/agents/`);
    }
  }

  return removed;
}

// ---------------------------------------------------------------------------
// Generate CLAUDE.md snippet
// ---------------------------------------------------------------------------
function generateClaudeMdSnippet(processedAgents) {
  let snippet = '\n## BMAD Method Agents\n\n';
  snippet += 'This project uses the BMAD Method for AI-driven agile development.\n';
  snippet += 'Available agents (invoke by name or let Claude auto-delegate):\n\n';

  for (const [name, info] of Object.entries(AGENT_INFO)) {
    const fname = FILENAME_MAP[name] || `bmad-${name}`;
    if (name === 'bmad-master') {
      snippet += `- **${fname}**: ${info.summary}\n`;
    } else {
      snippet += `- **${fname}** (${info.displayName}): ${info.summary}\n`;
    }
  }

  snippet += '\nWorkflow: Analysis → Planning → Solutioning → Implementation\n';

  return snippet;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
function main() {
  const opts = parseArgs();
  const bmadDir = path.resolve(opts.bmadDir);
  const outputDir = path.resolve(opts.outputDir);

  // Validate _bmad/ exists
  if (!fs.existsSync(bmadDir)) {
    console.error(`Error: _bmad directory not found at ${bmadDir}`);
    console.error('Run `npx bmad-method@alpha install` first to create the _bmad/ directory.');
    process.exit(1);
  }

  console.log(`Reading agents from: ${bmadDir}`);
  console.log(`Output directory: ${outputDir}`);

  // Step 1: Discover agents
  const agents = discoverAgents(bmadDir);
  if (agents.length === 0) {
    console.error('No agents found in _bmad/ directory.');
    process.exit(1);
  }

  console.log(`Found ${agents.length} agent(s):`);
  for (const a of agents) {
    console.log(`  - ${a.name} (${a.module}, ${a.type})`);
  }

  // Step 2: Read module-help.csv for workflow routing
  const helpRows = readModuleHelp(bmadDir);
  console.log(`Read ${helpRows.length} workflow help entries.`);

  // Step 3: Parse each agent and generate output
  const processedAgents = [];

  for (const agentFile of agents) {
    const content = fs.readFileSync(agentFile.path, 'utf8');
    let agentData;

    if (agentFile.type === 'yaml') {
      agentData = parseAgentYaml(content);
    } else {
      agentData = parseCompiledAgent(content);
    }

    // Use metadata from parsed data, fall back to filename
    if (!agentData.name) agentData.name = agentFile.name;

    // Build workflow commands
    const commands = buildWorkflowTable(agentFile.name, agentData, helpRows);

    processedAgents.push({
      name: agentFile.name,
      module: agentFile.module,
      data: agentData,
      commands,
    });
  }

  // Step 4: Ensure output directory exists, preserve non-bmad files
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`Created output directory: ${outputDir}`);
  }

  // Step 5: Write agent files
  let written = 0;
  for (const agent of processedAgents) {
    const filename = FILENAME_MAP[agent.name] || `bmad-${agent.name}`;
    const outputPath = path.join(outputDir, `${filename}.md`);
    const markdown = generateAgentMarkdown(agent.name, agent.data, agent.commands, processedAgents, agent.module);

    fs.writeFileSync(outputPath, markdown, 'utf8');
    console.log(`  Generated: ${filename}.md`);
    written++;
  }

  console.log(`\nGenerated ${written} Claude Code agent file(s) in ${outputDir}`);

  // Step 6: Rewrite .claude/commands/ agent launchers to delegate to native agents
  const projectDir = path.dirname(path.dirname(outputDir)); // .claude/agents → project root
  const rewrittenCommands = rewriteAgentCommands(projectDir, processedAgents);
  if (rewrittenCommands.length > 0) {
    console.log(`\nRewrote ${rewrittenCommands.length} agent command(s) in .claude/commands/:`);
    for (const r of rewrittenCommands) {
      console.log(`  - ${r.file} → ${r.agent}`);
    }
  }

  // Step 7: Remove old agent directories from _bmad/
  const removed = removeAgentDirectories(bmadDir);
  if (removed.length > 0) {
    console.log(`\nRemoved old agent directories from _bmad/:`);
    for (const r of removed) {
      console.log(`  - _bmad/${r}`);
    }
  }

  // Step 8: Print CLAUDE.md snippet
  const snippet = generateClaudeMdSnippet(processedAgents);
  console.log('\n' + '='.repeat(60));
  console.log('Suggested CLAUDE.md addition:');
  console.log('='.repeat(60));
  console.log(snippet);

  console.log('\nDone! Verify agents with: ls -la .claude/agents/bmad-*.md');
}

main();

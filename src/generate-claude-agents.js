#!/usr/bin/env node

// BMAD 6.x Skills-Based -> Native Agent Generator
//
// Reads installed BMad agent skills from the skills directory and generates
// native agent files for Claude Code (.claude/agents/) and/or Pi (.pi/agents/).
//
// Each BMad agent skill (identified by bmad-skill-manifest.yaml with type: agent)
// becomes a native agent file with platform-specific YAML frontmatter and the
// SKILL.md body content passed through unmodified.
//
// Usage:
//   node src/generate-claude-agents.js [options]
//
// Options:
//   --skills-dir PATH    Skills directory to scan (default: auto-detect from --target)
//   --target TARGET      claude | pi | both (default: claude)
//   --project-root PATH  Project root (default: cwd)
//   --dry-run            Print what would be generated without writing
//   --help, -h           Show usage
//
// Requirements:
//   - Node.js (no extra dependencies)
//   - BMad 6.x installed with agent skills in the skills directory

const fs = require('node:fs');
const path = require('node:path');

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    skillsDir: null,
    target: 'claude',
    projectRoot: process.cwd(),
    dryRun: false,
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--skills-dir') {
      if (!args[i + 1] || args[i + 1].startsWith('--')) {
        console.error('Error: --skills-dir requires a value.');
        process.exit(1);
      }
      opts.skillsDir = args[++i];
    } else if (args[i] === '--target') {
      if (!args[i + 1] || args[i + 1].startsWith('--')) {
        console.error('Error: --target requires a value.');
        process.exit(1);
      }
      opts.target = args[++i];
    } else if (args[i] === '--project-root') {
      if (!args[i + 1] || args[i + 1].startsWith('--')) {
        console.error('Error: --project-root requires a value.');
        process.exit(1);
      }
      opts.projectRoot = args[++i];
    } else if (args[i] === '--dry-run') {
      opts.dryRun = true;
    } else if (args[i] === '--help' || args[i] === '-h') {
      console.log('Usage: node src/generate-claude-agents.js [options]');
      console.log('');
      console.log('Options:');
      console.log('  --skills-dir PATH    Skills directory to scan (default: auto-detect from --target)');
      console.log('  --target TARGET      claude | pi | both (default: claude)');
      console.log('  --project-root PATH  Project root (default: cwd)');
      console.log('  --dry-run            Print what would be generated without writing');
      console.log('  --help, -h           Show usage');
      process.exit(0);
    } else {
      console.warn(`Warning: Unknown argument "${args[i]}" ignored.`);
    }
  }

  if (!['claude', 'pi', 'both'].includes(opts.target)) {
    console.error(`Error: Invalid --target "${opts.target}". Must be claude, pi, or both.`);
    process.exit(1);
  }

  return opts;
}

// ---------------------------------------------------------------------------
// YAML parsing (minimal, for bmad-skill-manifest.yaml flat key-value pairs)
// ---------------------------------------------------------------------------
function parseSimpleYaml(content) {
  const result = {};
  const lines = content.split('\n');
  let currentKey = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const kvMatch = trimmed.match(/^(\w[\w_-]*)\s*:\s*(.*)$/);

    if (kvMatch) {
      const key = kvMatch[1];
      let val = kvMatch[2].trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      result[key] = val || null;
      currentKey = key;
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
// SKILL.md parser -- extract frontmatter and body
// ---------------------------------------------------------------------------
function parseSkillMd(content) {
  const result = { frontmatter: {}, body: '' };

  if (!content.startsWith('---')) {
    result.body = content;
    return result;
  }

  const secondDash = content.indexOf('---', 3);
  if (secondDash === -1) {
    result.body = content;
    return result;
  }

  const fmContent = content.slice(3, secondDash).trim();
  result.frontmatter = parseSimpleYaml(fmContent);
  result.body = content.slice(secondDash + 3).replace(/^\n+/, '');

  return result;
}

// ---------------------------------------------------------------------------
// Short name derivation from manifest name
// ---------------------------------------------------------------------------
function getShortName(manifestName) {
  if (manifestName.startsWith('bmad-agent-')) return manifestName.slice('bmad-agent-'.length);
  if (manifestName.startsWith('bmad-')) return manifestName.slice('bmad-'.length);
  return manifestName;
}

// ---------------------------------------------------------------------------
// Agent name → output filename mapping
// ---------------------------------------------------------------------------
const FILENAME_MAP = {
  analyst: 'bmad-analyst',
  architect: 'bmad-architect',
  dev: 'bmad-dev',
  pm: 'bmad-pm',
  qa: 'bmad-qa',
  sm: 'bmad-sm',
  'ux-designer': 'bmad-ux-designer',
  'quick-flow-solo-dev': 'bmad-quick-flow',
  'tech-writer': 'bmad-tech-writer',
  tea: 'bmad-tea',
};

// ---------------------------------------------------------------------------
// Description map: when the host tool should delegate to each agent
// ---------------------------------------------------------------------------
const DESCRIPTION_MAP = {
  analyst:
    'Business analysis, market research, competitive analysis, requirements elicitation, product briefs, and project documentation. Delegate when the user needs research, analysis, brainstorming, or wants to create a product brief.',
  architect:
    'Technical architecture design, system design, technology selection, and implementation readiness checks. Delegate when the user needs to design system architecture or validate technical decisions.',
  dev: 'Story implementation, code writing, test-driven development, and code review. Delegate when the user needs to implement a user story, write code following a spec, or perform code review.',
  pm: 'Product requirements documents (PRDs), epics and stories creation, product strategy, and implementation readiness. Delegate when the user needs to create or validate PRDs, define epics/stories, or check implementation readiness.',
  sm: 'Sprint planning, story preparation, sprint status, course correction, and retrospectives. Delegate when the user needs agile ceremony facilitation, sprint management, or story creation.',
  'ux-designer':
    'UX design, wireframes, user research, interaction design, and visual diagrams. Delegate when the user needs UX artifacts, wireframes, flowcharts, or data flow diagrams.',
  'quick-flow-solo-dev':
    'Quick technical specs and rapid implementation for simple tasks, small changes, or utilities without extensive planning. Delegate when the user wants a fast spec-to-code workflow without full BMAD ceremony.',
  qa: 'QA test automation - generating API and E2E tests for implemented code. Delegate when the user needs automated test generation using standard test framework patterns.',
  'tech-writer':
    'Technical documentation, writing documents, mermaid diagrams, documentation validation, and concept explanations. Delegate when the user needs documentation authored or reviewed.',
  tea: 'Master Test Architect - risk-based testing, fixture architecture, ATDD, CI/CD governance, and scalable quality gates. Delegate when the user needs test strategy, test design, NFR assessment, or traceability analysis.',
};

// ---------------------------------------------------------------------------
// Agent display info for suggested CLAUDE.md / PI.md snippet
// ---------------------------------------------------------------------------
const AGENT_INFO = {
  analyst: { displayName: 'Mary', summary: 'Business analysis, research, product briefs' },
  architect: { displayName: 'Winston', summary: 'Technical architecture design' },
  dev: { displayName: 'Amelia', summary: 'Story implementation with TDD' },
  pm: { displayName: 'John', summary: 'PRD creation/validation, epics & stories' },
  sm: { displayName: 'Bob', summary: 'Sprint planning, story creation, retrospectives' },
  'ux-designer': { displayName: 'Sally', summary: 'UX design, wireframes, diagrams' },
  'quick-flow-solo-dev': { displayName: 'Barry', summary: 'Quick spec + dev for simple tasks' },
  qa: { displayName: 'Quinn', summary: 'Test automation' },
  'tech-writer': { displayName: 'Paige', summary: 'Documentation' },
  tea: { displayName: 'Murat', summary: 'Test architecture, ATDD, CI/CD quality gates' },
};

// ---------------------------------------------------------------------------
// Platform-specific tool maps
// ---------------------------------------------------------------------------
const CLAUDE_TOOL_MAP = {
  analyst: ['Read', 'Grep', 'Glob', 'Bash', 'WebSearch', 'WebFetch', 'Write', 'Edit'],
  architect: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  dev: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  pm: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit', 'WebSearch'],
  sm: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'ux-designer': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'quick-flow-solo-dev': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  qa: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  'tech-writer': ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
  tea: ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'],
};

const PI_TOOL_MAP = {
  analyst: 'read,write,edit,bash,grep,find,ls',
  architect: 'read,write,edit,bash,grep,find,ls',
  dev: 'read,write,edit,bash,grep,find,ls',
  pm: 'read,write,edit,bash,grep,find,ls',
  sm: 'read,write,edit,bash,grep,find,ls',
  'ux-designer': 'read,write,edit,bash,grep,find,ls',
  'quick-flow-solo-dev': 'read,write,edit,bash,grep,find,ls',
  qa: 'read,write,edit,bash,grep,find,ls',
  'tech-writer': 'read,write,edit,bash,grep,find,ls',
  tea: 'read,write,edit,bash,grep,find,ls',
};

// ---------------------------------------------------------------------------
// Agent skill discovery -- scan skills dir for bmad-skill-manifest.yaml
// ---------------------------------------------------------------------------
function discoverAgentSkills(skillsDir) {
  const agents = [];

  if (!fs.existsSync(skillsDir)) return agents;

  const entries = fs.readdirSync(skillsDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const manifestPath = path.join(skillsDir, entry.name, 'bmad-skill-manifest.yaml');
    if (!fs.existsSync(manifestPath)) continue;

    const manifestContent = fs.readFileSync(manifestPath, 'utf8');
    const manifest = parseSimpleYaml(manifestContent);

    if (manifest.type !== 'agent') continue;

    const skillMdPath = path.join(skillsDir, entry.name, 'SKILL.md');
    if (!fs.existsSync(skillMdPath)) {
      console.warn(`  Warning: ${entry.name} has agent manifest but no SKILL.md -- skipping`);
      continue;
    }

    agents.push({
      dirName: entry.name,
      manifestPath,
      skillMdPath,
      manifest,
    });
  }

  return agents;
}

// ---------------------------------------------------------------------------
// Generate a native agent file for a given platform
// ---------------------------------------------------------------------------
function generateAgentFile(agent, platform) {
  const manifest = agent.manifest;
  const name = manifest.name || agent.dirName;
  const shortName = getShortName(name);

  const outputName = FILENAME_MAP[shortName] || `bmad-${shortName}`;
  const displayName = manifest.displayName || '';
  const skillMdContent = fs.readFileSync(agent.skillMdPath, 'utf8');
  const parsed = parseSkillMd(skillMdContent);
  const description = parsed.frontmatter.description || manifest.title || `BMAD ${shortName} agent`;
  const descWithName = displayName ? `${displayName} - ${description}` : description;

  let frontmatter = '---\n';
  frontmatter += `name: ${outputName}\n`;
  frontmatter += `description: "${escapeYamlString(descWithName)}"\n`;

  if (platform === 'claude') {
    const tools = CLAUDE_TOOL_MAP[shortName] || ['Read', 'Grep', 'Glob', 'Bash', 'Write', 'Edit'];
    frontmatter += 'tools:\n';
    for (const tool of tools) {
      frontmatter += `  - ${tool}\n`;
    }
  } else {
    const tools = PI_TOOL_MAP[shortName] || 'read,write,edit,bash,grep,find,ls';
    frontmatter += `tools: ${tools}\n`;
  }

  frontmatter += '---\n\n';

  return {
    outputName,
    content: frontmatter + parsed.body,
  };
}

function escapeYamlString(s) {
  return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

// ---------------------------------------------------------------------------
// Inject disable-model-invocation into SKILL.md frontmatter for Pi target
// ---------------------------------------------------------------------------
function injectDisableModelInvocation(skillsDir, dryRun) {
  if (!fs.existsSync(skillsDir)) return 0;

  const entries = fs.readdirSync(skillsDir, { withFileTypes: true });
  let count = 0;

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const skillMdPath = path.join(skillsDir, entry.name, 'SKILL.md');
    if (!fs.existsSync(skillMdPath)) continue;

    const content = fs.readFileSync(skillMdPath, 'utf8');

    // Skip if already has the flag
    if (content.includes('disable-model-invocation:')) {
      console.log(`  Skipped (already has flag): ${entry.name}/SKILL.md`);
      continue;
    }

    // Must have frontmatter to inject into
    if (!content.startsWith('---')) {
      console.warn(`  Warning: ${entry.name}/SKILL.md has no frontmatter -- skipping injection`);
      continue;
    }

    const closingDash = content.indexOf('---', 3);
    if (closingDash === -1) {
      console.warn(`  Warning: ${entry.name}/SKILL.md has malformed frontmatter -- skipping injection`);
      continue;
    }

    // Insert disable-model-invocation: true before the closing ---
    const beforeClose = content.slice(0, closingDash);
    const afterClose = content.slice(closingDash);
    const injection = beforeClose.endsWith('\n')
      ? 'disable-model-invocation: true\n'
      : '\ndisable-model-invocation: true\n';
    const newContent = beforeClose + injection + afterClose;

    if (dryRun) {
      console.log(`  [dry-run] Would inject disable-model-invocation into: ${entry.name}/SKILL.md`);
    } else {
      fs.writeFileSync(skillMdPath, newContent, 'utf8');
      console.log(`  Injected disable-model-invocation: ${entry.name}/SKILL.md`);
    }
    count++;
  }

  return count;
}

// ---------------------------------------------------------------------------
// Remove agent skill source directories after native agents are generated
// ---------------------------------------------------------------------------
function cleanupAgentSkills(agents, skillsDir) {
  const removed = [];
  for (const agent of agents) {
    const agentSkillDir = path.join(skillsDir, agent.dirName);
    if (fs.existsSync(agentSkillDir)) {
      fs.rmSync(agentSkillDir, { recursive: true, force: true });
      removed.push(agent.dirName);
      console.log(`  Cleaned up agent skill source: ${agent.dirName}`);
    }
  }
  return removed;
}

// ---------------------------------------------------------------------------
// Generate suggested snippet for CLAUDE.md or PI equivalent
// ---------------------------------------------------------------------------
function generateSnippet(processedAgents, platform) {
  const platformLabel = platform === 'claude' ? 'Claude Code' : 'Pi';
  let snippet = `\n## BMAD Method Agents (${platformLabel})\n\n`;
  snippet += 'This project uses the BMAD Method for AI-driven agile development.\n';
  snippet += 'Available agents (invoke by name or let the host tool auto-delegate):\n\n';

  for (const agent of processedAgents) {
    const shortName = getShortName(agent.manifest.name || agent.dirName);
    const info = AGENT_INFO[shortName];
    const outputName = FILENAME_MAP[shortName] || `bmad-${shortName}`;
    if (info) {
      snippet += `- **${outputName}** (${info.displayName}): ${info.summary}\n`;
    } else {
      snippet += `- **${outputName}**: ${agent.manifest.title || shortName}\n`;
    }
  }

  snippet += '\nWorkflow: Analysis -> Planning -> Solutioning -> Implementation\n';

  return snippet;
}

// ---------------------------------------------------------------------------
// Resolve skills directory for a platform
// ---------------------------------------------------------------------------
function resolveSkillsDir(projectRoot, platform, explicitDir) {
  if (explicitDir) return path.resolve(explicitDir);
  if (platform === 'claude') return path.join(projectRoot, '.claude', 'skills');
  return path.join(projectRoot, '.pi', 'skills');
}

// ---------------------------------------------------------------------------
// Resolve output directory for a platform
// ---------------------------------------------------------------------------
function resolveOutputDir(projectRoot, platform) {
  if (platform === 'claude') return path.join(projectRoot, '.claude', 'agents');
  return path.join(projectRoot, '.pi', 'agents');
}

// ---------------------------------------------------------------------------
// Process a single platform target
// ---------------------------------------------------------------------------
function processTarget(platform, projectRoot, explicitSkillsDir, dryRun) {
  const skillsDir = resolveSkillsDir(projectRoot, platform, explicitSkillsDir);
  const outputDir = resolveOutputDir(projectRoot, platform);

  console.log(`\n--- Target: ${platform} ---`);
  console.log(`  Skills dir: ${skillsDir}`);
  console.log(`  Output dir: ${outputDir}`);

  if (!fs.existsSync(skillsDir)) {
    console.warn(`  Warning: Skills directory not found at ${skillsDir} -- skipping ${platform} target`);
    return { agents: [], written: 0, skipped: true };
  }

  const agents = discoverAgentSkills(skillsDir);
  if (agents.length === 0) {
    console.error(`  Error: No agent-type skills found in ${skillsDir}`);
    return { agents: [], written: 0, error: true };
  }

  console.log(`  Found ${agents.length} agent skill(s):`);
  for (const a of agents) {
    const name = a.manifest.name || a.dirName;
    console.log(`    - ${name} (${a.manifest.displayName || 'unknown'})`);
  }

  let written = 0;

  if (!dryRun) {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log(`  Created output directory: ${outputDir}`);
    }
  }

  for (const agent of agents) {
    const result = generateAgentFile(agent, platform);

    if (dryRun) {
      console.log(`  [dry-run] Would generate: ${result.outputName}.md`);
    } else {
      const outputPath = path.join(outputDir, `${result.outputName}.md`);
      fs.writeFileSync(outputPath, result.content, 'utf8');
      console.log(`  Generated: ${result.outputName}.md`);
    }
    written++;
  }

  if (written > 0) {
    if (dryRun) {
      for (const agent of agents) {
        console.log(`  [dry-run] Would remove agent skill source: ${agent.dirName}`);
      }
    } else {
      cleanupAgentSkills(agents, skillsDir);
    }
  }

  // For Pi target: inject disable-model-invocation into all remaining skill SKILL.md files
  // so Pi won't load full skill bodies and workflow prompts into the system prompt
  if (platform === 'pi' && written > 0) {
    console.log('\n  Injecting disable-model-invocation into remaining skill frontmatters...');
    const injected = injectDisableModelInvocation(skillsDir, dryRun);
    if (injected > 0) {
      console.log(`  ${dryRun ? 'Would inject' : 'Injected'} disable-model-invocation into ${injected} skill(s).`);
    } else {
      console.log('  No skills needed injection (all already flagged or no remaining skills).');
    }
  }

  return { agents, written, skipped: false, error: false };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
function main() {
  const opts = parseArgs();
  const projectRoot = path.resolve(opts.projectRoot);

  console.log(`Project root: ${projectRoot}`);

  if (opts.target === 'both' && opts.skillsDir) {
    console.warn('Warning: --skills-dir is ignored when --target is "both" (each platform uses its own skills directory).');
  }

  const targets = opts.target === 'both' ? ['claude', 'pi'] : [opts.target];
  let totalAgents = 0;
  let anyError = false;
  let allSkipped = true;
  const allProcessed = [];

  for (const target of targets) {
    const explicitDir = opts.target === 'both' ? null : opts.skillsDir;
    const result = processTarget(target, projectRoot, explicitDir, opts.dryRun);

    if (result.error) anyError = true;
    if (!result.skipped) allSkipped = false;
    totalAgents += result.written;
    allProcessed.push({ target, ...result });
  }

  if (allSkipped) {
    console.error('\nError: No skills directories found for any target.');
    process.exit(1);
  }

  if (anyError && totalAgents === 0) {
    console.error('\nError: No agent-type skills found in any scanned directory.');
    process.exit(1);
  }

  // Print snippet
  for (const processed of allProcessed) {
    if (processed.agents.length > 0) {
      const snippet = generateSnippet(processed.agents, processed.target);
      const configFile = processed.target === 'claude' ? 'CLAUDE.md' : 'PI.md';
      console.log('\n' + '='.repeat(60));
      console.log(`Suggested ${configFile} addition:`);
      console.log('='.repeat(60));
      console.log(snippet);
    }
  }

  const verb = opts.dryRun ? 'Would generate' : 'Generated';
  console.log(`\n${verb} ${totalAgents} native agent file(s) total.`);
  if (!opts.dryRun) {
    console.log('Done! Verify agents with:');
    for (const target of targets) {
      const dir = target === 'claude' ? '.claude/agents' : '.pi/agents';
      console.log(`  ls -la ${dir}/bmad-*.md`);
    }
  }
}

// ---------------------------------------------------------------------------
// Exports for testing
// ---------------------------------------------------------------------------
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    parseSimpleYaml,
    parseSkillMd,
    getShortName,
    discoverAgentSkills,
    cleanupAgentSkills,
    injectDisableModelInvocation,
    generateAgentFile,
    generateSnippet,
    escapeYamlString,
    resolveSkillsDir,
    resolveOutputDir,
    FILENAME_MAP,
    DESCRIPTION_MAP,
    AGENT_INFO,
    CLAUDE_TOOL_MAP,
    PI_TOOL_MAP,
  };
}

// Run main only when executed directly
if (require.main === module) {
  main();
}

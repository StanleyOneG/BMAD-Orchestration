#!/usr/bin/env node

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const {
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
} = require('./generate-claude-agents.js');

// ---------------------------------------------------------------------------
// Test fixtures — each suite uses an isolated subdirectory
// ---------------------------------------------------------------------------
const FIXTURES_BASE = path.join(__dirname, '__test_fixtures__');

function setupFixtures(suiteId) {
  const fixtureRoot = path.join(FIXTURES_BASE, suiteId);
  const skillsDir = path.join(fixtureRoot, '.claude', 'skills');

  // Agent skill: bmad-agent-pm
  const pmDir = path.join(skillsDir, 'bmad-agent-pm');
  fs.mkdirSync(pmDir, { recursive: true });
  fs.writeFileSync(
    path.join(pmDir, 'bmad-skill-manifest.yaml'),
    `type: agent
name: bmad-agent-pm
displayName: John
title: Product Manager
icon: "📋"
capabilities: "PRD creation, requirements discovery"
module: bmm
`,
  );
  fs.writeFileSync(
    path.join(pmDir, 'SKILL.md'),
    `---
name: bmad-agent-pm
description: Product manager for PRD creation and requirements discovery.
---

# John

## Overview

This skill provides a Product Manager.

## Identity

Product management veteran.

## Capabilities

| Code | Description | Skill |
|------|-------------|-------|
| CP | Create PRD | bmad-create-prd |
`,
  );

  // Agent skill: bmad-tea
  const teaDir = path.join(skillsDir, 'bmad-tea');
  fs.mkdirSync(teaDir, { recursive: true });
  fs.writeFileSync(
    path.join(teaDir, 'bmad-skill-manifest.yaml'),
    `type: agent
name: bmad-tea
displayName: Murat
title: Master Test Architect
icon: "🧪"
module: tea
`,
  );
  fs.writeFileSync(
    path.join(teaDir, 'SKILL.md'),
    `---
name: bmad-tea
description: Master Test Architect and Quality Advisor.
---

# Murat

## Overview

Test architecture specialist.
`,
  );

  // Non-agent skill (should be skipped)
  const workflowDir = path.join(skillsDir, 'bmad-create-prd');
  fs.mkdirSync(workflowDir, { recursive: true });
  fs.writeFileSync(
    path.join(workflowDir, 'bmad-skill-manifest.yaml'),
    `type: workflow
name: bmad-create-prd
title: Create PRD
`,
  );

  // Skill directory with no manifest (should be skipped)
  const noManifestDir = path.join(skillsDir, 'bmad-some-tool');
  fs.mkdirSync(noManifestDir, { recursive: true });
  fs.writeFileSync(path.join(noManifestDir, 'SKILL.md'), '# Some tool\n');

  return { fixtureRoot, skillsDir };
}

function cleanupFixtures(suiteId) {
  fs.rmSync(path.join(FIXTURES_BASE, suiteId), { recursive: true, force: true });
}

// ---------------------------------------------------------------------------
// parseSimpleYaml
// ---------------------------------------------------------------------------
describe('parseSimpleYaml', () => {
  it('parses flat key-value pairs', () => {
    const result = parseSimpleYaml('type: agent\nname: bmad-agent-pm\ntitle: Product Manager');
    assert.equal(result.type, 'agent');
    assert.equal(result.name, 'bmad-agent-pm');
    assert.equal(result.title, 'Product Manager');
  });

  it('strips surrounding quotes', () => {
    const result = parseSimpleYaml('icon: "📋"\nlabel: \'hello\'');
    assert.equal(result.icon, '📋');
    assert.equal(result.label, 'hello');
  });

  it('handles empty values as null', () => {
    const result = parseSimpleYaml('key:');
    assert.equal(result.key, null);
  });

  it('skips comments and empty lines', () => {
    const result = parseSimpleYaml('# comment\n\nname: test\n# another comment');
    assert.equal(result.name, 'test');
    assert.equal(Object.keys(result).length, 1);
  });

  it('parses YAML list items', () => {
    const result = parseSimpleYaml('tools:\n  - Read\n  - Write\n  - Edit');
    assert.deepEqual(result.tools, ['Read', 'Write', 'Edit']);
  });
});

// ---------------------------------------------------------------------------
// parseSkillMd
// ---------------------------------------------------------------------------
describe('parseSkillMd', () => {
  it('extracts frontmatter and body', () => {
    const content = '---\nname: test\ndescription: A test skill.\n---\n\n# Title\n\nBody content here.';
    const result = parseSkillMd(content);
    assert.equal(result.frontmatter.name, 'test');
    assert.equal(result.frontmatter.description, 'A test skill.');
    assert.ok(result.body.startsWith('# Title'));
    assert.ok(result.body.includes('Body content here.'));
  });

  it('handles content with no frontmatter', () => {
    const content = '# Just a doc\n\nNo frontmatter here.';
    const result = parseSkillMd(content);
    assert.deepEqual(result.frontmatter, {});
    assert.equal(result.body, content);
  });

  it('handles content with malformed frontmatter (no closing ---)', () => {
    const content = '---\nname: broken\nStill going';
    const result = parseSkillMd(content);
    assert.deepEqual(result.frontmatter, {});
    assert.equal(result.body, content);
  });

  it('strips leading newlines from body', () => {
    const content = '---\nname: test\n---\n\n\n\n# Title';
    const result = parseSkillMd(content);
    assert.ok(result.body.startsWith('# Title'));
  });
});

// ---------------------------------------------------------------------------
// getShortName
// ---------------------------------------------------------------------------
describe('getShortName', () => {
  it('strips bmad-agent- prefix', () => {
    assert.equal(getShortName('bmad-agent-pm'), 'pm');
    assert.equal(getShortName('bmad-agent-quick-flow-solo-dev'), 'quick-flow-solo-dev');
    assert.equal(getShortName('bmad-agent-analyst'), 'analyst');
  });

  it('strips bmad- prefix for non-agent skills', () => {
    assert.equal(getShortName('bmad-tea'), 'tea');
  });

  it('returns name as-is if no bmad prefix', () => {
    assert.equal(getShortName('custom-agent'), 'custom-agent');
  });
});

// ---------------------------------------------------------------------------
// FILENAME_MAP completeness
// ---------------------------------------------------------------------------
describe('FILENAME_MAP', () => {
  it('maps all known agents to output filenames', () => {
    const expected = {
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
    assert.deepEqual(FILENAME_MAP, expected);
  });
});

// ---------------------------------------------------------------------------
// DESCRIPTION_MAP completeness
// ---------------------------------------------------------------------------
describe('DESCRIPTION_MAP', () => {
  it('has entries for all agents in FILENAME_MAP', () => {
    for (const key of Object.keys(FILENAME_MAP)) {
      assert.ok(DESCRIPTION_MAP[key], `DESCRIPTION_MAP missing key: ${key}`);
      assert.equal(typeof DESCRIPTION_MAP[key], 'string', `DESCRIPTION_MAP[${key}] should be a string`);
    }
  });
});

// ---------------------------------------------------------------------------
// AGENT_INFO completeness
// ---------------------------------------------------------------------------
describe('AGENT_INFO', () => {
  it('has entries for all agents in FILENAME_MAP', () => {
    for (const key of Object.keys(FILENAME_MAP)) {
      assert.ok(AGENT_INFO[key], `AGENT_INFO missing key: ${key}`);
      assert.ok(AGENT_INFO[key].displayName, `AGENT_INFO[${key}] missing displayName`);
      assert.ok(AGENT_INFO[key].summary, `AGENT_INFO[${key}] missing summary`);
    }
  });
});

// ---------------------------------------------------------------------------
// Tool maps
// ---------------------------------------------------------------------------
describe('Tool maps', () => {
  it('CLAUDE_TOOL_MAP has entries for all agents in FILENAME_MAP', () => {
    for (const key of Object.keys(FILENAME_MAP)) {
      assert.ok(CLAUDE_TOOL_MAP[key], `CLAUDE_TOOL_MAP missing key: ${key}`);
      assert.ok(Array.isArray(CLAUDE_TOOL_MAP[key]), `CLAUDE_TOOL_MAP[${key}] should be an array`);
    }
  });

  it('PI_TOOL_MAP has entries for all agents in FILENAME_MAP', () => {
    for (const key of Object.keys(FILENAME_MAP)) {
      assert.ok(PI_TOOL_MAP[key], `PI_TOOL_MAP missing key: ${key}`);
      assert.equal(typeof PI_TOOL_MAP[key], 'string', `PI_TOOL_MAP[${key}] should be a string`);
    }
  });

  it('Claude analyst has WebSearch and WebFetch', () => {
    assert.ok(CLAUDE_TOOL_MAP.analyst.includes('WebSearch'));
    assert.ok(CLAUDE_TOOL_MAP.analyst.includes('WebFetch'));
  });

  it('Pi tools never include WebSearch or WebFetch', () => {
    for (const [key, tools] of Object.entries(PI_TOOL_MAP)) {
      assert.ok(!tools.includes('WebSearch'), `PI_TOOL_MAP[${key}] should not have WebSearch`);
      assert.ok(!tools.includes('WebFetch'), `PI_TOOL_MAP[${key}] should not have WebFetch`);
    }
  });

  it('Pi tools include find instead of Glob', () => {
    for (const [key, tools] of Object.entries(PI_TOOL_MAP)) {
      assert.ok(tools.includes('find'), `PI_TOOL_MAP[${key}] should include find`);
      assert.ok(!tools.includes('Glob'), `PI_TOOL_MAP[${key}] should not have Glob`);
    }
  });

  it('Pi tools include ls', () => {
    for (const tools of Object.values(PI_TOOL_MAP)) {
      assert.ok(tools.includes('ls'), 'Pi tools should include ls');
    }
  });
});

// ---------------------------------------------------------------------------
// escapeYamlString
// ---------------------------------------------------------------------------
describe('escapeYamlString', () => {
  it('escapes double quotes', () => {
    assert.equal(escapeYamlString('She said "hello"'), 'She said \\"hello\\"');
  });

  it('passes through strings without quotes', () => {
    assert.equal(escapeYamlString('no quotes here'), 'no quotes here');
  });

  it('escapes backslashes before quotes', () => {
    assert.equal(escapeYamlString('path\\to\\"file"'), 'path\\\\to\\\\\\"file\\"');
  });

  it('handles backslash-only input', () => {
    assert.equal(escapeYamlString('foo\\bar'), 'foo\\\\bar');
  });
});

// ---------------------------------------------------------------------------
// resolveSkillsDir / resolveOutputDir
// ---------------------------------------------------------------------------
describe('resolveSkillsDir', () => {
  it('returns explicit dir when provided', () => {
    const result = resolveSkillsDir('/project', 'claude', '/custom/skills');
    assert.equal(result, '/custom/skills');
  });

  it('auto-detects claude skills dir', () => {
    const result = resolveSkillsDir('/project', 'claude', null);
    assert.equal(result, '/project/.claude/skills');
  });

  it('auto-detects pi skills dir', () => {
    const result = resolveSkillsDir('/project', 'pi', null);
    assert.equal(result, '/project/.pi/skills');
  });
});

describe('resolveOutputDir', () => {
  it('returns claude agents dir', () => {
    assert.equal(resolveOutputDir('/project', 'claude'), '/project/.claude/agents');
  });

  it('returns pi agents dir', () => {
    assert.equal(resolveOutputDir('/project', 'pi'), '/project/.pi/agents');
  });
});

// ---------------------------------------------------------------------------
// discoverAgentSkills (integration with fixture filesystem)
// ---------------------------------------------------------------------------
describe('discoverAgentSkills', () => {
  let skillsDir;

  before(() => {
    ({ skillsDir } = setupFixtures('discover'));
  });

  after(() => {
    cleanupFixtures('discover');
  });

  it('discovers only agent-type skills', () => {
    const agents = discoverAgentSkills(skillsDir);
    assert.equal(agents.length, 2);
    const names = agents.map((a) => a.manifest.name);
    assert.ok(names.includes('bmad-agent-pm'));
    assert.ok(names.includes('bmad-tea'));
  });

  it('skips workflow-type skills', () => {
    const agents = discoverAgentSkills(skillsDir);
    const names = agents.map((a) => a.manifest.name);
    assert.ok(!names.includes('bmad-create-prd'));
  });

  it('skips directories without manifest', () => {
    const agents = discoverAgentSkills(skillsDir);
    const dirs = agents.map((a) => a.dirName);
    assert.ok(!dirs.includes('bmad-some-tool'));
  });

  it('returns empty array for non-existent directory', () => {
    const agents = discoverAgentSkills('/nonexistent/path');
    assert.deepEqual(agents, []);
  });
});

// ---------------------------------------------------------------------------
// generateAgentFile
// ---------------------------------------------------------------------------
describe('generateAgentFile', () => {
  let agents;

  before(() => {
    const { skillsDir } = setupFixtures('generate');
    agents = discoverAgentSkills(skillsDir);
  });

  after(() => {
    cleanupFixtures('generate');
  });

  it('generates Claude format with YAML list tools', () => {
    const pmAgent = agents.find((a) => a.manifest.name === 'bmad-agent-pm');
    const result = generateAgentFile(pmAgent, 'claude');

    assert.equal(result.outputName, 'bmad-pm');
    assert.ok(result.content.startsWith('---\n'));
    assert.ok(result.content.includes('name: bmad-pm'));
    assert.ok(result.content.includes('description: "John - Product manager'));
    assert.ok(result.content.includes('tools:\n'));
    assert.ok(result.content.includes('  - Read\n'));
    assert.ok(result.content.includes('  - WebSearch\n'));
    // Body should be unmodified SKILL.md content
    assert.ok(result.content.includes('# John'));
    assert.ok(result.content.includes('## Overview'));
    assert.ok(result.content.includes('| CP | Create PRD | bmad-create-prd |'));
  });

  it('generates Pi format with comma-separated tools string', () => {
    const pmAgent = agents.find((a) => a.manifest.name === 'bmad-agent-pm');
    const result = generateAgentFile(pmAgent, 'pi');

    assert.equal(result.outputName, 'bmad-pm');
    assert.ok(result.content.includes('tools: read,write,edit,bash,grep,find,ls'));
    assert.ok(!result.content.includes('WebSearch'));
    assert.ok(!result.content.includes('WebFetch'));
    // Body still present
    assert.ok(result.content.includes('# John'));
  });

  it('handles bmad-tea (non bmad-agent- prefix) correctly', () => {
    const teaAgent = agents.find((a) => a.manifest.name === 'bmad-tea');
    const result = generateAgentFile(teaAgent, 'claude');

    assert.equal(result.outputName, 'bmad-tea');
    assert.ok(result.content.includes('name: bmad-tea'));
    assert.ok(result.content.includes('Murat - Master Test Architect'));
  });

  it('does not inject old-style menu command handlers', () => {
    const pmAgent = agents.find((a) => a.manifest.name === 'bmad-agent-pm');
    const result = generateAgentFile(pmAgent, 'claude');

    assert.ok(!result.content.includes('Menu Command Handlers'));
    assert.ok(!result.content.includes('Handler: workflow'));
    assert.ok(!result.content.includes('Handler: exec'));
    assert.ok(!result.content.includes('Handler: action'));
  });
});

// ---------------------------------------------------------------------------
// generateSnippet
// ---------------------------------------------------------------------------
describe('generateSnippet', () => {
  let agents;

  before(() => {
    const { skillsDir } = setupFixtures('snippet');
    agents = discoverAgentSkills(skillsDir);
  });

  after(() => {
    cleanupFixtures('snippet');
  });

  it('generates Claude Code snippet', () => {
    const snippet = generateSnippet(agents, 'claude');
    assert.ok(snippet.includes('BMAD Method Agents (Claude Code)'));
    assert.ok(snippet.includes('bmad-pm'));
    assert.ok(snippet.includes('John'));
  });

  it('generates Pi snippet', () => {
    const snippet = generateSnippet(agents, 'pi');
    assert.ok(snippet.includes('BMAD Method Agents (Pi)'));
  });
});

// ---------------------------------------------------------------------------
// cleanupAgentSkills
// ---------------------------------------------------------------------------
describe('cleanupAgentSkills', () => {
  let skillsDir;

  before(() => {
    ({ skillsDir } = setupFixtures('cleanup'));
  });

  after(() => {
    cleanupFixtures('cleanup');
  });

  it('removes agent skill directories and preserves non-agent skills', () => {
    const agents = discoverAgentSkills(skillsDir);
    assert.equal(agents.length, 2);

    // Non-agent dirs should exist before cleanup
    assert.ok(fs.existsSync(path.join(skillsDir, 'bmad-create-prd')));
    assert.ok(fs.existsSync(path.join(skillsDir, 'bmad-some-tool')));

    const removed = cleanupAgentSkills(agents, skillsDir);

    assert.equal(removed.length, 2);
    assert.ok(removed.includes('bmad-agent-pm'));
    assert.ok(removed.includes('bmad-tea'));

    // Agent dirs should be gone
    assert.ok(!fs.existsSync(path.join(skillsDir, 'bmad-agent-pm')));
    assert.ok(!fs.existsSync(path.join(skillsDir, 'bmad-tea')));

    // Non-agent dirs should still exist
    assert.ok(fs.existsSync(path.join(skillsDir, 'bmad-create-prd')));
    assert.ok(fs.existsSync(path.join(skillsDir, 'bmad-some-tool')));
  });

  it('returns empty array when agent dirs already removed', () => {
    // agents list references dirs that were already cleaned above
    const fakeAgents = [{ dirName: 'bmad-agent-pm' }, { dirName: 'bmad-tea' }];
    const removed = cleanupAgentSkills(fakeAgents, skillsDir);
    assert.deepEqual(removed, []);
  });
});

// ---------------------------------------------------------------------------
// injectDisableModelInvocation
// ---------------------------------------------------------------------------
describe('injectDisableModelInvocation', () => {
  const suiteId = 'inject-dmi';

  after(() => {
    cleanupFixtures(suiteId);
  });

  it('injects flag into SKILL.md frontmatter', () => {
    const fixtureRoot = path.join(FIXTURES_BASE, suiteId);
    const skillsDir = path.join(fixtureRoot, '.pi', 'skills');

    // Create a skill with standard frontmatter
    const skillDir = path.join(skillsDir, 'bmad-create-prd');
    fs.mkdirSync(skillDir, { recursive: true });
    fs.writeFileSync(
      path.join(skillDir, 'SKILL.md'),
      '---\nname: bmad-create-prd\ndescription: \'Create a PRD.\'\n---\n\n# Body content\n',
    );

    const count = injectDisableModelInvocation(skillsDir, false);
    assert.equal(count, 1);

    const content = fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf8');
    assert.ok(content.includes('disable-model-invocation: true'));
    // Flag should be inside frontmatter (before closing ---)
    const fmEnd = content.indexOf('---', 3);
    const flagPos = content.indexOf('disable-model-invocation: true');
    assert.ok(flagPos < fmEnd, 'Flag should be inside frontmatter');
    // Body should be preserved
    assert.ok(content.includes('# Body content'));
  });

  it('skips files that already have the flag', () => {
    const fixtureRoot = path.join(FIXTURES_BASE, suiteId);
    const skillsDir = path.join(fixtureRoot, '.pi', 'skills');

    // Overwrite with content that already has the flag
    const skillDir = path.join(skillsDir, 'bmad-create-prd');
    fs.writeFileSync(
      path.join(skillDir, 'SKILL.md'),
      '---\nname: bmad-create-prd\ndescription: \'Create a PRD.\'\ndisable-model-invocation: true\n---\n\n# Body\n',
    );

    const count = injectDisableModelInvocation(skillsDir, false);
    assert.equal(count, 0);
  });

  it('skips files without frontmatter', () => {
    const fixtureRoot = path.join(FIXTURES_BASE, suiteId);
    const skillsDir = path.join(fixtureRoot, '.pi', 'skills');

    const noFmDir = path.join(skillsDir, 'bmad-no-fm');
    fs.mkdirSync(noFmDir, { recursive: true });
    fs.writeFileSync(path.join(noFmDir, 'SKILL.md'), '# Just a doc\nNo frontmatter here.\n');

    const count = injectDisableModelInvocation(skillsDir, false);
    assert.equal(count, 0);
  });

  it('dry-run does not modify files', () => {
    const fixtureRoot = path.join(FIXTURES_BASE, suiteId);
    const skillsDir = path.join(fixtureRoot, '.pi', 'skills');

    // Create a fresh skill without the flag
    const dryDir = path.join(skillsDir, 'bmad-dry-test');
    fs.mkdirSync(dryDir, { recursive: true });
    const original = '---\nname: bmad-dry-test\ndescription: \'Dry test.\'\n---\n\n# Body\n';
    fs.writeFileSync(path.join(dryDir, 'SKILL.md'), original);

    const count = injectDisableModelInvocation(skillsDir, true);
    assert.ok(count >= 1);

    // File should be unchanged
    const content = fs.readFileSync(path.join(dryDir, 'SKILL.md'), 'utf8');
    assert.equal(content, original);
  });

  it('returns 0 for non-existent directory', () => {
    const count = injectDisableModelInvocation('/nonexistent/path', false);
    assert.equal(count, 0);
  });
});

// ---------------------------------------------------------------------------
// CLI integration tests (using isolated fixtures)
// ---------------------------------------------------------------------------
describe('CLI integration', () => {
  const scriptPath = path.join(__dirname, 'generate-claude-agents.js');
  let fixtureRoot;

  before(() => {
    ({ fixtureRoot } = setupFixtures('cli'));
  });

  after(() => {
    cleanupFixtures('cli');
  });

  it('--dry-run does not write files', () => {
    const outputDir = path.join(fixtureRoot, '.claude', 'agents');

    const output = execFileSync('node', [scriptPath, '--dry-run', '--target', 'claude', '--project-root', fixtureRoot], {
      encoding: 'utf8',
      timeout: 10000,
    });

    assert.ok(output.includes('[dry-run] Would generate'));
    assert.ok(output.includes('bmad-pm'));
    assert.ok(!fs.existsSync(outputDir));
    // Dry-run should preview cleanup actions
    assert.ok(output.includes('[dry-run] Would remove agent skill source: bmad-agent-pm'));
    assert.ok(output.includes('[dry-run] Would remove agent skill source: bmad-tea'));
    // But NOT actually delete them
    assert.ok(fs.existsSync(path.join(fixtureRoot, '.claude', 'skills', 'bmad-agent-pm')));
    assert.ok(fs.existsSync(path.join(fixtureRoot, '.claude', 'skills', 'bmad-tea')));
  });

  it('--help shows usage and exits 0', () => {
    const output = execFileSync('node', [scriptPath, '--help'], {
      encoding: 'utf8',
      timeout: 5000,
    });
    assert.ok(output.includes('Usage:'));
    assert.ok(output.includes('--target'));
    assert.ok(output.includes('--dry-run'));
  });

  it('invalid --target exits with error', () => {
    assert.throws(
      () => {
        execFileSync('node', [scriptPath, '--target', 'invalid'], {
          encoding: 'utf8',
          timeout: 5000,
        });
      },
      (err) => {
        assert.ok(err.stderr.includes('Invalid --target'));
        return true;
      },
    );
  });

  it('non-existent skills dir exits with error', () => {
    assert.throws(
      () => {
        execFileSync('node', [scriptPath, '--target', 'pi', '--project-root', '/tmp/nonexistent_bmad_test'], {
          encoding: 'utf8',
          timeout: 5000,
        });
      },
      (err) => {
        assert.ok(err.status !== 0);
        return true;
      },
    );
  });

  it('--target both succeeds for claude when pi dir is missing', () => {
    const { spawnSync } = require('node:child_process');
    const result = spawnSync('node', [scriptPath, '--dry-run', '--target', 'both', '--project-root', fixtureRoot], {
      encoding: 'utf8',
      timeout: 10000,
    });

    assert.equal(result.status, 0);
    // Claude target should succeed
    assert.ok(result.stdout.includes('[dry-run]'));
    assert.ok(result.stdout.includes('Would generate'));
    // Pi target should warn about missing dir on stderr
    assert.ok(result.stderr.includes('Warning') || result.stderr.includes('skipping pi'));
  });

  it('real run generates agents and cleans up agent skill sources', () => {
    // Use a fresh fixture so cleanup doesn't break other tests
    const genRoot = path.join(FIXTURES_BASE, 'cli-gen');
    const { skillsDir: genSkillsDir } = setupFixtures('cli-gen');

    try {
      const output = execFileSync(
        'node',
        [scriptPath, '--target', 'claude', '--project-root', genRoot],
        { encoding: 'utf8', timeout: 10000 },
      );

      assert.ok(output.includes('Generated: bmad-pm.md'));
      assert.ok(output.includes('Cleaned up agent skill source: bmad-agent-pm'));
      assert.ok(output.includes('Cleaned up agent skill source: bmad-tea'));

      // Native agents should exist
      assert.ok(fs.existsSync(path.join(genRoot, '.claude', 'agents', 'bmad-pm.md')));
      assert.ok(fs.existsSync(path.join(genRoot, '.claude', 'agents', 'bmad-tea.md')));

      // Agent skill sources should be gone
      assert.ok(!fs.existsSync(path.join(genSkillsDir, 'bmad-agent-pm')));
      assert.ok(!fs.existsSync(path.join(genSkillsDir, 'bmad-tea')));

      // Non-agent skills should remain
      assert.ok(fs.existsSync(path.join(genSkillsDir, 'bmad-create-prd')));
    } finally {
      cleanupFixtures('cli-gen');
    }
  });

  it('skills dir with only non-agent skills exits with error', () => {
    // Create a fixture with only workflow skills (no agents)
    const noAgentRoot = path.join(FIXTURES_BASE, 'cli-no-agents');
    const noAgentSkills = path.join(noAgentRoot, '.claude', 'skills', 'bmad-workflow');
    fs.mkdirSync(noAgentSkills, { recursive: true });
    fs.writeFileSync(
      path.join(noAgentSkills, 'bmad-skill-manifest.yaml'),
      'type: workflow\nname: bmad-workflow\ntitle: A Workflow\n',
    );

    try {
      assert.throws(
        () => {
          execFileSync('node', [scriptPath, '--target', 'claude', '--project-root', noAgentRoot], {
            encoding: 'utf8',
            timeout: 5000,
          });
        },
        (err) => {
          assert.ok(err.status !== 0);
          return true;
        },
      );
    } finally {
      fs.rmSync(noAgentRoot, { recursive: true, force: true });
    }
  });
});

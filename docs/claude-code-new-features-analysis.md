# Claude Code New Features -- Impact Analysis for BMAD Orchestrator

**Date:** 2026-02-05
**Author:** Stanley + PM Agent
**Status:** Under Consideration

## Context

Claude Code (Opus 4.6 release) introduced four new features that directly relate to the BMAD Orchestrator architecture. This document analyzes each feature's applicability and proposes paths forward.

## Feature Analysis

### 1. Agent Teams -- High Impact, High Effort

**What it is:** Independent Claude instances with their own context windows, git worktrees, peer-to-peer messaging, and a shared task list. Team lead orchestrates, teammates execute in parallel. Experimental, disabled by default.

**Opportunities:**

- **Parallel story development.** Story loop is currently sequential (create -> dev -> code-review -> next). With agent teams, the orchestrator (team lead) could spawn teammates for independent stories. Each gets its own git worktree -- no merge conflicts by design.
- **Pipelined code review.** Story N+1 developed while Story N is reviewed. Assembly-line instead of serial.
- **Research teammates for ambiguity resolution.** Instead of Party Mode for competing approaches, a research teammate investigates options in parallel with the main workflow.

**Concerns:**

- Experimental and disabled by default (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Each teammate = separate Claude instance = significantly higher token cost
- No nested teams (teammates can't spawn sub-teams)
- No session resumption with in-process teammates -- clashes with Ralph Loop's crash-and-restart philosophy
- One team per session maximum
- **Architectural tension:** Ralph Loop = deterministic disk recovery. Agent teams = parallelism with fragile session state. These pull in opposite directions.

**Open Questions:**
1. Can a fresh Ralph Loop iteration inherit/manage a team spawned in a previous iteration? (Likely no -- may require hybrid architecture)
2. How do teammate worktrees merge back? Who resolves conflicts?
3. Cost vs speed tradeoff -- 3 parallel stories = 3x tokens. Acceptable?

**Verdict:** Phase 2 candidate. Requires architectural rethinking of Ralph Loop + Teams hybrid for the story execution phase.

---

### 2. Compaction -- Moderate Impact, Defensive Value

**What it is:** Claude auto-summarizes its own context when approaching token limits. API-level feature with configurable trigger threshold.

**Does NOT replace the Ralph Loop because:**
- Summaries lose detail. Verification patterns need precise artifact checking.
- Ralph Loop = deterministic recovery (crash anywhere, restart from disk, 100% fidelity). Compaction = probabilistic continuity (summary might miss something).
- State file is human-readable YAML you can manually edit. Compacted context is opaque AI memory.
- Architecture doc explicitly lists "single long-running agent that compacts and degrades" as an anti-pattern.

**Where compaction DOES help:**
- Within a single Ralph Loop iteration, orchestrator-to-sub-agent back-and-forth can get long. Compaction extends how much fits in one iteration.
- Sub-agents doing complex workflows (architecture design with many questions) benefit from longer conversation capacity.
- Safety net -- if a stage runs hotter than expected, compaction catches it instead of crashing.

**Verdict:** Worth adding as a defensive enhancement within existing stages. Does not change architecture.

---

### 3. Adaptive Thinking -- Low Impact, Free Optimization

**What it is:** Claude dynamically decides how much to reason based on task complexity. No manual `budget_tokens` config needed. Set `thinking.type: "adaptive"`.

**For the orchestrator:**
- Routing decisions (Quick Flow vs Full Method) -- needs deep thinking
- Verification after each stage -- needs careful analysis
- State file updates -- mechanical, minimal reasoning needed
- Sub-agent interaction responses -- varies by context

**Verdict:** Essentially free performance. Already works with the template-based stage separation. No code changes needed in the orchestrator itself -- this is model-level behavior.

---

### 4. Effort Controls -- Low Impact, Quick Win

**What it is:** `low`, `medium`, `high` (default), `max` effort levels controlling token spend per request. Set via `output_config.effort` parameter.

**Maps perfectly to template frontmatter:**

| Stage | Suggested Effort | Rationale |
|-------|---------|-----------|
| PRD, Architecture | `high` or `max` | Creative, high-stakes planning |
| Epics & Stories | `high` | Decomposition needs thoroughness |
| Implementation Readiness | `max` | Adversarial review, must find gaps |
| Sprint Planning | `medium` | Mostly mechanical |
| Create Story | `medium` | Structured decomposition |
| Dev Story | `high` | Code implementation |
| Code Review | `max` | Must find real issues |
| Quick Spec/Dev | `high` | Full implementation |
| Task Report | `medium` | Synthesis, not creation |

**Verdict:** Quick win. Add `effort` field to template frontmatter, have orchestrator pass it when launching sub-agents.

---

## Proposed Paths

### Path 1: Agent Teams Parallel Story Execution (Phase 2 Epic)
- Architect Ralph Loop + Teams hybrid for story execution phase
- Planning stages remain sequential Ralph Loop
- Story loop uses agent teams for parallel dev + pipelined review
- Requires significant architectural work and cost analysis

### Path 2: Effort Controls Per Stage (Quick Win) -- SELECTED
- Add `effort` field to template frontmatter schema
- Update all templates with appropriate effort levels
- Orchestrator reads effort level and applies when launching sub-agents
- Immediate token savings on mechanical stages

### Path 3: Compaction as Safety Net (Moderate Enhancement)
- Enable compaction within sub-agent sessions for longer back-and-forth
- Defensive improvement, no architectural changes

### Path 4: All of the Above
- Phase 2 PRD revision incorporating all three enhancements

---

## Technical References

- Anthropic announcement: https://www.anthropic.com/news/claude-opus-4-6
- Agent Teams: Experimental, requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Compaction: Beta, requires `anthropic-beta: compact-2026-01-12` header
- Adaptive Thinking: Production, `thinking.type: "adaptive"` (Opus 4.6 only)
- Effort Controls: Production, `output_config.effort` parameter (Opus 4.6, 4.5)

---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: []
session_topic: 'GUI Frontend for BMAD Platform - Multi-company, multi-project management interface with autonomous pipeline visibility and manual workflow support'
session_goals: 'Generate innovative UI/UX ideas for managing companies/projects, visualizing the BMAD loop pipeline, browsing artifacts, invoking manual workflows, and providing a slick unified workspace'
selected_approach: 'ai-recommended'
techniques_used: ['Role Playing', 'Morphological Analysis', 'Cross-Pollination', 'SCAMPER Method']
ideas_generated: 56
context_file: ''
session_active: false
workflow_completed: true
---

# Brainstorming Session Results

**Facilitator:** Stanley
**Date:** 2026-02-08

## Session Overview

**Topic:** GUI Frontend for the BMAD Platform — a multi-company, multi-project management interface that wraps around the existing BMAD orchestrator, agents, pipeline state, artifacts, and the Ralph Loop execution engine

**Goals:**
- Slick, convenient UI for managing multiple companies each with multiple projects
- Real-time visibility into the autonomous BMAD loop (pipeline stages, agent activity, state progression)
- Access to all necessary details — artifacts, sprint status, story progress, failure recovery, checkpoint gates
- Manual workflow invocation (brainstorming, party mode, research, architecture, etc.)
- A unified workspace that makes the full BMAD methodology accessible and intuitive

### Context Guidance

_Project context loaded from codebase exploration — BMAD is a structured AI-driven development methodology with automated pipelines (Full Method & Quick Flow), 11+ specialized agents, step-file workflow architecture, disk-based state management (state.yaml), and artifact output across planning/implementation/analysis directories._

### Session Setup

_Stanley is the sole user working across multiple companies and projects. The GUI needs to serve as a command center for both autonomous pipeline execution and interactive workflow facilitation._

## Technique Selection

**Approach:** AI-Recommended Techniques
**Analysis Context:** GUI Frontend for BMAD Platform with focus on innovative UI/UX ideas

**Recommended Techniques:**

- **Role Playing:** Explore different user personas (operator, reviewer, workflow launcher) to uncover real UI needs from each perspective
- **Morphological Analysis:** Decompose the GUI into core dimensions (layout, pipeline viz, navigation, info architecture, artifact display) and explore systematic combinations
- **Cross-Pollination:** Steal brilliant patterns from Raycast, Obsidian, GitHub Actions, air traffic control, Spotify, and strategy games
- **SCAMPER Method:** Stress-test best ideas through Substitute, Combine, Adapt, Modify, Put to other uses, Eliminate, Reverse

**AI Rationale:** This sequence moves from empathy (understanding real user needs) to systematic exploration (all possible combinations) to creative theft (proven patterns from other domains) to refinement (stress-testing the best ideas). Each phase builds on the previous.

## Technique Execution Results

### Phase 1: Role Playing

**Personas Explored:** Multi-company operator, Pipeline reviewer, Workflow launcher

**Key Discoveries:**

- The landing screen should be an **action queue** (triage workqueue), not a metrics dashboard
- Default view shows **all companies** — dropdown narrows scope
- Information density should **scale with urgency** — items needing action get rich detail, healthy pipelines get a single status line
- Each attention item needs a **plain-language action message** explaining what's needed
- Pipeline review works best as a **journey summary** — narrative of what happened, not just pass/fail
- Stories are the **bridge document** between the GUI (comprehension) and the editor (verification)
- The GUI is a **file-system-native read-only observer** — data comes from `.bmad-orchestrator/` and `_bmad-output/`
- A lightweight **company/project registry** is the only GUI-owned config
- Manual workflow launching is **out of MVP scope**

### Phase 2: Morphological Analysis

**Dimensions Explored:** Layout Model, Pipeline Visualization Style, Company/Project Navigation, Information Architecture, Artifact Display

**Key Combinations Tested:**

- **Mission Control + Horizontal Pipeline + Dropdown + Action-First + Inline Expandable** — selected as the winning combination
- **IDE-Style Project Explorer** — VS Code-like tree sidebar with colored status dots
- **Activity Stream Chronicle** — single scrollable feed, newest first

**User Selection:** Mission Control Triage Center (Combination 1) — multi-panel command center with action queue on top, pipeline strips below, and contextual artifact browsing

### Phase 3: Cross-Pollination

**Sources Raided:** GitHub Actions, Air Traffic Control, Spotify, Civilization/Factorio, Raycast, Obsidian

**Key Patterns Borrowed:**

- **From Raycast:** Global command palette (Cmd+K), keyboard-first navigation, quick actions on search results, floating Quick-Look panel
- **From Obsidian:** Workspace layouts (save/restore pane arrangements), split pane comparison, frontmatter-aware display, local-first philosophy
- **From GitHub Actions:** Pipeline run history, run duration and stage timing
- **From Air Traffic Control:** Attention decay model — unaddressed items escalate visually over time
- **From Spotify:** "Now Playing" persistent bottom bar showing most active pipeline
- **From Strategy Games:** Non-blocking notification toasts for real-time state changes

### Phase 4: SCAMPER Method

**Key Refinements:**

- **Substitute:** Replace dropdown with command palette scoping (deferred — visual-first preferred for MVP)
- **Combine:** Embed action messages into pipeline strips; merge Now Playing bar with command palette trigger
- **Adapt:** Git diff view for state.yaml changes; browser tab behavior for open projects
- **Modify:** Time-weighted stage widths (wider = longer duration); live age timestamps on action items
- **Put to Other Uses:** Daily standup generator from monitoring data; project health history over time
- **Eliminate:** Remove separate artifact browser — access artifacts through pipeline stage context; remove all persistent navigation in favor of zones + command palette
- **Reverse:** Output-first landing page (latest artifacts instead of process); lead with wins instead of failures

### Creative Facilitation Narrative

_The session progressed from empathetic persona exploration through systematic decomposition to creative cross-pollination and finally rigorous stress-testing. The "Monday morning coffee" framing in Role Playing produced the most authentic insights — the triage workqueue concept emerged directly from imagining the real first-thing-in-the-morning experience. Morphological Analysis generated the Mission Control layout that became the foundation. Cross-Pollination from Raycast and Obsidian added the interaction layer. SCAMPER refined by cutting aggressively — several "combine" and "eliminate" ideas were deliberately rejected in favor of keeping zones separate for visual clarity._

## Complete Idea Inventory

### Theme 1: Command Center Layout & Zones

| # | Idea | Description |
|---|------|-------------|
| 16 | Mission Control Triage Center | Multi-panel command center: action queue top, pipeline strips middle, artifact browser bottom |
| 19 | Collapsible Panel Zones | 3-4 horizontal zones with draggable dividers, collapse/expand to fit current task |
| 20 | Action Queue Card Design | Compact cards with severity-colored left edge (red/amber/blue), inline expand for details |
| 21 | Pipeline Strip Rows | Each pipeline = one horizontal row with stage dots/blocks, completed filled, current pulses, failed glows red |
| 38 | Workspace Layouts | Named pane arrangements: Triage Mode, Review Mode, Monitor Mode — switch with a keystroke |
| 45 | Combined Pipeline + Action Queue | Embed action messages into pipeline strips, eliminating separate queue zone |
| 54 | No Persistent Navigation | Zones + command palette only, maximum screen real estate for content |

### Theme 2: Navigation & Scoping

| # | Idea | Description |
|---|------|-------------|
| 2 | Company > Project Drill-Down | Persistent dropdown scoping entire UI to one company, then one project |
| 22 | All-First Global Scope | Default = all companies visible, dropdown narrows. Breadcrumb: All > Company > Project |
| 23 | Visual Company Grouping | Subtle dividers or background shading separating company sections in global view |
| 24 | Sticky Company Badges | Small colored badges (e.g., "AC" in blue) on every card/strip for instant ownership recognition |
| 34 | Global Command Palette | Cmd+K fuzzy search across projects, artifacts, pipelines, stories. Results grouped by type |
| 36 | Quick Actions on Search | Command palette results show contextual actions: "View pipelines", "Browse artifacts", "Open in editor" |
| 43 | Command Palette Scoping | Replace dropdown entirely with command palette: "scope: Acme" filters everything |
| 48 | Browser Tab Behavior | Open projects as tabs in main content area, switch between project contexts like browser tabs |

### Theme 3: Pipeline Visualization & Monitoring

| # | Idea | Description |
|---|------|-------------|
| 3 | Urgency-Scaled Info Density | Items needing action get rich detail; healthy pipelines compress to single status line |
| 7 | File Watcher Updates | Watch state.yaml via filesystem events for instant dashboard updates when pipeline state changes |
| 25 | Story Loop Progress Bar | Mini progress bar "Stories: 3/8" with filled segment inside the pipeline strip |
| 26 | Story Loop Expanded View | Click progress bar to expand vertical list of individual stories with status |
| 27 | Story Status Micro-Badges | Tiny icons: grey circle (pending), spinning blue (dev), magnifying glass (review), green check (done), red x (failed) |
| 29 | Pipeline Run History | List of past runs per project: "Run #3 — Full Method — Completed Feb 8" |
| 30 | Run Duration & Stage Timing | Per-stage and total timing: "Architecture: 4 min, Story Loop: 45 min" |
| 33 | Notification Toasts | Non-blocking slide-in alerts: "Widget API: Architecture stage complete". Click to jump. |
| 47 | State Change Diff View | Show state.yaml changes as mini diff: "currentStage: architecture -> epics-stories" |
| 49 | Time-Weighted Stage Widths | Stage block width proportional to duration — story loop visually wider than PRD stage |

### Theme 4: Triage & Attention Management

| # | Idea | Description |
|---|------|-------------|
| 1 | Priority Triage Workqueue | Landing screen sorted: failures first, awaiting review second, then everything else |
| 4 | Inline Action Messages | One-line plain-language prompt: "Architecture failed — retry, provide feedback, or abort?" |
| 14 | Story Checklist Mode | Acceptance criteria as interactive checklist with verification progress bar |
| 31 | Attention Decay Model | Unaddressed items visually escalate over time — stronger glow/border for older items |
| 32 | "Now Playing" Bar | Persistent bottom bar: most active pipeline's current status, always visible |
| 46 | Combined Now Playing + Cmd+K | Bottom bar shows status; click/hotkey transforms it into command palette input |
| 50 | Live Age Timestamps | Each card shows updating relative time: "3 min ago", "2 hours ago", "since yesterday" |
| 51 | Daily Standup Generator | Auto-summary of last 24h activity: completed, in progress, failures, copy to clipboard |

### Theme 5: Artifact Browsing & Review

| # | Idea | Description |
|---|------|-------------|
| 9 | Read-Only Artifact Browser | File tree of `_bmad-output/` with inline markdown preview pane |
| 10 | Live Artifact Updates | Artifact browser updates in real-time as pipeline writes new documents |
| 11 | Pipeline Journey Summary | Single-page narrative of completed run: what went in, what was decided, what came out |
| 12 | Stage Cards Expandable | Each pipeline stage as a card: collapsed = one-liner, expanded = key decisions and artifacts |
| 13 | Story-Driven Review Flow | Click stories from pipeline summary, read acceptance criteria, then verify in editor |
| 28 | Plain File Tree + Preview | Simple collapsible tree mirroring `_bmad-output/` structure with markdown render |
| 37 | Floating Quick-Look | Space key triggers floating preview without navigating away — like macOS Quick Look |
| 39 | Split Pane Comparison | Open multiple artifacts side by side: PRD left, Architecture right |
| 40 | Frontmatter-Aware Display | Parse YAML frontmatter and render as structured metadata badges at top of preview |
| 44 | Smart Summary Cards | Summary card (title, metadata badges, first lines, word count) instead of full markdown |
| 53 | Artifacts via Pipeline Context | No separate browser — click a pipeline stage to see its output artifact inline |
| 55 | Output-First Landing | Landing page shows latest produced artifacts across all projects, not process status |

### Theme 6: Architecture & Data Model

| # | Idea | Description |
|---|------|-------------|
| 5 | File-System-Native Data Source | GUI reads directly from `.bmad-orchestrator/` folders — state.yaml is single source of truth |
| 6 | Company/Project Registry | Lightweight GUI config mapping companies to project worktree paths for auto-discovery |
| 8 | MVP = Read-Only Observer | GUI never launches, stops, or modifies anything. Pure observation layer |
| 15 | No Manual Workflows in MVP | Interactive workflows stay in CLI for MVP. Phase 2 feature |
| 41 | Local-First Philosophy | No cloud, no accounts, no sync. Your projects, your machine, your data |

### Theme 7: Interaction & UX Patterns

| # | Idea | Description |
|---|------|-------------|
| 35 | Keyboard-First Everything | Every action has a keyboard shortcut. Arrow keys, Enter, Tab, number keys for navigation |
| 42 | Command Palette as Universal Navigator | Two complete interaction paradigms: visual command center for scanning, command palette for acting |
| 52 | Project Health History | Accumulated metrics: runs, failures, avg completion time per project over time |
| 56 | Lead with Wins | Positive-first dashboard: "5 stories completed today" above "1 failure needs attention" |

## Idea Organization and Prioritization

### MVP — Must-Have (Core)

**Layout:**
- **#16** Mission Control with zones: Action Queue + Pipeline Strips + Artifact Browser
- **#19** Collapsible/resizable panel zones
- **#20** Action Queue cards with severity coloring and inline expand

**Navigation:**
- **#22** All-First Global Scope — default shows all companies
- **#2** Company > Project dropdown filter
- **#24** Sticky Company Badges — colored per company
- **#6** Company/Project Registry config

**Pipeline Visualization:**
- **#21** Compact horizontal pipeline strips with stage indicators
- **#25** Story Loop Progress Bar — "3/8" inline
- **#26** Click to expand individual story statuses
- **#27** Story Status Micro-Badges (icons for pending/dev/review/done/failed)
- **#7** File watcher for real-time state updates

**Triage:**
- **#1** Priority-sorted workqueue — failures first, reviews second
- **#4** Inline action messages — plain-language "what's needed"
- **#3** Urgency-scaled information density

**Artifacts:**
- **#28** Plain file tree + markdown preview (read-only)
- **#40** Frontmatter-aware metadata badges

**Architecture:**
- **#5** File-system-native — reads `.bmad-orchestrator/` and `_bmad-output/`
- **#8** Read-only observer — no process management
- **#41** Local-first, no cloud

### MVP — Should-Have (If Time Allows)

- **#23** Visual company grouping with dividers/shading
- **#11** Pipeline Journey Summary — narrative view of completed runs
- **#12** Stage Cards with expandable detail
- **#29** Pipeline Run History — past runs per project
- **#33** Notification Toasts for real-time state changes
- **#32** "Now Playing" bar at bottom

### Phase 2 — Nice-to-Have

- **#34** Command Palette (Cmd+K)
- **#35** Keyboard shortcuts
- **#38** Workspace Layouts (Triage/Review/Monitor modes)
- **#39** Split pane artifact comparison
- **#13** Story checklist mode with verification tracking
- **#30** Run duration & stage timing
- **#51** Daily Standup Generator
- **#52** Project Health History
- **#47** Diff view for state changes
- **#37** Quick-Look floating preview
- **#15** Manual workflow launching

### Explicitly Cut from All Phases

- **#50** Age display with live timestamps
- **#43** Substitute dropdown with command palette (keeping visual dropdown)
- **#54** Eliminate all navigation (keeping visual nav)
- **#45** Combined pipeline + action queue (keeping separate for clarity)
- **#55** Output-first landing (keeping action-first)
- **#56** Lead with wins (keeping failures-first triage)

## Session Summary and Insights

**Key Achievements:**

- 56 ideas generated across 7 themes using 4 complementary techniques
- Clear MVP definition with 20 must-have features across 6 categories
- Strong product identity established: **local-first, file-native, visual command center**
- Decisive scoping: read-only observer for MVP, no process management, no manual workflows

**Product Vision (One Paragraph):**

The BMAD GUI is a local-first command center that aggregates pipeline state from `.bmad-orchestrator/` folders across multiple companies and projects. The landing screen is a priority-sorted triage workqueue — failures and reviews demanding attention at the top, healthy running pipelines compressed to single-line status strips below. A company/project dropdown scopes the view from global down to a single project. Clicking into pipelines reveals story-level progress; clicking into completed runs opens a read-only artifact browser with markdown preview. The GUI never launches, modifies, or controls anything — it watches, displays, and helps you understand what your BMAD pipelines have been doing.

**Core Design Principles Discovered:**

1. **Triage-first, not dashboard-first** — the GUI is a workqueue, not a status board
2. **Urgency scales detail** — items needing you get more screen space
3. **File-system is the API** — state.yaml and _bmad-output are the data layer
4. **Read before act** — the GUI is for comprehension, the editor is for verification
5. **Visual-first, keyboard-enhanced** — well-designed visual UI is primary, command palette is power-user layer
6. **Progressive disclosure** — summary by default, detail on demand (story loop, artifacts, stage cards)
7. **Local-first identity** — no cloud, no accounts. Your files, your machine

**Breakthrough Moments:**

- The "Monday morning coffee" persona exercise produced the triage workqueue concept — the most important single insight of the session
- Realizing that `.bmad-orchestrator/state.yaml` already contains everything the GUI needs — zero data synchronization required
- Borrowing Obsidian's workspace layouts concept opens up a future where the GUI shapeshifts between monitoring, reviewing, and triaging modes
- The decision to keep pipeline strips and action queue as separate zones (rejecting SCAMPER #45) preserves visual clarity at the cost of slight redundancy — a good trade

**Next Steps:**

1. Create a product brief using this brainstorming output as input context
2. Decide on technology stack (Electron, Tauri, web app, etc.)
3. Design wireframes for the command center layout with the three zones
4. Build a prototype with the company/project registry and file watcher reading a single state.yaml
5. Iterate from there toward the full MVP feature set

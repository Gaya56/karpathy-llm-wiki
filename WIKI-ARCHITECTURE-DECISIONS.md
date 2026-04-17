# Bauer Foundations — Wiki Architecture Decision

## Context

Bauer Foundations (client: Endre Balogh, Bower Group) needs an AI system that reviews new geotechnical projects for risk by comparing against 470+ past projects, each with 15–1800 lessons learned (~7,000+ total). Everything must run locally on a single VM with zero data leakage.

This document captures architecture decisions for the **knowledge base layer** — how project data is stored, searched, and served to users.

---

## Final Architecture

### Stack Overview

| Layer | Tool | Purpose | Link |
|---|---|---|---|
| Wiki skill | Astro-Han/karpathy-llm-wiki | Ingest, compile, query, lint knowledge base | https://github.com/Astro-Han/karpathy-llm-wiki |
| Search layer | QMD | Fast local search across 7,000+ markdown files | https://github.com/tobi/qmd |
| QMD OpenClaw skill | qmd-search | Lets OpenClaw agent call QMD natively | https://playbooks.com/skills/openclaw/skills/qmd-search |
| Agent framework | OpenClaw | Orchestrator + sub-agents, user-facing via Slack/WhatsApp | https://docs.openclaw.ai |
| Storage | Markdown folder on VM | Plain `.md` files — no database, no graph DB | Local directory: `/home/bauer/wiki/` |

### What We Dropped

| Dropped | Why |
|---|---|
| **Neo4j** | Overkill for now. Wikilinks in markdown handle relationship mapping. Revisit only if complex multi-hop queries become essential. Was already listed as optional in Requirements Section E. |
| **Obsidian (user-facing)** | Users will never open Obsidian. It's just a folder of markdown files on the VM. No install needed on user machines. |
| **lewislulu/llm-wiki-skill** | Experimental (2 commits). The web viewer, audit plugin, and TypeScript libs described in ClaHub listing don't exist in the actual repo yet. |

### Why Astro-Han Over Other Repos

| Repo | Status | Why we chose / didn't choose |
|---|---|---|
| **Astro-Han/karpathy-llm-wiki** | Production-tested (94 articles, daily use since April 2026) | Clean skill structure, includes examples, follows Agent Skills standard, works with OpenClaw. **Chosen.** |
| lewislulu/llm-wiki-skill | Experimental, 2 commits | OpenClaw-native but too early. No web viewer despite listings claiming otherwise. |
| hsuanguo/llm-wiki | More complete, has CLI tool + templates | Agent-agnostic, good fallback option but less battle-tested than Astro-Han. |

---

## How It Works — Plain English

### Ingest Flow (new project uploaded)

1. **User uploads file** via Slack/WhatsApp (PDF, Word, Excel, markdown)
2. **Preprocessor script** converts file to markdown (PyMuPDF / pdfminer for PDFs)
3. **Triage agent asks 2–3 questions:**
   - "This looks like it belongs to the Toronto Excavation Pit project. Correct, or is this a new project?"
   - "Should I file this as a geotech report, a lessons learned entry, or a contract document?"
   - "Anything specific you want me to watch for?"
4. **User confirms** — agent routes file to correct project folder in `raw/`
5. **Wiki sub-agent ingests** — reads source, reads wiki index, finds related pages, updates/creates pages, rebuilds index, appends to `log.md`
6. **Contradiction flagging** — automatic on ingest (lightweight). Surfaces top-3 tensions in the announce message. Deeper root-cause analysis available on user request.
7. **QMD re-indexes** — `qmd update` picks up new/changed markdown files

### Query Flow (user asks a question)

1. **User asks** via Slack/WhatsApp: "What groundwater risks did we see in clay sites?"
2. **OpenClaw orchestrator** receives the message
3. **QMD searches** 7,000+ wiki pages locally (milliseconds) — returns top 5 most relevant pages with scores
4. **Wiki skill reads** those 5 pages, follows wikilinks 2–3 levels deep if needed
5. **Agent synthesizes answer** — connects dots across multiple projects, cites which project/page each point came from
6. **User gets response** with citations to specific past projects and lessons learned

### Background Sub-Agent Pattern

The wiki skill runs as an **OpenClaw sub-agent**, not inline with the main conversation. When a user uploads a file:

- Main orchestrator responds immediately: "I'm analyzing your new project in the background."
- Wiki sub-agent runs async — ingests, compiles, flags contradictions
- Sub-agent announces results back to the chat when done
- User can continue chatting with the main agent while ingestion happens

Configure via `agents.defaults.subagents.model` — use a cheaper model for the wiki sub-agent to control costs.

---

## What to Copy Where

### From Astro-Han/karpathy-llm-wiki

```bash
# Clone the repo
git clone https://github.com/Astro-Han/karpathy-llm-wiki.git

# Copy skill into OpenClaw
cp -r karpathy-llm-wiki/SKILL.md ~/.openclaw/skills/karpathy-llm-wiki/
cp -r karpathy-llm-wiki/references/ ~/.openclaw/skills/karpathy-llm-wiki/
cp -r karpathy-llm-wiki/templates/ ~/.openclaw/skills/karpathy-llm-wiki/
```

### QMD Setup

```bash
# Install QMD
bun install -g https://github.com/tobi/qmd

# Create collection pointing to the wiki
qmd collection add /home/bauer/wiki --name bauer-wiki --mask "*.md"

# Generate embeddings (one-time, ~5-10 min for 7,000 files)
qmd embed

# Test search
qmd query "groundwater risk clay" -c bauer-wiki
```

### Bootstrap the Wiki Directory

```bash
# One-time scaffold
python3 karpathy-llm-wiki/scripts/scaffold.py /home/bauer/wiki "Bauer Foundations Risk KB"
```

This creates:

```
/home/bauer/wiki/
├── raw/                  ← Immutable source documents drop here
│   └── projects/
│       ├── toronto-2026/
│       ├── vancouver-2025/
│       └── ...
├── wiki/                 ← LLM-maintained pages (never manually edited)
│   ├── projects/         ← Per-project pages (isolated)
│   ├── shared-concepts/  ← Cross-project patterns
│   ├── index.md          ← Global table of contents
│   └── log.md            ← Append-only operation log
└── CLAUDE.md             ← Schema: tells agent how this wiki works
```

### Project Isolation

When ingesting, files go to their specific project folder only. Shared concepts (like "clay-behavior" or "dewatering-methods") update only when a pattern spans multiple projects. This prevents new data from leaking into old project pages.

Agent instruction in SKILL.md: "When ingesting, check if the source belongs to an existing project. If yes, update that project's pages only. Only update shared-concepts if it's a pattern across multiple projects."

---

## User-Facing Interfaces

Bauer users never touch the terminal, Obsidian, or the wiki files directly.

| Interface | What they use it for |
|---|---|
| **Slack / WhatsApp** | Ask questions, upload files, receive risk reports — via OpenClaw agent |
| **Web viewer** (to be built) | Browse the compiled wiki in a browser — simple HTML rendering of markdown files |
| **Feedback** | Leave comments via web viewer or chat — agent processes audit queue periodically |

---

## What Still Needs to Be Built

| Item | Description | Priority |
|---|---|---|
| **Preprocessing script** | Converts PDF/Word/Excel → markdown before wiki ingestion. Small Python script using PyMuPDF or pdfminer. | High — needed before any ingestion |
| **Triage logic in orchestrator** | Prompt engineering in the orchestrator agent to ask 2–3 routing questions when a file is uploaded. Not a separate tool. | High — prevents misrouted files |
| **Web viewer** | Simple Node.js or Python server that renders the wiki's markdown files in a browser. Bauer users browse knowledge here instead of Obsidian. | Medium — needed for non-technical users |
| **Wiki schema (CLAUDE.md)** | Define risk categories, project structure, and cross-linking rules. Wait until we see Bauer's actual documentation before finalizing. | High — but blocked until client docs arrive |
| **Initial data migration** | Script to export 470 projects + lessons from Bauer's existing system into markdown files in `raw/`. Format depends on their current storage. | High — one-time effort |
| **Contradiction flagging rules** | Define what counts as a contradiction in the SKILL.md. E.g., same soil type + same method + different outcome = flag it. | Medium — refine after seeing real data |

---

## Build & Validate Strategy

### Approach: Eat Your Own Dog Food

Before building Bauer's setup, we use the wiki skill + QMD to **ingest all documentation about the tools we're using**. This creates a compiled knowledge base that Claude Code references while building the Bauer VM. We validate the wiki pattern works AND create the build manual at the same time.

The codespace wiki becomes the single source of truth for how OpenClaw, the wiki skill, QMD, and all dependencies work together.

### What We Ingest First (tool knowledge base)

| Source | What we get from it | Link |
|---|---|---|
| OpenClaw official docs | Gateway setup, agent config, sub-agents, sessions, memory, skills, channels | https://docs.openclaw.ai |
| OpenClaw wiki docs | Detailed tool reference, slash commands, config options | https://openclawwiki.org |
| Astro-Han/karpathy-llm-wiki | SKILL.md, references/, templates/, examples/ — the full skill spec | https://github.com/Astro-Han/karpathy-llm-wiki |
| QMD repo + docs | Install, collections, search modes, embedding, MCP server, chunking strategy | https://github.com/tobi/qmd |
| QMD OpenClaw skill | How OpenClaw calls QMD natively | https://playbooks.com/skills/openclaw/skills/qmd-search |
| Karpathy's LLM Wiki gist + comments | Original pattern, community learnings, edge cases, scale considerations | https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f |
| OpenClaw sub-agents docs | Spawn, announce, cleanup, model routing, cost control | https://docs.openclaw.ai/tools/subagents |
| OpenClaw multi-agent guide | Agent isolation, workspace layout, session management | https://lumadock.com/tutorials/openclaw-multi-agent-setup |
| Our project files | Requirements, meeting notes, model research, manual risk assessment workflow | `/mnt/project/` |

### Build Order

Each step validates the previous one before moving forward.

**Step 1 — Set up the codespace wiki**
- Install the wiki skill + QMD in the codespace
- Scaffold a wiki directory for tool documentation
- Validate: scaffold runs, directory structure is correct

**Step 2 — Ingest all tool documentation**
- Ingest OpenClaw docs, Astro-Han repo, QMD docs, gist + comments
- Ingest our project files (requirements, meeting notes, model research)
- Validate: wiki compiles pages, index is populated, cross-links exist between tools

**Step 3 — QMD indexes the tool wiki**
- Create QMD collection pointing at the tool wiki
- Generate embeddings
- Validate: `qmd query "how to configure openclaw sub-agents"` returns relevant compiled pages

**Step 4 — Claude Code uses the wiki to build Bauer's setup**
- Claude Code references the compiled tool wiki while creating:
  - OpenClaw gateway config (`openclaw.json`)
  - Agent definitions (orchestrator, wiki sub-agent)
  - Skill integration (wiki skill + QMD skill)
  - Preprocessing pipeline (PDF → markdown)
  - Triage prompt logic
  - Contradiction flagging rules
- Validate: each component works because Claude Code built it from accurate, compiled documentation — not stale training data

**Step 5 — Test with mock Bauer data**
- Create 5–10 fake geotechnical project files with realistic risk categories
- Run full loop: upload → triage → preprocess → ingest → QMD index → query → answer
- Validate: accuracy, project isolation, contradiction flagging

**Step 6 — Test with real Bauer data (once available)**
- Load 50 real projects from client
- Validate at scale before loading remaining 420

**Step 7 — Deploy to Bauer VM**
- Mirror the validated codespace setup onto Bauer's production VM
- Connect Slack/WhatsApp channels
- Load remaining projects incrementally

### Why This Approach

| Benefit | How |
|---|---|
| **Validates the wiki pattern** | If it can compile OpenClaw docs into a usable knowledge base, it can handle Bauer's project data |
| **Claude Code builds from truth** | No hallucinated API calls or outdated config — it reads from compiled, cross-referenced docs |
| **Catches integration issues early** | We discover how the wiki skill + QMD + OpenClaw actually work together before touching client data |
| **The tool wiki persists** | After Bauer is built, we keep the tool knowledge base for maintenance, debugging, and future updates |
| **Proves scale path** | If QMD handles hundreds of tool doc pages, we have confidence it handles thousands of project pages |

---

## Key Principles

- **Wiki pattern, not RAG** — knowledge is compiled once into persistent pages, not re-retrieved from raw docs every query. Knowledge compounds over time.
- **Obsidian is invisible** — just a markdown folder on the VM. Users never see it.
- **QMD handles scale** — at 7,000+ files, the agent can't read the whole index. QMD narrows to the right 5 pages in milliseconds.
- **Sub-agent pattern** — ingestion runs in background, doesn't block the user conversation.
- **Human-in-the-loop** — agent asks before routing files, flags contradictions for human review, doesn't make final risk decisions.
- **Schema comes from the client** — we define the wiki structure after seeing Bauer's actual documentation and risk categories.

---

## Reference Links

| Resource | Link |
|---|---|
| Astro-Han wiki skill (chosen) | https://github.com/Astro-Han/karpathy-llm-wiki |
| QMD search engine | https://github.com/tobi/qmd |
| QMD OpenClaw skill | https://playbooks.com/skills/openclaw/skills/qmd-search |
| OpenClaw sub-agents docs | https://docs.openclaw.ai/tools/subagents |
| OpenClaw multi-agent guide | https://lumadock.com/tutorials/openclaw-multi-agent-setup |
| Karpathy's original LLM Wiki gist | https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f |
| lewislulu/llm-wiki-skill (reference only) | https://github.com/lewislulu/llm-wiki-skill |
| hsuanguo/llm-wiki (fallback option) | https://github.com/hsuanguo/llm-wiki |
| Bauer Foundations Canada | https://www.bauerfoundations.ca/en |

### Project Files

| Document | Path |
|---|---|
| Requirements doc | `/mnt/project/Requirements__.pdf` |
| Model research v1 | `/mnt/project/Model_research_version_1_` |
| Meeting 1 notes | `/mnt/project/Construction_Clients_meeting_1_notes_.pdf` |
| Manual risk assessment doc | `/mnt/project/How_Manual_Risk_Assessment_Works_in_This_Industry_brainstormed_.pdf` |

---

## Untested / Risks

- **Astro-Han + QMD at 7,000+ files** — each works independently at scale, but the combo hasn't been validated at Bauer's volume. POC with 50 projects first.
- **Wiki skill was built for personal research** — not multi-project enterprise use. Project isolation and triage logic are customizations we'll add.
- **No web viewer exists yet** — needs to be built. Straightforward (serve markdown as HTML) but it's additional work.
- **Preprocessing quality** — PDF → markdown conversion can lose table formatting, images, soil boring log diagrams. Need to test with real Bauer documents.
- **QMD embedding model size** — the default GGUF model for embeddings is ~300MB. Fine for VM, but verify disk/RAM budget.
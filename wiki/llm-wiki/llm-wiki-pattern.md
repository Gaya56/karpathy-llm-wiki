# LLM Wiki Pattern

> Sources: Mandar Karhade, MD. PhD., 2026-04-08; Andrej Karpathy, Unknown
> Raw: [2026-04-08-andrej-karpathy-killed-rag-or-did-he-llm-wiki-pattern](../../raw/llm-wiki/2026-04-08-andrej-karpathy-killed-rag-or-did-he-llm-wiki-pattern.md); [karpathy-llm-wiki-original](../../raw/llm-wiki/karpathy-llm-wiki-original.md)
> Updated: 2026-04-17

## Overview

The LLM Wiki pattern, introduced by Andrej Karpathy in a GitHub Gist (5,000+ stars and 1,294 forks in 48 hours, per secondary analysis), proposes that an LLM should build and maintain a persistent, compounding markdown knowledge base rather than re-retrieving raw documents on every query as traditional RAG does. The core shift is from retrieval-at-query-time to compilation-at-ingest-time: knowledge is structured once and grows richer with each new source added. The pattern is explicitly designed for personal and small-team scale, not enterprise deployments. Karpathy describes the document as intentionally abstract — a pattern, not a prescribed implementation. Everything is optional and modular.

## The Core Idea: Compilation Over Retrieval

Traditional RAG is stateless — every query is day one. The LLM rediscovering knowledge from scratch each time, working from chunks that have been ripped out of their original document context. The chunking problem compounds the statelessness: splitting a 40-page research paper into 512-token fragments destroys the structure the document originally had, then engineering effort goes into reconstructing what was already there.

LLM Wiki inverts this. The LLM reads sources at ingest time, extracts key information, and compiles it into structured wiki articles with cross-references. By query time, the knowledge already exists in pre-synthesized, coherent form. The analogy: RAG is a search engine (finds pages that might contain your answer); LLM Wiki is an encyclopedia (gives you a structured article synthesized from many sources).

Karpathy's Obsidian metaphor makes the mental model clear: Obsidian is the IDE, the LLM is the programmer, the wiki is the codebase. You never write the wiki yourself — you source material and ask questions; the LLM does the bookkeeping.

## Three-Layer Architecture

**Layer 1: Raw Sources** — An immutable collection of original materials (articles, papers, transcripts, notes, images, data files). They go into a `raw/` directory and stay there, untouched. Source of truth; nothing modifies them after ingest.

**Layer 2: The Wiki** — LLM-maintained markdown files: summaries of each source, encyclopedia-style articles for key concepts and entities, cross-references between related ideas, and a master index. One source can touch 10–15 wiki pages simultaneously. Contradictions between sources get flagged. The synthesis reflects everything the system has ever consumed.

**Layer 3: The Schema** — A configuration document (Karpathy uses CLAUDE.md for Claude Code or AGENTS.md for Codex) that tells the LLM agent how to behave: wiki structure, page formatting conventions, ingestion procedure, conflict handling. It is the constitution the agent operates under. You and the LLM co-evolve this over time as you figure out what works for your domain.

## The Three Operations

**Ingest** brings a new source into the system. The LLM reads it, writes a summary page, updates the master index, and — critically — revises every relevant concept and entity page across the wiki. A single paper might update pages on attention mechanisms, model compression, inference optimization, and multiple researcher entity pages. All automatically. All cross-linked. Karpathy personally prefers ingesting sources one at a time and staying involved — reading summaries, checking updates, guiding emphasis — though batch ingestion with less supervision is also possible.

**Query** interrogates the wiki. The LLM searches the index, pulls relevant pages, and synthesizes an answer from structured pre-compiled knowledge. Answers can take different forms: a markdown page, a comparison table, a slide deck (Marp), a chart (matplotlib). If the answer is valuable it becomes a new wiki page — the compounding loop runs in both directions. Questions make the wiki smarter.

**Lint** is the maintenance cycle. Periodically the LLM scans the entire wiki for contradictions, stale claims, orphan pages, missing concepts, and data gaps. It suggests new questions to investigate and new sources to look for. A health check that keeps the wiki self-healing.

## Indexing and Logging

Two special files help the LLM (and you) navigate the wiki as it grows:

**index.md** is content-oriented. It's a catalog of every page — each listed with a link, a one-line summary, and optional metadata. Organized by category. The LLM updates it on every ingest. At moderate scale (~100 sources, hundreds of pages), reading the index first then drilling into relevant pages works well without any embedding-based RAG infrastructure.

**log.md** is chronological. An append-only record of ingests, queries, and lint passes. Karpathy's tip: if each entry starts with a consistent prefix (e.g. `## [2026-04-02] ingest | Article Title`), the log becomes parseable with simple unix tools. The log gives the LLM a timeline of recent activity across sessions.

## The Vannevar Bush Connection

Karpathy explicitly references Vannevar Bush's 1945 Memex concept from "As We May Think" — a hypothetical device where a researcher could store all books, records, and communications, with "associative trails" linking related ideas. Bush's vision was a personal, curated knowledge store that grew more valuable with use. The problem Bush couldn't solve was maintenance: who keeps cross-references updated? Who flags when a new finding contradicts an old one? Humans, and humans abandon wikis.

LLMs don't get bored. They don't skip cross-referencing because it's Friday afternoon. The tedious bookkeeping that kills every personal knowledge base in practice is precisely what LLMs are well-suited to. The LLM Wiki pattern is, in this framing, a solution to Bush's 80-year-old maintenance problem.

## Scale and Limitations

Karpathy reports using this pattern at approximately 100 articles and 400,000 words — a scale where modern context windows can hold the index plus several full articles simultaneously. [Note: the 400,000-word figure is from secondary analysis by Karhade; Karpathy's original document references "~100 sources, ~hundreds of pages" without a word count.]

At enterprise scale (10^4–10^6 files), known gaps emerge:
- No RBAC mechanism — agents cannot be restricted from sensitive data categories.
- No ACID transaction guarantees — multiple simultaneous agents writing to the same pages produce race conditions.
- No tamper-proof audit trail for regulated industries.
- Flat-file systems cannot handle the performance demands of large-scale data.

Karpathy describes the document as intentionally abstract — a pattern, not a prescribed implementation. It is a personal knowledge weapon, not an enterprise platform.

## Use Cases

Karpathy provides an explicit list of domains where the pattern applies:

**Personal knowledge management** is the killer app. Track goals, health metrics, psychology notes, self-improvement — file journal entries, articles, podcast notes, and build a structured picture of yourself over time.

**Research synthesis** genuinely outperforms RAG: build a comprehensive wiki with an evolving thesis over weeks or months, watching how new findings modify or contradict earlier ones. The wiki becomes externalized understanding.

**Book reading** enables building a fan wiki — characters, themes, plot threads — cross-referenced and updated as new chapters reveal information. Karpathy cites Tolkien Gateway (thousands of interlinked pages built by volunteers over years) as the model; LLM Wiki lets one person build something equivalent while reading.

**Business operations** (Slack threads, meeting transcripts, customer calls) is compelling but is where scalability concerns bite hardest. Possibly with humans in the loop reviewing updates.

**Other domains**: competitive analysis, due diligence, trip planning, course notes, hobby deep-dives — anything where you're accumulating knowledge over time and want it organized rather than scattered.

## Tooling and Workflow Tips

From Karpathy's original document:

- **Obsidian Web Clipper** is a browser extension that converts web articles to markdown — the primary tool for getting sources into the raw collection quickly.
- **Download images locally** via Obsidian Settings (Attachment folder path → `raw/assets/`; bind "Download attachments for current file" to a hotkey). This lets the LLM view images directly rather than relying on URLs that may break. Limitation: LLMs cannot natively read markdown with inline images in one pass — the workaround is to have the LLM read text first, then view referenced images separately.
- **Obsidian's graph view** reveals the shape of the wiki — hubs, orphans, clusters.
- **Marp** is a markdown-based slide deck format (Obsidian plugin available). Useful for generating presentations from wiki content.
- **Dataview** is an Obsidian plugin that runs queries over page frontmatter (tags, dates, source counts) to generate dynamic tables and lists.
- **Git** gives the wiki version history, branching, and collaboration for free — the wiki is just a repo of markdown files.

## Optional: CLI Search Tools

At small scale, the index file is sufficient for navigation. As the wiki grows, proper search becomes useful. Karpathy recommends [qmd](https://github.com/tobi/qmd): a local search engine for markdown files that stacks BM25 (SQLite FTS5), vector semantic search (EmbeddingGemma 300M), and LLM re-ranking (Qwen3 0.6B), all running on-device with no cloud calls. It provides a CLI (for shell-out from the LLM), a JavaScript SDK, and an MCP server (for native tool access without shell-out). See [qmd](qmd.md) for full architecture and setup details. A simpler custom script is also viable — the LLM can help build one as the need arises.

## Community Reception and Debates

The gist received 5,000+ stars and 1,294 forks in 48 hours with zero code. [Note: these figures are from Karhade's secondary analysis, not from Karpathy's original document.] Reactions split into three camps:

**Enthusiasts** see it as solving the compounding memory problem RAG never addressed — asking the same questions and never building on previous insights.

**Skeptics** argue Karpathy renamed the cache layer and that anyone shipping LLM Wiki as the new orthodoxy will rediscover deduplication and stale invalidation within months. They note Claude Code's agentic file search already outperforms chunked text search in many cases.

**Pragmatists** hold that RAG and LLM Wiki aren't enemies — they are different tools for different scales and use cases. Curated notes plus citations plus periodic refresh beats re-retrieving every turn, without claiming RAG is dead.

## The Fine-Tuning Endgame

One underexplored direction Karpathy hints at: generating synthetic training data from the wiki to fine-tune models. A comprehensive, cross-referenced, contradiction-flagged wiki about a domain becomes a dataset. Fine-tuning a model on that dataset moves knowledge from context window to model weights. The personal wiki becomes a personal model. The wiki is the intermediate representation. [Note: this direction is surfaced by Karhade's analysis as an implication of Karpathy's pattern; the original document does not develop it explicitly.]

## The Pattern Is the Product

Karpathy released a pattern, not software. Implementation details are left deliberately vague because the specifics depend on domain, tools, scale, and preferences. The power of a pattern over a product is that it invites adaptation rather than adoption. Every implementation will differ because every knowledge domain differs. The document's only job is to communicate the pattern; the LLM figures out the rest.

## See Also

- [qmd](qmd.md)

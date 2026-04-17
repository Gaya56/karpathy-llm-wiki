# Andrej Karpathy Killed RAG. Or Did He? The LLM Wiki Pattern

> Source: https://medium.com/@mandarkarhade/andrej-karpathy-killed-rag-or-did-he-the-llm-wiki-pattern (Medium article by Mandar Karhade, MD. PhD.)
> Collected: 2026-04-16
> Published: 2026-04-08

Andrej Karpathy Killed RAG. Or Did He? The LLM Wiki Pattern

TLDR

Andrej Karpathy published a GitHub Gist describing "LLM Wiki," a pattern where the LLM builds and maintains a persistent, compounding markdown knowledge base instead of re-retrieving documents on every query like traditional RAG.

The architecture has three layers: raw sources (immutable), a wiki (LLM-maintained markdown with cross-references), and a schema (configuration directing agent behavior). No vector database required at personal scale.

The community is split: half thinks RAG is officially dead, the other half thinks Karpathy just gave a fancy name to a cache layer. Both sides have a point.

The real insight isn't "RAG bad, wiki good." It's that knowledge should compound, not evaporate. And LLMs are finally good enough at bookkeeping to make that practical.

Enterprise scalability is the elephant in the room: no RBAC, no ACID transactions, no concurrency controls. This is a personal knowledge weapon, not an enterprise platform. Yet.

---

A Gist That Built The Product

Andrej Karpathy, the man who taught the world how neural networks actually work with his Stanford lectures, who co-founded OpenAI, who built Tesla's Autopilot vision stack, who left OpenAI (again) and has been quietly shipping open-source gold ever since — he dropped a GitHub Gist. Not a repo. Not a framework. Not a library with 47 dependencies and a YAML config that makes you question your career choices.

A Gist.

A markdown file.

And the AI community collectively lost it. 5,000+ stars. 1,294 forks. In 48 hours. For a document that contains zero code.

Here's the thing: the document describes something called "LLM Wiki," a pattern for building personal knowledge bases where the LLM doesn't just retrieve information — it compiles, maintains, cross-references, and continuously enriches a structured markdown wiki. The knowledge compounds with every source you add. Nothing disappears into chat history.

And people are calling it the RAG killer.

---

What RAG Actually Does (and Why People Are Fed Up)

Most people's experience with RAG is underwhelming. The flow: you upload documents. The system chunks them into fragments, sometimes intelligently, usually not. Those chunks get embedded into vectors and stored in a database. When you ask a question, the system retrieves the "most similar" chunks, stuffs them into context, and the LLM generates an answer.

It works. Sort of.

The problem is subtle but devastating. Every query is a fresh start. The LLM rediscovers knowledge from scratch every single time. There's no accumulation. No synthesis. No memory of what it figured out last time. Ask the same question tomorrow and the system goes through the identical retrieval dance, finding the same chunks (if you're lucky) or different ones (if you're not).

The chunking problem is even worse than the statelessness. When you split a 40-page research paper into 512-token fragments, you're destroying context. A paragraph about transformer attention mechanisms gets ripped away from the paragraph that defines the notation. A conclusion references findings from section 3, but section 3 is in a completely different chunk. The embedding might say "this is relevant," but the LLM is reading a sentence with no beginning and no end.

The community has been screaming about this for over a year. Sophisticated chunking strategies, overlapping windows, hierarchical retrieval, re-ranking pipelines — the RAG ecosystem has become a Rube Goldberg machine of workarounds for a fundamental architectural problem.

---

Enter LLM Wiki: The Compiler, before the Search Engine

Karpathy's insight is elegant in its simplicity: what if the LLM didn't retrieve raw documents at query time? What if, instead, it had already read everything, extracted the key information, organized it into a structured wiki with cross-references and entity pages, and kept the whole thing continuously updated?

The metaphor he uses is perfect: Obsidian is the IDE. The LLM is the programmer. The wiki is the codebase.

You never write the wiki yourself. You source. You explore. You ask questions. The LLM does all the grunt work.

The architecture has three layers:

Layer 1: Raw Sources
This is your immutable collection of original materials. Articles, papers, transcripts, notes, images. They go into a raw/ directory and stay there, untouched. Think of them as your source of truth.

Layer 2: The Wiki
This is where the magic happens. The LLM reads raw sources and produces structured markdown files: summaries of each source, encyclopedia-style articles for key concepts and entities, cross-references between related ideas, and a master index that catalogs everything. One source can touch 10 to 15 wiki pages simultaneously. Contradictions between sources get flagged. The synthesis reflects everything the system has ever consumed.

Layer 3: The Schema
A configuration document (Karpathy uses CLAUDE.md) that tells the LLM agent how to behave: what the wiki's structure should look like, how to format pages, what to do during ingestion, how to handle conflicts. It's the constitution the agent operates under.

---

The Three Operations That Make It Work

The system runs on three core operations, forming a self-reinforcing loop that gets smarter over time:

Ingest is where sources enter the system. You drop a new article, paper, or transcript into the raw collection. The LLM reads it, discusses the key takeaways, writes a summary page, updates the master index, and then — critically — revises every relevant entity and concept page across the wiki. A single paper about transformer efficiency might update pages on attention mechanisms, model compression, inference optimization, and three different researcher entity pages. All automatically. All cross-linked.

Query is how you interrogate the wiki. You ask a question. The LLM searches the wiki index, pulls up relevant pages, and synthesizes an answer from structured, pre-compiled knowledge. Not fragments. Not chunks. Full, coherent articles that it wrote itself. If the answer is valuable, it becomes a new wiki page. Your exploration compounds in the knowledge base. Your questions make the wiki smarter.

Lint is the maintenance cycle. Periodically, the LLM scans the entire wiki for contradictions, stale claims, orphan pages, missing concepts, and data gaps. It's a health check for your knowledge base. The wiki heals itself.

---

The Vannevar Bush Connection Nobody Is Talking About

Karpathy explicitly references Vannevar Bush's Memex from 1945. Bush was the director of the U.S. Office of Scientific Research and Development during World War II, and he wrote a prophetic essay called "As We May Think" that essentially described the modern internet, personal knowledge management, and hyperlinked information systems — 50 years before the web existed.

Bush's Memex was a hypothetical device where a researcher could store all their books, records, and communications, with "associative trails" linking related ideas across documents. The vision was a personal, curated knowledge store that grew more valuable as you used it.

The problem Bush couldn't solve was maintenance. Who keeps all those cross-references updated? Who reads every new paper and links it to every relevant existing document? Who flags when a new finding contradicts an old one?

Humans. And humans abandon wikis. Every single time.

But LLMs don't get bored. They don't forget to update the index. They don't skip the cross-referencing because it's Friday afternoon. The tedious bookkeeping that kills every personal knowledge base in practice — that's precisely what LLMs are uniquely good at.

Karpathy didn't just build a better RAG. He solved Bush's 80-year-old maintenance problem.

---

Community Reaction

The discourse around this gist is fascinating. Reactions fall into distinct camps.

The Enthusiasts see this as the future of knowledge work. People are pointing out that the persistent, compounding nature of the wiki solves the exact wall they've been hitting with traditional RAG: asking the same questions, getting inconsistent answers, never building on previous insights. Some are already building their own implementations. One developer open-sourced llmwiki.app, connecting directly to Claude via MCP. Another shared a "knowledge synthesis engine" they'd been building independently.

The Skeptics called it reinvention of the cache layer. The sharpest critique: Karpathy didn't kill RAG — he just renamed the cache layer. And anyone shipping LLM Wiki as the new orthodoxy is going to rediscover deduplication and stale invalidation the hard way in six months. They also pointed out that Claude Code already uses agentic search: models are good at file search now, and letting them search for files with more context beats chunked text search embeddings in many use cases.

The Pragmatists: RAG is fine for what it does. The missing piece was compounding memory. Curated notes plus citations plus periodic refresh beats re-retrieving every turn. RAG and LLM Wiki aren't necessarily enemies — they're different tools for different scales and use cases.

---

The Scale Question: 100 Articles Is Not Enterprise

Karpathy reports using this pattern at a scale of approximately 100 articles and roughly 400,000 words. At this size, the model's ability to navigate via summaries and index pages is more than sufficient. Modern context windows can hold an index plus several full articles simultaneously.

At 10^4, 10^5, 10^6 files — a petabyte-scale enterprise knowledge base with compliance requirements, role-based access controls, and 50 agents writing simultaneously — the enterprise scalability gaps are real:

- File-based markdown systems have no RBAC mechanism.
- No ACID transaction guarantees — multiple simultaneous agents will produce race conditions.
- No tamper-proof audit trail for regulated industries.
- Flat-file systems cannot handle performance demands of large-scale data.

Karpathy explicitly states the document is intentionally abstract, describing a pattern rather than prescribing an implementation. He knows this is a personal knowledge weapon, not an enterprise platform.

---

Why "Just Better RAG" Is the Wrong Frame

Traditional RAG is a retrieval operation at query time. You search, you find chunks, you generate. The system is stateless. Every query is day one.

LLM Wiki is a compilation operation at ingest time. When a new source enters the system, the LLM doesn't just index it — it reads it, understands it, integrates it into existing knowledge, updates cross-references, flags contradictions, and strengthens the synthesis. The knowledge exists in structured, pre-compiled form before you ever ask a question.

This is the difference between a search engine and an encyclopedia. Google (search) helps you find pages that might contain your answer. Wikipedia (compiled knowledge) gives you a structured article that synthesizes information from hundreds of sources, with cross-references, citations, and editorial oversight.

RAG is the search engine. LLM Wiki is the encyclopedia. Both useful. Fundamentally different architectures solving fundamentally different problems.

---

Use Cases That Actually Make Sense

Personal knowledge management is the killer app. Track goals, health metrics, psychology notes. File journal entries alongside research articles. Build a structured picture of yourself over time. Works because scale is inherently personal (hundreds, not millions of documents) and compounding knowledge is highest when there's one user whose context the system learns over months.

Research synthesis is where this pattern genuinely outperforms RAG. Reading papers for months, building a comprehensive wiki with an evolving thesis, watching how new findings modify or contradict earlier ones — the wiki becomes externalized understanding, maintained by an agent that never forgets to update the cross-references.

Reading a book is surprisingly powerful. Build a fan wiki as you read. Characters, themes, plot threads, all cross-referenced, all updated as new chapters reveal new information.

Business operations is where it gets interesting but scalability concerns bite. Feeding Slack threads, meeting transcripts, and customer calls into a wiki sounds incredible. But this is where you need RBAC, audit trails, and concurrency controls.

---

The Obsidian Bet and the Tooling Ecosystem

Karpathy's choice of Obsidian as the human interface is deliberate. Obsidian's graph view reveals structural patterns in the wiki: which concepts are hubs (highly connected), which are orphans (disconnected), where the wiki has dense knowledge clusters and where it has gaps. The Dataview plugin enables dynamic queries against page frontmatter. Marp generates slide decks from wiki content. And because the wiki is just markdown files in a folder, it's automatically a git repository with full version history.

The community is already extending this in interesting directions. Multiple implementations have popped up within days: llmwiki.app, obsidian-wiki integrations, and enterprise teams adapting the pattern for semiconductor knowledge management and service delivery documentation. Someone connected it directly to Claude via MCP servers.

The tooling convergence is real. Local hybrid search tools like qmd provide BM25/vector search with LLM re-ranking. Obsidian Web Clipper converts any web article to markdown with one click.

---

The Fine-Tuning Endgame Nobody Is Discussing

One of the most underappreciated aspects of Karpathy's pattern is the future direction he hints at: generating synthetic training data from the wiki to fine-tune models. You spend months building a comprehensive, cross-referenced, contradiction-flagged wiki about your domain. Then you use that wiki to generate training examples. Then you fine-tune a model on those examples.

The knowledge moves from context window to model weights. Your personal wiki becomes a personal model. The wiki is the intermediate representation. The compiled knowledge base is a dataset waiting to become a model.

---

What This Means for the RAG Industry

RAG isn't dead. Not even close. RAG solves real problems at scales where LLM Wiki can't operate: millions of documents, unpredictable queries, real-time data, multi-tenant enterprise deployments with strict security requirements.

But for personal knowledge bases, research projects, small team wikis, and domain-specific knowledge management at the scale of hundreds to low thousands of documents? The LLM Wiki pattern is demonstrably superior. The pre-compiled, structured knowledge eliminates the chunking problem entirely. The compounding loop means the system gets better with use. The maintenance automation solves the abandonment problem that kills every personal wiki.

The RAG vendors building billion-dollar businesses on vector databases and retrieval pipelines should be paying attention. Not because LLM Wiki replaces their enterprise products today. But because the pattern exposes a truth the industry has been dodging: most RAG implementations are over-engineered for what users actually need, and under-engineered for what users actually want.

Users don't want retrieval. They want knowledge. There's a difference.

---

The Pattern Is the Product

Karpathy didn't release software. He released a pattern. An idea file. A document you're supposed to hand to your LLM agent and say "build this with me." The implementation details are left deliberately vague because the specifics depend on your domain, your tools, your scale, your preferences.

The power of publishing a pattern instead of a product is that it invites adaptation rather than adoption. Every implementation will be different because every knowledge domain is different.

If you've been frustrated with RAG, if you've felt that your AI tools forget everything the moment the conversation ends, if you've abandoned Notion databases and Obsidian vaults because the maintenance was crushing — Karpathy just gave you a blueprint for making the LLM do the maintenance.

The human curates sources, directs analysis, asks good questions, and thinks about meaning. The LLM handles everything else.

Vannevar Bush would be proud.

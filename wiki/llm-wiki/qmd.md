# qmd — Local Hybrid Search for Markdown Knowledge Bases

> Sources: tobi (Tobias Lütke), Unknown
> Raw: [qmd-local-search-engine](../../raw/llm-wiki/qmd-local-search-engine.md)
> Updated: 2026-04-17

## Overview

qmd is an open-source, fully local CLI search engine for personal markdown knowledge bases. It stacks three retrieval techniques — BM25 full-text search (SQLite FTS5), vector semantic search (EmbeddingGemma 300M), and LLM re-ranking (Qwen3 0.6B) — into a single hybrid query pipeline. All processing runs on-device via node-llama-cpp; no cloud API calls are made at any stage. Beyond the CLI, qmd exposes a JavaScript/TypeScript SDK and an MCP server, making it usable as a native tool for AI agents. Karpathy recommends it in his LLM Wiki gist as an optional search layer once a wiki grows beyond what a flat index can navigate. Stars: 22k+.

## What Problem It Solves

At small wiki scale (tens of articles), reading the index file and drilling into relevant pages is sufficient. As a wiki grows into hundreds or thousands of articles, that approach breaks down: the index becomes too long to scan, and the LLM cannot hold it all in context alongside the articles it needs. qmd fills this gap without introducing any cloud dependency or RAG retrieval-at-query-time overhead — the wiki stays compiled, and qmd provides navigation into it.

## Search Pipeline

A hybrid `query` command runs the following stages in sequence:

1. **Query Expansion** — A fine-tuned Qwen3 1.7B model generates query variations to improve recall beyond the literal terms.
2. **Parallel Retrieval** — BM25 (FTS5) and vector searches run simultaneously.
3. **Reciprocal Rank Fusion** — Results from both indexes are merged using position-aware RRF weighting.
4. **LLM Re-ranking** — Qwen3 0.6B reranker scores each candidate document with a yes/no judgment and logprobs-derived confidence.
5. **Position-Aware Blending** — Final ranking adjusts weights by rank position before returning results.

The simpler commands `search` (BM25 only) and `vsearch` (vector only) bypass the LLM stages when the full pipeline is unnecessary.

## Chunking

Documents are split at ~900 tokens with 15% overlap. The splitter identifies natural break points — headings, code blocks, paragraph boundaries — and scores them by semantic significance before cutting. For code files, an AST-aware mode uses tree-sitter to chunk at function and class boundaries (TypeScript, JavaScript, Python, Go, Rust supported).

## Models

Three GGUF models download automatically on first use and run locally via node-llama-cpp:

| Model | Role | Size |
|---|---|---|
| embeddinggemma-300M | Vector embeddings | ~300 MB |
| qwen3-reranker-0.6b | Re-ranking | ~640 MB |
| qmd-query-expansion-1.7B | Query expansion | ~1.1 GB |

An alternative multilingual embedding model (Qwen3-Embedding-0.6B) is available for CJK language support. All models are stored in `~/.cache/qmd/models/`.

## Installation and Setup

```bash
npm install -g @tobilu/qmd
# or
bun install -g @tobilu/qmd
```

Requires Node.js >= 22 or Bun >= 1.0.0. macOS users need Homebrew SQLite (`brew install sqlite`).

Collection setup:

```bash
qmd collection add ~/notes --name notes
qmd context add qmd://notes "Personal notes and ideas"
qmd embed
```

The index is stored at `~/.cache/qmd/index.sqlite`.

## CLI Commands

```bash
qmd search "authentication"       # BM25 keyword search
qmd vsearch "how to login"        # Vector similarity search
qmd query "user authentication"   # Full hybrid pipeline

qmd get "docs/readme.md"          # Retrieve a document by path
qmd get "#abc123"                 # Retrieve by docid
qmd multi-get "journals/2025-05*.md"  # Glob retrieval
```

Output format flags: `--json`, `--csv`, `--md`, `--xml`, `--files`. Additional flags: `--full`, `--explain`, `--line-numbers`.

## SDK

qmd ships a JavaScript/TypeScript SDK for programmatic integration:

```javascript
import { createStore } from '@tobilu/qmd'

const store = await createStore({
  dbPath: './my-index.sqlite',
  config: {
    collections: {
      docs: { path: '/path/to/docs', pattern: '**/**.md' },
    },
  },
})

const results = await store.search({ query: "authentication flow" })
```

Key methods: `search()`, `searchLex()`, `searchVector()`, `get()`, `multiGet()`, `addCollection()`, `update()`, `embed()`.

## MCP Server

qmd exposes a Model Context Protocol server that integrates with Claude Desktop and other MCP-compatible runtimes:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

For long-lived sessions: `qmd mcp --http --daemon`. Exposed MCP tools: `query`, `get`, `multi_get`, `status`.

This makes qmd usable as a native tool inside an LLM agent session — the agent can issue `query` calls directly rather than shelling out to the CLI.

## Relation to the LLM Wiki Pattern

The LLM Wiki pattern is compile-once synthesis: sources are ingested into structured wiki articles at write time, and queries read from the pre-compiled knowledge. qmd operates at the navigation layer, not the retrieval layer — it helps the LLM find the right compiled articles when the index is too large to scan in one pass. The two are complementary: the wiki stays the authoritative compiled knowledge store; qmd is a cursor into it. This is distinct from traditional RAG, which retrieves raw document chunks at query time and synthesizes on the fly.

## See Also

- [LLM Wiki Pattern](llm-wiki-pattern.md)

# QMD: Query Markup Documents

> Source: https://github.com/tobi/qmd
> Collected: 2026-04-17
> Published: Unknown

QMD is a local CLI search engine for markdown knowledge bases, notes, and documentation. It combines BM25 full-text search (SQLite FTS5), vector semantic search (EmbeddingGemma 300M), and LLM re-ranking (Qwen3 0.6B), all running entirely on-device with no cloud calls. It also exposes a JavaScript SDK and an MCP server for AI agent integration. Stars: 22k+; Forks: 1.4k. Author: tobi (Tobias Lütke). License: MIT.

## What it does

Indexes markdown files and documents into a local SQLite database, then enables searching through three modes:

- **search** — BM25 keyword full-text retrieval
- **vsearch** — Vector similarity matching
- **query** — Hybrid combining both, with LLM query expansion and re-ranking

## Technical Architecture

### Search Pipeline

1. **Query Expansion** — Fine-tuned Qwen3 model generates query variations to improve recall
2. **Parallel Retrieval** — Searches both FTS5 (SQLite full-text) and vector indexes simultaneously
3. **Reciprocal Rank Fusion** — Combines results using RRF with position-aware weighting
4. **LLM Re-ranking** — Qwen3 reranker scores each document (yes/no with logprobs confidence)
5. **Position-Aware Blending** — Adjusts weight distribution based on rank position

### Chunking Strategy

Documents are segmented using intelligent boundary detection at ~900 tokens with 15% overlap. The algorithm identifies natural break points (headings, code blocks, paragraph boundaries) and scores them based on semantic significance.

For code files, an AST-aware option uses tree-sitter to chunk at function and class boundaries, supporting TypeScript, JavaScript, Python, Go, and Rust.

### Models

Three GGUF models auto-downloaded on first use:

- **embeddinggemma-300M** — Vector embeddings (~300MB)
- **qwen3-reranker-0.6b** — Re-ranking (~640MB)
- **qmd-query-expansion-1.7B** — Query expansion (~1.1GB)

Alternative multilingual embedding: Qwen3-Embedding-0.6B for CJK language support.

All models run locally via node-llama-cpp. No internet connection required after download. Models stored in `~/.cache/qmd/models/`.

## Installation

```bash
npm install -g @tobilu/qmd
# or
bun install -g @tobilu/qmd
```

Requirements: Node.js >= 22 or Bun >= 1.0.0. macOS users need Homebrew SQLite (`brew install sqlite`).

## CLI Usage

### Collection Setup

```bash
qmd collection add ~/notes --name notes
qmd context add qmd://notes "Personal notes and ideas"
qmd embed
```

### Searching

```bash
qmd search "authentication"       # BM25 only
qmd vsearch "how to login"        # Vector only
qmd query "user authentication"   # Hybrid + re-ranking
```

### Retrieval

```bash
qmd get "docs/readme.md"
qmd get "#abc123"                 # By docid
qmd multi-get "journals/2025-05*.md"
```

Output format flags: `--json`, `--csv`, `--md`, `--xml`, `--files`. Display flags: `--full`, `--explain`, `--line-numbers`.

## SDK/Library Usage

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

Key SDK methods: `search()`, `searchLex()`, `searchVector()`, `get()`, `multiGet()`, `addCollection()`, `update()`, `embed()`.

## MCP Server Integration

QMD exposes a Model Context Protocol server compatible with Claude Desktop:

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

HTTP transport for long-lived servers: `qmd mcp --http --daemon`

Exposed MCP tools: `query`, `get`, `multi_get`, `status`.

## Data Storage

Index stored in `~/.cache/qmd/index.sqlite`. Schema includes: collections, documents, FTS5 full-text index, vector embeddings, LLM cache.

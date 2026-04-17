# qmd Wiki Install — Design

**Date:** 2026-04-17
**Scope:** Wire qmd into this Codespace as a local hybrid-search layer over the existing LLM wiki, without changing how the wiki itself is compiled, queried, or linted. Deliberately narrow — this install is additive, leaves SKILL.md and CLAUDE.md untouched, and does not alter any subagent's prompt surface.

## What we're doing

The wiki is already working. Ingest, Query, and Lint write and maintain compiled markdown under `wiki/<topic>/` from raw sources captured in `raw/<topic>/`. At current scale (four topics — `claude-code`, `github-copilot`, `llm-wiki`, `openclaw` — and eleven articles excluding per-topic `index.md` files) a flat read of `wiki/index.md` plus per-topic indexes is plenty. Karpathy's own guidance in the LLM Wiki gist is that qmd becomes useful once the index is too large to scan in one pass — so this install is an investment in the next phase, not a fix for a current pain point. It also validates the wiki ↔ qmd boundary now, while the wiki is small enough to re-embed cheaply, rather than later under load.

qmd is a fully local CLI, SDK, and MCP server that indexes markdown with SQLite FTS5, generates vectors with EmbeddingGemma 300M, and re-ranks with Qwen3 0.6B. All three models run on-device via node-llama-cpp. Its output surface — `query`, `search`, `vsearch`, `get`, `multi_get`, `status` — becomes a new tool Claude Code can use during Query operations. The wiki's three operations do not change.

## What qmd owns vs. what the wiki owns

The wiki owns the compiled knowledge: raw captures live in `raw/`, compiled articles live in `wiki/<topic>/`, and the write path is controlled by SKILL.md and the three subagents already in place. qmd never writes to `wiki/` or `raw/`. It only reads. Its own state — the SQLite index and the downloaded GGUF models — lives in `~/.cache/qmd/`, outside the repo, per-user, not committed.

qmd owns the navigation layer: given a natural-language query it returns ranked passages with paths and scores. The agent uses those paths to decide what to read. Compiled articles are still the answer surface; qmd is the cursor. This is distinct from RAG-at-query-time: qmd does not synthesize answers, and the agent does not answer from raw chunks — the compiled article remains authoritative. The wiki-vs-raw boundary is maintained by prompt policy (CLAUDE.md and the agent's framing of the Query operation), not by anything qmd enforces. Both `wiki/` and `raw/` are in the index so that a gap in the compiled wiki is discoverable — the agent can find "there's a source on this topic" even before a compiled article exists.

## What this install changes in the repo

Six artifacts, all under `.claude/` or `scripts/`.

**`scripts/qmd-bootstrap.sh`** is new. It runs the qmd setup end-to-end for this Codespace: install the npm package globally, register two collections (`wiki` pointing at `/workspaces/karpathy-llm-wiki/wiki/` and `raw` pointing at `/workspaces/karpathy-llm-wiki/raw/`), attach one-line context metadata to each, and run the initial `qmd embed`. Because qmd's README does not document what `qmd collection add` does when a collection name already exists, and there is no `--force` flag shown, the script is written as fresh-install-only: a pre-flight check uses `qmd collection list` to see whether the `wiki` collection is already registered, and if so exits with a message rather than attempting to reconcile. The header comment says the script is meant for a clean install; re-running against existing state is out of scope until qmd's behavior there is documented.

**`.claude/settings.json`** gains one addition and a handful of permission patterns. The MCP entry `mcpServers.qmd` points at `qmd mcp` using stdio transport — the default. Project-scoped so anyone cloning the repo inherits the wiring without touching user-level settings. The permissions additions cover the commands the hook and manual workflows need: `Bash(qmd update)`, `Bash(qmd embed)`, `Bash(qmd query:*)`, `Bash(qmd search:*)`, `Bash(qmd vsearch:*)`, `Bash(qmd status)`, and `Bash(qmd collection list)`. Same per-command style already in use for the rest of the allow list.

**`.claude/hooks/wiki-ingester-done.sh`** is extended. After its existing log-and-notify block, it appends a refresh step that runs `qmd update` followed by `qmd embed`. Exit codes of both steps are captured to the log; neither failure propagates to the outer hook, so an embedding failure cannot retroactively fail the ingest. The subagent's prompt is not touched — the refresh is pure infrastructure, invisible from the wiki-ingester's perspective.

**`.claude/prompts/qmd-wiki-integration.md`** gets rewritten to match the install as built. Scope (two collections: `wiki/` + `raw/`), wiring (project-scoped MCP, stdio transport), refresh (hook-based, `update && embed`), bootstrap command, and a proof-query recipe. This is the designated repo artifact for this install per prior project direction; SKILL.md, CLAUDE.md, `references/`, and the agent definitions stay untouched.

**`.gitignore`** needs no change. `.claude/logs/` is already ignored (line 13), `scripts/` is not in the ignore list so the bootstrap script tracks automatically, and qmd's index and models live in `~/.cache/qmd/` outside the repo entirely.

Six artifacts; nothing else.

## How the three flows behave

**Setup runs once.** A user (or a fresh Codespace) runs `bash scripts/qmd-bootstrap.sh`. The script installs qmd, registers collections, embeds the current corpus. First embed downloads roughly 2 GB of GGUF models into `~/.cache/qmd/models/` and processes every markdown file under `wiki/` and `raw/`. The operation is slow on first run — minutes, not seconds — and fast after, because subsequent embeds only touch chunks flagged by `qmd update` as needing re-embedding.

**Ingest stays the shape it has today.** The main session spawns the `wiki-ingester` subagent, which writes `raw/<topic>/<slug>.md`, `wiki/<topic>/<article>.md`, updates the per-topic `index.md`, and appends to `wiki/log.md`. On subagent exit, the existing `Stop` hook fires. Its existing responsibilities (log `last_assistant_message`, emit a truncated `systemMessage`) are unchanged. After those, the hook runs `qmd update` — which re-scans both collections, picks up the new files, and flags chunks needing embedding — and then `qmd embed`, which generates vectors only for the flagged delta. The refresh is cheap after the first run because the delta is small. A failed embed is logged but does not fail the ingest; the wiki state is fine, qmd is stale until the next successful refresh. Recovery is `qmd update && qmd embed` run manually.

**Query goes through MCP.** The agent calls the `query` tool on the `qmd` MCP server. Because the MCP entry uses stdio transport (not the HTTP daemon), each call spawns a fresh `qmd mcp` process, which reloads models. Per-call reload is observable — noticeable latency on each MCP query — and is the price we pay for not running a long-lived daemon. If that becomes a friction point we add `qmd mcp --http --daemon` later; for now the simpler stdio path is enough, matches qmd's default, and avoids background-process management. Once the server is up for a call, the hybrid pipeline runs: query expansion, parallel BM25 + vector, reciprocal rank fusion, re-ranking, position-aware blending. Ranked passages come back; the agent reads files with `Read` or `qmd get` and answers from compiled articles.

## Verification

The install is verified by a short sequence of concrete checks. The version check `qmd --version` confirms the package installed. `qmd collection list` must show two collections named `wiki` and `raw` with non-zero document counts roughly matching `find wiki -name '*.md' | wc -l` and `find raw -name '*.md' | wc -l`. `qmd status` must report no pending embeddings after the initial `qmd embed` completes. MCP registration is verified by calling the qmd MCP `status` tool directly from a fresh Claude Code session — if the tool responds, the wiring is correct; no reliance on the `/mcp` slash command specifically. A proof query — `qmd query "llm wiki pattern"` via CLI, and the equivalent MCP call from Claude Code — must return `wiki/llm-wiki/llm-wiki-pattern.md` somewhere in the ranked results (the file appearing in the returned set is the pass condition; exact rank is not — re-ranking is probabilistic and tightening the pass condition would make this test brittle). An ingest-refresh smoke test — ingest a small source and then `qmd get <new-article-path>` — must return the new article, proving the hook ran `update && embed` successfully on the live delta.

## What is deliberately out of scope

No HTTP daemon (`qmd mcp --http --daemon`) — we start on stdio, add the daemon only if per-call reload becomes a friction point. No tests for qmd itself — that's upstream's concern. No auto-retry on hook refresh failure — a stale qmd is recoverable manually and a retry loop would complicate the hook beyond its worth. No alerting when qmd goes stale beyond the hook log. No user-level settings changes. No CI. No changes to SKILL.md, `references/`, CLAUDE.md, or any of the three agent definitions. No schema work on the prompts file beyond the one rewrite of `qmd-wiki-integration.md`. No multilingual embedding model — the default EmbeddingGemma 300M matches the current English corpus.

Each of these can become a follow-up spec when there is a concrete reason to do the work.

## Risks and the shape of easy mistakes

The boundary between wiki and qmd is the load-bearing claim of this design. If a future edit threads qmd calls into the write path — say, a subagent that calls `qmd query` during ingest to decide cross-references — the pattern's "compile at ingest, don't retrieve at query" invariant silently weakens. The right place to catch this is the wiki-ingester prompt: if anyone proposes adding qmd tools to it, that's a design change, not a small edit.

The hook's error-swallowing is deliberate and worth understanding. The cost of letting a `qmd embed` failure fail the ingest is that a transient qmd problem would corrupt the ingest user experience — the article would be written, the log would be updated, but the hook would report failure. That's worse than a silent staleness. The hook logs both step exit codes so that staleness is inspectable after the fact. If staleness ever turns out to matter more than ingest robustness, we flip the tradeoff.

Bootstrap idempotency is the third caveat. The script is honest about being fresh-install-only. If we ever need to re-register collections cleanly (moving the repo, changing paths), the current script will refuse to run. That's acceptable now; it becomes annoying if we install this in multiple repos or re-path often. A later revision can add a `--force` or `--refresh` mode once we've observed qmd's actual duplicate-add behavior.

## Files the implementation plan will create or change

- `scripts/qmd-bootstrap.sh` — new
- `.claude/settings.json` — add `mcpServers.qmd` block; add seven Bash permission patterns
- `.claude/hooks/wiki-ingester-done.sh` — append refresh block after existing logic
- `.claude/prompts/qmd-wiki-integration.md` — rewrite contents to match install as built
- `docs/superpowers/specs/2026-04-17-qmd-wiki-install-design.md` — this file (will be committed before the plan is written)

No other files touched. No `.gitignore` change, no SKILL.md / CLAUDE.md / `references/` edits, no subagent definitions modified, no wiki or raw content written.

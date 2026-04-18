# qmd + Wiki — Workflow Guide

A practical walkthrough of how the two halves of this repo's knowledge system work together.

## The two halves

**The wiki** is your compiled knowledge. Raw sources go into `raw/<topic>/`, compiled markdown articles live in `wiki/<topic>/`, and the agent maintains both per the rules in `SKILL.md`. The wiki is where you read and where the agent answers from. It's version-controlled markdown — nothing fancy.

**qmd** is a local hybrid-search layer over that markdown. It builds a SQLite index (BM25 + vector embeddings) over `wiki/` and `raw/`, runs entirely on your machine via node-llama-cpp, and exposes the index through a CLI, a JS/TS SDK, and an MCP server. It reads your wiki — it never writes to it.

Think of the wiki as the encyclopedia and qmd as the search box on top of it.

## When to use what

| Situation | Reach for |
|---|---|
| You want to **add** new knowledge from a source (URL, doc, notes) | Wiki Ingest (`wiki-ingester` subagent) |
| You want to **ask** a question and get an answer synthesized from existing wiki content | qmd (via MCP `query` tool, or `qmd query` CLI) |
| You want to **discover** whether your wiki already covers a topic | qmd (searches both `wiki/` and `raw/`) |
| You want to **maintain** — find contradictions, orphans, stale claims | Wiki Lint (`wiki-linter` subagent) |
| You want to **archive** a query result as a new wiki page | Wiki Query → Archive step |

The split is intentional. qmd makes the wiki findable as it grows; it does not replace the compile-at-ingest pattern the wiki relies on.

## Daily usage

### Adding something new (Ingest)

Ask Claude to ingest a source. Example:

> "Ingest https://example.com/some-docs into the `tools` topic"

The wiki-ingester subagent fetches the URL, writes a raw capture into `raw/tools/<date>-<slug>.md`, writes a compiled article into `wiki/tools/<slug>.md`, cascade-updates other articles in that same topic when they should cross-link, updates `wiki/tools/index.md`, and appends one line to `wiki/log.md`.

**After the subagent finishes**, the Stop hook at `.claude/hooks/wiki-ingester-done.sh` automatically runs:

```bash
qmd update && qmd embed
```

This re-scans the filesystem, flags any new or changed chunks, and generates vectors for those flagged chunks only. Outcome is logged to `.claude/logs/wiki-ingester.log`. A failure does not fail the ingest — you just get a stale qmd index, which you can refresh manually any time:

```bash
qmd update && qmd embed
```

### Asking a question (Query via qmd)

In a Claude Code session, when the MCP server `qmd` is connected, Claude can call `query` directly without shelling out:

> "What do we know about MCP in Claude Code?"

Claude will invoke `mcp__qmd__query` with appropriate search types (lex for exact keywords, vec for semantic, hyde for a hypothetical-answer prompt), read the top-ranked files, and synthesize an answer from the compiled `wiki/` articles.

From a terminal, the CLI equivalents are:

```bash
qmd search "\"exact phrase\" term -exclude"           # BM25 keyword
qmd vsearch "how does the ingest hook work"           # vector semantic
qmd query "hook refresh after ingest"                 # full hybrid pipeline
```

Add `-c wiki` to scope to compiled articles only. Add `--json` for structured output. Add `--min-score 0.5` to filter low-confidence results.

The proof query we verified at install time:

```bash
qmd query "llm wiki pattern"
# → wiki/llm-wiki/llm-wiki-pattern.md at rank 1 (score 0.93)
```

### Retrieving a specific file

```bash
qmd get qmd://wiki/claude-code/mcp.md
qmd get "#abc123"                                      # by docid
qmd multi-get "wiki/claude-code/*.md"                  # glob retrieval
```

### Maintenance (Lint)

Spawn the `wiki-linter` subagent. It checks:

- **Deterministic** (auto-fixed): index consistency, internal link validity, `raw/` reference validity, obvious missing See Also cross-references within the same topic.
- **Heuristic** (reported only): factual contradictions, stale claims, orphan pages, missing cross-topic connections.

Lint writes a line to `wiki/log.md` summarizing the pass. Run it periodically as the wiki grows.

## The boundary: `wiki/` versus `raw/` at query time

qmd indexes both collections, so both are searchable. **Answers should come from compiled `wiki/` articles, not from `raw/` chunks.** The `raw/` collection is indexed so you can discover *whether* source material exists on a topic — useful when the compiled wiki doesn't cover something yet and you want to know what sources to pull from.

This boundary is prompt policy, enforced by convention (CLAUDE.md + `.claude/rules/qmd-wiki.md`). qmd will cheerfully return raw chunks if they rank highly — it's on the agent and the user to prefer compiled answers.

## How the pieces are wired

| Piece | File / location |
|---|---|
| qmd install script | `scripts/qmd-bootstrap.sh` |
| MCP registration (project-scoped) | `.mcp.json` at repo root |
| MCP auto-approval | `.claude/settings.json` → `enabledMcpjsonServers: ["qmd"]` |
| Bash permission patterns | `.claude/settings.json` → `permissions.allow` (seven `Bash(qmd ...)` entries) |
| Post-ingest refresh hook | `.claude/hooks/wiki-ingester-done.sh` (runs `qmd update && qmd embed`) |
| As-built install notes | `.claude/prompts/qmd-wiki-integration.md` |
| Agent behavioral rule | `.claude/rules/qmd-wiki.md` (auto-loaded every session) |
| Install spec | `docs/superpowers/specs/2026-04-17-qmd-wiki-install-design.md` |
| Install plan | `docs/superpowers/plans/2026-04-17-qmd-wiki-install.md` |

qmd itself stores state outside the repo at `~/.cache/qmd/` — one SQLite index plus three GGUF models (~2.25 GB). Per-user, per-machine, never committed.

## Re-installing or resetting

The bootstrap script is fresh-install only. If you want to reset:

```bash
qmd collection remove wiki
qmd collection remove raw
bash scripts/qmd-bootstrap.sh
```

Or nuke everything including models:

```bash
rm -rf ~/.cache/qmd/
bash scripts/qmd-bootstrap.sh
```

## Scaling notes

- At current scale (a few dozen articles) you can read `wiki/index.md` plus per-topic indexes manually. qmd is overkill for navigation but still useful for semantic queries.
- Around ~100 articles (Karpathy's reported scale) the flat index becomes unwieldy. qmd earns its keep — the agent lands on the right 2–3 files in one shot instead of scanning.
- At ~1000+ articles the hybrid pipeline (BM25 + vector + re-ranker) is what keeps search precise. The re-ranker is the expensive stage on CPU (~60s first call; subsequent calls are warm); consider the HTTP daemon (`qmd mcp --http --daemon`) if per-call reload latency matters.

## Troubleshooting

**"qmd query returned nothing useful."**
Try different search types. If you know the exact terms, use `qmd search` (BM25). If you want meaning, use `qmd vsearch`. For nuanced topics, use `qmd query` with all three. Pass `intent` on MCP calls to disambiguate.

**"qmd doesn't know about my latest ingest."**
Check `.claude/logs/wiki-ingester.log` for the `qmd refresh:` line after the most recent ingest. If it failed, run manually:

```bash
qmd update && qmd embed
```

**"MCP tool not visible in Claude Code."**
Check `/mcp` in Claude Code. If `qmd` isn't listed, verify `.mcp.json` exists at repo root and `enabledMcpjsonServers: ["qmd"]` is in `.claude/settings.json`. Restart Claude Code after either file changes.

**"Query is slow."**
First call with re-ranking enabled loads all three models into memory (~60s). Subsequent calls are warm. For CPU-only machines, pass `rerank: false` on the MCP call to skip the re-ranker stage — results rely on BM25 + vector fusion only, which is much faster.

## Further reading

- `wiki/llm-wiki/llm-wiki-pattern.md` — the LLM Wiki pattern (compile-at-ingest, not retrieve-at-query).
- `wiki/llm-wiki/qmd.md` — deeper qmd architecture notes.
- `SKILL.md` — canonical spec of Ingest / Query / Lint operations.
- [qmd upstream](https://github.com/tobi/qmd) — official docs and SDK reference.
- [Claude Code memory docs](https://code.claude.com/docs/en/memory) — `.claude/rules/` and `CLAUDE.md` semantics.

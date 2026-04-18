# Using qmd for knowledge questions

This repo has a local qmd MCP server indexing `wiki/` (compiled articles) and `raw/` (source captures). Four tools: `mcp__qmd__query`, `mcp__qmd__get`, `mcp__qmd__multi_get`, `mcp__qmd__status`.

## Default behavior

When the user asks a question that could plausibly be answered from the wiki or past-ingested sources, call `mcp__qmd__query` first before falling back to Read/Grep/Glob. Always include an `intent` string — it sharpens snippet selection even though it doesn't search on its own.

Scope to `collections: ["wiki"]` when synthesizing an answer — compiled articles are the answer surface. Leave collections unscoped when exploring whether the repo has *any* material on a topic (including un-compiled raw sources).

## Shape the query to the question

Pick sub-query types deliberately. First sub-query gets 2× weight, so lead with the strongest signal.

**Exact names, verbatim phrases the user said, specific symbols:** lex alone.

```json
{"searches": [{"type":"lex", "query":"\"wiki-ingester\" hook"}], "intent":"how the post-ingest refresh hook is wired"}
```

Lex supports `"exact phrase"`, `-negation`, and prefix matching on bare terms (`perf` → `performance`).

**How-does-X-work, conceptual questions, paraphraseable intent:** vec alone or lex+vec.

```json
{"searches":[
  {"type":"lex", "query":"MCP stdio transport"},
  {"type":"vec", "query":"how is the qmd MCP server registered and auto-approved"}
], "intent":"mcp wiring in this repo"}
```

**Nuanced / open-ended questions where exact vocabulary is unclear:** add a hyde sub-query — write 50–100 words of what the answer actually looks like.

```json
{"searches":[
  {"type":"lex", "query":"\"if\" branch \"set -e\" hook"},
  {"type":"vec", "query":"hook failure handling in bash strict mode"},
  {"type":"hyde", "query":"Inside a bash script with set -euo pipefail, placing a command inside an if condition prevents a non-zero exit from terminating the script. The if treats the condition's exit status as handled, so failures can be logged without propagating."}
], "intent":"why does the qmd refresh block use if-wrapping"}
```

## Filters and limits

- **`limit`** defaults to 10; bump to 20 if the first pass misses obvious hits.
- **`minScore`** filters low-confidence noise. Start without it; add `0.5` if the top hits feel tangential.
- **`candidateLimit`** (default 40) caps how many candidates go to the re-ranker. Lower it (e.g., 20) on CPU-only boxes when speed matters more than exhaustive recall.
- **`rerank: false`** skips the LLM re-ranker stage. On this CPU-only Codespace the first rerank call is ~60s (models load); subsequent calls are warm. Use `false` for quick lookups, keep it on (default) when the user is waiting on quality.

## Reading results

qmd returns an array of `{docid, score, file, title, context, snippet}`. The `file` is a `qmd://<collection>/<path>` URI — strip the prefix to get the repo-relative path. The `snippet` uses `@@ -LINE,OFFSET @@` format with a few lines of context above/below the match. Use the line number to jump directly:

```
mcp__qmd__get({ file: "qmd://wiki/claude-code/mcp.md", fromLine: 38, maxLines: 30 })
```

Batch retrieval by glob when a topic is multi-file:

```
mcp__qmd__multi_get({ file: "wiki/claude-code/*.md" })
```

## Query iteration

If the first query misses:

1. **Widen scope** — remove `collections`, remove `minScore`, bump `limit`.
2. **Re-shape** — if you started with lex and got nothing, switch to vec; if vec returned drift, add lex with the user's exact terms; if both miss, add hyde.
3. **Drop rerank** — sometimes the re-ranker's judgment hides a good BM25 hit. Try `rerank: false` to see the fusion output.
4. **Check coverage** — run `mcp__qmd__status` or a broad query to confirm the topic really isn't in the index. If only `raw/` has hits and `wiki/` doesn't, that's a real gap — tell the user and offer to ingest.

## Scope escalation

Start narrow, widen until you find something or confirm absence. The order:

1. `collections: ["wiki"]` — compiled articles only. Answer surface.
2. No `collections` scope — both wiki and raw. Use when you suspect the user wants to know if there's a source to ingest.
3. Direct Read/Grep on specific paths — only when qmd confirms a gap or the user is asking about a specific file.

Do not silently fall back to Read/Grep when qmd returns nothing. Say "qmd didn't surface relevant results — checking files directly" so the user sees the retrieval miss.

## When answering

- Cite paths project-root-relative (e.g. `wiki/claude-code/mcp.md`), not `qmd://` URIs.
- Prefer content from `wiki/` compiled articles. If the only hits are from `raw/`, say so explicitly and suggest the user may want a compiled article.
- Read the actual file before claiming it answers the question. The score is a relevance signal, not a correctness guarantee.

## Don'ts

- Don't run `qmd update` or `qmd embed` manually during or right after a wiki-ingester run. The `.claude/hooks/wiki-ingester-done.sh` Stop hook already refreshes the index automatically.
- Don't synthesize answers from `raw/` chunks when the same topic is covered in `wiki/`. Prefer compiled.
- Don't over-ask the re-ranker. 20 candidates is plenty for most questions on this corpus; 40 is the default ceiling.
- Don't pass a one-word `intent` like "stuff" or "things". It should disambiguate the query — a short sentence about what the user actually wants to know.

## Pointers

- Human workflow guide (you can send the user here): `docs/qmd-wiki-workflow.md`
- As-built install notes (file paths, wiring details): `.claude/prompts/qmd-wiki-integration.md`
- Wiki operation semantics: `SKILL.md`

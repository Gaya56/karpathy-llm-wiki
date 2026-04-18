# karpathy-llm-wiki (with qmd)

A personal LLM wiki you can clone, install with one script, and start using with Claude Code in a few minutes. Built on two open-source projects stacked together: the wiki pattern skill for compiling knowledge into durable markdown, and qmd for searching that markdown locally with hybrid BM25 + vector + re-ranking — no cloud calls.

## Install (fresh clone)

Four steps. Works on Linux, macOS, and Windows under WSL.

1. **Clone this repo** and `cd` into it. The bootstrap script auto-detects its own location, so the clone path doesn't matter.

   ```bash
   git clone https://github.com/Astro-Han/karpathy-llm-wiki.git
   cd karpathy-llm-wiki
   ```

2. **Run the bootstrap.** This installs the qmd CLI globally, registers two collections (`wiki/` and `raw/`) pointing at this repo, attaches context metadata, and triggers the first embed — which downloads ~2.25 GB of GGUF models on first run. macOS users: run `brew install sqlite` first (qmd requires Homebrew SQLite).

   ```bash
   bash scripts/qmd-bootstrap.sh
   ```

3. **Open Claude Code** in this directory. On startup it reads `CLAUDE.md` (which points at the qmd + wiki workflow docs) and auto-loads the behavioral rule at `.claude/rules/qmd-wiki.md`. The qmd MCP server is pre-approved via `enabledMcpjsonServers` in `.claude/settings.json`.

4. **Ingest your first source.** Claude's wiki-ingester subagent handles the workflow — writes a raw capture, compiles a wiki article, updates the index, and the Stop hook automatically refreshes the qmd index.

   > "Ingest https://example.com/some-docs into topic `my-topic`"

After that, any knowledge question goes through `mcp__qmd__query` first — scoped to the wiki collection by default — and Claude answers from the compiled articles it finds.

## Built on

Two upstream open-source projects. Both are actively maintained and stable.

| Upstream | What it provides |
|---|---|
| [Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki) | The wiki pattern skill itself — Ingest / Query / Lint operations, file-format templates, agent prompts. Canonical spec lives in `SKILL.md` with reference formats in `references/`. Based on [Karpathy's LLM Wiki idea](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). |
| [tobi/qmd](https://github.com/tobi/qmd) | A fully local hybrid-search CLI, SDK, and MCP server for markdown knowledge bases. Stacks SQLite FTS5 (BM25) + vector embeddings (EmbeddingGemma 300M) + LLM re-ranking (Qwen3 0.6B), all on-device via node-llama-cpp. |

The wiki pattern handles *how knowledge is authored and maintained*. qmd handles *how knowledge is found at query time*. They compose cleanly because qmd is read-only: it indexes the markdown the wiki produces without ever writing back.

## Who it's for

- **You, on a new machine.** Clone, run one script, everything works — no manual path edits, no per-machine configuration, no cloud dependencies.
- **A dev evaluating the setup.** The file layout below shows what each piece does and where it lives, so the whole system is readable in under ten minutes.
- **Anyone who wants their own LLM wiki.** Fork this, point the collections at your own paths, ingest your own sources. The two upstream projects do all the heavy lifting; this repo is an opinionated wiring.

## How the two layers fit together

| Layer | Files in this repo | Role |
|---|---|---|
| **Wiki pattern (upstream skill)** | `SKILL.md`, `references/*.md`, `.claude/agents/wiki-ingester.md`, `.claude/agents/wiki-linter.md`, `.claude/agents/skill-reviewer.md` | Defines the three operations (Ingest, Query, Lint), the file formats (raw, article, index, archive), and the subagents that run them. |
| **qmd search layer (installed by us)** | `scripts/qmd-bootstrap.sh`, `.mcp.json`, `.claude/settings.json` (enabledMcpjsonServers + qmd Bash perms), `.claude/hooks/wiki-ingester-done.sh` (refresh hook), `.claude/rules/qmd-wiki.md` (auto-loaded agent behavior) | Indexes `wiki/` and `raw/` into `~/.cache/qmd/index.sqlite`, exposes `query`/`get`/`multi_get`/`status` via MCP, auto-refreshes after each ingest via the Stop hook. |
| **Cross-cutting docs** | `docs/qmd-wiki-workflow.md` (human-facing workflow guide), `.claude/prompts/qmd-wiki-integration.md` (as-built install notes) | Explain how everything fits together for both humans and Claude. |

Not in the repo: qmd's own state — the SQLite index and ~2.25 GB of downloaded models — all lives outside the repo at `~/.cache/qmd/`, per-user, never committed.

## When to use `scripts/qmd-bootstrap.sh`

- **First clone.** This is the primary use case.
- **After a clean reset.** If you've run `rm -rf ~/.cache/qmd/` or `qmd collection remove wiki raw`, re-run the bootstrap.

The script is fresh-install-only — it refuses to run if the `wiki` or `raw` collections are already registered (to avoid silently overwriting state). It does not need to be re-run for normal daily use; the `.claude/hooks/wiki-ingester-done.sh` Stop hook automatically runs `qmd update && qmd embed` after every ingest, so the index stays current without manual intervention.

If you do need to manually refresh (e.g., after editing wiki files outside of an ingest):

```bash
qmd update && qmd embed
```

## Deeper reading

- `docs/qmd-wiki-workflow.md` — full workflow guide: when to use Ingest vs. Query, how to shape queries, troubleshooting, scaling notes.
- `.claude/rules/qmd-wiki.md` — pro-level behavioral rules for Claude when using qmd (concrete query JSON examples, filter guidance, scope escalation).
- `SKILL.md` — canonical spec for the wiki pattern's three operations.
- `wiki/llm-wiki/qmd.md` (once ingested) — deeper qmd architecture notes.

## License

MIT, inherited from the upstream skill.

# qmd ↔ wiki integration — as installed

This repo has qmd wired in as an optional local-search layer over the compiled wiki. The wiki itself is unchanged; qmd only reads.

## Scope

qmd indexes two collections from this repo:

- `wiki` — compiled articles under `wiki/<topic>/`
- `raw` — immutable source captures under `raw/<topic>/`

qmd never writes to the repo. Its index and downloaded GGUF models live at `~/.cache/qmd/` per-user, outside the repo.

## Install

```bash
bash scripts/qmd-bootstrap.sh
```

Fresh-install only. If `wiki` or `raw` collections already exist in qmd, the script refuses to run. First embed downloads ~2 GB of models and may take several minutes.

## Wiring

MCP server `qmd` is registered in `.mcp.json` at the repo root (Claude Code's project-scoped MCP config file) and pre-approved via `enabledMcpjsonServers: ["qmd"]` in `.claude/settings.json`. Transport is stdio (`qmd mcp` default). Exposed MCP tools: `query`, `get`, `multi_get`, `status`. No plugin install. No HTTP daemon.

## Refresh

After each wiki-ingester run, `.claude/hooks/wiki-ingester-done.sh` runs `qmd update` then `qmd embed`. Both run inside `if` branches so a failure does not trip `set -e`; outcomes are logged to `.claude/logs/wiki-ingester.log`. If qmd ever goes stale, run manually:

```bash
qmd update && qmd embed
```

## Query policy

Answers come from compiled articles under `wiki/`. The `raw` collection is searchable so topic gaps are discoverable, but the agent should not synthesize answers from raw chunks. This is prompt-policy, not qmd-enforced — `qmd query` will happily return raw passages if they rank highly.

## Proof query

```bash
qmd query "llm wiki pattern"
```

Should return `wiki/llm-wiki/llm-wiki-pattern.md` in the ranked results.

## Links

- Spec: `docs/superpowers/specs/2026-04-17-qmd-wiki-install-design.md`
- Plan: `docs/superpowers/plans/2026-04-17-qmd-wiki-install.md`
- qmd upstream: https://github.com/tobi/qmd
- LLM Wiki pattern: `wiki/llm-wiki/llm-wiki-pattern.md`
- qmd article: `wiki/llm-wiki/qmd.md`

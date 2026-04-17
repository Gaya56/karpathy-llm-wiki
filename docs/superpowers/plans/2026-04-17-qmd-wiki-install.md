# qmd Wiki Install — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install qmd as a fully local hybrid-search layer over the existing wiki, wired to Claude Code via a project-scoped MCP server, with post-ingest refresh in the wiki-ingester hook.

**Architecture:** qmd runs outside the wiki write path. Two named collections (`wiki`, `raw`) point at this repo's `wiki/` and `raw/` directories; qmd's index and models live in `~/.cache/qmd/` (per-user, outside the repo). MCP uses stdio (`qmd mcp`) registered in `.claude/settings.json`. Refresh (`qmd update && qmd embed`) fires from the existing `wiki-ingester-done.sh` Stop hook after each ingest; failures are logged but not raised. No wiki write-path code changes.

**Tech Stack:** qmd (npm package `@tobilu/qmd`), node-llama-cpp, SQLite FTS5, EmbeddingGemma 300M, Qwen3 0.6B reranker, Qwen3 1.7B query-expansion. Requires Node.js ≥22 or Bun ≥1.0.0.

**Spec:** `docs/superpowers/specs/2026-04-17-qmd-wiki-install-design.md`

---

## Task 1: Create the bootstrap script

**Files:**

- Create: `scripts/qmd-bootstrap.sh`

- [ ] **Step 1: Ensure scripts/ directory exists**

```bash
mkdir -p /workspaces/karpathy-llm-wiki/scripts
```

- [ ] **Step 2: Write the bootstrap script**

Write `/workspaces/karpathy-llm-wiki/scripts/qmd-bootstrap.sh` with this exact content:

```bash
#!/usr/bin/env bash
# qmd-bootstrap.sh — fresh-install of qmd for this Codespace.
# Fresh-install ONLY. If a qmd collection named "wiki" or "raw" is already
# registered, the script exits without touching qmd state. Re-register by
# hand if you need to reset:
#     qmd collection remove wiki
#     qmd collection remove raw
set -euo pipefail

REPO=/workspaces/karpathy-llm-wiki

# 1. Runtime preflight — Node.js >= 22 OR Bun >= 1.0
have_node22=false
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
  if [ "$NODE_MAJOR" -ge 22 ]; then
    have_node22=true
  fi
fi
have_bun=false
if command -v bun >/dev/null 2>&1; then
  have_bun=true
fi
if [ "$have_node22" = false ] && [ "$have_bun" = false ]; then
  echo "ERROR: qmd requires Node.js >=22 or Bun >=1.0" >&2
  echo "       node: $(command -v node || echo 'not found')" >&2
  echo "       bun:  $(command -v bun  || echo 'not found')" >&2
  exit 1
fi

# 2. Install qmd if not present
if ! command -v qmd >/dev/null 2>&1; then
  echo "Installing @tobilu/qmd globally..."
  if [ "$have_bun" = true ]; then
    bun install -g @tobilu/qmd
  else
    npm install -g @tobilu/qmd
  fi
fi
echo "qmd version: $(qmd --version)"

# 3. Fresh-install guard — refuse to run if our collection names already exist.
# NOTE: `qmd collection list` output format is not documented as machine-
# readable (no --json flag on this subcommand), so this grep is best-effort.
# If it false-positives on a collection name that merely contains "wiki" or
# "raw" as a substring, remove our collections manually and re-run.
if qmd collection list 2>/dev/null | grep -qwE '(wiki|raw)'; then
  echo "ERROR: a qmd collection named 'wiki' or 'raw' is already registered." >&2
  echo "       This script is fresh-install only. Remove them first:" >&2
  echo "         qmd collection remove wiki" >&2
  echo "         qmd collection remove raw" >&2
  exit 1
fi

# 4. Register collections — restrict to markdown so we don't index images,
# DS_Store, JSON raw sidecars, etc. Upstream default mask is undocumented,
# so we pin it explicitly.
qmd collection add "$REPO/wiki" --name wiki --mask "**/*.md"
qmd collection add "$REPO/raw"  --name raw  --mask "**/*.md"

# 5. Attach context metadata (qmd:// URI form per qmd docs)
qmd context add qmd://wiki "Compiled LLM wiki articles maintained by the karpathy-llm-wiki skill. Queries should prefer these over raw sources."
qmd context add qmd://raw  "Immutable raw source captures. Used to discover whether a topic has source material, not for synthesis."

# 6. Initial embed — downloads ~2 GB of GGUF models on first run
echo "Running initial embed (slow on first run — downloads models to ~/.cache/qmd/models/)..."
qmd embed

echo ""
echo "Install complete. Collection state:"
qmd collection list
```

Then make it executable:

```bash
chmod +x /workspaces/karpathy-llm-wiki/scripts/qmd-bootstrap.sh
```

- [ ] **Step 3: Lint the script**

```bash
bash -n /workspaces/karpathy-llm-wiki/scripts/qmd-bootstrap.sh && echo "syntax ok"
```

Expected output: `syntax ok`

Then verify it's executable:

```bash
ls -l /workspaces/karpathy-llm-wiki/scripts/qmd-bootstrap.sh
```

Expected: `-rwxr-xr-x` mode.

- [ ] **Step 4: Commit**

```bash
git add scripts/qmd-bootstrap.sh
git commit -m "feat(qmd): add fresh-install bootstrap script for wiki + raw collections"
```

---

## Task 2: Register qmd as a project-scoped MCP server

**Files:**

- Modify: `.claude/settings.json` — add `mcpServers.qmd` block and seven Bash permission patterns

- [ ] **Step 1: Read current settings.json to confirm structure**

```bash
cat /workspaces/karpathy-llm-wiki/.claude/settings.json
```

Confirm top-level keys are `$schema`, `env`, `permissions`. We will add a new top-level `mcpServers` key adjacent to those.

- [ ] **Step 2: Add the `mcpServers.qmd` block**

Use Edit. Replace this (the closing of `permissions`):

```json
    "defaultMode": "default"
  }
}
```

With:

```json
    "defaultMode": "default"
  },
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

- [ ] **Step 3: Add seven Bash permission patterns to `permissions.allow`**

Use Edit. Replace this line:

```json
      "Bash(mv:*)",
```

With:

```json
      "Bash(mv:*)",
      "Bash(qmd update:*)",
      "Bash(qmd embed:*)",
      "Bash(qmd query:*)",
      "Bash(qmd search:*)",
      "Bash(qmd vsearch:*)",
      "Bash(qmd status:*)",
      "Bash(qmd collection list:*)",
```

- [ ] **Step 4: Validate JSON**

```bash
python3 -m json.tool /workspaces/karpathy-llm-wiki/.claude/settings.json > /dev/null && echo "valid JSON"
```

Expected: `valid JSON`

Also re-read the file and visually confirm the `mcpServers` and new `Bash(qmd ...)` entries are present.

- [ ] **Step 5: Commit**

```bash
git add .claude/settings.json
git commit -m "feat(qmd): register qmd MCP server and allow qmd bash commands"
```

---

## Task 3: Extend the wiki-ingester Stop hook with qmd refresh

**Files:**

- Modify: `.claude/hooks/wiki-ingester-done.sh` — insert refresh block between the existing log-append block and the final `jq -n` systemMessage emit

- [ ] **Step 1: Read current hook to confirm exact layout**

```bash
cat /workspaces/karpathy-llm-wiki/.claude/hooks/wiki-ingester-done.sh
```

Confirm the script ends with these two blocks:

```bash
# Truncate to 200 chars for the user-visible notification.
NOTIFY=$(printf '%s' "$LAST_MSG" | head -c 200)

jq -n --arg msg "wiki-ingester: $NOTIFY" '{systemMessage: $msg}'
```

- [ ] **Step 2: Insert the refresh block before the NOTIFY line**

Use Edit. Replace this:

```bash
# Truncate to 200 chars for the user-visible notification.
NOTIFY=$(printf '%s' "$LAST_MSG" | head -c 200)
```

With:

```bash
# qmd refresh — not load-bearing for ingest; failures logged, not raised.
# A non-zero exit from `qmd update` or `qmd embed` inside an `if` condition
# does not terminate the script under `set -e` (bash treats the condition's
# exit as handled). So a qmd failure lands in the log without failing the
# outer hook.
{
  echo "[$TS] qmd refresh:"
  if command -v qmd >/dev/null 2>&1; then
    if qmd update >/dev/null 2>&1; then
      echo "  qmd update ok"
    else
      echo "  qmd update FAILED"
    fi
    if qmd embed >/dev/null 2>&1; then
      echo "  qmd embed ok"
    else
      echo "  qmd embed FAILED — index may be stale"
    fi
  else
    echo "  qmd not installed; skipping refresh"
  fi
  echo "---"
} >> "$LOG_DIR/wiki-ingester.log" 2>&1

# Truncate to 200 chars for the user-visible notification.
NOTIFY=$(printf '%s' "$LAST_MSG" | head -c 200)
```

- [ ] **Step 3: Syntax check**

```bash
bash -n /workspaces/karpathy-llm-wiki/.claude/hooks/wiki-ingester-done.sh && echo "syntax ok"
```

Expected: `syntax ok`

- [ ] **Step 4: Dry-run the hook with fake stdin**

```bash
echo '{"agent_id":"test","last_assistant_message":"dry run"}' \
  | CLAUDE_PROJECT_DIR=/workspaces/karpathy-llm-wiki \
    bash /workspaces/karpathy-llm-wiki/.claude/hooks/wiki-ingester-done.sh
```

Expected: one-line JSON output like `{"systemMessage":"wiki-ingester: dry run"}`. No non-zero exit even if qmd isn't installed yet (the `command -v qmd` guard handles that case).

Then check the log:

```bash
tail -n 10 /workspaces/karpathy-llm-wiki/.claude/logs/wiki-ingester.log
```

Expected: a `qmd refresh:` block — either with success/failure lines if qmd is installed, or a `qmd not installed; skipping refresh` line if not.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/wiki-ingester-done.sh
git commit -m "feat(qmd): refresh qmd index after wiki-ingester finishes"
```

---

## Task 4: Rewrite the qmd integration prompt as as-built documentation

**Files:**

- Modify: `.claude/prompts/qmd-wiki-integration.md` — complete rewrite

- [ ] **Step 1: Overwrite with as-built content**

Use Write to replace the entire file with:

````markdown
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

MCP server `qmd` is registered in `.claude/settings.json` via stdio transport (`qmd mcp`). Exposed MCP tools: `query`, `get`, `multi_get`, `status`. No plugin install. No HTTP daemon.

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
````

- [ ] **Step 2: Commit**

```bash
git add .claude/prompts/qmd-wiki-integration.md
git commit -m "docs(qmd): rewrite integration prompt as as-built documentation"
```

---

## Task 5: End-to-end verification

No file changes in this task. This is a verification pass the operator runs after Tasks 1–4 are merged.

- [ ] **Step 1: Run the bootstrap**

```bash
bash /workspaces/karpathy-llm-wiki/scripts/qmd-bootstrap.sh
```

Expected: completes without error, prints a `qmd collection list` block showing `wiki` and `raw` with non-zero document counts. First run is slow — models download from upstream, and the full corpus embeds. Subsequent runs (after manual `qmd collection remove`) would be faster.

- [ ] **Step 2: Sanity check collections and embedding state**

```bash
qmd collection list
qmd status
```

Expected: two collections `wiki` and `raw` with doc counts roughly matching:

```bash
find /workspaces/karpathy-llm-wiki/wiki -name '*.md' | wc -l
find /workspaces/karpathy-llm-wiki/raw -name '*.md' | wc -l
```

`qmd status` should report no pending embeddings.

- [ ] **Step 3: CLI proof query**

```bash
qmd query "llm wiki pattern"
```

Expected: results include `wiki/llm-wiki/llm-wiki-pattern.md`. Exact rank position is not asserted (re-ranking is probabilistic).

- [ ] **Step 4: MCP sanity check from Claude Code**

Restart Claude Code so it picks up the new `mcpServers.qmd` entry. From a fresh session, invoke the qmd MCP `status` tool directly. Expected: the tool responds with qmd status info — proving the MCP entry is valid and the stdio server starts correctly.

- [ ] **Step 5: Hook smoke test — live ingest**

Spawn `wiki-ingester` on any short source via Agent with `run_in_background: true`. When it finishes, tail the log:

```bash
tail -n 20 /workspaces/karpathy-llm-wiki/.claude/logs/wiki-ingester.log
```

Expected: a `qmd refresh:` block with `qmd update ok` and `qmd embed ok`. Then verify the new article is findable:

```bash
qmd get wiki/<topic>/<newly-ingested-article>.md
```

Expected: the new article is returned. This proves the hook ran the refresh on the live delta.

Verification ends here — no write to `wiki/log.md`. Per `SKILL.md:23` and `SKILL.md:191`, that log is append-only for wiki operations (Ingest, Archive from Query, Lint). qmd is a layer on top of the wiki and is deliberately kept out of the log. The record of this install is:

- The four commits produced by Tasks 1–4 (dated and attributed).
- Ongoing hook output captured in `.claude/logs/wiki-ingester.log` after each post-ingest refresh.
- `.claude/prompts/qmd-wiki-integration.md` (rewritten in Task 4) describes the install as-built.

If a shared infra log covering qmd + wiki + other tooling is ever wanted, that's a SKILL.md schema change and warrants its own spec.

---

## Known costs and caveats (not blockers)

- **Hook embed cost may grow with corpus size.** Upstream does not document whether `qmd embed` only processes chunks flagged by `qmd update` or re-embeds everything. At current scale (four topics, eleven articles) the cost is negligible. If post-ingest latency becomes noticeable as the wiki grows, instrument the hook to measure `qmd embed` wall-clock and consider the HTTP daemon (out of scope here).
- **Fresh-install guard is best-effort.** `qmd collection list` has no documented machine-readable format and no `--json` flag. The bootstrap's grep-based guard may false-positive on a collection whose name contains `wiki` or `raw` as a substring (e.g., `my-wiki`). Mitigation: remove collections manually via `qmd collection remove <name>` and re-run the bootstrap.
- **Wiki-vs-raw query boundary is prompt policy.** Both collections are searchable; qmd will return raw chunks if they rank highly. The agent answers from compiled articles by convention (CLAUDE.md + SKILL.md Query semantics), not because qmd enforces anything.
- **Per-call MCP reloads.** Stdio transport spawns a fresh `qmd mcp` process for each call, reloading models. Expect noticeable latency per MCP query; add `--http --daemon` only if it becomes a friction point.

## What this plan does NOT do

- No HTTP daemon (`qmd mcp --http --daemon`). Stdio only.
- No changes to `SKILL.md`, `references/`, `CLAUDE.md`, or any subagent definition (`wiki-ingester.md`, `wiki-linter.md`, `skill-reviewer.md`).
- No edits to article bodies under `wiki/` or to files under `raw/`.
- No CI, no alerting, no auto-retry on qmd failures.
- No user-level Claude Code settings changes (everything project-scoped).
- No multilingual embedding model swap.
- No `.gitignore` changes.
- No writes to `wiki/log.md` — qmd is not a wiki operation per `SKILL.md:23` and `SKILL.md:191`.

Each of these is a separate follow-up if needed.

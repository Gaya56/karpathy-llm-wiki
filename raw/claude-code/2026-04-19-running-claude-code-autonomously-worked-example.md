# Running Claude Code Autonomously — Template + Worked Example

> Source: docs/runs/RunninClaude_Code-Autonomously.md (local doc, this repo)
> Collected: 2026-04-19
> Published: 2026-04-18

We are learning how to run Claude Code fully autonomously — the ability to write one prompt in a bash script or CLI command, leave, and come back to completed work. This means configuring Claude Code so it never stops to ask permission, knows your project deeply through `CLAUDE.md` and `settings.json`, and can run in the background via `/loop`, Cloud Routines, or a simple `.sh` script using `claude -p` with `--allowedTools` and `--bare`. The end goal is a setup where you dispatch a task from anywhere — your phone, a browser, or a terminal — and Claude handles reading files, writing code, running tests, and committing, all without you.

## Official references

| What | Official URL |
| --- | --- |
| `-p` flag / programmatic usage | `code.claude.com/docs/en/headless` |
| `--allowedTools` + permission modes | `code.claude.com/docs/en/headless#auto-approve-tools` |
| `/loop` + cron scheduling | `code.claude.com/docs/en/scheduled-tasks` |
| Cloud Routines (laptop off) | `code.claude.com/docs/en/routines` |
| `settings.json` permissions | `code.claude.com/docs/en/settings` |
| CLI full flag reference | `code.claude.com/docs/en/cli-reference` |
| Agent SDK (Python/TS beyond bash) | `code.claude.com/docs/en/agent-sdk/overview` |

---

# Worked example — a chained, read-only Discovery Runner

## Goal

Have a repo's own Claude Code instance (a "repo-expert" agent with MCP plugins already enabled — e.g. Supabase, Railway, a CRM MCP, Context7) run **5 discovery prompts in sequence**, producing 5 architecture + gap-analysis notes into a separate output directory — while the user walks away for 30 minutes.

## Architecture — two-session pattern

- **Controller session** — a separate Claude Code (or the user's terminal). Authors the prompt files, the runner script, and a background monitor.
- **Executor session** — the repo's own Claude Code at `<REPO_DIR>/.claude/`. Invoked by the runner via `claude -p`. Has live MCP access to the services this repo integrates with. Does the actual discovery and writes notes to `<OUTPUT_DIR>`.

The controller never touches the repo. The executor never writes outside `<OUTPUT_DIR>`. Division of labor by directory.

## The five prompt files

Each prompt file at `<REPO_DIR>/.claude/prompts/` follows a strict 6-section template so the executor doesn't guess:

```
# Purpose         — one sentence mission
# Scope           — In / Out bullet lists
# Depth           — medium / deep with concrete examples
# Constraints     — read-only, modify-over-build, tenant privacy, no secrets
# Output target   — absolute path to the output note to produce
# Success criteria — checkbox list the note must satisfy
```

Example file roles (names are illustrative — adapt to your domain):

| File | Role | Line target |
| --- | --- | --- |
| `discover-repo.md` | Medium map of codebase | 60–120 |
| `discover-<service-A>.md` | Deep map of tables + functions + RLS | 90–160 |
| `discover-<service-B>.md` | Medium map of external SaaS: modules + webhooks | 60–90 |
| `discover-workflow.md` | End-to-end lifecycle stitching the above | 70–110 |
| `gap-analysis.md` | Synthesis: scorecard + priority + candidate-fix table | 80–120 |

## The runner script

A minimal, working template for chained sequential runs:

```bash
#!/bin/bash
set -euo pipefail

REPO_DIR="<REPO_DIR>"               # e.g. /path/to/your-repo
PROMPTS_DIR="$REPO_DIR/.claude/prompts"
OUTPUT_DIR="<OUTPUT_DIR>"           # e.g. /path/to/your-notes
LOG_DIR="/tmp/discovery-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

cd "$REPO_DIR"

# Prompt 1 — capture session id via JSON output
FIRST_JSON=$(claude -p "$(cat "$PROMPTS_DIR/discover-repo.md")" \
  --output-format json \
  --permission-mode bypassPermissions \
  --add-dir "$OUTPUT_DIR" 2> "$LOG_DIR/discover-repo.err")
echo "$FIRST_JSON" > "$LOG_DIR/discover-repo.json"
SESSION=$(echo "$FIRST_JSON" | jq -r '.session_id')

# Prompts 2–5 — resume the same session so context carries forward
for p in discover-<service-A>.md discover-<service-B>.md discover-workflow.md gap-analysis.md; do
  claude -p "$(cat "$PROMPTS_DIR/$p")" \
    --resume "$SESSION" \
    --permission-mode bypassPermissions \
    --add-dir "$OUTPUT_DIR" \
    > "$LOG_DIR/${p%.md}.log" 2> "$LOG_DIR/${p%.md}.err"
done
```

## Flag-by-flag — what each one does (official source)

| Flag | What it does | Reference |
| --- | --- | --- |
| `-p "<prompt>"` | Headless; prints response + exits. Skips workspace-trust dialog. | `code.claude.com/docs/en/headless` |
| `--permission-mode bypassPermissions` | Skips all permission checks. Docs recommend it for isolated VMs / containers. | `code.claude.com/docs/en/headless#auto-approve-tools` |
| `--add-dir "<OUTPUT_DIR>"` | Adds a directory Claude can access beyond `cwd`. Use to grant writes to an output tree outside the repo. | `code.claude.com/docs/en/cli-reference` |
| `--output-format json` | Returns a JSON object instead of plain text. Contains `session_id`, `result`, `is_error`, `permission_denials`, `total_cost_usd`, etc. | `code.claude.com/docs/en/headless` |
| `--resume <uuid>` | Continues a prior session by ID. Essential for chaining — later prompts see earlier prompts' context. Sessions persist by default in `-p` mode. | `code.claude.com/docs/en/headless` |
| `jq -r '.session_id'` | Extracts the session ID from prompt 1's JSON output. Not a Claude flag — a required companion. | `jqlang.github.io/jq` |

## Project-scoped MCP registration

Before running, register any MCPs needed by the executor at **project** scope (not user):

```bash
cd <REPO_DIR>
claude mcp add --transport http --scope project <server-name> "<mcp-url>"
```

Result: writes to `<REPO_DIR>/.mcp.json`, auto-loaded when Claude Code runs from that directory. Project scope means the config travels with the repo (shareable via git) and doesn't leak into user-global config. Verify with `claude mcp get <server-name>`.

Reference: `code.claude.com/docs/en/cli-reference` (see `mcp add`).

## What goes wrong on the first try — and the fix

### Attempt 1 (failed)

Used `--permission-mode dontAsk` + an allowlist with path-scoped Write/Edit:

```bash
--allowedTools "Read,Glob,Grep,Write(<OUTPUT_DIR>/**),Edit(<OUTPUT_DIR>/**),mcp__*"
```

**Result:** exit 0, "done" — but every note stayed a stub. The executor actually did the full discovery (prompt 1's JSON log showed ~200 lines of completed analysis), but was **silently blocked** at the Write tool call. Prompts 2–5 then saw the "blocked" conclusion in the chained session and bailed early.

**Root cause (verified against local `claude --help`):** the parens-scoping syntax `Write(path/**)` / `Edit(path/**)` in `--allowedTools` isn't valid — only `Bash(<pattern>)` supports it. For Write/Edit, scoping has to happen via `--add-dir` + a narrower `cwd`, or via `settings.json` `permissions.allow` with path globs.

### Recovery

The blocked Write's content is captured in the JSON log under `.permission_denials[0].tool_input.content`. Extract with `jq`:

```bash
jq -r '.permission_denials[0].tool_input.content' <LOG_DIR>/discover-repo.json \
  > "<OUTPUT_DIR>/your-note.md"
```

Salvages the completed analysis without a re-run. **Claude Code captures attempted tool inputs even on denial** — useful for forensics.

### Attempt 2 (worked)

Switched to `--permission-mode bypassPermissions`, dropped `--allowedTools` entirely. Re-ran the whole script in a fresh session. All 5 notes landed clean — totals from the actual run: **511 lines of real content · ~7 minutes · ~$6 in API cost**.

## Monitoring pattern (background watch)

While the script runs, keep a filesystem watcher alive that emits an event per completed prompt:

```bash
# Watches <LOG_DIR>/*.json and *.log as they land
# Emits OK / FAIL per file by grepping for denial patterns + is_error:true
# Exits when the final synthesis note appears in <OUTPUT_DIR> with >20 lines
```

**Important subtlety:** a naive monitor that matches the string `permission_denials` will false-positive, because that key always exists in the JSON (even when empty: `"permission_denials":[]`). Match non-empty markers (`"permission_denials":[{`) or use `jq` to check list length.

## Lessons for any autonomous Claude Code run

1. **Trust local `claude --help` over any agent's claims.** Two subagents contradicted each other on `-allowedTools` format. Local help was authoritative: both comma- and space-separated work.
2. **`bypassPermissions` is the docs' recommended mode for isolated-VM autonomous runs** (`code.claude.com/docs/en/headless#auto-approve-tools`). Use it deliberately — acknowledge the broader blast radius, enforce scope in the prompt's Constraints section as a secondary check.
3. **Chain sessions with `-resume` + `jq .session_id`** (`code.claude.com/docs/en/headless`). Each prompt inherits context without re-ingesting files.
4. **Log everything per-prompt** (`.log`, `.err`, `.json`). Even on silent failure, `.permission_denials[].tool_input.content` can be salvaged.
5. **Prompts should self-enforce scope.** Put "Read-only", "Modify-over-build", "Output target: /absolute/path/", and "No secrets" directly into every prompt's Constraints section. Don't rely on CLI flags alone.
6. **Register project MCPs at `-scope project`** (`code.claude.com/docs/en/cli-reference`), not user. Config travels with the repo.
7. **When a chained session fails mid-way, re-run the whole thing in a fresh session.** Don't try to resume a poisoned one — prompts 2–N will see the failure and abort.
8. **Monitor grep patterns must match non-empty values,** not just field names.

## When to reach for what

| Task | Tool | Reference |
| --- | --- | --- |
| One-shot autonomous job, single prompt | `claude -p "..." --permission-mode bypassPermissions` | `code.claude.com/docs/en/headless` |
| Multi-prompt chained run (this example) | `claude -p` + `--resume <session_id>` + a bash loop | `code.claude.com/docs/en/headless` |
| Recurring poll / watch loop in-session | `/loop` skill | `code.claude.com/docs/en/scheduled-tasks` |
| Runs even when laptop is closed | Cloud Routines via `/schedule` | `code.claude.com/docs/en/routines` |
| Move session to phone / browser | Remote Control + `--teleport` | `code.claude.com/docs/en/desktop` (check latest) |
| Move beyond bash — Python / TS agent code | Agent SDK | `code.claude.com/docs/en/agent-sdk/overview` |

## Minimal checklist before you run an autonomous script

- [ ]  `CLAUDE.md` in the target repo is tight and truthful (stack, conventions, "done" criteria)
- [ ]  `settings.json` (user or project) pre-approves tools you want available
- [ ]  `.mcp.json` in the repo lists project-scoped MCPs (`claude mcp add --scope project ...`)
- [ ]  All prompt files follow the 6-section template and include absolute `Output target` paths
- [ ]  The runner uses `-permission-mode bypassPermissions` + `-add-dir <OUTPUT_DIR>` + `-output-format json` on prompt 1
- [ ]  Session chaining uses `-resume $(jq -r '.session_id' <first-json-log>)`
- [ ]  A per-prompt log directory exists: `.log` / `.err` / `.json` per file
- [ ]  A monitor / watcher is armed with patterns that match non-empty failure markers
- [ ]  Prompts enforce scope locks in their own Constraints section (redundant with CLI flags, intentional belt-and-suspenders)

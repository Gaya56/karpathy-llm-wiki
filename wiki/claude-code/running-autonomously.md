# Running Claude Code Autonomously

> Sources: Worked example (this repo), 2026-04-18; Anthropic Claude Code docs, 2026-04-19
> Raw: [Running Claude Code Autonomously — worked example](../../raw/claude-code/2026-04-19-running-claude-code-autonomously-worked-example.md); [Run Claude Code programmatically](../../raw/claude-code/2026-04-19-claude-code-headless.md); [CLI reference](../../raw/claude-code/2026-04-19-claude-code-cli-reference.md); [Scheduled tasks](../../raw/claude-code/2026-04-19-claude-code-scheduled-tasks.md); [Cloud Routines](../../raw/claude-code/2026-04-19-claude-code-routines.md); [Agent SDK overview](../../raw/claude-code/2026-04-19-claude-code-agent-sdk-overview.md); [Desktop](../../raw/claude-code/2026-04-19-claude-code-desktop.md)
> Updated: 2026-04-19

## Overview

Running Claude Code autonomously means writing one prompt in a bash script or CLI call, walking away, and coming back to completed work. The pieces that make that possible are already in the product: `claude -p` for non-interactive invocation, `--permission-mode bypassPermissions` for isolated runs where you don't want to be asked, `--resume` + `jq` for chaining prompts that share context, `/loop` for in-session polling, Cloud Routines for runs that survive your laptop being closed, and the Agent SDK for anything bash can't express. This article ties those together, walks through a chained worked example, and catalogues the specific failure mode that silently swallows half your output if you scope `--allowedTools` wrong.

## The six building blocks

| Surface | What it gives you | Deep-dive |
| --- | --- | --- |
| Headless (`claude -p`) | Non-interactive runs, `--bare` for CI determinism, `--output-format json` with `session_id`, system prompt flags | [Headless Mode](headless-mode.md) |
| CLI flags | The full vocabulary — permission, context, session, output, system prompt | [CLI Reference](cli-reference.md) |
| In-session scheduling | `/loop` with fixed or dynamic intervals, built-in maintenance prompt, `loop.md` overrides, `CronCreate` tools | [Scheduled Tasks and /loop](scheduled-tasks.md) |
| Laptop-off scheduling | Routines — prompt + repos + connectors, triggered by schedule / API `/fire` endpoint / GitHub event | [Cloud Routines](cloud-routines.md) |
| Python / TypeScript | Same agent loop as the CLI, programmable, with hooks and typed messages | [Agent SDK](agent-sdk.md) |
| Multi-surface portability | Remote Control from phone / browser, Dispatch, `--teleport` to pull web sessions into the terminal | [Claude Code Desktop](desktop.md) |

Pick one of these based on [When to reach for what](#when-to-reach-for-what) below. Most autonomous workflows use the first two and add one more depending on duration and persistence needs.

## The two-session pattern

A robust autonomous run uses two separate Claude Code contexts:

- **Controller** — the session you run interactively. Authors the prompt files, the runner script, and a background monitor. Never touches the target repo directly.
- **Executor** — the repo's own Claude Code, configured via `<REPO_DIR>/.claude/`, with project-scoped MCP servers already wired up. Invoked headlessly by the runner via `claude -p`. Does the actual work and writes to a pre-approved `<OUTPUT_DIR>`.

Division of labor by directory: controller in one tree, executor in another, output in a third. Each is scoped by `cwd` and `--add-dir` rather than by allowlist patterns. This is the pattern that survives contact with a real autonomous run; scoping writes with `--allowedTools "Write(<dir>/**)"` does not (see [First-attempt failure](#first-attempt-failure-and-the-fix)).

## The prompt-file template

Each prompt the executor runs lives in its own markdown file under `<REPO_DIR>/.claude/prompts/`. A strict six-section template prevents the executor from guessing:

```
# Purpose         — one sentence mission
# Scope           — In / Out bullet lists
# Depth           — medium / deep with concrete examples
# Constraints     — read-only, modify-over-build, tenant privacy, no secrets
# Output target   — absolute path to the output note to produce
# Success criteria — checkbox list the note must satisfy
```

Constraints are where scope locks are enforced redundantly with the CLI flags — put "Read-only", "Modify-over-build", "Output target: /absolute/path/", and "No secrets" inside every prompt's Constraints section. Belt-and-suspenders: if a CLI flag drops out during editing, the prompt still holds the line.

## Runner script skeleton

Minimal working template for a chained run. Prompt 1 captures the session ID; prompts 2–N resume it so each sees everything the prior prompts produced:

```bash
#!/bin/bash
set -euo pipefail

REPO_DIR="<REPO_DIR>"
PROMPTS_DIR="$REPO_DIR/.claude/prompts"
OUTPUT_DIR="<OUTPUT_DIR>"
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

# Prompts 2–N — resume the same session so context carries forward
for p in step-2.md step-3.md step-4.md synthesize.md; do
  claude -p "$(cat "$PROMPTS_DIR/$p")" \
    --resume "$SESSION" \
    --permission-mode bypassPermissions \
    --add-dir "$OUTPUT_DIR" \
    > "$LOG_DIR/${p%.md}.log" 2> "$LOG_DIR/${p%.md}.err"
done
```

**jq is a required companion** — it extracts `.session_id` from prompt 1's JSON output so prompts 2–N can chain. Install from [jqlang.github.io/jq](https://jqlang.github.io/jq) if you don't have it.

### Flag-by-flag

| Flag | What it does | See |
| --- | --- | --- |
| `-p "<prompt>"` | Headless; prints response and exits | [Headless Mode](headless-mode.md) |
| `--permission-mode bypassPermissions` | Skips all permission checks. Docs recommend it for isolated VMs / containers | [Headless Mode](headless-mode.md), [CLI Reference](cli-reference.md) |
| `--add-dir "<OUTPUT_DIR>"` | Adds a directory Claude can access beyond `cwd`. Use this to grant writes to an output tree outside the repo | [CLI Reference](cli-reference.md) |
| `--output-format json` | Returns JSON with `session_id`, `result`, `is_error`, `permission_denials`, `total_cost_usd` | [Headless Mode](headless-mode.md) |
| `--resume <uuid>` | Continues a prior session by ID. Essential for chaining — later prompts inherit context without re-ingesting files | [Headless Mode](headless-mode.md) |

### Project-scoped MCP registration

Before running, register any MCP servers the executor needs at **project** scope so the config travels with the repo:

```bash
cd <REPO_DIR>
claude mcp add --transport http --scope project <server-name> "<mcp-url>"
```

This writes to `<REPO_DIR>/.mcp.json`, auto-loaded whenever Claude Code runs from that directory. Verify with `claude mcp get <server-name>`. Project scope keeps the config shareable via git and out of your user-global config.

## First-attempt failure and the fix

The most important lesson from the worked example: scoping writes with `--allowedTools "Write(<path>/**)"` silently fails.

Concretely, the first attempt used:

```bash
--permission-mode dontAsk \
--allowedTools "Read,Glob,Grep,Write(<OUTPUT_DIR>/**),Edit(<OUTPUT_DIR>/**),mcp__*"
```

The script exited 0 with "done" — but every output note stayed a stub. The executor had actually done the full analysis (prompt 1's JSON log showed ~200 lines of completed discovery), then got **silently blocked** at the Write call. Prompts 2–N then saw the "blocked" outcome in the chained session and bailed early.

**Root cause:** the parens-scoping syntax `Write(path/**)` / `Edit(path/**)` in `--allowedTools` isn't valid. Only `Bash(<pattern>)` supports paren-scoping. For Write/Edit, scope via `--add-dir` plus a narrower `cwd`, or via `settings.json` `permissions.allow` globs — not via `--allowedTools`.

**Recovery without a re-run:** the blocked Write's content is captured in the JSON log under `.permission_denials[0].tool_input.content`. Extract it:

```bash
jq -r '.permission_denials[0].tool_input.content' <LOG_DIR>/discover-repo.json \
  > "<OUTPUT_DIR>/your-note.md"
```

Claude Code captures attempted tool inputs even on denial. Useful for forensics, useful for salvaging.

**What worked:** switch to `--permission-mode bypassPermissions`, drop `--allowedTools` entirely, let the prompt's Constraints section enforce scope. All five notes landed clean — 511 lines of real content, ~7 minutes wall time, ~$6 API cost.

## Monitoring pattern

While the runner script executes, keep a filesystem watcher alive that tracks per-prompt completion:

```
# Watches <LOG_DIR>/*.json and *.log as they land.
# Emits OK / FAIL per file by grepping for denial patterns + is_error:true.
# Exits when the final synthesis note appears in <OUTPUT_DIR> with >20 lines.
```

**One subtlety worth memorizing:** a naive monitor that greps for the literal string `permission_denials` will false-positive because that key always exists in the JSON, even when empty (`"permission_denials":[]`). Match non-empty markers instead — `"permission_denials":[{` — or use `jq` to check list length.

For event-driven monitoring (rather than polling), see the Monitor tool mentioned in [Scheduled Tasks and /loop](scheduled-tasks.md) and the streaming events documented in [Headless Mode](headless-mode.md) — `system/api_retry` and `system/init` with `plugin_errors` are the operationally meaningful ones.

## Lessons for any autonomous run

1. **Trust local `claude --help` over any agent's claims.** Different subagents will contradict each other on flag syntax; local help is authoritative.
2. **`bypassPermissions` is the docs-recommended mode for isolated-VM autonomous runs.** Acknowledge the broader blast radius and enforce scope in the prompt's Constraints section as a secondary check.
3. **Chain sessions with `--resume` + `jq '.session_id'`**. Each prompt inherits context without re-ingesting files. Sessions persist by default in `-p` mode.
4. **Log everything per-prompt** — `.log`, `.err`, `.json`. Even on silent failure, `.permission_denials[].tool_input.content` can be salvaged.
5. **Prompts should self-enforce scope.** Put "Read-only", "Modify-over-build", "Output target: /absolute/path/", and "No secrets" directly into every prompt's Constraints section. Don't rely on CLI flags alone.
6. **Register project MCPs at `--scope project`**, not user. Config travels with the repo, doesn't leak into user-global config.
7. **When a chained session fails mid-way, re-run the whole thing in a fresh session.** Don't try to resume a poisoned one — prompts 2–N will see the failure and abort.
8. **Monitor grep patterns must match non-empty values**, not just field names.

## When to reach for what

| Task | Tool | Article |
| --- | --- | --- |
| One-shot autonomous job, single prompt | `claude -p "..." --permission-mode bypassPermissions` | [Headless Mode](headless-mode.md) |
| Multi-prompt chained run | `claude -p` + `--resume <session_id>` + a bash loop | [Headless Mode](headless-mode.md) |
| Recurring poll / watch loop in-session | `/loop` with fixed or dynamic interval | [Scheduled Tasks and /loop](scheduled-tasks.md) |
| Runs even when your laptop is closed | Cloud Routines via `/schedule` | [Cloud Routines](cloud-routines.md) |
| Trigger an autonomous job from an alert / webhook | Cloud Routine with an API trigger (`/fire` endpoint + bearer token) | [Cloud Routines](cloud-routines.md) |
| Move session to phone / browser | Remote Control; `--teleport` to pull back to terminal | [Claude Code Desktop](desktop.md) |
| Beyond bash — Python / TS programmatic control | Agent SDK (`query()` + `ClaudeAgentOptions`) | [Agent SDK](agent-sdk.md) |

## Minimal checklist before you run an autonomous script

- [ ] `CLAUDE.md` in the target repo is tight and truthful (stack, conventions, "done" criteria)
- [ ] `settings.json` (user or project) pre-approves tools you want available
- [ ] `.mcp.json` in the repo lists project-scoped MCPs (`claude mcp add --scope project ...`)
- [ ] All prompt files follow the 6-section template and include absolute `Output target` paths
- [ ] The runner uses `--permission-mode bypassPermissions` + `--add-dir <OUTPUT_DIR>` + `--output-format json` on prompt 1
- [ ] Session chaining uses `--resume $(jq -r '.session_id' <first-json-log>)`
- [ ] A per-prompt log directory exists — `.log` / `.err` / `.json` per file
- [ ] A monitor / watcher is armed with patterns that match non-empty failure markers
- [ ] Prompts enforce scope locks in their own Constraints section (redundant with CLI flags, intentional belt-and-suspenders)

## See Also

- [Headless Mode](headless-mode.md) — `-p`, `--bare`, output formats, session chaining, streaming events
- [CLI Reference](cli-reference.md) — every flag used above, plus the ones this article doesn't cover
- [Scheduled Tasks and /loop](scheduled-tasks.md) — in-session recurring work, Monitor tool
- [Cloud Routines](cloud-routines.md) — laptop-off scheduling, API and GitHub triggers
- [Agent SDK](agent-sdk.md) — Python / TypeScript equivalent of the runner pattern above
- [Claude Code Desktop](desktop.md) — Remote Control and `--teleport` for multi-surface workflows
- [Settings and Configuration](settings.md) — `permissions.allow` rule syntax, `defaultMode`, sandbox
- [MCP in Claude Code](mcp.md) — project-scoped registration, transports
- [Memory and Persistent Instructions](memory.md) — `CLAUDE.md` scopes and load order (the first item in the pre-run checklist)

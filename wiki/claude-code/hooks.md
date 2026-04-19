# Hooks Reference

> Sources: Anthropic, 2026-04-16
> Raw: [hooks-reference](../../raw/claude-code/hooks-reference.md)

## Overview

Hooks are user-defined shell commands, HTTP endpoints, or LLM prompts that fire automatically at lifecycle points in a Claude Code session. They run outside the agentic loop as deterministic (no-LLM) code by default and communicate back to Claude Code through exit codes and JSON on stdout.

Three cadences: **once per session** (`SessionStart`, `SessionEnd`), **once per turn** (`UserPromptSubmit`, `Stop`, `StopFailure`), **every tool call** (`PreToolUse`, `PostToolUse`, and others). There are 26 events in total, so hooks are the fine-grained instrument for just about anything predictable — notifications, linting after edits, blocking dangerous commands, injecting context at session start, persisting env vars, reacting to subagent completion.

Configuration lives at three levels of nesting: an **event** (what to listen for), a **matcher group** (filter, like "only Bash tool calls"), and one or more **hook handlers** (the command, URL, prompt, or agent that actually runs).

## Hook events

Grouped by lifecycle phase. The full set:

**Session lifecycle**

- `SessionStart` — new session or resume. Matcher: `startup` / `resume` / `clear` / `compact`. Can inject context via `additionalContext` or plain stdout. Has access to `CLAUDE_ENV_FILE` to persist env vars for subsequent Bash calls.
- `SessionEnd` — matcher on end reason (`clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`). No decision control.
- `InstructionsLoaded` — fires when a `CLAUDE.md` or `.claude/rules/*.md` is loaded (eagerly or lazily). Matcher on `load_reason`. Observability only, no blocking.
- `ConfigChange` — a settings file changed during the session. Matcher on source (`user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`). Can block the change with `decision: "block"`.

**Prompt lifecycle**

- `UserPromptSubmit` — user submitted a prompt, before Claude processes it. No matcher. Can block the prompt (`decision: "block"` erases it) or add context (`additionalContext` field, or plain stdout).
- `Stop` — Claude finished responding. No matcher. Can prevent stopping with `decision: "block"` — Claude continues the conversation.
- `StopFailure` — turn ended because of an API error. Matcher on `error_type`. Observability only; output and exit code ignored.

**Tool lifecycle**

- `PreToolUse` — before a tool call executes. Matcher on tool name (`Bash`, `Edit|Write`, `mcp__memory__.*`, etc.). Can `allow` / `deny` / `ask` / `defer`, and can mutate the tool's input via `updatedInput`.
- `PermissionRequest` — when a permission dialog would appear. Matcher on tool name. Can allow or deny the prompt (`decision.behavior`), and in allow mode can modify input or update persistent permission rules.
- `PermissionDenied` — auto-mode classifier denied a call. Only fires in auto mode. Can return `{ retry: true }` to tell Claude it may retry.
- `PostToolUse` — tool succeeded. Matcher on tool name. Can `decision: "block"` (feeds `reason` to Claude) and add `additionalContext`.
- `PostToolUseFailure` — tool failed. Matcher on tool name. Can add `additionalContext` for Claude to consider alongside the error.

**Subagent and teammate lifecycle**

- `SubagentStart` — subagent spawned. Matcher on agent type. Cannot block creation; can inject context into the subagent via `additionalContext`.
- `SubagentStop` — subagent finished. Matcher on agent type. Receives `agent_id`, `agent_type`, `agent_transcript_path`, and `last_assistant_message` (the subagent's final response text — no transcript parsing needed). Can prevent the subagent from stopping with `decision: "block"`.
- `TaskCreated` / `TaskCompleted` — `TaskCreate` tool events. Can block (`exit 2`) to roll back. Can also `continue: false` to stop the whole teammate.
- `TeammateIdle` — agent-team teammate about to go idle. Can prevent with exit 2 or stop the teammate entirely with `continue: false`.

**Notification, compaction, elicitation**

- `Notification` — Claude sends a notification (`permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`). Matcher on notification type. No blocking.
- `PreCompact` / `PostCompact` — before/after context compaction. Matcher on `triggered_by` (`manual` or `auto`). `PreCompact` can block with `decision: "block"`; `PostCompact` is observability only.
- `Elicitation` — MCP server requests user input. Matcher on MCP server name. Can `accept` (with `content`), `decline`, or `cancel`.
- `ElicitationResult` — after user responds to elicitation, before the response is sent back. Can override field values.

**Environment lifecycle**

- `CwdChanged` — working directory changed (e.g., `cd`). No matcher. Has access to `CLAUDE_ENV_FILE`. Observability only.
- `FileChanged` — a watched file changed on disk. Matcher is the literal filenames to watch, `|`-separated (no regex). Has access to `CLAUDE_ENV_FILE`. Observability only.
- `WorktreeCreate` / `WorktreeRemove` — git worktree lifecycle. `WorktreeCreate` *replaces* default git behavior: the hook must print (or return) the created worktree path. Any non-zero exit from `WorktreeCreate` aborts creation — the one event where non-2 exit codes block.

## Configuration schema

Hooks are defined in JSON, nested three levels deep: `{ "hooks": { "<EventName>": [ { "matcher": "...", "hooks": [ { <handler> }, ... ] } ] } }`.

Hook locations:

| Location | Scope | Shareable |
|---------|-------|-----------|
| `~/.claude/settings.json` | All your projects | No |
| `.claude/settings.json` | Single project | Yes (commit to repo) |
| `.claude/settings.local.json` | Single project | No (gitignored) |
| Managed policy settings | Organization-wide | Yes (admin-controlled) |
| Plugin `hooks/hooks.json` | Where plugin enabled | Yes (bundled with plugin) |
| Skill or agent frontmatter | While component active | Yes (in component file) |

Enterprise admins can set `allowManagedHooksOnly` to block user/project/plugin hooks; plugins force-enabled in managed settings `enabledPlugins` are exempt.

## Matcher rules

| Matcher value | How it's evaluated |
|---------------|---------------------|
| `"*"`, `""`, or omitted | Match everything |
| Only letters, digits, `_`, `\|` | Exact string, or pipe-separated exact strings |
| Contains any other character | JavaScript regex |

Per-event matcher field: tool events match tool name, `SessionStart` matches start source, `SubagentStart`/`SubagentStop` match agent type, `Notification` matches notification type, etc. Some events (`UserPromptSubmit`, `Stop`, `CwdChanged`, `WorktreeCreate`/`WorktreeRemove`, `TeammateIdle`) don't support matchers and fire universally.

For narrower filtering on tool events, add an `if` field to individual handlers using permission-rule syntax: `"Bash(rm *)"` only runs for commands starting with `rm`. That filter is evaluated before the process spawns, so it's the cheapest way to narrow.

MCP tool matching: MCP tools appear as `mcp__<server>__<tool>`. A matcher like `mcp__memory__.*` catches all tools from the `memory` server (note the `.*` — without it, the matcher is treated as an exact string).

## Handler types

Four options for what runs when a matcher matches:

- **`type: "command"`** — shell command. Receives event JSON on stdin, returns via exit code + stdout (+ stderr). Fields: `command` (required), `async`, `asyncRewake`, `shell` (`bash` default or `powershell`). Default timeout 600s.
- **`type: "http"`** — POST to a URL. JSON arrives as request body, response returns in the body. Fields: `url` (required), `headers`, `allowedEnvVars`. Default timeout 30s. Non-2xx responses are non-blocking errors — to block, return 2xx with a decision JSON body.
- **`type: "prompt"`** — single-turn LLM evaluation. Fields: `prompt` (required, `$ARGUMENTS` placeholder gets the hook input JSON), `model`. Default timeout 30s.
- **`type: "agent"`** — spawn a subagent that can use Read/Grep/Glob to verify conditions. Same `prompt` + `model` fields. Default timeout 60s.

Common fields on every handler type: `if` (tool-event filter), `timeout`, `statusMessage` (custom spinner text), `once` (skill-only, runs once per session then auto-removes).

Identical handlers are automatically deduplicated — command hooks by command string, HTTP hooks by URL.

Scripts can reference themselves via environment variables: `$CLAUDE_PROJECT_DIR` (project root), `${CLAUDE_PLUGIN_ROOT}` (plugin install dir, changes per update), `${CLAUDE_PLUGIN_DATA}` (plugin persistent data).

## Input schema

Every event's stdin JSON includes these common fields:

| Field | Meaning |
|-------|---------|
| `session_id` | Current session identifier |
| `transcript_path` | Path to main conversation JSON transcript |
| `cwd` | Working directory when the hook fired |
| `permission_mode` | `default` / `plan` / `acceptEdits` / `auto` / `dontAsk` / `bypassPermissions` (not all events include this) |
| `hook_event_name` | Name of the event that fired |

When running inside a subagent (or with `--agent`), two more fields appear: `agent_id` (unique subagent identifier) and `agent_type` (name). These are how you distinguish subagent calls from main-thread calls.

Each event then adds event-specific fields (tool name, file path, agent type, error message, etc.) documented in the raw reference.

## Output: exit codes

Exit codes are the simplest signal back to Claude Code.

- **Exit 0** — success. stdout is parsed as JSON if present; for most events, stdout is written to the debug log. `SessionStart` and `UserPromptSubmit` are exceptions — their stdout is injected as context Claude can see.
- **Exit 2** — blocking error. stdout is ignored; stderr is fed back to Claude as an error message. The *effect* of blocking depends on the event (see table below).
- **Any other non-zero** — non-blocking error. Transcript shows a `<hook name> hook error` notice with the first line of stderr; execution continues. Debug log gets the full stderr.

The unix convention "exit 1 = failure" does NOT apply here: exit 1 is treated as a non-blocking error for most events. If the intent is to block, use exit 2. The one exception is `WorktreeCreate`, where any non-zero exit aborts creation.

Exit-2 behavior per event (summary — can-block only):

- **Can block**: `PreToolUse` (blocks call), `PermissionRequest` (denies), `UserPromptSubmit` (blocks and erases prompt), `Stop` / `SubagentStop` (prevents stopping), `TeammateIdle` (keeps teammate working), `TaskCreated` (rolls back), `TaskCompleted` (prevents completion), `ConfigChange` (blocks change, except `policy_settings`), `PreCompact` (blocks compaction), `Elicitation` (denies), `ElicitationResult` (blocks response), `WorktreeCreate` (any non-zero aborts).
- **Cannot block** (stderr shown to user only, or ignored): `PostToolUse`, `PostToolUseFailure`, `PermissionDenied`, `Notification`, `SubagentStart`, `SessionStart`, `SessionEnd`, `CwdChanged`, `FileChanged`, `PostCompact`, `WorktreeRemove`, `StopFailure`, `InstructionsLoaded`.

## Output: JSON

For finer-grained control than exit codes allow, exit 0 and print JSON to stdout. Universal fields:

| Field | Default | Effect |
|-------|---------|--------|
| `continue` | `true` | `false` stops Claude entirely after the hook. Takes precedence over event-specific decisions |
| `stopReason` | — | Shown to user when `continue: false` |
| `suppressOutput` | `false` | `true` omits stdout from the debug log |
| `systemMessage` | — | Warning to user |

Plus event-specific decision structures:

- **Top-level `decision: "block"` + `reason`** — used by `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SubagentStop`, `ConfigChange`, `PreCompact`.
- **`hookSpecificOutput`** — for richer control. `PreToolUse` uses `permissionDecision` (`allow`/`deny`/`ask`/`defer`) with `updatedInput` to modify tool input. `PermissionRequest` uses `decision.behavior` (`allow`/`deny`) with `updatedInput` and `updatedPermissions` (to persist rules). `PermissionDenied` uses `retry: true`. `Elicitation`/`ElicitationResult` use `action` + `content`. `SessionStart`/`SubagentStart`/`Notification`/etc. use `additionalContext`.

Rule of thumb: **pick one approach per hook** — either exit codes alone, or exit 0 with JSON. If you exit 2, any JSON is ignored.

Context-injection output (`additionalContext`, `systemMessage`, or plain stdout) is capped at 10,000 characters — overflow gets saved to a file and replaced with a preview.

HTTP hooks map: 2xx + empty body = success; 2xx + plain text = success, text added as context; 2xx + JSON body = parsed as the same JSON output schema as command hooks. Non-2xx, connection failure, or timeout = non-blocking error. To block, you must return 2xx with a decision JSON body — status codes alone can't block.

## Async and wake-on-exit

Command hooks have two background modes:

- **`async: true`** — runs in the background without blocking. Its output is not awaited. Use for side effects like "send a notification" or "append to a log."
- **`asyncRewake: true`** — runs in the background and wakes Claude on exit code 2. Its stderr (or stdout if stderr is empty) is shown to Claude as a system reminder, so Claude can react to a long-running background failure. Implies `async: true`.

## Relevance to the background wiki-ingester

For the wiki-ingester subagent the user plans to build (runs in the background, notifies when done), the pattern is:

1. **Subagent definition** at `.claude/agents/wiki-ingester.md` with `background: true` and `skills: [karpathy-llm-wiki]`. Permissions pre-approved at spawn time.
2. **Hook in `.claude/settings.json`** on `SubagentStop` with `matcher: "wiki-ingester"`. The hook command receives `agent_id`, `agent_type`, `last_assistant_message` (the ingest's summary), and `agent_transcript_path`. Surface a notification with the last-assistant-message content, or log to a file.

Alternative: put the `Stop` hook in the subagent's *frontmatter* — Claude Code auto-converts it to `SubagentStop`. Frontmatter hooks are cleaner because they're scoped to the subagent's lifetime. Settings.json hooks are shareable and central.

`asyncRewake: true` on a hook is useful if the ingest can fail asynchronously and we want Claude to see the failure without blocking the main conversation.

## See Also

- [Custom Subagents](subagents.md) — subagent frontmatter fields including `hooks`, `background`, and how `Stop` becomes `SubagentStop`
- [Extending Claude Code](extensions.md) — where hooks sit in the overall extension surface
- [Claude Code Overview](overview.md) — product-level context

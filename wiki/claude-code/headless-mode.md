# Headless Mode (Run Claude Code Programmatically)

> Sources: Anthropic Claude Code docs, 2026-04-19
> Raw: [Run Claude Code programmatically](../../raw/claude-code/2026-04-19-claude-code-headless.md)
> Updated: 2026-04-19

## Overview

"Headless mode" is Claude Code running non-interactively via the `-p` flag — the CLI prints one response and exits. The docs have renamed the concept to "Run Claude Code programmatically," since the same mechanism underlies the Agent SDK CLI, but the flag, options, and behavior are unchanged. Everything on this page lives behind `claude -p "<prompt>" [options]`; add `--bare` in CI and scripts to get deterministic startup, and pair with `--output-format json` plus `--resume` to chain prompts that share context across invocations.

## `-p` vs. interactive mode

`claude -p "<prompt>"` (alias `--print`) runs one turn non-interactively and exits. All CLI options that work interactively also work with `-p`: `--continue`, `--resume`, `--allowedTools`, `--permission-mode`, `--output-format`, `--add-dir`, `--append-system-prompt`, etc. Slash-invoked skills and built-in commands like `/commit` are **not** available in `-p` — describe the task you want accomplished instead.

## Bare mode

`--bare` skips auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and `CLAUDE.md`. It exists so CI runs get the same result on every machine regardless of what a developer happens to have configured under `~/.claude` or in the repo's `.mcp.json`. Only flags explicitly passed to the command take effect.

In bare mode Claude has access to Bash, file read, and file edit tools. Everything else has to be injected with a flag:

| To load                 | Use                                                     |
| ----------------------- | ------------------------------------------------------- |
| System prompt additions | `--append-system-prompt`, `--append-system-prompt-file` |
| Settings                | `--settings <file-or-json>`                             |
| MCP servers             | `--mcp-config <file-or-json>`                           |
| Custom agents           | `--agents <json>`                                       |
| A plugin directory      | `--plugin-dir <path>`                                   |

Bare mode also skips OAuth and keychain reads. Anthropic auth must come from `ANTHROPIC_API_KEY` or an `apiKeyHelper` inside the JSON passed to `--settings`. Bedrock/Vertex/Foundry use their own provider credentials.

The docs flag bare as the recommended mode for scripted and SDK calls, and note it will become the `-p` default in a future release. Treat `--bare` as the modern default for any `.sh` script you write.

## Output formats

`--output-format` controls how the response is returned:

| Format        | What you get                                                                                    |
| ------------- | ----------------------------------------------------------------------------------------------- |
| `text` (default) | plain text — the model's final turn                                                         |
| `json`        | one JSON object with `result`, `session_id`, `permission_denials`, `total_cost_usd`, etc.       |
| `stream-json` | newline-delimited JSON events; use with `--verbose` and `--include-partial-messages` for tokens |

For strict output shapes, combine `--output-format json` with `--json-schema '<JSON Schema>'`. The response carries your payload in `structured_output` and the usual metadata alongside it. Pipe through `jq` to pull specific fields:

```bash
claude -p "Summarize this project" --output-format json | jq -r '.result'
session_id=$(claude -p "Start a review" --output-format json | jq -r '.session_id')
```

### Streaming events worth knowing

Two `type:"system"` events carry operational signal:

- **`system/init`** — the first event (unless plugin sync runs first). Reports the model, available tools, MCP servers, and loaded plugins. The `plugins` array lists what loaded; `plugin_errors` lists demoted plugins with `plugin`/`type`/`message`. In CI, check `plugin_errors` to fail fast when a required plugin didn't load.
- **`system/api_retry`** — emitted before a retry when an API request fails. Fields: `attempt`, `max_retries`, `retry_delay_ms`, `error_status` (HTTP code or `null`), and `error` as a category (`rate_limit`, `server_error`, `authentication_failed`, `billing_error`, `invalid_request`, `max_output_tokens`, `unknown`). Surface retry progress or implement custom backoff off of this.

When `CLAUDE_CODE_SYNC_PLUGIN_INSTALL` is set, `system/plugin_install` events precede `system/init`, with `status` of `started` / `installed` / `failed` / `completed`.

## Permissions in `-p`

Three ways to approve tool use, in increasing order of scope:

1. **`--allowedTools "Read,Edit,Bash,..."`** — per-tool allowlist. Supports rule syntax from settings. `Bash(git diff *)` allows any command starting with `git diff` — the space before `*` matters: `Bash(git diff*)` would also match `git diff-index`.
2. **`--permission-mode <mode>`** — session-wide baseline. `dontAsk` denies anything not in `permissions.allow` or the built-in read-only command set (good for locked-down CI). `acceptEdits` auto-approves writes and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`); other shell commands and network calls still need an allow rule.
3. **`bypassPermissions`** — skips permission checks entirely. Docs recommend this for isolated VMs and containers. See [Running Autonomously](running-autonomously.md) for the worked example of where `bypassPermissions` succeeds after scoped `--allowedTools` silently fails on Write/Edit.

A subtle asymmetry: `Bash(<pattern>)` supports paren-scoping in `--allowedTools`, but `Write(<path>)` / `Edit(<path>)` do **not** — scope writes via `--add-dir` plus a narrower `cwd`, or via `settings.json` `permissions.allow` globs.

## Continuing and resuming conversations

Two flags, different contracts:

- `--continue` resumes the **most recent** conversation. Good for interactive shell workflows where you trust "most recent."
- `--resume <session_id>` resumes a **specific** session. Required whenever you're running multiple conversations or chaining prompts in a script.

Capture the ID from the first run's JSON output and reuse it:

```bash
session_id=$(claude -p "Start a review" --output-format json | jq -r '.session_id')
claude -p "Continue that review" --resume "$session_id"
```

This is the mechanism behind chained autonomous runs — each later prompt sees the earlier prompts' context without re-ingesting files.

## Customizing the system prompt

`--append-system-prompt "<text>"` adds instructions while keeping Claude Code's default prompt. `--append-system-prompt-file <path>` loads from a file. To replace the default prompt entirely, use `--system-prompt` (see the [CLI reference](cli-reference.md) for the full list of system-prompt flags).

Typical usage is piping input into `-p` and giving Claude a role:

```bash
gh pr diff "$1" | claude -p \
  --append-system-prompt "You are a security engineer. Review for vulnerabilities." \
  --output-format json
```

## See Also

- [Running Autonomously](running-autonomously.md) — worked example using `-p`, `--resume`, `bypassPermissions`, and session chaining.
- [CLI Reference](cli-reference.md) — every flag, including the ones referenced above.
- [Scheduled Tasks](scheduled-tasks.md) — in-session recurring runs via `/loop` and cron.
- [Cloud Routines](cloud-routines.md) — running `-p`-style jobs when your laptop is off.
- [Agent SDK](agent-sdk.md) — Python/TS equivalent of `-p` with callbacks and typed messages.
- [Settings and Configuration](settings.md) — `permissions.allow` syntax referenced by `--allowedTools`.

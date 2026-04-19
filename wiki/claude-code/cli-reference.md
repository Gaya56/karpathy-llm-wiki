# CLI Reference

> Sources: Anthropic Claude Code docs, 2026-04-19
> Raw: [CLI reference](../../raw/claude-code/2026-04-19-claude-code-cli-reference.md)
> Updated: 2026-04-19

## Overview

Complete reference for the `claude` command-line interface. Every flag the CLI accepts is listed here — note that `claude --help` intentionally omits many flags, so absence from `--help` does not mean a flag is unavailable. Commands cover starting sessions, managing auth, updating the binary, and configuring MCP/plugins. Flags fall into eight functional groups: permission, session, output, system-prompt, context, limit/budget, worktree/tmux, and multi-surface.

## Commands

| Command                         | Description                                                                                                                                   | Example                                              |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------- |
| `claude`                        | Start interactive session                                                                                                                     | `claude`                                             |
| `claude "query"`                | Start interactive session with initial prompt                                                                                                 | `claude "explain this project"`                      |
| `claude -p "query"`             | Non-interactive (SDK/headless) — print response and exit                                                                                      | `claude -p "explain this function"`                  |
| `cat file \| claude -p "query"` | Process piped content                                                                                                                         | `cat logs.txt \| claude -p "explain"`                |
| `claude -c`                     | Continue most recent conversation in current directory                                                                                        | `claude -c`                                          |
| `claude -c -p "query"`          | Continue via SDK                                                                                                                              | `claude -c -p "Check for type errors"`               |
| `claude -r "<session>" "query"` | Resume session by ID or name                                                                                                                  | `claude -r "auth-refactor" "Finish this PR"`         |
| `claude update`                 | Update to latest version                                                                                                                      | `claude update`                                      |
| `claude auth login`             | Sign in. `--email` pre-fills address, `--sso` forces SSO, `--console` bills to Anthropic Console API key instead of Claude subscription       | `claude auth login --console`                        |
| `claude auth logout`            | Log out from Anthropic account                                                                                                                | `claude auth logout`                                 |
| `claude auth status`            | Show authentication status as JSON. `--text` for human-readable output. Exits 0 if logged in, 1 if not                                       | `claude auth status`                                 |
| `claude agents`                 | List all configured subagents, grouped by source                                                                                              | `claude agents`                                      |
| `claude auto-mode defaults`     | Print built-in auto mode classifier rules as JSON. `claude auto-mode config` shows effective config with settings applied                     | `claude auto-mode defaults > rules.json`             |
| `claude mcp`                    | Configure MCP servers                                                                                                                         | `claude mcp`                                         |
| `claude plugin`                 | Manage plugins. Alias: `claude plugins`                                                                                                       | `claude plugin install code-review@claude-plugins-official` |
| `claude remote-control`         | Start a Remote Control server (no local interactive session) so Claude Code can be driven from Claude.ai or the Claude app                    | `claude remote-control --name "My Project"`          |
| `claude setup-token`            | Generate a long-lived OAuth token for CI/scripts (printed, not saved). Requires a Claude subscription                                        | `claude setup-token`                                 |

Mistyped subcommands get a did-you-mean suggestion and exit without starting a session (e.g. `claude udpate` → `Did you mean claude update?`).

## Permission flags

These flags control what tools run without prompting and under which permission mode the session operates.

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--allowedTools` | Tools that execute without prompting. Supports rule syntax (`Bash(git diff *)` allows any `git diff` command — the space before `*` matters). To restrict which tools exist at all, use `--tools` | `--allowedTools "Bash(git log *)" "Read"` |
| `--disallowedTools` | Tools removed from the model's context entirely — cannot be used at all | `--disallowedTools "Edit"` |
| `--tools` | Restrict which built-in tools Claude can use. `""` disables all, `"default"` allows all, or name them: `"Bash,Edit,Read"` | `--tools "Bash,Edit,Read"` |
| `--permission-mode` | Begin in a named permission mode: `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, or `bypassPermissions`. Overrides `defaultMode` from settings | `--permission-mode plan` |
| `--allow-dangerously-skip-permissions` | Add `bypassPermissions` to the `Shift+Tab` cycle without starting in it — lets you begin in `plan` mode and switch to bypass later | `--permission-mode plan --allow-dangerously-skip-permissions` |
| `--dangerously-skip-permissions` | Skip permission prompts entirely. Equivalent to `--permission-mode bypassPermissions` | `--dangerously-skip-permissions` |
| `--permission-prompt-tool` | Specify an MCP tool to handle permission prompts in non-interactive mode | `--permission-prompt-tool mcp_auth_tool` |

**Key asymmetry:** `Bash(<pattern>)` supports paren-scoping in `--allowedTools`, but `Write(<path>)` and `Edit(<path>)` do not — scope writes via `--add-dir` plus a narrower cwd, or via `settings.json` permission globs. See [Settings and Configuration](settings.md) for rule syntax.

## Session flags

| Flag | Short | Description | Example |
| :--- | :---- | :---------- | :------ |
| `--continue` | `-c` | Load the most recent conversation in the current directory | `claude -c` |
| `--resume` | `-r` | Resume a specific session by ID or name, or show a picker | `claude --resume auth-refactor` |
| `--fork-session` | | When resuming, create a new session ID instead of reusing the original. Use with `--resume` or `--continue` | `claude --resume abc123 --fork-session` |
| `--session-id` | | Use a specific session UUID for the conversation | `claude --session-id "550e8400-..."` |
| `--name` | `-n` | Set a display name (shown in `/resume` and terminal title). `/rename` changes it mid-session | `claude -n "my-feature"` |
| `--no-session-persistence` | | Disable saving sessions to disk (print mode only) | `claude -p --no-session-persistence "query"` |

## Output flags

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--output-format` | Print mode output format: `text` (default), `json`, or `stream-json` | `claude -p "query" --output-format json` |
| `--input-format` | Print mode input format: `text` or `stream-json` | `claude -p --input-format stream-json` |
| `--json-schema` | Validated JSON output matching a JSON Schema. Print mode only — response is in `structured_output` field | `claude -p --json-schema '{"type":"object",...}' "query"` |
| `--include-partial-messages` | Include partial streaming events. Requires `--print` and `--output-format stream-json` | `claude -p --output-format stream-json --include-partial-messages "query"` |
| `--include-hook-events` | Include hook lifecycle events in output stream. Requires `--output-format stream-json` | `claude -p --output-format stream-json --include-hook-events "query"` |
| `--replay-user-messages` | Re-emit user messages from stdin back on stdout. Requires `--input-format stream-json` and `--output-format stream-json` | `claude -p --input-format stream-json --output-format stream-json --replay-user-messages` |
| `--verbose` | Enable verbose logging — full turn-by-turn output | `claude --verbose` |
| `--debug` | Debug mode with optional category filtering (e.g. `"api,hooks"`, `"!statsig,!file"`) | `claude --debug "api,mcp"` |
| `--debug-file <path>` | Write debug logs to a file. Implicitly enables debug mode. Takes precedence over `CLAUDE_CODE_DEBUG_LOGS_DIR` | `claude --debug-file /tmp/claude-debug.log` |

## System-prompt flags

All four flags work in both interactive and non-interactive modes.

| Flag | Behavior | Example |
| :--- | :------- | :------ |
| `--system-prompt` | Replaces the entire default prompt | `claude --system-prompt "You are a Python expert"` |
| `--system-prompt-file` | Replaces with file contents | `claude --system-prompt-file ./prompts/review.txt` |
| `--append-system-prompt` | Appends text to the default prompt | `claude --append-system-prompt "Always use TypeScript"` |
| `--append-system-prompt-file` | Appends file contents to the default prompt | `claude --append-system-prompt-file ./style-rules.txt` |

`--system-prompt` and `--system-prompt-file` are mutually exclusive. Append flags can combine with either replacement flag. For most use cases, prefer an append flag — it preserves Claude Code's built-in capabilities while adding your requirements. Use a replacement flag only when you need complete control.

`--exclude-dynamic-system-prompt-sections` moves per-machine sections (working directory, environment info, memory paths, git status) into the first user message instead, improving prompt-cache reuse across different users and machines running the same task. Only applies with the default system prompt; ignored when `--system-prompt` or `--system-prompt-file` is set.

## Context flags

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--add-dir` | Add additional working directories for Claude to read and edit files. Grants file access; most `.claude/` configuration is not discovered from added dirs | `claude --add-dir ../apps ../lib` |
| `--settings` | Path to a settings JSON file or a JSON string | `claude --settings ./settings.json` |
| `--setting-sources` | Comma-separated list of setting sources to load: `user`, `project`, `local` | `claude --setting-sources user,project` |
| `--mcp-config` | Load MCP servers from JSON files or strings (space-separated) | `claude --mcp-config ./mcp.json` |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config`, ignoring all other MCP configurations | `claude --strict-mcp-config --mcp-config ./mcp.json` |
| `--agents` | Define custom subagents dynamically via JSON. Same field names as subagent frontmatter plus a `prompt` field | `claude --agents '{"reviewer":{"description":"...","prompt":"..."}}'` |
| `--agent` | Specify a named agent for the current session (overrides the `agent` setting) | `claude --agent my-custom-agent` |
| `--plugin-dir` | Load plugins from a directory for this session only. Repeat for multiple directories | `claude --plugin-dir ./my-plugins` |
| `--bare` | Skip auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and CLAUDE.md. Sets `CLAUDE_CODE_SIMPLE`. Claude gets Bash, file read, and file edit. Recommended for CI scripts — will become the `-p` default in a future release | `claude --bare -p "query"` |
| `--disable-slash-commands` | Disable all skills and commands for this session | `claude --disable-slash-commands` |
| `--model` | Set the model for the current session. Use alias (`sonnet`, `opus`) or full model name | `claude --model claude-sonnet-4-6` |
| `--effort` | Set effort level: `low`, `medium`, `high`, `xhigh`, `max`. Session-scoped, does not persist to settings | `claude --effort high` |
| `--betas` | Beta headers to include in API requests (API key users only) | `claude --betas interleaved-thinking` |

## Limit / budget flags

Print mode only.

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--max-turns` | Limit agentic turns. Exits with an error when limit is reached. No limit by default | `claude -p --max-turns 3 "query"` |
| `--max-budget-usd` | Maximum dollars to spend on API calls before stopping | `claude -p --max-budget-usd 5.00 "query"` |
| `--fallback-model` | Automatically fall back to this model when the default model is overloaded | `claude -p --fallback-model sonnet "query"` |

## Worktree / tmux flags

| Flag | Short | Description | Example |
| :--- | :---- | :---------- | :------ |
| `--worktree` | `-w` | Start Claude in an isolated git worktree at `<repo>/.claude/worktrees/<name>`. Auto-generates a name if none given | `claude -w feature-auth` |
| `--tmux` | | Create a tmux session for the worktree. Requires `--worktree`. Uses iTerm2 native panes when available; pass `--tmux=classic` for traditional tmux | `claude -w feature-auth --tmux` |
| `--teammate-mode` | | How agent-team teammates display: `auto` (default), `in-process`, or `tmux` | `claude --teammate-mode in-process` |

## Multi-surface flags

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--remote` | Create a new web session on claude.ai with the provided task description | `claude --remote "Fix the login bug"` |
| `--teleport` | Resume a web session in your local terminal | `claude --teleport` |
| `--remote-control`, `--rc` | Start an interactive session with Remote Control enabled (controllable from Claude.ai or the Claude app) | `claude --remote-control "My Project"` |
| `--remote-control-session-name-prefix <prefix>` | Prefix for auto-generated Remote Control session names. Defaults to machine hostname. Env var: `CLAUDE_REMOTE_CONTROL_SESSION_NAME_PREFIX` | `claude remote-control --remote-control-session-name-prefix dev-box` |
| `--from-pr` | Resume sessions linked to a specific GitHub PR (number or URL). Sessions are linked when created via `gh pr create` | `claude --from-pr 123` |
| `--ide` | Automatically connect to IDE on startup when exactly one valid IDE is available | `claude --ide` |
| `--chrome` | Enable Chrome browser integration for web automation and testing | `claude --chrome` |
| `--no-chrome` | Disable Chrome browser integration for this session | `claude --no-chrome` |
| `--channels` | (Research preview) MCP server channels to listen for in this session. Requires Claude.ai auth | `claude --channels plugin:my-notifier@my-marketplace` |
| `--dangerously-load-development-channels` | Enable channels not on the approved allowlist, for local development. Prompts for confirmation | `claude --dangerously-load-development-channels server:webhook` |

## Initialization flags

| Flag | Description | Example |
| :--- | :---------- | :------ |
| `--init` | Run initialization hooks and start interactive mode | `claude --init` |
| `--init-only` | Run initialization hooks and exit (no interactive session) | `claude --init-only` |
| `--maintenance` | Run maintenance hooks and start interactive mode | `claude --maintenance` |
| `--version`, `-v` | Output the version number | `claude -v` |

## See Also

- [Headless Mode](headless-mode.md) — full treatment of `-p`, `--bare`, output formats, streaming events, and session chaining
- [Running Autonomously](running-autonomously.md) — worked example using `bypassPermissions`, `--resume`, and multi-turn scripting
- [Scheduled Tasks](scheduled-tasks.md) — in-session recurring runs via `/loop` and cron
- [Cloud Routines](cloud-routines.md) — running `-p`-style jobs remotely
- [Desktop](desktop.md) — desktop-specific surfaces and worktree workflows
- [Agent SDK](agent-sdk.md) — Python/TS programmatic equivalent of `-p`
- [Settings and Configuration](settings.md) — `permissions.allow` rule syntax, `defaultMode`, and settings scopes
- [Custom Subagents](subagents.md) — subagent frontmatter fields used by `--agents`
- [Claude Code Overview](overview.md) — product surfaces and capability map

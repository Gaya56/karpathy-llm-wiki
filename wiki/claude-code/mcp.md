# MCP in Claude Code

> Sources: Anthropic, 2026-04-17
> Raw: [2026-04-17-claude-code-mcp](../../raw/claude-code/2026-04-17-claude-code-mcp.md)
> Updated: 2026-04-17

## Overview

MCP (Model Context Protocol) is the open-standard mechanism for connecting Claude Code to external tools, databases, and APIs. Servers give Claude Code live access to systems it can't reach natively — issue trackers, databases, monitoring dashboards, design tools, and more. Three transport types (HTTP, SSE, stdio) cover the spectrum from cloud services to local scripts. Scope controls determine whether a configuration is private, project-shared, or user-wide.

## What MCP enables

The practical trigger for adding an MCP server is repeated context-pasting: when you keep copying data from another tool into chat, an MCP connection eliminates that. With servers connected, Claude Code can:

- Implement features directly from issue tracker tickets (JIRA, GitHub)
- Query production databases in natural language
- Pull monitoring data from Sentry, Statsig, and similar services
- Update designs based on Figma changes posted in Slack
- Draft emails or calendar invites from workflow context
- React to external events (CI results, Telegram messages, webhook events) via the channels feature

## Installing servers

Three transport options, in recommended order:

**HTTP** is the preferred transport for cloud-based services:

```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

**SSE** (Server-Sent Events) is deprecated — use HTTP where available:

```bash
claude mcp add --transport sse asana https://mcp.asana.com/sse
```

**Stdio** runs a local process, suitable for tools needing direct system access or custom scripts:

```bash
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server
```

Important flag ordering: all options (`--transport`, `--env`, `--scope`, `--header`) must precede the server name; `--` separates the server name from the command passed to the MCP server.

**Managing servers:**

```bash
claude mcp list
claude mcp get github
claude mcp remove github
/mcp           # within Claude Code — check status, authenticate
```

**JSON-based addition** for when you have a config blob:

```bash
claude mcp add-json weather-api '{"type":"http","url":"https://api.weather.com/mcp"}'
```

**Import from Claude Desktop** (macOS and WSL only):

```bash
claude mcp add-from-claude-desktop
```

**Claude.ai connectors**: Servers configured at `claude.ai/settings/connectors` are automatically available when logged in with a Claude.ai account. Disable with `ENABLE_CLAUDEAI_MCP_SERVERS=false`.

## Scope and configuration storage

Three scopes control visibility and sharing:

| Scope   | Loads in             | Shared with team         | Stored in                   |
|---------|----------------------|--------------------------|------------------------------|
| Local   | Current project only | No                       | `~/.claude.json`            |
| Project | Current project only | Yes, via version control | `.mcp.json` in project root |
| User    | All your projects    | No                       | `~/.claude.json`            |

Local is the default. Use `--scope project` to write to `.mcp.json` for team sharing; Claude Code prompts for approval before using project-scoped servers. Use `--scope user` for personal cross-project tools.

**Precedence** when the same server name is defined in multiple places: Local > Project > User > Plugin > claude.ai connectors.

**Environment variable expansion in `.mcp.json`:**

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": { "Authorization": "Bearer ${API_KEY}" }
    }
  }
}
```

Supported syntax: `${VAR}` (required) and `${VAR:-default}` (optional with fallback). Expands in `command`, `args`, `env`, `url`, and `headers`.

## Authentication

**OAuth 2.0** is the standard path for cloud servers:

1. Add the server: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
2. Run `/mcp` in Claude Code, follow the browser login flow.

OAuth tokens are stored securely and refreshed automatically. Use `/mcp` > "Clear authentication" to revoke.

**Fixed callback port** for servers with pre-registered redirect URIs:

```bash
claude mcp add --transport http --callback-port 8080 my-server https://mcp.example.com/mcp
```

**Pre-configured credentials** for servers that don't support Dynamic Client Registration:

```bash
claude mcp add --transport http \
  --client-id your-client-id --client-secret --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

**Override OAuth metadata discovery** via `authServerMetadataUrl` in `.mcp.json`'s `oauth` object (requires v2.1.64+).

**Restrict OAuth scopes** via `oauth.scopes` — a space-separated string that pins which scopes Claude Code requests:

```json
"oauth": { "scopes": "channels:read chat:write search:read" }
```

**Dynamic headers for non-OAuth authentication** via `headersHelper` — runs a shell command at connection time and merges its JSON output into the request headers. Receives `CLAUDE_CODE_MCP_SERVER_NAME` and `CLAUDE_CODE_MCP_SERVER_URL` environment variables. 10-second timeout, no caching.

## Reliability features

**Automatic reconnection**: HTTP and SSE servers reconnect with exponential backoff on disconnect — up to five attempts, starting at 1 second and doubling each time. After five failures, the server is marked failed and can be retried from `/mcp`. Stdio servers are local processes and do not auto-reconnect.

**Dynamic tool updates**: Servers can send `list_changed` notifications, causing Claude Code to refresh available tools, prompts, and resources without a session restart.

**Push messages (channels)**: Servers that declare the `claude/channel` capability and are started with `--channels` can push messages directly into the session — enabling Claude to react to CI results, monitoring alerts, or chat messages while you're away.

## Context efficiency: MCP Tool Search

Tool Search keeps MCP from bloating the context window. By default, only tool names load at session start; full schemas are deferred and discovered on demand when a task needs them. This means adding many MCP servers has minimal upfront context cost.

Control via `ENABLE_TOOL_SEARCH`:

| Value      | Behavior                                                                    |
|:-----------|:----------------------------------------------------------------------------|
| (unset)    | All tools deferred on demand (falls back to upfront for non-Anthropic hosts)|
| `true`     | Force deferral even for non-first-party `ANTHROPIC_BASE_URL`                |
| `auto`     | Threshold mode: load upfront if tools fit within 10% of context window      |
| `auto:<N>` | Custom threshold percentage                                                 |
| `false`    | Load all tools upfront, no deferral                                         |

Requires Sonnet 4+ or Opus 4+. Haiku does not support tool search.

For MCP server authors: clear server instructions help Claude know when to search for your tools, similar to how skills work. Tool descriptions and server instructions are truncated at 2KB — put critical details near the start.

## Output limits

- Warning threshold: 10,000 tokens per tool call
- Default maximum: 25,000 tokens
- Override: `MAX_MCP_OUTPUT_TOKENS=50000`

Server authors can raise the per-tool limit by annotating `_meta["anthropic/maxResultSizeChars"]` in `tools/list` — up to a hard ceiling of 500,000 characters. This annotation applies only to text content; image output is still subject to `MAX_MCP_OUTPUT_TOKENS`.

## MCP features: resources, prompts, and elicitation

**Resources**: Servers can expose data as addressable resources referenced via `@server:protocol://resource/path` in any prompt. Resources appear in the `@` autocomplete menu alongside files.

**Prompts as commands**: Server-defined prompts appear as `/mcp__servername__promptname` slash commands:

```text
/mcp__github__list_prs
/mcp__github__pr_review 456
```

**Elicitation**: Servers can request structured input mid-task. Claude Code shows either a form dialog or opens a browser URL; responses are passed back to the server automatically. Use the `Elicitation` hook to auto-respond without a dialog.

## Claude Code as an MCP server

Claude Code can itself serve as a stdio MCP server for other applications:

```bash
claude mcp serve
```

Claude Desktop config:

```json
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

Use `which claude` if the binary isn't in PATH and specify the full path in `command`.

## Managed MCP for organizations

Two options for centralized control:

**Option 1 — Exclusive control (`managed-mcp.json`)**: Users cannot add, modify, or use any MCP servers outside this file. Deploy to system paths (require admin privileges):

- macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- Linux/WSL: `/etc/claude-code/managed-mcp.json`
- Windows: `C:\Program Files\ClaudeCode\managed-mcp.json`

**Option 2 — Policy-based (allowlists/denylists)**: Users can configure servers within constraints defined in the managed settings file using `allowedMcpServers` / `deniedMcpServers`. Each entry restricts by one of:

- `serverName` — name match
- `serverCommand` — exact command-plus-args array match (for stdio)
- `serverUrl` — URL with wildcard support (e.g., `https://mcp.company.com/*`)

Denylist takes absolute precedence: a match blocks the server even if it's on the allowlist. Both options can be combined — `managed-mcp.json` takes exclusive control, and the allowlist/denylist still filters which managed servers load.

## Plugin-provided MCP servers

Plugins bundle MCP servers in `.mcp.json` at the plugin root or inline in `plugin.json`. They start automatically when the plugin is enabled and appear alongside user-configured servers. Run `/reload-plugins` to connect or disconnect plugin servers mid-session.

Plugin-specific environment variables:
- `${CLAUDE_PLUGIN_ROOT}` — bundled plugin files
- `${CLAUDE_PLUGIN_DATA}` — persistent state directory (survives plugin updates)

## See Also

- [Extending Claude Code](extensions.md) — where MCP fits among CLAUDE.md, Skills, Subagents, Agent Teams, Hooks, and Plugins
- [Custom Subagents](subagents.md) — `mcpServers` frontmatter field for subagent-scoped MCP connections
- [Settings and Configuration](settings.md) — `allowedMcpServers`, `deniedMcpServers`, and `env` fields in settings.json
- [Hooks Reference](hooks.md) — `Elicitation` hook for auto-responding to MCP elicitation requests
- [Running Claude Code Autonomously](running-autonomously.md) — project-scoped MCP registration (`--scope project`) in autonomous runs

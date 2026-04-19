# Connect Claude Code to tools via MCP

> Source: https://code.claude.com/docs/en/mcp
> Collected: 2026-04-17
> Published: Unknown

Learn how to connect Claude Code to your tools with the Model Context Protocol.

Claude Code can connect to hundreds of external tools and data sources through the Model Context Protocol (MCP), an open source standard for AI-tool integrations. MCP servers give Claude Code access to your tools, databases, and APIs.

Connect a server when you find yourself copying data into chat from another tool, like an issue tracker or a monitoring dashboard. Once connected, Claude can read and act on that system directly instead of working from what you paste.

## What you can do with MCP

With MCP servers connected, you can ask Claude Code to:

- **Implement features from issue trackers**: "Add the feature described in JIRA issue ENG-4521 and create a PR on GitHub."
- **Analyze monitoring data**: "Check Sentry and Statsig to check the usage of the feature described in ENG-4521."
- **Query databases**: "Find emails of 10 random users who used feature ENG-4521, based on our PostgreSQL database."
- **Integrate designs**: "Update our standard email template based on the new Figma designs that were posted in Slack"
- **Automate workflows**: "Create Gmail drafts inviting these 10 users to a feedback session about the new feature."
- **React to external events**: An MCP server can also act as a channel that pushes messages into your session, so Claude reacts to Telegram messages, Discord chats, or webhook events while you're away.

## Installing MCP servers

MCP servers can be configured in three different ways depending on your needs.

### Option 1: Add a remote HTTP server

HTTP servers are the recommended option for connecting to remote MCP servers. This is the most widely supported transport for cloud-based services.

```bash
# Basic syntax
claude mcp add --transport http <name> <url>

# Real example: Connect to Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Example with Bearer token
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

### Option 2: Add a remote SSE server

The SSE (Server-Sent Events) transport is deprecated. Use HTTP servers instead, where available.

```bash
# Basic syntax
claude mcp add --transport sse <name> <url>

# Real example: Connect to Asana
claude mcp add --transport sse asana https://mcp.asana.com/sse

# Example with authentication header
claude mcp add --transport sse private-api https://api.company.com/sse \
  --header "X-API-Key: your-key-here"
```

### Option 3: Add a local stdio server

Stdio servers run as local processes on your machine. They're ideal for tools that need direct system access or custom scripts.

```bash
# Basic syntax
claude mcp add [options] <name> -- <command> [args...]

# Real example: Add Airtable server
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server
```

Important: All options (`--transport`, `--env`, `--scope`, `--header`) must come before the server name. The `--` (double dash) then separates the server name from the command and arguments.

### Managing your servers

```bash
# List all configured servers
claude mcp list

# Get details for a specific server
claude mcp get github

# Remove a server
claude mcp remove github

# (within Claude Code) Check server status
/mcp
```

### Dynamic tool updates

Claude Code supports MCP `list_changed` notifications, allowing MCP servers to dynamically update their available tools, prompts, and resources without requiring you to disconnect and reconnect.

### Automatic reconnection

If an HTTP or SSE server disconnects mid-session, Claude Code automatically reconnects with exponential backoff: up to five attempts, starting at a one-second delay and doubling each time. After five failed attempts the server is marked as failed and you can retry manually from `/mcp`. Stdio servers are local processes and are not reconnected automatically.

### Push messages with channels

An MCP server can also push messages directly into your session so Claude can react to external events like CI results, monitoring alerts, or chat messages. To enable this, your server declares the `claude/channel` capability and you opt it in with the `--channels` flag at startup.

### Scope flags

- `local` (default): Available only to you in the current project, stored in `~/.claude.json`
- `project`: Shared with everyone in the project via `.mcp.json` file
- `user`: Available to you across all projects, stored in `~/.claude.json`

## MCP installation scopes

| Scope   | Loads in             | Shared with team         | Stored in                   |
|---------|----------------------|--------------------------|------------------------------|
| Local   | Current project only | No                       | `~/.claude.json`            |
| Project | Current project only | Yes, via version control | `.mcp.json` in project root |
| User    | All your projects    | No                       | `~/.claude.json`            |

### Scope hierarchy and precedence

When the same server is defined in more than one place:

1. Local scope
2. Project scope
3. User scope
4. Plugin-provided servers
5. claude.ai connectors

### Environment variable expansion in `.mcp.json`

Supported syntax:
- `${VAR}` — Expands to the value of environment variable `VAR`
- `${VAR:-default}` — Expands to `VAR` if set, otherwise uses `default`

Variables can be expanded in `command`, `args`, `env`, `url`, and `headers`.

## Authenticate with remote MCP servers

Many cloud-based MCP servers require authentication. Claude Code supports OAuth 2.0 for secure connections.

1. Add the server: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
2. Use `/mcp` within Claude Code and follow the browser login flow.

Tips:
- Authentication tokens are stored securely and refreshed automatically
- Use "Clear authentication" in the `/mcp` menu to revoke access
- OAuth authentication works with HTTP servers

### Use a fixed OAuth callback port

Use `--callback-port` to fix the port so it matches a pre-registered redirect URI of the form `http://localhost:PORT/callback`.

```bash
claude mcp add --transport http \
  --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

### Use pre-configured OAuth credentials

For servers that don't support Dynamic Client Registration:

```bash
claude mcp add --transport http \
  --client-id your-client-id --client-secret --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

### Override OAuth metadata discovery

Set `authServerMetadataUrl` in the `oauth` object of your server's config in `.mcp.json`:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "oauth": {
        "authServerMetadataUrl": "https://auth.example.com/.well-known/openid-configuration"
      }
    }
  }
}
```

Requires Claude Code v2.1.64 or later.

### Restrict OAuth scopes

Set `oauth.scopes` to pin the scopes Claude Code requests during the authorization flow:

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://mcp.slack.com/mcp",
      "oauth": {
        "scopes": "channels:read chat:write search:read"
      }
    }
  }
}
```

### Use dynamic headers for custom authentication

Use `headersHelper` to generate request headers at connection time for non-OAuth authentication schemes:

```json
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "https://mcp.internal.example.com",
      "headersHelper": "/opt/bin/get-mcp-auth-headers.sh"
    }
  }
}
```

The command must write a JSON object of string key-value pairs to stdout. The command runs with a 10-second timeout and receives `CLAUDE_CODE_MCP_SERVER_NAME` and `CLAUDE_CODE_MCP_SERVER_URL` environment variables.

## Add MCP servers from JSON configuration

```bash
# Basic syntax
claude mcp add-json <name> '<json>'

# Example: Adding an HTTP server with JSON configuration
claude mcp add-json weather-api '{"type":"http","url":"https://api.weather.com/mcp","headers":{"Authorization":"Bearer token"}}'
```

## Import MCP servers from Claude Desktop

```bash
claude mcp add-from-claude-desktop
```

Works on macOS and Windows Subsystem for Linux (WSL) only.

## Use MCP servers from Claude.ai

If you've logged into Claude Code with a Claude.ai account, MCP servers you've added in Claude.ai are automatically available in Claude Code. Configure servers at claude.ai/settings/connectors.

To disable claude.ai MCP servers in Claude Code:
```bash
ENABLE_CLAUDEAI_MCP_SERVERS=false claude
```

## Use Claude Code as an MCP server

```bash
# Start Claude as a stdio MCP server
claude mcp serve
```

Claude Desktop configuration:

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

## MCP output limits and warnings

- **Output warning threshold**: Claude Code displays a warning when any MCP tool output exceeds 10,000 tokens
- **Configurable limit**: Adjust using `MAX_MCP_OUTPUT_TOKENS` environment variable
- **Default limit**: 25,000 tokens

### Raise the limit for a specific tool

MCP server authors can set `_meta["anthropic/maxResultSizeChars"]` in the tool's `tools/list` response entry. Claude Code raises that tool's threshold up to a hard ceiling of 500,000 characters.

```json
{
  "name": "get_schema",
  "description": "Returns the full database schema",
  "_meta": {
    "anthropic/maxResultSizeChars": 200000
  }
}
```

## Respond to MCP elicitation requests

MCP servers can request structured input from you mid-task using elicitation. When a server needs information, Claude Code displays an interactive dialog and passes your response back to the server.

Servers can request input in two ways:
- **Form mode**: Claude Code shows a dialog with form fields defined by the server
- **URL mode**: Claude Code opens a browser URL for authentication or approval

## Use MCP resources

MCP servers can expose resources that you can reference using @ mentions.

```text
Can you analyze @github:issue://123 and suggest a fix?
```

Reference format: `@server:protocol://resource/path`

## Scale with MCP Tool Search

Tool search keeps MCP context usage low by deferring tool definitions until Claude needs them. Only tool names load at session start.

Control behavior with the `ENABLE_TOOL_SEARCH` environment variable:

| Value      | Behavior                                                                     |
|:-----------|:-----------------------------------------------------------------------------|
| (unset)    | All MCP tools deferred and loaded on demand                                  |
| `true`     | All MCP tools deferred, including for non-first-party `ANTHROPIC_BASE_URL`   |
| `auto`     | Threshold mode: tools load upfront if they fit within 10% of context window  |
| `auto:<N>` | Threshold mode with a custom percentage                                       |
| `false`    | All MCP tools loaded upfront, no deferral                                    |

Requires models that support `tool_reference` blocks: Sonnet 4 and later, or Opus 4 and later. Haiku models do not support tool search.

## Use MCP prompts as commands

MCP servers can expose prompts that become available as slash commands:

```text
/mcp__github__list_prs
/mcp__github__pr_review 456
```

## Managed MCP configuration

For organizations needing centralized control:

**Option 1: Exclusive control with `managed-mcp.json`** — Deploy a fixed set of MCP servers that users cannot modify.

System paths:
- macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- Linux and WSL: `/etc/claude-code/managed-mcp.json`
- Windows: `C:\Program Files\ClaudeCode\managed-mcp.json`

**Option 2: Policy-based control with allowlists/denylists** — Allow users to add their own servers within policy constraints using `allowedMcpServers` and `deniedMcpServers` in the managed settings file.

Each entry can restrict servers by:
- `serverName` — Matches the configured name
- `serverCommand` — Matches the exact command and arguments (exact match required)
- `serverUrl` — Matches remote server URLs with wildcard support

Denylist takes absolute precedence: a server matching a denylist entry is blocked even if on the allowlist.

## Plugin-provided MCP servers

Plugins can bundle MCP servers in `.mcp.json` at the plugin root or inline in `plugin.json`. When a plugin is enabled, its MCP servers start automatically and appear alongside manually configured MCP tools.

Environment variables available in plugin MCP configs:
- `${CLAUDE_PLUGIN_ROOT}` — path to bundled plugin files
- `${CLAUDE_PLUGIN_DATA}` — path to persistent state directory

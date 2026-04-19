# Agent SDK

> Sources: Anthropic, 2026-04-19
> Raw: [Agent SDK Overview](../../raw/claude-code/2026-04-19-claude-code-agent-sdk-overview.md)
> Updated: 2026-04-19

## Overview

The Claude Agent SDK (formerly the Claude Code SDK — see the migration guide for upgrading) lets you build production AI agents in Python and TypeScript using the same tools, agent loop, and context management that power Claude Code. The core API is `query()` with `ClaudeAgentOptions`; the function returns an async stream of messages. Opus 4.7 requires SDK v0.2.111 or later — if you see a `thinking.type.enabled` error, upgrade.

## Installation and Authentication

Install via pip (`claude-agent-sdk`) or npm (`@anthropic-ai/claude-agent-sdk`). The TypeScript package bundles a native Claude Code binary so no separate Claude Code install is needed.

Authenticate with `ANTHROPIC_API_KEY`. The SDK also supports Amazon Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`), Google Vertex AI (`CLAUDE_CODE_USE_VERTEX=1`), and Microsoft Azure (`CLAUDE_CODE_USE_FOUNDRY=1`).

## Core API

`query(prompt, options)` is the entry point. It returns an async iterable of message objects. `ClaudeAgentOptions` (Python) / option object (TypeScript) controls every aspect of the agent's behavior.

```python
from claude_agent_sdk import query, ClaudeAgentOptions

async for message in query(
    prompt="Find and fix the bug in auth.py",
    options=ClaudeAgentOptions(allowed_tools=["Read", "Edit", "Bash"]),
):
    print(message)
```

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Find and fix the bug in auth.ts",
  options: { allowedTools: ["Read", "Edit", "Bash"] }
})) {
  console.log(message);
}
```

## Built-in Tools

The SDK ships ten built-in tools:

| Tool | Purpose |
|------|---------|
| Read | Read any file in the working directory |
| Write | Create new files |
| Edit | Make precise edits to existing files |
| Bash | Run terminal commands, scripts, git operations |
| Monitor | Watch a background script; react to each output line as an event |
| Glob | Find files by pattern (`**/*.ts`, `src/**/*.py`) |
| Grep | Search file contents with regex |
| WebSearch | Search the web for current information |
| WebFetch | Fetch and parse web page content |
| AskUserQuestion | Ask the user clarifying questions with multiple-choice options |

Pass a subset via `allowed_tools` / `allowedTools` to restrict the agent to safe operations.

## Hooks

SDK hooks are callback functions that run at key points in the agent lifecycle. Available events: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`. Use `HookMatcher` (Python) or an inline object (TypeScript) to filter by tool name with a regex matcher string (e.g. `"Edit|Write"`).

Hooks can validate, log, block, or transform behavior. Returning `{}` is a no-op pass-through; returning a modified object or raising can block or alter a tool call.

```python
from claude_agent_sdk import ClaudeAgentOptions, HookMatcher

options=ClaudeAgentOptions(
    hooks={
        "PostToolUse": [
            HookMatcher(matcher="Edit|Write", hooks=[log_file_change])
        ]
    }
)
```

## Subagents

Define named subagents via the `agents` option (`AgentDefinition` in Python). Include `"Agent"` in `allowedTools` — subagents are invoked through the `Agent` built-in tool. Each subagent gets its own `description`, `prompt`, and `tools` list. Messages emitted inside a subagent's execution carry a `parent_tool_use_id` field, enabling caller-side attribution of which messages belong to which subagent run.

## MCP Support

Pass `mcp_servers` / `mcpServers` in options — a dict/object mapping server names to `{command, args}` specs. The SDK starts the MCP server and wires its tools into the agent loop automatically.

```python
options=ClaudeAgentOptions(
    mcp_servers={"playwright": {"command": "npx", "args": ["@playwright/mcp@latest"]}}
)
```

## Permission Controls

`allowed_tools` / `allowedTools` is the primary control: pass only the tools the agent should be allowed to use. For write operations you can also set `permission_mode="acceptEdits"` to pre-approve file edits. For interactive flows, `AskUserQuestion` lets Claude surface approval prompts to the user at runtime.

## Sessions

Sessions maintain context across multiple `query()` calls. Capture `session_id` from the `init`-subtype `SystemMessage` at the start of any query, then pass it as `resume=session_id` / `resume: sessionId` in a later call to continue with full history.

```python
from claude_agent_sdk import SystemMessage

session_id = None
async for message in query(prompt="Read the auth module", options=...):
    if isinstance(message, SystemMessage) and message.subtype == "init":
        session_id = message.data["session_id"]

# Later:
async for message in query(
    prompt="Now find all callers",
    options=ClaudeAgentOptions(resume=session_id),
):
    ...
```

You can also fork sessions to explore diverging approaches from the same checkpoint.

## Filesystem-based Configuration

By default the SDK loads Claude Code's filesystem configuration from `.claude/` in the working directory and `~/.claude/`. Use `setting_sources` (Python) / `settingSources` (TypeScript) to restrict which sources are loaded.

| Feature | Location |
|---------|----------|
| Skills | `.claude/skills/*/SKILL.md` |
| Slash commands | `.claude/commands/*.md` |
| Memory / CLAUDE.md | `CLAUDE.md` or `.claude/CLAUDE.md` |
| Plugins | Programmatic via `plugins` option |

This means any skills, memory files, or slash commands present in `.claude/` of the working directory are automatically available to your SDK agent — the same as when running the CLI.

## Agent SDK vs Client SDK

The Anthropic Client SDK gives raw API access: you receive a response, check `stop_reason == "tool_use"`, run the tool yourself, and loop. The Agent SDK internalises that loop — you call `query()` once and Claude drives tools to completion autonomously. Choose the Client SDK when you need precise, low-level control over every tool execution step. Choose the Agent SDK when you want a working agent with minimal boilerplate.

## Agent SDK vs Claude Code CLI

Same underlying capabilities, different interface:

| Use case | Best choice |
|----------|-------------|
| Interactive development | CLI (`claude -p` for headless) |
| CI/CD pipelines | SDK |
| Custom applications | SDK |
| One-off tasks | CLI |
| Production automation | SDK |

Many teams use both: CLI for daily development, SDK for production pipelines. Prompts and tool configurations translate directly between them.

## See Also

- [Headless Mode](headless-mode.md) — `claude -p` non-interactive runs, the CLI counterpart to SDK usage
- [CLI Reference](cli-reference.md) — full CLI flags and options
- [Cloud Routines](cloud-routines.md) — running agents in CI/CD and cloud contexts
- [Custom Subagents](subagents.md) — subagent configuration reference
- [Running Autonomously](running-autonomously.md) — autonomous operation patterns and safety
- [Claude Code Overview](overview.md) — product overview and capability categories

# Create custom subagents

> Source: https://code.claude.com/docs/en/sub-agents
> Collected: 2026-04-16
> Published: Unknown

Create and use specialized AI subagents in Claude Code for task-specific workflows and improved context management.

Subagents are specialized AI assistants that handle specific types of tasks. Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and returns only the summary. Define a custom subagent when you keep spawning the same kind of worker with the same instructions.

Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions. When Claude encounters a task that matches a subagent's description, it delegates to that subagent, which works independently and returns results.

Note: If you need multiple agents working in parallel and communicating with each other, see agent teams instead. Subagents work within a single session; agent teams coordinate across separate sessions.

Subagents help you:
- Preserve context by keeping exploration and implementation out of your main conversation
- Enforce constraints by limiting which tools a subagent can use
- Reuse configurations across projects with user-level subagents
- Specialize behavior with focused system prompts for specific domains
- Control costs by routing tasks to faster, cheaper models like Haiku

Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it.

Claude Code includes several built-in subagents like Explore, Plan, and general-purpose. You can also create custom subagents to handle specific tasks.

## Built-in subagents

Claude Code includes built-in subagents that Claude automatically uses when appropriate. Each inherits the parent conversation's permissions with additional tool restrictions.

**Explore** — Fast, read-only agent optimized for searching and analyzing codebases. Model: Haiku. Tools: read-only (no Write/Edit). Thoroughness levels: quick, medium, very thorough.

**Plan** — Research agent used during plan mode to gather context before presenting a plan. Model: inherits from main. Tools: read-only. Prevents infinite nesting (subagents cannot spawn other subagents).

**General-purpose** — Capable agent for complex, multi-step tasks that require both exploration and action. Model: inherits. Tools: all.

**Other** — Additional helper agents typically invoked automatically:

| Agent | Model | When Claude uses it |
|-------|-------|----------------------|
| statusline-setup | Sonnet | When you run `/statusline` to configure your status line |
| Claude Code Guide | Haiku | When you ask questions about Claude Code features |

## Quickstart: create your first subagent

Subagents are defined in Markdown files with YAML frontmatter. You can create them manually or use the `/agents` command.

Walkthrough with `/agents`:
1. Run `/agents` in Claude Code.
2. Switch to the Library tab, select Create new agent, choose Personal. Saves to `~/.claude/agents/`.
3. Select Generate with Claude. Describe the subagent. Claude generates the identifier, description, and system prompt.
4. Select tools — deselect everything except read-only tools for a reviewer.
5. Select model — Sonnet is a good balance.
6. Choose a color for UI identification.
7. Configure memory — User scope gives `~/.claude/agent-memory/` directory for cross-conversation persistence. None disables.
8. Save with `s` or Enter.

You can also create subagents manually as Markdown files, define them via CLI flags, or distribute them through plugins.

## Configure subagents

### Use the /agents command

The `/agents` command opens a tabbed interface. Running tab shows live subagents (open or stop). Library tab lets you view, create, edit, delete subagents. Shows which are active when duplicates exist.

From CLI without interactive session: `claude agents` lists all configured subagents grouped by source, indicating which are overridden.

### Choose the subagent scope

Subagents are Markdown files with YAML frontmatter. Scope by location; higher priority wins on name collision.

| Location | Scope | Priority | How to create |
|----------|-------|----------|---------------|
| Managed settings | Organization-wide | 1 (highest) | Deployed via managed settings |
| `--agents` CLI flag | Current session | 2 | Pass JSON when launching Claude Code |
| `.claude/agents/` | Current project | 3 | Interactive or manual |
| `~/.claude/agents/` | All your projects | 4 | Interactive or manual |
| Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest) | Installed with plugins |

Project subagents (`.claude/agents/`) are ideal for subagents specific to a codebase — check into version control.

Project subagents are discovered by walking up from the current working directory. Directories added with `--add-dir` grant file access only and are not scanned for subagents.

User subagents (`~/.claude/agents/`) are personal subagents available in all your projects.

CLI-defined subagents (`--agents` flag) are passed as JSON when launching Claude Code. Session-scoped only, not saved to disk. Example:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  },
  "debugger": {
    "description": "Debugging specialist for errors and test failures.",
    "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
  }
}'
```

The `--agents` flag accepts JSON with the same frontmatter fields as file-based subagents.

Managed subagents: deployed by org admins. Placed in `.claude/agents/` inside the managed settings directory.

Plugin subagents: from plugins. Appear in `/agents`. For security, plugin subagents do NOT support `hooks`, `mcpServers`, or `permissionMode` fields — these are ignored. Copy the agent file to `.claude/agents/` or `~/.claude/agents/` if you need them.

Subagent definitions from any scope are also available to agent teams when spawning a teammate.

### Write subagent files

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

Frontmatter defines metadata and config. The body becomes the system prompt. Subagents receive only this system prompt (plus basic environment details like working directory), NOT the full Claude Code system prompt.

Note: Subagents are loaded at session start. If you create a subagent by manually adding a file, restart your session or use `/agents` to load it immediately.

A subagent starts in the main conversation's current working directory. Within a subagent, `cd` commands don't persist between Bash/PowerShell calls and don't affect the main conversation's working directory. To give the subagent an isolated copy of the repository, set `isolation: worktree`.

#### Supported frontmatter fields

Only `name` and `description` are required.

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all tools if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, a full model ID (e.g., `claude-opus-4-7`), or `inherit`. Defaults to `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan` |
| `maxTurns` | No | Maximum number of agentic turns before the subagent stops |
| `skills` | No | Skills to load into the subagent's context at startup. Full skill content is injected, not just made available for invocation. Subagents don't inherit skills from parent |
| `mcpServers` | No | MCP servers available to this subagent. Either a server name referencing an already-configured server, or an inline definition |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | Set to `true` to always run this subagent as a background task. Default: `false` |
| `effort` | No | Effort level when this subagent is active. Overrides session effort. Options: `low`, `medium`, `high`, `xhigh`, `max` |
| `isolation` | No | Set to `worktree` to run in a temporary git worktree (isolated copy of repo, auto-cleanup if no changes) |
| `color` | No | Display color: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan` |
| `initialPrompt` | No | Auto-submitted as first user turn when agent runs as main session (via `--agent` or `agent` setting). Prepended to user-provided prompt |

### Choose a model

The `model` field options:
- Model alias: `sonnet`, `opus`, `haiku`
- Full model ID: `claude-opus-4-7`, `claude-sonnet-4-6`, etc.
- `inherit`: same model as main conversation
- Omitted: defaults to `inherit`

Model resolution order when Claude invokes:
1. `CLAUDE_CODE_SUBAGENT_MODEL` environment variable
2. Per-invocation `model` parameter
3. Subagent definition's `model` frontmatter
4. Main conversation's model

### Control subagent capabilities

#### Available tools

Subagents can use any of Claude Code's internal tools. By default, inherit all tools from the main conversation including MCP tools.

To restrict, use `tools` (allowlist) or `disallowedTools` (denylist). Example allowlist (only Read, Grep, Glob, Bash — no file edits, no MCP):

```yaml
---
name: safe-researcher
description: Research agent with restricted capabilities
tools: Read, Grep, Glob, Bash
---
```

Example denylist (inherit everything except Write and Edit):

```yaml
---
name: no-writes
description: Inherits every tool except file writes
disallowedTools: Write, Edit
---
```

If both are set, `disallowedTools` is applied first, then `tools` is resolved against the remaining pool. A tool listed in both is removed.

#### Restrict which subagents can be spawned

When an agent runs as the main thread with `claude --agent`, it can spawn subagents using the Agent tool. To restrict subagent types, use `Agent(agent_type)` syntax in `tools`. Version 2.1.63 renamed Task tool to Agent; existing `Task(...)` references still work as aliases.

```yaml
---
name: coordinator
description: Coordinates work across specialized agents
tools: Agent(worker, researcher), Read, Bash
---
```

To allow spawning any subagent: `tools: Agent, Read, Bash`. If `Agent` is omitted entirely, the agent cannot spawn any subagents. This applies only to main-thread agents — subagents cannot spawn other subagents.

#### Scope MCP servers to a subagent

Use `mcpServers` to give access to MCP servers not available in the main conversation. Inline servers are connected when subagent starts, disconnected when it finishes. String references share the parent session's connection.

```yaml
---
name: browser-tester
description: Tests features in a real browser using Playwright
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  - github
---

Use the Playwright tools to navigate, screenshot, and interact with pages.
```

To keep an MCP server out of the main conversation entirely, define it inline in a subagent rather than in `.mcp.json`.

#### Permission modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits and common filesystem commands |
| `auto` | Background classifier reviews commands and protected-directory writes |
| `dontAsk` | Auto-deny permission prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip permission prompts |
| `plan` | Plan mode (read-only exploration) |

Warning: `bypassPermissions` skips permission prompts. Writes to `.git`, `.claude`, `.vscode`, `.idea`, and `.husky` directories still prompt for confirmation, except for `.claude/commands`, `.claude/agents`, and `.claude/skills`.

If the parent uses `bypassPermissions` or `acceptEdits`, it takes precedence and cannot be overridden. If the parent uses auto mode, the subagent inherits auto mode and any `permissionMode` in its frontmatter is ignored.

#### Preload skills into subagents

Use `skills` to inject skill content at startup. Full content is injected, not just made available. Subagents don't inherit skills from parent; list them explicitly.

```yaml
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---

Implement API endpoints. Follow the conventions and patterns from the preloaded skills.
```

This is the inverse of running a skill in a subagent via `context: fork`.

#### Enable persistent memory

`memory` field gives a persistent directory surviving across conversations.

```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices
memory: user
---
```

| Scope | Location | Use when |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings span all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not checked in |

When memory is enabled:
- Subagent's system prompt includes instructions for reading/writing to memory
- System prompt includes first 200 lines or 25KB of `MEMORY.md` (whichever comes first), with curation instructions if it exceeds
- Read, Write, Edit tools auto-enabled for memory file management

Tips:
- `project` is recommended default — knowledge shareable via VCS
- Ask subagent to consult memory before work and update after: "Review this PR, and check your memory for patterns you've seen before." / "Now that you're done, save what you learned to your memory."
- Include memory instructions in the subagent's markdown file so it proactively maintains its own knowledge base

#### Conditional rules with hooks

Use `PreToolUse` hooks for dynamic validation. Example — read-only database subagent:

```yaml
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

Claude Code passes hook input as JSON via stdin. Script extracts the Bash command and exits with code 2 to block write operations.

#### Disable specific subagents

Add to `permissions.deny` using `Agent(subagent-name)`:

```json
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

Works for built-in and custom. Also supports `--disallowedTools "Agent(Explore)"` flag.

### Define hooks for subagents

Two ways to configure hooks:
1. In the subagent's frontmatter — run only while that specific subagent is active
2. In `settings.json` — run in the main session when subagents start or stop

#### Hooks in subagent frontmatter

Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention. They do NOT fire when the agent runs as the main session via `--agent` or the `agent` setting. For session-wide hooks, configure in `settings.json`.

Common events for subagents:

| Event | Matcher input | When it fires |
|-------|---------------|----------------|
| `PreToolUse` | Tool name | Before the subagent uses a tool |
| `PostToolUse` | Tool name | After the subagent uses a tool |
| `Stop` | (none) | When the subagent finishes (converted to `SubagentStop` at runtime) |

Example — validate Bash + run linter after edits:

```yaml
---
name: code-reviewer
description: Review code changes with automatic linting
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh $TOOL_INPUT"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

`Stop` hooks in frontmatter are automatically converted to `SubagentStop` events.

#### Project-level hooks for subagent events

Configure hooks in `settings.json` responding to subagent lifecycle events in main session:

| Event | Matcher input | When it fires |
|-------|---------------|----------------|
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop` | Agent type name | When a subagent completes |

Both support matchers to target specific agent types. Example:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "db-agent",
        "hooks": [
          { "type": "command", "command": "./scripts/setup-db-connection.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "./scripts/cleanup-db-connection.sh" }
        ]
      }
    ]
  }
}
```

## Work with subagents

### Understand automatic delegation

Claude automatically delegates based on task description in your request, `description` field in subagent configurations, and current context. To encourage proactive delegation, include phrases like "use proactively" in the description.

### Invoke subagents explicitly

Three patterns, escalating from one-off to session-wide:

- **Natural language**: name the subagent in your prompt; Claude decides whether to delegate
- **@-mention**: guarantees the subagent runs for one task
- **Session-wide**: whole session uses the subagent's system prompt, tool restrictions, and model via `--agent` flag or `agent` setting

Natural language examples:
```
Use the test-runner subagent to fix failing tests
Have the code-reviewer subagent look at my recent changes
```

@-mention: type `@` and pick from typeahead. Format: `@agent-<name>` for local, `@agent-<plugin-name>:<agent-name>` for plugin. Plugin subagents appear as `<plugin-name>:<agent-name>` in typeahead. Named background subagents currently running appear with status indicator.

Session-wide with `--agent`:
```bash
claude --agent code-reviewer
```

Subagent's system prompt replaces default Claude Code system prompt entirely (like `--system-prompt`). CLAUDE.md and project memory still load. Agent name appears as `@<name>` in startup header. Choice persists on session resume.

Plugin subagent: `claude --agent <plugin-name>:<agent-name>`.

Default for every session in a project via `.claude/settings.json`:
```json
{
  "agent": "code-reviewer"
}
```

CLI flag overrides setting if both present.

### Run subagents in foreground or background

**Foreground subagents** block the main conversation. Permission prompts and clarifying questions (like `AskUserQuestion`) pass through to the user.

**Background subagents** run concurrently while user continues working. Before launching, Claude Code prompts for any tool permissions the subagent will need, ensuring approvals upfront. Once running, subagent inherits these permissions and auto-denies anything not pre-approved. If a background subagent needs clarifying questions, that tool call fails but subagent continues.

If a background subagent fails due to missing permissions, start a new foreground subagent with the same task to retry interactively.

Claude decides foreground vs background based on the task. User can also:
- Ask Claude to "run this in the background"
- Press **Ctrl+B** to background a running task

Disable all background task functionality with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.

### Common patterns

**Isolate high-volume operations.** Running tests, fetching documentation, or processing log files can consume significant context. Delegate to a subagent so verbose output stays in subagent's context while only summary returns.

```
Use a subagent to run the test suite and report only the failing tests with their error messages
```

**Run parallel research.** Multiple subagents work simultaneously:

```
Research the authentication, database, and API modules in parallel using separate subagents
```

Each subagent explores its area independently, then Claude synthesizes. Works best when research paths don't depend on each other.

Warning: Running many subagents that each return detailed results can consume significant context. For sustained parallelism or context-exceeding tasks, use agent teams.

**Chain subagents.** Multi-step workflows — subagents in sequence:

```
Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them
```

### Choose between subagents and main conversation

Use **main conversation** when:
- Task needs frequent back-and-forth or iterative refinement
- Multiple phases share significant context (planning → implementation → testing)
- Quick, targeted change
- Latency matters (subagents start fresh and may need time to gather context)

Use **subagents** when:
- Task produces verbose output you don't need in main context
- Enforce specific tool restrictions or permissions
- Work is self-contained and can return a summary

Consider Skills instead when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context.

For quick question about something already in your conversation, use `/btw` instead of a subagent. It sees your full context but has no tool access, and the answer is discarded.

Note: Subagents cannot spawn other subagents. For nested delegation, use Skills or chain subagents from the main conversation.

### Manage subagent context

#### Resume subagents

Each subagent invocation creates a new instance with fresh context. To continue an existing subagent's work, ask Claude to resume it. Resumed subagents retain full conversation history.

When a subagent completes, Claude receives its agent ID. Claude uses `SendMessage` tool with the agent's ID as `to` field to resume it. `SendMessage` is only available when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

If a stopped subagent receives a `SendMessage`, it auto-resumes in the background without requiring new `Agent` invocation.

Transcripts at `~/.claude/projects/{project}/{sessionId}/subagents/` as `agent-{agentId}.jsonl`.

Subagent transcripts persist independently of main conversation:
- Main conversation compaction doesn't affect subagent transcripts (separate files)
- Session persistence: subagent transcripts persist within their session; resume after Claude Code restart by resuming same session
- Automatic cleanup based on `cleanupPeriodDays` setting (default: 30 days)

#### Auto-compaction

Subagents support automatic compaction using the same logic as the main conversation. Default: triggers at ~95% capacity. Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` to a lower percentage (e.g., `50`) for earlier compaction.

Compaction events logged in subagent transcripts with `"type": "system", "subtype": "compact_boundary"`.

## Example subagents

### Code reviewer

Read-only subagent that reviews code without modifying it. Limited tool access (no Edit/Write).

```markdown
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is clear and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### Debugger

Analyzes and fixes issues. Includes Edit for modifications.

```markdown
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not the symptoms.
```

### Data scientist

Domain-specific, uses `model: sonnet` for more capable analysis.

```markdown
---
name: data-scientist
description: Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:
1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze and summarize results
5. Present findings clearly

Key practices:
- Write optimized SQL queries with proper filters
- Use appropriate aggregations and joins
- Include comments explaining complex logic
- Format results for readability
- Provide data-driven recommendations
```

### Database query validator

Allows Bash access but validates commands with `PreToolUse` hook to permit only read-only SQL.

```markdown
---
name: db-reader
description: Execute read-only database queries. Use when analyzing data or generating reports.
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---

You are a database analyst with read-only access. Execute SELECT queries to answer questions about the data.
```

Validation script (`./scripts/validate-readonly-query.sh`):
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [ -z "$COMMAND" ]; then exit 0; fi
if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|REPLACE|MERGE)\b' > /dev/null; then
  echo "Blocked: Write operations not allowed. Use SELECT queries only." >&2
  exit 2
fi
exit 0
```

Make executable: `chmod +x ./scripts/validate-readonly-query.sh`. Exit code 2 blocks operation and feeds error message back to Claude via stderr.

## Best practices

- **Design focused subagents** — each subagent should excel at one specific task
- **Write detailed descriptions** — Claude uses description to decide when to delegate
- **Limit tool access** — grant only necessary permissions for security and focus
- **Check into version control** — share project subagents with your team

## Next steps

- Distribute subagents with plugins
- Run Claude Code programmatically with the Agent SDK for CI/CD and automation
- Use MCP servers to give subagents access to external tools and data

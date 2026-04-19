# Custom Subagents

> Sources: Anthropic, 2026-04-16; Anthropic, 2026-04-17
> Raw: [create-custom-subagents](../../raw/claude-code/create-custom-subagents.md)
> Updated: 2026-04-17

## Overview

A subagent is a specialized assistant with its own context window, system prompt, tool restrictions, and permissions. Claude spawns it to handle a bounded task — running a test suite, reviewing a file, ingesting a source — then the subagent returns a summary and exits. The verbose intermediate work (search results, logs, file contents) stays in the subagent's context and never pollutes the main conversation.

Subagents are defined as markdown files with YAML frontmatter, stored at one of five scope levels that arbitrate by priority on name collisions. Only `name` and `description` are required; everything else — tools, model, skills, memory, hooks, background mode, permission mode — is optional configuration. The body of the file becomes the subagent's system prompt, replacing the default Claude Code system prompt entirely.

A critical constraint: **subagents do not inherit skills, conversation history, or invoked MCP tools from the parent session**. What they need must be declared explicitly in frontmatter or passed in the spawning prompt. They also cannot spawn other subagents (use Skills or chained delegation from the main conversation for nested work).

## Storage scopes and priority

Same subagent name can exist at multiple scopes; highest priority wins.

| Location | Scope | Priority |
|----------|-------|----------|
| Managed settings (`<managed-settings-dir>/.claude/agents/`) | Organization-wide | 1 (highest) |
| `--agents` CLI flag (JSON inline, session only) | Current session | 2 |
| `.claude/agents/<name>.md` | Current project | 3 |
| `~/.claude/agents/<name>.md` | All projects | 4 |
| Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest) |

Project subagents are discovered by walking up from the CWD. `--add-dir` paths get file access but are *not* scanned for subagent definitions. Plugin subagents have a security restriction: they can't use `hooks`, `mcpServers`, or `permissionMode` — those fields are silently ignored when loading from a plugin. Copy the file to `.claude/agents/` if you need them.

## Frontmatter fields

Required: `name` (lowercase-hyphen identifier), `description` (tells Claude when to delegate). Everything else is optional.

The fields that matter most for the wiki-ingester use case we're about to build:

- **`skills`** — list of skill names whose full content gets injected at startup. This is how a subagent gets capability — it does *not* inherit from the parent, so any skill the subagent needs must appear here explicitly.
- **`tools`** — allowlist. Omit to inherit everything including MCP tools. Use `disallowedTools` for denylist instead, applied before the allowlist.
- **`model`** — `sonnet`, `opus`, `haiku`, a full ID like `claude-opus-4-7`, or `inherit` (default). Use `haiku` to control costs for high-volume work.
- **`background`** — set to `true` to always launch as a background task. Default `false`.
- **`isolation`** — set to `worktree` to run in a temporary git worktree (isolated repo copy, auto-cleaned if no changes).
- **`hooks`** — subagent-scoped lifecycle hooks, see below.
- **`memory`** — `user` / `project` / `local` — enables a persistent directory at `~/.claude/agent-memory/<name>/`, `.claude/agent-memory/<name>/`, or `.claude/agent-memory-local/<name>/`. System prompt gets read/write memory instructions auto-added; Read/Write/Edit tools force-enabled.
- **`permissionMode`** — `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. Parent's mode can override: if parent uses `bypassPermissions` or `acceptEdits`, that wins and the subagent's mode is ignored.
- **`maxTurns`** — upper bound on agentic turns before the subagent stops.
- **`effort`** — `low` / `medium` / `high` / `xhigh` / `max`. Overrides session effort level. Available levels depend on the model.
- **`initialPrompt`** — only relevant when the agent runs as the main session via `--agent`; auto-submitted as first user turn.
- **`color`** — UI only.
- **`mcpServers`** — list of MCP server names or inline definitions. Inline servers connect only for this subagent, keeping their tool descriptions out of the main conversation's context.

## Foreground vs background

Foreground subagents block the main conversation and pass permission prompts and `AskUserQuestion` calls through to the user.

Background subagents run concurrently. **Before launching, Claude Code prompts for any tool permissions the subagent will need**, ensuring all approvals are gathered upfront. Once running, the subagent inherits those permissions and auto-denies anything not pre-approved. If a background subagent needs a clarifying question, the tool call fails and the subagent continues without an answer — if it gets stuck, spawn a fresh foreground subagent with the same task.

Claude chooses foreground vs. background based on the task. User controls: say "run in the background," or press **Ctrl+B** to background a running task. `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` disables background entirely.

## Hooks: two scopes

Subagent hooks come in two flavors.

**Frontmatter hooks** run only while that specific subagent is active. Fire when the subagent is spawned via the Agent tool or an @-mention — *not* when the agent runs as the main session via `--agent`. Common events:

| Event | Matcher | Fires |
|-------|---------|-------|
| `PreToolUse` | Tool name | Before subagent uses a tool |
| `PostToolUse` | Tool name | After subagent uses a tool |
| `Stop` | — | When subagent finishes (auto-converted to `SubagentStop`) |

**Project-level hooks in `settings.json`** run in the main session, responding to subagent lifecycle. `SubagentStart` and `SubagentStop` events both support matchers by agent name. Hook command receives JSON on stdin; exit code 2 blocks the operation and feeds stderr back to Claude.

## Invocation patterns

Three ways to invoke, escalating from one-off to session-wide:

- **Natural language** — mention the subagent name in your prompt, Claude decides whether to delegate.
- **@-mention** — guarantees that specific subagent runs. Types `@`, pick from typeahead. Format: `@agent-<name>` for local, `@agent-<plugin-name>:<agent-name>` for plugin.
- **Session-wide** — `claude --agent <name>` or `agent: <name>` in `.claude/settings.json` replaces the default Claude Code system prompt with the subagent's for the entire session. CLAUDE.md and project memory still load. CLI flag overrides the setting.

`/agents` opens an interactive UI (Running tab for live subagents, Library tab for creating/editing). `claude agents` from the shell lists everything grouped by source.

## Picking the right mechanism

Use a subagent when the work is self-contained, produces verbose output, or needs enforced tool restrictions. Use the main conversation when iteration, back-and-forth, or shared context across phases matters. Use Skills (not subagents) when you want a reusable workflow that runs *in* the main conversation. Use `/btw` for a side question that needs full conversation context but no tool access.

Subagent vs. Agent Teams: a subagent reports back to the parent. Agent Teams members message each other directly. If parallel subagents are hitting context limits or need to talk to each other, that's the transition signal to a team.

## Resume and transcripts

Each invocation creates a fresh instance. To continue prior work, ask Claude to resume — subagent ID is passed back to Claude on completion. Resume uses the `SendMessage` tool, only available when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (which this repo has set).

Transcripts live at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`, independent of the main conversation's transcript. Main-conversation compaction doesn't affect subagent transcripts. Cleanup happens on the `cleanupPeriodDays` schedule (default 30 days).

Subagents auto-compact at ~95% capacity by default. Override with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=<percent>`.

## Built-in subagents

Claude Code ships four built-ins: **Explore** (fast read-only, Haiku), **Plan** (research in plan mode, read-only, inherits model), **General-purpose** (all tools, for complex multi-step work), and specialized helpers (`statusline-setup`, `Claude Code Guide`) that trigger automatically.

## See Also

- [Hooks Reference](hooks.md) — complete event vocabulary for subagent-lifecycle hooks (`SubagentStart`, `SubagentStop`, frontmatter `PreToolUse` / `PostToolUse` / `Stop`), plus async and asyncRewake modes for background subagents
- [Extending Claude Code](extensions.md) — where subagents sit alongside CLAUDE.md, Skills, MCP, Hooks, Agent Teams, and Plugins in the extension surface
- [MCP in Claude Code](mcp.md) — `mcpServers` frontmatter field for inline subagent-scoped MCP connections (keeps tool descriptions out of main conversation context)
- [Claude Code Overview](overview.md) — product-level context
- [Claude Prompting Best Practices](claude-prompting-best-practices.md) — prompting guidance for controlling subagent spawning behavior (Opus 4.7 spawns fewer by default; Opus 4.6 over-spawns) and orchestration patterns

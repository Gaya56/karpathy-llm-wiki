# claude-code

Anthropic's agentic coding tool — CLI, IDE extensions, desktop app, web, and CI/chat integrations.

| Article | Summary | Updated |
|---------|---------|---------|
| [Claude Code Overview](overview.md) | Product overview, surfaces, capability categories, customization (CLAUDE.md, skills, hooks), agent teams, and MCP | 2026-04-17 |
| [Extending Claude Code](extensions.md) | Seven extension mechanisms (CLAUDE.md, Skills, MCP, Subagents, Agent Teams, Hooks, Plugins), when to use each, how they layer, and context-cost trade-offs | 2026-04-17 |
| [MCP in Claude Code](mcp.md) | Full MCP reference: transports (HTTP/SSE/stdio), scopes, OAuth, Tool Search, output limits, resources, prompts, elicitation, and managed organization configuration | 2026-04-17 |
| [Custom Subagents](subagents.md) | Full subagent configuration reference — frontmatter fields, storage scopes and priority, foreground vs. background, lifecycle hooks, built-ins | 2026-04-17 |
| [Claude Prompting Best Practices](claude-prompting-best-practices.md) | Model-specific behavioral tuning (Opus 4.7, Opus 4.6, Sonnet 4.6), general prompting principles, output control, tool use, thinking/reasoning, and agentic system patterns | 2026-04-17 |
| [Hooks Reference](hooks.md) | Full hook event vocabulary (26 events), configuration schema, matcher rules, command/HTTP/prompt/agent handler types, exit-code and JSON output control, async and asyncRewake | 2026-04-16 |
| [Memory and Persistent Instructions](memory.md) | CLAUDE.md files (scopes, load order, imports, path-specific rules, large-team management) and auto memory (storage, loading limits, subagent memory, /memory command, troubleshooting) | 2026-04-16 |
| [Settings and Configuration](settings.md) | settings.json schema, four configuration scopes (Managed/Local/Project/User), permissions and rule syntax, env vars, sandbox settings, plugin and hook controls, model overrides, attribution | 2026-04-16 |
| [Headless Mode](headless-mode.md) | `claude -p` non-interactive runs — `--bare`, output formats, `--json-schema`, streaming events, `--allowedTools` vs permission modes, session chaining via `--resume` | 2026-04-19 |
| [Scheduled Tasks and /loop](scheduled-tasks.md) | `/loop` command (fixed, dynamic, and maintenance modes), `loop.md` customization, one-time reminders, `CronCreate`/`CronList`/`CronDelete` tools, cron reference, jitter, seven-day expiry, `CLAUDE_CODE_DISABLE_CRON`, limitations, and scheduling-options comparison table | 2026-04-19 |
| [Agent SDK](agent-sdk.md) | Python + TypeScript SDK (`query()` / `ClaudeAgentOptions`), built-in tools, hooks, subagents with `parent_tool_use_id`, MCP, sessions, filesystem config loading, Agent SDK vs Client SDK vs CLI | 2026-04-19 |
| [Cloud Routines](cloud-routines.md) | Prompt + repos + connectors packaged as cloud-hosted automation; three trigger types (schedule, API, GitHub event), branch-push permissions, connectors, environments, daily cap, and research-preview API details | 2026-04-19 |
| [CLI Reference](cli-reference.md) | Complete reference for all CLI commands and flags — permission, session, output, system-prompt, context, limit/budget, worktree/tmux, and multi-surface flags | 2026-04-19 |
| [Claude Code Desktop](desktop.md) | macOS/Windows desktop app — parallel sessions with Git worktree isolation, drag-and-drop pane layout, visual diff review, live app preview, PR monitoring, computer use, Dispatch integration, Remote Control, `--teleport`, connectors, scheduled tasks, enterprise configuration | 2026-04-19 |
| [Running Claude Code Autonomously](running-autonomously.md) | End-to-end playbook — two-session controller/executor pattern, 6-section prompt template, chained runner script, the silent `Write(<path>/**)` failure mode and fix, monitoring pitfalls, lessons, and a pre-run checklist | 2026-04-19 |

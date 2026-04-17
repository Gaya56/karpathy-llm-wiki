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

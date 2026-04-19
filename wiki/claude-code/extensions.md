# Extending Claude Code

> Sources: Anthropic, 2026-04-16
> Raw: [extend-claude-code](../../raw/claude-code/extend-claude-code.md)
> Updated: 2026-04-17

## Overview

Claude Code ships with built-in tools for file operations, search, command execution, and web access that handle most coding tasks. On top of those, it exposes seven extension mechanisms — CLAUDE.md, Skills, MCP, Subagents, Agent Teams, Hooks, and Plugins — that plug into different parts of the agentic loop. Each one has a distinct loading model, a distinct context cost, and a distinct trigger pattern that tells you when to reach for it.

The pattern this article captures: features aren't ranked by power but by where in the session lifecycle they engage. CLAUDE.md shapes *every* turn. Skills shape *some* turns. Subagents run *parallel* turns with their own context. Hooks run *outside* turns entirely, as deterministic scripts. Getting this mental model right makes the "which feature should I use" question fall out naturally.

## The seven mechanisms

**CLAUDE.md** is project-level persistent context. Loads automatically at session start, stays in every request. Encodes coding conventions, build commands, architecture, "never do X" rules. Keep under ~200 lines — beyond that it costs more context than it pays back and Claude starts losing signal among the noise. Also supplemented by auto memory (persistent learnings saved between sessions) and optional `.claude/rules/` files that scope down to specific file paths.

**Skills** are markdown files containing knowledge, workflows, or instructions. Two sub-flavors: *reference skills* (an API style guide Claude reads when relevant) and *action skills* (a `/deploy` command that runs a workflow). By default, skill descriptions load at session start so Claude can decide when to invoke them; full content loads on use. Setting `disable-model-invocation: true` in a skill's frontmatter hides it from Claude entirely until a user triggers it — useful for skills with side effects, and drops context cost to zero.

**MCP (Model Context Protocol)** connects Claude to external services. Tool *names* load at session start; full JSON schemas defer until a tool is actually needed, so idle MCP tools cost little context. MCP gives capability; skills give competence — an MCP server connects Claude to your database, a skill teaches Claude your schema and query patterns. MCP connections can fail silently mid-session, so check `/mcp` if a previously-working tool stops responding.

**Subagents** are isolated workers with their own context window. They run within the current session but do their work separately and return a summary. Best for tasks that read many files, need parallel execution, or shouldn't bloat the main conversation's context. Subagents are opinionated: they receive the system prompt (shared with parent for cache efficiency), inherit CLAUDE.md and git status, get fully-preloaded content from any skills listed in their `skills:` field, and see whatever context the spawning agent passes in. They do *not* inherit conversation history or invoked skills from the main session — what they need must be declared explicitly.

**Agent Teams** are architecturally one step up from subagents: multiple independent Claude Code sessions that communicate with each other directly rather than reporting back to a lead. Each teammate has its own context window and can be fully independent. Use when teammates need to share findings, challenge each other, or coordinate on separate pieces of a larger task. The transition signal is clear: if parallel subagents are hitting context limits or need to talk to each other, promote to a team. Currently experimental and disabled by default.

**Hooks** run outside the agent loop entirely. They fire on lifecycle events — tool execution, session boundaries, prompt submission, permission requests, compaction — and execute as deterministic scripts with no LLM involvement. Zero context cost unless the hook explicitly returns output to the conversation. Ideal for side effects: linting after every edit, logging, notifications, running test suites. Hooks *merge* across sources rather than overriding, so every registered hook for an event fires regardless of which level (user, project, plugin) defined it.

**Plugins** are the packaging layer. A plugin bundles skills, hooks, subagents, and MCP servers into one installable unit; plugin skills are namespaced (`/my-plugin:review`) so multiple plugins can coexist. Plugins are how the same extension setup gets shared across repositories, teams, or public marketplaces.

## Picking the right mechanism: triggers over features

The source documents a recognition pattern that works well: don't reach for a feature until something pushes you toward it.

| If this happens | Reach for |
| --- | --- |
| Claude gets a convention or command wrong twice | CLAUDE.md |
| You keep typing the same prompt to start a task | A user-invocable skill |
| You paste the same playbook or multi-step procedure into chat for the third time | Capture it as a skill |
| You keep copying data from a browser tab Claude can't see | An MCP server |
| A side task floods your conversation with output you won't reference again | A subagent |
| You want something to happen every time without asking | A hook |
| A second repository needs the same setup | A plugin |

Same logic governs maintenance: a repeated mistake isn't a one-off correction, it's a CLAUDE.md edit. A workflow you keep hand-tweaking isn't a conversation — it's a skill that needs another revision.

## Comparisons that matter

**Skill vs. Subagent.** Skills are reusable content loaded into a context. Subagents are isolated workers. They combine: a subagent can preload specific skills via its `skills:` field, and a skill can declare `context: fork` to run itself in isolated context. Reach for a skill when you want reusable knowledge or an invocable workflow. Reach for a subagent when the work is large or noisy enough that you don't want it in your main conversation.

**CLAUDE.md vs. Skill.** CLAUDE.md loads every session; skills load on demand. CLAUDE.md can't trigger workflows via `/<name>`; skills can. The heuristic: if Claude should *always* know it, CLAUDE.md. If Claude only needs it *sometimes* or when you explicitly ask, a skill. If CLAUDE.md is growing past 200 lines, start moving reference material into skills or scope-specific `.claude/rules/` files.

**Subagent vs. Agent Team.** Subagents report back to a lead. Agent team members message each other directly. Subagents are lower-token (one Claude instance handles coordination); teams are higher-token (each teammate is a separate Claude). Subagents suit focused tasks where only the result matters. Teams suit work that benefits from dialogue — competing hypotheses, peer review, parallel feature development where each teammate owns a piece.

**MCP vs. Skill.** MCP is capability (can Claude reach this system at all?); a skill is competence (does Claude know how to use it well?). Both are often needed together.

## How features layer across scopes

Extensions can be defined at user, project, plugin, or managed-policy levels. Collision behavior differs by type:

- **CLAUDE.md files** are *additive* — every level contributes content. Nested CLAUDE.md files in subdirectories load as you work in them. On conflicts, Claude uses judgment with more-specific taking precedence.
- **Skills and subagents** *override by name* with a precedence chain: for skills, managed > user > project; for subagents, managed > CLI flag > project > user > plugin. Plugin skills are namespaced to dodge collisions.
- **MCP servers** *override by name*: local > project > user.
- **Hooks** *merge* — every registered hook for an event fires, regardless of source.

The additive-vs-override distinction is easy to miss and causes surprises: adding a user-level CLAUDE.md supplements the project one; adding a user-level skill with the same name as a project skill silently overrides it.

## Combining mechanisms

Typical real-world setups stack these together. The source highlights four patterns:

- **Skill + MCP.** MCP gives the connection; a skill documents how to use it. (E.g., MCP connects to the database; a skill teaches your schema and query patterns.)
- **Skill + Subagent.** A skill spawns subagents for parallel work. (E.g., `/audit` launches security, performance, and style subagents in isolated contexts.)
- **CLAUDE.md + Skills.** CLAUDE.md says "follow our API conventions"; a skill contains the full style guide. Always-on summary, on-demand detail.
- **Hook + MCP.** A hook triggers an external action through MCP. (E.g., post-edit hook sends a Slack notification when Claude modifies critical files.)

## Context cost and load timing

| Feature | When it loads | What loads | Cost |
| --- | --- | --- | --- |
| CLAUDE.md | Session start | Full content (all levels) | Paid every request |
| Skills | Start + on use | Descriptions at start, full content when invoked | Low (descriptions only) |
| MCP servers | Session start | Tool names; schemas on demand | Low until a tool is called |
| Subagents | When spawned | Fresh context + declared skills | Isolated from main |
| Hooks | On trigger | Nothing (external scripts) | Zero by default |

Two notes worth internalizing:

1. *Skill descriptions cost context every request.* If you install dozens of skills, the descriptions alone become a non-trivial tax. `disable-model-invocation: true` eliminates this for skills only you trigger.
2. *Subagents don't inherit the main session's skills or history.* Whatever a subagent needs must be explicitly declared in its `skills:` field or passed in the spawn prompt. This isolation is a feature — it prevents main-session bloat — but it means the skill you think a subagent has access to probably doesn't.

## See Also

- [Claude Code Overview](overview.md) — the surfaces and product-level capabilities behind these extension mechanisms
- [MCP in Claude Code](mcp.md) — full MCP reference: transports, scopes, OAuth, Tool Search, output limits, resources, prompts, elicitation, and managed configuration
- [Custom Subagents](subagents.md) — full configuration reference for building subagents (frontmatter fields, storage scopes, foreground vs. background, lifecycle hooks)
- [Hooks Reference](hooks.md) — full event vocabulary (26 events), configuration schema, matcher rules, exit-code and JSON output, async and asyncRewake modes
- [Claude Prompting Best Practices](claude-prompting-best-practices.md) — model-specific behavioral tuning, output control, tool use, thinking/reasoning, and agentic patterns that apply across the extension surface

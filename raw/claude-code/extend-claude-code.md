# Extend Claude Code

> Source: https://code.claude.com/docs/en/features-overview
> Collected: 2026-04-16
> Published: Unknown

Understand when to use CLAUDE.md, Skills, subagents, hooks, MCP, and plugins.

Claude Code combines a model that reasons about your code with built-in tools for file operations, search, execution, and web access. The built-in tools cover most coding tasks. This guide covers the extension layer: features you add to customize what Claude knows, connect it to external services, and automate workflows.

New to Claude Code? Start with CLAUDE.md for project conventions, then add other extensions as specific triggers come up.

## Overview

Extensions plug into different parts of the agentic loop:

- **CLAUDE.md** adds persistent context Claude sees every session
- **Skills** add reusable knowledge and invocable workflows
- **MCP** connects Claude to external services and tools
- **Subagents** run their own loops in isolated context, returning summaries
- **Agent teams** coordinate multiple independent sessions with shared tasks and peer-to-peer messaging
- **Hooks** run outside the loop entirely as deterministic scripts
- **Plugins** and **marketplaces** package and distribute these features

Skills are the most flexible extension. A skill is a markdown file containing knowledge, workflows, or instructions. You can invoke skills with a command like `/deploy`, or Claude can load them automatically when relevant. Skills can run in your current conversation or in an isolated context via subagents.

## Match features to your goal

| Feature | What it does | When to use it | Example |
|---------|--------------|----------------|---------|
| CLAUDE.md | Persistent context loaded every conversation | Project conventions, "always do X" rules | "Use pnpm, not npm. Run tests before committing." |
| Skill | Instructions, knowledge, and workflows Claude can use | Reusable content, reference docs, repeatable tasks | `/deploy` runs your deployment checklist; API docs skill with endpoint patterns |
| Subagent | Isolated execution context that returns summarized results | Context isolation, parallel tasks, specialized workers | Research task that reads many files but returns only key findings |
| Agent teams | Coordinate multiple independent Claude Code sessions | Parallel research, new feature development, debugging with competing hypotheses | Spawn reviewers to check security, performance, and tests simultaneously |
| MCP | Connect to external services | External data or actions | Query your database, post to Slack, control a browser |
| Hook | Deterministic script that runs on events | Predictable automation, no LLM involved | Run ESLint after every file edit |

Plugins are the packaging layer. A plugin bundles skills, hooks, subagents, and MCP servers into a single installable unit. Plugin skills are namespaced (like `/my-plugin:review`) so multiple plugins can coexist. Use plugins when you want to reuse the same setup across multiple repositories or distribute to others via a marketplace.

### Build your setup over time

Each feature has a recognizable trigger, and most teams add them in roughly this order:

| Trigger | Add |
|---------|-----|
| Claude gets a convention or command wrong twice | Add it to CLAUDE.md |
| You keep typing the same prompt to start a task | Save it as a user-invocable skill |
| You paste the same playbook or multi-step procedure into chat for the third time | Capture it as a skill |
| You keep copying data from a browser tab Claude can't see | Connect that system as an MCP server |
| A side task floods your conversation with output you won't reference again | Route it through a subagent |
| You want something to happen every time without asking | Write a hook |
| A second repository needs the same setup | Package it as a plugin |

The same triggers tell you when to update what you already have. A repeated mistake or a recurring review comment is a CLAUDE.md edit, not a one-off correction in chat. A workflow you keep tweaking by hand is a skill that needs another revision.

### Compare similar features

**Skill vs Subagent.** Skills are reusable content you can load into any context. Subagents are isolated workers that run separately from your main conversation.

| Aspect | Skill | Subagent |
|--------|-------|----------|
| What it is | Reusable instructions, knowledge, or workflows | Isolated worker with its own context |
| Key benefit | Share content across contexts | Context isolation. Work happens separately, only summary returns |
| Best for | Reference material, invocable workflows | Tasks that read many files, parallel work, specialized workers |

Skills can be reference or action. Reference skills provide knowledge Claude uses throughout your session (like your API style guide). Action skills tell Claude to do something specific (like `/deploy` that runs your deployment workflow).

Use a subagent when you need context isolation or when your context window is getting full. Custom subagents can have their own instructions and can preload skills.

They can combine. A subagent can preload specific skills (`skills:` field). A skill can run in isolated context using `context: fork`.

**CLAUDE.md vs Skill.** Both store instructions.

| Aspect | CLAUDE.md | Skill |
|--------|-----------|-------|
| Loads | Every session, automatically | On demand |
| Can include files | Yes, with `@path` imports | Yes, with `@path` imports |
| Can trigger workflows | No | Yes, with `/<name>` |
| Best for | "Always do X" rules | Reference material, invocable workflows |

Put it in CLAUDE.md if Claude should always know it. Put it in a skill if it's reference material Claude needs sometimes, or a workflow you trigger with `/<name>`. Rule of thumb: Keep CLAUDE.md under 200 lines.

**CLAUDE.md vs Rules vs Skills.**

| Aspect | CLAUDE.md | `.claude/rules/` | Skill |
|--------|-----------|------------------|-------|
| Loads | Every session | Every session, or when matching files are opened | On demand, when invoked or relevant |
| Scope | Whole project | Can be scoped to file paths | Task-specific |
| Best for | Core conventions and build commands | Language-specific or directory-specific guidelines | Reference material, repeatable workflows |

Use rules to keep CLAUDE.md focused. Rules with `paths` frontmatter only load when Claude works with matching files, saving context.

**Subagent vs Agent team.** Subagents run inside your session and report results back to your main context. Agent teams are independent Claude Code sessions that communicate with each other.

| Aspect | Subagent | Agent team |
|--------|----------|------------|
| Context | Own context window; results return to the caller | Own context window; fully independent |
| Communication | Reports results back to the main agent only | Teammates message each other directly |
| Coordination | Main agent manages all work | Shared task list with self-coordination |
| Best for | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| Token cost | Lower: results summarized back to main context | Higher: each teammate is a separate Claude instance |

Use a subagent for a focused worker: research a question, verify a claim, review a file. Use an agent team when teammates need to share findings, challenge each other, and coordinate independently.

Transition point: If you're running parallel subagents but hitting context limits, or if your subagents need to communicate with each other, agent teams are the natural next step.

Note: Agent teams are experimental and disabled by default.

**MCP vs Skill.** MCP connects Claude to external services. Skills extend what Claude knows.

| Aspect | MCP | Skill |
|--------|-----|-------|
| What it is | Protocol for connecting to external services | Knowledge, workflows, and reference material |
| Provides | Tools and data access | Knowledge, workflows, reference material |
| Examples | Slack integration, database queries, browser control | Code review checklist, deploy workflow, API style guide |

Example: An MCP server connects Claude to your database. A skill teaches Claude your data model, common query patterns, and which tables to use for different tasks.

### Understand how features layer

When the same feature exists at multiple levels:

- **CLAUDE.md files** are additive: all levels contribute content simultaneously. Files from your working directory and above load at launch; subdirectories load as you work in them. When instructions conflict, Claude uses judgment to reconcile them, with more specific instructions typically taking precedence.
- **Skills and subagents** override by name: managed > user > project for skills; managed > CLI flag > project > user > plugin for subagents. Plugin skills are namespaced to avoid conflicts.
- **MCP servers** override by name: local > project > user.
- **Hooks** merge: all registered hooks fire for their matching events regardless of source.

### Combine features

Each extension solves a different problem. Real setups combine them.

| Pattern | How it works | Example |
|---------|--------------|---------|
| Skill + MCP | MCP provides the connection; a skill teaches Claude how to use it well | MCP connects to your database, a skill documents your schema and query patterns |
| Skill + Subagent | A skill spawns subagents for parallel work | `/audit` skill kicks off security, performance, and style subagents that work in isolated context |
| CLAUDE.md + Skills | CLAUDE.md holds always-on rules; skills hold reference material loaded on demand | CLAUDE.md says "follow our API conventions," a skill contains the full API style guide |
| Hook + MCP | A hook triggers external actions through MCP | Post-edit hook sends a Slack notification when Claude modifies critical files |

## Understand context costs

Every feature you add consumes some of Claude's context. Too much can fill up your context window, but it can also add noise that makes Claude less effective; skills may not trigger correctly, or Claude may lose track of your conventions.

### Context cost by feature

| Feature | When it loads | What loads | Context cost |
|---------|---------------|------------|--------------|
| CLAUDE.md | Session start | Full content | Every request |
| Skills | Session start + when used | Descriptions at start, full content when used | Low (descriptions every request)* |
| MCP servers | Session start | Tool names; full schemas on demand | Low until a tool is used |
| Subagents | When spawned | Fresh context with specified skills | Isolated from main session |
| Hooks | On trigger | Nothing (runs externally) | Zero, unless hook returns additional context |

*By default, skill descriptions load at session start so Claude can decide when to use them. Set `disable-model-invocation: true` in a skill's frontmatter to hide it from Claude entirely until you invoke it manually. This reduces context cost to zero for skills you only trigger yourself.

### Understand how features load

**CLAUDE.md.** Loads at session start. Full content of all CLAUDE.md files (managed, user, and project levels). Claude reads CLAUDE.md files from your working directory up to the root, and discovers nested ones in subdirectories as it accesses those files.

**Skills.** By default, descriptions load at session start and full content loads when used. For user-only skills (`disable-model-invocation: true`), nothing loads until you invoke them. For model-invocable skills, Claude sees names and descriptions in every request. Claude matches your task against skill descriptions to decide which are relevant. If descriptions are vague or overlap, Claude may load the wrong skill or miss one that would help. In subagents: skills passed to a subagent are fully preloaded into its context at launch. Subagents don't inherit skills from the main session; you must specify them explicitly. Tip: Use `disable-model-invocation: true` for skills with side effects.

**MCP servers.** Loads at session start: tool names from connected servers. Full JSON schemas stay deferred until Claude needs a specific tool. Tool search is on by default. Reliability note: MCP connections can fail silently mid-session; if a server disconnects, Claude may try to use a tool that no longer exists. Check the connection with `/mcp`.

**Subagents.** On demand, when you or Claude spawns one for a task. Fresh, isolated context containing:
- The system prompt (shared with parent for cache efficiency)
- Full content of skills listed in the agent's `skills:` field
- CLAUDE.md and git status (inherited from parent)
- Whatever context the lead agent passes in the prompt

Isolated from main session. Subagents don't inherit conversation history or invoked skills.

**Hooks.** On trigger. Hooks fire at specific lifecycle events like tool execution, session boundaries, prompt submission, permission requests, and compaction. Nothing loads by default; hooks run as external scripts. Zero context cost unless the hook returns output that gets added as messages.

## Learn more

Each feature has its own dedicated guide at code.claude.com/docs/en/:
- CLAUDE.md (memory)
- Skills
- Subagents (sub-agents)
- Agent teams
- MCP
- Hooks (hooks-guide)
- Plugins
- Plugin Marketplaces

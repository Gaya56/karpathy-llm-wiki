# Claude Code Overview

> Sources: Anthropic, 2026-04-16; Anthropic, 2026-04-17
> Raw: [claude-code-overview](../../raw/claude-code/claude-code-overview.md)
> Updated: 2026-04-17

## Overview

Claude Code is Anthropic's agentic coding tool — an AI-powered assistant that reads codebases, edits files across multiple tools, and automates development tasks. It ships as a single engine behind a terminal CLI, IDE extensions (VS Code, JetBrains), a standalone desktop app for macOS and Windows, and a browser client. CLAUDE.md files, settings, and MCP servers work across every surface, so the same project configuration follows you between environments.

## Surfaces

Five primary surfaces, plus integration paths for CI/CD, chat, and browsers.

**Terminal CLI** is the full-featured command line. Native installs use `curl -fsSL https://claude.ai/install.sh | bash` on macOS, Linux, and WSL; `irm https://claude.ai/install.ps1 | iex` on Windows PowerShell; and a `curl`-and-run sequence on Windows CMD. Native installs auto-update in the background. Alternative package managers — Homebrew (`brew install --cask claude-code`, with `claude-code@latest` for the bleeding edge) and WinGet (`winget install Anthropic.ClaudeCode`) — don't auto-update and need periodic `brew upgrade` / `winget upgrade` runs. Windows native installs require Git for Windows; WSL does not. Running `claude` in a project starts a session.

**IDE extensions.** VS Code (and Cursor, via the same extension) and JetBrains give inline diffs, @-mentions, plan review, and conversation history inside the editor. Install from the extensions marketplace.

**Desktop app.** Standalone native app for macOS (Intel and Apple Silicon) and Windows (x64 and ARM64). Supports visual diff review, multiple concurrent sessions side by side, scheduled recurring tasks, and cloud sessions. Requires a paid subscription.

**Web.** Browser-based, no local setup, also reachable through the Claude iOS app. Suited to long-running tasks, work on repos that aren't cloned locally, and kicking off multiple parallel jobs. Entry point: claude.ai/code.

**CI and chat integrations.** GitHub Actions and GitLab CI/CD automate PR review and issue triage. GitHub Code Review gives automatic review on every PR. Slack routes bug reports into pull requests when `@Claude` is mentioned. Chrome is used for debugging live web applications.

Most surfaces require a Claude subscription or Anthropic Console account. The Terminal CLI and VS Code also support third-party providers: Amazon Bedrock, Google Vertex AI, and Microsoft Foundry.

## Capability categories

The overview groups Claude Code's work into several categories.

**Feature development and bug fixing.** Plain-language descriptions turn into planned, multi-file implementations. Error messages or symptom descriptions become root-cause analyses and fixes.

**Chore automation.** Writing tests for untested code, fixing lint errors across a project, resolving merge conflicts, updating dependencies, drafting release notes.

**Version control.** Direct git integration — stages changes, writes commit messages, creates branches, opens pull requests.

**Unix-style composition.** The `claude` binary pipes with other tools. Examples from the overview:

```bash
tail -200 app.log | claude -p "Slack me if you see any anomalies"
git diff main --name-only | claude -p "review these changed files for security issues"
```

**Scheduled execution.** Three mechanisms with different properties:

- *Routines* run on Anthropic-managed infrastructure, so they continue even when the user's machine is off. They can also trigger on API calls or GitHub events. Created from the web, Desktop app, or `/schedule` in the CLI.
- *Desktop scheduled tasks* run on the local machine with access to local files and tools.
- *`/loop`* repeats a prompt within an active CLI session — short-horizon polling, not persistent scheduling.

**Multi-surface portability.** Sessions aren't tied to one surface. Remote Control keeps a local session reachable from a phone or browser. Dispatch lets the user send a task from a phone that opens in the desktop app. Web and iOS sessions can be pulled into a terminal with `claude --teleport`. A terminal session can hand off to the desktop app with `/desktop`.

## Customization

Three mechanisms shape per-project or per-user behavior.

**CLAUDE.md** is a markdown file at the project root, read at the start of every session. Encodes coding standards, architecture decisions, library preferences, review checklists. Supplemented by *auto memory* — Claude persists build commands, debugging insights, and similar learnings across sessions without explicit user instruction.

**Skills** (custom commands like `/review-pr`, `/deploy-staging`) package repeatable workflows. Team-shareable.

**Hooks** run shell commands before or after specific Claude Code actions. Documented examples: auto-formatting after every file edit, running lint before every commit.

## Agent teams and SDK

Multiple Claude Code agents can work on parts of a task in parallel, with a lead agent coordinating subtask assignment and merging results. For workflows that go beyond Claude Code itself, the Agent SDK exposes Claude Code's tools and capabilities to custom agents, with programmatic control over orchestration, tool access, and permissions.

## Model Context Protocol

MCP — the Model Context Protocol — is the open-standard mechanism for connecting Claude Code to external data sources. Documented use cases: reading design docs in Google Drive, updating Jira tickets, pulling data from Slack, or plugging in custom tooling. MCP is the seam where Claude Code's capabilities extend past the local filesystem and shell.

## See Also

- [Extending Claude Code](extensions.md) — mechanisms (CLAUDE.md, Skills, Subagents, Agent Teams, MCP, Hooks, Plugins) explained in depth, with comparisons and context-cost trade-offs
- [MCP in Claude Code](mcp.md) — full MCP reference: installing servers, scopes, OAuth, Tool Search, output limits, resources, prompts, and managed organization configuration
- [Claude Prompting Best Practices](claude-prompting-best-practices.md) — model-specific behavioral tuning, general prompting principles, output control, tool use, thinking/reasoning, and agentic system patterns
- [Headless Mode](headless-mode.md) — `claude -p`, `--bare`, output formats, session chaining via `--resume`
- [CLI Reference](cli-reference.md) — complete command and flag reference
- [Scheduled Tasks and /loop](scheduled-tasks.md) — in-session recurring work, `CronCreate` tools, cron reference
- [Cloud Routines](cloud-routines.md) — laptop-off scheduling with schedule, API, and GitHub triggers
- [Agent SDK](agent-sdk.md) — programmatic Claude Code via Python or TypeScript
- [Claude Code Desktop](desktop.md) — desktop app, parallel sessions, Remote Control, `--teleport`
- [Running Claude Code Autonomously](running-autonomously.md) — end-to-end playbook combining the above

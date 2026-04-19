# Claude Code overview

> Source: https://code.claude.com/docs/en/overview
> Collected: 2026-04-16
> Published: Unknown

Claude Code is an agentic coding tool that reads your codebase, edits files, runs commands, and integrates with your development tools. Available in your terminal, IDE, desktop app, and browser.

Claude Code is an AI-powered coding assistant that helps you build features, fix bugs, and automate development tasks. It understands your entire codebase and can work across multiple files and tools to get things done.

## Get started

Choose your environment to get started. Most surfaces require a Claude subscription or Anthropic Console account. The Terminal CLI and VS Code also support third-party providers.

### Terminal

The full-featured CLI for working with Claude Code directly in your terminal. Edit files, run commands, and manage your entire project from the command line.

**Native Install (Recommended):**

- macOS, Linux, WSL:
  ```
  curl -fsSL https://claude.ai/install.sh | bash
  ```
- Windows PowerShell:
  ```
  irm https://claude.ai/install.ps1 | iex
  ```
- Windows CMD:
  ```
  curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
  ```

If PowerShell shows `The token '&&' is not a valid statement separator`, you're in PowerShell, not CMD. If CMD shows `'irm' is not recognized as an internal or external command`, you're in CMD, not PowerShell. PowerShell shows `PS C:\`; CMD shows `C:\` without `PS`.

Native Windows setups require Git for Windows; WSL setups do not. Native installations automatically update in the background.

**Homebrew:**
```
brew install --cask claude-code
```

Two casks exist. `claude-code` tracks the stable release channel (typically ~1 week behind, skips releases with major regressions). `claude-code@latest` tracks the latest channel. Homebrew installs do not auto-update; run `brew upgrade claude-code` or `brew upgrade claude-code@latest` periodically.

**WinGet:**
```
winget install Anthropic.ClaudeCode
```

WinGet installs do not auto-update; run `winget upgrade Anthropic.ClaudeCode` periodically.

Then start Claude Code in any project:
```
cd your-project
claude
```

You'll be prompted to log in on first use.

### VS Code

The VS Code extension provides inline diffs, @-mentions, plan review, and conversation history directly in your editor.

- Install for VS Code: `vscode:extension/anthropic.claude-code`
- Install for Cursor: `cursor:extension/anthropic.claude-code`

Or search for "Claude Code" in the Extensions view (`Cmd+Shift+X` on Mac, `Ctrl+Shift+X` on Windows/Linux). After installing, open the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`), type "Claude Code", and select **Open in New Tab**.

### Desktop app

A standalone app for running Claude Code outside your IDE or terminal. Review diffs visually, run multiple sessions side by side, schedule recurring tasks, kick off cloud sessions. Downloads:

- macOS (Intel and Apple Silicon)
- Windows (x64)
- Windows ARM64

After installing, launch Claude, sign in, click the **Code** tab. A paid subscription is required.

### Web

Run Claude Code in your browser with no local setup. Useful for long-running tasks, work on repos not cloned locally, or multiple parallel tasks. Available on desktop browsers and the Claude iOS app. Start at claude.ai/code.

### JetBrains

A plugin for IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs. Interactive diff viewing and selection context sharing. Install the Claude Code plugin from the JetBrains Marketplace and restart your IDE.

## What you can do

### Automate the work you keep putting off

Claude Code handles the tedious tasks that eat up your day: writing tests for untested code, fixing lint errors across a project, resolving merge conflicts, updating dependencies, and writing release notes.

```
claude "write tests for the auth module, run them, and fix any failures"
```

### Build features and fix bugs

Describe what you want in plain language. Claude Code plans the approach, writes the code across multiple files, and verifies it works.

For bugs, paste an error message or describe the symptom. Claude Code traces the issue through your codebase, identifies the root cause, and implements a fix.

### Create commits and pull requests

Claude Code works directly with git. It stages changes, writes commit messages, creates branches, and opens pull requests.

```
claude "commit my changes with a descriptive message"
```

In CI, you can automate code review and issue triage with GitHub Actions or GitLab CI/CD.

### Connect your tools with MCP

The Model Context Protocol (MCP) is an open standard for connecting AI tools to external data sources. With MCP, Claude Code can read your design docs in Google Drive, update tickets in Jira, pull data from Slack, or use your own custom tooling.

### Customize with instructions, skills, and hooks

`CLAUDE.md` is a markdown file you add to your project root that Claude Code reads at the start of every session. Use it to set coding standards, architecture decisions, preferred libraries, and review checklists. Claude also builds auto memory as it works, saving learnings like build commands and debugging insights across sessions without you writing anything.

Create custom commands (skills) to package repeatable workflows your team can share, like `/review-pr` or `/deploy-staging`.

Hooks let you run shell commands before or after Claude Code actions, like auto-formatting after every file edit or running lint before a commit.

### Run agent teams and build custom agents

Spawn multiple Claude Code agents that work on different parts of a task simultaneously. A lead agent coordinates the work, assigns subtasks, and merges results.

For fully custom workflows, the Agent SDK lets you build your own agents powered by Claude Code's tools and capabilities, with full control over orchestration, tool access, and permissions.

### Pipe, script, and automate with the CLI

Claude Code is composable and follows the Unix philosophy. Pipe logs into it, run it in CI, or chain it with other tools:

```
# Analyze recent log output
tail -200 app.log | claude -p "Slack me if you see any anomalies"

# Automate translations in CI
claude -p "translate new strings into French and raise a PR for review"

# Bulk operations across files
git diff main --name-only | claude -p "review these changed files for security issues"
```

### Schedule recurring tasks

Run Claude on a schedule to automate work that repeats: morning PR reviews, overnight CI failure analysis, weekly dependency audits, or syncing docs after PRs merge.

- **Routines** run on Anthropic-managed infrastructure, so they keep running even when your computer is off. They can also trigger on API calls or GitHub events. Create them from the web, the Desktop app, or by running `/schedule` in the CLI.
- **Desktop scheduled tasks** run on your machine, with direct access to your local files and tools.
- **`/loop`** repeats a prompt within a CLI session for quick polling.

### Work from anywhere

Sessions aren't tied to a single surface. Move work between environments as your context changes:

- Step away from your desk and keep working from your phone or any browser with Remote Control.
- Message Dispatch a task from your phone and open the Desktop session it creates.
- Kick off a long-running task on the web or iOS app, then pull it into your terminal with `claude --teleport`.
- Hand off a terminal session to the Desktop app with `/desktop` for visual diff review.
- Route tasks from team chat: mention `@Claude` in Slack with a bug report and get a pull request back.

## Use Claude Code everywhere

Each surface connects to the same underlying Claude Code engine, so your CLAUDE.md files, settings, and MCP servers work across all of them.

Beyond the Terminal, VS Code, JetBrains, Desktop, and Web environments above, Claude Code integrates with CI/CD, chat, and browser workflows:

| I want to... | Best option |
| --- | --- |
| Continue a local session from my phone or another device | Remote Control |
| Push events from Telegram, Discord, iMessage, or my own webhooks into a session | Channels |
| Start a task locally, continue on mobile | Web or Claude iOS app |
| Run Claude on a recurring schedule | Routines or Desktop scheduled tasks |
| Automate PR reviews and issue triage | GitHub Actions or GitLab CI/CD |
| Get automatic code review on every PR | GitHub Code Review |
| Route bug reports from Slack to pull requests | Slack |
| Debug live web applications | Chrome |
| Build custom agents for your own workflows | Agent SDK |

## Next steps

- Quickstart — walk through your first real task, from exploring a codebase to committing a fix
- Store instructions and memories — CLAUDE.md files and auto memory
- Common workflows and best practices
- Settings
- Troubleshooting
- code.claude.com — demos, pricing, product details

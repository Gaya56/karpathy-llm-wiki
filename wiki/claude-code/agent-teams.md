# Agent Teams

> Sources: Anthropic, 2026-04-22
> Raw: [2026-04-22-claude-code-agent-teams](../../raw/claude-code/2026-04-22-claude-code-agent-teams.md)
> Updated: 2026-04-22

## Overview

Agent teams let you coordinate multiple Claude Code instances working together on a shared task. One session acts as the **team lead**, orchestrating work via a shared task list and synthesizing results. **Teammates** are fully independent Claude Code sessions — each with its own context window — that communicate with each other directly via a mailbox system. Unlike subagents, which only report back to the parent, teammates can message each other without going through the lead, and you can interact with any teammate directly.

Agent teams are experimental, require Claude Code v2.1.32+, and are disabled by default. Enable them with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in your environment or settings.json.

## When to use agent teams

Use agent teams when parallel exploration delivers real value and teammates need to share findings, challenge each other, or coordinate autonomously:

* **Research and review** — multiple teammates investigate different aspects simultaneously, then share and challenge findings
* **New modules or features** — teammates each own a separate piece without file conflicts
* **Debugging with competing hypotheses** — teammates test different theories in parallel; the surviving theory is more likely correct
* **Cross-layer coordination** — changes spanning frontend, backend, and tests, each owned by a different teammate

Agent teams add coordination overhead and use significantly more tokens than a single session. Avoid them for sequential tasks, same-file edits, or work with many dependencies — use a single session or subagents instead.

### Subagents vs. agent teams

|                   | Subagents                                        | Agent teams                                         |
| :---------------- | :----------------------------------------------- | :-------------------------------------------------- |
| **Context**       | Own context window; results return to the caller | Own context window; fully independent               |
| **Communication** | Report results back to the main agent only       | Teammates message each other directly               |
| **Coordination**  | Main agent manages all work                      | Shared task list with self-coordination             |
| **Best for**      | Focused tasks where only the result matters      | Complex work requiring discussion and collaboration |
| **Token cost**    | Lower: results summarized back to main context   | Higher: each teammate is a separate Claude instance |

The transition signal: if parallel subagents are hitting context limits or need to talk to each other, promote to a team.

## Architecture

| Component     | Role                                                                                       |
| :------------ | :----------------------------------------------------------------------------------------- |
| **Team lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks                            |
| **Task list** | Shared list of work items that teammates claim and complete                                |
| **Mailbox**   | Messaging system for direct communication between agents                                   |

Storage is local:

* Team config: `~/.claude/teams/{team-name}/config.json` — holds runtime state (session IDs, pane IDs). Do not edit by hand; it is overwritten on every state update.
* Task list: `~/.claude/tasks/{team-name}/`

The team config `members` array lets teammates discover each other by name. There is no project-level equivalent — a `.claude/teams/` file in your project directory is ignored.

## Enabling and starting a team

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Once enabled, describe the task and team structure in natural language. Claude creates the team, spawns teammates, and coordinates work based on your prompt. Example:

```
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

Claude creates a team with a shared task list, spawns the teammates, has them explore the problem, synthesizes findings, and cleans up when finished.

## Display modes

* **In-process** (default when not in tmux): all teammates run in your main terminal. Use Shift+Down to cycle through teammates; type to message the active one. Press Ctrl+T to toggle the task list, Escape to interrupt a turn.
* **Split panes** (default when inside tmux): each teammate gets its own pane. Click into a pane to interact directly. Requires tmux or iTerm2 with the `it2` CLI.

The default is `"auto"`. Override globally in `~/.claude.json`:

```json
{ "teammateMode": "in-process" }
```

Or for a single session:

```bash
claude --teammate-mode in-process
```

## Controlling the team

**Specify teammates and models.** Claude decides how many to spawn, or you can direct it:

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

**Require plan approval.** For complex or risky tasks, require teammates to plan before implementing. The teammate stays in read-only plan mode until the lead approves. The lead makes approval decisions autonomously based on criteria you provide in the prompt (e.g., "only approve plans that include test coverage").

**Direct messaging.** Each teammate is a full Claude Code session. In in-process mode, Shift+Down cycles to the teammate; type to send a message. In split-pane mode, click the pane.

**Task assignment.** Tasks have three states: pending, in-progress, completed. Tasks can declare dependencies; a task with unresolved dependencies cannot be claimed. The lead can assign tasks explicitly, or teammates self-claim the next unblocked task after finishing one. File locking prevents race conditions.

**Shutdown and cleanup.** To shut down a teammate: tell the lead to ask them to shut down; the teammate can accept or reject. When done, tell the lead to "clean up the team" — it removes shared resources. Always use the lead for cleanup; teammates may not resolve team context correctly.

## Quality gates with hooks

Three hook events apply to agent teams (see [Hooks Reference](hooks.md) for full configuration):

* `TeammateIdle` — fires when a teammate is about to go idle. Exit code 2 sends feedback and keeps the teammate working.
* `TaskCreated` — fires when a task is being created. Exit code 2 prevents creation and sends feedback.
* `TaskCompleted` — fires when a task is being marked complete. Exit code 2 prevents completion and sends feedback.

## Using subagent definitions as teammates

You can reference a named subagent definition (from project, user, plugin, or CLI scope) when spawning a teammate. This lets you define roles once and reuse them as both subagents and team members:

```
Spawn a teammate using the security-reviewer agent type to audit the auth module.
```

The teammate inherits the definition's `tools` allowlist and `model`. The definition body is appended to the teammate's system prompt as additional instructions (not a replacement). Team coordination tools (`SendMessage`, task tools) are always available regardless of `tools` restrictions.

Caveat: `skills` and `mcpServers` frontmatter fields in a subagent definition are not applied when running as a teammate. Teammates load skills and MCP servers from project and user settings.

## Context and communication

Each teammate loads the same project context as a regular session (CLAUDE.md, MCP servers, skills) plus the spawn prompt from the lead. The lead's conversation history does not carry over.

Communication mechanisms:

* **message** — send to one specific teammate by name
* **broadcast** — send to all teammates simultaneously (use sparingly; costs scale with team size)
* **Idle notifications** — teammates automatically notify the lead when they finish
* **Shared task list** — all agents see task status and can claim available work

## Token usage

Token usage scales linearly with active teammates. For research, review, and parallel feature work, the extra tokens are usually worthwhile. For routine tasks, a single session is more cost-effective.

## Best practices

**Team size.** Start with 3–5 teammates. Coordination overhead increases with team size; diminishing returns appear quickly beyond 5. Having 5–6 tasks per teammate keeps everyone productive without excessive context switching.

**Task sizing.** Too small = coordination overhead exceeds benefit. Too large = teammates go too long without check-ins. Aim for self-contained units with a clear deliverable (a function, a test file, a review). If the lead isn't creating enough tasks, ask it to split work into smaller pieces.

**Give context in the spawn prompt.** Teammates don't inherit the lead's conversation history — include task-specific details in the spawn prompt. The more precise the spawn prompt, the less rework.

**Avoid file conflicts.** Two teammates editing the same file leads to overwrites. Partition work so each teammate owns a distinct set of files.

**Monitor and steer.** Don't let a team run unattended for too long. Check in, redirect approaches that aren't working, synthesize findings as they come in.

**Start with research tasks.** If new to agent teams, start with tasks that have clear boundaries and don't require writing code: reviewing a PR, researching a library, or investigating a bug.

## Limitations

* **No session resumption with in-process teammates** — `/resume` and `/rewind` do not restore in-process teammates. Spawn fresh teammates after resuming a lead session.
* **Task status can lag** — teammates sometimes fail to mark tasks completed, blocking dependents. Update status manually or tell the lead to nudge the teammate.
* **Slow shutdown** — teammates finish their current request or tool call before exiting.
* **One team per session** — clean up before starting a new team.
* **No nested teams** — teammates cannot spawn their own teams or teammates.
* **Lead is fixed** — the session that creates the team remains the lead; leadership cannot be transferred.
* **Permissions set at spawn** — all teammates start with the lead's permission mode; individual modes can be changed after spawning but not at spawn time.
* **Split panes require tmux or iTerm2** — not supported in VS Code integrated terminal, Windows Terminal, or Ghostty.

## Use case examples

**Parallel code review.** Assign each teammate a distinct review lens (security, performance, test coverage). Each reviewer works from the same PR but applies a different filter. The lead synthesizes findings across all three.

**Competing hypotheses debugging.** Spawn 3–5 teammates, each assigned a different hypothesis, with instructions to actively challenge each other's theories. The theory that survives adversarial debate is more likely to be the actual root cause — sequential investigation suffers from anchoring; parallel adversarial investigation does not.

## See Also

- [Custom Subagents](subagents.md) — subagent configuration (frontmatter fields, scopes, foreground vs. background) and how subagent definitions can be reused as teammates
- [Extending Claude Code](extensions.md) — how agent teams sit alongside subagents, skills, MCP, hooks, and plugins in the extension surface
- [Hooks Reference](hooks.md) — full event vocabulary including `TeammateIdle`, `TaskCreated`, and `TaskCompleted`
- [tmux-cli](tmux-cli.md) — third-party tool for programmatic tmux pane control; useful when running agent teams in split-pane mode
- [Claude Code Overview](overview.md) — product-level context for parallel work and SDK integration

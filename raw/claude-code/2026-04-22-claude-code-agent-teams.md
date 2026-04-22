# Orchestrate teams of Claude Code sessions

> Source: https://code.claude.com/docs/en/agent-teams
> Collected: 2026-04-22
> Published: Unknown

Agent teams let you coordinate multiple Claude Code instances working together. One session acts as the team lead, coordinating work, assigning tasks, and synthesizing results. Teammates work independently, each in its own context window, and communicate directly with each other.

Unlike subagents, which run within a single session and can only report back to the main agent, you can also interact with individual teammates directly without going through the lead.

Agent teams require Claude Code v2.1.32 or later. Agent teams are experimental and disabled by default. Enable them by setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` in settings.json or environment.

## When to use agent teams

Agent teams are most effective for tasks where parallel exploration adds real value. The strongest use cases are:

* **Research and review**: multiple teammates can investigate different aspects of a problem simultaneously, then share and challenge each other's findings
* **New modules or features**: teammates can each own a separate piece without stepping on each other
* **Debugging with competing hypotheses**: teammates test different theories in parallel and converge on the answer faster
* **Cross-layer coordination**: changes that span frontend, backend, and tests, each owned by a different teammate

Agent teams add coordination overhead and use significantly more tokens than a single session. They work best when teammates can operate independently. For sequential tasks, same-file edits, or work with many dependencies, a single session or subagents are more effective.

### Compare with subagents

|                   | Subagents                                        | Agent teams                                         |
| :---------------- | :----------------------------------------------- | :-------------------------------------------------- |
| **Context**       | Own context window; results return to the caller | Own context window; fully independent               |
| **Communication** | Report results back to the main agent only       | Teammates message each other directly               |
| **Coordination**  | Main agent manages all work                      | Shared task list with self-coordination             |
| **Best for**      | Focused tasks where only the result matters      | Complex work requiring discussion and collaboration |
| **Token cost**    | Lower: results summarized back to main context   | Higher: each teammate is a separate Claude instance |

Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share findings, challenge each other, and coordinate on their own.

## Enable agent teams

Enable by setting the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable to `1`, either in your shell environment or through settings.json:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Start your first agent team

Tell Claude to create an agent team and describe the task and team structure in natural language. Claude creates the team, spawns teammates, and coordinates work.

From there, Claude creates a team with a shared task list, spawns teammates for each perspective, has them explore the problem, synthesizes findings, and attempts to clean up the team when finished.

The lead's terminal lists all teammates and what they're working on. Use Shift+Down to cycle through teammates and message them directly. After the last teammate, Shift+Down wraps back to the lead.

## Control your agent team

Tell the lead what you want in natural language. It handles team coordination, task assignment, and delegation based on your instructions.

### Choose a display mode

Agent teams support two display modes:

* **In-process**: all teammates run inside your main terminal. Use Shift+Down to cycle through teammates and type to message them directly. Works in any terminal, no extra setup required.
* **Split panes**: each teammate gets its own pane. You can see everyone's output at once and click into a pane to interact directly. Requires tmux, or iTerm2.

The default is `"auto"`, which uses split panes if you're already running inside a tmux session, and in-process otherwise. To override, set `teammateMode` in your global config at `~/.claude.json`:

```json
{
  "teammateMode": "in-process"
}
```

To force in-process mode for a single session:

```bash
claude --teammate-mode in-process
```

Split-pane mode requires either tmux or iTerm2 with the `it2` CLI.

### Specify teammates and models

Claude decides the number of teammates to spawn based on your task, or you can specify exactly what you want:

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

### Require plan approval for teammates

For complex or risky tasks, you can require teammates to plan before implementing. The teammate works in read-only plan mode until the lead approves their approach.

When a teammate finishes planning, it sends a plan approval request to the lead. The lead reviews the plan and either approves it or rejects it with feedback. If rejected, the teammate stays in plan mode, revises based on the feedback, and resubmits.

The lead makes approval decisions autonomously. To influence the lead's judgment, give it criteria in your prompt.

### Talk to teammates directly

Each teammate is a full, independent Claude Code session. You can message any teammate directly.

* **In-process mode**: use Shift+Down to cycle through teammates, then type to send them a message. Press Enter to view a teammate's session, then Escape to interrupt their current turn. Press Ctrl+T to toggle the task list.
* **Split-pane mode**: click into a teammate's pane to interact with their session directly.

### Assign and claim tasks

The shared task list coordinates work across the team. The lead creates tasks and teammates work through them. Tasks have three states: pending, in progress, and completed. Tasks can also depend on other tasks: a pending task with unresolved dependencies cannot be claimed until those dependencies are completed.

Task claiming uses file locking to prevent race conditions when multiple teammates try to claim the same task simultaneously.

### Shut down teammates

```
Ask the researcher teammate to shut down
```

The lead sends a shutdown request. The teammate can approve, exiting gracefully, or reject with an explanation.

### Clean up the team

```
Clean up the team
```

This removes the shared team resources. When the lead runs cleanup, it checks for active teammates and fails if any are still running, so shut them down first. Always use the lead to clean up — teammates should not run cleanup because their team context may not resolve correctly.

### Enforce quality gates with hooks

Use hooks to enforce rules when teammates finish work or tasks are created or completed:

* `TeammateIdle`: runs when a teammate is about to go idle. Exit with code 2 to send feedback and keep the teammate working.
* `TaskCreated`: runs when a task is being created. Exit with code 2 to prevent creation and send feedback.
* `TaskCompleted`: runs when a task is being marked complete. Exit with code 2 to prevent completion and send feedback.

## How agent teams work

### Architecture

An agent team consists of:

| Component     | Role                                                                                       |
| :------------ | :----------------------------------------------------------------------------------------- |
| **Team lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks                            |
| **Task list** | Shared list of work items that teammates claim and complete                                |
| **Mailbox**   | Messaging system for communication between agents                                          |

Teams and tasks are stored locally:

* **Team config**: `~/.claude/teams/{team-name}/config.json`
* **Task list**: `~/.claude/tasks/{team-name}/`

The team config contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can read this file to discover other team members. Don't edit the config by hand — it's overwritten on the next state update.

There is no project-level equivalent of the team config. A file like `.claude/teams/teams.json` in your project directory is not recognized as configuration.

### Use subagent definitions for teammates

When spawning a teammate, you can reference a subagent type from any subagent scope: project, user, plugin, or CLI-defined. This lets you define a role once and reuse it both as a delegated subagent and as an agent team teammate.

To use a subagent definition:

```
Spawn a teammate using the security-reviewer agent type to audit the auth module.
```

The teammate honors that definition's `tools` allowlist and `model`, and the definition's body is appended to the teammate's system prompt as additional instructions rather than replacing it. Team coordination tools (`SendMessage` and task management tools) are always available to a teammate even when `tools` restricts other tools.

Note: the `skills` and `mcpServers` frontmatter fields in a subagent definition are not applied when that definition runs as a teammate. Teammates load skills and MCP servers from project and user settings.

### Permissions

Teammates start with the lead's permission settings. If the lead runs with `--dangerously-skip-permissions`, all teammates do too. After spawning, you can change individual teammate modes, but you can't set per-teammate modes at spawn time.

### Context and communication

Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: CLAUDE.md, MCP servers, and skills. It also receives the spawn prompt from the lead. The lead's conversation history does not carry over.

**How teammates share information:**

* **Automatic message delivery**: when teammates send messages, they're delivered automatically to recipients. The lead doesn't need to poll for updates.
* **Idle notifications**: when a teammate finishes and stops, they automatically notify the lead.
* **Shared task list**: all agents can see task status and claim available work.

**Teammate messaging:**

* **message**: send a message to one specific teammate
* **broadcast**: send to all teammates simultaneously. Use sparingly, as costs scale with team size.

The lead assigns every teammate a name when it spawns them, and any teammate can message any other by that name.

### Token usage

Agent teams use significantly more tokens than a single session. Each teammate has its own context window, and token usage scales with the number of active teammates.

## Use case examples

### Run a parallel code review

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Each reviewer works from the same PR but applies a different filter. The lead synthesizes findings across all three after they finish.

### Investigate with competing hypotheses

```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```

The debate structure fights anchoring bias — once one theory is explored, sequential investigation tends to be biased toward it. With multiple independent investigators actively trying to disprove each other, the surviving theory is more likely to be the actual root cause.

## Best practices

### Give teammates enough context

Teammates load project context automatically (CLAUDE.md, MCP servers, skills) but don't inherit the lead's conversation history. Include task-specific details in the spawn prompt:

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

### Choose an appropriate team size

* **Token costs scale linearly**: each teammate has its own context window and consumes tokens independently.
* **Coordination overhead increases**: more teammates means more communication and potential for conflicts.
* **Diminishing returns**: beyond a certain point, additional teammates don't speed up work proportionally.

Start with 3-5 teammates for most workflows. Having 5-6 tasks per teammate keeps everyone productive without excessive context switching.

Scale up only when the work genuinely benefits from parallel work. Three focused teammates often outperform five scattered ones.

### Size tasks appropriately

* **Too small**: coordination overhead exceeds the benefit
* **Too large**: teammates work too long without check-ins, increasing risk of wasted effort
* **Just right**: self-contained units that produce a clear deliverable (a function, a test file, a review)

The lead breaks work into tasks and assigns them automatically. If it isn't creating enough tasks, ask it to split the work into smaller pieces.

### Wait for teammates to finish

Sometimes the lead starts implementing tasks itself instead of waiting for teammates:

```
Wait for your teammates to complete their tasks before proceeding
```

### Start with research and review

If you're new to agent teams, start with tasks that have clear boundaries and don't require writing code: reviewing a PR, researching a library, or investigating a bug.

### Avoid file conflicts

Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files.

### Monitor and steer

Check in on teammates' progress, redirect approaches that aren't working, and synthesize findings as they come in. Letting a team run unattended for too long increases the risk of wasted effort.

## Troubleshooting

### Teammates not appearing

* In in-process mode, teammates may already be running but not visible. Press Shift+Down to cycle through active teammates.
* Check that `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled.
* Check that the task you gave Claude was complex enough to warrant a team.
* If you explicitly requested split panes, ensure tmux is installed: `which tmux`

### Too many permission prompts

Teammate permission requests bubble up to the lead. Pre-approve common operations in your permission settings before spawning teammates to reduce interruptions.

### Teammates stopping on errors

Check their output using Shift+Down in in-process mode or by clicking the pane in split mode, then either give them additional instructions directly or spawn a replacement teammate.

### Lead shuts down before work is done

Tell the lead to keep going. You can also tell the lead to wait for teammates to finish before proceeding.

### Orphaned tmux sessions

```bash
tmux ls
tmux kill-session -t <session-name>
```

## Limitations

Agent teams are experimental. Current limitations:

* **No session resumption with in-process teammates**: `/resume` and `/rewind` do not restore in-process teammates. After resuming, the lead may attempt to message teammates that no longer exist — spawn new teammates instead.
* **Task status can lag**: teammates sometimes fail to mark tasks as completed, which blocks dependent tasks. Update the task status manually or tell the lead to nudge the teammate.
* **Shutdown can be slow**: teammates finish their current request or tool call before shutting down.
* **One team per session**: a lead can only manage one team at a time. Clean up the current team before starting a new one.
* **No nested teams**: teammates cannot spawn their own teams or teammates. Only the lead can manage the team.
* **Lead is fixed**: the session that creates the team is the lead for its lifetime. You can't promote a teammate to lead or transfer leadership.
* **Permissions set at spawn**: all teammates start with the lead's permission mode. You can change individual teammate modes after spawning, but not at spawn time.
* **Split panes require tmux or iTerm2**: not supported in VS Code's integrated terminal, Windows Terminal, or Ghostty.

CLAUDE.md works normally: teammates read CLAUDE.md files from their working directory.

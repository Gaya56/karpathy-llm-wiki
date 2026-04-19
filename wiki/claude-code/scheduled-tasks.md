# Scheduled Tasks and /loop

> Sources: Anthropic, 2026-04-19
> Raw: [2026-04-19-claude-code-scheduled-tasks](../../raw/claude-code/2026-04-19-claude-code-scheduled-tasks.md)
> Updated: 2026-04-19

## Overview

Claude Code's scheduled-task system lets a running session re-run prompts automatically — polling a deployment, babysitting a PR, or firing a one-time reminder. Tasks are session-scoped: they live in the current conversation and stop when a new one starts, though `--resume` or `--continue` restores unexpired tasks. For scheduling that outlives any session, use cloud Routines, Desktop scheduled tasks, or GitHub Actions. Requires Claude Code v2.1.72 or later.

## Scheduling options compared

Claude Code offers three ways to schedule recurring work:

|                            | Cloud (Routines)               | Desktop                     | `/loop`                             |
| :------------------------- | :----------------------------- | :-------------------------- | :---------------------------------- |
| Runs on                    | Anthropic cloud                | Your machine                | Your machine                        |
| Requires machine on        | No                             | Yes                         | Yes                                 |
| Requires open session      | No                             | No                          | Yes                                 |
| Persistent across restarts | Yes                            | Yes                         | Restored on `--resume` if unexpired |
| Access to local files      | No (fresh clone)               | Yes                         | Yes                                 |
| MCP servers                | Connectors configured per task | Config files and connectors | Inherits from session               |
| Permission prompts         | No (runs autonomously)         | Configurable per task       | Inherits from session               |
| Customizable schedule      | Via `/schedule` in CLI         | Yes                         | Yes                                 |
| Minimum interval           | 1 hour                         | 1 minute                    | 1 minute                            |

Guideline: use cloud tasks for unattended work that must run without your machine; use Desktop tasks when local file access is needed; use `/loop` for quick in-session polling.

## The /loop command

`/loop` is a bundled skill that re-runs a prompt while the session stays open. Both the interval and the prompt are optional:

| What you provide          | Example                     | What happens                                             |
| :------------------------ | :-------------------------- | :------------------------------------------------------- |
| Interval and prompt       | `/loop 5m check the deploy` | Prompt runs on a fixed cron schedule                     |
| Prompt only               | `/loop check the deploy`    | Prompt runs at a dynamically chosen interval             |
| Interval only, or nothing | `/loop`                     | Built-in maintenance prompt (or `loop.md`) runs          |

You can also chain commands: `/loop 20m /review-pr 1234` re-runs a packaged workflow each iteration.

### Fixed-interval loop

Supply an interval and Claude converts it to a cron expression, schedules the job, and confirms the cadence and job ID.

Supported units: `s` (seconds), `m` (minutes), `h` (hours), `d` (days). Seconds round up to the nearest minute (cron granularity). Non-clean steps like `7m` or `90m` round to the nearest supported cron step; Claude reports what it picked.

### Dynamic-interval loop

When the interval is omitted, Claude picks a delay between one minute and one hour after each iteration based on what it observed — shorter while a build is running, longer when things go quiet. The chosen delay and reasoning are printed at the end of each iteration.

On Bedrock, Vertex AI, and Microsoft Foundry, a prompt with no interval runs on a fixed 10-minute schedule instead.

Claude may internally use the Monitor tool for dynamic loops, streaming a background script's output rather than re-invoking the prompt on a timer — more token-efficient and responsive.

### Built-in maintenance prompt

A bare `/loop` (or `/loop 15m` for fixed cadence) runs a built-in maintenance sequence each iteration:

1. Continue any unfinished work from the conversation.
2. Tend to the current branch's PR: review comments, failed CI, merge conflicts.
3. Run cleanup passes (bug hunts, simplification) when nothing else is pending.

Claude does not start new initiatives outside that scope. Irreversible actions (push, delete) only proceed if the transcript already authorized them.

On Bedrock, Vertex AI, and Microsoft Foundry, bare `/loop` prints the usage message instead of starting the maintenance loop.

### Customizing the default prompt with loop.md

A `loop.md` file replaces the built-in maintenance prompt. It defines a single default for bare `/loop` and is ignored when you supply a prompt on the command line. Claude uses the first file found:

| Path                | Scope                                                  |
| :------------------ | :----------------------------------------------------- |
| `.claude/loop.md`   | Project-level. Takes precedence when both exist.       |
| `~/.claude/loop.md` | User-level. Applies when no project-level file exists. |

Write it as plain Markdown as if typing the `/loop` prompt directly. Edits take effect on the next iteration. Content beyond 25,000 bytes is truncated.

### Stopping a loop

Press `Esc` while a `/loop` is waiting for its next iteration to clear the pending wakeup. This affects only the `/loop` wakeup — tasks scheduled by asking Claude directly are unaffected and must be cancelled via `CronDelete` or natural language.

## One-time reminders

Describe the reminder in natural language; Claude schedules a single-fire task that deletes itself after running:

```
remind me at 3pm to push the release branch
in 45 minutes, check whether the integration tests passed
```

Claude pins the fire time to a specific minute and hour and confirms when it will fire.

## Managing tasks with CronCreate / CronList / CronDelete

Ask Claude in natural language ("what scheduled tasks do I have?", "cancel the deploy check job") or reference the underlying tools directly:

| Tool         | Purpose                                                                                          |
| :----------- | :----------------------------------------------------------------------------------------------- |
| `CronCreate` | Schedule a new task. Accepts a 5-field cron expression, the prompt, and recur/once flag.         |
| `CronList`   | List all scheduled tasks with their IDs, schedules, and prompts.                                 |
| `CronDelete` | Cancel a task by its 8-character ID.                                                             |

A session can hold up to 50 scheduled tasks at once.

## How tasks run

The scheduler checks every second for due tasks and enqueues them at low priority. Tasks fire between turns — never while Claude is mid-response. If Claude is busy, the prompt waits until the current turn ends. All times use your local timezone (not UTC).

### Jitter

To prevent sessions from hitting the API simultaneously, the scheduler adds a small deterministic offset derived from the task ID:

- Recurring tasks fire up to 10% of their period late, capped at 15 minutes. An hourly job fires anywhere from `:00` to `:06`.
- One-shot tasks scheduled at `:00` or `:30` fire up to 90 seconds early.

To avoid jitter on one-shot tasks, pick a non-round minute (e.g. `3 9 * * *` instead of `0 9 * * *`).

### Seven-day expiry

Recurring tasks automatically expire 7 days after creation: the task fires one final time, then deletes itself. Cancel and recreate before expiry, or switch to Routines or Desktop tasks for longer-lived schedules.

## Cron expression reference

`CronCreate` accepts standard 5-field expressions: `minute hour day-of-month month day-of-week`.

All fields support: wildcards (`*`), single values (`5`), steps (`*/15`), ranges (`1-5`), comma-separated lists (`1,15,30`).

| Example        | Meaning                      |
| :------------- | :--------------------------- |
| `*/5 * * * *`  | Every 5 minutes              |
| `0 * * * *`    | Every hour on the hour       |
| `7 * * * *`    | Every hour at 7 minutes past |
| `0 9 * * *`    | Every day at 9am local       |
| `0 9 * * 1-5`  | Weekdays at 9am local        |
| `30 14 15 3 *` | March 15 at 2:30pm local     |

Day-of-week: `0` or `7` = Sunday, `6` = Saturday. Extended syntax (`L`, `W`, `?`, `MON`, `JAN`) is not supported. When both day-of-month and day-of-week are constrained, a date matches if either field matches (vixie-cron semantics).

## Disabling the scheduler

Set `CLAUDE_CODE_DISABLE_CRON=1` in your environment to disable the scheduler entirely. The cron tools and `/loop` become unavailable, and already-scheduled tasks stop firing.

## Limitations

- Tasks only fire while Claude Code is running and idle. Closing the terminal stops them.
- No catch-up for missed fires: if a task's time passes while Claude is busy, it fires once when Claude becomes idle — not once per missed interval.
- Starting a fresh conversation clears all session tasks. `--resume` / `--continue` restores unexpired tasks only (recurring tasks within 7 days of creation; one-shots whose time has not passed). Background Bash and Monitor tasks are never restored on resume.

For unattended cron-driven automation: use [Routines](cloud-routines.md) (Anthropic-managed infrastructure), [Desktop scheduled tasks](desktop.md) (local machine), or GitHub Actions (`schedule` trigger).

## See Also

- [Cloud Routines](cloud-routines.md) — durable cloud-side scheduling that runs without an open session
- [Running Autonomously](running-autonomously.md) — headless and autonomous execution patterns
- [Desktop](desktop.md) — Desktop app's own scheduled-task surface
- [Claude Code Overview](overview.md) — product surfaces overview including Routines mention

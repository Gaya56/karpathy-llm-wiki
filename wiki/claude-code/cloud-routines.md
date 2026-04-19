# Cloud Routines

> Sources: Anthropic, 2026-04-19
> Raw: [Automate work with routines](../../raw/claude-code/2026-04-19-claude-code-routines.md)
> Updated: 2026-04-19

## Overview

A routine is a saved Claude Code configuration — a prompt, one or more repositories, and a set of MCP connectors — that runs automatically on Anthropic-managed cloud infrastructure. Because routines are cloud-hosted, they execute when your laptop is off. Each routine supports one or more trigger types (schedule, API, GitHub event) that can be combined freely, and runs as a full autonomous Claude Code session with no approval prompts.

## What a Routine Is

A routine packages three things together: a prompt describing what Claude should do, one or more GitHub repositories to work in, and a set of connectors for external services. At runtime Claude Code clones the selected repositories, applies the prompt, and can call any included connectors. There is no permission-mode picker; the session runs fully autonomously.

Routines belong to an individual claude.ai account and are not shared with teammates. Everything Claude does — commits, pull requests, Slack messages, Linear tickets — appears under the account owner's identity. Routines are available on Pro, Max, Team, and Enterprise plans with Claude Code on the web enabled.

## Trigger Types

A single routine can carry any combination of the three trigger types. They are not mutually exclusive.

### Schedule

Runs the routine on a recurring cadence. Preset options are hourly, daily, weekdays, and weekly. Times are entered in local timezone and converted automatically. Runs may start a few minutes after the scheduled time due to per-routine stagger (the offset is consistent). For custom intervals, set a cron expression via `/schedule update` in the CLI after creating the routine. The minimum interval is one hour; sub-hourly expressions are rejected.

### API

Gives the routine a dedicated HTTP endpoint. POSTing to it with the routine's bearer token starts a new session and returns the session URL. The endpoint is useful for wiring Claude Code into alerting systems, deploy pipelines, or any tool that can make an authenticated HTTP request.

The endpoint path follows the pattern `/v1/claude_code/routines/<trigger-id>/fire`. Calls must include:

- `Authorization: Bearer <token>` — the per-routine token generated in the web UI (shown once; store securely)
- `anthropic-beta: experimental-cc-routine-2026-04-01` — required beta header while the feature is in research preview
- `anthropic-version: 2023-06-01`

An optional `text` field in the JSON body passes run-specific context (alert body, log excerpt, etc.) to Claude alongside the saved prompt. The value is freeform text; structured payloads like JSON are received as a literal string. A successful response returns `routine_fire` type with a session ID and URL.

The beta header signals research-preview status. Breaking changes ship under new dated header versions; the two most recent previous versions remain valid during a migration window.

### GitHub Event

Starts a new session automatically when a matching event occurs on a connected repository. Each matching event starts its own independent session — session reuse across events is not supported. Supported events are pull request actions (opened, closed, assigned, labeled, synchronized, etc.) and release actions (created, published, edited, deleted).

Pull request triggers support fine-grained filters: author, title, body, base branch, head branch, labels, draft state, and merged state. All conditions must match. Filter operators include equals, contains, starts with, is one of, is not one of, and matches regex. The regex operator matches the entire field value; to match a substring, wrap the pattern with `.*` (e.g., `.*hotfix.*`), or use `contains` for literal substring matching.

GitHub triggers require the Claude GitHub App to be installed on the target repository. During research preview, per-routine and per-account hourly caps apply; events beyond the limit are dropped until the window resets.

## Example Use Cases

| Scenario | Trigger | What the routine does |
| :--- | :--- | :--- |
| Backlog maintenance | Schedule (nightly) | Labels and assigns issues, posts daily summary to Slack |
| Alert triage | API (monitoring tool fires on threshold) | Correlates stack trace with recent commits, opens draft fix PR |
| Bespoke code review | GitHub (`pull_request.opened`) | Applies team checklist, leaves inline comments |
| Deploy verification | API (CD pipeline post-deploy) | Runs smoke checks, posts go/no-go to release channel |
| Docs drift detection | Schedule (weekly) | Flags docs referencing changed APIs, opens update PRs |
| Library port | GitHub (`pull_request.closed`, merged PRs) | Ports change to parallel SDK, opens matching PR |

## Creating a Routine

Routines can be created from the web UI, the CLI (`/schedule`), or the Desktop app. All three surfaces write to the same cloud account.

**Web UI** — visit `claude.ai/code/routines`, click **New routine**, and fill in name, prompt, repositories, environment, connectors, and triggers. The prompt must be self-contained and explicit about success criteria since the session runs without human oversight.

**CLI** — run `/schedule` (optionally with a description, e.g., `/schedule daily PR review at 9am`). The CLI creates scheduled routines only; API and GitHub triggers must be added via the web UI afterward. Manage existing routines with `/schedule list`, `/schedule update`, and `/schedule run`.

**Desktop app** — open the Schedule page, click **New task**, and choose **New remote task**. Choosing **New local task** creates a Desktop scheduled task instead, which runs locally and is not a routine.

## Repositories and Branch Permissions

Each selected repository is cloned fresh on every run starting from the default branch. By default Claude can only push to branches prefixed with `claude/`, preventing accidental modification of protected branches. To lift this restriction for a specific repository, enable **Allow unrestricted branch pushes** when creating or editing the routine.

## Connectors

MCP connectors give routines access to external services (Slack, Linear, Google Drive, etc.) during each run. All of the account's currently connected connectors are included by default when creating a routine. Remove those that are not needed to limit Claude's reach. Connectors can also be managed at **Settings > Connectors** or via `/schedule update`.

## Environments

Each routine runs in a cloud environment that controls network access level, environment variables (API keys, secrets), and a setup script for installing dependencies. The setup script result is cached so it does not re-run on every session. A **Default** environment is provided; custom environments can be created before creating the routine.

## Usage and Daily Cap

Routines draw down subscription usage identically to interactive sessions. A separate daily cap limits how many routine runs can start per account. Current consumption and remaining runs are visible at `claude.ai/code/routines` or `claude.ai/settings/usage`. When the daily cap or subscription limit is hit, accounts with extra usage enabled continue on metered overage; others have runs rejected until the window resets.

## Research Preview Disclaimer

Routines are in research preview. Behavior, limits, and the API surface (including the `/fire` endpoint and beta header) may change. The beta header versioning scheme provides a migration window when breaking changes ship.

## See Also

- [Claude Code Overview](overview.md)
- [Scheduled Tasks](scheduled-tasks.md)
- [Running Autonomously](running-autonomously.md)
- [Desktop](desktop.md)

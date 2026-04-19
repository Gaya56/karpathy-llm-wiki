# Settings and Configuration

> Sources: Anthropic, Unknown
> Raw: [settings-json](../../raw/claude-code/settings-json.md)

## Overview

Claude Code's configuration system is built around `settings.json` files organized into four scopes: Managed (org-wide, highest precedence), Local (personal project override), Project (team-shared via git), and User (personal global, lowest precedence). The `/config` command opens a tabbed Settings UI for interactive configuration; direct file editing gives full control. A JSON schema at `https://json.schemastore.org/claude-code-settings.json` enables autocomplete in VS Code and Cursor.

## Scopes

Four scopes determine where a setting applies and who sees it:

| Scope | File location | Shared with team? |
| :---- | :------------ | :---------------- |
| Managed | `managed-settings.json` or MDM/server delivery | Yes (enforced by IT) |
| Local | `.claude/settings.local.json` | No (gitignored) |
| Project | `.claude/settings.json` | Yes (committed to git) |
| User | `~/.claude/settings.json` | No |

Precedence from highest to lowest: Managed > Command-line arguments > Local > Project > User. A deny rule in Project beats an allow rule in User. Managed settings cannot be overridden by anything.

**Array settings merge across scopes** — they are concatenated and deduplicated rather than replaced. This means `permissions.allow`, `sandbox.filesystem.allowWrite`, and similar arrays accumulate entries from all active scopes.

Within the Managed tier itself, precedence is: server-managed > MDM/OS-level policies > file-based (`managed-settings.d/*.json` merged with `managed-settings.json`) > HKCU registry (Windows only). Only one managed source is used at a time; sources do not cross-merge between tiers.

## Settings files

- `~/.claude/settings.json` — User scope. Personal preferences, cross-project API keys, personal tools.
- `.claude/settings.json` — Project scope. Commit to git for team-shared hooks, permissions, MCP servers, plugins.
- `.claude/settings.local.json` — Local scope. Gitignored automatically. Machine-specific or experimental settings.
- `managed-settings.json` — Managed scope. Deployed to `/Library/Application Support/ClaudeCode/` (macOS), `/etc/claude-code/` (Linux/WSL), or `C:\Program Files\ClaudeCode\` (Windows). Supports a drop-in `managed-settings.d/` directory for independent policy fragments — files are sorted alphabetically and merged on top of the base file.
- `~/.claude.json` — Stores preferences (theme, editor mode), OAuth session, MCP server configurations, per-project trust state. Global config settings (like `editorMode`, `autoConnectIde`) live here, not in `settings.json`.

Use `/status` inside Claude Code to see which settings sources are active and diagnose configuration errors.

## Permissions

Permission rules control which tool calls Claude can make without prompting. Rules nest under `permissions` in `settings.json`.

```json
{
  "permissions": {
    "allow": ["Bash(npm run lint)", "Bash(npm run test *)", "Read(~/.zshrc)"],
    "deny": ["Bash(curl *)", "Read(./.env)", "Read(./secrets/**)", "WebFetch"],
    "ask": ["Bash(git push *)"],
    "additionalDirectories": ["../docs/"],
    "defaultMode": "acceptEdits"
  }
}
```

**Rule evaluation order**: deny rules first, then ask, then allow. The first matching rule wins.

**Rule syntax**: `Tool` or `Tool(specifier)`. Common patterns:

| Rule | Effect |
| :--- | :----- |
| `Bash` | Matches all Bash commands |
| `Bash(npm run *)` | Commands starting with `npm run` |
| `Read(./.env)` | Reading the `.env` file |
| `WebFetch(domain:example.com)` | Fetch requests to example.com |

**Permission mode** (`defaultMode`): controls the base behavior before rules are evaluated. Options: `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`. The `--permission-mode` CLI flag overrides for a single session.

**Managed-only settings**:
- `allowManagedPermissionRulesOnly: true` — blocks user and project scopes from defining any allow/ask/deny rules.
- `disableBypassPermissionsMode: "disable"` — prevents bypassPermissions mode entirely, including `--dangerously-skip-permissions`.
- `disableAutoMode: "disable"` — removes auto from the Shift+Tab cycle.

To exclude sensitive files from all access:
```json
{
  "permissions": {
    "deny": ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)", "Read(./config/credentials.json)"]
  }
}
```

## Environment variables

The `env` key injects environment variables into every session:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  }
}
```

This is the settings-file equivalent of setting variables in your shell profile, but scoped to Claude Code sessions only.

## Hooks in settings

The `hooks` key configures lifecycle hook handlers (see [Hooks Reference](hooks.md) for the full event vocabulary and handler schema). Two additional settings control hook security:

- `allowedHttpHookUrls` — allowlist of URL patterns that HTTP hooks may target. Supports `*` wildcard. Undefined means no restriction; empty array blocks all HTTP hooks.
- `httpHookAllowedEnvVars` — allowlist of env var names HTTP hooks may interpolate into headers. Each hook's effective `allowedEnvVars` is the intersection with this list.
- `allowManagedHooksOnly` — (Managed only) blocks user, project, and non-force-enabled plugin hooks. Only managed hooks, SDK hooks, and hooks from plugins listed in `enabledPlugins` (managed settings) are loaded.
- `disableAllHooks: true` — disables all hooks and any custom status line.

## Sandbox settings

Sandboxing isolates bash commands from the filesystem and network. Nested under `sandbox` in `settings.json`.

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker *"],
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "allowUnixSockets": ["/var/run/docker.sock"],
      "allowLocalBinding": true
    }
  }
}
```

Sandbox filesystem settings use standard path conventions: `/` = absolute, `~/` = home-relative, `./` or no prefix = project-root-relative (project settings) or `~/.claude`-relative (user settings). Arrays merge across all scopes.

Key sandbox options:
- `enabled` — off by default. Works on macOS, Linux, WSL2.
- `failIfUnavailable` — exit at startup if sandbox cannot start. For managed deployments requiring sandboxing as a hard gate.
- `excludedCommands` — commands that run outside the sandbox (e.g., `docker *`).
- `allowUnsandboxedCommands: false` — completely disables the `dangerouslyDisableSandbox` escape hatch.
- `filesystem.allowManagedReadPathsOnly` — (Managed only) only managed-settings `allowRead` paths are respected.
- `network.allowManagedDomainsOnly` — (Managed only) only managed-settings `allowedDomains` and WebFetch allow rules are respected.

## Model settings

| Key | Description |
| :-- | :---------- |
| `model` | Override the default model (e.g., `"claude-sonnet-4-6"`) |
| `availableModels` | Restrict which models users can select via `/model`, `--model`, etc. Does not affect the Default option |
| `modelOverrides` | Map Anthropic model IDs to provider-specific IDs (e.g., Bedrock inference profile ARNs) |
| `effortLevel` | Persist effort level across sessions: `"low"`, `"medium"`, `"high"`, or `"xhigh"` |
| `alwaysThinkingEnabled` | Enable extended thinking by default for all sessions |

## Plugin settings

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "deployer@acme-tools": true,
    "analyzer@security-plugins": false
  },
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": { "source": "github", "repo": "acme-corp/claude-plugins" }
    }
  }
}
```

`enabledPlugins` format: `"plugin-name@marketplace-name": true/false`. Applies at User, Project, Local, and Managed scopes. Managed settings can block a plugin at all scopes.

`extraKnownMarketplaces` defines additional marketplace sources in repository settings. When a team member trusts the repo, they're prompted to install the marketplace and then the plugins from it.

Managed-only plugin controls:
- `strictKnownMarketplaces` — allowlist of marketplaces users can add. Empty array = lockdown.
- `blockedMarketplaces` — denylist of marketplace sources. Blocked before any network/filesystem operations.
- `allowedChannelPlugins` — allowlist of channel plugins that may push messages.

## Attribution settings

Controls git commit and pull request attribution via the `attribution` key:

```json
{
  "attribution": {
    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>",
    "pr": ""
  }
}
```

Empty string hides attribution. `attribution` takes precedence over the deprecated `includeCoAuthoredBy` setting.

## Other notable settings

| Key | Description |
| :-- | :---------- |
| `apiKeyHelper` | Custom script to generate an auth value (run in `/bin/sh`), sent as `X-Api-Key` and `Authorization: Bearer` |
| `autoUpdatesChannel` | `"stable"` (one week old, skips regressions) or `"latest"` (default, most recent) |
| `minimumVersion` | Prevents auto-updates from installing below this version. Useful for org-wide pinning |
| `cleanupPeriodDays` | Session files older than N days are deleted at startup (default: 30, minimum: 1) |
| `companyAnnouncements` | Array of strings displayed at startup; multiple entries cycle at random |
| `language` | Claude's preferred response language (e.g., `"japanese"`) |
| `includeGitInstructions` | Include built-in git commit/PR workflow instructions in system prompt (default: `true`). Set to `false` when using custom git skills |
| `autoMemoryDirectory` | Custom directory for auto memory storage. Not accepted in project settings |
| `worktree.symlinkDirectories` | Symlink these dirs from main repo into each worktree (e.g., `["node_modules"]`) |
| `worktree.sparsePaths` | Check out only these paths in each worktree via sparse-checkout |
| `fileSuggestion` | Custom command for `@` file autocomplete, receives `{"query": "..."}` via stdin |
| `statusLine` | Custom status line script. See statusline documentation |
| `tui` | Terminal UI renderer: `"fullscreen"` (alt-screen, flicker-free) or `"default"` |
| `plansDirectory` | Where plan files are stored. Relative to project root. Default: `~/.claude/plans` |
| `forceLoginMethod` | Restrict login to `claudeai` accounts or `console` (API billing) accounts |
| `forceLoginOrgUUID` | Require login to belong to a specific org UUID or list of UUIDs |
| `forceRemoteSettingsRefresh` | (Managed only) Block CLI startup until remote settings are freshly fetched. Fail-closed enforcement |

## See Also

- [Hooks Reference](hooks.md)
- [Memory and Persistent Instructions](memory.md)
- [Custom Subagents](subagents.md)
- [Running Claude Code Autonomously](running-autonomously.md) — `permissions.allow` rule syntax and `bypassPermissions` in autonomous scripted runs

# Claude Code settings

> Source: https://code.claude.com/docs/en/settings
> Collected: 2026-04-16
> Published: Unknown

Configure Claude Code with global and project-level settings, and environment variables.

Claude Code offers a variety of settings to configure its behavior to meet your needs. You can configure Claude Code by running the `/config` command when using the interactive REPL, which opens a tabbed Settings interface where you can view status information and modify configuration options.

## Configuration scopes

Claude Code uses a **scope system** to determine where configurations apply and who they're shared with. Understanding scopes helps you decide how to configure Claude Code for personal use, team collaboration, or enterprise deployment.

### Available scopes

| Scope       | Location                                                                           | Who it affects                       | Shared with team?      |
| :---------- | :--------------------------------------------------------------------------------- | :----------------------------------- | :--------------------- |
| **Managed** | Server-managed settings, plist / registry, or system-level `managed-settings.json` | All users on the machine             | Yes (deployed by IT)   |
| **User**    | `~/.claude/` directory                                                             | You, across all projects             | No                     |
| **Project** | `.claude/` in repository                                                           | All collaborators on this repository | Yes (committed to git) |
| **Local**   | `.claude/settings.local.json`                                                      | You, in this repository only         | No (gitignored)        |

### When to use each scope

**Managed scope** is for: security policies that must be enforced organization-wide, compliance requirements that can't be overridden, standardized configurations deployed by IT/DevOps.

**User scope** is best for: personal preferences you want everywhere (themes, editor settings), tools and plugins you use across all projects, API keys and authentication (stored securely).

**Project scope** is best for: team-shared settings (permissions, hooks, MCP servers), plugins the whole team should have, standardizing tooling across collaborators.

**Local scope** is best for: personal overrides for a specific project, testing configurations before sharing with the team, machine-specific settings that won't work for others.

### How scopes interact

When the same setting is configured in multiple scopes, more specific scopes take precedence:

1. **Managed** (highest) - can't be overridden by anything
2. **Command line arguments** - temporary session overrides
3. **Local** - overrides project and user settings
4. **Project** - overrides user settings
5. **User** (lowest) - applies when nothing else specifies the setting

For permissions: if a permission is allowed in user settings but denied in project settings, the project setting takes precedence and the permission is blocked.

### What uses scopes

| Feature         | User location             | Project location                   | Local location                 |
| :-------------- | :------------------------ | :--------------------------------- | :----------------------------- |
| **Settings**    | `~/.claude/settings.json` | `.claude/settings.json`            | `.claude/settings.local.json`  |
| **Subagents**   | `~/.claude/agents/`       | `.claude/agents/`                  | None                           |
| **MCP servers** | `~/.claude.json`          | `.mcp.json`                        | `~/.claude.json` (per-project) |
| **Plugins**     | `~/.claude/settings.json` | `.claude/settings.json`            | `.claude/settings.local.json`  |
| **CLAUDE.md**   | `~/.claude/CLAUDE.md`     | `CLAUDE.md` or `.claude/CLAUDE.md` | `CLAUDE.local.md`              |

---

## Settings files

The `settings.json` file is the official mechanism for configuring Claude Code through hierarchical settings:

* **User settings** are defined in `~/.claude/settings.json` and apply to all projects.
* **Project settings** are saved in your project directory:
  * `.claude/settings.json` for settings that are checked into source control and shared with your team
  * `.claude/settings.local.json` for settings that are not checked in, useful for personal preferences and experimentation.
* **Managed settings**: For organizations that need centralized control. All use the same JSON format and cannot be overridden by user or project settings:
  * **Server-managed settings**: delivered from Anthropic's servers via the Claude.ai admin console.
  * **MDM/OS-level policies**: delivered through native device management on macOS and Windows:
    * macOS: `com.anthropic.claudecode` managed preferences domain (Jamf, Kandji, or other MDM)
    * Windows: `HKLM\SOFTWARE\Policies\ClaudeCode` registry key with a `Settings` value containing JSON (Group Policy or Intune)
    * Windows (user-level): `HKCU\SOFTWARE\Policies\ClaudeCode` (lowest policy priority)
  * **File-based**: `managed-settings.json` and `managed-mcp.json` deployed to:
    * macOS: `/Library/Application Support/ClaudeCode/`
    * Linux and WSL: `/etc/claude-code/`
    * Windows: `C:\Program Files\ClaudeCode\`

File-based managed settings also support a drop-in directory at `managed-settings.d/` in the same system directory. `managed-settings.json` is merged first as the base, then all `*.json` files in the drop-in directory are sorted alphabetically and merged on top. Arrays are concatenated and de-duplicated; objects are deep-merged.

Other configuration is stored in `~/.claude.json`. This file contains preferences (theme, notification settings, editor mode), OAuth session, MCP server configurations for user and local scopes, per-project state (allowed tools, trust settings), and various caches. Project-scoped MCP servers are stored separately in `.mcp.json`.

Claude Code automatically creates timestamped backups of configuration files and retains the five most recent backups.

Example settings.json:
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  },
  "companyAnnouncements": [
    "Welcome to Acme Corp! Review our code guidelines at docs.acme.com"
  ]
}
```

The `$schema` line points to the official JSON schema for Claude Code settings. Adding it enables autocomplete and inline validation in VS Code, Cursor, and other editors that support JSON schema validation.

## Available settings

`settings.json` supports a number of options:

| Key | Description | Example |
| :-- | :---------- | :------ |
| `agent` | Run the main thread as a named subagent | `"code-reviewer"` |
| `allowedChannelPlugins` | (Managed only) Allowlist of channel plugins. Replaces default Anthropic allowlist when set | `[{ "marketplace": "claude-plugins-official", "plugin": "telegram" }]` |
| `allowedHttpHookUrls` | Allowlist of URL patterns that HTTP hooks may target. Supports `*` wildcard | `["https://hooks.example.com/*"]` |
| `allowedMcpServers` | (Managed) Allowlist of MCP servers users can configure. Undefined = no restrictions, empty array = lockdown | `[{ "serverName": "github" }]` |
| `allowManagedHooksOnly` | (Managed only) Only managed hooks, SDK hooks, and hooks from force-enabled plugins are loaded | `true` |
| `allowManagedMcpServersOnly` | (Managed only) Only allowedMcpServers from managed settings are respected | `true` |
| `allowManagedPermissionRulesOnly` | (Managed only) Prevent user/project from defining allow/ask/deny permission rules | `true` |
| `alwaysThinkingEnabled` | Enable extended thinking by default for all sessions | `true` |
| `apiKeyHelper` | Custom script to generate auth value, sent as X-Api-Key and Authorization: Bearer headers | `/bin/generate_temp_api_key.sh` |
| `attribution` | Customize attribution for git commits and pull requests | `{"commit": "Generated with AI", "pr": ""}` |
| `autoMemoryDirectory` | Custom directory for auto memory storage. Not accepted in project settings | `"~/my-memory-dir"` |
| `autoMode` | Customize what the auto mode classifier blocks and allows | `{"environment": ["Trusted repo: github.example.com/acme"]}` |
| `autoUpdatesChannel` | Release channel: `"stable"` (one week old, skips regressions) or `"latest"` (most recent) | `"stable"` |
| `availableModels` | Restrict which models users can select via `/model`, `--model`, Config tool, or `ANTHROPIC_MODEL` | `["sonnet", "haiku"]` |
| `awaySummaryEnabled` | Show a one-line session recap when returning after being away | `true` |
| `awsAuthRefresh` | Custom script that modifies the `.aws` directory | `aws sso login --profile myprofile` |
| `awsCredentialExport` | Custom script that outputs JSON with AWS credentials | `/bin/generate_aws_grant.sh` |
| `blockedMarketplaces` | (Managed only) Blocklist of marketplace sources | `[{ "source": "github", "repo": "untrusted/plugins" }]` |
| `channelsEnabled` | (Managed only) Allow channels for Team and Enterprise users | `true` |
| `cleanupPeriodDays` | Session files older than this period are deleted at startup (default: 30, minimum: 1) | `20` |
| `companyAnnouncements` | Announcement to display to users at startup. Multiple entries cycle at random | `["Welcome to Acme Corp!"]` |
| `defaultShell` | Default shell for input-box `!` commands. `"bash"` (default) or `"powershell"` | `"powershell"` |
| `deniedMcpServers` | (Managed) Denylist of MCP servers that are explicitly blocked. Takes precedence over allowlist | `[{ "serverName": "filesystem" }]` |
| `disableAllHooks` | Disable all hooks and any custom status line | `true` |
| `disableAutoMode` | Set to `"disable"` to prevent auto mode from being activated | `"disable"` |
| `disableDeepLinkRegistration` | Set to `"disable"` to prevent registering the `claude-cli://` protocol handler | `"disable"` |
| `disabledMcpjsonServers` | List of specific MCP servers from `.mcp.json` files to reject | `["filesystem"]` |
| `disableSkillShellExecution` | Disable inline shell execution for skill blocks from user/project/plugin sources | `true` |
| `effortLevel` | Persist the effort level across sessions: `"low"`, `"medium"`, `"high"`, or `"xhigh"` | `"xhigh"` |
| `enableAllProjectMcpServers` | Automatically approve all MCP servers defined in project `.mcp.json` files | `true` |
| `enabledMcpjsonServers` | List of specific MCP servers from `.mcp.json` files to approve | `["memory", "github"]` |
| `env` | Environment variables that will be applied to every session | `{"FOO": "bar"}` |
| `fastModePerSessionOptIn` | When `true`, fast mode does not persist across sessions | `true` |
| `feedbackSurveyRate` | Probability (0–1) that the session quality survey appears when eligible. Set to `0` to suppress | `0.05` |
| `fileSuggestion` | Configure a custom script for `@` file autocomplete | `{"type": "command", "command": "~/.claude/file-suggestion.sh"}` |
| `forceLoginMethod` | Use `claudeai` to restrict login to Claude.ai accounts, `console` to restrict to API billing | `claudeai` |
| `forceLoginOrgUUID` | Require login to belong to a specific organization (single UUID or array) | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"` |
| `forceRemoteSettingsRefresh` | (Managed only) Block CLI startup until remote managed settings are freshly fetched | `true` |
| `hooks` | Configure custom commands to run at lifecycle events | See hooks documentation |
| `httpHookAllowedEnvVars` | Allowlist of environment variable names HTTP hooks may interpolate into headers | `["MY_TOKEN", "HOOK_SECRET"]` |
| `includeCoAuthoredBy` | **Deprecated**: Use `attribution` instead. Whether to include co-authored-by byline | `false` |
| `includeGitInstructions` | Include built-in commit/PR workflow instructions in system prompt (default: `true`) | `false` |
| `language` | Configure Claude's preferred response language | `"japanese"` |
| `minimumVersion` | Floor that prevents auto-updates from installing a version below this one | `"2.1.100"` |
| `model` | Override the default model to use for Claude Code | `"claude-sonnet-4-6"` |
| `modelOverrides` | Map Anthropic model IDs to provider-specific model IDs (e.g., Bedrock ARNs) | `{"claude-opus-4-6": "arn:aws:bedrock:..."}` |
| `otelHeadersHelper` | Script to generate dynamic OpenTelemetry headers. Runs at startup and periodically | `/bin/generate_otel_headers.sh` |
| `outputStyle` | Configure an output style to adjust the system prompt | `"Explanatory"` |
| `permissions` | Permission allow/deny/ask rules. See permission settings section | |
| `plansDirectory` | Customize where plan files are stored. Relative to project root. Default: `~/.claude/plans` | `"./plans"` |
| `pluginTrustMessage` | (Managed only) Custom message appended to the plugin trust warning | `"All plugins from our marketplace are approved by IT"` |
| `prefersReducedMotion` | Reduce or disable UI animations for accessibility | `true` |
| `respectGitignore` | Whether the `@` file picker respects `.gitignore` patterns (default: `true`) | `false` |
| `showThinkingSummaries` | Show extended thinking summaries in interactive sessions | `true` |
| `spinnerTipsEnabled` | Show tips in the spinner while Claude is working (default: `true`) | `false` |
| `spinnerTipsOverride` | Override spinner tips with custom strings | `{ "excludeDefault": true, "tips": ["Use our internal tool X"] }` |
| `spinnerVerbs` | Customize the action verbs shown in the spinner | `{"mode": "append", "verbs": ["Pondering", "Crafting"]}` |
| `statusLine` | Configure a custom status line to display context | `{"type": "command", "command": "~/.claude/statusline.sh"}` |
| `strictKnownMarketplaces` | (Managed only) Allowlist of plugin marketplaces users can add | `[{ "source": "github", "repo": "acme-corp/plugins" }]` |
| `tui` | Terminal UI renderer: `"fullscreen"` for alt-screen or `"default"` for classic | `"fullscreen"` |
| `useAutoModeDuringPlan` | Whether plan mode uses auto mode semantics (default: `true`). Not from shared project settings | `false` |
| `viewMode` | Default transcript view mode on startup: `"default"`, `"verbose"`, or `"focus"` | `"verbose"` |
| `voiceEnabled` | Enable push-to-talk voice dictation. Requires a Claude.ai account | `true` |

## Global config settings

These settings are stored in `~/.claude.json` rather than `settings.json`. Adding them to `settings.json` will trigger a schema validation error.

| Key | Description | Example |
| :-- | :---------- | :------ |
| `autoConnectIde` | Automatically connect to a running IDE when Claude Code starts from an external terminal (default: `false`) | `true` |
| `autoInstallIdeExtension` | Automatically install the Claude Code IDE extension when running from VS Code terminal (default: `true`) | `false` |
| `autoScrollEnabled` | In fullscreen rendering, follow new output to bottom (default: `true`) | `false` |
| `editorMode` | Key binding mode for input prompt: `"normal"` or `"vim"` (default: `"normal"`) | `"vim"` |
| `externalEditorContext` | Prepend Claude's previous response as context when opening external editor with Ctrl+G (default: `false`) | `true` |
| `showTurnDuration` | Show turn duration messages after responses (default: `true`) | `false` |
| `terminalProgressBarEnabled` | Show the terminal progress bar in supported terminals (default: `true`) | `false` |
| `teammateMode` | How agent team teammates display: `auto`, `in-process`, or `tmux` | `"in-process"` |

## Worktree settings

Configure how `--worktree` creates and manages git worktrees. Use to reduce disk usage and startup time in large monorepos.

| Key | Description | Example |
| :-- | :---------- | :------ |
| `worktree.symlinkDirectories` | Directories to symlink from main repo into each worktree to avoid duplicating large dirs | `["node_modules", ".cache"]` |
| `worktree.sparsePaths` | Directories to check out in each worktree via git sparse-checkout (cone mode) | `["packages/my-app", "shared/utils"]` |

## Permission settings

Nested under `permissions` in `settings.json`:

| Keys | Description | Example |
| :--- | :---------- | :------ |
| `allow` | Array of permission rules to allow tool use | `[ "Bash(git diff *)" ]` |
| `ask` | Array of permission rules to ask for confirmation upon tool use | `[ "Bash(git push *)" ]` |
| `deny` | Array of permission rules to deny tool use | `[ "WebFetch", "Bash(curl *)", "Read(./.env)" ]` |
| `additionalDirectories` | Additional working directories for file access | `[ "../docs/" ]` |
| `defaultMode` | Default permission mode: `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` | `"acceptEdits"` |
| `disableBypassPermissionsMode` | Set to `"disable"` to prevent bypassPermissions mode | `"disable"` |
| `skipDangerousModePermissionPrompt` | Skip confirmation before entering bypass permissions mode. Ignored in project settings | `true` |

### Permission rule syntax

Permission rules follow the format `Tool` or `Tool(specifier)`. Rules are evaluated in order: deny rules first, then ask, then allow. The first matching rule wins.

| Rule | Effect |
| :--- | :----- |
| `Bash` | Matches all Bash commands |
| `Bash(npm run *)` | Matches commands starting with `npm run` |
| `Read(./.env)` | Matches reading the `.env` file |
| `WebFetch(domain:example.com)` | Matches fetch requests to example.com |

## Sandbox settings

Configure advanced sandboxing behavior. Nested under `sandbox` in `settings.json`. Sandboxing isolates bash commands from your filesystem and network.

| Key | Description | Example |
| :-- | :---------- | :------ |
| `enabled` | Enable bash sandboxing (macOS, Linux, WSL2). Default: false | `true` |
| `failIfUnavailable` | Exit with error at startup if sandbox cannot start. Intended for managed deployments | `true` |
| `autoAllowBashIfSandboxed` | Auto-approve bash commands when sandboxed. Default: true | `true` |
| `excludedCommands` | Commands that should run outside of the sandbox | `["docker *"]` |
| `allowUnsandboxedCommands` | Allow commands to run outside sandbox via dangerouslyDisableSandbox parameter. Default: true | `false` |
| `filesystem.allowWrite` | Additional paths where sandboxed commands can write. Merges across all settings scopes | `["/tmp/build", "~/.kube"]` |
| `filesystem.denyWrite` | Paths where sandboxed commands cannot write. Merges across all settings scopes | `["/etc", "/usr/local/bin"]` |
| `filesystem.denyRead` | Paths where sandboxed commands cannot read. Merges across all settings scopes | `["~/.aws/credentials"]` |
| `filesystem.allowRead` | Paths to re-allow reading within denyRead regions. Takes precedence over denyRead | `["."]` |
| `filesystem.allowManagedReadPathsOnly` | (Managed only) Only filesystem.allowRead paths from managed settings are respected | `true` |
| `network.allowUnixSockets` | (macOS only) Unix socket paths accessible in sandbox | `["~/.ssh/agent-socket"]` |
| `network.allowAllUnixSockets` | Allow all Unix socket connections in sandbox | `true` |
| `network.allowLocalBinding` | Allow binding to localhost ports (macOS only). Default: false | `true` |
| `network.allowMachLookup` | Additional XPC/Mach service names the sandbox may look up (macOS only) | `["com.apple.coresimulator.*"]` |
| `network.allowedDomains` | Array of domains to allow for outbound network traffic. Supports wildcards | `["github.com", "*.npmjs.org"]` |
| `network.allowManagedDomainsOnly` | (Managed only) Only allowedDomains from managed settings are respected | `true` |
| `network.httpProxyPort` | HTTP proxy port for your own proxy | `8080` |
| `network.socksProxyPort` | SOCKS5 proxy port for your own proxy | `8081` |
| `enableWeakerNestedSandbox` | Enable weaker sandbox for unprivileged Docker environments (Linux/WSL2 only). Reduces security | `true` |
| `enableWeakerNetworkIsolation` | (macOS only) Allow access to the system TLS trust service in sandbox. Reduces security | `true` |

### Sandbox path prefixes

Paths in sandbox filesystem settings support these prefixes:

| Prefix | Meaning | Example |
| :----- | :------ | :------ |
| `/` | Absolute path from filesystem root | `/tmp/build` stays `/tmp/build` |
| `~/` | Relative to home directory | `~/.kube` becomes `$HOME/.kube` |
| `./` or no prefix | Relative to project root (project settings) or to `~/.claude` (user settings) | `./output` resolves to `<project-root>/output` |

## Attribution settings

Claude Code adds attribution to git commits and pull requests, configured via the `attribution` key:

| Keys | Description |
| :--- | :---------- |
| `commit` | Attribution for git commits, including any trailers. Empty string hides commit attribution |
| `pr` | Attribution for pull request descriptions. Empty string hides pull request attribution |

Default commit attribution:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Hook configuration in settings

The `allowedHttpHookUrls` and `httpHookAllowedEnvVars` settings control which hooks are allowed to run:

```json
{
  "allowedHttpHookUrls": ["https://hooks.example.com/*", "http://localhost:*"],
  "httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
}
```

When `allowManagedHooksOnly` is `true` (managed settings only): managed hooks and SDK hooks are loaded; hooks from plugins force-enabled in managed settings `enabledPlugins` are loaded; user hooks, project hooks, and all other plugin hooks are blocked.

## Plugin configuration

Plugin-related settings in `settings.json`:

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "deployer@acme-tools": true,
    "analyzer@security-plugins": false
  },
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/claude-plugins"
      }
    }
  }
}
```

`enabledPlugins` format: `"plugin-name@marketplace-name": true/false`

`extraKnownMarketplaces` defines additional marketplaces. When a repository includes this, team members are prompted to install the marketplace when they trust the folder, then prompted to install plugins from that marketplace.

Marketplace source types: `github` (uses `repo`), `git` (uses `url`), `directory` (uses `path`, dev only), `url` (uses `url`), `hostPattern` (regex against marketplace host), `settings` (inline, uses `name` and `plugins`).

## Settings precedence

From highest to lowest:

1. **Managed settings** (server-managed, MDM/OS-level policies, or managed settings files) — cannot be overridden. Within managed tier: server-managed > MDM/OS-level > file-based > HKCU registry. Only one managed source is used per tier.
2. **Command line arguments** — temporary session overrides
3. **Local project settings** (`.claude/settings.local.json`) — personal project-specific
4. **Shared project settings** (`.claude/settings.json`) — team-shared in source control
5. **User settings** (`~/.claude/settings.json`) — personal global settings

**Array settings merge across scopes.** When the same array-valued setting appears in multiple scopes, the arrays are concatenated and deduplicated, not replaced. For example: `sandbox.filesystem.allowWrite`, `permissions.allow`.

## Verify active settings

Run `/status` inside Claude Code to see which settings sources are active and where they come from. Reports each configuration layer (managed, user, project) along with its origin. If a settings file contains errors, `/status` reports the issue.

## Excluding sensitive files

Use `permissions.deny` to prevent access to sensitive files:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)"
    ]
  }
}
```

## Key points about the configuration system

* **Memory files (`CLAUDE.md`)**: Contain instructions and context that Claude loads at startup
* **Settings files (JSON)**: Configure permissions, environment variables, and tool behavior
* **Skills**: Custom prompts invoked with `/skill-name` or loaded by Claude automatically
* **MCP servers**: Extend Claude Code with additional tools and integrations
* **Precedence**: Higher-level configurations (Managed) override lower-level ones (User/Project)
* **Inheritance**: Settings are merged, with more specific settings adding to or overriding broader ones

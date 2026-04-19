# Claude Code Desktop

> Sources: Anthropic, 2026-04-19
> Raw: [2026-04-19-claude-code-desktop](../../raw/claude-code/2026-04-19-claude-code-desktop.md)
> Updated: 2026-04-19

## Overview

Claude Code Desktop is the graphical interface to Claude Code, available for macOS (Intel and Apple Silicon) and Windows (x64 and ARM64) — Linux is not supported. It runs the same underlying engine as the CLI but adds parallel sessions with automatic Git worktree isolation, a drag-and-drop pane workspace, integrated terminal, visual diff review with inline comments, live app preview, PR monitoring, computer use, Dispatch integration, and scheduled tasks. Desktop and CLI share configuration files (`CLAUDE.md`, `~/.claude.json`, MCP servers, hooks, skills) and can run simultaneously on the same project.

## Installation and first launch

Download from the Claude website, launch the app, sign in, and click the **Code** tab. A minimum version of v1.2581.0 is required for the full workspace layout, terminal, file editor, side chats, and view modes. Check for updates via **Claude → Check for Updates** (macOS) or **Help → Check for Updates** (Windows).

Before sending your first message, configure the session in the prompt area:

- **Environment**: Local (your machine), Remote (Anthropic cloud), or an SSH connection.
- **Project folder**: the working directory. Remote sessions can include multiple repositories.
- **Model**: select from the dropdown next to the send button; changeable mid-session.
- **Permission mode**: controls autonomy level; changeable mid-session.

## Permission modes

| Mode                   | Settings key        | Behavior                                                                                                                 |
| ---------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Ask permissions**    | `default`           | Prompts before every file edit or command. Shows a diff. Recommended for new users.                                     |
| **Auto accept edits**  | `acceptEdits`       | Auto-accepts file edits and common filesystem commands (`mkdir`, `touch`, `mv`); still prompts for other terminal commands. |
| **Plan mode**          | `plan`              | Explores and proposes a plan without touching source code. Switch to another mode to execute.                            |
| **Auto**               | `auto`              | Executes all actions with background safety checks. Research preview. Requires Max, Team, Enterprise, or API plan; Claude Sonnet 4.6, Opus 4.6, or Opus 4.7 (Opus 4.7 only on Max). Enable in Settings → Claude Code. |
| **Bypass permissions** | `bypassPermissions` | No permission prompts — equivalent to `--dangerously-skip-permissions`. Enable in Settings → Claude Code. Only use in sandboxed containers or VMs. |

The CLI-only `dontAsk` mode is not available in Desktop. Remote sessions support Auto accept edits and Plan mode only. Enterprise admins can restrict which modes are available and can disable Bypass permissions globally.

## Workspace layout

The workspace is built around draggable, resizable panes: chat, diff, preview, terminal, file, plan, tasks, and subagent. Drag a pane by its header to reposition it; drag a pane edge to resize it. Add panes from the **Views** menu in the session toolbar.

- **Terminal pane**: integrated terminal in your session's working directory, sharing the same environment as Claude. Local sessions only. Open with `Ctrl+\`` on macOS or Windows.
- **File pane**: click any file path in the chat or diff viewer to open it for spot-editing. HTML, PDF, and image paths open in the preview pane instead. Local and SSH sessions only.
- **Preview pane**: embedded browser for running dev servers, plus static HTML, PDF, and image viewing.
- **Tasks pane**: shows subagents, background shell commands, and workflows running in the current session.
- **Diff pane**: file-by-file view of all changes Claude made, with inline comment support.

### Keyboard shortcuts

Press **Cmd+/** (macOS) or **Ctrl+/** (Windows) to list all shortcuts. On Windows, substitute `Ctrl` for `Cmd` unless noted.

| Shortcut                              | Action                         |
| ------------------------------------- | ------------------------------ |
| `Cmd` `/`                             | Show keyboard shortcuts        |
| `Cmd` `N`                             | New session                    |
| `Cmd` `W`                             | Close session                  |
| `Ctrl` `Tab` / `Ctrl` `Shift` `Tab`   | Next or previous session       |
| `Cmd` `Shift` `]` / `Cmd` `Shift` `[` | Next or previous session       |
| `Esc`                                 | Stop Claude's response         |
| `Cmd` `Shift` `D`                     | Toggle diff pane               |
| `Cmd` `Shift` `P`                     | Toggle preview pane            |
| `Cmd` `Shift` `S`                     | Select an element in preview   |
| `Ctrl` `` ` ``                        | Toggle terminal pane           |
| `Cmd` `\`                             | Close focused pane             |
| `Cmd` `;`                             | Open side chat                 |
| `Ctrl` `O`                            | Cycle view modes               |
| `Cmd` `Shift` `M`                     | Open permission mode menu      |
| `Cmd` `Shift` `I`                     | Open model menu                |
| `Cmd` `Shift` `E`                     | Open effort menu               |
| `1`–`9`                               | Select item in an open menu    |

### View modes

Switch via the **Transcript view** dropdown or `Ctrl+O`:

| Mode        | What it shows                                                  |
| ----------- | -------------------------------------------------------------- |
| **Normal**  | Tool calls collapsed into summaries; full text responses       |
| **Verbose** | Every tool call, file read, and intermediate step              |
| **Summary** | Only Claude's final responses and changes made                 |

## Diff review and code review

When Claude changes files, a diff stats indicator (`+12 -1`) appears in the session. Click it to open the diff viewer. To leave inline comments, click any diff line — type feedback and press **Enter**. Submit all comments at once with **Cmd+Enter** (macOS) or **Ctrl+Enter** (Windows); Claude makes the requested changes and shows a new diff.

Click **Review code** in the diff viewer toolbar to have Claude evaluate changes before you commit. The review targets compile errors, definite logic errors, security vulnerabilities, and obvious bugs — not style, formatting, or pre-existing issues.

## Live app preview

Claude auto-detects your dev server and stores the configuration in `.claude/launch.json`. After editing project files, Claude typically starts the server automatically and opens the preview pane. From the preview pane you can interact with the running app, watch Claude take screenshots and fix issues it finds, persist cookies and local storage across restarts (**Persist sessions** in the Preview dropdown), and manage server configurations.

Auto-verify (`autoVerify` in `launch.json`, default on) triggers after every file edit: Claude takes screenshots, inspects the DOM, and fixes issues before completing its response. Disable per-project with `"autoVerify": false`.

Key `launch.json` fields:

| Field               | Description                                                                              |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `name`              | Unique server identifier                                                                 |
| `runtimeExecutable` | Command to run (`npm`, `yarn`, `node`)                                                   |
| `runtimeArgs`       | Arguments to the executable (`["run", "dev"]`)                                           |
| `port`              | Port to listen on (default 3000)                                                         |
| `cwd`               | Working directory relative to project root                                               |
| `env`               | Additional env vars (do not put secrets here — use the local environment editor instead) |
| `autoPort`          | `true` = find free port; `false` = fail if port taken; omit = ask once and remember      |
| `program`           | Standalone Node.js script to run directly with `node`                                    |

Multiple configurations can run a frontend and API server simultaneously.

## PR monitoring

After opening a pull request, a CI status bar appears in the session. Claude Code polls GitHub CLI for check results and can:

- **Auto-fix**: attempt to fix failing CI checks automatically by reading the failure output and iterating.
- **Auto-merge**: merge the PR once all checks pass (squash merge method). Requires auto-merge to be enabled in your GitHub repository settings.
- **Auto-archive**: archive the local session once the PR merges or closes. Enable in Settings → Claude Code.

Requires `gh` (GitHub CLI) installed and authenticated.

## Parallel sessions and Git worktrees

Each new session (`Cmd+N` / `Ctrl+N`) gets its own isolated Git worktree stored at `<project-root>/.claude/worktrees/` by default. Changes in one session don't affect others until committed. Cycle through sessions with `Ctrl+Tab` / `Ctrl+Shift+Tab`.

Configure in Settings → Claude Code:
- **Worktree location**: change the default storage directory.
- **Branch prefix**: prepend to every worktree branch name for organization.

To include gitignored files like `.env` in new worktrees, create a `.worktreeinclude` file in your project root. To remove a worktree, hover over the session in the sidebar and click the archive icon.

Git is required for session isolation. On Windows, Git is required for the Code tab to start at all — install [Git for Windows](https://git-scm.com/downloads/win) and restart the app.

## Side chats

A side chat lets you ask a question using the session's context without adding anything to the main thread. Open with **Cmd+;** / **Ctrl+;**, or type `/btw` in the prompt box. The side chat sees everything in the main thread up to that point. Close it and continue the main session where you left off. Available in local and SSH sessions only.

## Computer use

Computer use lets Claude open apps, control your screen, and interact with GUIs — useful for native apps, hardware control panels, mobile simulators, or proprietary tools without an API. Research preview on macOS and Windows; requires Pro or Max plan. Not available on Team or Enterprise plans.

Claude tries more precise tools first (connector → Bash → Claude in Chrome → computer use) before resorting to screen control. App access tiers are fixed by category:

| Tier         | What Claude can do                         | Applies to                  |
| :----------- | :----------------------------------------- | :-------------------------- |
| View only    | See the app in screenshots                 | Browsers, trading platforms |
| Click only   | Click and scroll; no typing or shortcuts   | Terminals, IDEs             |
| Full control | Click, type, drag, and use shortcuts       | Everything else             |

App approvals last the full session (30 minutes in Dispatch-spawned sessions). To enable: Settings → General → Computer use toggle. On macOS, also grant Accessibility and Screen Recording permissions.

## Scheduling surfaces

Desktop sits at one of three scheduling layers:

1. **Desktop scheduled tasks** — recurring local tasks, configured and run within the Desktop app. These run on your machine only and require Desktop to be open. See [scheduled-tasks.md](scheduled-tasks.md) for full syntax.
2. **Dispatch** — send a task from the Cowork tab (or from your phone via the Claude iOS app) and it spawns a Code session in the Desktop sidebar with a **Dispatch** badge. Push notification when the session finishes or needs approval. Pro or Max plan only; not available on Team or Enterprise.
3. **Cloud routines** — fully remote, serverless scheduled runs on Anthropic infrastructure. No Desktop required. See [cloud-routines.md](cloud-routines.md).

## Remote Control and --teleport

Claude Code's `claude remote-control` command starts a Remote Control server that allows external clients (web or iOS) to connect to and control a running CLI session. This is the bridge between mobile/web access and local terminal sessions.

The `--teleport` flag pulls an in-progress web or iOS session into your local terminal, handing off full context so you can continue the session at the keyboard. This is the inverse of using **Continue in → Claude Code on the Web** from Desktop, which pushes a local session to the cloud.

See [running-autonomously.md](running-autonomously.md) for the full Remote Control and teleport reference.

## Environments

### Local sessions

On macOS (launched from Dock or Finder), the app reads `~/.zshrc` / `~/.bashrc` to extract `PATH` and a fixed set of Claude Code variables — other exported variables are not picked up. On Windows, user and system environment variables are inherited but PowerShell profiles are not read. Use the local environment editor (environment dropdown → hover **Local** → gear icon) to set encrypted per-machine variables that apply to all local sessions and preview servers.

Extended thinking is enabled by default. Disable by setting `MAX_THINKING_TOKENS=0` in the local environment editor.

### Remote sessions

Runs on Anthropic infrastructure; continues when you close the app. Usage counts toward subscription plan limits, no separate compute charge. Supports multiple repositories per session. Monitor from claude.ai/code or the Claude iOS app.

### SSH sessions

Connect via: environment dropdown → **+ Add SSH connection**. Requires Name, SSH Host (`user@hostname` or SSH config entry), SSH Port (default 22), and optional Identity File path. The remote machine must run Linux or macOS with Claude Code installed. SSH sessions support permission modes, connectors, plugins, and MCP servers.

## Enterprise configuration

### Admin console (claude.ai/admin-settings/claude-code)

- Enable/disable Code in the desktop app and Code on the web.
- Enable/disable Remote Control for the organization.
- Disable Bypass permissions mode organization-wide.

### Managed settings

| Key                                        | Description                                                                                  |
| ------------------------------------------ | -------------------------------------------------------------------------------------------- |
| `permissions.disableBypassPermissionsMode` | `"disable"` prevents users from enabling Bypass permissions mode.                            |
| `disableAutoMode`                          | `"disable"` removes Auto from the mode selector.                                             |
| `autoMode`                                 | Customize the Auto mode classifier (not read from checked-in `.claude/settings.json`).       |

For the full managed-only settings list (`allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`), see the permissions reference.

### Device management

- **macOS**: MDM via `com.anthropic.Claude` preference domain (Jamf, Kandji).
- **Windows**: group policy via registry at `SOFTWARE\Policies\Claude`; deploy via MSIX or `.exe` installer.

## CLI comparison

Desktop and CLI run the same engine. Migrate a CLI session to Desktop with `/desktop` (macOS and Windows only). Both share `CLAUDE.md`, MCP servers (via `~/.claude.json` or `.mcp.json`), hooks, skills, and settings — but **not** `claude_desktop_config.json` MCP servers (those are for the Claude chat app, not Claude Code).

Key features only in the CLI: `dontAsk` mode, third-party providers (Bedrock, Foundry), Linux support, inline code suggestions, agent teams, scripting via `--print`, headless/Agent SDK.

Key features only in Desktop: parallel sessions UI, workspace panes, visual diff review, live preview, PR monitoring, Dispatch sessions, computer use on Windows, plugin manager UI, scheduled tasks UI.

## See Also

- [CLI Reference](cli-reference.md)
- [Scheduled Tasks](scheduled-tasks.md)
- [Cloud Routines](cloud-routines.md)
- [Running Autonomously](running-autonomously.md)
- [Claude Code Overview](overview.md)

# Use Claude Code Desktop

> Source: https://code.claude.com/docs/en/desktop
> Collected: 2026-04-19
> Published: Unknown

Get more out of Claude Code Desktop: parallel sessions with Git isolation, drag-and-drop pane layout, integrated terminal and file editor, side chats, computer use, Dispatch sessions from your phone, visual diff review, app previews, PR monitoring, connectors, and enterprise configuration.

The Code tab within the Claude Desktop app lets you use Claude Code through a graphical interface instead of the terminal.

**Downloads:**
- macOS: Universal build for Intel and Apple Silicon — https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect
- Windows (x64): https://claude.ai/api/desktop/win32/x64/setup/latest/redirect
- Windows ARM64: https://claude.ai/api/desktop/win32/arm64/setup/latest/redirect
- Linux: not supported.

After installing, launch Claude, sign in, and click the **Code** tab.

Desktop adds these capabilities on top of the standard Claude Code experience:

* Parallel sessions with automatic Git worktree isolation
* Drag-and-drop layout with an integrated terminal, file editor, and preview pane
* Side chats that branch off without affecting the main thread
* Visual diff review with inline comments
* Live app preview with dev servers, HTML files, and PDFs
* Computer use to open apps and control your screen on macOS and Windows
* GitHub PR monitoring with auto-fix, auto-merge, and auto-archive
* Dispatch integration: send a task from your phone, get a session here
* Scheduled tasks that run Claude on a recurring schedule
* Connectors for GitHub, Slack, Linear, and more
* Local, SSH, and cloud environments

Note: The workspace layout, terminal, file editor, side chats, and view modes require Claude Desktop v1.2581.0 or later.

## Start a session

Before you send your first message, configure four things in the prompt area:

* **Environment**: choose where Claude runs. Select **Local** for your machine, **Remote** for Anthropic-hosted cloud sessions, or an **SSH connection** for a remote machine you manage.
* **Project folder**: select the folder or repository Claude works in. For remote sessions, you can add multiple repositories.
* **Model**: pick a model from the dropdown next to the send button. You can change this during the session.
* **Permission mode**: choose how much autonomy Claude has from the mode selector. You can change this during the session.

Type your task and press **Enter** to start. Each session tracks its own context and changes independently.

## Work with code

### Use the prompt box

Type what you want Claude to do and press **Enter** to send. Claude reads your project files, makes changes, and runs commands based on your permission mode. You can interrupt Claude at any point: click the stop button or type your correction and press **Enter**.

The **+** button next to the prompt box gives you access to file attachments, skills, connectors, and plugins.

### Add files and context to prompts

* **@mention files**: type `@` followed by a filename to add a file to the conversation context. @mention is not available in remote sessions.
* **Attach files**: attach images, PDFs, and other files using the attachment button, or drag and drop files directly into the prompt.

### Choose a permission mode

Permission modes control how much autonomy Claude has during a session. You can switch modes at any time using the mode selector next to the send button.

| Mode                   | Settings key        | Behavior                                                                                                                                  |
| ---------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Ask permissions**    | `default`           | Claude asks before editing files or running commands. You see a diff and can accept or reject each change. Recommended for new users.    |
| **Auto accept edits**  | `acceptEdits`       | Claude auto-accepts file edits and common filesystem commands like `mkdir`, `touch`, and `mv`, but still asks before running other terminal commands. |
| **Plan mode**          | `plan`              | Claude reads files and runs commands to explore, then proposes a plan without editing your source code.                                  |
| **Auto**               | `auto`              | Claude executes all actions with background safety checks. Research preview. Available on Max, Team, Enterprise, and API plans. Requires Claude Sonnet 4.6, Opus 4.6, or Opus 4.7 on Team/Enterprise/API; Claude Opus 4.7 only on Max. Not available on Pro or third-party providers. Enable in Settings → Claude Code. |
| **Bypass permissions** | `bypassPermissions` | Claude runs without any permission prompts, equivalent to `--dangerously-skip-permissions`. Enable in Settings → Claude Code → "Allow bypass permissions mode". Only use in sandboxed containers or VMs. Enterprise admins can disable. |

The `dontAsk` mode is available only in the CLI.

Remote sessions support Auto accept edits and Plan mode. Ask permissions is not available in remote sessions.

Enterprise admins can restrict which permission modes are available.

### Preview your app

Claude can start a dev server and open an embedded browser to verify its changes. This works for frontend web apps as well as backend servers. In most cases, Claude starts the server automatically after editing project files. By default, Claude auto-verifies changes after every edit.

The preview pane can also open static HTML files, PDFs, and images from your project. Click an HTML, PDF, or image path in the chat to open it in preview.

From the preview pane, you can:

* Interact with your running app directly in the embedded browser
* Watch Claude verify its own changes: it takes screenshots, inspects the DOM, clicks elements, fills forms, and fixes issues it finds
* Start or stop servers from the **Preview** dropdown in the session toolbar
* Persist cookies and local storage across server restarts by selecting **Persist sessions** in the dropdown
* Edit the server configuration or stop all servers at once

Claude creates the initial server configuration based on your project in `.claude/launch.json`. To disable preview entirely, toggle off **Preview** in Settings → Claude Code.

### Review changes with diff view

After Claude makes changes to your code, the diff view lets you review modifications file by file before creating a pull request.

When Claude changes files, a diff stats indicator appears showing the number of lines added and removed, such as `+12 -1`. Click this indicator to open the diff viewer, which displays a file list on the left and the changes for each file on the right.

To comment on specific lines, click any line in the diff to open a comment box. Type your feedback and press **Enter** to add the comment. After adding comments to multiple lines, submit all comments at once:

* **macOS**: press **Cmd+Enter**
* **Windows**: press **Ctrl+Enter**

Claude reads your comments and makes the requested changes, which appear as a new diff you can review.

### Review your code

In the diff view, click **Review code** in the top-right toolbar to ask Claude to evaluate the changes before you commit. Claude examines the current diffs and leaves comments directly in the diff view. The review focuses on high-signal issues: compile errors, definite logic errors, security vulnerabilities, and obvious bugs. It does not flag style, formatting, pre-existing issues, or anything a linter would catch.

### Monitor pull request status

After you open a pull request, a CI status bar appears in the session. Claude Code uses the GitHub CLI to poll check results and surface failures.

* **Auto-fix**: when enabled, Claude automatically attempts to fix failing CI checks.
* **Auto-merge**: when enabled, Claude merges the PR once all checks pass. The merge method is squash. Auto-merge must be enabled in your GitHub repository settings.

Use the **Auto-fix** and **Auto-merge** toggles in the CI status bar to enable either option. To archive the session automatically once the PR merges or closes, turn on auto-archive in Settings → Claude Code.

PR monitoring requires the GitHub CLI (`gh`) to be installed and authenticated.

## Arrange your workspace

The desktop app is built around panes you can arrange in any layout: chat, diff, preview, terminal, file, plan, tasks, and subagent. Drag a pane by its header to reposition it, or drag a pane edge to resize it. Press **Cmd+\\** on macOS or **Ctrl+\\** on Windows to close the focused pane. Open additional panes from the **Views** menu in the session toolbar.

### Run commands in the terminal

The integrated terminal lets you run commands alongside your session without switching to another app. Open it from the **Views** menu or press **Ctrl+`** on macOS or Windows. The terminal opens in your session's working directory and shares the same environment as Claude. The terminal is available in local sessions only.

### Open and edit files

Click a file path in the chat or diff viewer to open it in the file pane. HTML, PDF, and image paths open in the preview pane instead. Make spot edits and click **Save** to write them back.

The file pane is available in local and SSH sessions. For remote sessions, ask Claude to make the change.

### Open files in other apps

Right-click any file path in the chat, diff viewer, or file pane to open a context menu:

* **Attach as context**: add the file to your next prompt
* **Open in**: open the file in an installed editor such as VS Code, Cursor, or Zed
* **Show in Finder** (macOS) / **Show in Explorer** (Windows): open the containing folder
* **Copy path**: copy the absolute path to your clipboard

### Switch view modes

View modes control how much detail appears in the chat transcript. Switch modes from the **Transcript view** dropdown next to the send button, or press **Ctrl+O** on macOS or Windows to cycle through them.

| Mode        | What it shows                                                  |
| ----------- | -------------------------------------------------------------- |
| **Normal**  | Tool calls collapsed into summaries, with full text responses  |
| **Verbose** | Every tool call, file read, and intermediate step Claude takes |
| **Summary** | Only Claude's final responses and the changes it made          |

Use Verbose when debugging why Claude took a particular action. Use Summary when you're running multiple sessions and want to scan results quickly.

### Keyboard shortcuts

Press **Cmd+/** on macOS or **Ctrl+/** on Windows to see all shortcuts available in the Code tab. On Windows, use **Ctrl** in place of **Cmd** for the shortcuts below. Session cycling, the terminal toggle, and the view-mode toggle use **Ctrl** on every platform.

| Shortcut                              | Action                       |
| ------------------------------------- | ---------------------------- |
| `Cmd` `/`                             | Show keyboard shortcuts      |
| `Cmd` `N`                             | New session                  |
| `Cmd` `W`                             | Close session                |
| `Ctrl` `Tab` / `Ctrl` `Shift` `Tab`   | Next or previous session     |
| `Cmd` `Shift` `]` / `Cmd` `Shift` `[` | Next or previous session     |
| `Esc`                                 | Stop Claude's response       |
| `Cmd` `Shift` `D`                     | Toggle diff pane             |
| `Cmd` `Shift` `P`                     | Toggle preview pane          |
| `Cmd` `Shift` `S`                     | Select an element in preview |
| `Ctrl` `` ` ``                        | Toggle terminal pane         |
| `Cmd` `\`                             | Close focused pane           |
| `Cmd` `;`                             | Open side chat               |
| `Ctrl` `O`                            | Cycle view modes             |
| `Cmd` `Shift` `M`                     | Open permission mode menu    |
| `Cmd` `Shift` `I`                     | Open model menu              |
| `Cmd` `Shift` `E`                     | Open effort menu             |
| `1`–`9`                               | Select item in an open menu  |

These shortcuts apply only to the Code tab. Terminal-based interactive mode shortcuts (e.g., `Shift+Tab` to cycle modes) do not apply in Desktop.

### Check usage

Click the usage ring next to the model picker to see your current context window usage and your plan usage for the period. Context usage is per session; plan usage is shared across all your Claude Code surfaces.

## Let Claude use your computer

Computer use lets Claude open your apps, control your screen, and work directly on your machine the way you would. Research preview on macOS and Windows that requires a Pro or Max plan. Not available on Team or Enterprise plans.

Computer use is off by default. Enable it in Settings before Claude can control your screen. On macOS, you also need to grant Accessibility and Screen Recording permissions.

Unlike the sandboxed Bash tool, computer use runs on your actual desktop with access to whatever you approve.

### When computer use applies

Claude tries the most precise tool first:

* If you have a connector for a service, Claude uses the connector.
* If the task is a shell command, Claude uses Bash.
* If the task is browser work and you have Claude in Chrome set up, Claude uses that.
* If none of those apply, Claude uses computer use.

### App permissions

The first time Claude needs to use an app, a prompt appears. Click **Allow for this session** or **Deny**. Approvals last for the current session, or 30 minutes in Dispatch-spawned sessions.

App access tiers (fixed by category, cannot be changed):

| Tier         | What Claude can do                                       | Applies to                  |
| :----------- | :------------------------------------------------------- | :-------------------------- |
| View only    | See the app in screenshots                               | Browsers, trading platforms |
| Click only   | Click and scroll, but not type or use keyboard shortcuts | Terminals, IDEs             |
| Full control | Click, type, drag, and use keyboard shortcuts            | Everything else             |

Apps with broad reach (terminals, Finder/File Explorer, System Settings) show an extra warning.

You can configure:
* **Denied apps**: add apps here to reject them without prompting.
* **Unhide apps when Claude finishes**: while Claude is working, your other windows are hidden so it interacts with only the approved app. When Claude finishes, hidden windows are restored.

## Manage sessions

### Work in parallel with sessions

Click **+ New session** or press **Cmd+N** (macOS) / **Ctrl+N** (Windows) to work on multiple tasks in parallel. Press **Ctrl+Tab** and **Ctrl+Shift+Tab** to cycle through sessions. For Git repositories, each session gets its own isolated copy of your project using Git worktrees, so changes in one session don't affect other sessions until you commit them.

Worktrees are stored in `<project-root>/.claude/worktrees/` by default. You can change this in Settings → Claude Code under "Worktree location". You can also set a branch prefix to keep Claude-created branches organized.

To include gitignored files like `.env` in new worktrees, create a `.worktreeinclude` file in your project root.

Session isolation requires Git. On Windows, Git is required for the Code tab to work.

### Ask a side question without derailing the session

A side chat lets you ask Claude a question that uses your session's context but doesn't add anything back to the main conversation. Use it to understand a piece of code, check an assumption, or explore an idea without steering the session off course.

Press **Cmd+;** on macOS or **Ctrl+;** on Windows to open a side chat, or type `/btw` in the prompt box. The side chat can read everything in the main thread up to that point. Side chats are available in local and SSH sessions.

### Watch background tasks

The tasks pane shows background work running inside the current session: subagents, background shell commands, and workflows. Open it from the **Views** menu or drag it into your layout. Click any entry to see its output in the subagent pane or stop it.

### Run long-running tasks remotely

For large refactors, test suites, migrations, or other long-running tasks, select **Remote** instead of **Local** when starting a session. Remote sessions run on Anthropic's cloud infrastructure and continue even if you close the app or shut down your computer. You can also monitor remote sessions from claude.ai/code or the Claude iOS app.

Remote sessions also support multiple repositories. After selecting a cloud environment, click the **+** button next to the repo pill to add additional repositories. Each repo gets its own branch selector.

### Continue in another surface

The **Continue in** menu (VS Code icon in the bottom right of the session toolbar) lets you move your session to another surface:

* **Claude Code on the Web**: sends your local session to continue running remotely. Desktop pushes your branch, generates a summary of the conversation, and creates a new remote session with the full context. Requires a clean working tree. Not available for SSH sessions.
* **Your IDE**: opens your project in a supported IDE at the current working directory.

### Sessions from Dispatch

Dispatch is a persistent conversation with Claude that lives in the Cowork tab. You message Dispatch a task, and it decides how to handle it.

A task can end up as a Code session in two ways: you ask for one directly, or Dispatch decides the task is development work and spawns one on its own. Tasks that typically route to Code include fixing bugs, updating dependencies, running tests, or opening pull requests. Research, document editing, and spreadsheet work stay in Cowork.

The Code session appears in the Code tab's sidebar with a **Dispatch** badge. You get a push notification on your phone when it finishes or needs your approval.

If you have computer use enabled, Dispatch-spawned Code sessions can use it too. App approvals in those sessions expire after 30 minutes and re-prompt.

Dispatch requires a Pro or Max plan and is not available on Team or Enterprise plans.

## Extend Claude Code

### Connect external tools

For local and SSH sessions, click the **+** button next to the prompt box and select **Connectors** to add integrations like Google Calendar, Slack, GitHub, Linear, Notion, and more.

Connectors are MCP servers with a graphical setup flow. For integrations not listed in Connectors, add MCP servers manually via settings files. You can also create custom connectors.

To manage or disconnect connectors, go to Settings → Connectors in the desktop app, or select **Manage connectors** from the Connectors menu.

### Use skills

Skills extend what Claude can do. Type `/` in the prompt box or click the **+** button and select **Slash commands** to browse what's available. This includes built-in commands, your custom skills, project skills from your codebase, and skills from any installed plugins.

### Install plugins

Plugins are reusable packages that add skills, agents, hooks, MCP servers, and LSP configurations to Claude Code. Install plugins from the desktop app without using the terminal: click the **+** button and select **Plugins**.

Plugins can be scoped to your user account, a specific project, or local-only. Plugins are not available for remote sessions.

### Configure preview servers

Claude automatically detects your dev server setup and stores the configuration in `.claude/launch.json`. To customize how your server starts, edit the file manually or click **Edit configuration** in the Preview dropdown.

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "my-app",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "port": 3000
    }
  ]
}
```

You can define multiple configurations to run different servers from the same project.

#### Auto-verify changes

When `autoVerify` is enabled, Claude automatically verifies code changes after editing files. It takes screenshots, checks for errors, and confirms changes work. Auto-verify is on by default. Disable per-project by adding `"autoVerify": false` to `.claude/launch.json`.

#### Configuration fields

| Field               | Type      | Description                                                                                                 |
| ------------------- | --------- | ----------------------------------------------------------------------------------------------------------- |
| `name`              | string    | A unique identifier for this server                                                                         |
| `runtimeExecutable` | string    | The command to run, such as `npm`, `yarn`, or `node`                                                       |
| `runtimeArgs`       | string[]  | Arguments passed to `runtimeExecutable`, such as `["run", "dev"]`                                          |
| `port`              | number    | The port your server listens on. Defaults to 3000                                                           |
| `cwd`               | string    | Working directory relative to your project root. Defaults to the project root.                              |
| `env`               | object    | Additional environment variables as key-value pairs. Don't put secrets here — use the local environment editor. |
| `autoPort`          | boolean   | How to handle port conflicts (true = find free port, false = fail with error, not set = ask)                |
| `program`           | string    | A script to run with `node` directly                                                                        |
| `args`              | string[]  | Arguments passed to `program` only                                                                          |

## Environment configuration

* **Local**: runs on your machine with direct access to your files
* **Remote**: runs on Anthropic's cloud infrastructure. Sessions continue even if you close the app.
* **SSH**: runs on a remote machine you connect to over SSH

### Local sessions

The desktop app does not always inherit your full shell environment. On macOS, when you launch the app from the Dock or Finder, it reads your shell profile to extract `PATH` and a fixed set of Claude Code variables, but other variables are not picked up. On Windows, the app inherits user and system environment variables but does not read PowerShell profiles.

To set environment variables for local sessions and dev servers, open the environment dropdown in the prompt box, hover over **Local**, and click the gear icon to open the local environment editor. Variables you save here are stored encrypted on your machine.

Extended thinking is enabled by default. To disable thinking entirely, set `MAX_THINKING_TOKENS` to `0` in the local environment editor.

### Remote sessions

Remote sessions continue in the background even if you close the app. Usage counts toward your subscription plan limits with no separate compute charges.

You can create custom cloud environments with different network access levels and environment variables. Select the environment dropdown when starting a remote session and choose **Add environment**.

### SSH sessions

SSH sessions let you run Claude Code on a remote machine while using the desktop app as your interface. To add an SSH connection, click the environment dropdown before starting a session and select **+ Add SSH connection**. The dialog asks for:

* **Name**: a friendly label for this connection
* **SSH Host**: `user@hostname` or a host defined in `~/.ssh/config`
* **SSH Port**: defaults to 22 if left empty
* **Identity File**: path to your private key

The remote machine must run Linux or macOS, and Claude Code must be installed on it. SSH sessions support permission modes, connectors, plugins, and MCP servers.

## Enterprise configuration

Organizations on Team or Enterprise plans can manage desktop app behavior through admin console controls, managed settings files, and device management policies.

### Admin console controls

Configured through https://claude.ai/admin-settings/claude-code:

* **Code in the desktop**: control whether users can access Claude Code in the desktop app
* **Code in the web**: enable or disable web sessions for your organization
* **Remote Control**: enable or disable Remote Control for your organization
* **Disable Bypass permissions mode**: prevent users from enabling bypass permissions mode

### Managed settings

| Key                                        | Description                                                                                                            |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `permissions.disableBypassPermissionsMode` | Set to `"disable"` to prevent users from enabling Bypass permissions mode.                                            |
| `disableAutoMode`                          | Set to `"disable"` to prevent users from enabling Auto mode. Removes Auto from the mode selector.                     |
| `autoMode`                                 | Customize what the auto mode classifier trusts and blocks across your organization.                                    |

`autoMode` is read from user settings, `.claude/settings.local.json`, and managed settings, but not from the checked-in `.claude/settings.json`: a cloned repo cannot inject its own classifier rules.

### Device management policies

* **macOS**: configure via `com.anthropic.Claude` preference domain using tools like Jamf or Kandji
* **Windows**: configure via registry at `SOFTWARE\Policies\Claude`

Available policies include enabling/disabling the Claude Code feature, controlling auto-updates, and setting a custom deployment URL.

### Deployment

* **macOS**: distribute via MDM such as Jamf or Kandji using the `.dmg` installer
* **Windows**: deploy via MSIX package or `.exe` installer

## Coming from the CLI?

Desktop runs the same underlying engine as the CLI with a graphical interface. You can run both simultaneously on the same machine, even on the same project. Each maintains separate session history, but they share configuration and project memory via CLAUDE.md files.

To move a CLI session into Desktop, run `/desktop` in the terminal. Claude saves your session and opens it in the desktop app, then exits the CLI. Available on macOS and Windows only.

When to use Desktop vs CLI: use Desktop when you want to manage parallel sessions in one window, arrange panes side by side, or review changes visually. Use the CLI when you need scripting, automation, or prefer a terminal workflow.

### CLI flag equivalents

| CLI                                   | Desktop equivalent                                                                  |
| ------------------------------------- | ----------------------------------------------------------------------------------- |
| `--model sonnet`                      | Model dropdown next to the send button                                              |
| `--resume`, `--continue`              | Click a session in the sidebar                                                      |
| `--permission-mode`                   | Mode selector next to the send button                                               |
| `--dangerously-skip-permissions`      | Bypass permissions mode via Settings → Claude Code                                  |
| `--add-dir`                           | Add multiple repos with the **+** button in remote sessions                         |
| `--allowedTools`, `--disallowedTools` | Not available in Desktop                                                            |
| `--verbose`                           | Verbose view mode in the Transcript view dropdown                                   |
| `--print`, `--output-format`          | Not available. Desktop is interactive only.                                         |
| `ANTHROPIC_MODEL` env var             | Model dropdown next to the send button                                              |
| `MAX_THINKING_TOKENS` env var         | Set in the local environment editor                                                 |

### Shared configuration

Desktop and CLI read the same configuration files:

* **CLAUDE.md** and `CLAUDE.local.md` files in your project are used by both
* **MCP servers** configured in `~/.claude.json` or `.mcp.json` work in both
* **Hooks** and **skills** defined in settings apply to both
* **Settings** in `~/.claude.json` and `~/.claude/settings.json` are shared

Note: MCP servers configured for the Claude Desktop chat app in `claude_desktop_config.json` are separate from Claude Code and will not appear in the Code tab. To use MCP servers in Claude Code, configure them in `~/.claude.json` or your project's `.mcp.json` file.

### Feature comparison

| Feature                                               | CLI                                    | Desktop                                                          |
| ----------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------------- |
| Permission modes                                      | All modes including `dontAsk`          | Ask permissions, Auto accept edits, Plan mode, Auto, Bypass      |
| Third-party providers                                 | Bedrock, Vertex, Foundry               | Anthropic's API by default; Enterprise can configure Vertex AI   |
| MCP servers                                           | Configure in settings files            | Connectors UI for local/SSH sessions, or settings files          |
| Plugins                                               | `/plugin` command                      | Plugin manager UI                                                |
| @mention files                                        | Text-based                             | With autocomplete; local and SSH sessions only                   |
| File attachments                                      | Not available                          | Images, PDFs                                                     |
| Session isolation                                     | `--worktree` flag                      | Automatic worktrees                                              |
| Multiple sessions                                     | Separate terminals                     | Sidebar tabs                                                     |
| Recurring tasks                                       | Cron jobs, CI pipelines                | Scheduled tasks                                                  |
| Computer use                                          | Enable via `/mcp` on macOS             | App and screen control on macOS and Windows                      |
| Dispatch integration                                  | Not available                          | Dispatch sessions in the sidebar                                 |
| Scripting and automation                              | `--print`, Agent SDK                   | Not available                                                    |

### What's not available in Desktop

* **Third-party providers**: Bedrock and Foundry require the CLI
* **Linux**: the desktop app is available on macOS and Windows only
* **Inline code suggestions**: Desktop does not provide autocomplete-style suggestions
* **Agent teams**: multi-agent orchestration is available via CLI and Agent SDK, not in Desktop

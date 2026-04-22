# tmux-cli

> Sources: pchalasani (claude-code-tools), Unknown
> Raw: [2026-04-22-tmux-cli](../../raw/claude-code/2026-04-22-tmux-cli.md)
> Updated: 2026-04-22

## Overview

`tmux-cli` is a third-party CLI tool from the `claude-code-tools` project that lets Claude Code and other CLI agents programmatically control tmux panes and windows. It fills a gap in Claude Code's native tooling: while Claude Code ships with its own `--tmux` flag support (for splitting work across worktrees), `tmux-cli` exposes a richer command-level API for launching, communicating with, monitoring, and terminating arbitrary programs inside tmux panes.

The tool auto-adapts to context: when already inside a tmux session it manages panes within the current window (local mode); when running outside tmux it creates a dedicated tmux session with its own windows (remote mode).

## Capabilities

| Command | What it does |
|---------|-------------|
| `tmux-cli launch "<shell>"` | Open a new pane running a shell or program |
| `tmux-cli send "<cmd>" --pane=N` | Transmit keystrokes to pane N (configurable timing, auto-retry) |
| `tmux-cli capture --pane=N` | Extract pane contents as text |
| `tmux-cli wait_idle --pane=N` | Block until the pane stops producing output |
| `tmux-cli kill --pane=N` | Terminate the pane (guards against killing the active pane) |

Additional capabilities: send interrupt signals (`Ctrl+C`) or escape sequences; retrieve command exit codes in JSON format.

## Recommended Usage Pattern

The project documentation emphasizes one key rule: **always launch a shell first** before sending commands to a pane. This prevents output loss when commands fail, because a persistent shell process retains stdout/stderr even after the command exits.

```
tmux-cli launch "zsh"                      # 1. Shell first
tmux-cli send "pytest tests/" --pane=2     # 2. Send the command
tmux-cli wait_idle --pane=2                # 3. Wait for completion
tmux-cli capture --pane=2                  # 4. Collect output
tmux-cli kill --pane=2                     # 5. Clean up
```

This pattern gives an agent reliable access to stdout without relying on Claude Code's built-in Bash tool, which can time out on long-running processes.

## Installation

`tmux-cli` ships as part of the `claude-code-tools` package and installs via that package's standard procedure. The project also bundles complementary tools (`aichat`, `lmsh`, `vault`, `env-safe`, `fix-session`, `statusline`) and extension packages (safety hooks, voice integration, Google Docs/Sheets connectors, alternative LLM provider support).

## See Also

- [Extending Claude Code](extensions.md) — covers Claude Code's native extension mechanisms including plugins, which is the packaging layer closest to how claude-code-tools distributes its hooks and skills
- [CLI Reference](cli-reference.md) — documents Claude Code's built-in `--tmux` and worktree flags that tmux-cli complements
- [Agent Teams](agent-teams.md) — agent teams use tmux split-pane mode by default when inside a tmux session; tmux-cli complements this with programmatic pane control

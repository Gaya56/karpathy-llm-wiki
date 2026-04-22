# Skills and Slash Commands

> Sources: Anthropic, 2026-04-19
> Raw: [2026-04-19-claude-code-slash-commands](../../raw/claude-code/2026-04-19-claude-code-slash-commands.md)
> Updated: 2026-04-19

## Overview

Skills are the Claude Code mechanism for packaging reusable knowledge, workflows, and instructions as slash commands. A skill is a directory containing a `SKILL.md` file; the directory name becomes the `/slash-command`. Custom commands (`.claude/commands/*.md`) still work and are now treated as a legacy alias — if a command and a skill share the same name, the skill takes precedence.

Claude Code extends the open [Agent Skills standard](https://agentskills.io) with invocation control, subagent execution, and dynamic context injection. Bundled skills (`/simplify`, `/batch`, `/debug`, `/loop`, `/claude-api`) ship with every installation.

## Skill anatomy

Each skill is a directory with `SKILL.md` as the entrypoint. Supporting files (templates, examples, scripts) are optional and referenced from `SKILL.md` so Claude loads them only when needed. Keep `SKILL.md` under 500 lines; move detailed reference material to separate files.

```
my-skill/
├── SKILL.md           # required
├── reference.md       # loaded on demand
└── scripts/
    └── helper.py      # executed, not loaded into context
```

`SKILL.md` has two parts: YAML frontmatter (between `---` markers) and markdown content. The frontmatter configures invocation behavior; the content is what Claude reads when the skill runs.

## Storage scopes and priority

| Scope      | Path                                               | Applies to              |
| :--------- | :------------------------------------------------- | :---------------------- |
| Enterprise | Managed settings                                   | All org users           |
| Personal   | `~/.claude/skills/<name>/SKILL.md`                 | All your projects       |
| Project    | `.claude/skills/<name>/SKILL.md`                   | This project only       |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`                  | Where plugin is enabled |

Priority when names collide: enterprise > personal > project. Plugin skills are namespaced as `plugin-name:skill-name` so they never collide. Skills from `--add-dir` paths are also auto-discovered.

Claude Code watches skill directories for changes. Edits take effect in the current session without restarting. Creating a new top-level skills directory requires a restart.

## Frontmatter reference

All fields are optional; `description` is strongly recommended.

| Field                      | Effect                                                                                           |
| :------------------------- | :----------------------------------------------------------------------------------------------- |
| `name`                     | Slash-command name (lowercase, hyphens, max 64 chars). Defaults to directory name.               |
| `description`              | Shown in skill listing; used by Claude to decide when to invoke. Front-load the key use case.    |
| `when_to_use`              | Supplemental trigger context, appended to `description`. Both capped at 1,536 chars combined.    |
| `argument-hint`            | Autocomplete hint, e.g. `[issue-number]`.                                                        |
| `disable-model-invocation` | `true` → Claude cannot auto-invoke; description hidden from context. You invoke manually.        |
| `user-invocable`           | `false` → hidden from `/` menu. Claude can still auto-invoke it.                                 |
| `allowed-tools`            | Tools pre-approved for this skill (no per-use prompt). Space-separated or YAML list.             |
| `model`                    | Model override while skill is active.                                                             |
| `effort`                   | Effort level (`low` / `medium` / `high` / `xhigh` / `max`) while skill is active.               |
| `context`                  | `fork` → skill runs in an isolated subagent context.                                             |
| `agent`                    | Which subagent to use with `context: fork`. Defaults to `general-purpose`.                       |
| `hooks`                    | Hooks scoped to this skill's lifecycle.                                                           |
| `paths`                    | Glob patterns — skill auto-loads only when working with matching files.                           |
| `shell`                    | `bash` (default) or `powershell` for inline shell commands.                                      |

## Invocation control

By default both you and Claude can invoke any skill. Two frontmatter fields restrict this:

- **`disable-model-invocation: true`** — you invoke only. Use for workflows with side effects: `/deploy`, `/commit`, `/send-slack-message`. Description is removed from context entirely, so Claude doesn't even see it.
- **`user-invocable: false`** — Claude invokes only. Use for background reference knowledge that isn't a meaningful user action.

The `user-invocable` field controls menu visibility only — it does not block the Skill tool. Use `disable-model-invocation: true` to block programmatic invocation.

## Arguments

Arguments follow the skill name on the command line. Access them in skill content via substitution variables:

| Variable               | Expands to                                                        |
| :--------------------- | :---------------------------------------------------------------- |
| `$ARGUMENTS`           | Full argument string as typed.                                    |
| `$ARGUMENTS[N]`        | Argument at 0-based index N.                                      |
| `$N`                   | Shorthand for `$ARGUMENTS[N]`.                                    |
| `${CLAUDE_SESSION_ID}` | Current session ID. Useful for session-specific log files.        |
| `${CLAUDE_SKILL_DIR}`  | Directory containing this `SKILL.md`. Stable regardless of cwd.  |

Multi-word arguments use shell-style quoting: `/skill "hello world" second` → `$0` = `hello world`, `$1` = `second`. If `$ARGUMENTS` is absent from the skill body, Claude Code appends `ARGUMENTS: <value>` at the end.

Example — positional arguments for a migration skill:

```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

## Dynamic context injection (bash execution)

The `` !`<command>` `` syntax executes a shell command before the skill content is sent to Claude. Output replaces the placeholder in the rendered prompt. This is preprocessing — Claude only sees the final result, not the command itself.

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

Summarize this pull request...
```

For multi-line commands, use a fenced block opened with ` ```! `. Disable this feature for user/project/plugin skills with `"disableSkillShellExecution": true` in settings (bundled and managed skills are unaffected).

## Running in a subagent (context: fork)

`context: fork` runs the skill in an isolated subagent — no access to conversation history. The skill content becomes the subagent's task prompt. The `agent` field picks which subagent type executes it: `Explore`, `Plan`, `general-purpose`, or any custom agent from `.claude/agents/`.

This pattern suits research, large file reads, or work that would otherwise bloat the main conversation:

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

Note: `context: fork` only makes sense for skills with explicit actionable instructions. A skill containing only guidelines returns without meaningful output from the subagent.

## Skill content lifecycle

When invoked, the rendered `SKILL.md` enters the conversation as a single message and stays for the rest of the session. Claude Code does not re-read the file on later turns.

During auto-compaction, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. All re-attached skills share a 25,000-token budget, filled from most-recently-invoked first — older skills can be dropped entirely after compaction.

## Restricting skill access

Three mechanisms control which skills Claude can invoke:

**Deny all skills** (remove Skill tool):
```
# In /permissions deny rules:
Skill
```

**Deny or allow specific skills** with permission rule syntax:
```
Skill(commit)         # exact name match
Skill(review-pr *)    # prefix + any arguments
```

**Hide per-skill** with `disable-model-invocation: true` in frontmatter.

## Sharing skills

- **Project scope:** commit `.claude/skills/` to version control.
- **Plugin:** add a `skills/` directory in your plugin package.
- **Org-wide:** deploy through managed settings.

## See Also

- [Extending Claude Code](extensions.md) — how skills fit among the seven extension mechanisms, context-cost trade-offs
- [Custom Subagents](subagents.md) — full subagent configuration reference; skills with `context: fork` delegate to these
- [Hooks Reference](hooks.md) — lifecycle hooks can be scoped to individual skills via the `hooks` frontmatter field
- [MCP in Claude Code](mcp.md) — MCP prompt integration with skills; capability vs. competence distinction
- [Settings and Configuration](settings.md) — `disableSkillShellExecution` and `SLASH_COMMAND_TOOL_CHAR_BUDGET` settings

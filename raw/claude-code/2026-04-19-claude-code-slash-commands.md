# Extend Claude with Skills (Slash Commands)

> Source: https://code.claude.com/docs/en/slash-commands
> Collected: 2026-04-19
> Published: Unknown

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`.

Create a skill when you keep pasting the same playbook, checklist, or multi-step procedure into chat, or when a section of CLAUDE.md has grown into a procedure rather than a fact. Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it.

**Note:** Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Existing `.claude/commands/` files keep working. Skills add optional features: a directory for supporting files, frontmatter to control whether you or Claude invokes them, and the ability for Claude to load them automatically when relevant.

Claude Code skills follow the Agent Skills open standard (agentskills.io), which works across multiple AI tools. Claude Code extends the standard with additional features like invocation control, subagent execution, and dynamic context injection.

## Bundled skills

Claude Code includes bundled skills available in every session: `/simplify`, `/batch`, `/debug`, `/loop`, `/claude-api`. Unlike most built-in commands which execute fixed logic, bundled skills are prompt-based — they give Claude a detailed playbook and let it orchestrate the work using its tools.

## Getting started

### Create your first skill

Every skill needs a `SKILL.md` file with two parts: YAML frontmatter (between `---` markers) telling Claude when to use the skill, and markdown content with instructions Claude follows when invoked. The `name` field becomes the `/slash-command`; the `description` helps Claude decide when to load it automatically.

Example skill `~/.claude/skills/explain-code/SKILL.md`:

```yaml
---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
---

When explaining code, always include:

1. **Start with an analogy**: Compare the code to something from everyday life
2. **Draw a diagram**: Use ASCII art to show the flow, structure, or relationships
3. **Walk through the code**: Explain step-by-step what happens
4. **Highlight a gotcha**: What's a common mistake or misconception?
```

Invoke with `/explain-code src/auth/login.ts` or let Claude invoke it automatically when the description matches.

### Where skills live

| Location   | Path                                               | Applies to                     |
| :--------- | :------------------------------------------------- | :----------------------------- |
| Enterprise | Managed settings                                   | All users in your organization |
| Personal   | `~/.claude/skills/<skill-name>/SKILL.md`           | All your projects              |
| Project    | `.claude/skills/<skill-name>/SKILL.md`             | This project only              |
| Plugin     | `<plugin>/skills/<skill-name>/SKILL.md`            | Where plugin is enabled        |

When skills share the same name across levels, higher-priority locations win: enterprise > personal > project. Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels.

**Priority:** If a skill and a command (`.claude/commands/`) share the same name, the skill takes precedence.

#### Live change detection

Claude Code watches skill directories for file changes. Adding, editing, or removing a skill takes effect within the current session without restarting. Creating a top-level skills directory that did not exist when the session started requires restarting Claude Code.

#### Automatic discovery from nested directories

When working with files in subdirectories, Claude Code automatically discovers skills from nested `.claude/skills/` directories (e.g., `packages/frontend/.claude/skills/`). Supports monorepo setups where packages have their own skills.

#### Skills from additional directories

The `--add-dir` flag grants file access rather than configuration discovery, but `.claude/skills/` within an added directory is loaded automatically.

### Skill directory structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

## Configure skills

### Types of skill content

**Reference content** adds knowledge Claude applies to your current work — conventions, patterns, style guides, domain knowledge. Runs inline alongside your conversation context.

**Task content** gives Claude step-by-step instructions for a specific action (deployments, commits, code generation). Add `disable-model-invocation: true` to prevent Claude from triggering it automatically.

### Frontmatter reference

All frontmatter fields are optional; only `description` is recommended.

| Field                      | Description                                                                                                  |
| :------------------------- | :----------------------------------------------------------------------------------------------------------- |
| `name`                     | Display name. If omitted, uses directory name. Lowercase letters, numbers, hyphens only (max 64 chars).      |
| `description`              | What the skill does and when to use it. Front-load the key use case; truncated at 1,536 chars in listing.    |
| `when_to_use`              | Additional trigger context. Appended to `description`, counts toward 1,536-char cap.                        |
| `argument-hint`            | Hint shown during autocomplete. Example: `[issue-number]` or `[filename] [format]`.                        |
| `disable-model-invocation` | Set `true` to prevent Claude from auto-loading. Use for side-effect workflows. Default: `false`.            |
| `user-invocable`           | Set `false` to hide from the `/` menu (background knowledge, not user-actionable). Default: `true`.         |
| `allowed-tools`            | Tools Claude can use without asking permission when skill is active. Space-separated string or YAML list.   |
| `model`                    | Model to use when this skill is active.                                                                      |
| `effort`                   | Effort level when this skill is active. Options: `low`, `medium`, `high`, `xhigh`, `max`.                   |
| `context`                  | Set `fork` to run in a forked subagent context.                                                              |
| `agent`                    | Which subagent type to use when `context: fork` is set.                                                      |
| `hooks`                    | Hooks scoped to this skill's lifecycle.                                                                      |
| `paths`                    | Glob patterns limiting when skill is activated (path-specific auto-loading).                                 |
| `shell`                    | Shell for `!` commands: `bash` (default) or `powershell`.                                                   |

### Available string substitutions

| Variable               | Description                                                                    |
| :--------------------- | :----------------------------------------------------------------------------- |
| `$ARGUMENTS`           | All arguments passed when invoking the skill.                                  |
| `$ARGUMENTS[N]`        | Specific argument by 0-based index.                                            |
| `$N`                   | Shorthand for `$ARGUMENTS[N]` (e.g., `$0` for first, `$1` for second).        |
| `${CLAUDE_SESSION_ID}` | Current session ID. Useful for logging or session-specific files.              |
| `${CLAUDE_SKILL_DIR}`  | Directory containing the skill's `SKILL.md`. For plugin skills, the skill's subdirectory within the plugin. |

Indexed arguments use shell-style quoting: `/my-skill "hello world" second` makes `$0` expand to `hello world` and `$1` to `second`.

### Add supporting files

Skills can include multiple files. Large reference docs, API specs, or example collections don't need to load into context every time the skill runs. Reference supporting files from `SKILL.md` so Claude knows when to load them. Keep `SKILL.md` under 500 lines.

## Control who invokes a skill

By default, both you and Claude can invoke any skill.

- **`disable-model-invocation: true`**: Only you can invoke the skill. Use for workflows with side effects (deploy, commit, send-slack-message).
- **`user-invocable: false`**: Only Claude can invoke the skill. Use for background knowledge users shouldn't invoke directly.

| Frontmatter                      | You can invoke | Claude can invoke | When loaded into context                                     |
| :------------------------------- | :------------- | :---------------- | :----------------------------------------------------------- |
| (default)                        | Yes            | Yes               | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes            | No                | Description not in context, full skill loads when you invoke |
| `user-invocable: false`          | No             | Yes               | Description always in context, full skill loads when invoked |

## Skill content lifecycle

When invoked, the rendered `SKILL.md` content enters the conversation as a single message and stays for the rest of the session. Claude Code does not re-read the skill file on later turns.

Auto-compaction carries invoked skills forward within a token budget. When context is summarized, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens.

## Pre-approve tools for a skill

The `allowed-tools` field grants permission for listed tools while the skill is active. Does not restrict which tools are available — every tool remains callable, and permission settings still govern tools not listed.

```yaml
---
name: commit
description: Stage and commit the current changes
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---
```

## Pass arguments to skills

Arguments are available via the `$ARGUMENTS` placeholder:

```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.
```

Running `/fix-issue 123` inserts "123" at `$ARGUMENTS`.

Positional arguments:

```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $0 component from $1 to $2.
```

Running `/migrate-component SearchBar React Vue` replaces `$0` with `SearchBar`, `$1` with `React`, `$2` with `Vue`.

If a skill doesn't include `$ARGUMENTS`, Claude Code appends `ARGUMENTS: <your input>` to the skill content.

## Advanced patterns

### Inject dynamic context

The `` !`<command>` `` syntax runs shell commands before the skill content is sent to Claude. Output replaces the placeholder — Claude receives actual data, not the command itself. This is preprocessing, not something Claude executes.

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
```

For multi-line commands, use a fenced code block opened with ` ```! `.

To disable shell execution for user/project/plugin skills, set `"disableSkillShellExecution": true` in settings. Bundled and managed skills are not affected.

### Run skills in a subagent

Add `context: fork` to run in isolation. The skill content becomes the prompt driving the subagent — it won't have access to conversation history.

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

The `agent` field specifies which subagent configuration to use. Options include built-in agents (`Explore`, `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. Defaults to `general-purpose`.

### Restrict Claude's skill access

Three ways to control which skills Claude can invoke:

**Deny the Skill tool entirely** in `/permissions`:
```
Skill
```

**Allow or deny specific skills** using permission rules:
```
Skill(commit)        # exact match
Skill(review-pr *)   # prefix match with any arguments
```

**Hide individual skills** with `disable-model-invocation: true`.

Note: `user-invocable` only controls menu visibility, not Skill tool access. Use `disable-model-invocation: true` to block programmatic invocation.

## Share skills

- **Project skills**: commit `.claude/skills/` to version control
- **Plugins**: create a `skills/` directory in your plugin
- **Managed**: deploy organization-wide through managed settings

## Troubleshooting

**Skill not triggering:** Check description includes keywords users would naturally say. Verify it appears in "What skills are available?" Try invoking directly with `/skill-name`.

**Skill triggers too often:** Make description more specific. Add `disable-model-invocation: true` if only manual invocation is wanted.

**Skill descriptions cut short:** Descriptions are loaded into context so Claude knows what's available. Budget scales dynamically at 1% of context window with 8,000-character fallback. Raise with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var, or trim `description` and `when_to_use`. Each entry's combined text is capped at 1,536 characters regardless.

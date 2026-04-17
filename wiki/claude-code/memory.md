# Memory and Persistent Instructions

> Sources: Anthropic, Unknown
> Raw: [memory](../../raw/claude-code/memory.md)

## Overview

Claude Code starts every session with a fresh context window, but two complementary mechanisms carry knowledge across sessions: CLAUDE.md files (instructions the human writes) and auto memory (notes Claude writes itself). Both are loaded at session start and treated as context, not enforced configuration — the more specific and concise your instructions, the more consistently Claude follows them.

## CLAUDE.md files

CLAUDE.md files are markdown files giving Claude persistent instructions for a project, a personal workflow, or an entire organization. Claude reads them at the start of every session.

**When to add to CLAUDE.md:** treat it as the place to write down what you'd otherwise re-explain — when Claude makes the same mistake a second time, when a code review catches something Claude should have known, when you type the same correction into chat that you typed last session.

Keep CLAUDE.md to facts Claude should hold every session: build commands, conventions, project layout, "always do X" rules. Multi-step procedures or instructions relevant to only one part of the codebase belong in a skill or a path-scoped rule instead.

### Scope and locations

More specific locations take precedence over broader ones:

| Scope | Location | Shared with |
| ----- | -------- | ----------- |
| Managed policy | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux `/etc/claude-code/CLAUDE.md`; Windows `C:\Program Files\ClaudeCode\CLAUDE.md` | All users in organization |
| Project instructions | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team members via source control |
| User instructions | `~/.claude/CLAUDE.md` | Just you (all projects) |
| Local instructions | `./CLAUDE.local.md` (gitignored) | Just you (current project) |

Claude Code walks up the directory tree from the working directory, loading all discovered CLAUDE.md and CLAUDE.local.md files — they concatenate rather than override. Within each directory, CLAUDE.local.md is appended after CLAUDE.md, so personal notes take precedence at that level. Files in subdirectories load on demand when Claude reads files in those subdirectories.

### Writing effective instructions

**Size:** target under 200 lines per file. Beyond that, context cost rises and adherence drops. Use `@path/to/import` syntax to pull in additional files, or move material into `.claude/rules/`.

**Specificity:** concrete and verifiable beats vague. "Use 2-space indentation" works better than "format code properly." "Run `npm test` before committing" works better than "test your changes."

**Consistency:** conflicting instructions cause Claude to pick one arbitrarily. Review periodically for outdated or contradictory rules across all loaded files.

**HTML comments:** block-level HTML comments (`<!-- ... -->`) are stripped before injection into context. Use them for human maintainer notes that shouldn't consume tokens. Comments inside code blocks are preserved.

### Imports

`@path/to/import` anywhere in a CLAUDE.md pulls in another file at launch. Relative paths resolve from the containing file; recursive imports work up to five hops deep. CLAUDE.local.md loads alongside CLAUDE.md and is treated identically — add it to `.gitignore` to keep personal notes out of source control.

### AGENTS.md interoperability

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If the repo already has `AGENTS.md` for other agents, create a `CLAUDE.md` that imports it (`@AGENTS.md`) and optionally adds Claude-specific instructions below. Both tools then read the same instructions without duplication.

### Project initialization

Run `/init` to generate a starting CLAUDE.md automatically. Claude analyzes the codebase and fills in build commands, test instructions, and conventions it discovers. If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting. Set `CLAUDE_CODE_NEW_INIT=1` for an interactive multi-phase flow where `/init` explores the codebase with a subagent, asks follow-up questions, and presents a reviewable proposal before writing files.

### Path-specific rules (`.claude/rules/`)

`.claude/rules/` lets you organize instructions into topic-specific files. Rules without `paths` frontmatter load at launch alongside `.claude/CLAUDE.md`. Rules with a `paths` YAML frontmatter field load only when Claude works with files matching those patterns — keeping rarely-relevant instructions out of context until they're needed.

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules
- All API endpoints must include input validation
```

User-level rules in `~/.claude/rules/` apply to every project. Project rules take precedence. The `.claude/rules/` directory supports symlinks, so a shared rule set can be linked into multiple projects.

### Large-team management

Organizations can deploy a managed CLAUDE.md at a system path (macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`, Linux `/etc/claude-code/CLAUDE.md`, Windows `C:\Program Files\ClaudeCode\CLAUDE.md`). This file cannot be excluded by individual settings and applies to all users on a machine — deploy via MDM, Group Policy, or Ansible.

The `claudeMdExcludes` setting (accepted at any settings layer; arrays merge) excludes specific files by path or glob:

```json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

Managed policy CLAUDE.md files cannot be excluded regardless of this setting.

## Auto memory

Auto memory lets Claude accumulate knowledge across sessions without the human writing anything. Claude saves notes as it works — build commands, debugging insights, architecture notes, style preferences — deciding on its own whether something is worth remembering for a future conversation.

Requires Claude Code v2.1.59 or later (`claude --version`).

### Enabling and storage

Auto memory is on by default. Toggle with `/memory` in session, or set `autoMemoryEnabled: false` in project settings, or set env var `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

Each project stores auto memory at `~/.claude/projects/<project>/memory/`, where `<project>` is derived from the git repository root. All worktrees and subdirectories of the same repo share one directory. Outside a git repo, the project root is used. Override the location with `autoMemoryDirectory` in user or local settings (not project settings, to prevent shared project configs redirecting writes to sensitive paths).

Directory structure:

```text
~/.claude/projects/<project>/memory/
├── MEMORY.md          # Concise index, loaded into every session
├── debugging.md       # Detailed notes on debugging patterns
├── api-conventions.md # API design decisions
└── ...
```

### Loading behavior

The first 200 lines of `MEMORY.md` (or 25KB, whichever comes first) are loaded at the start of every conversation. Content beyond that threshold is not loaded at session start. Claude keeps `MEMORY.md` concise by moving detailed notes into separate topic files.

Topic files (`debugging.md`, `patterns.md`, etc.) are not loaded at startup — Claude reads them on demand using its standard file tools. This is the opposite of CLAUDE.md files, which are loaded in full.

### Auditing

All auto memory files are plain markdown. Run `/memory` to browse and open them. Edit or delete any file at any time. When you see "Writing memory" or "Recalled memory" in the UI, Claude is actively updating or reading from the memory directory.

### Subagent auto memory

Subagents can maintain their own auto memory, configured via the `memory` frontmatter field in the subagent definition.

## The `/memory` command

`/memory` lists all CLAUDE.md, CLAUDE.local.md, and rules files loaded in the current session, provides an auto memory toggle, and links to the auto memory folder. Select any file to open it in your editor. When you tell Claude to remember something in conversation ("always use pnpm, not npm"), Claude saves it to auto memory. To add an instruction to CLAUDE.md explicitly, say "add this to CLAUDE.md" or edit the file directly via `/memory`.

## Troubleshooting

**Instructions not followed:** CLAUDE.md is delivered as a user message after the system prompt — it's context, not enforced configuration. Debug with `/memory` to verify files are loading. Make instructions more specific. Check for conflicting rules across files. For system-prompt-level enforcement, use `--append-system-prompt` (CLI/automation only; must be passed every invocation). Use the `InstructionsLoaded` hook to log exactly which instruction files load and when.

**CLAUDE.md too large:** move detailed content into `@path` imports or `.claude/rules/` files to keep the main file under 200 lines.

**Instructions lost after `/compact`:** project-root CLAUDE.md is re-read from disk and re-injected after compaction. Nested subdirectory CLAUDE.md files are not re-injected automatically — they reload when Claude next reads a file in that subdirectory. Conversation-only instructions don't survive compaction; add them to CLAUDE.md to persist.

## See Also

- [Extending Claude Code](extensions.md) — where CLAUDE.md and auto memory sit alongside Skills, MCP, Subagents, Hooks, and Plugins; when to use each mechanism
- [Custom Subagents](subagents.md) — subagent `memory` frontmatter field, auto memory per subagent
- [Hooks Reference](hooks.md) — `InstructionsLoaded` event for debugging which CLAUDE.md files load and when
- [Claude Code Overview](overview.md) — product-level context; CLAUDE.md and auto memory in the customization section

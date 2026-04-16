# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This repo **is** an Agent Skill — it is not an application. There is no build, no test suite, no lint tooling, no package.json. The "code" is markdown: `SKILL.md` plus templates in `references/`. It gets installed into other projects via `npx add-skill Astro-Han/karpathy-llm-wiki` and then executed by whatever agent runtime loads it (Claude Code, Cursor, Codex, etc.).

When you run the skill in *this* repo during development, `raw/` and `wiki/` directories are normally runtime artifacts that only exist in downstream user projects — **except when you operate this repo as your own dogfood wiki.** In that mode they exist here; see "Operating your own wiki (dogfood mode)" below. They are gitignored so they do not ship via `npx add-skill`.

## Canonical vs. derived files

- `SKILL.md` is the canonical specification of skill behavior. Workflow rules (Ingest / Query / Lint semantics, cascade updates, date conventions) live here and only here.
- `references/*.md` hold the **exact file formats** (raw, article, index, archive). Never duplicate these formats inside `SKILL.md` — `SKILL.md` should point to them.
- `README.md` is marketing-facing. When skill behavior changes, update `SKILL.md` first; only touch `README.md` if user-visible claims or the Quick Start change.
- `examples/` is sample output from a real production wiki, used as a demo — do not treat it as authoritative for format details (`references/` is).
- `WIKI-ARCHITECTURE-DECISIONS.md` is a client-specific design doc (Bauer Foundations integration). It is not part of the skill itself — changes there do not imply skill changes.

## Key architectural distinctions to preserve

- **Wiki model, not RAG.** Knowledge is compiled once into durable markdown pages during Ingest. Do not introduce suggestions to re-retrieve from `raw/` at Query time.
- **`raw/` is immutable.** Ingest writes to it; nothing else modifies it. Queries never read from it.
- **`wiki/` is one level deep only** — `wiki/<topic>/<article>.md`. Do not propose nested topic trees.
- **Path conventions differ by context.** Inside wiki files, links are relative to the current file. In conversation output (citations), paths are project-root-relative. This asymmetry is intentional — preserve it in any edits.
- **Three operations, strict file-write rules.** Ingest writes `index.md` + `log.md`. Archive (from Query) writes both. Lint writes `log.md` (and `index.md` only when auto-fixing). Plain Query writes nothing. Don't blur these boundaries.

## Editing SKILL.md

The frontmatter `description` field is what agent runtimes use to decide when to trigger the skill. Changes to it affect activation behavior across every tool the skill is installed in — treat it like a public API.

Lint's two-tier structure (deterministic auto-fix vs. heuristic report-only) is load-bearing. New checks must be placed in the correct tier; a heuristic check that auto-fixes would silently rewrite user content.

## Operating your own wiki (dogfood mode)

You are both the builder of this skill and its first user. You maintain `raw/` and `wiki/` in this repo as your own working knowledge base — a place to ingest documentation for the tools you work with, compile articles, run queries, and package workflows into reusable skills as they prove out.

You follow `SKILL.md` exactly. The wiki is one level deep (`wiki/<topic>/<article>.md`). Links inside wiki files are relative markdown links, not `[[wikilinks]]`. Three operations only: Ingest, Query, Lint. `references/` is the authoritative format spec; `examples/` shows what real-world articles and indexes look like — use both.

When you hit something `SKILL.md` doesn't provide — a missing operation, an awkward convention, a gap you wish worked differently — don't quietly do it your own way. File a page under `wiki/issues/` describing the gap, and propose the change to `SKILL.md` through the normal edit flow. The whole point of dogfooding is that your frustrations become real signal for improving the skill.

`raw/` and `wiki/` are gitignored in this repo. They are your private knowledge base, not something downstream users should inherit when they install the skill.

The specific sources you will ingest, the checklist for validating the setup, and the roadmap of skills you want to package are not frozen in this file. They live in `wiki/index.md` once you scaffold the wiki, because that content changes as you learn.

## Workflow

For multi-step work — a new feature, a meaningful refactor, a chunk of wiki integration — use the full superpowers flow: brainstorm → write a plan → execute. Don't skip straight to editing.

For bugs and unexpected behavior, use systematic-debugging before proposing fixes.

Before claiming something is done, use verification-before-completion. In most repos this means running tests. Here it means running Lint per `SKILL.md` and reading the resulting `log.md` to confirm the operation succeeded. Test-driven development has a similar analog: there are no code tests to fail, so the "failing test" is a `wiki/issues/` page, a broken-link case, or a checklist item you can't satisfy yet.

Changes to this CLAUDE.md file go through `claude-md-management:revise-claude-md` rather than ad-hoc edits. That keeps the document from drifting every time the conversation wanders.

## Behavioral guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This repo **is** an Agent Skill — it is not an application. There is no build, no test suite, no lint tooling, no package.json. The "code" is markdown: `SKILL.md` plus templates in `references/`. It gets installed into other projects via `npx add-skill Astro-Han/karpathy-llm-wiki` and then executed by whatever agent runtime loads it (Claude Code, Cursor, Codex, etc.).

When you run the skill in *this* repo during development, `raw/` and `wiki/` directories do not exist and should not be created — they are runtime artifacts that only exist in downstream user projects.

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

# CLAUDE.md Merge — Implementation Plan

## Context

The repo has two competing framings in play. The current `CLAUDE.md` describes this project as a skill under development. A newly drafted schema frames the same repo as the agent's own dogfood wiki — a place the agent uses to learn the skill by actually running it, catch gaps, and package proven workflows into new skills.

In brainstorming we resolved four questions (full reasoning in `docs/superpowers/specs/2026-04-16-claude-md-merge-design.md`):

- The repo stays **dual-purpose** — skill development *and* agent's wiki coexist. Skill-dev rules govern `SKILL.md`, `references/`, `README.md`, `examples/`. Wiki-operation rules govern the new `raw/` and `wiki/`. Two contexts, one CLAUDE.md, cleanly partitioned.
- The agent **dogfoods** the skill. It follows `SKILL.md` exactly. When it hits a gap, it files a `wiki/issues/` page and proposes a `SKILL.md` change — it doesn't silently diverge.
- **Moderate workflow integration** — a short Workflow section naming brainstorm → plan → execute, systematic-debugging for bugs, verification-before-completion mapped to "run Lint and read log.md" (since this repo has no tests).
- **Defer ephemera** — the draft's 8-source list, 12-item self-test checklist, and 4-skill roadmap stay out of CLAUDE.md. They'll live in `wiki/index.md` once phase three scaffolds the wiki.

This plan covers **phase one only**: edit `CLAUDE.md`, add two lines to `.gitignore`. Phase two (`.claude/` settings) and phase three (scaffold + ingest) get their own brainstorms and plans.

## Files to change

- `/workspaces/karpathy-llm-wiki/CLAUDE.md` — one small edit + two new sections
- `/workspaces/karpathy-llm-wiki/.gitignore` — add `raw/` and `wiki/`

No other files touched.

## Step-by-step

### Step 1 — Amend §"What this repository is"

In `CLAUDE.md`, replace the second paragraph (the one starting "When you run the skill in *this* repo during development…") so it acknowledges the dogfood exception:

```
When you run the skill in *this* repo during development, `raw/` and `wiki/` directories are normally runtime artifacts that only exist in downstream user projects — **except when you operate this repo as your own dogfood wiki.** In that mode they exist here; see "Operating your own wiki (dogfood mode)" below. They are gitignored so they do not ship via `npx add-skill`.
```

### Step 2 — Insert §"Operating your own wiki (dogfood mode)"

In `CLAUDE.md`, insert this new section after §"Editing SKILL.md" and before §"Behavioral guidelines":

```
## Operating your own wiki (dogfood mode)

You are both the builder of this skill and its first user. You maintain `raw/` and `wiki/` in this repo as your own working knowledge base — a place to ingest documentation for the tools you work with, compile articles, run queries, and package workflows into reusable skills as they prove out.

You follow `SKILL.md` exactly. The wiki is one level deep (`wiki/<topic>/<article>.md`). Links inside wiki files are relative markdown links, not `[[wikilinks]]`. Three operations only: Ingest, Query, Lint. `references/` is the authoritative format spec; `examples/` shows what real-world articles and indexes look like — use both.

When you hit something `SKILL.md` doesn't provide — a missing operation, an awkward convention, a gap you wish worked differently — don't quietly do it your own way. File a page under `wiki/issues/` describing the gap, and propose the change to `SKILL.md` through the normal edit flow. The whole point of dogfooding is that your frustrations become real signal for improving the skill.

`raw/` and `wiki/` are gitignored in this repo. They are your private knowledge base, not something downstream users should inherit when they install the skill.

The specific sources you will ingest, the checklist for validating the setup, and the roadmap of skills you want to package are not frozen in this file. They live in `wiki/index.md` once you scaffold the wiki, because that content changes as you learn.
```

### Step 3 — Insert §"Workflow"

In `CLAUDE.md`, insert this new section immediately after §"Operating your own wiki (dogfood mode)" and before §"Behavioral guidelines":

```
## Workflow

For multi-step work — a new feature, a meaningful refactor, a chunk of wiki integration — use the full superpowers flow: brainstorm → write a plan → execute. Don't skip straight to editing.

For bugs and unexpected behavior, use systematic-debugging before proposing fixes.

Before claiming something is done, use verification-before-completion. In most repos this means running tests. Here it means running Lint per `SKILL.md` and reading the resulting `log.md` to confirm the operation succeeded. Test-driven development has a similar analog: there are no code tests to fail, so the "failing test" is a `wiki/issues/` page, a broken-link case, or a checklist item you can't satisfy yet.

Changes to this CLAUDE.md file go through `claude-md-management:revise-claude-md` rather than ad-hoc edits. That keeps the document from drifting every time the conversation wanders.
```

### Step 4 — Update `.gitignore`

Append to `/workspaces/karpathy-llm-wiki/.gitignore`:

```
# Agent's dogfood wiki — private to this repo, do not ship via `npx add-skill`
raw/
wiki/
```

### Step 5 — Copy the plan to the repo's plans directory

Write this plan file to `/workspaces/karpathy-llm-wiki/docs/superpowers/plans/2026-04-16-claude-md-merge.md` so the spec and plan live together in the repo. (Per writing-plans skill convention.)

### Step 6 — Commit (only on explicit go-ahead)

Do **not** auto-commit. If the user says to commit, stage the three modified files plus the spec and plan docs, and write a commit message along the lines of:

```
docs: expand CLAUDE.md with dogfood-wiki mode and workflow section
```

## Verification

End-to-end check after Steps 1–5:

1. Read `/workspaces/karpathy-llm-wiki/CLAUDE.md` start to finish. Confirm section order:
   - `# CLAUDE.md` (header)
   - `## What this repository is` — second paragraph shows the amended text from Step 1
   - `## Canonical vs. derived files` — unchanged
   - `## Key architectural distinctions to preserve` — unchanged
   - `## Editing SKILL.md` — unchanged
   - `## Operating your own wiki (dogfood mode)` — new, matches Step 2 text
   - `## Workflow` — new, matches Step 3 text
   - `## Behavioral guidelines` — unchanged from the Karpathy content
2. Read `/workspaces/karpathy-llm-wiki/.gitignore`. Confirm the existing four entries are intact and the new block from Step 4 is appended.
3. `git status` should show exactly two modified files (`CLAUDE.md`, `.gitignore`) plus two new files under `docs/superpowers/` (the spec from earlier + the plan from Step 5). Nothing else.
4. No changes to `SKILL.md`, `references/`, `README.md`, or `examples/`.

## Explicitly out of scope

- No edits to `SKILL.md`, `references/`, `README.md`, or `examples/`.
- No `.claude/` changes (that's phase two).
- No scaffolding of `raw/` or `wiki/`, no ingesting any source (that's phase three).
- No sources list, checklist, or skills roadmap committed to CLAUDE.md (per decision D3).
- The pre-existing markdown-lint warnings (MD032/MD031/MD040) inside the Karpathy section stay as-is. Fixing them means reformatting content the user pasted verbatim, which violates the "match existing style" rule. Flag and revisit separately if desired.

## Risks / things easy to get wrong

- **Section ordering.** The two new sections must sit between §"Editing SKILL.md" and §"Behavioral guidelines" in that order. Inserting in the wrong place breaks the document's flow.
- **The dogfood escape hatch has to stay prominent.** If the "file a `wiki/issues/` page and propose a `SKILL.md` change" instruction gets buried, the agent will silently invent its own conventions and the feedback loop collapses.
- **The `.gitignore` line is load-bearing for distribution.** Missing it means the agent's private notes ship to every downstream user of this skill. Easy oversight; high consequence.
- **Preserve existing sections verbatim.** Only §"What this repository is" gets an edit. The other three existing sections should be untouched — don't "improve" adjacent text under the guise of the same commit.

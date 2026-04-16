# Topic-Isolated Indexes — Design

**Date:** 2026-04-16
**Scope:** Single change to how the wiki stores its index files and how the Ingest operation touches topic folders. Deliberately narrow — scale features like topic metadata and agent teams are explicit follow-ups, not part of this spec.

## What we're doing

Right now SKILL.md defines one global `wiki/index.md` that lists every article grouped under topic headings, and the Ingest operation's cascade step scans across topics for cross-references it should add. The wiki-ingester we just built faithfully followed those rules during its first real run — and the result exposed a pattern we don't want long-term. A single ingest writes to both its own topic and the shared global index, cascade logic suggests edits in unrelated topic folders, and as the number of topics grows the global index becomes a bottleneck for reading, navigating, and reasoning about a single topic's contents.

This spec replaces that with a two-part change: split the index file along topic boundaries, and tighten ingest behavior so one ingest only ever touches one topic folder.

## The two changes, and why they go together

**Split the index.** Each topic folder gets its own `index.md` that lists only that topic's articles. The top-level `wiki/index.md` shrinks to a topic directory — one row per topic, with a short description and a link into the topic's own index. Mental model: the top-level file is a table of chapters; each per-topic file is a chapter's table of contents.

**Tighten ingest to one topic.** The Ingest operation's Cascade step becomes same-topic only. Scanning other topics for cross-references is removed from Ingest entirely. Cross-topic See Also additions are no longer a side effect of ingesting — they become a deliberate, separate act. The wiki-linter already surfaces missing cross-topic connections as heuristic findings; that channel becomes the primary way gaps are noticed and decided on.

Doing only one of the two would feel wrong in opposite ways. Splitting indexes but keeping cross-topic cascade means topics look independent but still silently edit each other during ingests. Tightening cascade but keeping the global index means topics aren't actually isolated — the single biggest "view of the wiki" file still mixes them. Together, the two changes express one principle: each topic is a self-contained book, and cross-topic connections are an editorial decision made outside the Ingest flow.

## What the new structure looks like

Same disk layout rules — `wiki/` is still one level deep, articles still live at `wiki/<topic>/<article>.md`. The difference is the index files:

- `wiki/index.md` — top-level. One row per topic. Columns: topic name (as a markdown link pointing at the topic's `index.md`), short description, and optionally an Updated date reflecting when any article in the topic last changed. That's it. No article rows at this level.
- `wiki/<topic>/index.md` — per-topic. Looks like what today's `wiki/index.md` holds for a single topic: a title, a short description of the topic, and an Articles table with columns for the article link, one-line summary, and Updated date.
- `wiki/log.md` — unchanged. Still the single append-only operation log at the wiki root.

## How Ingest behaves under the new rules

A single ingest touches exactly one topic folder. The subagent (1) saves the raw source into `raw/<topic>/`, (2) writes or merges the compiled article into `wiki/<topic>/`, (3) updates that topic's `index.md`, (4) appends one line to `wiki/log.md`. Two narrow exceptions exist. First, when the ingest introduces a genuinely new topic that doesn't exist yet, it also adds one row to the top-level `wiki/index.md` with a short description of the new topic. Second, Initialization still scaffolds the empty `wiki/index.md` (heading only) and `wiki/log.md` (heading only) on first run — that part is unchanged.

Cascade Updates apply only within the same topic folder. The existing "scan `wiki/index.md` entries in other topics for articles covering related concepts" step is removed. See Also additions across topics no longer happen as part of Ingest.

Query and Lint both adapt naturally. Query reads the top-level `index.md` to locate the relevant topic, then reads the topic's `index.md` to find articles, then reads the articles themselves. Lint's deterministic "index consistency" check splits into two — the top-level index is compared to the actual set of topic folders, and each topic's `index.md` is compared to the articles in its folder. Heuristic findings (including missing cross-topic references) are unchanged.

## Performance properties worth preserving

The design keeps ingest, query, and lint costs proportional to the topic being worked on, not to the total size of the wiki. An ingest into a topic with 5 articles reads that topic's 5-entry index regardless of whether the wiki has 2 topics or 400. The top-level index stays small (one short row per topic) even at many topics — 400 rows of one-line-each markdown is a trivial file to read. Cross-topic cascade was the operation that scaled with wiki size; removing it is the biggest perf improvement this change delivers.

## Files that change

The following files change — most of them small edits.

- `SKILL.md`. §Architecture describes the split. §Initialization wording clarified (same behavior, just phrased around the new shape). §Cascade Updates loses its cross-topic step. §Post-Ingest specifies writing to the topic's index and only touching the top-level index when a new topic is created. §Conventions gets a one-line reinforcement of "one ingest, one topic."
- `references/index-template.md` splits into two files. `index-template.md` becomes the template for the top-level topic directory. A new `topic-index-template.md` becomes the template for a single topic's index. SKILL.md's pointers to the templates update accordingly.
- `.claude/agents/wiki-linter.md`. Its Index consistency deterministic check is rewritten to cover the two-level structure: top-level index vs actual topic folders, and each topic's index vs articles in that folder. The rest of the agent stays.
- `CLAUDE.md`. The one line in §Key architectural distinctions that says `wiki/` is one level deep gets a small amendment noting each topic also holds its own `index.md`.
- `README.md`. If the marketing copy describes the old single-index model, it gets reconciled. This is user-facing so the claim must match reality.
- `.claude/agents/wiki-ingester.md` does not need editing. It preloads the karpathy-llm-wiki skill, so the updated SKILL.md rules flow through automatically on next reload.

## Migration of the existing two-topic wiki

Three file operations, no article bodies touched.

1. Create `wiki/claude-code/index.md` holding the four existing claude-code rows (overview, extensions, subagents, hooks) in the topic-index format.
2. Create `wiki/llm-wiki/index.md` holding the one existing llm-wiki row (llm-wiki-pattern) in the same format.
3. Rewrite `wiki/index.md` down to a two-row topic directory: `claude-code` and `llm-wiki`, each with a short description and a link to the topic's own index.

Nothing else moves. The article files, the raw files, the log, and the hooks all stay where they are.

## Verification

End-to-end check after the changes land.

- `wiki/index.md` is short — two topic rows and no article rows.
- `wiki/claude-code/index.md` exists and lists the four claude-code articles with correct Updated dates.
- `wiki/llm-wiki/index.md` exists and lists the one llm-wiki article.
- Running the wiki-linter shows zero deterministic findings. Heuristic findings still surface the missing cross-topic See Also between `llm-wiki-pattern.md` and the `claude-code/` articles — we deliberately leave that unaddressed because cross-topic linking is now a separate editorial step.
- A fresh test ingest of one Claude Code URL lands in `wiki/claude-code/` only, adds one row to `wiki/claude-code/index.md`, does not touch `wiki/llm-wiki/index.md`, and does not touch `wiki/index.md` (because claude-code already exists as a topic).
- A fresh test ingest of a source in a genuinely new topic creates a new topic folder, creates its `index.md`, and adds exactly one row to the top-level `wiki/index.md`.

## Explicitly out of scope

Several scale-related ideas were raised alongside this design. They are deliberately not part of this spec and should be handled as separate specs when the need is concrete.

- **Topic metadata.** Adding structured fields like language, tools, type, last-active-date to topics. Valuable for discoverability once the wiki has tens or hundreds of topics. Not needed at two topics. Future spec when we feel the pain.
- **Category groupings or two-level navigation.** If the top-level topic directory ever gets too long to scan, we can add a categorization layer. A flat list works fine for now and for a long while.
- **A dedicated "connect" or "relate" operation.** Automating the cross-topic See Also additions that the wiki-linter flags heuristically. Premature until manual editorial passes feel like toil.
- **Agent teams.** We have `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set, so teams are available, but we haven't hit a concrete workflow where teams outperform subagents. The transition signal per the subagents reference article is "parallel subagents hitting context limits or needing to talk to each other" — we have neither. Build teams when a specific workflow demands them, not as a generic upgrade.
- **README.md marketing expansion.** If the README needs broader updates for any reason, do those in a separate pass. This spec only touches README.md to reconcile claims about the index shape.
- **Search or query operations against topic metadata.** Depends on metadata existing. Follow-up work.

## Non-obvious invariants worth calling out

- The Ingest operation still writes to `wiki/log.md` exactly once per ingest. Log format is unchanged. The log is the cross-topic chronological record; moving it into topic folders would destroy that property.
- Lint's existing two-tier structure (deterministic auto-fix vs heuristic report-only) is preserved. Cross-topic findings remain heuristic by design — they don't become deterministic just because Ingest stopped adding them.
- The wiki-ingester's system prompt does not need editing because it preloads the skill. This is the first concrete payoff of the `skills: [karpathy-llm-wiki]` design decision — a skill-level rule change propagates to all subagents that preload the skill on their next spawn.
- The `examples/` directory already hints at the per-topic pattern (cross-refs in example articles point at `../<topic>/_index.md`-style paths). This change aligns SKILL.md with that existing intent rather than diverging from it, which is also why we're not renaming — `index.md` in each topic stays simple and conventional.

## References

- Current `SKILL.md` at HEAD commit.
- Current `references/index-template.md`.
- Current `wiki/index.md` with `llm-wiki` and `claude-code` topic sections.
- Wiki-linter report from 2026-04-16 that surfaced the hallucinated See Also link and the cross-topic gap.
- [Custom Subagents](/workspaces/karpathy-llm-wiki/wiki/claude-code/subagents.md) and [Hooks Reference](/workspaces/karpathy-llm-wiki/wiki/claude-code/hooks.md) — used the `skills:` preload pattern and `SubagentStop` hook that validate the wiki-ingester approach used in this design's verification steps.

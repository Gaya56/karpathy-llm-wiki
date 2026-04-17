# CLAUDE.md Merge — Design

**Date:** 2026-04-16

## What we're doing

The repo already has a CLAUDE.md that describes this project as a skill under development. You drafted a second CLAUDE.md that frames the repo as the agent's own wiki — a place where the agent learns by doing, tests every feature, and turns its learnings into skills.

The two drafts contradict each other in several places (whether `raw/` and `wiki/` should exist here, what the directory layout looks like, which wikilink syntax to use, etc.). This phase merges them into one document that keeps the existing skill-development rules and adds the "agent operates its own wiki here" framing on top.

This is phase one of three. Phase two updates `.claude/` settings and agents. Phase three scaffolds the wiki and starts ingesting sources. Each phase gets its own brainstorm and plan.

## The four decisions we made

We resolved four questions in brainstorming:

First, the repo stays dual-purpose. It's still the skill being developed, and it's also the agent's own dogfood wiki. The existing rules (about `SKILL.md`, `references/`, and so on) stay authoritative for the skill files. The new rules govern the `raw/` and `wiki/` directories the agent creates. Two contexts, one CLAUDE.md, cleanly separated.

Second, the agent dogfoods the skill. When the agent operates its wiki, it follows `SKILL.md` exactly — one level deep, relative links, three operations (Ingest, Query, Lint). The `examples/` directory shows what that looks like in practice. If the agent ever wants something the skill doesn't provide (a `Compile` operation, `[[wikilinks]]`, typed subdirectories), it doesn't just use them. It writes a `wiki/issues/` page explaining the gap and proposes a change to `SKILL.md`. That way the dogfood loop actually catches things.

Third, the workflow section stays moderate. The new plugins (`superpowers`, `claude-md-management`) mostly work by auto-triggering from their own descriptions, so CLAUDE.md doesn't need to repeat them. What it does need is a short section that names the main flow (brainstorm → plan → execute for big work, systematic-debugging for bugs) and maps the generic guidance to this repo. "Verification before completion" normally means running tests — this repo has none, so it means running Lint and reading `log.md`. "Write a failing test first" has no tests here either, so the analog is a failing `wiki/issues/` page or a broken-link case.

Fourth, we don't freeze the specific sources list, checklist, or skills roadmap in CLAUDE.md. The draft had an 8-source list, a 12-item self-test checklist, and a 4-skill roadmap. All useful, but they're phase-three artifacts — the wiki will produce them as living content in its own `index.md` once it exists. Putting them in CLAUDE.md means paying tokens on every conversation for content that'll be outdated by the time it matters.

## What the merged CLAUDE.md looks like

Same sections as today, in the same order, plus two new ones.

The existing five sections stay: the header, "What this repository is", "Canonical vs. derived files", "Key architectural distinctions to preserve", and "Editing SKILL.md". One line in "What this repository is" needs a small tweak: it currently says `raw/` and `wiki/` shouldn't exist in this repo, which is about to be wrong. We change it to say they shouldn't exist *except* when the agent is dogfooding, and point at the new section.

The first new section is "Operating your own wiki (dogfood mode)". It explains that the agent is both builder and first user of the skill, that it follows `SKILL.md` exactly, that the `references/` directory is the authoritative format spec and `examples/` shows what real articles look like, and that the escape hatch for gaps is a `wiki/issues/` page plus a proposed `SKILL.md` change. It also notes that `raw/` and `wiki/` are gitignored here and that the specific sources, checklist, and skills roadmap will live in `wiki/index.md` once phase three scaffolds it.

The second new section is "Workflow". It names the brainstorm → plan → execute flow, says to use systematic-debugging for bugs, maps "verification before completion" and TDD to this markdown-only repo, and says CLAUDE.md edits should go through `claude-md-management:revise-claude-md` rather than ad-hoc.

The Karpathy behavioral guidelines (already there) stay at the end.

## The gitignore part

This one matters. The repo is distributed via `npx add-skill Astro-Han/karpathy-llm-wiki`, which means anything committed here gets shipped to every downstream user. If the agent creates its own `raw/` and `wiki/` and those aren't gitignored, users installing the skill would inherit the agent's private notes, research scraps, and half-compiled articles. That's obviously wrong.

So phase one also adds `raw/` and `wiki/` to `.gitignore`. Small change, load-bearing.

## What this phase doesn't touch

No changes to `SKILL.md`, `references/`, `README.md`, or `examples/`. No changes to `.claude/`. No scaffolding of `raw/` or `wiki/`. No ingesting anything. No freezing a sources list.

We also leave the markdown-lint warnings in the existing Karpathy section alone. They were introduced when we appended the user's draft content verbatim, and fixing them means reformatting content the user provided as-is — which runs against the "match existing style, don't improve adjacent content" rule. If you want them fixed, say so and we'll do it in a separate commit.

## Things that would be easy to get wrong

A few spots where it'd be easy to drift:

The dogfood escape hatch has to be prominent enough that the agent actually uses it. If `Operating your own wiki` buries the "file a `wiki/issues/` page and propose a `SKILL.md` change" instruction in a list, the agent will quietly invent its own conventions the first time it hits a gap, and the whole feedback loop collapses.

The two contexts (skill development vs. wiki operation) have to apply to disjoint files. Skill rules govern `SKILL.md`, `references/`, `README.md`, `examples/`. Wiki rules govern `raw/` and `wiki/`. No file should be governed by both — if we get that wrong, edits start cascading unpredictably.

The `.gitignore` line is more important than it looks. Without it, the skill's distribution is broken.

## References

The existing CLAUDE.md at HEAD (commit `2bba51b`). The draft schema passed inline as the argument to `/superpowers:brainstorming`. The `examples/` directory for real-world article structure. `references/` for the authoritative format specs. Plugins installed: `superpowers` 5.0.7, `claude-md-management`, `andrej-karpathy-skills`.

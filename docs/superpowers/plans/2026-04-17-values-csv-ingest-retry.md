# Values-in-the-Wild CSV Ingest — Retry Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the tabular-source gap the first ingest exposed, then re-run the same ingest cleanly and compare v1 vs v2 to confirm the fix.

**Architecture:** The v1 ingest of `values_frequencies.csv` produced a good wiki article and a good raw sidecar, but failed to land the CSV itself in `raw/` because `Bash(cp:*)` was not pre-approved for the background subagent and the Read→Write fallback blew the token budget. Fix has two prongs: (1) permission fix — add `Bash(cp:*)` and `Bash(mv:*)` to `permissions.allow`; (2) skill fix — add one paragraph to SKILL.md §Ingest §Fetch formalising that **raw data stays raw**: binary/tabular sources are copied verbatim into `raw/` with a markdown sidecar for metadata. Then snapshot v1, roll back, reload, rerun, diff.

**Tech Stack:** Claude Code `.claude/settings.json` permissions, SKILL.md markdown edit, `wiki-ingester` background subagent, shell (`cp`, `mv`, `rm`, `diff`), the `/reload-plugins` slash command.

---

## Files touched

| File | Action |
|------|--------|
| `.claude/settings.json` | Add `Bash(cp:*)` and `Bash(mv:*)` to `permissions.allow` |
| `SKILL.md` | Insert one paragraph in §Ingest §Fetch about binary/tabular raw handling |
| `/tmp/v1-values-ingest/` | New scratch snapshot directory (ephemeral, not tracked) |
| `wiki/anthropic-research/` | Snapshot then delete (wiki article + per-topic index) |
| `raw/anthropic-research/` | Snapshot then delete (markdown sidecar only in v1; v2 will also have the CSV) |
| `wiki/index.md` | Edit — remove the v1 anthropic-research row for a clean retest |
| `values_frequencies.csv` (repo root) | Leave in place — still the source input for the v2 run |

No touches to `CLAUDE.md`, `.gitignore`, `references/`, any agent, or any hook script. Two in-flight memory files (`feedback_pre-approve-subagent-permissions.md`, `project_wiki-infrastructure.md`) may need a one-line refresh post-run if the outcome differs meaningfully from what they describe; evaluate at the end, not upfront.

---

## Task 1: Snapshot v1 output for later comparison

The main point of this plan is to *compare*, so v1 has to be preserved before we delete it.

**Files:**
- Create: `/tmp/v1-values-ingest/wiki-index.md`
- Create: `/tmp/v1-values-ingest/topic-index.md`
- Create: `/tmp/v1-values-ingest/article.md`
- Create: `/tmp/v1-values-ingest/raw-sidecar.md`

- [ ] **Step 1.1: Create the snapshot directory**

```bash
mkdir -p /tmp/v1-values-ingest
```

- [ ] **Step 1.2: Copy all four v1 outputs**

```bash
cp /workspaces/karpathy-llm-wiki/wiki/index.md /tmp/v1-values-ingest/wiki-index.md
cp /workspaces/karpathy-llm-wiki/wiki/anthropic-research/index.md /tmp/v1-values-ingest/topic-index.md
cp /workspaces/karpathy-llm-wiki/wiki/anthropic-research/values-in-the-wild.md /tmp/v1-values-ingest/article.md
cp /workspaces/karpathy-llm-wiki/raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.md /tmp/v1-values-ingest/raw-sidecar.md
```

- [ ] **Step 1.3: Verify all four files are present and non-empty**

```bash
ls -la /tmp/v1-values-ingest/ && wc -l /tmp/v1-values-ingest/*.md
```

Expected: four files listed, none zero-byte, roughly 75 / 7 / 75 / 66 lines respectively (matching what was observed in the session transcript).

---

## Task 2: Add `cp` and `mv` to the allow list

This is the permission that blocked v1's subagent from landing the CSV in `raw/`.

**Files:**
- Modify: `/workspaces/karpathy-llm-wiki/.claude/settings.json`

- [ ] **Step 2.1: Read the current file to confirm its exact state**

```
Read /workspaces/karpathy-llm-wiki/.claude/settings.json
```

Confirm `Bash(curl:*)` immediately precedes `WebFetch` in the `allow` array (that pair will be the Edit anchor).

- [ ] **Step 2.2: Edit — insert `Bash(cp:*)` and `Bash(mv:*)` between `Bash(curl:*)` and `WebFetch`**

old_string:
```
      "Bash(curl:*)",
      "WebFetch"
```

new_string:
```
      "Bash(curl:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "WebFetch"
```

- [ ] **Step 2.3: Verify the edit landed correctly**

```bash
grep -E '"Bash\((cp|mv|curl)' /workspaces/karpathy-llm-wiki/.claude/settings.json
```

Expected: three lines — `Bash(curl:*)`, `Bash(cp:*)`, `Bash(mv:*)`.

---

## Task 3: Add the tabular/binary-source paragraph to SKILL.md

One paragraph, surgical, inserted right after the `references/raw-template.md` pointer in §Ingest §Fetch. The paragraph codifies the user's constraint — *raw data stays raw* — and gives the ingester an explicit recipe for CSV/JSON/Parquet/image sources.

**Files:**
- Modify: `/workspaces/karpathy-llm-wiki/SKILL.md`

- [ ] **Step 3.1: Edit SKILL.md**

old_string:
```
   See `references/raw-template.md` for the exact format.

### Compile (wiki/)
```

new_string:
```
   See `references/raw-template.md` for the exact format.

**Binary or tabular sources (CSV, JSON, Parquet, images, etc.).** The raw artifact is the source file itself — copy it verbatim into `raw/<topic>/YYYY-MM-DD-descriptive-slug.<ext>` with no modification. Alongside it, create a markdown sidecar at `raw/<topic>/YYYY-MM-DD-descriptive-slug.md` carrying the same metadata header (Source URL, Collected, Published) plus a Schema section for tabular sources. The compiled wiki article references both — sidecar for context, raw file for the full data. When the source is too large to inline, sample a representative preview in the wiki article and point at the raw file for the complete content.

### Compile (wiki/)
```

- [ ] **Step 3.2: Verify the paragraph is present and formatted correctly**

```bash
grep -A1 "Binary or tabular sources" /workspaces/karpathy-llm-wiki/SKILL.md
```

Expected: the heading line plus the next line of the paragraph.

---

## Task 4: Roll back v1 so the retest starts clean

Two directory deletes and one line removed from `wiki/index.md`. `Bash(rm -rf:*)` is in `deny`, so we use plain `rm -r` (user will see a prompt and approve).

**Files:**
- Delete: `/workspaces/karpathy-llm-wiki/wiki/anthropic-research/` (recursively)
- Delete: `/workspaces/karpathy-llm-wiki/raw/anthropic-research/` (recursively)
- Modify: `/workspaces/karpathy-llm-wiki/wiki/index.md`

- [ ] **Step 4.1: Remove the two topic directories**

```bash
rm -r /workspaces/karpathy-llm-wiki/wiki/anthropic-research /workspaces/karpathy-llm-wiki/raw/anthropic-research
```

- [ ] **Step 4.2: Edit `wiki/index.md` — remove the v1 anthropic-research row**

old_string:
```
| [openclaw](openclaw/index.md) | Open-source AI assistant platform built on Anthropic's Claude Agent SDK — gateway architecture, multi-channel deployment, and multi-model support | 2026-04-16 |
| [anthropic-research](anthropic-research/index.md) | Anthropic research outputs — datasets, papers, and technical reports on Claude's behavior, values, and capabilities | 2026-04-17 |
```

new_string:
```
| [openclaw](openclaw/index.md) | Open-source AI assistant platform built on Anthropic's Claude Agent SDK — gateway architecture, multi-channel deployment, and multi-model support | 2026-04-16 |
```

- [ ] **Step 4.3: Verify clean state**

```bash
ls /workspaces/karpathy-llm-wiki/wiki/ | grep anthropic || echo "(no wiki anthropic dir — good)"
ls /workspaces/karpathy-llm-wiki/raw/ | grep anthropic || echo "(no raw anthropic dir — good)"
grep anthropic /workspaces/karpathy-llm-wiki/wiki/index.md || echo "(no anthropic row in top-level index — good)"
```

Expected: three "(good)" confirmations.

---

## Task 5: Reload plugins so the ingester picks up the new SKILL.md

The `wiki-ingester` subagent has `skills: [karpathy-llm-wiki]` in its frontmatter — it preloads SKILL.md at spawn time. Without a reload it would run v2 under the v1 SKILL.md rules and the whole test is invalidated.

**Files:** none (runtime-only).

- [ ] **Step 5.1: Ask the user to run `/reload-plugins`**

This is a user-only slash command; Claude cannot invoke it. Message the user:

> Ready for the rerun. Please run `/reload-plugins` so the wiki-ingester picks up the new SKILL.md, then tell me when it's done.

- [ ] **Step 5.2: Wait for user confirmation before proceeding.** Do not spawn the subagent until the user confirms the reload completed.

---

## Task 6: Respawn the wiki-ingester on the same CSV

Identical source, identical topic. The only things that should differ from v1 are: (a) the CSV actually lands in `raw/`, (b) the article/sidecar language reflects the new SKILL.md paragraph.

**Files:** none at this step (the subagent will write its own).

- [ ] **Step 6.1: Confirm the CSV source is still at the repo root**

```bash
ls -lh /workspaces/karpathy-llm-wiki/values_frequencies.csv
```

Expected: 81 KB file, unchanged from v1.

- [ ] **Step 6.2: Spawn `wiki-ingester` via the Agent tool with `run_in_background: true`.**

Prompt contents:

```
Ingest this local CSV file into the wiki under topic `anthropic-research` (will be a new topic — no existing directory).

Source file: /workspaces/karpathy-llm-wiki/values_frequencies.csv (81 KB, 3,308 lines)

Source metadata:
- Dataset: Anthropic/values-in-the-wild on Hugging Face
- URL: https://huggingface.co/datasets/Anthropic/values-in-the-wild
- Published by: Anthropic
- License: CC-BY-4.0
- Companion paper: "Values in the Wild: Discovering and Analyzing Values in Real-World Language Model Interactions" (Anthropic, 2025)
- What it is: 3,307 distinct values Claude expressed across real-world conversations, paired with frequency (% of conversations).

This is a binary/tabular source. Per SKILL.md §Ingest §Fetch, raw data stays raw:
1. Copy the CSV verbatim into raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.csv (no modification to the bytes).
2. Create a markdown sidecar at raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.md with source metadata + schema + a top-N preview.
3. Compile a wiki article at wiki/anthropic-research/values-in-the-wild.md describing the dataset, with a top-30 sample inline and a pointer to the raw CSV for the full table.
4. This is a new topic: create wiki/anthropic-research/index.md and add one row to wiki/index.md.
5. Log one line to wiki/log.md.

Write a clean final summary — the SubagentStop hook will capture it.
```

- [ ] **Step 6.3: Wait for the completion notification.** Do not proactively poll the output file.

---

## Task 7: Verify the fix and compare v1 vs v2

**Files:** none modified here (read-only verification + diff).

- [ ] **Step 7.1: Confirm the CSV landed in raw/ verbatim**

```bash
ls -la /workspaces/karpathy-llm-wiki/raw/anthropic-research/ && \
  wc -l /workspaces/karpathy-llm-wiki/raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.csv && \
  diff /workspaces/karpathy-llm-wiki/values_frequencies.csv /workspaces/karpathy-llm-wiki/raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.csv && echo "CSV bytes unchanged — raw stayed raw."
```

Expected: both `.csv` and `.md` present in the directory; CSV line count 3,308; `diff` emits nothing and the echo line fires.

- [ ] **Step 7.2: Diff each of the four markdown outputs against v1**

```bash
diff /tmp/v1-values-ingest/wiki-index.md /workspaces/karpathy-llm-wiki/wiki/index.md || true
echo "=== topic index ==="
diff /tmp/v1-values-ingest/topic-index.md /workspaces/karpathy-llm-wiki/wiki/anthropic-research/index.md || true
echo "=== article ==="
diff /tmp/v1-values-ingest/article.md /workspaces/karpathy-llm-wiki/wiki/anthropic-research/values-in-the-wild.md || true
echo "=== raw sidecar ==="
diff /tmp/v1-values-ingest/raw-sidecar.md /workspaces/karpathy-llm-wiki/raw/anthropic-research/2026-04-17-values-in-the-wild-frequencies.md || true
```

(`|| true` keeps the chain going even when a diff is non-empty.)

- [ ] **Step 7.3: Run the wiki-linter foreground to confirm zero deterministic issues**

Spawn `wiki-linter` via the Agent tool (foreground, not background). Prompt:

```
Lint the wiki at /workspaces/karpathy-llm-wiki/wiki. Report findings in the standard two-section format (Auto-fixed / For review). Pay special attention to the new raw/anthropic-research/ directory — verify that the wiki article's Raw field link and the sidecar's reference to the CSV both resolve.
```

Expected: zero deterministic findings. Heuristic findings may still include the cross-topic See Also gap (deliberately deferred by design — that's expected signal).

- [ ] **Step 7.4: Write a one-paragraph v1-vs-v2 comparison for the user.**

Cover: (a) did the CSV land in `raw/` unchanged? (b) which of the four markdown files are identical between v1 and v2, which differ, and are the differences meaningful? (c) any gaps the linter surfaced. Do not commit yet — let the user review and decide whether the result merits a commit.

---

## Verification (self-review before calling done)

Run through this checklist mentally before reporting the task complete:

1. **Permission fix landed.** `.claude/settings.json` `allow` array contains both `Bash(cp:*)` and `Bash(mv:*)`; `Bash(curl:*)` still present; `Bash(rm -rf:*)` still in `deny`.
2. **SKILL.md note landed.** One new paragraph starting `**Binary or tabular sources...**` appears between the raw-template reference and `### Compile (wiki/)`. Surrounding text untouched.
3. **Clean rollback succeeded.** Before spawning v2, neither `wiki/anthropic-research/` nor `raw/anthropic-research/` exist, and `wiki/index.md` is back to three topic rows.
4. **Reload happened.** User explicitly confirmed `/reload-plugins`. This is not optional — running v2 without it invalidates the whole test.
5. **CSV bytes preserved.** `diff` between the repo-root CSV and the copy in `raw/` produces no output. The bytes are byte-for-byte identical. Raw data stayed raw.
6. **Wiki structure coherent.** Linter runs clean; both indexes list the new topic and article; the wiki article's Raw field points at the `.md` sidecar (not the `.csv`); the sidecar itself references the `.csv` by name.
7. **Comparison report is substantive.** The v1-vs-v2 report names specific files that differ and says whether the differences are meaningful (e.g., new CSV pointer in article, different wording in observations section) or cosmetic.

---

## Risks and easy-to-get-wrong spots

- **Skipping the reload is silent.** The subagent will happily run v2 on the old SKILL.md and produce output that looks correct but doesn't test anything. Task 5 is load-bearing. If the user doesn't confirm, do not spawn.
- **`rm -rf` is blocked, `rm -r` isn't.** `rm -r` will still prompt the user. Don't try to work around it — wait for approval. Do not edit settings.json to add `Bash(rm:*)` mid-plan; out of scope.
- **`Bash(cp:*)` must exist in `allow` before the subagent spawns.** If Task 2 is skipped or fails, v2 will reproduce v1's failure exactly — the subagent will auto-deny `cp`, fall back to Read→Write, and fail on the CSV's token budget. Do Task 2 before Task 6.
- **Sidecar filename collision.** The sidecar and the CSV share the same `YYYY-MM-DD-descriptive-slug` stem — only the extensions differ (`.md` vs `.csv`). That is intentional and documented in SKILL.md §Ingest §Fetch after Task 3. The ingester needs to pick this up; if it invents a different naming scheme in v2, flag it as a skill-gap follow-up — do not fix in this plan.
- **Diff output on the article can be very noisy.** Two LLM runs on the same source will vary word-for-word even when the ideas are identical. Don't read the raw diff as "the fix changed something" — read it as "here's what the model wrote differently this time." The CSV-presence check in Step 7.1 is the actual fix signal.
- **Don't commit at the end.** The user said "compare the outputs," not "commit." Hold for explicit go-ahead. The dogfood wiki files are un-gitignored on this branch but that does not mean they should auto-land in a commit.

---

## Out of scope

- Editing `references/raw-template.md` to add a tabular variant. Could be worth doing later, but SKILL.md's new paragraph is enough to unblock the ingester; the template only needs an update if a second CSV ingest shows the same gap.
- Adding `Bash(rm:*)`, `Bash(rmdir:*)`, or `Bash(diff:*)` to `allow`. Main-session one-off prompts are fine; no need to broaden permissions on speculation.
- Any edit to `.claude/agents/wiki-ingester.md`. The subagent inherits the new rules through the skill preload — no agent-file change needed.
- Re-ingesting any previously ingested source (Claude Code docs, Karpathy PDF, OpenClaw). This plan is strictly the values-in-the-wild retry.
- Committing or pushing. Discrete follow-up, user-gated.

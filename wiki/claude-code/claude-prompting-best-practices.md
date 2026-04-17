# Claude Prompting Best Practices

> Sources: Anthropic, Unknown
> Raw: [2026-04-17-claude-prompting-best-practices](../../raw/claude-code/2026-04-17-claude-prompting-best-practices.md)

## Overview

Anthropic's single reference for prompt engineering with Claude's latest models (Opus 4.7, Opus 4.6, Sonnet 4.6, Haiku 4.5). The guide covers foundational techniques, model-specific behavioral tuning, output and format control, tool use, thinking and reasoning, and agentic system patterns. The core tension throughout is that each new model generation is significantly more capable and responsive than its predecessor — prompts written for older models often overtrigger or under-steer newer ones, requiring active tuning rather than just upgrading the model string.

## Model-specific tuning: Claude Opus 4.7

Claude Opus 4.7 is Anthropic's most capable generally available model. It performs well on existing Opus 4.6 prompts but has behavioral shifts that require tuning in production.

**Response length and verbosity.** Opus 4.7 calibrates length to task complexity rather than defaulting to a fixed verbosity. If your product expects a certain style, add explicit length guidance. Positive examples showing appropriate concision tend to outperform negative instructions ("do not over-explain").

**Effort and thinking depth.** The effort parameter is more important for Opus 4.7 than any prior Opus. Effort levels: `max` (may show diminishing returns or overthinking), `xhigh` (best for coding and agentic use cases), `high` (balances token usage and intelligence — minimum for intelligence-sensitive work), `medium` (cost-sensitive with lower intelligence trade-off), `low` (latency-sensitive, non-intelligence-sensitive tasks). At `max` or `xhigh`, set a large max output token budget — start at 64k tokens. If you observe shallow reasoning on complex problems, raise effort rather than prompting around it.

**Tool use triggering.** Opus 4.7 uses tools less often than Opus 4.6 and relies more on reasoning. Raising effort is the primary lever to increase tool usage. At `high` or `xhigh`, tool usage in agentic search and coding increases substantially. When a specific tool is still undertriggered, add explicit prompt guidance about when and how to use it.

**Literal instruction following.** Opus 4.7 interprets prompts more literally and will not silently generalize an instruction from one item to another. State scope explicitly: "Apply this formatting to every section, not just the first one."

**Subagent spawning.** Opus 4.7 spawns fewer subagents by default than Opus 4.6. This is steerable — add explicit guidance about when subagents are and are not warranted.

**Design and frontend defaults.** Opus 4.7 has a persistent default house style (warm cream backgrounds, serif display type, terracotta/amber accent). Generic "don't use cream" instructions tend to shift to a different fixed palette. Two reliable approaches: (1) specify a concrete alternative with explicit color palette, typography, layout; (2) ask the model to propose design options before building. Opus 4.7 also generates distinctive frontends with less prompting than prior models — a minimal frontend aesthetics prompt is usually sufficient.

**Code review harnesses.** Opus 4.7 follows conservative prompts more literally. If your harness says "only report high-severity issues," the model may investigate thoroughly but suppress low-severity findings — raising precision but potentially lowering recall. Adjust to "report every issue you find, including ones you are uncertain about or consider low-severity... your goal is coverage."

**Interactive coding products.** Opus 4.7 uses more tokens in interactive settings because it reasons more after user turns. To maximize both performance and token efficiency: use `xhigh` or `high` effort, add autonomous features, reduce required human interactions, and specify task, intent, and constraints upfront in the first human turn.

## General principles

**Be clear and direct.** Think of Claude as a brilliant but new employee who lacks context on your norms. Specificity about desired output format and constraints is the most reliable lever. Golden rule: show your prompt to a colleague with minimal context — if they'd be confused, Claude will be too.

**Add context and motivation.** Explaining *why* a constraint exists helps Claude generalize it correctly. "Never use ellipses since the text-to-speech engine will not know how to pronounce them" outperforms "NEVER use ellipses."

**Use examples effectively.** Few-shot/multishot prompting is one of the most reliable ways to steer output format, tone, and structure. Make examples relevant, diverse (covering edge cases), and structured (wrapped in `<example>` / `<examples>` tags). 3–5 examples is the recommended range.

**Structure with XML tags.** XML tags help Claude parse complex prompts that mix instructions, context, examples, and variable inputs. Use consistent, descriptive tag names. Nest tags for hierarchical content.

**Give Claude a role.** A single sentence in the system prompt ("You are a helpful coding assistant specializing in Python.") focuses behavior and tone.

**Long context prompting.** For 20k+ token inputs: put longform data at the top of the prompt (queries at the end can improve response quality by up to 30% on complex multi-document inputs); structure documents in `<document>` tags with `<document_content>` and `<source>` subtags; ask Claude to quote relevant passages before carrying out the task.

## Output and formatting

**Claude's latest models are more concise and direct.** They may skip verbal summaries after tool calls. If you need more visibility: "After completing a task that involves tool use, provide a quick summary of the work you've done."

**Steer format positively.** "Your response should be composed of smoothly flowing prose paragraphs" outperforms "Do not use markdown." You can also use XML format indicators: "Write the prose sections in `<smoothly_flowing_prose_paragraphs>` tags." Matching your prompt style to the desired output style also works — removing markdown from your prompt can reduce markdown in output.

**Migrating away from prefilled responses.** Starting with Claude 4.6 models, prefilled responses on the last assistant turn are deprecated. Migrations:
- Format control: use Structured Outputs or ask the model to conform to the schema directly
- Eliminating preambles: "Respond directly without preamble. Do not start with phrases like 'Here is...'"
- Continuations: move the continuation to the user message with the final text from the interrupted response
- Context hydration: inject reminders into the user turn, or hydrate via tools for agentic systems

## Tool use

**Explicit action instructions.** Claude's latest models follow instructions precisely, which means "Can you suggest some changes?" gets suggestions, not implementations. To get action, be direct: "Change this function to improve its performance." You can add a system-level prompt to make Claude proactive by default (`<default_to_action>`) or conservative by default (`<do_not_act_before_instructions>`).

**Parallel tool calling.** Claude's latest models excel at parallel tool execution and do so without prompting in most cases. To guarantee parallel execution or adjust aggression, use an explicit `<use_parallel_tool_calls>` system prompt block. To reduce parallelism: "Execute operations sequentially with brief pauses between each step."

**Overtriggering in Opus 4.5 / 4.6.** These models are more responsive to the system prompt than previous generations. Prompts designed to combat undertriggering may now cause overtriggering. Dial back aggressive language — replace "CRITICAL: You MUST use this tool when..." with "Use this tool when...".

## Thinking and reasoning

**Adaptive thinking (Opus 4.6, Sonnet 4.6).** These models use `thinking: {type: "adaptive"}` — Claude dynamically decides when and how much to think based on the `effort` parameter and query complexity. In internal evaluations, adaptive thinking reliably outperforms extended thinking. Use `effort` to control thinking depth. `budget_tokens` is still functional on these models but deprecated.

**Migrating from extended thinking.** Replace `thinking: {type: "enabled", budget_tokens: N}` with `thinking: {type: "adaptive"}` and `output_config: {effort: "high"}`. If not using extended thinking, no changes are required — thinking is off by default when the `thinking` parameter is omitted.

**Overthinking in Opus 4.6.** At higher effort settings, Opus 4.6 does extensive upfront exploration. Tune guidance: replace blanket defaults with targeted instructions, remove over-prompting, and use effort as the primary throttle. If you still see excessive thinking: "When you're deciding how to approach a problem, choose an approach and commit to it. Avoid revisiting decisions unless you encounter new information that directly contradicts your reasoning."

**General thinking tips.** Prefer general instructions ("think thoroughly") over prescriptive step-by-step plans. Multishot examples work with thinking — use `<thinking>` tags inside few-shot examples. When thinking is off, use structured `<thinking>` and `<answer>` tags for manual chain-of-thought. Ask Claude to self-check against test criteria before finishing.

## Agentic systems

**Context awareness and long-horizon tasks.** Claude 4.6 and 4.5 track their remaining context window (token budget). If your harness compacts context or saves to external files, tell Claude explicitly so it doesn't try to wrap up work prematurely. Pair with the memory tool for seamless context transitions.

**Multi-context window workflows.** For tasks spanning multiple context windows: use the first window to set up a test and script framework; have Claude write structured state files (e.g., `tests.json` for test tracking); create setup scripts that can replay server/test initialization from scratch; consider starting fresh context windows over compaction where possible (Claude's latest models recover state effectively from the filesystem and git log); provide verification tools (Playwright MCP, computer use) for correctness checking without continuous human feedback.

State management: use JSON for structured data (test results, task status), freeform text for progress notes, and git for checkpointing. Emphasize incremental progress.

**Autonomy and safety.** Without guidance, Opus 4.6 may take hard-to-reverse actions. Add explicit guidance about which categories of actions require user confirmation (destructive operations, force-pushes, shared-system operations) and a prohibition on using destructive shortcuts when encountering obstacles.

**Research tasks.** Define clear success criteria, encourage source verification across multiple sources. For complex research: prompt for structured approach with competing hypotheses, confidence tracking, and a hypothesis tree or research notes file.

**Subagent orchestration.** Claude's latest models delegate to specialized subagents proactively. Guide this by ensuring well-defined subagent tools with descriptive definitions and letting Claude orchestrate naturally. Opus 4.6 has a strong predilection for subagents and may spawn them when a direct approach would suffice — add explicit guidance if seeing excessive spawning: "Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that don't need to share state. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly rather than delegating."

**Overeagerness and overengineering.** Opus 4.5 and 4.6 tend to create extra files, add unnecessary abstractions, and build in unrequested flexibility. Add a scoping prompt: only make changes that are directly requested or clearly necessary; don't add docstrings/comments to code you didn't change; don't create helpers for one-time operations.

**Minimizing hallucinations.** "Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering."

## Migration considerations (4.6 models)

1. Be specific about desired behavior — describe exactly what you want to see
2. Use modifiers that encourage quality and detail in instructions
3. Request specific features (animations, interactivity) explicitly
4. Update thinking configuration to adaptive thinking with the effort parameter
5. Migrate away from prefilled responses
6. Dial back anti-laziness prompting — Claude 4.6 is significantly more proactive than prior models and may overtrigger on instructions designed for them

**Sonnet 4.5 → Sonnet 4.6**: Sonnet 4.6 defaults to `high` effort; Sonnet 4.5 had no effort parameter. Set effort explicitly — `medium` for most applications, `low` for latency-sensitive workloads. Set large max output token budget (64k recommended) at medium or high effort. For the hardest, longest-horizon tasks, prefer Opus 4.7.

## See Also

- [Custom Subagents](subagents.md) — subagent configuration, background mode, and spawning patterns referenced in agentic orchestration guidance
- [Extending Claude Code](extensions.md) — where prompting fits within the broader extension surface (CLAUDE.md, Skills, MCP, Hooks)
- [Claude Code Overview](overview.md) — product-level context; model and capability overview
- [Settings and Configuration](settings.md) — effort level persistence (`effortLevel`), model overrides, and `alwaysThinkingEnabled` settings

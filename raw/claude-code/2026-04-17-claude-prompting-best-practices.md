# Prompting best practices

> Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
> Collected: 2026-04-17
> Published: Unknown

Comprehensive guide to prompt engineering techniques for Claude's latest models, covering clarity, examples, XML structuring, thinking, and agentic systems.

This is the single reference for prompt engineering with Claude's latest models, including Claude Opus 4.7, Claude Opus 4.6, Claude Sonnet 4.6, and Claude Haiku 4.5. It covers foundational techniques, output control, tool use, thinking, and agentic systems.

## Prompting Claude Opus 4.7

Claude Opus 4.7 is Anthropic's most capable generally available model, with particular strengths in long-horizon agentic work, knowledge work, vision, and memory tasks. It performs well out of the box on existing Claude Opus 4.6 prompts.

### Response length and verbosity

Claude Opus 4.7 calibrates response length to how complex it judges the task to be, rather than defaulting to a fixed verbosity. To decrease verbosity:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

Positive examples showing appropriate concision tend to be more effective than negative examples or "do not" instructions.

### Calibrating effort and thinking depth

The effort parameter tunes intelligence vs. token spend:

- **`max`**: Max effort for intelligence-demanding tasks; may show diminishing returns or overthinking
- **`xhigh`** (new): Best for most coding and agentic use cases
- **`high`**: Balances token usage and intelligence; minimum for most intelligence-sensitive use cases
- **`medium`**: Cost-sensitive use cases trading off intelligence
- **`low`**: Short, scoped, latency-sensitive, non-intelligence-sensitive tasks

Claude Opus 4.7 respects effort levels strictly, especially at the low end. At `low` and `medium`, the model scopes its work to what was asked. If you observe shallow reasoning on complex problems, raise effort to `high` or `xhigh` rather than prompting around it. At `max` or `xhigh` effort, set a large max output token budget (start at 64k tokens).

Adaptive thinking triggering is steerable. To reduce unwanted thinking:

```
Thinking adds latency and should only be used when it will meaningfully improve answer quality — typically for problems that require multi-step reasoning. When in doubt, respond directly.
```

### Tool use triggering

Claude Opus 4.7 tends to use tools less often than Claude Opus 4.6 and uses reasoning more. Increasing the effort setting is a useful lever to increase tool usage, especially in knowledge work. `high` or `xhigh` effort settings show substantially more tool usage in agentic search and coding.

### User-facing progress updates

Claude Opus 4.7 provides more regular, higher-quality updates to the user throughout long agentic traces. Remove scaffolding that forces interim status messages if you previously added it.

### More literal instruction following

Claude Opus 4.7 interprets prompts more literally and explicitly than Claude Opus 4.6, particularly at lower effort levels. It will not silently generalize an instruction from one item to another. State scope explicitly: "Apply this formatting to every section, not just the first one."

### Tone and writing style

Claude Opus 4.7 is more direct and opinionated, with less validation-forward phrasing and fewer emoji than Claude Opus 4.6's warmer style. For warmer tone:

```
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```

### Controlling subagent spawning

Claude Opus 4.7 tends to spawn fewer subagents by default. Steer with explicit guidance:

```
Do not spawn a subagent for work you can complete directly in a single response (e.g. refactoring a function you can already see).

Spawn multiple subagents in the same turn when fanning out across items or reading multiple files.
```

### Design and frontend defaults

Claude Opus 4.7 has a consistent default house style: warm cream/off-white backgrounds (~`#F4F1EA`), serif display type (Georgia, Fraunces, Playfair), italic word-accents, terracotta/amber accent. This is persistent. Two approaches work reliably:

1. Specify a concrete alternative with explicit color palette, typography, layout specs
2. Have the model propose options before building (breaks the default, gives users control)

Claude Opus 4.7 generates distinctive frontends with more minimal prompting guidance than prior models. This prompt snippet works well:

```
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white or dark backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character. Use unique fonts, cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

### Interactive coding products

Claude Opus 4.7 tends to use more tokens in interactive settings primarily because it reasons more after user turns. To maximize performance and token efficiency: use `xhigh` or `high` effort, add autonomous features, and reduce the number of required human interactions. Specify task, intent, and constraints upfront in the first human turn.

### Code review harnesses

Claude Opus 4.7 has meaningfully better bug-finding (11pp better recall in Anthropic's evals), but follows conservative prompts more literally. If your harness says "only report high-severity issues," the model may investigate thoroughly but not report lower-severity findings. Recommended prompt language:

```
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage - a separate verification step will do that. Your goal here is coverage: it is better to surface a finding that later gets filtered out than to silently drop a real bug. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```

### Computer use

Computer use capability works across resolutions, up to a new maximum of 2576px / 3.75MP. Sending images at 1080p provides a good balance of performance and cost.

## General principles

### Be clear and direct

Claude responds well to clear, explicit instructions. Think of Claude as a brilliant but new employee who lacks context on your norms and workflows.

**Golden rule:** Show your prompt to a colleague with minimal context on the task. If they'd be confused, Claude will be too.

- Be specific about the desired output format and constraints
- Provide instructions as sequential steps using numbered lists or bullet points when order or completeness matters

Example: "Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation." outperforms "Create an analytics dashboard."

### Add context to improve performance

Providing motivation behind instructions helps Claude better understand your goals:

Less effective: `NEVER use ellipses`

More effective: `Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.`

Claude is smart enough to generalize from the explanation.

### Use examples effectively

A few well-crafted examples (few-shot/multishot prompting) can dramatically improve accuracy and consistency. Make examples:

- **Relevant:** Mirror your actual use case
- **Diverse:** Cover edge cases, vary enough that Claude doesn't pick up unintended patterns
- **Structured:** Wrap in `<example>` tags (multiple in `<examples>` tags)

Include 3–5 examples for best results.

### Structure prompts with XML tags

XML tags help Claude parse complex prompts unambiguously. Wrap each content type in its own tag (`<instructions>`, `<context>`, `<input>`). Nest tags for hierarchical content (documents inside `<documents>`, each in `<document index="n">`).

### Give Claude a role

Setting a role in the system prompt focuses Claude's behavior and tone. Even a single sentence makes a difference:

```python
system="You are a helpful coding assistant specializing in Python."
```

### Long context prompting

For large documents or data-rich inputs (20k+ tokens):

- **Put longform data at the top**: Place documents near the top of your prompt, above your query, instructions, and examples. Queries at the end can improve response quality by up to 30%.
- **Structure with XML tags**: Wrap each document in `<document>` tags with `<document_content>` and `<source>` subtags.
- **Ground responses in quotes**: Ask Claude to quote relevant parts of documents first before carrying out the task.

### Model self-knowledge

If you need Claude to identify itself correctly:

```
The assistant is Claude, created by Anthropic. The current model is Claude Opus 4.7.
```

## Output and formatting

### Communication style and verbosity

Claude's latest models are more concise and natural: more direct, more conversational, less verbose. Claude may skip verbal summaries after tool calls. To get more visibility:

```
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

### Control the format of responses

1. **Tell Claude what to do instead of what not to do**: "Your response should be composed of smoothly flowing prose paragraphs" beats "Do not use markdown."
2. **Use XML format indicators**: "Write the prose sections in `<smoothly_flowing_prose_paragraphs>` tags."
3. **Match your prompt style to the desired output style**: Removing markdown from your prompt can reduce markdown in output.
4. **Provide explicit guidance for specific formatting preferences**: A detailed prose-over-bullets prompt works for long-form content.

### LaTeX output

Claude Opus 4.6 defaults to LaTeX for mathematical expressions. To get plain text:

```
Format your response in plain text only. Do not use LaTeX, MathJax, or any markup notation such as \( \), $, or \frac{}{}. Write all math expressions using standard text characters (e.g., "/" for division, "*" for multiplication, and "^" for exponents).
```

### Migrating away from prefilled responses

Starting with Claude 4.6 models, prefilled responses on the last assistant turn are no longer supported (Mythos Preview returns a 400 error). Migration paths:

- **Controlling output formatting**: Use Structured Outputs or ask the model to conform to the schema directly
- **Eliminating preambles**: "Respond directly without preamble. Do not start with phrases like 'Here is...', 'Based on...', etc."
- **Avoiding bad refusals**: Claude is much better at appropriate refusals now; clear prompting in the user message is sufficient
- **Continuations**: Move to the user message with "Your previous response was interrupted and ended with `[previous_response]`. Continue from where you left off."
- **Context hydration**: For long conversations, inject reminders into the user turn; for agentic systems, hydrate via tools

## Tool use

### Tool usage

For Claude to take action rather than suggest: be explicit. "Change this function to improve its performance" rather than "Can you suggest some changes to improve this function?"

To make Claude proactive about action by default:

```
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing.
</default_to_action>
```

To make Claude more conservative:

```
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action.
</do_not_act_before_instructions>
```

Claude Opus 4.5 and 4.6 are more responsive to the system prompt than previous models — if prompts were designed to reduce undertriggering, these models may now overtrigger. Dial back aggressive language: use "Use this tool when..." instead of "CRITICAL: You MUST use this tool when...".

### Optimize parallel tool calling

Claude's latest models excel at parallel tool execution. To boost to ~100% or adjust aggression:

```
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

To reduce parallel execution: "Execute operations sequentially with brief pauses between each step to ensure stability."

## Thinking and reasoning

### Overthinking and excessive thoroughness

Claude Opus 4.6 does significantly more upfront exploration than previous models, especially at higher effort settings. Tune guidance:

- Replace blanket defaults with targeted instructions: "Use [tool] when it would enhance your understanding of the problem" instead of "Default to using [tool]"
- Remove over-prompting: tools that undertriggered in previous models likely trigger appropriately now
- Use effort as a fallback: lower effort setting to reduce overall thinking and token usage

```
When you're deciding how to approach a problem, choose an approach and commit to it. Avoid revisiting decisions unless you encounter new information that directly contradicts your reasoning. If you're weighing two approaches, pick one and see it through.
```

`budget_tokens` cap is still functional on Opus 4.6 and Sonnet 4.6 but deprecated. Prefer lowering the effort setting or using `max_tokens` as a hard limit with adaptive thinking.

### Leverage thinking and interleaved thinking

Claude Opus 4.6 and Claude Sonnet 4.6 use adaptive thinking (`thinking: {type: "adaptive"}`), where Claude dynamically decides when and how much to think based on the `effort` parameter and query complexity. In internal evaluations, adaptive thinking reliably drives better performance than extended thinking.

Migrating from extended thinking with `budget_tokens`:

Before (extended thinking):
```python
client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=64000,
    thinking={"type": "enabled", "budget_tokens": 32000},
    messages=[{"role": "user", "content": "..."}],
)
```

After (adaptive thinking):
```python
client.messages.create(
    model="claude-opus-4-7",
    max_tokens=64000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},
    messages=[{"role": "user", "content": "..."}],
)
```

Additional thinking tips:
- Prefer general instructions over prescriptive steps — "think thoroughly" often beats a hand-written plan
- Multishot examples work with thinking: use `<thinking>` tags inside few-shot examples
- Manual CoT as fallback when thinking is off: use structured `<thinking>` and `<answer>` tags
- Ask Claude to self-check: "Before you finish, verify your answer against [test criteria]"

When extended thinking is disabled, Claude Opus 4.5 is sensitive to the word "think" and variants; consider "consider," "evaluate," or "reason through" instead.

## Agentic systems

### Long-horizon reasoning and state tracking

Claude 4.6 and 4.5 models feature context awareness — the model tracks its remaining context window (token budget) throughout a conversation.

If using a harness that compacts context or allows saving to external files:

```
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

The memory tool pairs naturally with context awareness for seamless context transitions.

### Multi-context window workflows

For tasks spanning multiple context windows:

1. Use the first context window to set up a framework (write tests, create setup scripts), then iterate on a todo-list in future windows
2. Have the model write tests in a structured format (e.g., `tests.json`) before starting work; track status persistently
3. Set up quality-of-life tools: encourage Claude to create setup scripts (e.g., `init.sh`) to start servers and run test suites
4. Consider starting fresh vs. compacting — Claude's latest models are extremely effective at discovering state from the local filesystem
5. Provide verification tools for correctness (Playwright MCP server, computer use capabilities)
6. Encourage complete usage of context: "This is a very long task... It's encouraged to spend your entire output context working on the task — just make sure you don't run out of context with significant uncommitted work."

State management best practices:
- Use structured formats (JSON) for test results and task status
- Use unstructured text for progress notes
- Use git for state tracking — provides a log and checkpoints that can be restored
- Emphasize incremental progress: ask Claude to keep track of progress and focus on incremental work

### Balancing autonomy and safety

Without guidance, Claude Opus 4.6 may take actions that are difficult to reverse. To require confirmation before risky actions:

```
Consider the reversibility and potential impact of your actions. You are encouraged to take local, reversible actions like editing files or running tests, but for actions that are hard to reverse, affect shared systems, or could be destructive, ask the user before proceeding.

Examples of actions that warrant confirmation:
- Destructive operations: deleting files or branches, dropping database tables, rm -rf
- Hard to reverse operations: git push --force, git reset --hard, amending published commits
- Operations visible to others: pushing code, commenting on PRs/issues, sending messages, modifying shared infrastructure
```

### Research and information gathering

For optimal research results:
1. Provide clear success criteria
2. Encourage source verification across multiple sources
3. For complex research, use a structured approach with competing hypotheses, confidence tracking, and a hypothesis tree or research notes file

### Subagent orchestration

Claude's latest models recognize when tasks benefit from specialized subagents and delegate proactively without explicit instruction.

To guide this behavior:
1. Ensure well-defined subagent tools with good descriptions
2. Let Claude orchestrate naturally
3. Watch for overuse — Claude Opus 4.6 has a strong predilection for subagents and may spawn them when a direct approach would suffice

If seeing excessive subagent use:

```
Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that don't need to share state. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly rather than delegating.
```

### Chain complex prompts

With adaptive thinking and subagent orchestration, Claude handles most multi-step reasoning internally. Explicit prompt chaining is still useful when you need to inspect intermediate outputs or enforce a specific pipeline structure.

The most common chaining pattern: generate a draft → review against criteria → refine based on review. Each step is a separate API call so you can log, evaluate, or branch.

### Reduce file creation in agentic coding

Claude's latest models may create new files for testing and iteration purposes. To minimize net new file creation:

```
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

### Overeagerness

Claude Opus 4.5 and 4.6 have a tendency to overengineer — creating extra files, adding unnecessary abstractions, building in unrequested flexibility. To minimize:

```
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused:
- Scope: Don't add features, refactor code, or make "improvements" beyond what was asked.
- Documentation: Don't add docstrings, comments, or type annotations to code you didn't change.
- Defensive coding: Don't add error handling, fallbacks, or validation for scenarios that can't happen.
- Abstractions: Don't create helpers or utilities for one-time operations.
```

### Avoid focusing on passing tests and hard-coding

```
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs.
```

### Minimizing hallucinations in agentic coding

```
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase.
</investigate_before_answering>
```

## Capability-specific tips

### Improved vision capabilities

Claude Opus 4.5 and 4.6 have improved vision capabilities, performing better on image processing and data extraction with multiple images. Performance tip: give Claude a crop tool or skill so it can "zoom in" on relevant regions of an image.

### Frontend design

Claude Opus 4.5 and 4.6 excel at building complex web applications. Without guidance, models default to generic patterns ("AI slop" aesthetic). Prompt snippet for distinctive frontends:

```
<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. Avoid this: make creative, distinctive frontends that surprise and delight.

Focus on:
- Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter.
- Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency.
- Motion: Use animations for effects and micro-interactions.
- Backgrounds: Create atmosphere and depth rather than defaulting to solid colors.

Avoid: overused font families (Inter, Roboto, Arial, system fonts), clichéd color schemes (particularly purple gradients), predictable layouts, cookie-cutter design.
</frontend_aesthetics>
```

## Migration considerations

When migrating to Claude 4.6 models from earlier generations:

1. Be specific about desired behavior — describe exactly what you'd like to see
2. Frame instructions with modifiers encouraging quality and detail
3. Request specific features (animations, interactive elements) explicitly
4. Update thinking configuration: use adaptive thinking (`thinking: {type: "adaptive"}`) instead of manual `budget_tokens`
5. Migrate away from prefilled responses (deprecated starting Claude 4.6)
6. Tune anti-laziness prompting: dial back guidance that was needed for previous models, as Claude 4.6 is significantly more proactive

### Migrating from Claude Sonnet 4.5 to Claude Sonnet 4.6

Claude Sonnet 4.6 defaults to `high` effort (Sonnet 4.5 had no effort parameter). Consider adjusting:

- **Medium** for most applications
- **Low** for high-volume or latency-sensitive workloads
- Set large max output token budget (64k tokens recommended) at medium or high effort

For the hardest, longest-horizon problems, Opus 4.7 remains the right choice; Sonnet 4.6 is optimized for fast turnaround and cost efficiency.

If using extended thinking with `budget_tokens` on Sonnet 4.5, migrate to adaptive thinking with the effort parameter. A budget around 16k tokens provides headroom during migration while deprecated configuration is still functional.

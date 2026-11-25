---
name: deep-research
description: Use this skill when the user's prompt requires (1) researching a topic across multiple sources, comparing options or alternatives, analyzing trends or history, understanding markets or industries, or reviewing literature or studies and (2) synthesizing that research into the personal knowledge vault (~/code/go/src/github.com/stringy/notes). If you're planning to search the web or internal knowledge bases, consider using this skill. This skill coordinates research subagents, so use it only when you have a tool for spawning subagents (the Agent or Task tool); otherwise, research the question directly.
---

# Coordinating Deep Research

## Your Role

You are acting as the **coordinator**. Your job is to analyze the user's question, spawn subagents, and manage the distillation of their findings into the knowledge vault. In order to keep your context clean, you should never conduct research or write files directly. For the same reason, you also should not read the researcher.md or vault-writer.md files.

As you work, if you have a to-do or task-list tool (for example TodoWrite, or TaskCreate and TaskUpdate), use it to keep the user informed of your plan and progress. For clarity, don't reference subagents in those items. For example, you might say "Conduct research" instead of "Spawn research subagents".

## Process

1. [If necessary] Ask the user follow up questions
2. Choose a title for this research and create its scratch folder
3. Decompose the user's query to determine subagent count
4. Spawn research subagents (in parallel)
5. [If absolutely necessary] Conduct one additional round of research
6. Spawn vault writer subagent
7. Clean up scratch and deliver summary to user

### 1. [If necessary] Ask the user follow up questions

Read the user's question and consider if there are any missing or ambiguous details that need to be clarified. Some examples include:
- Ambiguous terminology — Acronyms, jargon, or terms with multiple meanings across different fields
- Implicit geographic or jurisdictional context — Questions where the answer varies significantly by region but no region is specified
- Ambiguous entities — Company names, product names, or proper nouns that refer to multiple distinct entities

In order to avoid creating unnecessary friction with the user, follow ups should only be asked when they would meaningfully impact how research is conducted.

If you determine that you do need to ask follow up questions, do so with the AskUserQuestion tool.

### 2. Choose a title for this research and create its scratch folder

First choose a title for this research. It names the scratch folder that will hold this request's research notes, so make it a short, specific title for this research in the user's language and in sentence case: 3 to 6 words and under 50 characters (count them, and drop words rather than exceed either limit), using only letters, numbers and single spaces. Keep accented and non-Latin letters exactly as the user's language writes them (for example é, ñ, ü, 日本語) rather than converting to plain ASCII, and use no hyphens, underscores, apostrophes or other punctuation. For example, a question about how the EU AI Act affects startups could use "EU AI Act startup obligations".

All research scratch lives in the knowledge vault: create the folder research_notes/{research title}/ under the vault root ~/code/go/src/github.com/stringy/notes. The vault's .gitignore already covers research_notes/, and the folder is deleted once the research is distilled (step 7), so it never becomes a durable artifact. Quote these paths in shell commands, since the title contains spaces, and note the vault root's absolute path — you will give the subagents absolute paths into this folder. If research_notes/ already contains folders, they are leftovers from interrupted runs: choose a title that differs from them, and never rename, move or write into another request's folder.

If this request returns to a topic researched earlier, the durable findings live in the vault's topic pages. Check topics/README.md (the topic map, ~45 lines) for the relevant page and note its path: you will pass it to the vault writer in step 6 as background to build on, and the writer will integrate the new findings into that page. Research whatever this request adds or needs re-checked. If the user asks for the earlier research to be redone independently, do not pass the earlier page on.

### 3. Decompose the user's query to determine subagent count

In order to effectively spawn and task subagents, determine if and how the user's question can be decomposed into independent subtopics. These subtopics should be mutually exclusive and collectively exhaustive. For each subtopic, then consider if the research requires (or would benefit from) multiple independent points of view.

| Researchers | Decomposition Strategy | Example |
|-------------|------------------------|---------|
| 1 | No meaningful decomposition — single factual question | "Who won the 2024 Super Bowl?" |
| 3 | Few natural angles or perspectives on a focused topic | "Effects of temperature on salmon migration" → (1) biological mechanisms, (2) observed population data, (3) climate projections |
| 4 | Distinct facets or evaluation criteria | "Compare CRM platforms for small businesses" → (1) pricing models, (2) feature comparison, (3) integrations ecosystem, (4) user reviews/sentiment |
| 5 | Multiple independent entities, regions, or domains | "AI regulation landscape" → (1) US federal, (2) EU/GDPR-AI Act, (3) China, (4) UK, (5) industry self-regulation |
| 6+ | Large enumerable set requiring systematic coverage | "Electric vehicle adoption rates by US state" → researchers assigned to regional clusters |

In the next step, you should spawn one subagent for each subtopic and independent point of view that you identified. When in doubt, 3 researchers is a reasonable default. If in step 2 you noted earlier research to build on, decompose only what this request adds or needs re-checked; the vault writer will have the earlier material.

### 4. Spawn foreground research subagents (in parallel)

For each subtopic and independent point of view determined above, spawn a foreground research subagent.

To spawn research subagents, use the Agent tool (named Task in some versions) with subagent_type="general-purpose" and run_in_background=false. Ensure that you provide **extremely clear, specific** instructions to each research subagent. Be sure to propagate constraints of the original question to the research subagent (e.g., temporal, geographical). In the prompts below, replace {path_to_skill} with this skill's base directory (the directory this SKILL.md was loaded from), {vault root} with the vault root path noted in step 2, and {research title} with the title you chose in step 2. Follow the exact format provided below:

```
Agent(
  run_in_background=false
  subagent_type="general-purpose",
  description="{3-5 words}",
  prompt="Research {specific narrow topic}.

Objective: {clear description of what's covered in the desired output}

Key questions:
- {Specific question 1}
- {Specific question 2}

Suggested sources:
- {Types of source to prioritize}

Constraints:
- {Any bounds from the initial user query, including temporal or geographic}

Save your output notes to {vault root}/research_notes/{research title}/{topic}.md

**As a first step, you must read {path_to_skill}/references/researcher.md for instructions on how to conduct research.**"
)
```

Example of a good, clear, detailed prompt for a research subagent:

> Research the semiconductor supply chain crisis and its current status as of 2026.
>
> Objective: Compile a dense report of the facts, covering the current situation, ongoing solutions, and future outlook, with specific timelines and quantitative data where available.
>
> Key questions:
>  - What are current bottlenecks?
>  - What are the projected capacity increases from new fab construction?
>  - What are geopolitical factors affecting supply chains?
>  - When do experts predict supply will meet demand?
>
> Suggested sources:
> - Recent quarterly reports from major chip manufacturers like TSMC, Samsung, and Intel, found on investor relations pages or through the SEC EDGAR database
> - Industry reports from SEMI, Gartner, and IDC that provide market analysis and forecasts
> - Government responses, including US CHIPS Act implementation progress at commerce.gov, EU Chips Act at ec.europa.eu, and similar initiatives in Japan, South Korea, and Taiwan through their respective government portals
>
> Constraints:
> - Must reflect current state as of 2026 with prior issues clearly noted as such
>
> Save your output notes to {vault root}/research_notes/Semiconductor supply chain outlook 2026/semiconductor_supply_chain.md
>
> **As a first step, you must read {path_to_skill}/references/researcher.md for instructions on how to conduct research.**"

In order to ensure research is conducted as quickly as possible, it's essential that all subagents are spawned in parallel, i.e., that you make all your calls to the Agent tool in a single turn.

### 5. [If absolutely necessary] Conduct one additional round of research

Based on the task summaries returned by the research subagents, determine if there are any critical gaps that would make the findings incomplete. If deemed absolutely necessary, spawn researchers in parallel to close those gaps. Spawning additional researchers in this step delays delivery to the user, leading to a much worse experience, so this must be used with extreme care.

**This step can only be followed once** - after the researchers finish, move immediately to Step 6, regardless of what results you get back. If you kick off any more research, you will hit timeouts or rate limits, meaning the user will never get an answer to their query. **To help yourself remember this, you should always output "After these researchers finish, I will move directly to coordinating the vault writer" when choosing to kick off additional research.**

### 6. Spawn foreground vault writer subagent

After research is done, spawn a single vault writer subagent. Use the Agent tool (named Task in some versions) with subagent_type="general-purpose" and run_in_background=false, and fill in the placeholders as in step 4. For {the user's original question}, state the question this research must answer in full — if this request returns to or extends earlier research, that is the earlier question as amended by this request (for example "How does the EU AI Act affect startups, including penalties?"), not just the follow-up message. For earlier vault pages, give the absolute path(s) of the topic page(s) you noted in step 2, or write "none" if you noted nothing to build on or the user asked for an independent redo. Follow the exact format provided below:

```
Agent(
  run_in_background=false
  subagent_type="general-purpose",
  description="Distil research to vault",
  prompt="Read the research notes in {vault root}/research_notes/{research title}/ and distil them into the knowledge vault, answering: {the user's original question}

Earlier vault pages to build on: {absolute path(s) of the topic page(s) from step 2, or "none"}

Session date: {today's date}

**As a first step, you must read {path_to_skill}/references/vault-writer.md for instructions on how to distil research into the vault.**"
)
```

### 7. Clean up scratch and deliver summary to user

After the vault writer is done:
1. Delete the scratch folder: rm -rf "{vault root}/research_notes/{research title}" (quote the path in shell commands — the title contains spaces).
2. Run git status --short and git diff --stat with the working directory set to the vault root, and show the result. Do not commit — the user reviews and commits.
3. Send the user a brief summary (aim for 3-5 sentences) of the durable findings and the vault pages created or updated, with their absolute paths — the vault writer's final message contains both. If the vault writer found nothing durable, say so and summarize what was researched from its message.

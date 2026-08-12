---
name: daily-summary
description: Generate a daily work summary from a pre-extracted list of OpenCode sessions and append it to the daily note
tags: [notes, summary, standup, daily]
---

# Daily Summary

Generate a concise daily work summary from a list of OpenCode sessions.

## Input

The user prompt is one of:

- `/daily-summary <absolute-note-path>` — append the summary to the note at that path.
- `/daily-summary --stdout` — print the summary only; do not write any file.

The session data is supplied on stdin as a Markdown block, one bullet per
session, in the form:

```
# OpenCode sessions — YYYY-MM-DD

- <session title>  (<repo>, $<cost>)
- ...

Total: N session(s), $X.XX
```

Session titles are the primary signal — treat each as a short description of a
piece of work. The repo name shows where it happened; the cost is a rough
finger-in-the-air effort/spend indicator, not a precise figure.

## Task

1. Read the session list from stdin.
2. Group related sessions by project/repo and by topic (e.g. several
   `@explore subagent` sessions in one repo are one investigation).
3. Produce 3–5 past-tense bullet points covering the main work done. Focus on
   what was accomplished, not process. Merge duplicates.
4. Add one final line giving the day's total cost as a finger-in-the-air figure,
   e.g. `Rough spend: ~$324 (dominated by the collector segfault work).`

## Output Format

```markdown
## Daily Summary

- Point about the main work area
- Key task or investigation completed
- Another notable piece of work
- Rough spend: ~$X for the day
```

## Writing the note

- If invoked with `--stdout`, print the summary to stdout and stop.
- Otherwise, write to the absolute note path given:
  - If the file does not exist, create it with frontmatter first:
    ```markdown
    ---
    title: YYYY-MM-DD
    tags: []
    created: YYYY-MM-DD
    ---

    # YYYY-MM-DD
    ```
  - If a `## Daily Summary` section already exists, append the new bullets to it
    rather than creating a second section.
  - Otherwise append a new `## Daily Summary` section at the end.

## Style

- Concise, factual, past tense.
- No unnecessary detail; skip trivial or empty sessions.
- Group related work together rather than listing every session.

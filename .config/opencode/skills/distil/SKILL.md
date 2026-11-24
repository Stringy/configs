---
name: distil
description: Distil the current session (or a past OpenCode session) into the knowledge vault as dated evidence notes and updated living pages
tags: [notes, memory, knowledge, distil]
---

# Distil Session to Knowledge Vault

Capture the durable knowledge from a finished session into the personal knowledge
vault at `~/code/go/src/github.com/stringy/notes`, so future sessions can find it.

## Input

- `/distil` — distil the **current** session. The conversation is already in context.
  If earlier turns were compacted away, work with what remains and note any gap.
- `/distil <session-id>` — distil a **past** session from the OpenCode database.
  Extract the transcript first (see below), including child subagent sessions, which
  often hold the bulk of the findings.

Extraction commands for past sessions (DB at
`~/.local/share/opencode/opencode.db`):

```bash
# Session metadata (title, directory, dates)
sqlite3 -readonly -separator ' | ' ~/.local/share/opencode/opencode.db \
  "SELECT title, directory FROM session WHERE id = '<id>';"

# Full text transcript, in order
sqlite3 -readonly ~/.local/share/opencode/opencode.db \
  "SELECT json_extract(data, '$.text') FROM part
   WHERE session_id = '<id>' AND json_extract(data, '$.type') = 'text'
   ORDER BY time_created;"

# Child subagent sessions (distil these too)
sqlite3 -readonly -separator ' | ' ~/.local/share/opencode/opencode.db \
  "SELECT id, title FROM session WHERE parent_id = '<id>';"
```

For long sessions, extract to a file and search/read it in chunks rather than loading
everything at once.

## Task

1. **Identify durable knowledge** produced by the session: findings, verified
   conclusions, design decisions and their rationale, how-something-works
   understanding, gotchas, open questions. Ignore chat noise, process, and transient
   debugging. If there is nothing durable, say so and stop — do not create noise.

2. **Read the vault conventions first**: `~/code/go/src/github.com/stringy/notes/AGENTS.md`.
   Follow them exactly (frontmatter, tags, wikilinks, British English).

3. **Classify each piece of knowledge**:
   - Research stream or recurring investigation → living page `research/<topic>.md`
     (create or update; see the vault's `research/` conventions).
   - Understanding of a software component or subject area → living page
     `component/<name>.md` (create or update; see the vault's `component/`
     conventions).
   - Investigation findings with sources → dated evidence note
     `YYYY-MM-DD-<slug>.md` at the vault root (today's date for the current session;
     the session's date for a past session).
   - One stream can justify both a research page and a component page (e.g. a
     security audit produces attack-surface findings *and* component
     understanding) — create both and cross-link rather than forcing one.
   - Name new pages with a short, stable `snake_case` topic name.

4. **Find related pages** — always, before writing anything. Discovery must cost
   lines, not files:
   1. Read both indexes: `research/README.md` and `component/README.md` (~30 lines
      total — this is the topic map). Note every page whose description could
      relate to the new knowledge.
   2. Pick 2–4 distinctive terms from the new knowledge (project names, APIs,
      identifiers, technique names — e.g. `requestUID`, `audit ID`) and search
      for **paths only**:
      ```bash
      grep -ril "<term>" ~/code/go/src/github.com/stringy/notes/
      grep -rl "^tags:.*<tag>" ~/code/go/src/github.com/stringy/notes/
      ```
      (`rg` also works when directly available, but `grep -ril` is used here
      because it survives command-translation wrappers.)
   3. Confirm each candidate with `head -15 <file>` — frontmatter plus the
      `Related:` line is enough to decide. Follow a candidate's wikilinks one hop
      only if still uncertain.
   4. Never read full pages or the whole vault to find candidates.

5. **Write the evidence note** (when the session has investigation-style findings):
   findings with sources — URLs, `file:line` references — counterevidence,
   conclusions, open questions. Never invent a URL or `file:line`; if the source is
   the session itself, cite it as session title, date, and ID.

6. **Update the living pages**: read the existing page first. Integrate new knowledge
   into its structure — do not append a dated changelog, do not duplicate existing
   content. Bump the `updated` frontmatter date. New claims link to their evidence
   (wikilink to the dated note, or the session citation). Then:
   - Add the confirmed related pages (step 4) to this page's `Related:` line.
   - Add the reciprocal link on each related page's `Related:` line — edit only
     that line, nothing else on the page. For root notes without a `Related:`
     line, add an inline wikilink in the body instead.

7. **Update the indexes**: add new pages to `research/README.md` or
   `component/README.md`.

8. **Report**: list every file created or changed, then run `git status --short`
   and `git diff --stat` with the working directory set to the vault
   (`~/code/go/src/github.com/stringy/notes`) and show the result. Do **not**
   commit — the user reviews and commits.

## Rules

- British English in all vault prose; code identifiers and paths stay as-is.
- Preserve uncertainty and disagreements — record counterevidence, not just
  conclusions.
- Never write credentials, tokens, or customer/incident-sensitive material into the
  vault, even if the session contained them.
- Do not restructure or rewrite existing notes beyond integrating the new knowledge.
- One update per living page per distil; keep pages a synthesis, not a log.

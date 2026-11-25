---
name: distil
description: Distil the current session (or a past OpenCode session) into the knowledge vault as updated topic pages and a session summary note
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
   Follow them exactly (frontmatter, tags, inline wikilinks, British English).

3. **Route each piece of knowledge to a topic page** — the topic pages in
   `topics/` are where all content lives:
   - Understanding of a component, technology, operator, or subject area →
     `topics/<name>.md` (create or update).
   - Research stream or recurring investigation → `topics/<name>.md` with the
     `research` tag (create or update).
   - One session can justify several pages (e.g. a security audit produces
     attack-surface findings *and* component understanding) — create them and
     cross-link inline rather than forcing everything into one.
   - If no page fits, create one with a short, stable `snake_case` topic name
     rather than leaving findings homeless. A new page can start as a stub.

4. **Find related pages** — always, before writing anything. Discovery must cost
   lines, not files:
   1. Read `topics/README.md` (~30 lines — this is the topic map). Note every
      page whose description could relate to the new knowledge.
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
      `## See also` section is enough to decide. Follow a candidate's
      wikilinks one hop only if still uncertain.
   4. Never read full pages or the whole vault to find candidates.

5. **Update the topic pages**: read the existing page first. Integrate new
   knowledge into its structure — do not append a dated changelog, do not
   duplicate existing content. Bump the `updated` frontmatter date. Citations
   (`file:line` refs, URLs) go inline where the claims are made; never invent
   a URL or `file:line` — if the source is the session itself, cite it in the
   session note and link that note for provenance. Link sibling topics inline
   on first mention (see the vault's wiki-linking convention) and maintain
   the `## See also` section where it adds value. Add the reciprocal link on
   each related page — inline if the new concept is mentioned there,
   otherwise in its `## See also`; edit only what that needs, nothing else.

6. **Write the session note**: `sessions/YYYY-MM-DD-<slug>.md` — today's date
   for the current session, the session's own date for a past session. It is a
   *summary of what was discussed*, not where the findings live: a short
   recap, links to every topic page created or updated, and any open
   questions raised but not yet absorbed elsewhere. The findings themselves
   belong in the topic pages — do not duplicate them here.

7. **Update the indexes**: add new topic pages to `topics/README.md` and the
   session note to `sessions/README.md`.

8. **Report**: list every file created or changed, then run `git status --short`
   and `git diff --stat` with the working directory set to the vault
   (`~/code/go/src/github.com/stringy/notes`) and show the result. Do **not**
   commit — the user reviews and commits.

## Rules

- British English in all vault prose; code identifiers and paths stay as-is.
- Topic pages carry the content and its citations; session notes carry the
  summary and the links. Never park findings in a session note.
- Preserve uncertainty and disagreements — record counterevidence, not just
  conclusions.
- Never write credentials, tokens, or customer/incident-sensitive material into
  the vault, even if the session contained them.
- Do not restructure or rewrite existing pages beyond integrating the new
  knowledge.
- One update per topic page per distil; keep pages a synthesis, not a log.

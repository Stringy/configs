# Novel Project

## Structure

```
project/
  CLAUDE.md          — Claude editorial instructions
  bible.md           — world bible
  metadata.yaml      — author/contact details for manuscript submission
  Makefile           — build and utility targets
  chapters/          — one file per chapter
    01-chapter-name.md
    02-chapter-name.md
  notes/             — characters, timeline, research
  build/             — compiled output (gitignored)
```

## Writing chapters

- One file per chapter, prefixed with numbers for ordering: `01-name.md`, `02-name.md`
- Start each chapter with a `#` heading — this becomes the chapter title
- Use `---` (horizontal rule) for scene breaks within a chapter
- No YAML frontmatter in chapter files — just prose
- `metadata.yaml` holds title and contact details for manuscript compilation

Example chapter file:

```markdown
# The Basement

Pax stared at the file on his desk.

---

The second scene starts after the break.
```

## Make targets

```
make help          — show all targets
make wordcount     — word count per chapter and total
make today         — words written since last commit
make outline       — first heading from each chapter
make find q="word" — search across all chapters
make manuscript    — compile to Shunn manuscript format (DOCX)
make pdf           — compile to PDF
make epub          — compile to EPUB
make deps          — install pandoc and LaTeX dependencies
```

## Setup

1. Fill in `metadata.yaml` with your contact details
2. Run `make deps` once to install pandoc
3. Start writing in `chapters/`

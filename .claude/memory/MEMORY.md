# Memory

## Workflow Preferences

### Code Validation for Large Features
When working on big features with lots of file changes:
1. **Skeleton first**: Write public API, type signatures, struct definitions, and function signatures with no implementation. User validates the shape of the solution before implementation begins.
2. **Narrated diffs**: After each logical change, walk through the diff explaining decisions — why this abstraction, why this structure, what alternatives were considered. A mini code review briefing at each step.

- [Co-author lookup](feedback_coauthor_lookup.md) — Never guess co-author details; verify from git log. Credit reviewers for suggested code.

---
name: review
description: "Review changed code for correctness, cleanness, testability, idiomatic code use, documentation, and developer intent. Focuses on actionable findings only."
---

# Code Review Skill

You are reviewing code changes on the current git branch. Your goal is to produce
a focused, actionable review. Do not praise good code — only surface things that
need to change or deserve discussion.

## Step 1: Gather Context

1. Identify the merge base and diff:
   ```
   git diff --stat $(git merge-base master HEAD)..HEAD
   git diff $(git merge-base master HEAD)..HEAD
   ```
2. Read the commit messages:
   ```
   git log --format='%h %s%n%b' $(git merge-base master HEAD)..HEAD
   ```
3. Check for a linked ticket (JIRA). Look for patterns like `ROX-\d+` in:
   - The branch name (`git branch --show-current`)
   - Commit messages
   If found, fetch the ticket for context:
   ```
   WebFetch https://issues.redhat.com/browse/ROX-XXXXX
   ```
4. Read surrounding code as needed to understand the changes — but only to
   inform your understanding. The review is about the diff, not the existing code.

## Step 2: Analyse the Changes

Evaluate the diff against these criteria:

- **Correctness**: Bugs, logic errors, edge cases, off-by-one errors, race
  conditions, resource leaks, error handling gaps.
- **Cleanness**: Unnecessary complexity, duplication, dead code, poor naming,
  confusing structure.
- **Testability**: Missing tests for new behaviour, untestable design, test
  gaps for important edge cases.
- **Idiomatic code**: Language-specific conventions violated, non-standard
  patterns where standard ones exist, misuse of libraries/frameworks.
- **Documentation**: Missing or misleading comments on non-obvious behaviour,
  public API without docs, outdated comments contradicted by the code.
- **Developer intent**: Does the code actually achieve what the commit messages,
  ticket, and branch name suggest? Are there gaps between stated intent and
  implementation?

## Step 3: Report Findings

Present findings as a list, grouped by file. Each finding must include:

- **Severity**: one of:
  - `must-fix` — bugs, correctness issues, security problems
  - `should-fix` — significant quality/maintainability issues
  - `nit` — minor style or preference issues
- **Location**: file path and line number or range (from the diff)
- **Issue**: concise description of the problem
- **Suggestion**: how to fix it (code snippet if helpful)

Format:

```
## Findings

### path/to/file.go

1. **[must-fix]** L42-45: Description of the issue.
   Suggestion: how to fix it.

2. **[nit]** L80: Description of minor issue.
   Suggestion: alternative approach.

### path/to/other_file.py

1. **[should-fix]** L12: Description.
   Suggestion: fix.
```

If there are no findings, say so briefly.

End with a one-line summary: number of must-fix, should-fix, and nit findings.

## Rules

- Focus exclusively on the diff. Use surrounding code only for context.
- Do not list things that are fine. No "looks good" commentary.
- Do not repeat findings — if the same issue appears in multiple places,
  group them.
- Be concise. One or two sentences per finding is usually enough.
- If you cannot determine severity confidently, err on the side of lower severity
  and note your uncertainty.

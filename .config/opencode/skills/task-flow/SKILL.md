---
name: task-flow
description: TaskWarrior feature planning and implementation orchestration. Use when breaking a repository feature into tracked tasks, managing their dependencies, or safely parallelising disjoint implementation work.
---

# Task Flow

Use TaskWarrior as the durable record for a single repository feature. Plan work into small, independently verifiable tasks, track dependencies, and dispatch only implementation tasks whose edit surfaces are demonstrably disjoint.

## Hard Boundaries

- Never access Jira. Do not invoke `jai`, `jira`, Jira APIs, Jira MCP tools, browser searches for Jira, or update Jira tickets.
- A branch name may be read as local metadata only. Treat ticket-looking text in it as opaque; do not validate, fetch, or enrich it.
- Work in the current repository and branch. Do not create worktrees, branches, commits, rebases, merges, pushes, or pull requests unless the user explicitly asks.
- The controller owns TaskWarrior mutations. Workers must report their outcomes rather than changing task state.

## Project Selection

Derive the TaskWarrior project from the repository root:

| Repository path | Project |
| --- | --- |
| `~/code/go/src/github.com/stackrox/<repo>` | `work.<repo>` |
| `~/code/go/src/github.com/stringy/<repo>` | `personal.<repo>` |

For any other location, ask the user which TaskWarrior project to use. Never infer a project from a branch name.

## Read State

Use machine-readable output for all reads:

```bash
task project:<project> +opencode export
task project:<project> +feature-<short-uuid> export
task project:<project> +feature-<short-uuid> status:pending export
```

Use UUIDs for all updates. Do not rely on volatile numeric task IDs. Use `task ... rc.context= ...` when the active context could exclude the selected project.

## Plan a Feature

Before creating tasks, inspect the repository and produce a concise dependency graph. Ask for confirmation before creating or changing TaskWarrior tasks.

Create one feature task tagged `+opencode +feature`. Annotate it with the repository root and current branch. Find its UUID through a narrow `export` query, then derive `feature-<first-8-uuid-characters>` for all child tasks.

Each implementation task must contain:

- a specific deliverable;
- owned files or directories and any shared interfaces;
- acceptance criteria;
- a validation command;
- dependencies and explicit non-goals.

Create dependent tasks with `depends:<uuid>`. Add a final integration task that depends on every implementation task. Feature tasks are grouping records: do not use TaskWarrior's unsupported parent-child model.

Annotate material decisions, dispatches, completed validations, and blockers. Keep annotations short and factual.

## Parallelism Preflight

The shared worktree is safe for concurrent writing only when every selected task is independent. Before dispatching parallel workers, compare each pair for:

- files and directories;
- public types, APIs, schemas, and configuration contracts;
- tests and test fixtures;
- dependency manifests, lockfiles, generated files, and formatting scope.

Dispatch concurrently only if each pair has disjoint ownership and no shared interface. Otherwise, run them serially. Start with at most two concurrent writers.

Workers may modify only the files in their task brief. They must not commit, alter dependencies, run repository-wide formatters, rebase, merge, or spawn subagents. A worker that discovers extra scope reports it; the controller creates a separate task after approval.

## Execute

1. Query unblocked child tasks with `status:pending` and their feature tag.
2. Run the parallelism preflight and select one or two eligible tasks.
3. Mark each selected task started and annotate the dispatch identity.
4. Dispatch a fresh implementation subagent for each task using `/home/ghutton/.config/opencode/prompts/task-flow-worker.md` as the worker contract. Include only the task brief, applicable repository constraints, and the required report format.
5. Reconcile each worker result sequentially. Inspect its diff and run its required validation.
6. Mark a task complete only after validation passes. If it cannot proceed without external input, stop it and annotate the blocker; create a dependent unblocking task when that is actionable.
7. Run the final integration task only after every implementation task is complete.

Never dispatch a worker for a completed, started, blocked, or dependency-blocked task.

## Worker Report

Every worker report must include:

- status: complete, blocked, or needs-scope;
- changed files;
- validation command and result;
- any conflict or unplanned work discovered.

When no tasks remain, report the TaskWarrior feature UUID, completed tasks, validation performed, and unresolved blockers.

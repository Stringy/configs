---
name: task-flow
description: TaskWarrior feature planning and implementation orchestration. Use when breaking a repository feature into tracked tasks, managing their dependencies, or safely parallelising implementation work in per-task worktrees.
---

# Task Flow

Use TaskWarrior as the durable record for a single repository feature. Plan work into small, independently verifiable tasks, track dependencies, and dispatch each implementation task into its own worktree, where the worker commits to an owned task branch. The controller merges completed task branches back into the feature branch.

## Hard Boundaries

- Never access Jira. Do not invoke `jai`, `jira`, Jira APIs, Jira MCP tools, browser searches for Jira, or update Jira tickets.
- A branch name may be read as local metadata only. Treat ticket-looking text in it as opaque; do not validate, fetch, or enrich it.
- Work in the current repository and feature branch. Within the task lifecycle, the controller may create task worktrees and branches cut from the feature branch and merge them back into it; workers commit only inside their own task worktree. Do not push, open pull requests, rebase, or rewrite the feature branch history unless the user explicitly asks.
- The controller owns TaskWarrior mutations. Workers must report their outcomes rather than changing task state, with one exception: a worker appends a single completion annotation to its own task (see Worker Report). Status transitions, dependencies, and dispatch annotations remain controller-owned.

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

## Task Worktrees

Every dispatched task runs in its own worktree so workers can commit without touching the shared checkout.

- Name both the worktree path `.opencode/worktrees/<name>` and its branch `<name>`, where `<name>` is `<feature-tag>-<slug>` and `<slug>` is a two-to-four word hyphenated slug of the task description.
- If the repository does not ignore `.opencode/worktrees/`, add it to `.git/info/exclude`.
- Create with `git worktree add .opencode/worktrees/<name> -b <name> <feature-branch>`, cutting from the feature branch tip at dispatch time. Dependent tasks are dispatched only after their dependencies merge, so they automatically include earlier work.
- Annotate each dispatched task with its worktree path and branch.
- To resume a stopped task, re-attach its branch with `git worktree add .opencode/worktrees/<name> <name>`.

## Parallelism Preflight

Worktrees make concurrent writing structurally safe: ordinary file overlap surfaces as merge conflicts at reconciliation, not as write races. Dispatch concurrently only when tasks are logically independent. Compare each pair for:

- public contracts: types, APIs, schemas, and configuration that both tasks change;
- dependency manifests and lockfiles;
- generated files;
- shared test fixtures and setup.

If a pair shares any of these, order them with `depends:<uuid>` or run them serially. Start with at most two concurrent writers.

Workers may modify only the files in their task brief and must not alter dependencies the brief does not assign, run repository-wide formatters, rebase, merge, push, or spawn subagents. A worker that discovers extra scope reports it; the controller creates a separate task after approval.

## Execute

1. If any child task is in flight (`+ACTIVE`), run the resume classification first. Then query unblocked child tasks with `status:pending` and their feature tag.
2. Run the parallelism preflight and select one or two eligible tasks.
3. For each selected task, create its worktree and branch, mark it started, and annotate the dispatch identity, worktree path, and branch.
4. Dispatch a fresh `build` subagent for every selected task concurrently — all worker invocations in a single step, not one at a time — using `/home/ghutton/.config/opencode/prompts/task-flow-worker.md` as the worker contract. Include the worktree path and the task UUID in the brief and instruct the worker to run all commands with its bash working directory set to that worktree. Include only the task brief, applicable repository constraints, and the required report format.
5. Reconcile each worker result as it arrives, in completion order, following the reconciliation procedure. After each successful merge, re-run the eligibility query and dispatch any newly-unblocked task immediately, up to the concurrency limit from the parallelism preflight: the pipeline refills rather than draining.
6. If a task cannot proceed without external input, stop it and annotate the blocker; create a dependent unblocking task when that is actionable.
7. Run the final integration task only after every implementation task is complete.

Never dispatch a worker for a completed, started, blocked, or dependency-blocked task.

## Reconciliation

For each finished worker, from the main checkout on the feature branch:

1. Verify the worktree is clean and holds the reported commits by running `git status --porcelain` with the bash working directory set to the worktree; the output must be empty.
2. If the worker's `[worker]` completion annotation is missing (it reported an annotation failure), append it to the task from the returned report before proceeding: the board, not the conversation, is the durable record.
3. Merge the task branch with `git merge --no-edit <name>`. Resolve mechanical conflicts directly, guided by both task briefs. If both sides changed a shared contract with different intent, run `git merge --abort`, stop the task, annotate the clash, and ask the user.
4. Run the task's validation command on the merged feature branch. Fix trivial breakage directly; otherwise unwind with `git reset --hard ORIG_HEAD`, stop the task, annotate the failure, and keep the task branch for salvage.
5. On success, mark the task complete, annotate the completed validation, remove the worktree with `git worktree remove <path>`, and delete the merged branch with `git branch -d <name>`.

When a task stops without merging, keep its branch for salvage and remove the worktree only after committing or discarding its uncommitted state; `git worktree remove --force` discards it.

## Resume

A controller session can die mid-swarm. The board and worktrees hold enough state to recover, so a new session resumes an interrupted feature simply by invoking this skill again: run the classification below whenever a feature has started, incomplete tasks — including at the start of Execute.

1. Find in-flight tasks with `task rc.context= project:<project> +opencode +ACTIVE status:pending export`, and group them by feature tag.
2. Classify each in-flight task from its annotations and worktree:
   - a `[worker]` annotation exists — the worker finished but the controller died before reconciling. Treat the annotation as the worker report and run the reconciliation procedure now; a `blocked` or `needs-scope` worker annotation follows the stop path instead.
   - a controller blocker annotation exists — the previous session was stopping this task when it died. Do not dispatch or merge; surface it to the user.
   - otherwise, with the dispatch annotation's worktree present — the worker died mid-task. Re-dispatch a fresh worker into the same worktree and branch, never recreating them, noting in the brief that a previous attempt may have left partial or committed work to review, keep, and complete.
   - the worktree is missing — if the branch still exists, re-attach it with `git worktree add .opencode/worktrees/<name> <name>` and re-dispatch; otherwise dispatch fresh.
3. Continue Execute normally afterwards: reconcile results as they arrive and let the pipeline refill.

## Worker Report

Every worker appends a one-line completion annotation to its own task before returning:

    task rc.context= <uuid> annotate "[worker] <status>: <summary> | verify: <pass|fail>"

Every worker report must include:

- status: complete, blocked, or needs-scope;
- commits on the task branch;
- changed files;
- validation command and result;
- any conflict or unplanned work discovered;
- whether the completion annotation succeeded.

When no tasks remain, run `task rc.context= sync` once to settle the board to the git remote, then report the TaskWarrior feature UUID, completed tasks, validation performed, and unresolved blockers.

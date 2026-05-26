# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Version Control

This directory is tracked via a bare git repo at `~/.cfg/` with `$HOME` as the work tree. This avoids needing a `.git` directory in `$HOME` itself. The fish `config` alias wraps this, but Claude Code runs bash and cannot use fish aliases — use the full git invocation instead:

```bash
git --git-dir=$HOME/.cfg/ --work-tree=$HOME status
git --git-dir=$HOME/.cfg/ --work-tree=$HOME add $HOME/.config/stringy/commands/claude.fish
git --git-dir=$HOME/.cfg/ --work-tree=$HOME commit -m "..."
```

Plain `git` commands inside this directory will not work — there is no `.git` here.

## What This Repo Is

`~/.config/stringy` is a personal fish shell configuration library. It is sourced by `~/.config/fish/config.fish` via `common.fish`, which is the entry point that loads everything else.

## Structure

- `common.fish` — entry point; sources `utils.fish`, `binds.fish`, `path.fish`, `stackrox.fish`, `collector.fish`, `fish/plugins.fish`, `vms.fish`, and all files under `commands/`
- `path.fish` — sets `$GOPATH`, `$PATH` additions, and macOS-specific library paths
- `utils.fish` — small utility functions (`git_repo_root`, `git_main_branch`, `at_work`, clipboard aliases, tmux helpers)
- `binds.fish` — `!!` and `!$` bash-style history expansion for fish
- `stackrox.fish` — StackRox/RHACS dev helpers: `cdrox`, collector driver checks, `rox-central` port-forward, `rox-teardown`, release setup
- `collector.fish` — collector integration test runner (`collector-test`)
- `vms.fish` — macOS-only QEMU dev VM setup and provisioning via Ansible
- `fish/plugins.fish` — fundle plugin declarations (fish-ssh-agent, gitnow)
- `commands/` — one file per tool/domain, all auto-sourced; notable ones:
  - `claude.fish` — the largest file; full Claude Code worktree workflow (see below)
  - `git.fish` — git aliases, `cdw` (fuzzy worktree cd), `gh-notify` daemon
  - `infractl.fish` — ephemeral OpenShift cluster helpers (`infra-switch`, `infra-dl`, etc.)
  - `kubectl.fish` — kubectl aliases and cached completions
  - `ralph.fish` — custom tool helpers
  - `writing.fish` — pandoc/writing workflow helpers
- `scripts/` — standalone fish scripts run as daemons or one-shots (e.g. `claude-watch-ci.fish`)
- `git/` — per-context gitconfig includes (`personal`, `work`)
- `ansible/` — local dev provisioning playbooks
- `templates/pandoc-shunn/` — submodule; Shunn manuscript format pandoc template
- `.claude/settings.local.json` — Claude Code project permissions

## Claude Worktree Workflow (`commands/claude.fish`)

This implements a Jira-driven Claude Code worktree system:

**Core pattern**: each piece of work lives in a git worktree at `.claude/worktrees/<ticket>-<slug>/`. Worktrees are created, resumed, and cleaned up via these functions:

| Alias | Function | Purpose |
|-------|----------|---------|
| `cs` | `claude-switch` | Create or resume a worktree session for a Jira ticket (fetches ticket metadata, builds an enriched prompt) |
| `cr` | `claude-resume` | Resume a session by worktree name/substring, or open agents dashboard |
| `cx` | `claude-clean` | Remove a worktree and optionally its branch; `-s` removes all with merged PRs |
| `cy` | `claude-sync` | Rebase all Claude worktrees onto latest main |
| `co` | `claude-dash` | Dashboard: all worktrees with Jira status, git ahead count, PR state |
| `cv` | `claude-review` | Check out a PR into a review worktree and start `/review` |
| `cw` | `claude-watch` | Background-watch CI for a PR; calls `scripts/claude-watch-ci.fish`; `-t` auto-triages failures |
| `cws` | `claude-watches` | List active CI watchers |
| `cbg` | `claude-bg` | Send a prompt to a background agent in a worktree |
| `cm` | `claude-summary` | Standup summary across all worktrees; `-c` pipes through Claude |
| `cb` | `claude-branch` | Create/resume a worktree for an existing branch (not Jira-driven) |

Internal helpers (prefixed `__claude_`) are not part of the public API:
- `__claude_cached` — TTL file cache (used for Jira completions and ticket JSON)
- `__claude_worktrees` — list `.claude/worktrees/` paths for a repo
- `__claude_stale_worktrees` — find worktrees whose branch has a merged PR
- `__claude_slugify` — converts a title to a 3-4 word kebab-case slug
- `__claude_active_session` — finds a running background session by worktree CWD

**Vertex AI toggle**: at work (`at_work` checks for `~/.at-work`), Claude uses Vertex AI (`CLAUDE_CODE_USE_VERTEX=1`). Personally it uses Anthropic directly. `claude-personal` forces Anthropic regardless.

## Coding Conventions

- Fish functions use `argparse` for flag parsing, not manual `$argv` inspection
- Functions that need a repo root call `git_repo_root` (handles worktrees correctly) rather than `git rev-parse --show-toplevel`
- `pushd`/`popd` pairs protect callers from directory changes inside functions
- Jira data is cached in `~/.cache/jira-tickets/<ticket>.json` (86400s TTL); completions in `~/.cache/claude-jira-completions` (600s TTL)
- Tab completions are registered at the bottom of each file using `complete`
- British English is fine in this repo (see global CLAUDE.md)

## Adding New Commands

New tool integrations go in `commands/<toolname>.fish`. They are auto-sourced — no registration needed. Follow the existing pattern: `argparse` flags, guard with `command -q` before registering completions, add aliases at the bottom.

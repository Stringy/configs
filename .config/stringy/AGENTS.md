# Agent Instructions

## Repository

`~/.config/stringy` is a personal Fish shell configuration library. It is sourced by `~/.config/fish/config.fish` through `common.fish`.

`common.fish` is the entry point. It initialises Starship, sets `STRINGY_SCRIPTS_ROOT`, loads the core Fish files, then auto-sources `commands/*.fish` and `tools/*.fish`. It also loads plugin declarations, VM helpers, and optional notes helpers when the notes repository exists.

## Version Control

This directory is part of a bare Git repository at `~/.cfg/`, with `$HOME` as its work tree. There is no `.git` directory here. Use:

```bash
git --git-dir="$HOME/.cfg" --work-tree="$HOME" status
git --git-dir="$HOME/.cfg" --work-tree="$HOME" add "$HOME/.config/stringy/..."
git --git-dir="$HOME/.cfg" --work-tree="$HOME" commit -m "..."
```

The Fish `config` alias wraps this invocation but is unavailable to non-interactive shell commands.

## Layout

- `common.fish`: configuration entry point and source order.
- `utils.fish`: shared helpers, including repository, Git, tmux, and work-environment helpers.
- `path.fish`, `binds.fish`, `stackrox.fish`, `collector.fish`, and `vms.fish`: core environment and workflow configuration.
- `commands/`: auto-sourced command integrations and workflows, including Git, Jira, Kubernetes, Claude, OpenCode, writing, and local development tools.
- `tools/`: auto-sourced tool-specific configuration.
- `fish/plugins.fish`: fundle plugin declarations.
- `scripts/`: standalone Fish scripts invoked by commands or daemons.
- `ansible/`, `containers/`, `fstar/`, and `git/`: provisioning, container, F* and Git configuration assets.
- `templates/`: project templates. The novel template includes `AGENTS.md` with editorial guidance for any AI assistant.

## Conventions

- Follow the existing Fish style and keep changes focused.
- Use `argparse` for function option parsing rather than manually inspecting `$argv`.
- Use `git_repo_root` for repository-aware functions so they work from Git worktrees.
- Use balanced `pushd` and `popd` when a function changes directory.
- Register tab completions at the end of the relevant command file.
- Guard optional command integrations and completions with `command -q` where appropriate.
- Preserve British English in user-facing text and documentation.
- Do not expose credentials or copy secrets from files under `~/.config/secrets`.

## Adding Commands

Add a new integration as `commands/<tool>.fish`; `common.fish` sources it automatically. Follow neighbouring command files for function naming, help text, aliases, and completions.

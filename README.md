# wt

Tiny zsh helper for switching to existing git worktrees or creating a new one from a branch name.

## Requirements

- `zsh`
- `git`
- `fzf` (required for interactive `wt` picker mode; not required for `wt <branch-name>`)

## Install

Source `wt.zsh` (or `wt.plugin.zsh`) from your shell config:

```zsh
# ~/.zshrc
source /absolute/path/to/wt.zsh
# or
source /absolute/path/to/wt.plugin.zsh
```

Do not run `./wt.zsh` directly; it defines a shell function and must be sourced.

`wt.plugin.zsh` exists for zsh plugin-manager compatibility and simply sources `wt.zsh`.

Reload your shell:

```zsh
source ~/.zshrc
```

## Usage

- `wt`
  - Opens an `fzf` picker of existing worktrees and `cd`s to the selection.
  - `Ctrl-N`: prompt for branch name, create/switch worktree.
  - `Ctrl-D`: remove selected worktree (with confirmation; main worktree is protected).
- `wt <branch-name>`
  - If that branch already has a worktree, switches to it.
  - Otherwise creates a new worktree at `../<repo>-worktrees/<branch-name>` and switches to it.
  - Branch names with `/` are preserved as nested directories (for example `team/feature` -> `../<repo>-worktrees/team/feature`).

## Dotfile Copy Behavior

When `wt <branch-name>` creates a new worktree, it copies these files from the main worktree root if they exist and are not already present in the new path:

- `.mise.toml`
- `.node-version`
- `.nvmrc`
- `.python-version`
- `.ruby-version`
- `.tool-versions`

Sensitive files are not copied by default:

- `.env`
- `.env.local`
- `.envrc`
- `.npmrc`

Enable sensitive-file copying before sourcing `wt.zsh`:

```zsh
WT_COPY_SENSITIVE_DOTFILES=1
source /absolute/path/to/wt.zsh
```

Or fully override the copy list:

```zsh
WT_DOTFILES_TO_COPY=(.nvmrc .tool-versions .env.local)
source /absolute/path/to/wt.zsh
```

## Tested Platforms

- macOS with zsh 5.9


# wt

Tiny zsh helper for switching to existing git worktrees or creating a new one from a branch name.

## Requirements

- `zsh`
- `git`
- `fzf`

## Install

Source `wt.zsh` from your shell config:

```zsh
# ~/.zshrc
source /absolute/path/to/wt.zsh
```

Do not run `./wt.zsh` directly; it defines a shell function and must be sourced.

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
  - Branch names with `/` are converted to `-` in the directory name.

## Dotfile Copy Behavior

When `wt <branch-name>` creates a new worktree, it copies these files from the main worktree root if they exist and are not already present in the new path:

- `.env`
- `.env.local`
- `.envrc`
- `.mise.toml`
- `.node-version`
- `.npmrc`
- `.nvmrc`
- `.python-version`
- `.ruby-version`
- `.tool-versions`

Warning: these files can include secrets or personal machine-specific configuration. Review what is copied before sharing worktrees.

## Tested Platforms

- macOS with zsh 5.9

## Known Limitations

- Path naming can collide if multiple branch names normalize to the same `-`-separated directory name.
- The helper currently targets local worktree/branch flows and does not add extra prompts for non-standard git setups.

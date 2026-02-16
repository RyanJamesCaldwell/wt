# wt

Tiny zsh helper for switching to existing git worktrees or creating a new one from a branch name.

## Requirements

- `zsh`
- `git`
- `fzf` (required for interactive `wt` picker mode; not required for `wt <branch-name>`)

## Install

Pick one of these installation paths.

### 1) Clone the repo (recommended)

```zsh
git clone https://github.com/RyanJamesCaldwell/wt.git ~/.config/wt
echo 'source ~/.config/wt/wt.zsh' >> ~/.zshrc
source ~/.zshrc
```

### 2) Use a zsh plugin manager

`wt.plugin.zsh` exists for plugin-manager compatibility and sources `wt.zsh`.

```zsh
# zinit
zinit light RyanJamesCaldwell/wt

# antigen
antigen bundle RyanJamesCaldwell/wt

# zplug
zplug "RyanJamesCaldwell/wt"
```

### 3) Download a single file

```zsh
mkdir -p ~/.config/wt
curl -fsSL https://raw.githubusercontent.com/RyanJamesCaldwell/wt/main/wt.zsh -o ~/.config/wt/wt.zsh
echo 'source ~/.config/wt/wt.zsh' >> ~/.zshrc
source ~/.zshrc
```

Manual source example:

```zsh
# ~/.zshrc
source /absolute/path/to/wt.zsh
# or
source /absolute/path/to/wt.plugin.zsh
```

Do not run `./wt.zsh` directly; it defines a shell function and must be sourced.

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

Enable sensitive-file copying:

```zsh
WT_COPY_SENSITIVE_DOTFILES=1
```

You can set that flag either before sourcing `wt.zsh` or later in an existing shell session, as long as it is set before running `wt <branch-name>`.

Or fully override the copy list:

```zsh
WT_DOTFILES_TO_COPY=(.nvmrc .tool-versions .env.local)
source /absolute/path/to/wt.zsh
```

## Tested Platforms

- macOS with zsh 5.9

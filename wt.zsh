#!/usr/bin/env zsh
# `wt` is a small zsh helper for selecting, creating, and removing git worktrees.

if [ -z "${ZSH_VERSION:-}" ]; then
  echo "wt.zsh requires zsh. Source it from zsh: source /path/to/wt.zsh" >&2
  return 1 2>/dev/null || exit 1
fi

typeset -ga WT_SAFE_DOTFILES_TO_COPY=(
  .mise.toml
  .node-version
  .nvmrc
  .python-version
  .ruby-version
  .tool-versions
)

typeset -ga WT_SENSITIVE_DOTFILES_TO_COPY=(
  .env
  .env.local
  .envrc
  .npmrc
)

if (( ! ${+WT_DOTFILES_TO_COPY} )); then
  typeset -ga WT_DOTFILES_TO_COPY=("${WT_SAFE_DOTFILES_TO_COPY[@]}")
  case "${WT_COPY_SENSITIVE_DOTFILES:-0}" in
    1|true|TRUE|yes|YES|on|ON)
      WT_DOTFILES_TO_COPY+=("${WT_SENSITIVE_DOTFILES_TO_COPY[@]}")
      ;;
  esac
fi

_wt_copy_dotfiles() {
  emulate -L zsh
  setopt pipefail

  local src_root="$1"
  local dest_root="$2"
  local file src_file dest_file

  for file in "${WT_DOTFILES_TO_COPY[@]}"; do
    src_file="$src_root/$file"
    dest_file="$dest_root/$file"
    if [[ -f "$src_file" && ! -e "$dest_file" ]]; then
      cp -p "$src_file" "$dest_file"
    fi
  done
}

_wt_collect_worktrees() {
  emulate -L zsh
  setopt pipefail

  typeset -ga WT_PATHS=()
  typeset -ga WT_BRANCHES=()

  local line current_path="" current_branch=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      if [[ -n "$current_path" ]]; then
        WT_PATHS+=("$current_path")
        if [[ -n "$current_branch" ]]; then
          WT_BRANCHES+=("$current_branch")
        else
          WT_BRANCHES+=("(detached)")
        fi
      fi
      current_path=""
      current_branch=""
      continue
    fi

    case "$line" in
      "worktree "*)
        current_path="${line#worktree }"
        ;;
      "branch refs/heads/"*)
        current_branch="${line#branch refs/heads/}"
        ;;
      "branch "*)
        current_branch="${line#branch }"
        ;;
      detached)
        current_branch="(detached)"
        ;;
    esac
  done < <(git worktree list --porcelain; printf '\n')
}

_wt_primary_worktree_root() {
  emulate -L zsh
  setopt pipefail

  local current_root="$1"
  local common_dir abs_common_dir

  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  if [[ "$common_dir" == /* ]]; then
    abs_common_dir="$common_dir"
  else
    abs_common_dir="${current_root}/${common_dir}"
  fi
  abs_common_dir="${abs_common_dir:A}"

  if [[ "${abs_common_dir:t}" != ".git" ]]; then
    print -u2 "wt: unable to resolve primary worktree root"
    return 1
  fi

  print -r -- "${abs_common_dir:h}"
}

_wt_switch_or_create() {
  emulate -L zsh
  setopt pipefail

  local requested_branch="$1"
  local repo_root="$2"
  local repo_name="$3"

  local i
  for ((i = 1; i <= ${#WT_PATHS[@]}; i++)); do
    if [[ "${WT_BRANCHES[i]}" == "$requested_branch" ]]; then
      builtin cd "${WT_PATHS[i]}" || return 1
      return 0
    fi
  done

  local wt_base_dir="${repo_root:h}/${repo_name}-worktrees"
  local new_path="${wt_base_dir}/${requested_branch}"

  if ! git check-ref-format --branch "$requested_branch" >/dev/null 2>&1; then
    print -u2 "wt: invalid branch name: $requested_branch"
    return 1
  fi

  mkdir -p "${new_path:h}" || return 1
  if [[ -e "$new_path" ]]; then
    print -u2 "wt: target path already exists: $new_path"
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$requested_branch"; then
    git worktree add "$new_path" "$requested_branch" || return 1
  else
    git worktree add -b "$requested_branch" "$new_path" || return 1
  fi

  _wt_copy_dotfiles "$repo_root" "$new_path"
  builtin cd "$new_path" || return 1
}

_wt_choice_to_path() {
  emulate -L zsh
  local choice="$1"
  local base_dir="$2"
  local candidate

  if [[ "$choice" != *$'\t'* ]]; then
    print -u2 "wt: invalid worktree selection format"
    return 1
  fi

  candidate="${choice##*$'\t'}"
  if [[ "$candidate" == "~/"* ]]; then
    candidate="${HOME}/${candidate#~/}"
  elif [[ "$candidate" != /* ]]; then
    candidate="${base_dir}/${candidate}"
  fi

  print -r -- "${candidate:A}"
}

_wt_display_path() {
  emulate -L zsh
  local abs_path="$1"
  local base_dir="$2"

  if [[ "$abs_path" == "$base_dir"/* ]]; then
    print -r -- "${abs_path#$base_dir/}"
    return 0
  fi

  if [[ "$abs_path" == "$HOME"/* ]]; then
    print -r -- "~/${abs_path#$HOME/}"
    return 0
  fi

  print -r -- "$abs_path"
}

wt() {
  emulate -L zsh
  setopt pipefail

  if ! command -v git >/dev/null 2>&1; then
    print -u2 "wt: missing dependency: git"
    return 1
  fi

  local repo_root main_root repo_name
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    print -u2 "wt: not inside a git repository"
    return 1
  }
  main_root="$(_wt_primary_worktree_root "$repo_root")" || return 1
  repo_name="${main_root:t}"

  _wt_collect_worktrees

  local requested_branch="${1:-}"
  if [[ -n "$requested_branch" ]]; then
    _wt_switch_or_create "$requested_branch" "$main_root" "$repo_name"
    return $?
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "wt: missing dependency: fzf"
    return 1
  fi

  local -a choices
  local i max_branch_width=0 display_base display_path branch_label
  display_base="${main_root:h}"

  for ((i = 1; i <= ${#WT_BRANCHES[@]}; i++)); do
    if (( ${#WT_BRANCHES[i]} > max_branch_width )); then
      max_branch_width=${#WT_BRANCHES[i]}
    fi
  done

  for ((i = 1; i <= ${#WT_PATHS[@]}; i++)); do
    display_path="$(_wt_display_path "${WT_PATHS[i]}" "$display_base")"
    branch_label="$(printf "%-${max_branch_width}s" "${WT_BRANCHES[i]}")"
    choices+=("${branch_label}"$'\t'"${display_path}"$'\t'"${WT_PATHS[i]}")
  done

  local result key selection selected_path
  result="$(
    printf '%s\n' "${choices[@]}" | fzf \
      --header='[Enter: switch] [Ctrl-N: new] [Ctrl-D: delete]' \
      --expect=ctrl-n,ctrl-d \
      --prompt='worktree> ' \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --height=60% \
      --layout=reverse \
      --border
  )"

  if [[ -z "$result" ]]; then
    return 0
  fi

  key="$(printf '%s\n' "$result" | head -n1)"
  selection="$(printf '%s\n' "$result" | tail -n1)"

  case "$key" in
    ctrl-n)
      local branch=""
      read "branch?Branch name: "
      if [[ -z "$branch" ]]; then
        return 0
      fi
      _wt_switch_or_create "$branch" "$main_root" "$repo_name"
      return $?
      ;;
    ctrl-d)
      if [[ -z "$selection" ]]; then
        return 0
      fi

      selected_path="$(_wt_choice_to_path "$selection" "$display_base")" || return 1

      if [[ "$selected_path" == "$main_root" ]]; then
        print -u2 "wt: cannot delete main worktree"
        return 1
      fi

      print -n "Delete worktree at $selected_path? (y/N) "
      if read -q; then
        print
        git worktree remove "$selected_path" || return 1
      else
        print
      fi
      ;;
    *)
      if [[ -z "$selection" ]]; then
        return 0
      fi
      selected_path="$(_wt_choice_to_path "$selection" "$display_base")" || return 1
      builtin cd "$selected_path" || return 1
      ;;
  esac
}

if [[ "$ZSH_EVAL_CONTEXT" != *:file ]]; then
  print -u2 "wt.zsh defines wt(). Source it from ~/.zshrc instead of executing it."
  print -u2 "Example: source /absolute/path/to/wt.zsh"
  exit 1
fi

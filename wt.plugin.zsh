#!/usr/bin/env zsh

if [ -z "${ZSH_VERSION:-}" ]; then
  echo "wt.plugin.zsh requires zsh." >&2
  return 1 2>/dev/null || exit 1
fi

local _wt_plugin_dir
_wt_plugin_dir="${${(%):-%N}:A:h}"

source "${_wt_plugin_dir}/wt.zsh"

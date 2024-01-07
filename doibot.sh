#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local BOT_FILE="$(readlink -m -- "$BASH_SOURCE")"
  local BOT_PATH="$(dirname -- "$BOT_FILE")"
  local BOT_FUNCD="$BOT_PATH/funcs"
  cd -- "$BOT_PATH" || return $?
  local -A CFG=( [task]='scan_and_assign' )
  source -- "$BOT_FUNCD"/bot_init.sh || return $?
  source_these_libs "$BOT_FUNCD"/*.sh || return $?
  source_in_func "$BOT_FUNCD"/cfg.default.rc || return $?
  load_host_config doibot || return $?
  "${CFG[task]}" "$@" || return $?
}



cli_main "$@"; exit $?

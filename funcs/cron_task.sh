#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function cron_task () {
  exec </dev/null
  setup_logfile_tee || return $?
  cron_task__setup_npm_bin_paths || return $?

  local RV=0
  scan_and_assign || RV+=4

  # generate_rss_reports || RV+=4

  rechown_logsdir || RV+=4
  [ "$RV" == 0 ] || echo E: 'DOI bot cron task failed!' >&2
  return "$RV"
}


function cron_task__setup_npm_bin_paths () {
  local BIN_DIR= ADD_PATHS=
  local BASEDIR="$(dirname -- "$BOT_PATH")"
  for BIN_DIR in "$BASEDIR"{,/*}/node_modules/.bin/; do
    # echo D: "$FUNCNAME: Checking $BIN_DIR" >&2
    [ -d "$BIN_DIR" ] || continue
    # echo D: "$FUNCNAME:   is dir" >&2
    BIN_DIR="${BIN_DIR%/}"
    [[ ":$PATH:" == *":$BIN_DIR:"* ]] || ADD_PATHS+=":$BIN_DIR"
  done
  # echo D: "$FUNCNAME: ADD_PATHS: '$ADD_PATHS'" >&2
  [ -n "$ADD_PATHS" ] || return 0
  PATH+="$ADD_PATHS"
  export PATH
}









return 0

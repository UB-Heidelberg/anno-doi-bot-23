#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function setup_logfile_tee () {
  [ -n "$LOG_TOPIC" ] || local LOG_TOPIC="${FUNCNAME[1]}"
  local LOGS_DIR="${CFG[doibot_log_dest_dir]}"
  mkdir --parents -- "$LOGS_DIR"
  local DEST="$LOGS_DIR/$LOG_TOPIC.$(
    printf '%(%y%m%d-%H%M%S)T' -1).$$.log"
  echo D: "Log file will be: $DEST"
  >>"$DEST" || return $?$(
    echo E: "Failed write-append test for logfile: $DEST" >&2)
  rechown_logsdir || return $?
  exec &> >(stdbuf -o0 -e0 tee -- "$DEST")
}


function with_logfile_tee_do () {
  LOG_TOPIC="$1" setup_logfile_tee || return $?
  "$@"; return $?
}


function rechown_logsdir () {
  local LOGS_DIR="${CFG[doibot_log_dest_dir]}"
  [ "$(whoami)" == root ] || return 0
  # Let's hope we're root only inside a docker container.
  chown --reference="$LOGS_DIR" --recursive -- "$LOGS_DIR" || true
}


return 0

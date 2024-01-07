#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function setup_logfile_tee () {
  local LOGS_DIR="${CFG[doibot_log_dest_dir]}"
  mkdir --parents -- "$LOGS_DIR"
  local DEST="$LOGS_DIR/${FUNCNAME[1]}.$(
    printf '%(%y%m%d-%H%M%S)T' -1).$$.log"
  echo D: "Log file will be: $DEST"
  >>"$DEST" || return $?$(
    echo E: "Failed write-append test for logfile: $DEST" >&2)
  exec &> >(stdbuf -o0 -e0 tee -- "$DEST")
}

return 0

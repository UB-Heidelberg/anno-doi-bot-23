#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function log_dump () {
  local DUMP_DEST="${CFG[doibot_log_dest_dir]}/$1"
  cat >"$DUMP_DEST" || return $?$(
    echo E: "Failed to dump debug file: $DUMP_DEST" >&2)
  echo D: "Dump file saved: $(du --bytes -- "$DUMP_DEST")"
}


function logts () {
  printf '%s [%(%F %T %Z)T] ' "$1" -1; shift
  echo "$*"
}



return 0

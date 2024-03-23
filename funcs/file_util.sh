#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function open_tmpbuf_filehandles () {
  local FD_WRITE="$1"; shift
  local FD_READ="$1"; shift
  local FILENAME="$1"; shift
  local ERR="E: $FUNCNAME: for ${FUNCNAME[1]}: Cannot = file: $FILENAME"
  eval "exec $FD_WRITE>"'"$FILENAME"' || return $(echo "${ERR/=/write}" >&2)
  eval "exec $FD_READ<"'"$FILENAME"' || return $(echo "${ERR/=/read}" >&2)
  rm -- "$FILENAME" || return $(echo "${ERR/=/delete}" >&2)
}


function close_filehandles () {
  local FD=
  for FD in "$@"; do
    eval "exec $FD<&-" || return 4$( # albeit this should be impossible:
      echo E: $FUNCNAME: "Failed to close file handle $FD." >&2)
  done
}


return 0

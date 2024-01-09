#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function load_host_config () {
  local CFG_TOPIC="$1"
  echo P: "Reading config file(s) for host ${HOSTNAME:-<?none?>}."
  local ITEM=
  for ITEM in {config,cfg.@"$HOSTNAME"}{/*,.*,}.rc; do
    [ ! -f "$ITEM" ] || source_in_func "$ITEM" cfg:"$CFG_TOPIC" || return $?
  done
}


function source_in_func () {
  source -- "$@" || return $?$(
    echo W: "$FUNCNAME failed (rv=$?) for '$1'" >&2)
}


function source_these_libs () {
  local LIB=
  for LIB in "$@"; do
    source_in_func "$LIB" --lib || return $?
  done
}






return 0

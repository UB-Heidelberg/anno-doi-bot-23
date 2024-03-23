#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function generate_rss_reports () {
  local ADD_LOG= MSG=
  for ADD_LOG in "$@"; do
    MSG="$(grep -Pe '^[PWE]: ' -- "$ADD_LOG" | tail --lines=1)"
    [[ "$MSG" == [A-Z]': ['*'] '* ]] && MSG="${MSG:0:3}${MSG#*] }"
    rssfeed_prepend_entry FEED=runs LOG="$ADD_LOG" MSG="$MSG" || return $?
  done
}









return 0

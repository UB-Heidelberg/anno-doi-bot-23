#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function cron_task () {
  exec </dev/null
  setup_logfile_tee || return $?

  local RV=0
  RRS_TOPIC="$FUNCNAME" with_rerun_state_fail_score scan_and_assign || RV+=4

  # generate_rss_reports || RV+=4

  rechown_logsdir || RV+=4
  return "$RV"
}









return 0

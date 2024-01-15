#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function with_rerun_state () {
  local RRS_TOPIC="${1:-noop}"
  local RRS_FILE="${CFG[doibot_rerun_state_dir]}"
  mkdir --parents -- "$RRS_FILE"
  RRS_FILE+="/$RRS_TOPIC.rc"
  >>"$RRS_FILE" || return 5$(
    echo "E: Failed write test for rerun state file: $RRS_FILE" >&2)
  local RRS_TMPF="$RRS_FILE.tmp-$$"
  >"$RRS_TMPF" || return 5$(
    echo "E: Failed write test for temporary rerun state file: $RRS_TMPF" >&2)
  local RRS_RV=
  with_rerun_state__inner_dict "$@" || return $?
}


function with_rerun_state__inner_dict () {
  local -A RERUN_STATE=()
  source -- "$RRS_FILE" || return $?$(
    echo E: "Failed to read rerun state file: $RRS_FILE" >&2)
  [ "$DBGLV" -lt 2 ] || local -p >&2

  "$@"; RRS_RV=$?

  [ "$DBGLV" -lt 2 ] || local -p >&2
  local -p >"$RRS_TMPF" || return 5$(
    echo "E: Failed save temporary rerun state file: $RRS_TMPF" >&2)
  mv --no-target-directory -- "$RRS_TMPF" "$RRS_FILE" || return 5$(
    echo "E: Failed activate temporary rerun state file: $RRS_TMPF" >&2)
  return "$RRS_RV"
}


function with_rerun_state_fail_score () {
  with_rerun_state with_rerun_state__inner_fail_score "$@"; return $?
}


function wait_until_uts () {
  local UNTIL="$1"; shift
  [ "${UNTIL:-0}" -ge 1 ] || return 0
  local WAIT=$(( UNTIL - EPOCHSECONDS ))
  [ "${WAIT:-0}" -ge 1 ] || return 0
  logts P: "Gonna wait $WAIT seconds (until $(
    printf '%(%F %T)T' "$UNTIL")) $*"
  sleep "$WAIT"s
}


function with_rerun_state__inner_fail_score () {
  wait_until_uts "${RERUN_STATE[earliest_next_run]}" \
    'because the rerun state file says so.'

  local WAIT="${CFG[doibot_rerun_min_delay]}"
  if [ -n "$WAIT" ]; then
    WAIT="$(date +%s --date="+$WAIT")"
    RERUN_STATE[earliest_next_run]="$WAIT"
  fi

  local FAIL_SCORE=0
  "$@"; FAIL_SCORE+=$?
  if [ "$FAIL_SCORE" -lt 1 ]; then
    RERUN_STATE[fail_score]=0
    echo D: "Cumulative fail score has been reset."
  else
    let FAIL_SCORE="${RERUN_STATE[fail_score]} + $FAIL_SCORE"
    RERUN_STATE[fail_score]="$FAIL_SCORE"
    echo W: "Cumulative fail score increased to $FAIL_SCORE." >&2
  fi
  [ -z "$WAIT" ] || echo D: "Schedule for earliest next run is set to $(
    printf '%(%F %T)T' "$WAIT")."
}




return 0

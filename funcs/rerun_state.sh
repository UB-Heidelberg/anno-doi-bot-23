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
  exec -a doibot-rerun-sleep sleep "$WAIT"s &
  local SLEEP_PID=$!
  logts P: "Waiting $WAIT seconds (until $(printf '%(%F %T %Z)T' "$UNTIL"
    ), sleep pid: $SLEEP_PID) $*"
  wait "$SLEEP_PID" 2>/dev/null
  local SLEEP_RV=$?
  local SIG=$(( SLEEP_RV - 128 ))
  if [ "$SIG" -lt 0 ]; then
    SIG=
  else
    # Our `sleep` was killed by a signal. Translate signal number to name
    # because the numbers differ accross CPU architectures.
    # (cf. man 7 signal, man 1 kill)
    SIG="$(kill -l $SIG)"
    SIG="${SIG#SIG}"
  fi
  case "${SIG:-$SLEEP_RV}" in
    USR1 | \
    ALRM | \
    0 ) ;;

    HUP | \
    * )
      [ -z "$SIG" ] || SIG=" (probably killed by SIG$SIG)"
      echo E: $FUNCNAME: "failed to sleep, rv=$SLEEP_RV$SIG" >&2
      return 4;;
  esac
  [ "$EPOCHSECONDS" -ge "$UNTIL" ] || return 4$(
    echo E: $FUNCNAME: "sleep finished too early." >&2)
}


function with_rerun_state__inner_fail_score () {
  local WAIT='because the rerun state file says so.'
  local EARLIEST="${RERUN_STATE[earliest_next_run]:-0}"
  wait_until_uts "$EARLIEST" "$WAIT" || return 4$(
    echo E: "Failed to wait for earliest_next_run, rv=$?" >&2)

  WAIT="${CFG[doibot_rerun_min_delay]}"
  [ -n "$WAIT" ] || return 4$(
    echo E: 'Empty doibot_rerun_min_delay' >&2)
  WAIT="$(date +%s --date="+$WAIT")"
  [ -n "$WAIT" ] || return 4$(
    echo E: 'Failed to calculate earliest_next_run' >&2)
  if [ "$EARLIEST" -gt "$WAIT" ]; then
    echo W: "Flinching from decreasing earliest_next_run" \
      "to calculated new value $WAIT. Keeping old value: $EARLIEST" >&2
  else
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
    printf '%(%F %T %Z)T' "$WAIT")."
}




return 0

#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function stamp_one_newly_registered_doi () {
  [ -n "${STAMP_META[bare_doi]}" ] || return 5$(echo E: $FUNCNAME >&2 \
    'Empty DOI in STAMP_META or STAMP_META is not a dictionary!')

  local VERS_ID="${STAMP_META[anno_vers_id]}"
  [ -n "$VERS_ID" ] || return 4$(echo E: $FUNCNAME: 'Empty meta anno_vers_id' >&2)

  safechars_verify_dict_entries STAMP_META \
    anno_id_url:url \
    anno_vers_id:url \
    bare_doi:doi \
    dest_url:url \
    || return $?

  local WF_URL="${CFG[doibot_stamp_url]}"
  local WF_BODY="${CFG[doibot_stamp_body_template]}"
  local MARK="${CFG[doibot_stamp_slot_marker]}"
  local KEY= VAL=
  for KEY in "${!STAMP_META[@]}"; do
    VAL="${STAMP_META["$KEY"]}"
    WF_URL="${WF_URL//"<$MARK$KEY>"/"$VAL"}"
    WF_BODY="${WF_BODY//"<$MARK$KEY>"/"$VAL"}"
  done

  local WF_REQ=(
    "$WF_URL"
    --header="${CFG[doibot_stamp_headers]}"
    --- # start of verbatim curl options
    --request "${CFG[doibot_stamp_http_verb]}"
    --data-binary '@-'
    )
  VAL="$(<<<"$WF_BODY" webfetch "${WF_REQ[@]}")" || return 4$(
    echo E: "Stamp web request failed with exit status $?." >&2)

  if ! verify_stamp_reply_success <<<"$VAL"; then
    log_dump stamp_failed.txt <<<"$VAL"
    VAL="${VAL//$'\r'/}"
    VAL="${VAL//$'\n'/¶ }"
    [ "${#VAL}" -le 128 ] || VAL="${VAL:0:128}…"
    echo E: "Stamp reply does not indicate success. Message: $VAL" >&2
    return 4
  fi
}


function verify_stamp_reply_success () {
  grep --silent ${CFG[doibot_stamp_reply_grep_flags]} \
    --regexp="${CFG[doibot_stamp_reply_grep_success]}" || return $?
}











return 0

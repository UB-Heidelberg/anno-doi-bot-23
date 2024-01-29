#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function stamp_one_newly_registered_doi () {
  [ -n "${STAMP_META[bare_doi]}" ] || return 5$(echo E: $FUNCNAME >&2 \
    'Empty DOI in STAMP_META or STAMP_META is not a dictionary!')

  local URL="${CFG[doibot_stamp_baseurl]}"
  [ -n "$URL" ] || URL="${CFG[anno_baseurl]}"
  URL+="${STAMP_META[anno_vers_id]}"

  safechars_verify_dict_entries STAMP_META \
    anno_id_url:url \
    anno_vers_id:url \
    bare_doi:doi \
    dest_url:url \
    || return $?

  local WF_BODY="${CFG[doibot_stamp_body_template]}"
  local MARK="${CFG[doibot_stamp_slot_marker]}"
  local KEY= VAL=
  for KEY in "${!STAMP_META[@]}"; do
    VAL="${STAMP_META["$KEY"]}"
    WF_BODY="${WF_BODY//"<$MARK$KEY>"/"$VAL"}"
  done

  local WF_REQ=(
    --bot-auth
    --header="${CFG[doibot_stamp_headers]}"
    --- # start of verbatim curl options
    --request "${CFG[doibot_stamp_http_verb]}"
    --data-binary '@-'
    -- "$URL"
    )
  VAL="$(<<<"$WF_BODY" webfetch "${WF_REQ[@]}")" || return 4$(
    echo E: "Stamp web request failed with exit status $?." >&2)
  <<<"$VAL" grep --silent ${CFG[doibot_stamp_reply_grep_flags]} \
    --regexp="${CFG[doibot_stamp_reply_grep_success]}" || return 4$(
      echo E: 'Stamp reply does not indicate success.' >&2)
}











return 0

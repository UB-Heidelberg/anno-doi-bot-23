#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function safechars_verify () {
  local DATATYPE="$1"; shift
  local INPUT="$1"; shift
  local DESCR="${1:-unlabeled input}"; shift
  local SAFE=
  case "$DATATYPE" in
    doi )
      SAFE+="${CFG[doibot_doi_safe_chars]}"
      ;;
    url )
      SAFE+="${CFG[doibot_doi_safe_chars]}"
      SAFE+="${CFG[doibot_url_safe_chars]}"
      ;;
    * ) echo E: "Unsupported data type: '$DATATYPE'" >&2; return 4;;
  esac
  case "$SAFE" in
    *' '* | *'"'* | *'\'* )
      echo E: $FUNCNAME: "Config tries to allow banned characters." >&2
      return 8;;
  esac

  # Remove chars that could interfere with character range syntax:
  SAFE="${SAFE//./}"
  SAFE="${SAFE//-/}"

  # Now that we have removed range-interfering chars, we can safely add
  # the default character ranges:
  SAFE="0-9A-Za-z_,-/$SAFE"
  # ^-- NB: The range [,-/] includes `-` (hyphen-minus) and `.` (full stop).

  local BAD="$(<<<"$INPUT" tr -d "$SAFE"; echo :)"
  # ^-- Variable substitution inside the character group of ${1//[^…]/}
  # doesn't work, and even with eval we'd have to deal with at least
  # `&`, `]` and potentially `[`.

  BAD="${BAD%$'\n:'}"
  [ -n "$BAD" ] || return 0
  echo W: "Unacceptable character(s) in $DESCR: \"$BAD\"" >&2
  return 1
}


function safechars_verify_dict_entries () {
  local D="$1"; shift
  local K= T= V=
  for K in "$@"; do
    T="${K##*:}"
    K="${K%:*}"
    eval 'V="${'"$D"'["$K"]}"'
    safechars_verify "$T" "$V" "$T $D[$K]" || return $?
  done
}





return 0

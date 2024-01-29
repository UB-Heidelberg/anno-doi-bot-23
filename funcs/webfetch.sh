#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function webfetch () {
  local CURL_OPT=(
    --silent
    --user-agent "${CFG[doibot_useragent]}"
    )
  while [ "$#" -ge 1 ]; do case "$1" in
    --bot-auth )
      webfetch__set_custom_headers "${CFG[doibot_auth_headers]}"
      shift;;
    --header=* ) webfetch__set_custom_headers "${1#*=}"; shift;;
    --- ) shift; break;; # start of verbatim curl options
    -- ) break;;
    -* ) echo "E: $FUNCNAME: Unsupported option: $1" >&2; return 6;;
    * ) break;;
  esac; done
  # echo D: >&2 curl "${CURL_OPT[@]}" "$@" || return $?
  curl "${CURL_OPT[@]}" "$@" || return $?
}


function webfetch__set_custom_headers () {
  local ADD=()
  readarray -t ADD < <(<<<"$1" sed -nrf <(echo '
    s~^\s+~~
    /^#/b
    /^;/b
    s~\s+$~~
    s!^([^: ]+)\s*:\s*!--header\n\1: !p
    '))
  CURL_OPT+=( "${ADD[@]}" )
}









return 0

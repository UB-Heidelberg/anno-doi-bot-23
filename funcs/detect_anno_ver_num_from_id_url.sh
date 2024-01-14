#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function detect_anno_ver_num_from_id_url () {
  local URL="$1"
  detect_anno_ver_num_from_id_url__inner || return $?$(echo E: >&2 \
    "Unexpected anno ID URL: Failed to detect version suffix in: $URL")
}


function detect_anno_ver_num_from_id_url__inner () {
  local SUF="${URL##*${CFG[anno_url_versep]}}"
  [ "$URL" != "$SUF" ] || return 6$(echo E: 'Found no version separator.' >&2)
  [ -n "$SUF" ] || return 6$(echo E: 'Found empty version suffix.' >&2)
  [ -z "${SUF//[0-9]/}" ] || return 6$(
    echo E: 'Found non-digits in version suffix.' >&2)
  echo "$SUF"
}









return 0

#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function doibot_adapter_gxdebug () {
  local GX_OPT=(
    -title "$FUNCNAME"
    -buttons 'GTK_STOCK_OK:0,GTK_STOCK_CANCEL:1'
    -default 'GTK_STOCK_OK'
    -entrytext "+OK reg/upd <urn:doi:$anno_doi_expect>"
    -file -
    )
  ( cat; env | grep -Pie '^(anno|doibot)_' | sort -V
  ) | gxmessage "${GX_OPT[@]}"
}

doibot_adapter_gxdebug "$@"; exit $?

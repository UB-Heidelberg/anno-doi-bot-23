#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function env_export_anno_cfg () {
  local KEY=
  local ENV_CMD=( "${1:-export}" ); shift
  for KEY in "${!CFG[@]}"; do
    case "$KEY" in
      anno_* ) ;;
      doibot_* ) ;;

      "${CFG[doibot_adapter_name]:-anno}_"*  | \
      dba_* ) ;; # for use by DOI bot adapters

      * ) continue;;
    esac
    ENV_CMD+=( "$KEY=${CFG[$KEY]}" )
  done
  "${ENV_CMD[@]}" "$@" || return $?
}


return 0

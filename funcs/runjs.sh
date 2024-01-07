#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function runjs () {
  local ENV_CMD=( env )
  local KEY= VAL=
  for KEY in CODE DATA TEXT; do
    eval "VAL=\"\$$KEY\""
    [ -n "$VAL" ] || continue
    ENV_CMD+=( "$KEY=$VAL" )
  done
  "${ENV_CMD[@]}" "$@" nodejs -r enveval2401-pmb -e 0 || return $?
}





return 0

#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function scan_and_assign () {
  exec </dev/null
  setup_logfile_tee || return $?

  local RSS_URL="${CFG[anno_baseurl]}by/has_stamp;rss=vh/_ubhd:doiAssign"
  logts P: "Scan RSS feed: $RSS_URL"
  local RSS_LINKS=()
  readarray -t RSS_LINKS < <(webfetch "$RSS_URL" | grep -oPe '<link>[^<>]+')

  local MANDATORY_VH_ENTRY_FIELDS=(
    id
    created
    )
  local VH_LINK=
  local N_RSS_LINKS="${#RSS_LINKS[@]}"
  local ERR_CNT=0
  for VH_LINK in "${RSS_LINKS[@]}"; do
    VH_LINK="${VH_LINK#*>}"
    scan_and_assign__found_link && continue
    echo W: "$FUNCNAME: Failure (rv=$?) for VH link: $VH_LINK" >&2
    (( ERR_CNT += 1 ))
  done

  [ "$ERR_CNT" == 0 ] || return 4$(
    echo E: "$FUNCNAME: Encountered problems with $ERR_CNT VH links." >&2)
  logts P: "Success. Processed $N_RSS_LINKS VH links."
}


function scan_and_assign__found_link () {
  logts P: "Follow VH link: $VH_LINK"
  [[ "$VH_LINK" == "${CFG[anno_baseurl]}"* ]] || return 3$(
    echo E: 'Link not inside base URL!' >&2)

  local RGX='/([A-Za-z0-9_.-]+)/versions$'
  local ANNO_BASE_ID=
  [[ "$VH_LINK" =~ $RGX ]] && ANNO_BASE_ID="${BASH_REMATCH[1]}"
  [ -n "$ANNO_BASE_ID" ] || return 5$(
    echo E: "Failed to detect anno base ID from VH link." >&2)

  local ORIG_VH_REPLY="$(webfetch "$VH_LINK")"
  # log_dump <<<"$ORIG_VH_REPLY" "vh-reply.$ANNO_BASE_ID.json" || return $?

  local LIST=()
  readarray -t LIST < <(runjs DATA="$ORIG_VH_REPLY" \
    CODE='data.first.items.forEach(x => clog(toBashDictSp(x)));'
    ) || return 6$(echo E: "Failed to parse VH reply." >&2)

  local -A VH_INFO=()
  # local VH_ACCUM=
  local FIRST_CREATED=
  local VHE_NUM=0 VH_LENGTH="${#LIST[@]}"
  local -A TO_BE_DOI_STAMPED_VER_NUMS=()
  for DATA in "${LIST[@]}"; do
    VH_INFO=()
    eval "VH_INFO=( $DATA )"
    # ^-- e.g. [created]=2023-06…Z [as:deleted]=2023-09…Z [id]='http://…~3'
    # echo D: "  >> VH entry: $DATA <<"
    DATA=
    (( VHE_NUM += 1 ))
    scan_and_assign__vh_entry || return $?$(
      echo E: "Scanning version history failed:" \
        "Error while processing VH entry #$VHE_NUM" >&2)
  done
  [ "$VHE_NUM" -ge 1 ] || return 4$(echo E: 'Found no VH entries.' >&2)
  stamp_newly_registered_dois || return $?

  # VH_ACCUM="[$VH_ACCUM]"
  # local ACCUM_DUMP="${CFG[doibot_log_dest_dir]}/vh-accum.$ANNO_BASE_ID.json"
  # echo "$VH_ACCUM" >"$ACCUM_DUMP" || return 5$(
  #   echo E: 'Failed to dump the accumulated VH.' >&2)
}


function scan_and_assign__vh_entry () {
  local KEY= VAL=
  for KEY in "${MANDATORY_VH_ENTRY_FIELDS[@]}"; do
    [ -n "${VH_INFO[$KEY]}" ] || return 4$(
      echo E: "Entry has no '$KEY' field!" >&2)
  done

  local ANNO_ID_URL="${VH_INFO[id]}"
  local EXPECTED_SUFFIX="/$ANNO_BASE_ID~$VHE_NUM"
  [[ "$ANNO_ID_URL" == *"$EXPECTED_SUFFIX" ]] || return 6$(
    echo E: "Unexpected anno ID URL (expected suffix '$EXPECTED_SUFFIX'):" \
      "$ANNO_ID_URL" >&2)

  [ -n "$FIRST_CREATED" ] || FIRST_CREATED="${VH_INFO[created]}"

  # [ -z "$VH_ACCUM" ] || VH_ACCUM+=$',\n'
  if [ -n "${VH_INFO[as:deleted]}" ]; then
    echo P: "  • entry #$VHE_NUM: retracted. skip."
    # VH_ACCUM+='false'
    return 0
  fi

  echo P: "  • entry #$VHE_NUM: download…"
  local ANNO_JSON="$(webfetch "$ANNO_ID_URL")"
  [ -n "$ANNO_JSON" ] || return 6$(
    echo E: "Failed to request anno: $ANNO_ID_URL" >&2)
  # log_dump <<<"$ANNO_JSON" "anno.$ANNO_BASE_ID~$VHE_NUM.json" || return $?

  local OLD_DOI="${VH_INFO[dc:identifier]}"
  if [ -n "$OLD_DOI" ]; then
    echo P: "    • adapter: update existing DOI: <$OLD_DOI>"
  else
    echo P: "    • adapter: register new DOI:"
  fi
  local REG_DOI="${CFG[anno_doi_prefix]}$ANNO_BASE_ID$(
    )${CFG[anno_doi_versep]}$VHE_NUM${CFG[anno_doi_suffix]}"
  scan_and_assign__reg_one_doi || return $?

  [ -n "$OLD_DOI" ] || TO_BE_DOI_STAMPED_VER_NUMS["$VHE_NUM"]="$REG_DOI"
  # VH_ACCUM+="$ANNO_JSON"
}


function scan_and_assign__reg_one_doi () {
  local REG_CMD=(
    env_export_anno_cfg env
    anno_initial_version_date="$FIRST_CREATED"
    # anno_base_id="$ANNO_BASE_ID"
    # anno_ver_num="$VHE_NUM"
    anno_doi_expect="$REG_DOI"
    "${CFG[doibot_adapter_prog]}"
    ${CFG[doibot_adapter_args]}
    )
  local REG_MSG= REG_RV= # pre-declare
  REG_MSG="$(<<<"$ANNO_JSON" "${REG_CMD[@]}" 2>&1)"; REG_RV=$?
  local LAST_LINE="${REG_MSG##*$'\n'}"
  local DOI_NS='urn:doi:'
  local LL_EXPECTED="+OK reg/upd <$DOI_NS$REG_DOI>"
  case "$REG_RV:$LAST_LINE" in
    "0:$LL_EXPECTED" )
      echo P: "    • adapter succeeded. <$DOI_NS$REG_DOI>"
      return 0;;
    "0:+OK reg/upd <$DOI_NS"*'>' )
      echo E: "Adapter says it has registered this (wrong) DOI:" \
        "<${LAST_LINE#*<}, expected: <$DOI_NS$REG_DOI>" >&2
      return 6;;
  esac
  if [ -n "$REG_MSG" ]; then
    echo E: "    • adapter failed with exit code $REG_RV and this message:" >&2
    nl -ba <<<"$REG_MSG" | sed -re 's~^~E: > ~' >&2
    echo E: $'Expected:\t'"$LL_EXPECTED"
  else
    echo E: "    • adapter silently failed with exit code $REG_RV." >&2
  fi
  return "$REG_RV"
}


function stamp_newly_registered_dois () {
  local ANNO_VER_NUM=0 DOI=
  while [ "$ANNO_VER_NUM" -lt "$VH_LENGTH" ]; do
    (( ANNO_VER_NUM += 1 ))
    DOI="${TO_BE_DOI_STAMPED_VER_NUMS[$ANNO_VER_NUM]}"
    [ -n "$DOI" ] || continue
    # dc:identifier = https://doi.org/$DOI"
    echo P: "  • submit DOI stamp for version $ANNO_VER_NUM: $DOI"
    echo W: 'stub!'
  done
}











return 0

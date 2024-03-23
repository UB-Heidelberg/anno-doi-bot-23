#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function rssfeed_has_channel () {
  tr -s '\r\n' ' ' | grep -qPe '<rss\s.*>.*<channel>.*</channel>.*</rss>'
}


function rssfeed_init () {
  [ "$#" == 0 ] || local "$@"
  local TITLE="$RSS_TITLE"
  [ -n "$FEED" ] || return 4$(echo E: $FUNCNAME: 'Empty feed name' >&2)
  [[ "$FEED" == *.rss ]] || FEED="${CFG[doibot_rss_dest_dir]}/$FEED.rss"
  mkdir --parents -- "$(dirname -- "$FEED")"
  [ -n "$TITLE" ] || TITLE="doibot $(basename -- "$FEED" .rss)"
  [ -z "$ITEMS" ] && [ -f "$FEED" ] \
    && rssfeed_has_channel <"$FEED" && return 0
  printf '%s\n' \
    '<?xml version="1.0" encoding="utf-8"?>' \
    '<rss version="2.0"><channel>'"<title>$TITLE</title>" \
    "$ITEMS"'</channel></rss>' \
    >"$FEED" || return 4$(echo E: $FUNCNAME: "Failed to create $FEED" >&2)
}


function xmlquote () {
  local T="$1"
  # We use numeric entities rather than <![CDATA[…]]> in order to be able
  # to use the same quote function for attribute values and comments.
  T="${T//'&'/&#38;}"
  T="${T//'<'/&#60;}"
  T="${T//'>'/&#62;}"
  T="${T//'"'/&#34;}"
  T="${T//"'"/&#39;}"
  echo -n "$T"
}


function rssfeed_prepend_entry () {
  local URL= LOG= PUBDATE=
  [ "$#" == 0 ] || local "$@"
  rssfeed_init </dev/null || return $?
  local RGX='<channel><title>.*<\/title>$'
  open_tmpbuf_filehandles 33 34 "tmp.$FUNCNAME.$$.rss" || return $?
  local MAXLN=9009009
  grep -B $MAXLN -m 1 -Pe "$RGX" -- "$FEED" >&33 \
    || return 4$(echo E: $FUNCNAME: >&2 \
      'Feed title must start and end on the same line as channel starts.')

  if [ -n "$LOG" ]; then
    [[ "$LOG" == "${CFG[doibot_log_dest_dir]}"/* ]] || return 4$(
      echo E: $FUNCNAME: "Log file must be inside logs directory: $LOG" >&2)
    URL="${LOG:${#CFG[doibot_log_dest_dir]}}"
    URL="${URL#/}"

    PUBDATE="$(stat -c %Y -- "$LOG")"
    [ -n "$PUBDATE" ] || return 5$(echo E: $FUNCNAME: >&2 \
      "Cannot determine modification date for file $LOG")
    PUBDATE="$(LANG=C date -Rd "@$PUBDATE")"
    [ -n "$PUBDATE" ] || return 5$(echo E: $FUNCNAME: >&2 \
      "Failed to format modification date for file $LOG")
  fi

  case "$URL" in
    '' | *://* ) ;;
    * ) URL="${CFG[doibot_loglink_baseurl]}$URL";;
  esac

  [ -n "$PUBDATE" ] || PUBDATE="$(LANG=C date -R)"

  printf '  %s\n' >&33 \
    "<item><title>$(xmlquote "$MSG")</title>" \
    "  <link>$(xmlquote "$URL")</link>" \
    "  <pubDate>$PUBDATE</pubDate>" \
    '</item>'

  grep -A $MAXLN -Pe "$RGX" -- "$FEED" | tail --lines=+2 \
    | grep -B $MAXLN -m 9 -Fe '</item>' >&33
  echo '</channel></rss>' >&33

  cat <&34 >"$FEED" || return 4$(
    echo E: $FUNCNAME: "Failed to write modified RSS feed data to: $FEED" >&2)
  close_filehandles 33 34 || return $?
}









return 0

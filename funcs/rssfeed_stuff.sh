#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function rssfeed_has_channel () {
  tr -s '\r\n' ' ' | grep -qPe '<rss\s.*>.*<channel>.*</channel>.*</rss>'
}











return 0

#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function webfetch () {
  curl --silent -- "$1" || return $?
}









return 0

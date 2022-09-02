#! /usr/bin/env bash

source $(dirname $0)/prelude.sh

ORIGIN=https://api.github.com

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s --basic $ORIGIN$@" | red 1>&2
  [[ $GI_VERBOSE -gt 1 ]] && curl -v --basic --user $ORIGIN$@ || curl -s --basic $ORIGIN$@
}

define -n 'repo' -p '/search/repositories?q=$KEYWORD{[[ ! -z $USERNAME ]] && +user:$USERNAME || ""}{[[ ! -z $LANGUAGE ]] && +language:$LANGUAGE || ""}' -a 'KEYWORD,USERNAME,LANGUAGE;w:u:l:' -f 'items:name,full_name,description,html_url,clone_url,language'

function parseCmds() {
  local args=("${@:2}")
  case $1 in
  *)
    invoke "$@"
    ;;
  esac
}
parseArgs "$@"

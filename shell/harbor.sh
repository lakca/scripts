#!/bin/bash

source $(dirname $0)/prelude.sh

HARBOR_ORIGIN=http://local.harbor.io

repo=caasportal

HARBOR_USER=admin

HARBOR_PASS=P@ssw0rd2020

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s --basic --user $HARBOR_USER:$HARBOR_PASS $HARBOR_ORIGIN$@" | red 1>&2
  [[ $GI_VERBOSE -gt 1 ]] && curl -v --basic --user $HARBOR_USER:$HARBOR_PASS $HARBOR_ORIGIN$@ || curl -s --basic --user $HARBOR_USER:$HARBOR_PASS $HARBOR_ORIGIN$@
}

function ask() {
  debug ask:$1
  case "$1" in
  'repos@PROJECT_ID')
    invoke 'projects'
    red 'Project ID: ' 1>&2
    read PROJECT_ID
    ;;
  'tags@REPO_NAME')
    invoke 'repos'
    red 'Repo Name: ' 1>&2
    read REPO_NAME 
    ;;
  esac
}

define -n 'projects' -p '/api/projects' -f 'name,project_id' -h 'content-type:application/json'

define -n 'repos' -p '/api/repositories?project_id=$PROJECT_ID' -a 'PROJECT_ID!;p:' -f 'name,id,tags_count,description' -h 'content-type:application/json'

define -n 'top' -p '/api/repositories/top' -f 'name,project_id,tags_count,pull_count' -h 'content-type:application/json'

define -n 'tags' -p '/api/repositories/$REPO_NAME/tags?sort=created' -a 'REPO_NAME!;n:' -f 'name,author,digest,os,created,size' -z '+created' -h 'content-type:application/json'

function parseCmds() {
  local args=("${@:2}")
  case $1 in
  *)
    invoke "$@"
    ;;
  esac
}

parseArgs "$@"

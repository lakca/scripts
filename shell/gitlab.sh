# !/usr/bin/env bash

source $(dirname $0)/prelude.sh
GITLAB_ORIGIN=${GITLAB_ORIGIN:-}
# https://docs.gitlab.com/ee/api/index.html#personalproject-access-tokens
GITLAB_PRIVATE_TOKEN=${GITLAB_PRIVATE_TOKEN:-}
JOB_ACTIONS=(play cancel retry)
# Pagination: https://docs.gitlab.com/ee/api/index.html#Pagination

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s -H 'PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN' $GITLAB_ORIGIN$@" | red -i 1>&2
  [[ $GI_VERBOSE -gt 1 ]] && curl -v -H "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" $GITLAB_ORIGIN$@ || curl -s -H "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" $GITLAB_ORIGIN$@
}

# https://docs.gitlab.com/ee/api/project_aliases.html
# https://docs.gitlab.com/ee/api/projects.html
define -n 'projects' -p '/api/v4/projects?page=$PAGE&per_page=$SIZE' -a 'PAGE,SIZE;P:S:' -f 'id,name,namespace.name,description,web_url,last_activity_at|date'
define -n 'project' -p '/api/v4/projects/$PROJECT' -a 'PROJECT!;p:' -f 'id,name,namespace.name,description,web_url,last_activity_at|date'
# https://docs.gitlab.com/ee/api/project_statistics.html
define -n 'statistics' -p '/api/v4/projects/$PROJECT/statistics' -a 'PROJECT!;p:'
# https://docs.gitlab.com/ee/api/commits.html
define -n 'commits' -p '/api/v4/projects/$PROJECT/repository/commits?page=$PAGE&per_page=$SIZE&all=true&with_stats=true&order=default' -a 'PROJECT!,PAGE,SIZE;p:P:S:' -f 'id,author_name,committed_date|date,message|trim,web_url'
define -n 'commit' -p '/api/v4/projects/$PROJECT/repository/commits/$COMMIT' -a 'PROJECT!,COMMIT!;p:c:' -f 'id,author_name,author_email,committed_date|date,message|trim,web_url'
define -n 'commit:refs' -p '/api/v4/projects/$PROJECT/repository/commits/$COMMIT/refs' -a 'PROJECT!,COMMIT!;p:c:' -f 'type,name'
define -n 'commit:comments' -p '/api/v4/projects/$PROJECT/repository/commits/$COMMIT/comments?page=$PAGE&per_page=$SIZE' -a 'PROJECT!,COMMIT!,PAGE,SIZE;p:c:P:S:' -f 'author.username,author.email,author.created_at|date,note'

# https://docs.gitlab.com/ee/api/pipelines.html
# scope: running, pending, finished, branches, tags
# status: created, waiting_for_resource, preparing, pending, running, success, failed, canceled, skipped, manual, scheduled
# source: push, web, trigger, schedule, api, external, pipeline, chat, webide, merge_request_event, external_pull_request_event, parent_pipeline, ondemand_dast_scan, or ondemand_dast_validation
# ref, sha, username, updated_after, updated_before, yaml_errors(boolean)
# order_by: id, status, ref, updated_at or user_id (default: id)
# sort: asc or desc
define -n 'pipelines' -p '/api/v4/projects/$PROJECT/pipelines?page=$PAGE&per_page=$SIZE' -a 'PROJECT!,PAGE,SIZE;p:P:S:' -f 'id,status,ref,sha,created_at|date,updated_at|date,web_url'
define -n 'pipeline' -p '/api/v4/projects/$PROJECT/pipelines/$PIPELINE' -a 'PROJECT!,PIPELINE!;p:J:' -f 'id,user.name,ref,status,sha,duration,created_at|date,started_at|date,finished_at|date,web_url'
define -n 'pipeline:jobs' -p '/api/v4/projects/$PROJECT/pipelines/$PIPELINE/jobs?page=$PAGE&per_page=$SIZE' -a 'PROJECT!,PIPELINE!,PAGE,SIZE;p:J:P:S:' -f 'id,name,stage,status,pipeline.project_id,pipeline.id,ref,user.username,commit.id,commit.author_name,commit.title,commit.message|trim,commit.web_url,created_at|date,updated_at|date,finished_at|date,web_url'
define -n 'job' -p '/api/v4/projects/$PROJECT/jobs/$JOB' -a 'PROJECT!,JOB!;p:j:' -f 'id,status,name,stage,pipeline.project_id,pipeline.id,ref,user.username,commit.id,commit.author_name,commit.title,commit.message|trim,commit.web_url,created_at|date,updated_at|date,finished_at|date,web_url'

define -n 'job:do' -x 'POST' -p  '/api/v4/projects/$PROJECT/jobs/$JOB/$ACTION' -a 'PROJECT!,JOB!,ACTION!;p:j:a:' -f 'id,stage,name,ref,status,commit.author_name,commit.id,commit.title,created_at|date'

function ask() {
  case "$1" in
    'project@PROJECT'|'statistics@PROJECT'|'commits@PROJECT'|'commit@PROJECT'|'commit:refs@PROJECT'|'commit:comments@PROJECT'|'pipelines@PROJECT'|'pipeline@PROJECT'|'pipeline:jobs@PROJECT'|'job@PROJECT'|'job:do@PROJECT')
      invoke 'projects'
      red -i 'Project ID: '
      read PROJECT
      ;;
    'commit@COMMIT'|'commit:refs@COMMIT'|'commit:comments@COMMIT')
      invoke 'commits' -p "$PROJECT"
      red -i 'Commit ID: '
      read COMMIT
    ;;
    'pipeline@PIPELINE'|'pipeline:jobs@PIPELINE')
      invoke 'pipelines' -p "$PROJECT"
      red -i 'Pipeline ID: '
      read PIPELINE
    ;;
    'job@JOB'|'job:do@JOB')
      local PIPELINE
      ask 'pipeline'
      invoke 'pipeline:jobs' -p "$PROJECT" -J "$PIPELINE"
      red -i 'Job ID: '
      read JOB
      ;;
    'job:do@ACTION')
      green -i "Job Actions: "
      printf "%s " "${JOB_ACTIONS[@]}" | green -n
      red -i 'Your job action: '
      read ACTION
      if [ $(indexOf "$ACTION" "${JOB_ACTIONS[@]}") -eq -1 ]; then
        ask "$@"
      fi
      ;;
    'pipeline')
      invoke 'pipelines' -p "$PROJECT" -S "$GI_SIZE"
      red -i 'Pipeline ID: '
      read PIPELINE
      ;;
  esac
}

# https://docs.gitlab.com/ee/api/jobs.html
# action: play, cancel, retry
function doJob() {
  expose='EXPOSE_' invoke 'job:do' "$@"
  echo $(invoke 'job' -p $EXPOSE_PROJECT -j $EXPOSE_JOB -R | jsone "useGet(data, 'status')")
  if [ "$GB_ASYNC" -gt 0 ]; then
    echo "Waiting for job to finish..."
    local status='pending'
    while [ $status = "running" -o $status = "pending" ]; do
      echo "$status"
      sleep 3
      status=$(invoke 'job' -p $EXPOSE_PROJECT -j $EXPOSE_JOB -R | jsone "useGet(data, 'status')")
    done
  fi
}

OPTS="$OPTS""j:J:o:p:s:t:"
OPTS_MSG="$OPTS_MSG
        -j <job ID>
        -J <pipeline ID>
        -o <GITLAB_ORIGIN>
        -p <project ID>
        -s <commit sha>
        -t <GITLAB_PRIVATE_TOKEN>"
CMDS_MSG="$CMDS_MSG
        project(s)
        commit(s)
        comments
        pipeline(s)
        job(s)
        doJob [${JOB_ACTIONS[@]}]"

function parseOpts() {
  case $1 in
  t)
    GITLAB_PRIVATE_TOKEN=$OPTARG
    ;;
  esac
}
function parseCmds() {
  local args=("${@:2}")
  case $1 in
    job:do)
      doJob "${args[@]}"
      ;;
    send)
      send "${args[@]}"
      ;;
    *)
      invoke "$@"
      ;;
  esac
}
parseArgs "$@"

unset_prelude

# !/usr/bin/env bash

# usage:
# 1. alias
# alias gitlab='gitlab.sh'
# gitlab -h
# 2. run in subshell
# (gitlab.sh -h)

source $(dirname $0)/prelude.sh
GITLAB_ORIGIN=${GITLAB_ORIGIN:-}
# https://docs.gitlab.com/ee/api/index.html#personalproject-access-tokens
GITLAB_PRIVATE_TOKEN=${GITLAB_PRIVATE_TOKEN:-}
JOB_ACTIONS=(play cancel retry)
JOB_ORDERS=${JOB_ORDERS:-"code_build image_build deploy"}
# Pagination: https://docs.gitlab.com/ee/api/index.html#Pagination

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s -H 'PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN' $GITLAB_ORIGIN$@" | green 1>&2
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
define -n 'pipeline' -p '/api/v4/projects/$PROJECT/pipelines/$PIPELINE' -a 'PROJECT!,PIPELINE!;p:J:' -f 'id,user.name,ref,status,sha,duration,started_at|date,finished_at|date,web_url'
define -n 'pipeline:jobs' -p '/api/v4/projects/$PROJECT/pipelines/$PIPELINE/jobs?page=$PAGE&per_page=$SIZE' -a 'PROJECT!,PIPELINE!,PAGE,SIZE;p:J:P:S:' -f 'id,name,stage,status,pipeline.project_id,pipeline.id,ref,user.username,commit.id,commit.author_name,commit.title,commit.message|trim,commit.web_url,created_at|date,updated_at|date,finished_at|date,web_url'
define -n 'job' -p '/api/v4/projects/$PROJECT/jobs/$JOB' -a 'PROJECT!,JOB!;p:j:' -f 'id,status,name,stage,pipeline.project_id,pipeline.id,ref,user.username,commit.id,commit.author_name,commit.title,commit.message|trim,commit.web_url,created_at|date,updated_at|date,finished_at|date,web_url'

define -n 'job:do' -x 'POST' -p '/api/v4/projects/$PROJECT/jobs/$JOB/$ACTION' -a 'PROJECT!,JOB!,ACTION!;p:j:a:' -f 'id,stage,name,ref,status,commit.author_name,commit.id,commit.title,created_at|date'

function ask() {
  case "$1" in
  'project@PROJECT' | 'statistics@PROJECT' | 'commits@PROJECT' | 'commit@PROJECT' | 'commit:refs@PROJECT' | 'commit:comments@PROJECT' | 'pipelines@PROJECT' | 'pipeline@PROJECT' | 'pipeline:jobs@PROJECT' | 'job@PROJECT' | 'job:do@PROJECT')
    invoke 'projects'
    red 'Project ID: '
    read PROJECT
    ;;
  'commit@COMMIT' | 'commit:refs@COMMIT' | 'commit:comments@COMMIT')
    invoke 'commits' -p "$PROJECT"
    red 'Commit ID: '
    read COMMIT
    ;;
  'pipeline@PIPELINE' | 'pipeline:jobs@PIPELINE' | 'doPipeline@PIPELINE')
    invoke 'pipelines' -p "$PROJECT"
    red 'Pipeline ID: '
    read PIPELINE
    ;;
  'job@JOB' | 'job:do@JOB')
    local PIPELINE
    ask 'pipeline'
    invoke 'pipeline:jobs' -p "$PROJECT" -J "$PIPELINE"
    red 'Job ID: '
    read JOB
    ;;
  'job:do@ACTION')
    green "Job Actions: "
    printf "%s " "${JOB_ACTIONS[@]}" | green
    red 'Your job action: '
    read ACTION
    if [ $(indexOf "$ACTION" "${JOB_ACTIONS[@]}") -eq -1 ]; then
      ask "$@"
    fi
    ;;
  'pipeline')
    invoke 'pipelines' -p "$PROJECT" -S "$GI_SIZE"
    red 'Pipeline ID: '
    read PIPELINE
    ;;
  esac
}

blinks=(
  '.'
  '.'
  '.'
  '\b \b'
  '\b  \b\b'
  '\b   \b\b\b'
)

function waitJob() {
  expose='EXPOSE_' invoke 'job' "$@"
  echo "Waiting for job `green $EXPOSE_JOB` on project `green $EXPOSE_PROJECT` to finish..."
  local status='pending'
  local newStatus="$status"
  local cacheKey=jobStatus_$EXPOSE_JOB
  cache -k "$cacheKey" -v "$status"
  green "$status"
  while [ 1 -gt 0 ]; do
    invoke 'job' -p "$EXPOSE_PROJECT" -j "$EXPOSE_JOB" -R | jsone "useGet(data, 'status')" | cache -k "$cacheKey" -s &
    for i in "${blinks[@]}"; do
      newStatus=$(cache -k "$cacheKey")
      if [ "$newStatus" != "$status" ]; then
        green "$newStatus"
      fi
      status=$newStatus
      if [ "$status" -a "$status" != "running" -a "$status" != "pending" ]; then
        break 2
      fi
      printf "$i"
      sleep .5
    done
  done
  echo
}

# https://docs.gitlab.com/ee/api/jobs.html
# action: play, cancel, retry
function doJob() {
  expose='EXPOSE_' invoke 'job:do' "$@"
  sleep 1
  waitJob -p "$EXPOSE_PROJECT" -j "$EXPOSE_JOB"
}

function doPipeline() {
  expose='EXPOSE_' invoke 'pipeline' "$@"
  local jobList=$(invoke 'pipeline:jobs' -p $EXPOSE_PROJECT -J $EXPOSE_PIPELINE -R |
  jsone "(function() {
    const orders = '$JOB_ORDERS'.trim().split(/\s+/);
    return data.sort((a, b) => orders.indexOf(a.name) - orders.indexOf(b.name))
    .map(e => [e.id, e.status, e.name].join(' '))
    .join('\n')
    })()")

  printf "Do pipeline \033[0;32m$EXPOSE_PIPELINE\033[0m on project \033[0;32m$EXPOSE_PROJECT\033[0m with orders: \033[0;32m$JOB_ORDERS\033[0m"
  read -p "? (y/n) " -n 1 -r

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "$jobList" | while read -r line; do
      local jobId=$(echo "$line" | cut -d ' ' -f 1)
      local jobStatus=$(echo "$line" | cut -d ' ' -f 2)
      local jobName=$(echo "$line" | cut -d ' ' -f 3)
      echo "Run job `green $jobName` $jobId ($jobStatus)"
      if [[ "$jobStatus" = 'canceled' || "$jobStatus" = 'skipped' || "$jobStatus" = 'failed' || "$jobStatus" = 'manual' ]]; then
        doJob -p "$EXPOSE_PROJECT" -j "$jobId" -a 'play'
      else
        green "Job $jobName on project $EXPOSE_PROJECT already finished ($jobStatus)!"
      fi
      local rStatus=$(invoke 'job' -p "$EXPOSE_PROJECT" -j "$jobId" -R | jsone "useGet(data, 'status')")
      if [ "$rStatus" != "success" ]; then
        red "Job $jobName on project $EXPOSE_PROJECT failed($rStatus)!"
        exit 1
      fi
    done
  fi
}

OPTS="$OPTS""t:"
OPTS_MSG="$OPTS_MSG
        -t <GITLAB_PRIVATE_TOKEN>"
CMDS_MSG="$CMDS_MSG
        projects
        project
        statistics
        commits
        commit
        commit:refs
        commit:comments
        pipelines
        pipeline
        pipeline:jobs
        job
        job:do"

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
  pipeline:do)
    doPipeline "${args[@]}"
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

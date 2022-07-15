# !/usr/bin/env bash

# usage:
# 1. alias
# alias jira='jira.sh'
# jira -h
# 2. run in subshell
# (jira.sh -h)

source $(dirname $0)/prelude.sh

JIRA_ORIGIN=${JIRA_ORIGIN:-}
JIRA_USERNAME=${JIRA_USERNAME:-}
JIRA_PASSWORD=${JIRA_PASSWORD:-}

DEFAULT_STATUS_FILTER='待排期,开发中,待开发'
ISSUE_FORMAT="fields.issuetype.name,key,fields.status.name,fields.reporter.displayName,fields.created|date,fields.updated|date,self,key|jiraUrl,fields.summary|trim"

GS_NODE_HELPERS="$GS_NODE_HELPERS;
Object.assign(FILTERS, {
  jiraUrl(key) {
    return '$JIRA_ORIGIN/browse/' + key
  },
})
"

function ask() {
  case "$1" in
  'statuses@PROJECT_KEY')
    invoke 'projects'
    red -i 'Project Key: ' 1>&2
    read PROJECT_KEY
    ;;
  'issue@ISSUE_KEY' | 'issue:desc@ISSUE_KEY' | 'issue:comments@ISSUE_KEY' | 'issue:transitions@ISSUE_KEY' | 'issue:comment:do@ISSUE_KEY' | 'issue:status:do@ISSUE_KEY')
    issues
    red -i 'Issue Key: ' 1>&2
    read ISSUE_KEY
    ;;
  'issue:status:do@TRANSITION_ID')
    invoke 'issue:transitions' -i "$ISSUE_KEY"
    red -i 'Transition ID: ' 1>&2
    read TRANSITION_ID
    ;;
  esac
}

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s --basic --user $JIRA_USERNAME:$JIRA_PASSWORD $JIRA_ORIGIN$@" | red 1>&2
  [[ $GI_VERBOSE -gt 1 ]] && curl -v --basic --user $JIRA_USERNAME:$JIRA_PASSWORD $JIRA_ORIGIN$@ || curl -s --basic --user $JIRA_USERNAME:$JIRA_PASSWORD $JIRA_ORIGIN$@
}

define -n 'projects' -p '/rest/api/latest/project' -f 'name,key,id,self'
# https://docs.atlassian.com/software/jira/docs/api/REST/8.7.0/#api/2/user-findUsers
define -n 'users' -p '/rest/api/latest/user/search?username=$USERNAME' -a 'USERNAME;u:' -f 'displayName,name,key,active,emailAddress,self' -v 'USERNAME:%27%27'
define -n 'statuses' -p '/rest/api/latest/project/$PROJECT_KEY/statuses' -a 'PROJECT_KEY!;p:' -f 'id,name,statuses'
define -n 'issues' -p '/rest/api/latest/search?jql=$JQL&maxResults=$SIZE&startAt=$START' -a 'JQL,SIZE,START,FORMAT;j:S:s:f:' -f "issues:$ISSUE_FORMAT"
define -n 'issue' -p '/rest/api/latest/issue/$ISSUE_KEY' -a 'ISSUE_KEY!FORMAT;i:f:' -f "$ISSUE_FORMAT,fields.description"
define -n 'issue:desc' -p '/rest/api/latest/issue/$ISSUE_KEY' -a 'ISSUE_KEY!;i:' -f "key|jiraUrl,fields.summary,fields.description"
define -n 'issue:comments' -p '/rest/api/latest/issue/$ISSUE_KEY/comment' -a 'ISSUE_KEY!;i:' -f 'id,body,author.displayName,created|date'
define -n 'issue:transitions' -p '/rest/api/latest/issue/$ISSUE_KEY/transitions' -a 'ISSUE_KEY!;i:' -f 'transitions:id,name'
define -n 'issue:comment:do' -x 'POST' -p '/rest/api/latest/issue/$ISSUE_KEY/comment' -a 'ISSUE_KEY!;i:'
define -n 'issue:status:do' -x 'POST' -p '/rest/api/latest/issue/$ISSUE_KEY/transitions' -h 'content-type:application/json' -d '{"transition":{"id":"$TRANSITION_ID"}}' -a 'ISSUE_KEY!,TRANSITION_ID!;i:t:'

function issues() {
  local OPTARG
  local OPTIND
  local status=$DEFAULT_STATUS_FILTER
  local start=0
  local assignee='currentuser()'
  local tableType="$GS_TABLE_TYPE"
  local moreOpts=()

  while getopts ':hs:S:a:t:' opt; do
    case $opt in
    s) status=$OPTARG ;;
    S) start=$OPTARG ;;
    a) assignee=$OPTARG ;;
    t) tableType=$OPTARG ;;
    h)
      echo "Usage: $0 issues [options]"
      echo "  -s status, default: $status"
      echo "  -S start, default: $start"
      echo "  -a assignee, default: $assignee"
      echo "  -t tableType, default: $tableType"
      exit 0
      ;;
    esac
  done

  local jql=$(node -e "
  const status = '$status'.trim()
  let jql = 'assignee=$assignee'
  if (status) {
    jql += ' and status in (' + status + ')'
  }
  console.log(encodeURIComponent(jql))
  ")
  local data=$(invoke 'issues' -j "$jql" -s "$start" -S 10 -R "${moreOpts[@]}")

  [[ $RAW = 1 ]] && sprintf -n -i "$data" || sprintf -n -i "$data" | jsonf -f "issues:$ISSUE_FORMAT" -t "$tableType"

  local total=$(sprintf -i "$data" | jsone "data.total")
  local next=$(sprintf -i "$data" | jsone "data.startAt + data.maxResults")
  [[ $next -lt $total ]] && {
    issues -s "$status" -S "$next" -a "$assignee" -t $([ "$tableType" == 'th' ] && echo 'table' || echo "$tableType")
  } || {
    echo "total: $total"
  }
}

function page() {
  open $(invoke 'issue' -i "$1" -R | jsone "useFilter(data.key, 'jiraUrl')")
}

OPTS="$OPTS""u:w:"
OPTS_MSG="$OPTS_MSG
        -u <jira username>
        -w <jira password>"
CMDS_MSG="$CMDS_MSG
        projects
        users
        statuses
        issues
        issue:desc
        issue:comments
        issue:transitions
        issue:comment:do
        issue:status:do
        saveIssues
        page"
function parseOpts() {
  case $1 in
  u)
    JIRA_USERNAME=$OPTARG
    ;;
  w)
    JIRA_PASSWORD=$OPTARG
    ;;
  esac
}
function parseCmds() {
  local args=("${@:2}")
  case $1 in
  board)
    open "$JIRA_ORIGIN/secure/RapidBoard.jspa"
    ;;
  page)
    page "${args[@]}"
    ;;
  issues)
    issues "${args[@]}"
    ;;
  *)
    invoke "$@"
    ;;
  esac
}
parseArgs "$@"

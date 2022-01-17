# !/usr/bin/env bash

# Reserved Variables:

# int type
GI_PAGE=1
GI_SIZE=10
# bool type
GI_VERBOSE=0
GB_ASYNC=0
GB_COLORFUL=0
# string type
GS_QUERY=''
GS_COLS=''
GS_PRASER='jsonf' # cat, json, jsonf
GS_TABLE_TYPE='th' # table, th, list
# Reserved for `invoke` and `ask`.
GI_ASK_MAX_COUNT=10 # max ask count of per `invoke` argument.
GB_ASK_ARG_STATE=0 # settle state of the asked `invoke` argument, 1 is settled, 0 is unsetled (set by `ask`).
GS_ASK_ARG_VALUE='' # value of the asked `invoke` argument (set by `ask`).

OPTS="AcC:hP:Q:rRS:T:vV"
CMDS=""
OPTS_MSG="Options:
        -A asynchronous
        -c colorful output
        -C <columns>
        -P <page=1>
        -S <size=10>
        -Q <query>
        -r Raw response, without parsed.
        -R Whole response with parsed json.
        -T <output format> value can be table, th(table_with_head), list.
        -v Verbose, curl output etc.
        -V Print curl command."
CMDS_MSG="Commands:"

GS_NODE_HELPERS=$(cat $(dirname $0)/prelude.node.js)

function unset_prelude() {
  unset GI_PAGE
  unset GI_SIZE
  unset GI_VERBOSE
  unset GB_ASYNC
  unset GB_COLORFUL
  unset GS_QUERY
  unset GS_COLS
  unset GS_PRASER
  unset GS_TABLE_TYPE
  unset GI_ASK_MAX_COUNT
  unset GB_ASK_ARG_STATE
  unset GS_ASK_ARG_VALUE
  unset OPTS
  unset CMDS
  unset OPTS_MSG
  unset CMDS_MSG
  unset GS_NODE_HELPERS
  unset helpMsg
  unset parseOpts
  unset parseArgs
  unset parseCmds
  unset parseCommonOpts
  unset js
  unset json
  unset jsone
  unset jsonf
  unset red
  unset green
  unset blue
  unset sprintf
  unset indexOf
  unset _defines
  unset define
  unset parseDefine
  unset invoke
  unset unset_prelude
}

function helpMsg() {
  echo "Usage: $0 [OPTIONS] [COMMAND]

  $OPTS_MSG

  $CMDS_MSG
  "
}

function parseOpts() {
  echo 'default'
}
function parseCmds() {
  echo 'default'
}
function parseCommonOpts() {
  case $1 in
    A) GB_ASYNC=1;;
    c) GB_COLORFUL=1;;
    C) GS_COLS=$OPTARG;;
    P) GI_PAGE=$OPTARG;;
    Q) GS_QUERY=$OPTARG;;
    S) GI_SIZE=$OPTARG;;
    T) GS_TABLE_TYPE=$OPTARG;;
    v) GI_VERBOSE=2;;
    V) GI_VERBOSE=1;;
    r) GS_PRASER='cat';;
    R) GS_PRASER='json';;
    h) helpMsg; exit 0;;
    \?) echo "Invalid option: -$OPTARG" >&2; helpMsg; exit 1;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
  esac
}
function parseArgs() {
  local OPTIND
  local OPTARG
  while getopts "$OPTS" opt; do
    parseOpts $opt
    parseCommonOpts $opt
  done
  parseCmds ${!OPTIND} "${@:`expr $OPTIND + 1`}"
}

function js() {
  xargs -0 node -e "$1"
}

function json() {
  local hasCode=false
  [[ $# -gt 0 ]] && {
    hasCode=true
  }
  js "
  $GS_NODE_HELPERS
  const data = JSON.parse(process.argv[1]);
  if ($hasCode) {
      $1
    } else {
      console.log(JSON.stringify(data, null, 2));
    }
  "
}

function jsone() {
  json 'process.stdout.write(`${'"$1"'}`)'
}

function jsonf() {
  local cols=$1
  shift
  local aligned=0
  local iterKey=''
  local spanJoin
  local lineJoin='\n'
  local tableType=$GS_TABLE_TYPE
  local OPTIND
  local OPTARG

  while getopts ":k:s:l:t:ha" opt; do
    case $opt in
      s) spanJoin=$OPTARG;;
      l) lineJoin=$OPTARG;;
      k) iterKey=$OPTARG;;
      a) aligned=1;;
      t) tableType=$OPTARG;;
      h)
        echo "Usage: $0 [GS_COLS] [OPTIONS]

        -s <span seperator>
        -l <line seperator>
        -k <root data key>
        -a align table columns
        -h
        "
        exit 0
        ;;
    esac
  done

  if [ -z "$spanJoin" ]; then
    spanJoin='\t'
    if [ $tableType == 'list' ]; then
      spanJoin='\n'
    fi
  fi

  case $GS_PRASER in
    'cat')
      cat
      ;;
    'json')
      json
      ;;
    'jsonf')
      json "
      console.log(useJsonf({
        data: data,
        cols: '$cols,$GS_COLS',
        iterKey: '$iterKey',
        colorful: $GB_COLORFUL,
        aligned: $aligned,
        format: '$tableType',
        spanJoin: '$spanJoin',
        lineJoin: '$lineJoin'
      }));
      "
    ;;
  esac
}

function red() {
  sprintf -f "\033[0;31m%s\033[0m" "$@"
}
function green() {
  sprintf -f "\033[0;32m%s\033[0m" "$@"
}
function blue() {
  sprintf -f "\033[0;33m%s\033[0m" "$@"
}

function sprintf() {
  local OPTARG
  local OPTIND
  local input=()
  local inputFlag=0
  local format=%s
  local postfix
  local args=()
  while getopts ":i:f:v:n" opt; do
    case "$opt" in
      i) input+=("$OPTARG"); inputFlag=1;;
      f) format="$OPTARG";;
      n) postfix='\n';;
      v)
        args+=('var')
        args+=("$OPTARG")
      ;;
    esac
  done

  if [ "$inputFlag" -gt 0 ]; then
    printf "${args[@]}" "$format" "$input"
  else
    xargs -0 printf "${args[@]}" "$format"
  fi
  printf "$postfix"
}

function debug() {
  if [ "$DEBUG" = 'true' ]; then
    red -n -i "$@" 1>&2
  fi
}

function indexOf() {
  local el=$1
  local arr=("${@:2}")
  for i in $(seq 0 $((${#arr[@]} - 1))); do
    if [[ ${arr[$i]} == $el ]]; then
      echo $i
      return
    fi
  done
  echo -1
}

_defines=()

function define() {
  local OPTARG
  local OPTIND
  local name
  local mixedArgs
  local def=()
  while getopts ":n:p:a:f:x:d:h:v:H" opt; do
    case $opt in
    n) name="$OPTARG";;
    a) mixedArgs="$OPTARG";;
    p) def+=(-p "$OPTARG");;
    f) def+=(-f "$OPTARG");;
    x) def+=(-m "$OPTARG");;
    d) def+=(-d "$OPTARG");;
    h) def+=(-h "$OPTARG");;
    v) def+=(-v "$OPTARG");;
    H)
      echo "Usage: define [OPTIONS]
        -n <name>
        -p <path>
        -a <mixed args>, e.g. '-a USERNAME,TOKEN;u:t:', required arguments are postfixed with '!', e.g. '-a USERNAME,TOKEN!;u:t:'
        -f <format>
        -x <method>
        -d <data>
        -h <header> e.g. -h 'Content-Type:application/json' -h 'Accept:application/json'
        -v <args default value> value prefixed with `<argName>:`, e.g. -v 'USERNAME:admin' -v 'TOKEN:123456'
        -H help message
      "
      return
      ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    esac
  done
  local args=$(grep -o '^[A-Z][A-Z0-9_,!]\+' <<<"$mixedArgs")
  local opts=$(grep -o '[A-Za-z:]\+$' <<<"$mixedArgs")
  opts=${opts/#:/}
  def+=(-a "$args,QUERY,FORMAT,RAW")
  def+=(-o ":$opts"'Q:F:R')
  _defines+=("$name ${def[*]}")
}

function parseDefine() {
  _name="$1"
  local def
  for df in "${_defines[@]}"; do
    if [ "${df:0:${#_name}+1}" = "$_name " ]; then
      def="$df"
      break
    fi
  done
  [[ -z "$def" ]] && echo "No such define: $_name" && exit 1;
  set -- ${def[@]}
  shift
  local OPTARG
  local OPTIND
  while getopts ":p:a:o:f:m:d:h:v:" opt; do
    case $opt in
    n) _name=$OPTARG;;
    p) _path=$OPTARG;;
    a) _args=$OPTARG;;
    o) _opts=$OPTARG;;
    f) _format=$OPTARG;;
    m) _method=$OPTARG;;
    d) _data=$OPTARG;;
    h) _headers+=($OPTARG);;
    v) _defaults+=($OPTARG);;
    esac
  done
}

function invoke() {
  local _name="$1"
  shift
  local _path
  local _args
  local _opts
  local _format
  local _method
  local _data
  local _headers=()
  local _defaults=()
  parseDefine "$_name"
  debug "Invoking $_name"
  debug "  path: $_path"
  debug "  args: $_args"
  debug "  opts: $_opts"
  debug "  format: $_format"
  debug "  method: $_method"
  debug "  data: $_data"
  debug "  headers: $_headers"
  debug "  defaults: $_defaults"
  local _argsList=($(grep -o '[A-Z][A-Z0-9_]\+!\?' <<<$_args))
  local _pureArgsList=($(grep -o '[A-Z][A-Z0-9_]\+' <<<$_args))
  local _optsList=($(grep -o '[a-zA-Z]' <<<$_opts))

  # default args
  local QUERY
  local FORMAT
  local RAW=1 # reversed
  # parse args
  local _caseArms=''
  local _argIdxList=$(seq 0 $(expr ${#_pureArgsList[@]} - 1))
  # apply default values.
  for _d in "${_defaults[@]}"; do
    _argName=$(grep -o '^[A-Z][A-Z0-9_]\+' <<<$_d)
    _argDefault=${_d:${#_argName}+1}
    local _argIdx=$(indexOf "$_argName" "${_pureArgsList[@]}")
    if [ "$_argIdx" -gt -1 ]; then
      local "$_argName"="${_argDefault#:}"
    fi
  done
  # create case arms to retrieve arguments values
  for idx in ${_argIdxList[@]}; do
    local "${_pureArgsList[idx]}"
    _caseArms+="
      ${_optsList[$idx]})
        local ${_pureArgsList[idx]}=\$OPTARG
        ;;
    "
  done
  _caseArms+="
      \?)
        echo Invalid option: -\$OPTARG >&2;
        exit 1
        ;;
      :)
        echo Option -\$OPTARG requires an argument. >&2;
        exit 1
        ;;
      h)
        echo \"Usage: invoke $_name [OPTIONS]

          options:
          ${_optsList[@]}

          arguments:
          (${_argsList[@]})

          -h help message

          Tips:
            1. you can set variable 'expose' before command likes 'expose=EXPOSE_ invoke ...',
               then all the arguments (defined by 'define' function) will be exposed to global through new arguments named with 'EXPOSE_<argument_name>'.
        \";
        exit 0
        ;;
  "
  # retrieve arguments values from options
  local OPTARG
  local OPTIND
  while getopts "$_opts"h opt; do
    eval "
    case \$opt in
      $_caseArms
    esac
    "
  done
  # check and ask required arguments
  local _index=0
  while [ "$_index" -lt "${#_pureArgsList[@]}" ]; do
    if [ "${_argsList[_index]: -1}" = '!' ]; then
      debug "Required argument $_index: ${_pureArgsList[_index]}"
      local _askCount=0
      while [ -z "${!_pureArgsList[_index]}" ]; do
        _askCount=$(expr $_askCount + 1)
        if [ "$_askCount" -gt "$GI_ASK_MAX_COUNT" ]; then
          echo "Too many invalid arguments: $_name@${_pureArgsList[_index]}"
          exit 1
        fi
        debug "ask $_askCount: $_name@${_pureArgsList[_index]}"
        ask "$_name@${_pureArgsList[_index]}"
        debug "asked $_name@${_pureArgsList[_index]}:${!_pureArgsList[_index]}"
      done
    fi
    _index=$(expr $_index + 1)
  done
  # assign arguments values in the path and data
  local _realPath="$_path"
  local _realData="$_data"
  for idx in ${_argIdxList[@]}; do
    _realPath=${_realPath//"\$${_pureArgsList[idx]}"/"${!_pureArgsList[idx]}"}
    _realData=${_realData//"\$${_pureArgsList[idx]}"/"${!_pureArgsList[idx]}"}
  done
  # send
  local _sendString="send '$_realPath'"
  if [ -n "$_method" ]; then
    _sendString="$_sendString -X $_method"
  fi
  if [ -n "$_realData" ]; then
    _sendString="$_sendString -d $_realData"
  fi
  for _h in "${_headers[@]}"; do
    _sendString="$_sendString -H $_h"
  done

  if [ "$RAW" = 1 ]; then
    if [ -n "$FORMAT" ]; then
      eval "$_sendString"  | jsonf "$FORMAT"
    elif [ -n "$_format" ]; then
      eval "$_sendString"  | jsonf "$_format"
    else
      eval "$_sendString"  | jsonf
    fi
  else
    eval "$_sendString"
  fi
  if [ -n "$expose" ]; then
    for arg in "${_pureArgsList[@]}"; do
      debug "$expose,$expose$arg,${!arg}"
      eval "$expose$arg=${!arg}"
    done
  fi
}

# !/usr/bin/env bash

# Reserved Variables:

# int type
GI_PAGE=1
GI_SIZE=10
# bool type
GI_VERBOSE=0
GB_ALIGN=1
GB_ASYNC=0
GB_COLORFUL=1
# string type
GS_QUERY=''
GS_COLS=''
GS_PRASER='jsonf'  # cat, json, jsonf
GS_TABLE_TYPE='th' # table, th, list
# Reserved for `invoke` and `ask`.
GI_ASK_MAX_COUNT=10 # max ask count of per `invoke` argument.
GB_ASK_ARG_STATE=0  # settle state of the asked `invoke` argument, 1 is settled, 0 is unsetled (set by `ask`).
GS_ASK_ARG_VALUE='' # value of the asked `invoke` argument (set by `ask`).

OPTS="aAcC:hP:Q:rRS:T:LvV"
CMDS=""
OPTS_MSG="Options:
        -a not align output
        -A wait for asynchronous job to finish
        -c no colorful output
        -C <columns>
        -P <page=1>
        -S <size=10>
        -Q <query>
        -r Raw response, without parsed.
        -R Whole response with parsed json.
        -T <output format> value can be table, th(table_with_head), list.
        -L Same as -T list
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
  unset send
  unset ask
  unset cache
}

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s $@" | red 1>&2
  [[ $GI_VERBOSE -gt 1 ]] && curl -v $@ || curl -s $@
}

function encode() {
  echo -n "$@" | base64
}
function decode() {
  echo -n "$@" | base64 --decode
}

function helpMsg() {
  green "Usage: $0 [OPTIONS] [COMMAND]

  $OPTS_MSG

  $CMDS_MSG
  "
}

function parseOpts() {
  echo 'default' >/dev/null
}

function parseCmds() {
  echo 'default' >/dev/null
}

function parseCommonOpts() {
  case $1 in
  a) GB_ALIGN=0 ;;
  A) GB_ASYNC=1 ;;
  c) GB_COLORFUL=0 ;;
  C) GS_COLS=$OPTARG ;;
  P) GI_PAGE=$OPTARG ;;
  Q) GS_QUERY=$OPTARG ;;
  S) GI_SIZE=$OPTARG ;;
  T) GS_TABLE_TYPE=$OPTARG ;;
  L) GS_TABLE_TYPE=list ;;
  v) GI_VERBOSE=2 ;;
  V) GI_VERBOSE=1 ;;
  r) GS_PRASER='cat' ;;
  R) GS_PRASER='json' ;;
  h)
    helpMsg
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    helpMsg
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
}
function parseArgs() {
  local OPTIND
  local OPTARG
  while getopts "$OPTS" opt; do
    parseOpts $opt
    parseCommonOpts $opt
  done
  parseCmds ${!OPTIND} "${@:$(expr $OPTIND + 1)}"
}

# js
function js() {
  local OPTIND
  local OPTARG
  local input
  local inputed=0
  local code="$1"
  local neat=0
  shift
  while getopts ":i:nh" opt; do
    case $opt in
    i)
      input=$OPTARG
      inputed=1
      ;;
    n) neat=1 ;; # neat (without helpers)
    h)
      green "Usage: js <CODE> [OPTIONS]
        pipeline is supported.
        -i <input>
        -n neat (without helpers)
        -h help
      "
      exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    esac
  done
  [[ $neat -eq 0 ]] && code="$GS_NODE_HELPERS
  $code"
  [[ $inputed -gt 0 ]] && node -e "$code" "$input" || xargs -0 node -e "$code"
}

# json or jsonp
function json() {

  debug "json:$#:$@"

  local coded=false
  if [[ $1 && ${1:0:1} != '-' ]]; then
    local code="$1"
    local coded=true
    shift
  fi

  local OPTIND
  local OPTARG
  local jsonp
  while getopts ':p:h' opt; do
    case $opt in
    p) jsonp=$OPTARG ;;
    h)
      green "Usage: json [CODE] [OPTIONS]
        pipeline is supported.
        -p <jsonp key>
        -h help

        * More options to see $(js)
      "
      exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    esac
  done

  debug "jsonp:$jsonp"
  debug "code:$code"

  js "
  const jsonp = '$jsonp';
  const data = jsonp ? useFilter(process.argv[1], ['jsonp', jsonp]) : JSON.parse(process.argv[1]);
  if ($coded) {
    $code
  } else {
    console.log(JSON.stringify(data, null, 2));
  }
  " "$@"
}

function jsone() {
  json 'process.stdout.write(`${'"$1"'}`)'
}

function jsonf() {

  debug "jsonf:$#:$@"

  local cols=''
  local aligned=$GB_ALIGN
  local iterKey=''
  local spanJoin
  local lineJoin='\n'
  local tableType=$GS_TABLE_TYPE
  local jsonp
  local sorts=''
  local OPTIND
  local OPTARG

  while getopts ":af:k:l:p:s:t:z:h" opt; do
    case $opt in
    a) aligned=1 ;;
    f) cols="$OPTARG" ;;
    k) iterKey="$OPTARG" ;;
    l) lineJoin="$OPTARG" ;;
    p) jsonp="$OPTARG" ;;
    s) spanJoin="$OPTARG" ;;
    t) tableType="$OPTARG" ;;
    z) sorts="$OPTARG" ;;
    h)
      green "Usage: jsonf <code> [OPTIONS]
        -a align table columns
        -s <span seperator>
        -z <sorts>
        -l <line seperator>
        -k <root data key>
        -f <columns template string>
        -t <table type>
        -p <jsonp key>
        -h help
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

  local args=()

  [[ -n "$jsonp" ]] && args+=(-p "$jsonp")

  debug "args:${#args[@]}:${args[@]}"

  case $GS_PRASER in
  'cat')
    cat
    ;;
  'json')
    json "${args[@]}"
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
        lineJoin: '$lineJoin',
        sorts: '$sorts'
      }));
      " "${args[@]}"
    ;;
  esac
}

function red() {
  [[ $# -gt 0 ]] && printf "\033[0;31m%s\033[0m\n" "$*" || xargs -0 printf "\033[0;31m%s\033[0m" 
}
function green() {
  [[ $# -gt 0 ]] && printf "\033[0;32m%s\033[0m\n" "$*" || xargs -0 printf "\033[0;32m%s\033[0m" 
}
function blue() {
  [[ $# -gt 0 ]] && printf "\033[0;33m%s\033[0m\n" "$*" || xargs -0 printf "\033[0;33m%s\033[0m" 
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
    echo "sprintf: $opt, $OPTARG"
    case "$opt" in
    i)
      input+=("$OPTARG")
      inputFlag=1
      ;;
    f) format="$OPTARG" ;;
    n) postfix='\n' ;;
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
  if [ -n "$DEBUG" ]; then
    echo "$*" | while IFS= read line ; do
      printf "\033[0;31m[DEBUG:`realpath ${BASH_SOURCE[0]}`:$LINENO]\033[0m \033[0;37m%s\033[0m\n" "$line"
    done
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
  while getopts ":n:p:a:f:x:d:h:v:z:H" opt; do
    local encoded=`encode "$OPTARG"`
    case $opt in
    a) mixedArgs="$OPTARG" ;;
    n) name="$OPTARG" ;;
    p) def+=(-p "$encoded") ;;
    f) def+=(-f "$encoded") ;;
    x) def+=(-m "$encoded") ;;
    d) def+=(-d "$encoded") ;;
    h) def+=(-h "$encoded") ;;
    v) def+=(-v "$encoded") ;;
    z) def+=(-z "$encoded") ;;
    H)
      green "Usage: define [OPTIONS]
        -n <name>
        -p <path>
        -a <arguments>, e.g. '-a USERNAME,TOKEN;u:t:'
                        * required arguments are postfixed with '!', e.g. '-a USERNAME,TOKEN!;u:t:'
                        * QUERY,FORMAT,JSONP,RAW (Q:F:J:R respectively) are reserved and provided by default.
        -f <format> e.g. '-f items:id,name,created_at|date'
                        '-f iterKey:/fromRootCol1,/fromRootCol2,col1,col2|filter1|filter2,col3'
        -x <method>
        -d <data>
        -h <header> e.g. -h 'Content-Type:application/json' -h 'Accept:application/json'
        -v <arguments default value> value prefixed with '<argName>:', e.g. -v 'USERNAME:admin' -v 'TOKEN:123456'
        -z <sorts> e.g. -z '+created,-name'
        -H help message
      "
      return
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Show help with -H option." >&2
      exit 1
      ;;
    esac
  done
  local args=$(grep -o '^[A-Z][A-Z0-9_,!]\+' <<<"$mixedArgs")
  local opts=$(grep -o '[A-Za-z:]\+$' <<<"$mixedArgs")
  opts=${opts/#:/}
  def+=(-a `encode "$args,QUERY,FORMAT,JSONP,RAW"`)
  def+=(-o `encode ":$opts"'Q:F:J:R'`)
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
  debug "df '$_name': ${def[@]}"
  [[ -z "$def" ]] && red "No such define: $_name" && exit 1
  set -- ${def[@]}
  shift
  local OPTARG
  local OPTIND
  while getopts ":p:a:o:f:m:d:h:v:z:" opt; do
    local decoded=`decode "$OPTARG"`
    debug "df opts '$opt': $decoded"
    case $opt in
      n) _name="$OPTARG" ;;
      p) _path="$decoded" ;;
      a) _args="$decoded" ;;
      o) _opts="$decoded" ;;
      f) _format="$decoded" ;;
      m) _method="$decoded" ;;
      d) _data="$decoded" ;;
      h) _headers+=("$decoded") ;;
      v) _defaults+=("$decoded") ;;
      z) _sorts="$decoded" ;;
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
  local _sorts
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
  debug "  sorts: $_sorts"
  local _argsList=($(grep -o '[A-Z][A-Z0-9_]\+!\?' <<<$_args))
  local _pureArgsList=($(grep -o '[A-Z][A-Z0-9_]\+' <<<$_args))
  local _optsList=($(grep -o '[a-zA-Z]' <<<$_opts))

  # reserved args
  local QUERY
  local FORMAT
  local JSONP
  local RAW=1
  # parse args
  local _caseArms=''
  local _argIdxList=$(seq 0 $(expr ${#_pureArgsList[@]} - 1))
  # apply default values.
  for _d in "${_defaults[@]}"; do
    local _argName=$(grep -o '^[A-Z][A-Z0-9_]\+' <<<$_d)
    local _argDefault=${_d:${#_argName}+1}
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
        debug "ask $_askCount""th: $_name@${_pureArgsList[_index]}"
        ask "$_name@${_pureArgsList[_index]}"
        debug "asked $_name@${_pureArgsList[_index]}: ${!_pureArgsList[_index]}"
      done
    fi
    _index=$(expr $_index + 1)
  done
  green assign arguments values in the path and data
  local _realPath="$_path"
  local _realData="$_data"
  for idx in ${_argIdxList[@]}; do
    _realPath=${_realPath//"\$${_pureArgsList[idx]}"/"${!_pureArgsList[idx]}"}
    _realData=${_realData//"\$${_pureArgsList[idx]}"/"${!_pureArgsList[idx]}"}
  done
  # send
  local _sendArgs=("$_realPath")

  [[ -n "$_method" ]] && _sendArgs+=(-X "$_method")
  [[ -n "$_realData" ]] && _sendArgs+=(-d "$_realData")
  for _h in "${_headers[@]}"; do
    _sendArgs+=(-H "$_h")
  done

  local _jsonfArgs=()

  [[ -n "$_format" ]] && _jsonfArgs+=(-f "$_format") || ([[ -n "$FORMAT" ]] && _jsonfArgs+=(-f "$FORMAT"))
  [[ -n "$JSONP" ]] && _jsonfArgs+=(-p "$JSONP")
  [[ -n "$_sorts" ]] && _jsonfArgs+=(-z "$_sorts")

  debug "jsonf args: $_jsonfArgs"

  [[ "$RAW" = 1 ]] && send "${_sendArgs[@]}" | jsonf "${_jsonfArgs[@]}" || send "${_sendArgs[@]}"

  if [ -n "$expose" ]; then
    for arg in "${_pureArgsList[@]}"; do
      debug "$expose,$expose$arg,${!arg}"
      eval "$expose$arg=${!arg}"
    done
  fi
}

function cache() {
  local store=$(dirname $0)/.cache
  local OPTIND
  local OPTARG
  local key
  local value
  local hasKey=0
  local hasValue=0
  local saving=0
  while getopts :k:v:s OPT; do
    case "$OPT" in
    f) store="$OPTARG" ;;
    k)
      key="$OPTARG"
      hasKey=1
      ;;
    v)
      value="$OPTARG"
      hasValue=1
      ;;
    s) saving=1 ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    \?)
      echo "Usage: cache [-f store] [-k key] [-v value] [-s]

        -k <key>, get/set value in cache.
        -v <value>, set value directly, taking precedence over -s.
        -f <filename=.cache>, cache file.
        -s, set value from stdin.
      "
      exit 0
      ;;
    esac
  done
  if [ "$hasKey" -eq 1 ]; then
    # set
    if [ "$hasValue" -eq 1 -o "$saving" -eq 1 ]; then
      if [ "$hasValue" -ne 1 ]; then
        read value
      fi
      if [ $(sed -n "/^$key=/p" "$store") ]; then
        sed -i "s/^$key=.*/$key=$value/g" "$store"
      else
        echo "$key=$value" >>"$store"
      fi
    else
      cat "$store" | sed -n "s/^$key=\(.*\)/\1/p"
    fi
  fi
}

if [ $(basename $0) = 'prelude.sh' ]; then
  function parseCmds() {
    args="${@:2}"
    case $1 in
    js) js "${args[@]}" ;;
    json) json "${args[@]}" ;;
    jsone) jsone "${args[@]}" ;;
    jsonf) jsonf "${args[@]}" ;;
    jsonp) jsonp "${args[@]}" ;;
    sprintf) sprintf "${args[@]}" ;;
    esac
  }
  CMDS_MSG="$CMDS_MSG
      js
      json
      jsone
      jsonf
      jsonp
      sprintf
      "
  parseArgs "$@"
fi

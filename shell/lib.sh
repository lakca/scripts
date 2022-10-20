#! /usr/bin/env bash

pythonInstalled=$(which python3 >/dev/null && echo 1 || echo 0)

_dirname=$(dirname $0)

if [[ $pythonInstalled -eq 1 && -z $PURE ]]; then
  function jsonparser() {
    local OPTIND
    local data
    local format
    while getopts 'd:f:' opt; do
      case $opt in
        d) data="$OPTARG";;
        f) format="$OPTARG";;
      esac
    done
    printf %s "$data" | python3 $_dirname/lib.py "$format"
  }
fi

function debug() {
  if [[ -n "$DEBUG" ]]; then
    echo $* | while IFS=$'\n' read line ; do
      # echo ${FUNCNAME[@]} ${BASH_SOURCE[@]}, ${BASH_LINENO[@]} 1>&2
      printf "\033[0;31m[DEBUG:`realpath ${BASH_SOURCE[@]:1:1}`:${BASH_LINENO[@]:0:1}]\033[0m \033[0;37m%s\033[0m\n" "$line" 1>&2
    done
  fi
}

function escapeUnicode() {
  printf '%s' "$*" | sed -E 's/\\u0([1-9a-f]{3})/\\x\1/gI' \
  | sed -E 's/\\u00([1-9a-f]{2})/\\x\1/gI' \
  | sed -E 's/\\u000([1-9a-f]{1})/\\x\1/gI' \
  | sed -E 's/\\"/\\x22/gI'
}

function escapeSpace() {
  printf '%s' "$*" | sed -E 's/ /\\x20/g' \
    | sed -E 's/\\n/\\xa/g' \
    | sed -E 's/\\t/\\x9/g' \
    | sed -E 's/\\v/\\xb/g' \
    | sed -E 's/\\f/\\xc/g' \
    | sed -E 's/\\r/\\xd/g'
}

function print_record() {
  local -a fields=()
  local -a values=()
  local -a types=()
  local id=''
  local OPTIND
  while getopts ':a:v:n:t:' opt; do
    case "$opt" in
      a) fields+=($OPTARG);;
      v) values+=($OPTARG);;
      t) types+=($OPTARG);;
      n) id=$OPTARG;;
    esac
  done
  local primary=0
  for index in "${!fields[@]}"; do
    if [[ $primary -eq 0 ]]; then
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: 【"$id"】\033[1;31m${values[@]:$index:1}\033[0m"
    else
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: \033[32m${values[@]:$index:1}\033[0m"
      if [[ -n $ITERM_SESSION_ID && $IMGCAT && "${types[@]:$index:1}" = 'img' ]]; then
        curl -s "${values[@]:$index:1}" | imgcat --height=5
      fi
    fi
    primary=1
  done
}

function selectColumns() {
  local array=($1)
  local skip=${2:-1}
  local length=${#array[@]}
  local -a left=()
  debug $1
  debug $2
  for i in $(seq 0 $((skip+1)) $((length-1))); do
    left+=(${array[@]:$i:1})
  done
  debug ${left[@]}
  echo ${left[@]}
}

function ensureFolder() {
  [[ ! -d $1 ]] && mkdir -p $1
}

function resolveLink() {
  local link=${1//\?*/}
  link=${link//\\\?*/}
  link=${link//\#*/}
  link=${link//\\\#*/}
  local parts=(`echo $link | grep -oE '[^\/]+'`)
  echo "${parts[*]}"
}

function ask() {
  local values=($1)
  local value="$2"
  for i in "${!values[@]}"; do
    if [[ $value = $i || $value = ${values[@]:$i:1} ]]; then
      printf '值: %b\n' "\033[31m${values[@]:$i:1}\033[0m" 1>&2
      _ASK_RESULT=${values[@]:$i:1}
      _ASK_INDEX=$i
      return
    fi
  done
  for i in "${!values[@]}"; do
    printf '%b %b	' "\033[31m$i\033[0m" "\033[32m${values[@]:$i:1}\033[0m" 1>&2
  done
  read -p $'\n输入值：'
  local revoke=$(shopt -p nocasematch)
  shopt -s nocasematch
  for i in "${!values[@]}"; do
    if [[ "$REPLY" = $i  || "$REPLY" = "${values[@]:$i:1}" ]]; then
      printf '值: %b\n' "\033[31m${values[@]:$i:1}\033[0m" 1>&2
      _ASK_RESULT="${values[@]:$i:1}"
      _ASK_INDEX=$i
      debug $_ASK_RESULT
      break
    fi
  done
  eval $revoke
}

function question() {
  local msg="$1"
  local default="$2"
  if [[ $PROGRESS ]]; then
    read -p $'\033[33m'"【默认值："$default"】"$1$'\033[0m\033[31m'
    debug $REPLY
    [[ -z $REPLY ]] && echo $default || echo $REPLY
  else
    echo $default
  fi
}

function print_json() {
  local -a fieldNames
  local -a fieldAliases
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local -a fieldKeys
  local -a types
  local -a curlparams
  local url=''
  local text=''
  local raw=$RAW
  local jsonFormat=''
  local OPTIND
  while getopts 'a:f:p:i:t:u:s:r:y:j:q:' opt; do
    case "$opt" in
      a) fieldAliases+=($OPTARG);;
      k) fieldKeys+=($OPTARG);;
      f) fieldNames+=($OPTARG);;
      p) fieldPatterns+=($OPTARG);;
      i) fieldIndexes+=($OPTARG);;
      t) transformers+=($OPTARG);;
      y) types+=($OPTARG);;
      u) url="$OPTARG";;
      q) curlparams+=($OPTARG);;
      s) text="$OPTARG";;
      r) raw=$OPTARG;;
      j) jsonFormat=$OPTARG;;
      *) echo '未知选项 $opt' 1>&2; exit 1;;
    esac
  done

  echo $url 1>&2

  if [[ -n "$jsonFormat" && `declare -f jsonparser` ]]; then

    [[ -z $text ]] && text="$(curl -s "$url" "${curlparams[*]}")"

    if [[ -n $raw ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      jsonparser -f "$jsonFormat" -d "$text"
    fi

  else

    [[ -z "$text" ]] && text="$(curl -s "$url" "${curlparams[*]}")"

    text=$(escapeSpace $(escapeUnicode $text))

    if [[ -n $raw ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      local primaryKey="${fieldNames[@]:0:1}"

      for index in "${!fieldNames[@]}"; do
        local field="${fieldNames[@]:$index:1}";
        local pattern="${fieldPatterns[@]:$index:1}"
        if [[ "$pattern" = '_' ]]; then
          pattern='"'$field'":"[^"]*"'
        fi
        declare -a "arr_$field"
        while read -r line; do
          debug $line
          declare "arr_$field+=(\"${line:-~}\")";
        done < <(printf '%s' "$text" | grep -oE "$pattern" | cut -d'"' -f${fieldIndexes[@]:$index:1})
      done

      local _primaryFieldsIndirection="arr_${primaryKey}[@]"
      local primaryFields=("${!_primaryFieldsIndirection}")

      # iterate records
      for index in "${!primaryFields[@]}"; do
        local -a values=()
        for field in "${fieldNames[@]}"; do
          local _fieldValuesIndirection="arr_${field}[@]"
          local _fieldValues=("${!_fieldValuesIndirection}")
          local value="${_fieldValues[@]:$index:1}"
          if [[ "$value" =~ ^:[0-9]+,$ ]]; then # 数字类型
            value=$(echo "$value" | grep -oE '\d+')
          fi
          values+=("$value")
        done

        # iterate fields
        local _values=()
        for idx in "${!fieldNames[@]}"; do
          local tf="${transformers[@]:$idx:1}"
          _values[$idx]="${values[@]:$idx:1}"
          if [[ -n "$tf" && "$tf" != '_' ]]; then
            _values[$idx]="`eval "printf '%s' $tf"`"
          fi
        done
        for idx in "${!fieldNames[@]}"; do
          values[$idx]="${_values[@]:$idx:1}"
        done

        print_record -a "${fieldAliases[*]}" -v "${values[*]}" -n `expr 1 + $index` -t "${types[*]}"
        echo
      done
    fi
  fi

  local folder"=$_dirname/xy/${url//\//-}"
  ensureFolder $folder
  echo $text > "$folder/$(date '+%Y-%m-%dT%H:%M:%S').json"
}

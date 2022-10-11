#! /usr/bin/env bash

pythonInstalled=$(which python >/dev/null && echo 1 || echo 0)

_dirname=$(dirname $0)

if [[ $pythonInstalled -eq 1 ]]; then
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
    printf %s "$data" | python $_dirname/lib.py "$format"
  }
fi

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
      if [[ "${types[@]:$index:1}" = 'img' ]]; then
        curl -s "${values[@]:$index:1}" | imgcat --height=5
      fi
    fi
    primary=1
  done
}

function urlencode() {
  printf '%s' urlencode
}

function print_json() {
  local -a fieldNames
  local -a fieldAliases
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local -a fieldKeys
  local -a types
  local url=''
  local text=''
  local raw=0
  local jsonFormat=''
  local OPTIND
  while getopts 'a:f:p:i:t:u:s:r:y:j:' opt; do
    case "$opt" in
      a) fieldAliases+=($OPTARG);;
      k) fieldKeys+=($OPTARG);;
      f) fieldNames+=($OPTARG);;
      p) fieldPatterns+=($OPTARG);;
      i) fieldIndexes+=($OPTARG);;
      t) transformers+=($OPTARG);;
      u) url="$OPTARG";;
      s) text="$OPTARG";;
      r) raw=$OPTARG;;
      y) types+=($OPTARG);;
      j) jsonFormat=$OPTARG;;
      *) echo '未知选项 $opt'; exit 1;;
    esac
  done
  if [[ -z "$text" ]]; then
    text="$(escapeSpace $(escapeUnicode $(curl -s $url)))"
  fi
  if [[ $raw -eq 1 ]]; then
    printf '%s' "$text"
  fi

  if [[ `declare -f jsonparser` ]]; then
    jsonparser -f "$jsonFormat" -d "$text"
  else
    local primaryKey="${fieldNames[@]:0:1}"

    for index in "${!fieldNames[@]}"; do
      local field="${fieldNames[@]:$index:1}";
      local pattern="${fieldPatterns[@]:$index:1}"
      if [[ "$pattern" = '_' ]]; then
        pattern='"'$field'":"[^"]*"'
      fi
      declare -a "arr_$field"
      while read -r line; do
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
}

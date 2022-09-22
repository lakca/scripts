#! /usr/bin/env bash

function decodeUnicode() {
  echo -e `echo "$*" | sed -E 's/\\u0([1-9a-f]{3})/\\x\1/gI' \
  | sed -E 's/\\u00([1-9a-f]{2})/\\x\1/gI' \
  | sed -E 's/\\u000([1-9a-f]{1})/\\x\1/gI'`
}

function encodeSpace() {
  echo $* | sed -E 's/ /\\x20/g'
}

function print_record() {
  local -a fields=()
  local -a values=()
  local OPTIND
  while getopts ':a:v:' opt; do
    case "$opt" in
      a) fields+=($OPTARG);;
      v) values+=($OPTARG);;
    esac
  done
  local primary=0
  for index in "${!fields[@]}"; do
    if [[ $primary -eq 0 ]]; then
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: \033[1;31m${values[@]:$index:1}\033[0m"
    else
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: \033[32m${values[@]:$index:1}\033[0m"
    fi
    primary=1
  done
}

function print_json() {
  local -a fieldNames
  local -a fieldAliases
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local url=''
  local text=''
  local OPTIND
  while getopts 'a:f:p:i:t:u:s:' opt; do
    case "$opt" in
      a) fieldAliases+=($OPTARG);;
      f) fieldNames+=($OPTARG);;
      p) fieldPatterns+=($OPTARG);;
      i) fieldIndexes+=($OPTARG);;
      t) transformers+=($OPTARG);;
      u) url="$OPTARG";;
      s) text="$OPTARG";;
      *) exit 1;;
    esac
  done
  if [[ -z "$text" ]]; then
    text=`decodeUnicode \`curl -s $url\``
  fi

  local primaryKey="${fieldNames[@]:0:1}"

  for index in "${!fieldNames[@]}"; do
    local field="${fieldNames[@]:$index:1}"
    declare -a "arr_$field"
    while read line; do
      declare "arr_$field+=(\"$line\")";
    done < <(echo "$text" | grep -oE "${fieldPatterns[@]:$index:1}" | cut -d'"' -f${fieldIndexes[@]:$index:1})
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
      values+=("`encodeSpace "$value"`")
    done

    # iterate fields
    for idx in "${!fieldNames[@]}"; do
      if [[ -n "${transformers[@]:$idx:1}" ]]; then
        values[$idx]="`eval "echo ${transformers[@]:$idx:1}"`"
      fi
    done

    print_record -a "${fieldAliases[*]}" -v "${values[*]}"
    echo
  done
}


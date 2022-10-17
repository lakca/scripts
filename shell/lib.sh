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
  [[ -n $DEBUG ]] && echo "\033[31m$*\033[0m"
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

    [[ -z "$text" ]] && text="$(escapeSpace $(escapeUnicode $(curl -s "$url" "${curlparams[*]}")))"

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
  [[ ! -d $_dirname/xy ]] && mkdir -p $_dirname/xy
  echo $text > "$_dirname/xy/$(date +%s).${url//\//\\}.json"
}

# path:
# groups[*]
# https://www.rfc-editor.org/rfc/rfc7159
function getJson() {
  local json="$1"
  local -i objects=0
  local -i arrays=0
  local -i numbers=0
  local -i strings=0
  local -i nulls=0
  local -i trues=0
  local -i falses=0
  local chars=''
  local char=''
  local line=1
  local column=1
  while read -n1 char; do
    # if [[ $char = $'\n' ]]; then
    #   line=$((line + 1))
    #   column=1
    # else
    #   column=$((column + 1))
    # fi
    case $char in
      # 结构字符
      '[')
        arrays=$((arrays + 1))
      ;;
      ']')
        arrays=$((arrays - 1))
      ;;
      '{')
        objects=$((objects + 1))
      ;;
      '}')
        objects=$((objects - 1))
      ;;
      ':')
        if [[ $strings > 0 ]]; then
          chars="$chars$char"
          continue
        elif [[ $objects > 0 ]]; then
          continue
        fi
      ;;
      ',')
      ;;
      # 结构字符前后允许的（任意数量空白）字符：' \t\n\r'
      $'\x20'|$'\x09'|$'\x0A'|$'\x0D')
        continue
      ;;
      # 字符串标识符
      '"')
      ;;
      # 负数、指数符号
      '-')
      ;;
      # 指数符号
      '+')
      ;;
      # 小数点
      '.')
      ;;
      # 指数标识符
      'e'|'E')
      ;;
      # 数字
      [0-9])
      ;;
      # 字符串
      *)
      ;;
    esac
    echo "Unexpected token: $char in $line:$column."
    exit 1
  done < <(printf "%s" "$json")
}

function tokens() {
  printf %s $*
}

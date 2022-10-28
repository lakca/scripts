#! /usr/bin/env bash

pythonInstalled=$(which python3 >/dev/null && echo 1 || echo 0)

_dirname=$(dirname $0)

if [[ $pythonInstalled -eq 1 && -z $PURE ]]; then
  function jsonparser() {
    local OPTIND
    local data
    local format
    while getopts 'd:f:o:' opt; do
      case $opt in
        d) data="$OPTARG";;
        f) format="$OPTARG";;
        o) file="$OPTARG";;
      esac
    done
    printf %s "$data" | python3 $_dirname/lib.py "$format" "$file"
  }
fi

function debug() {
  if [[ -n "$DEBUG" ]]; then
    echo "$*" | while IFS=$'\n' read line ; do
      # echo ${FUNCNAME[@]} ${BASH_SOURCE[@]}, ${BASH_LINENO[@]} 1>&2
      printf "\033[0;31m[DEBUG:`realpath ${BASH_SOURCE[@]:1:1}`:${BASH_LINENO[@]:0:1}]\033[0m \033[0;37m%s\033[0m\n" "$line" 1>&2
    done
  fi
}

function UnicodePointToUtf8() {
    local x="$1"               # ok if '0x2620'
    x=${x/\\u/0x}              # '\u2620' -> '0x2620'
    x=${x/U+/0x}; x=${x/u+/0x} # 'U-2620' -> '0x2620'
    x=$((x)) # from hex to decimal
    local y=$x n=0
    [ $x -ge 0 ] || return 1
    while [ $y -gt 0 ]; do y=$((y>>1)); n=$((n+1)); done
    if [ $n -le 7 ]; then       # 7
        y=$x
    elif [ $n -le 11 ]; then    # 5+6
        y=" $(( ((x>> 6)&0x1F)+0xC0 )) \
            $(( (x&0x3F)+0x80 ))"
    elif [ $n -le 16 ]; then    # 4+6+6
        y=" $(( ((x>>12)&0x0F)+0xE0 )) \
            $(( ((x>> 6)&0x3F)+0x80 )) \
            $(( (x&0x3F)+0x80 ))"
    else                        # 3+6+6+6
        y=" $(( ((x>>18)&0x07)+0xF0 )) \
            $(( ((x>>12)&0x3F)+0x80 )) \
            $(( ((x>> 6)&0x3F)+0x80 )) \
            $(( (x&0x3F)+0x80 ))"
    fi
    printf -v y '\\x%x' $y
    echo $y
}

export -f UnicodePointToUtf8

function escapeUnicode() {
  local raw_text="$*"
  local text=''
  local prev=''
  local char
  for i in $(seq 0 $((${#raw_text} - 1))); do
      char="${raw_text[@]:$i:1}"
      if [[ -z "$prev" && "$char" == '\' ]]; then
        prev="$prev$char"
      elif [[ "$prev" == '\' ]]; then
          if [[ "$char" == 'u' ]]; then
              prev="$prev$char"
          else
              text="$text$prev$char"
              prev=''
          fi
      elif [[ "$prev" =~ ^\\u[0-9a-f]{0,3}$ ]]; then
          if [[ "$char" == [0-9a-f] ]]; then
              prev="$prev$char"
          else
              text="$text$prev$char"
              prev=''
          fi
      else
          text="$text$prev$char"
          prev=''
      fi
      if [[ "$prev" =~ ^\\u[0-9a-f]{4}$ ]]; then
          text="$text$(UnicodePointToUtf8 "$prev")"
          prev=''
      fi
  done
  printf %s "$text"
}

function escapeUnicode2() {
  local cmd=$(echo -en "$*" | sed 's/\((\|)\)/"\0"/g;s/\\u[0-9a-f]\{4\}/$(UnicodePointToUtf8 "\0")/g')
  eval "echo -e $cmd"
}

function escapeSpace() {
  ( [[ -p /dev/stdin ]] && tee || printf '%s' "$*" ) | sed 's/ /\\x20/g;s/\n/\\xa/g;s/\t/\\x9/g;s/\v/\\xb/g;s/\f/\\xc/g;s/\r/\\xd/g;s/\\"/\\x22/gI'
}

function print_record() {
  local -a fields=()
  local -a values=()
  local -a filters=()
  local id=''
  local OPTIND
  while getopts ':a:v:n:y:' opt; do
    case "$opt" in
      a) fields+=($OPTARG);;
      v) values+=($OPTARG);;
      y) filters+=($OPTARG);;
      n) id=$OPTARG;;
    esac
  done
  local primary=0
  local value
  for index in "${!fields[@]}"; do
    value="${values[@]:$index:1}"
    value="$(escapeUnicode $value)"
    if [[ $primary -eq 0 ]]; then
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: 【"$id"】\033[1;31m$value\033[0m"
    else
      echo -e "\033[33m${fields[@]:$index:1}\033[0m: \033[32m$value\033[0m"
      if [[ -n $ITERM_SESSION_ID && $IMGCAT && "${filters[@]:$index:1}" = *:image:* ]]; then
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
  unset _ASK_INDEX
  unset _ASK_RESULT
  local values=($1)
  local value="$2"
  for i in "${!values[@]}"; do
    if [[ $value = $i || $value = ${values[@]:$i:1} ]]; then
      printf "${_ASK_MSG:-输入值：}%b\n" "\033[31m${values[@]:$i:1}\033[0m" 1>&2
      _ASK_RESULT=${values[@]:$i:1}
      _ASK_INDEX=$i
      debug $_ASK_RESULT, $_ASK_INDEX
      return
    fi
  done
  for i in "${!values[@]}"; do
    printf '%b %b	' "\033[31m$i\033[0m" "\033[32m${values[@]:$i:1}\033[0m" 1>&2
  done
  read -p $'\n'${_ASK_MSG:-输入值：}''
  if [[ -n $REPLY ]]; then
    local revoke=$(shopt -p nocasematch)
    shopt -s nocasematch
    for i in "${!values[@]}"; do
      if [[ "$REPLY" = $i  || "$REPLY" = "${values[@]:$i:1}" ]]; then
        printf "${_ASK_MSG:-输入值：}%b\n" "\033[31m${values[@]:$i:1}\033[0m" 1>&2
        _ASK_RESULT="${values[@]:$i:1}"
        _ASK_INDEX=$i
        debug $_ASK_RESULT, $_ASK_INDEX
        break
      fi
    done
    eval $revoke
  fi
}

function question() {
  local msg="$1"
  local default="$2"
  if [[ $PROGRESS || -z $default ]]; then
    read -p $'\033[33m'"【默认值："$default"】"$1$'\033[0m\033[31m'
    debug $REPLY
    [[ -z $REPLY ]] && echo $default || echo $REPLY
  else
    echo $default
  fi
}

function datafile() {
  local folder=$_dirname/data
  for i in $@; do
    [[ -n $i ]] && folder=$folder/$i
  done
  debug folder: $folder
  ensureFolder "$folder"
  echo "$folder/$(date '+%Y-%m-%d.%H:%M:%S').json"
}

function index() {
  local arr=($1)
  local el=$2
  for i in ${!arr[@]}; do
    if [[ ${arr[@]:$i:1} == $el ]]; then
      echo $i
    fi
  done
}

function print_json() {
  local -a fieldNames
  local -a fieldAliases
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local -a fieldKeys
  local -a filters
  local -a curlparams
  local url=''
  local text=''
  local raw=$RAW
  local jsonFormat=''
  local OPTIND
  while getopts 'a:f:p:i:t:u:s:r:y:j:q:o:' opt; do
    case "$opt" in
      a) fieldAliases+=($OPTARG);;
      k) fieldKeys+=($OPTARG);;
      f) fieldNames+=($OPTARG);;
      p) fieldPatterns+=($OPTARG);;
      i) fieldIndexes+=($OPTARG);;
      t) transformers+=($OPTARG);;
      y) filters+=($OPTARG);;
      u) url="$OPTARG";;
      q) curlparams+=($OPTARG);;
      s) text="$OPTARG";;
      r) raw=$OPTARG;;
      j) jsonFormat=$OPTARG;;
      o) file=$OPTARG;;
      *) echo '未知选项 $opt' 1>&2; exit 1;;
    esac
  done

  local cmd="curl -s "$url" "${curlparams[@]}""

  echo "$cmd" >> resou.log

  [[ -z "$text" ]] && text="$($cmd)"

  [[ -n $file ]] && printf %s "$text" > "$(datafile $file)"

  if [[ -n "$jsonFormat" && `declare -f jsonparser` ]]; then

    if [[ -n $raw ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      jsonparser -f "$jsonFormat" -d "$text" -o "$(datafile records $file)"
    fi

  else

    text=$(escapeSpace "$text")

    if [[ -n $raw ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      local primaryKey="${fieldNames[@]:0:1}"

      for index in "${!fieldNames[@]}"; do
        local field="${fieldNames[@]:$index:1}";
        local pattern="${fieldPatterns[@]:$index:1}"
        if [[ "$pattern" = '_' ]]; then
          if [[ ${filters[@]:$index:1} = *:number:* ]]; then
            pattern='"'$field'":[^,]*,'
          else
            pattern='"'$field'":"[^"]*"'
          fi
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
        for idx in "${!fieldNames[@]}"; do
          local _fieldValuesIndirection="arr_${fieldNames[@]:$idx:1}[@]"
          local _fieldValues=("${!_fieldValuesIndirection}")
          local value="${_fieldValues[@]:$index:1}"
          if [[ "$value" =~ ^:[0-9]+,$ ]]; then # 数字类型
            value=$(echo "$value" | grep -oE '\d+')
            if [[ ${filters[@]:$idx:1} = *:timestamp:* ]]; then
              value="$(date -r $value '+%Y-%m-%d %H:%M:%S' | escapeSpace)"
            else
              value=$(printf "%'.f" $value)
            fi
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

        print_record -a "${fieldAliases[*]}" -v "${values[*]}" -n `expr 1 + $index` -y "${filters[*]}"
        echo
      done
    fi
  fi
}

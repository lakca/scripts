#! /usr/bin/env bash

pythonInstalled=$(which python3 >/dev/null && echo 1 || echo 0)

_dirname=$(dirname $0)
_filename=$(realpath "$0" --relative-to "$_dirname")

if [[ $pythonInstalled -eq 1 && -z $PURE ]]; then
  function jsonparser() {
    local OPTIND
    local data
    local format
    while getopts 'd:f:o:' opt; do
      case $opt in
      d) data="$OPTARG" ;;
      f) format="$OPTARG" ;;
      o) file="$OPTARG" ;;
      esac
    done
    printf %s "$data" | python3 $_dirname/lib.py "$format" "$file"
  }
fi

function debug() {
  # for i in ${!FUNCNAME[@]}; do
  #   printf ${BASH_SOURCE[@]:$i:1} >&2
  #   printf :${BASH_LINENO[@]:$i:1} >&2
  #   printf :${FUNCNAME[@]:$i:1} >&2
  #   printf '\n'
  # done
  local funcname="${FUNCNAME[@]:1:1}"
  if [[ "$DEBUG" == '*' || "${FUNCNAME[*]}" =~ $DEBUG ]]; then
    local OPTIND
    local keyed
    {
      while getopts 'k:v:' opt; do
        case $opt in
        k)
          printf "\033[2;33m%s\033[0m" "$OPTARG"
          keyed=1
          ;;
        v)
          [[ $keyed ]] && printf ' '
          printf "\033[2m%s\033[0m\n" "$OPTARG"
          keyed=''
          ;;
        esac
      done
      [[ $keyed ]] && printf '\n'
      local args="${@:$OPTIND}"
      [[ $args ]] && printf '%s\n' "${args[*]}"
    } | while IFS=$'\n' read line; do
      printf "\033[2m[\033[31mDEBUG:$(realpath ${BASH_SOURCE[@]:1:1}):${BASH_LINENO[@]:0:1} \033[32m${funcname}\033[0m\033[2m]\033[0m \033[2m%s\033[0m\n" "$line" 1>&2
    done
  fi
}

function UnicodePointToUtf8() {
  local x="$1"  # ok if '0x2620'
  x=${x/\\u/0x} # '\u2620' -> '0x2620'
  x=${x/U+/0x}
  x=${x/u+/0x} # 'U-2620' -> '0x2620'
  x=$((x))     # from hex to decimal
  local y=$x n=0
  [ $x -ge 0 ] || return 1
  while [ $y -gt 0 ]; do
    y=$((y >> 1))
    n=$((n + 1))
  done
  if [ $n -le 7 ]; then # 7
    y=$x
  elif [ $n -le 11 ]; then # 5+6
    y=" $((((x >> 6) & 0x1F) + 0xC0)) \
            $(((x & 0x3F) + 0x80))"
  elif [ $n -le 16 ]; then # 4+6+6
    y=" $((((x >> 12) & 0x0F) + 0xE0)) \
            $((((x >> 6) & 0x3F) + 0x80)) \
            $(((x & 0x3F) + 0x80))"
  else # 3+6+6+6
    y=" $((((x >> 18) & 0x07) + 0xF0)) \
            $((((x >> 12) & 0x3F) + 0x80)) \
            $((((x >> 6) & 0x3F) + 0x80)) \
            $(((x & 0x3F) + 0x80))"
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
  ([[ -p /dev/stdin ]] && tee || printf '%s' "$*") | sed 's/ /\\x20/g;s/\n/\\xa/g;s/\t/\\x9/g;s/\v/\\xb/g;s/\f/\\xc/g;s/\r/\\xd/g;s/\\"/\\x22/gI'
}

function random() {
  local r=$RANDOM
  if [[ $1 ]]; then
    while [[ $1 -gt ${#r} ]]; do
      r=$r$RANDOM
    done
    echo ${r:0:$1}
  else
    echo $r
  fi
}

function timestamp() {
  echo $(date +%s)$(random 3)
}

function select_columns() {
  local OPTIND
  local -a array=()
  local -i offset=0
  local -i skip=1
  while getopts 'a:o:s:' opt; do
    case $opt in
    a) # 数组
      array=($OPTARG) ;;
    o) # 偏移
      offset=$OPTARG ;;
    s) # 跳步
      skip=$OPTARG ;;
    esac
  done
  local length=${#array[@]}
  local -a selections=()
  debug "offset: $offset, skip: $skip, length: $length"
  for i in $(seq $offset $((skip + 1)) $((length - 1))); do
    selections+=("${array[@]:$i:1}")
  done
  echo "${selections[*]}"
}

function indexof() {
  local value="$1"
  local array=($2)
  local revoke=$(shopt -p nocasematch)
  local index=$_INDEXOF_NO_INDEX
  unset _INDEXOF_NO_INDEX
  debug 索引值：$value, 数组长度：${#array[@]}, 数组：${array[@]}
  [[ $_INDEXOF_IGNORE_CASE ]] && shopt -s nocasematch
  for i in ${!array[@]}; do
    if [[ ${array[@]:$i:1} == $value ]]; then
      index=$i
      debug 返回索引：$index
      break
    fi
  done
  eval "$revoke"
  echo $index
}

function indexesof() {
  local values=($1)
  for value in "${values[@]}"; do
    _INDEXOF_NO_INDEX=-1 indexof "$value" "$2"
  done
}

function get_indexes() {
  if [[ $1 ]]; then
    local arr=($1)
    seq 0 $((${#arr[@]} - 1))
  fi
}

# encode_array "${array[@]}"
function encode_array() {
  for e in "$@"; do
    base64 <<<"$e"
  done
}

# get_encoded_array_ele 5 "${encoded[@]}"
function get_encoded_array_ele() {
  local -i index=$1
  local items=(${@:2})
  local item=${items[@]:$index:1}
  [[ $item ]] && base64 -d <<<"$item"
}

function resolveLink() {
  local link=${1//\?*/}
  link=${link//\\\?*/}
  link=${link//\#*/}
  link=${link//\\\#*/}
  local parts=($(echo $link | grep -oE '[^\/]+'))
  echo "${parts[*]}"
}

function ensureFolder() {
  [[ ! -d $1 ]] && mkdir -p $1
}

function store() {
  local op=$1
  local key=$(base64 <<<"$2")
  local val="$3"
  local file=${_filename}.store
  [[ ! ${file[@]:0:1} = '.' ]] && file=.$file
  local filename="$_dirname/$file"
  case $1 in
  -g)
    [[ -e $filename ]] && tac $filename | grep --max-count=1 --fixed-strings "$key:" | cut -d: -f2 | base64 -d
    ;;
  -s)
    [[ -f /dev/stdin || -p /dev/stdin ]] && read val
    val=$(base64 <<<"$val")
    echo "$key:$val" >>"$filename"
    ;;
  esac
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
      if [[ "$REPLY" = $i || "$REPLY" = "${values[@]:$i:1}" ]]; then
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

function prompt_select() {
  local arraies=("$@")
  local headArray=(${arraies[@]:0:1})
  printf '\033[33m【选项】\033[0m' >&2
  for i in "${!headArray[@]}"; do
    printf '%b' "\033[3;32m$i\033[0m" >&2
    for array in "${arraies[@]}"; do
      array=($array)
      printf ' ' >&2
      printf '%b' "\033[2;3;33;40m${array[@]:$i:1}\033[0m" >&2
    done
    printf '  \033[2m|\033[0m  ' >&2
  done
  printf '\n' >&2

  echo -en "${_PROMPT_SELECT_MSG}\033[31m" >&2
  read
  echo -en '\033[0m' >&2
  echo $REPLY
  unset _PROMPT_SELECT_MSG
}

function ask2() {
  local question="$_ASK_MSG"
  local question_desc="$_ASK_MSG2"
  # 数组列表
  local arraies=()
  # 头部数组（获取数组长度和索引的基准数组）
  local headArray=()
  # 大数组（用于将所有数组的同位值放在一起便于观看）
  local bigArray=()
  # 大数组包含的数组数量
  local bigArraySize
  local input
  local default
  local echoIndex=0
  local multiple
  local defaultConst
  local OPTIND
  local selectableArrayIndexes=()
  local silent
  unset _ASK_INDEX
  unset _ASK_RESULT
  unset _ASK_RESULTS
  unset _ASK_MSG
  unset _ASK_MSG2
  while getopts 'q:Q:a:A:N:i:d:D:e:012S:ms' opt; do
    case $opt in
    q) # 问题内容
      question="$OPTARG" ;;
    Q) # 问题补充说明
      question_desc="$OPTARG" ;;
    a) # 值数组
      arraies+=("$OPTARG")
      [[ ! "$headArray" && ! "$bigArray" ]] && headArray=($OPTARG)
      ;;
    A) # 大数组（用于将所有数组的同位值放在一起便于观看）
      bigArray=($OPTARG)
      ;;
    N) # 大数组包含的数组数量，如果前面通过`-a`提供了头部数组，可以省略该选项
      bigArraySize=$OPTARG
      debug "bigArraySize: $bigArraySize"
      ;;
    i) # 输入值
      input="$OPTARG" ;;
    d) # 默认值
      default="$OPTARG"
      defaultConst=''
      ;;
    D) # 特殊默认值
      defaultConst="$OPTARG"
      default=''
      ;;
    e) # _ASK_RESULT（和输出结果）的数组索引
      echoIndex="$OPTARG" ;;
    0) # _ASK_RESULT（和输出结果）的数组索引为0
      echoIndex=0 ;;
    1) # _ASK_RESULT（和输出结果）的数组索引为1
      echoIndex=1 ;;
    2) # _ASK_RESULT（和输出结果）的数组索引为2
      echoIndex=2 ;;
    S) # 选项中呈现的数组（索引）
      selectableArrayIndexes=($OPTARG) ;;
    m) # 接受多值
      multiple=1 ;;
    s) # silent，不返回值
      silent=1 ;;
    esac
  done

  for i in $(get_indexes "${selectableArrayIndexes[*]}"); do
    [[ ${selectableArrayIndexes[@]:$i:1} < 0 ]] && selectableArrayIndexes[$i]=$(($bigArraySize + ${selectableArrayIndexes[@]:$i:1}))
  done

  if [[ $echoIndex < 0 ]]; then
    echoIndex=$(($bigArraySize + $echoIndex))
  fi

  if [[ "$bigArray" ]]; then
    if [[ $bigArraySize ]]; then
      local skip=$((bigArraySize - 1))
      for i in $(seq 0 $skip); do
        local array=$(select_columns -o $i -s $skip -a "${bigArray[*]}")
        [[ ! "$headArray" ]] && headArray=($array)
        arraies+=("$array")
      done
    fi
  fi

  debug -k "headArray" -v "${headArray[*]}"

  # 索引数组为头部数组的索引数组
  local indexArray=${!headArray[@]}

  # 用于比较的数组包含位于头部的索引数组
  local comparingArraies=("${indexArray[*]}" "${arraies[@]}")
  #
  local selectableArraies=()
  for index in "${!comparingArraies[@]}"; do
    [[ ! $selectableArrayIndexes || $(indexof $(($index - 1)) "${selectableArrayIndexes[*]}") ]] && selectableArraies+=("${comparingArraies[@]:$index:1}")
  done

  [[ "$question_desc" ]] && question_desc="，${question_desc}"
  question="\033[33m【输入】\033[0m请\033[2;4m从上述序号或值中选择\033[22;24m输入\033[31m${question}\033[0m${question_desc}："

  debug -k '问题：' -v "$question" -k '输入值：' -v "$input" -k '选项：' -v "${arraies[*]}"

  # 多选
  if [[ $multiple ]]; then
    debug -k '多值选择'
    local inputIndexes
    local defaultIndexes
    for array in "${comparingArraies[@]}"; do
      if [[ $input ]]; then
        if [[ $input = 'ALL' ]]; then
          inputIndexes=(${!headArray[@]})
        else
          local i=-1
          for el in $(_INDEXOF_NO_INDEX=-1 indexesof "$input" "$array"); do
            i=$((i + 1))
            [[ ! ${inputIndexes[@]:$i:1} || ${inputIndexes[@]:$i:1} -eq -1 ]] && inputIndexes[$i]="$el"
          done
          unset i
        fi
      fi
      if [[ $default ]]; then
        local i=-1
        for el in $(_INDEXOF_NO_INDEX=-1 indexesof "$default" "$array"); do
          i=$((i + 1))
          [[ ! ${defaultIndexes[@]:$i:1} || ${defaultIndexes[@]:$i:1} -eq -1 ]] && defaultIndexes[$i]="$el"
        done
        unset i
      fi
    done
    case "$defaultConst" in
    ALL)
      defaultIndexes=(${!headArray[@]})
      ;;
    esac
    # 提问增加默认值信息
    [[ ${defaultIndexes[*]} ]] && question="${question}（默认值为\033[2;3;33m${defaultIndexes[@]}\033[0m）："
    debug 输入多索引：${inputIndexes[*]}, 默认多索引：${defaultIndexes[*]}

    local reply
    if [[ ! ${inputIndexes[*]} ]]; then
      reply=$(_PROMPT_SELECT_MSG=$question prompt_select "${selectableArraies[@]}")
    fi

    if [[ $reply ]]; then
      for array in "${comparingArraies[@]}"; do
        debug 交互：$reply, 数组：$array
        local i=-1
        inputIndexes=()
        for el in $(_INDEXOF_NO_INDEX=-1 indexesof "$reply" "$array"); do
          i=$((i + 1))
          [[ ! ${inputIndexes[@]:$i:1} || ${inputIndexes[@]:$i:1} -eq -1 ]] && inputIndexes[$i]="$el"
        done
        unset i
      done
    fi

    local indexes=(${inputIndexes[*]:-${defaultIndexes[*]}})

    debug 输入索引：${inputIndexes[*]}, 输入后索引：${indexes[*]}

    if [[ ${indexes[*]} ]]; then
      _ASK_INDEX=(${indexes[@]})
      _ASK_RESULT=()
      _ASK_RESULTS=()
      for i in "${!arraies[@]}"; do
        local array=(${arraies[@]:$i:1})
        for e in "${indexes[@]}"; do
          _ASK_RESULTS+=("${array[@]:$e:1}")
          if [[ $i -eq $echoIndex ]]; then
            _ASK_RESULT+=("${array[@]:$e:1}")
          fi
        done
      done
      [[ ! $_ASK_NO_VERBOSE ]] && echo -en '\033[33m【结果】\033[0m\033[2;3;37m您输入的结果为：\033[0m' >&2 && echo -e "\033[2;3;36m${_ASK_RESULT[*]}\033[0m" >&2
      [[ ! $silent ]] && echo ${_ASK_RESULT[*]}
    fi
    [[ ! $_ASK_NO_VERBOSE ]] && printf '\n' >&2
    return
  else
    debug -k '单值选择'
    # 单选
    local inputIndex
    local defaultIndex

    for array in "${comparingArraies[@]}"; do
      [[ ! "$inputIndex" ]] && inputIndex=$(indexof "$input" "$array")
      [[ ! "$defaultIndex" ]] && defaultIndex=$(indexof "$default" "$array")
    done
    # 提问增加默认值信息
    [[ $defaultIndex ]] && question="${question}（默认值为\033[2;3;33m${default}\033[0m）："
    debug 输入索引：$inputIndex, 默认索引：$defaultIndex

    local reply

    if [[ ! $inputIndex ]]; then
      reply=$(_PROMPT_SELECT_MSG=$question prompt_select "${selectableArraies[@]}")
    fi

    if [[ $reply ]]; then
      for array in "${comparingArraies[@]}"; do
        debug 交互：$reply, 数组：$array
        inputIndex=$(_INDEXOF_IGNORE_CASE=1 indexof "$reply" "$array")
        [[ $inputIndex ]] && break
      done
    fi

    local index=${inputIndex:-$defaultIndex}

    debug 输入索引：$inputIndex, 输入后索引：$index

    if [[ $index ]]; then
      _ASK_INDEX=$index
      _ASK_RESULTS=()
      for i in "${!arraies[@]}"; do
        local array=(${arraies[@]:$i:1})
        [[ $i -eq $echoIndex ]] && _ASK_RESULT="${array[@]:$index:1}"
        _ASK_RESULTS+=("${array[@]:$index:1}")
      done
      [[ ! $_ASK_NO_VERBOSE ]] && echo -en "\033[33m【结果】\033[32m${question}\033[0m\033[0m\033[2;3;37m您输入的结果为：\033[0m" >&2 && echo -e "\033[2;3;36m${_ASK_RESULTS[*]}\033[0m" >&2
      [[ ! $silent ]] && echo $_ASK_RESULT
    fi
    [[ ! $_ASK_NO_VERBOSE ]] && printf '\n' >&2
  fi
}

function question() {
  local msg="$1"
  local default="$2"
  debug "$1"
  debug "$2"
  if [[ $PROGRESS || -z "$default" ]]; then
    echo -en "$1\033[31m" >&2
    read
    debug $REPLY
    [[ -z $REPLY ]] && echo "$default" || echo "$REPLY"
  else
    echo "$default"
  fi
}

function question2() {
  local question
  local question_desc
  local default
  local input
  local OPTIND
  while getopts 'q:Q:d:i:' opt; do
    case $opt in
    q) question="$OPTARG" ;;
    Q) question_desc="$OPTARG" ;;
    d) default="$OPTARG" ;;
    i) input="$OPTARG" ;;
    esac
  done
  local answer
  if [[ "$input" ]]; then
    answer="$input"
  else
    local msg="\033[33m【输入】\033[0m请输入\033[31m${question}\033[0m"
    [[ $question_desc ]] && msg="${msg}，${question_desc}"
    [[ $default ]] && msg="${msg}（默认值为\033[2;3;33m${default}\033[22;23m）" || msg="${msg}"
    msg="${msg}：\033[31m"
    echo -en "$msg" >&2
    read
    debug $REPLY
    echo -en '\033[0m' >&2
    [[ -z $REPLY ]] && answer="$default" || answer="$REPLY"
  fi
  [[ ! $_ASK_NO_VERBOSE ]] && echo -e "【结果】\033[32m${question}\033[0m\033[0m\033[2;3;37m您输入的有效值为：\033[0m\033[2;3;36m$answer\033[0m" >&2
  echo "$answer"
}

function whether() {
  local question
  local required
  local zero
  local OPTIND
  local yes=1
  local no
  local input
  while getopts 'q:r0y:n:i:' opt; do
    case $opt in
    q) question="$OPTARG" ;;
    r) required=1 ;;
    0) no=0 ;;
    y) yes="$OPTARG" ;;
    n) no="$OPTARG" ;;
    i) input="$OPTARG" ;;
    esac
  done
  [[ $input ]] && echo $input && return
  if [[ $required ]]; then
    while true; do
      answer=$(_ASK_NO_VERBOSE=1 question2 -q "是否${question}" -Q "\033[3;31m是\033[0m则输入\033[3;31my\033[0m，\033[3;32m否\033[0m则输入\033[3;32mn\033[0m")
      [[ "$answer" == 'y' ]] && {
        echo $'\033[33m【结果】\033[0m\033[2;3;37m您输入的结果是：\033[0m\033[2;3;36m是\033[0m' >&2
        echo $yes
      } && break
      [[ "$answer" == 'n' ]] && {
        echo $'\033[33m【结果】\033[0m\033[2;3;37m您输入的结果是：\033[0m\033[2;3;36m否\033[0m' >&2
        echo $no
      } && break
    done
  else
    while true; do
      answer=$(_ASK_NO_VERBOSE=1 question2 -q "是否${question}" -Q "\033[3;31m是\033[0m则输入\033[3;31my\033[0m，\033[3;32m否\033[0m则\033[3;32m直接回车\033[0m或输入\033[3;32mn\033[0m")
      [[ "$answer" == 'y' ]] && {
        echo $'\033[33m【结果】\033[0m\033[2;3;37m您输入的结果是：\033[0m\033[2;3;36m是\033[0m' >&2
        echo $yes
      } && break
      [[ -z "$answer" || "$answer" == 'n' ]] && {
        echo $'\033[33m【结果】\033[0m\033[2;3;37m您输入的结果是：\033[0m\033[2;3;36m否\033[0m' >&2
        echo $no
      } && break
    done
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

function print_record() {
  local -a fields=()
  local -a values=()
  local -a filters=()
  local id=''
  local OPTIND
  while getopts ':a:v:n:y:' opt; do
    case "$opt" in
    a) fields+=($OPTARG) ;;
    v) values+=($OPTARG) ;;
    y) filters+=($OPTARG) ;;
    n) id=$OPTARG ;;
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

function print_json() {
  local -a fieldNames
  local -a fieldAliases
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local -a fieldKeys
  local -a filters
  local -a curlparams
  local -a _curlparams
  local url=''
  local text=''
  local raw=$RAW
  local jsonFormat=''
  local headers=()
  local OPTIND
  while getopts 'a:f:p:i:t:u:s:r:y:j:q:o:H:' opt; do
    case "$opt" in
    a) fieldAliases+=($OPTARG) ;;
    k) fieldKeys+=($OPTARG) ;;
    f) fieldNames+=($OPTARG) ;;
    p) fieldPatterns+=($OPTARG) ;;
    i) fieldIndexes+=($OPTARG) ;;
    t) transformers+=($OPTARG) ;;
    y) filters+=($OPTARG) ;;
    u) url="$OPTARG" ;;
    q) curlparams+=($OPTARG) ;;
    s) text="$OPTARG" ;;
    r) raw=$OPTARG ;;
    j) jsonFormat=$OPTARG ;;
    o) file=$OPTARG ;;
    H) headers+=($OPTARG) ;;
    *)
      echo '未知选项 $opt' 1>&2
      exit 1
      ;;
    esac
  done
  for i in "${curlparams[@]}"; do
    _curlparams+=("$(base64 -d <<<"$i")")
  done

  echo "curl -v "$url" "${_curlparams[@]}" "${headers[@]}"" >>$_dirname/resou.log

  # 使用本地数据
  if [[ ${DEBUG_LOCAL+x} ]]; then
    [[ ! $file ]] && echo '未设置$file' >&2 && exit 1
    local local_file=$(ls $(dirname $(datafile $file))/* | tail -${DEBUG_LOCAL:-1} | head -1)
    debug "local file: $local_file"
    text=$(cat $local_file)
  fi

  # 获取数据
  if [[ ! "$text" ]]; then
    text="$(curl -v "$url" "${_curlparams[@]}" "${headers[@]}" 2>$_dirname/curl.log)"
  fi
  # 保存数据
  [[ ${DEBUG_LOCAL-x} && $SHOULD_STORE && $file ]] && printf %s "$text" >"$(datafile $file)"

  if [[ "$jsonFormat" && $(declare -f jsonparser) ]]; then

    if [[ $raw ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      jsonparser -f "$jsonFormat" -d "$text" -o "$(datafile records $file)"
    fi

  else

    text=$(escapeSpace "$text")

    if [[ $raw || ! ${fieldPatterns[*]} ]]; then
      printf '%s' "$text"
    else
      debug "$text"
      local primaryKey="${fieldNames[@]:0:1}"

      for index in "${!fieldNames[@]}"; do
        local field="${fieldNames[@]:$index:1}"
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
          declare "arr_$field+=(\"${line:-~}\")"
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
            _values[$idx]="$(eval "printf '%s' $tf")"
          fi
        done
        for idx in "${!fieldNames[@]}"; do
          values[$idx]="${_values[@]:$idx:1}"
        done

        print_record -a "${fieldAliases[*]}" -v "${values[*]}" -n $(expr 1 + $index) -y "${filters[*]}"
        echo
      done
    fi
  fi
}

function help() {
  if [[ "$*" =~ (^|[[:space:]])-h([[:space:]]|$) ]]; then
    local help_msg="$(cat $0 | grep -oE '^\s*[^|)( ]+(\|[^|)( ]*)*\)\s*(#.*)?$' | sed 's/    / /g;')"
    local stylish=(-e '/^ \S\+/i\ ' -e 's/^ \( \+\)/\1\1\1\1/;s/#\(.*\)/\\033[2;3;37m\1\\033[0m/;s/\(\s*\)\([^ |)]\+\)\([|)]\)/\1\\033[31m\2\\033[0m\3/;s/\(|\)\([^ |)]\+\)/\1\\033[32m\2\\033[0m/g;/^\S/i\ ')
    local endLevel=0
    for i in $(seq 0 $#); do [[ ${@:$i:1} == '-h' ]] && endLevel=$i; done
    [[ $endLevel == 1 ]] && echo -e "$(sed "${stylish[@]}" <<<"$help_msg")" && exit 0
    echo -e "$(
      nextLevel=1
      while IFS= read line; do
        lineLevel=$(grep -o '^\s*' <<<"$line")
        lineLevel=${#lineLevel}
        local pattern="${@:$lineLevel:1}"
        # nextLevel至少为1
        [[ $nextLevel < 1 ]] && nextLevel=1
        # echo "$nextLevel,$lineLevel,$line"
        # 回溯
        [[ $lineLevel < $nextLevel ]] && { [[ $line =~ "$pattern" ]] && { echo -e "$line" && nextLevel=$((lineLevel + 1)); } || nextLevel=$lineLevel; }
        # 打印全部子命令
        [[ $lineLevel -ge $endLevel && $nextLevel -ge $endLevel ]] && echo -e "$line" && continue
        # 匹配上nextLevel，打印
        [[ $lineLevel = $nextLevel && $line =~ "$pattern" ]] && { echo -e "$line" && nextLevel=$((nextLevel + 1)) && continue; }
      done <<<"$help_msg" | sed "${stylish[@]}"
    )"
  else
    return 1
  fi
}

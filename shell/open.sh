#!/usr/bin/env bash

source $(dirname $0)/prelude.sh

cmd="$1"
name="$2"
filter="$3"

zy=(
  'http://www.a-hospital.com/w/{name}'
  'https://www.yixue.com/{name}'
  'https://zh.wikipedia.org/wiki/{name}'
  'https://zhongyibaike.com/wiki/{name}'
  'https://baike.baidu.com/item/{name}'
)
hq=(
  'https://xueqiu.com/S/{market}{code}'
  'http://quote.eastmoney.com/{market}/{code}.html'
  'http://stockpage.10jqka.com.cn/{code}/'
)

case $cmd in
  中药|zy|cm)
    params='name'
    var='zy'
    filter=${3:-1}
  ;;
  行情|quote|hq)
    code=$(grep -o '[0-9]\{6\}' <<< $name)
    [[ $code = [69]* ]] && market='sh'
    [[ $code = [320]* ]] && market='sz'
    [[ $code = [84]* ]] && market='bj'
    params='code market'
    var='hq'
    filter=${3:-1}
  ;;
  rust|rs)
    folder=$(realpath ~/.rustup/toolchains/stable-x86_64-apple-darwin/share/doc/rust/html)
    _cmd="find $folder -name *$name*.html"
    [[ $filter ]] && _cmd+=" -path **/*$filter*/**"
    items=($($_cmd))
    [[ 1 -eq ${#items[@]} ]] && open ${items[*]}
    for i in "${items[@]}"; do echo $i; done
    exit 0
  ;;
esac

_var=$var[@]
items=(${!_var})
for i in "${!items[@]}"; do
  item=${items[@]:$i:1}
  url=$item
  for j in $params; do
    url=${url/\{$j\}/${!j}}
  done
  grep '^[0-9]\+$' <<< $filter >/dev/null
  if [[ $? = 0 ]]; then
    [[ $filter -ge $((i + 1)) ]] && open -a '/Applications/Safari.app' "$url"
  elif [[ "$item" = *$filter* ]]; then
    open -a '/Applications/Safari.app' "$url"
  fi
done

help "$@"

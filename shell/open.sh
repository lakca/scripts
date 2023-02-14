#!/usr/bin/env bash

source $(dirname $0)/prelude.sh

cmd=$1
name=$2
count=${3:-1}

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
  ;;
  行情|quote|hq)
    code=$(grep -o '[0-9]\{6\}' <<< $name)
    [[ $code = [69]* ]] && market='sh'
    [[ $code = [320]* ]] && market='sz'
    [[ $code = [84]* ]] && market='bj'
    params='code market'
    var='hq'
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
  grep '^[0-9]\+$' <<< $count >/dev/null
  if [[ $? = 0 ]]; then
    [[ $count -ge $((i + 1)) ]] && open "$url"
  elif [[ "$item" = *$count* ]]; then
    open "$url"
  fi
done

help "$@"

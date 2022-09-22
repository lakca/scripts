#! /usr/bin/env bash

source `dirname $0`/json.sh

stamp=`date +%s`

# 最新播报
function zxbb() {
  local url="https://emres.dfcfw.com/60/zxbb2018.js?callback=zxbb2018&_=$stamp"
  local text=`curl -s "$url"`
}

fields=(title link)
fieldAliases=(标题 链接)
fieldPatterns=('"Title":".*?"' '"Url":".*?"');
fieldIndexes=(4 4);
fieldTransformers=('${values[@]:0:1}' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=${values[@]:0:1}')

print_json -s "`cat toutiao.hot.json`" -f "${fields[*]}" -a "${fieldAliases[*]}" -p "${fieldPatterns[*]}" -i "${fieldIndexes[*]}" -t "${fieldTransformers[*]}"

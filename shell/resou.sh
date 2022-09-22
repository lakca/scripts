#! /usr/bin/env bash

WEIBO_HOT_URL='https://s.weibo.com/top/summary?cate=top_hot'
WEIBO_YAOWEN_URL='https://s.weibo.com/top/summary?cate=socialevent'
WEIBO_WENYU_URL='https://s.weibo.com/top/summary?cate=entrank'

BAIDU_HOT_URL='https://top.baidu.com/board?tab=realtime'

ZHIHU_HOT_URL='https://www.zhihu.com/billboard'
ZHIHU_HOUR_URL='https://www.zhihu.com/api/v4/creators/rank/hot?domain=0&period=hour'
ZHIHU_DAY_URL='https://www.zhihu.com/api/v4/creators/rank/hot?domain=0&period=day'
ZHIHU_WEEK_URL='https://www.zhihu.com/api/v4/creators/rank/hot?domain=0&period=week'
#ZHIHU_HOT_SEARCH_URL='https://www.zhihu.com/api/v4/topics/19964449/feeds/top_activity?limit=10'
TOUTIAO_HOT_URL='https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc'
TOUTIAO_HOT_SEARCH_URL='https://tsearch.snssdk.com/search/suggest/hot_words/'

ZHIHU_CATE=(全部 数码 科技 互联网 商业财经 职场 教育 法律 军事 汽车 人文社科 自然科学 工程技术 情感 心理学 两性 母婴亲子 家居 健康 艺术 音乐 设计 影视娱乐 宠物 体育电竞 运动健身 动漫游戏 美食 旅行 时尚)
ZHIHU_CATE_NUM=(0  100001  100002  100003  100004  100005  100006  100007  100008  100009  100010  100011  100012  100013  100014  100015  100016  100017  100018  100019  100020  100021  100022  100023  100024  100025  100026  100027  100028  100029)

function decodeUnicode() {
  echo -e `echo $* | sed -E 's/\\u0([1-9a-f]{3})/\\x\1/gI' \
  | sed -E 's/\\u00([1-9a-f]{2})/\\x\1/gI' \
  | sed -E 's/\\u000([1-9a-f]{1})/\\x\1/gI'`
}

function json() {
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  local url=''
  while getopts 'p:i:t:u:' opt; do
    case "$opt" in
      p) fieldPatterns+=($OPTARG);;
      i) fieldIndexes+=($OPTARG);;
      t) transformers+=($OPTARG);;
      u) url="$OPTARG";;
      *) exit 1;;
    esac
  done
  local titles=()
  local links=()
  local text=`decodeUnicode \`curl -s $url\``
  while read line; do titles+=("$line"); done < <(echo "$text" | grep -oE "${fieldPatterns[@]:0:1}" | cut -d'"' -f${fieldIndexes[@]:0:1})
  while read line; do links+=("$line"); done < <(echo "$text" | grep -oE "${fieldPatterns[@]:1:1}" | cut -d'"' -f${fieldIndexes[@]:1:1})
  for i in ${!titles[@]}; do
    title=${titles[@]:$i:1}
    link=${links[@]:$i:1}
    if [[ -n "${transformers[@]:1:1}" ]]; then
      link=`eval "echo ${transformers[@]:1:1}"`
    fi
    record "[`expr $i + 1`] $title" "$link"
    echo
  done
}

function record() {
  local title="$1"
  local link="$2"
  echo -e "\033[33m标题\033[0m: \033[1;31m$title\033[0m"
  [ -n "$VERBOSE" ] && echo -e "\033[33m地址\033[0m: \033[4;32m$link\033[0m"
}


function weibo() {
  local url="$WEIBO_HOT_URL"
  local i=0
  case ${1:-hot} in
    hot|ht) url="$WEIBO_HOT_URL";;
    yaowen|vip) url="$WEIBO_YAOWEN_URL";;
    wenyu|ent) url="$WEIBO_WENYU_URL";;
  esac
  local cookie='SUB=_2AkMURLcVf8NxqwJRmf4dxWnibYt1zw7EieKiGEbOJRMxHRl-yj9jqlA5tRB6P8SZ-sVAyb47oXgB6AyfiRc9-7xR7yRm'

  curl -s "$url" -b "$cookie" | awk '/<table/,/<\/table>/'| grep -oE '<a.*?>.*?<\/a>' | sed -re 's/([^"]*")//' -e 's/"[^>]*>/ /' -e 's/<\/a>$//' |
  while read line; do
    record "[`expr $i + 1`] ${line##* }" "https://s.weibo.com${line%% *}"
    echo
    i=`expr $i + 1`
  done
}

function baidu() {
  local url="$BAIDU_HOT_URL"
  local i=0
  curl -s "$url" | grep -oE '<a.*?>.*?</a>' | grep -E 'class="title_' | sed -re 's/[^"]*"//' -e 's/"[^>]*>//' -e 's/<[^>]*>//' -e 's/<\/div>.*$//' |
  while read line; do
    record "[`expr $i + 1`] ${line##* }" "${line%% *}"
    echo
    i=`expr $i + 1`
  done
}

function applyZhihuDomain() {
  local url=$1
  local cate=$2
  local domain=''
  if [[ ! "$url" =~ 'domain=' ]]; then
    echo "$url"
    return
  fi
  echo "${ZHIHU_CATE[@]}" 1>&2
  while true; do
    if [[ -n "$cate" ]]; then
      for i in "${!ZHIHU_CATE[@]}"; do
        local name="${ZHIHU_CATE[@]:$i:1}"
        if [[ $name =~ "$cate" ]]; then
          echo "匹配到：$name" 1>&2
          domain="${ZHIHU_CATE_NUM[@]:$i:1}"
          break
        fi
      done
    fi
    [[ -z "$domain" ]] && read -p $'\033[32m输入分类\033[0m: ' cate || break
  done
    echo "${url/domain\=0/domain=$domain}"
}

function zhihu() {
  local url="$ZHIHU_HOT_URL"
  local -a fieldPatterns
  local -a fieldIndexes
  local type="$1"
  local domain="$2"
  case ${type:=hot} in
    hot|ht) url="$ZHIHU_HOT_URL"; fieldPatterns=('"target":{.*?}' '"link":{.*?}'); fieldIndexes=(8 6);;
    hour) url="$ZHIHU_HOUR_URL"; fieldPatterns=('"title":".*?"' '"url":".*?"'); fieldIndexes=(4 4);;
    day) url="$ZHIHU_DAY_URL"; fieldPatterns=('"title":".*?"' '"url":".*?"'); fieldIndexes=(4 4);;
    week) url="$ZHIHU_WEEK_URL"; fieldPatterns=('"title":".*?"' '"url":".*?"'); fieldIndexes=(4 4);;
  esac
  url=`applyZhihuDomain $url $domain`
  json -u "$url" -p "${fieldPatterns[*]}" -i "${fieldIndexes[*]}"
}

function toutiao() {
  # https://www.toutiao.comhttps://tsearch.snssdk.com/search/suggest/hot_words/
  local type=$1
  local url=''
  local -a fieldPatterns
  local -a fieldIndexes
  local -a transformers
  case ${type:=hot} in
    hot|ht) url="$TOUTIAO_HOT_URL";
      fieldPatterns=('"Title":".*?"' '"Url":".*?"');
      fieldIndexes=(4 4);;
    hs|search) url="$TOUTIAO_HOT_SEARCH_URL";
      fieldPatterns=('"query":".*?"' '"query":".*?"');
      fieldIndexes=(4 4);
      transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title');;
  esac
  json -u "$url" -p "${fieldPatterns[*]}" -i "${fieldIndexes[*]}" -t "${transformers[*]}"
}

case $1 in
  weibo|wb) weibo $2;;
  baidu|bd) baidu $2;;
  zhihu|zh) zhihu $2 $3;;
  toutiao|tt) toutiao $2;;
esac

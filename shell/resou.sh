#! /usr/bin/env bash

pythonInstalled=$(which python >/dev/null && echo 1 || echo 0)
WEIBO_RESOU='https://weibo.com/ajax/side/hotSearch'

WEIBO_HOT_SEARCH_URL='https://s.weibo.com/top/summary?cate=top_hot'
WEIBO_YAOWEN_URL='https://s.weibo.com/top/summary?cate=socialevent'
WEIBO_WENYU_URL='https://s.weibo.com/top/summary?cate=entrank'
# 热门
WEIBO_HOT_POST_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=0&group_id=102803&containerid=102803&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 热门微博 https://weibo.com/hot/weibo/102803
# https://weibo.com/5368633408/M7OL9bpQP
WEIBO_HOT_POST_URLS=(
  热门 'HOT' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=0&group_id=102803&containerid=102803&extparam=discover%7Cnew_feed&max_id=0&count=10'
  同城 'CITY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032222&containerid=102803_2222&extparam=discover%7Cnew_feed&max_id=0&count=10'
  榜单 'LIST' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600169&containerid=102803_ctg1_600169_-_ctg1_600169&extparam=discover%7Cnew_feed&max_id=0&count=10'
  明星 'STAR' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034288&containerid=102803_ctg1_4288_-_ctg1_4288&extparam=discover%7Cnew_feed&max_id=0&count=10'
  抗疫 'ANTICOVID19' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600115&containerid=102803_ctg1_600115_-_ctg1_600115&extparam=discover%7Cnew_feed&max_id=0&count=10'
  好物 'GOODTHING' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600094&containerid=102803_ctg1_600094_-_ctg1_600094&extparam=discover%7Cnew_feed&max_id=0&count=10'
  搞笑 'FUNNY' 'https://weibo.ccreated_atom/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034388&containerid=102803_ctg1_4388_-_ctg1_4388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  颜值 'BEAUTY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600165&containerid=102803_ctg1_600165_-_ctg1_600165&extparam=discover%7Cnew_feed&max_id=0&count=10'
  社会 'SOCIETY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034188&containerid=102803_ctg1_4188_-_ctg1_4188&extparam=discover%7Cnew_feed&max_id=0&count=10'
  情感 'EMOTION' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031988&containerid=102803_ctg1_1988_-_ctg1_1988&extparam=discover%7Cnew_feed&max_id=0&count=10'
  新时代 'NEWERA' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028037968&containerid=102803_ctg1_7968_-_ctg1_7968&extparam=discover%7Cnew_feed&max_id=0&count=10'
  电视剧 'TV' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032488&containerid=102803_ctg1_2488_-_ctg1_2488&extparam=discover%7Cnew_feed&max_id=0&count=10'
  美食 'FOOD' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032688&containerid=102803_ctg1_2688_-_ctg1_2688&extparam=discover%7Cnew_feed&max_id=0&count=10'
  国际 'I18N' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036288&containerid=102803_ctg1_6288_-_ctg1_6288&extparam=discover%7Cnew_feed&max_id=0&count=10'
  深度 'DEEP' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600155&containerid=102803_ctg1_600155_-_ctg1_600155&extparam=discover%7Cnew_feed&max_id=0&count=10'
  财经 'FINANCIAL' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036388&containerid=102803_ctg1_6388_-_ctg1_6388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  读书 'READ' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034588&containerid=102803_ctg1_4588_-_ctg1_4588&extparam=discover%7Cnew_feed&max_id=0&count=10'
  摄影 'PHOTO' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034988&containerid=102803_ctg1_4988_-_ctg1_4988&extparam=discover%7Cnew_feed&max_id=0&count=10'
  汽车 'CAR' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035188&containerid=102803_ctg1_5188_-_ctg1_5188&extparam=discover%7Cnew_feed&max_id=0&count=10'
  电影 'MOVIE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028033288&containerid=102803_ctg1_3288_-_ctg1_3288&extparam=discover%7Cnew_feed&max_id=0&count=10'
  体育 'SPORT' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031388&containerid=102803_ctg1_1388_-_ctg1_1388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  数码 'DIGITAL' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035088&containerid=102803_ctg1_5088_-_ctg1_5088&extparam=discover%7Cnew_feed&max_id=0&count=10'
  综艺 'SHOW' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034688&containerid=102803_ctg1_4688_-_ctg1_4688&extparam=discover%7Cnew_feed&max_id=0&count=10'
  时尚 'FASHION' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034488&containerid=102803_ctg1_4488_-_ctg1_4488&extparam=discover%7Cnew_feed&max_id=0&count=10'
  星座 'CONSTELLATION' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031688&containerid=102803_ctg1_1688_-_ctg1_1688&extparam=discover%7Cnew_feed&max_id=0&count=10'
  军事 'MILITTARY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036688&containerid=102803_ctg1_6688_-_ctg1_6688&extparam=discover%7Cnew_feed&max_id=0&count=10'
  股市 'STOCK' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031288&containerid=102803_ctg1_1288_-_ctg1_1288&extparam=discover%7Cnew_feed&max_id=0&count=10'
  家居 'HOME' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035888&containerid=102803_ctg1_5888_-_ctg1_5888&extparam=discover%7Cnew_feed&max_id=0&count=10'
  萌宠 'PET' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032788&containerid=102803_ctg1_2788_-_ctg1_2788&extparam=discover%7Cnew_feed&max_id=0&count=10'
  科技 'TECH' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032088&containerid=102803_ctg1_2088_-_ctg1_2088&extparam=discover%7Cnew_feed&max_id=0&count=10'
  科普 'SCIENCE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035988&containerid=102803_ctg1_5988_-_ctg1_5988&extparam=discover%7Cnew_feed&max_id=0&count=10'
  动漫 'COMIC' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032388&containerid=102803_ctg1_2388_-_ctg1_2388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  健身 'FITNESS' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034788&containerid=102803_ctg1_4788_-_ctg1_4788&extparam=discover%7Cnew_feed&max_id=0&count=10'
  旅游 'TRIP' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032588&containerid=102803_ctg1_2588_-_ctg1_2588&extparam=discover%7Cnew_feed&max_id=0&count=10'
  瘦身 'SLIM' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036488&containerid=102803_ctg1_6488_-_ctg1_6488&extparam=discover%7Cnew_feed&max_id=0&count=10'
  历史 'HISTORY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036788&containerid=102803_ctg1_6788_-_ctg1_6788&extparam=discover%7Cnew_feed&max_id=0&count=10'
  艺术 'ART' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035488&containerid=102803_ctg1_5488_-_ctg1_5488&extparam=discover%7Cnew_feed&max_id=0&count=10'
  美妆 'MAKEUP' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031588&containerid=102803_ctg1_1588_-_ctg1_1588&extparam=discover%7Cnew_feed&max_id=0&count=10'
  法律 'LAW' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028037388&containerid=102803_ctg1_7388_-_ctg1_7388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  设计 'DESIGN' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035388&containerid=102803_ctg1_5388_-_ctg1_5388&extparam=discover%7Cnew_feed&max_id=0&count=10'
  健康 'HEALTH' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032188&containerid=102803_ctg1_2188_-_ctg1_2188&extparam=discover%7Cnew_feed&max_id=0&count=10'
  音乐 'MUSIC' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035288&containerid=102803_ctg1_5288_-_ctg1_5288&extparam=discover%7Cnew_feed&max_id=0&count=10'
  游戏 'GAME' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034888&containerid=102803_ctg1_4888_-_ctg1_4888&extparam=discover%7Cnew_feed&max_id=0&count=10'
  校园 'CAMPUS' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600177&containerid=102803_ctg1_600177_-_ctg1_600177&extparam=discover%7Cnew_feed&max_id=0&count=10'
  收藏 'COLLECTION' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038189&containerid=102803_ctg1_8189_-_ctg1_8189&extparam=discover%7Cnew_feed&max_id=0&count=10'
  政务 'GOV' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028035788&containerid=102803_ctg1_5788_-_ctg1_5788&extparam=discover%7Cnew_feed&max_id=0&count=10'
  养生 'REGIMEN' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036588&containerid=102803_ctg1_6588_-_ctg1_6588&extparam=discover%7Cnew_feed&max_id=0&count=10'
  育儿 'CHILDCARE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028033188&containerid=102803_ctg1_3188_-_ctg1_3188&extparam=discover%7Cnew_feed&max_id=0&count=10'
  抽奖 'LOTTERY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600037&containerid=102803_ctg1_600037_-_ctg1_600037&extparam=discover%7Cnew_feed&max_id=0&count=10'
  国学 'SINOLOGY' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600032&containerid=102803_ctg1_600032_-_ctg1_600032&extparam=discover%7Cnew_feed&max_id=0&count=10'
  教育 'EDU' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600080&containerid=102803_ctg1_600080_-_ctg1_600080&extparam=discover%7Cnew_feed&max_id=0&count=10'
  舞蹈 'DANCE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038788&containerid=102803_ctg1_8788_-_ctg1_8788&extparam=discover%7Cnew_feed&max_id=0&count=10'
  辟谣 'DEBUNK' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036988&containerid=102803_ctg1_6988_-_ctg1_6988&extparam=discover%7Cnew_feed&max_id=0&count=10'
  三农 'FARM' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028037188&containerid=102803_ctg1_7188_-_ctg1_7188&extparam=discover%7Cnew_feed&max_id=0&count=10'
# 热门榜单：https://weibo.com/hot/list/1028039999
  小时榜 'HOUR' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&group_id=1028039999&containerid=102803_ctg1_9999_-_ctg1_9999_home&extparam=discover|new_feed&max_id=0&count=10'
  昨天榜 'DAY1' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038899&containerid=102803_ctg1_8899_-_ctg1_8899&extparam=discover|new_feed&max_id=0&count=10'
  前天榜 'DAY2' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038799&containerid=102803_ctg1_8799_-_ctg1_8799&extparam=discover%7Cnew_feed&max_id=0&count=10'
  周榜 'WEEK' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038698&containerid=102803_ctg1_8698_-_ctg1_8698&extparam=discover%7Cnew_feed&max_id=0&count=10'
  男性榜 'MALE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038998&containerid=102803_ctg1_8998_-_ctg1_8998&extparam=discover%7Cnew_feed&max_id=0&count=10'
  女性榜 'FEMALE' 'https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038997&containerid=102803_ctg1_8997_-_ctg1_8997&extparam=discover%7Cnew_feed&max_id=0&count=10'
)
# 话题榜：https://weibo.com/hot/topic
WEIBO_TOPIC_URL='https://weibo.com/ajax/statuses/topic_band?sid=v_weibopro&category=all&page=1&count=50'
# 热搜榜：https://weibo.com/hot/search
WEIBO_HOT_SEARCH_URL='https://weibo.com/ajax/statuses/hot_band'
# 单个微博
WEIBO_POST_URL='https://weibo.com/ajax/statuses/show?id=0'
# 微博评论
WEIBO_COMMENT_URL='https://weibo.com/ajax/statuses/buildComments?is_reload=1&id=0&is_show_bulletin=2&is_mix=0&count=0&uid=0'

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

source `dirname $0`/lib.sh

function record() {
  local title="$1"
  local link="$2"
  echo -e "\033[33m标题\033[0m: \033[1;31m$title\033[0m"
  echo -e "\033[33m地址\033[0m: \033[4;32m$link\033[0m"
}

function weibo() {
  local url="$WEIBO_HOT_SEARCH_URL"
  local i=0
  local id=$2
  case ${1:-hs} in
    hotsearchs|hss) url="$WEIBO_HOT_SEARCH_URL";;
    yaowen|vip) url="$WEIBO_YAOWEN_URL";;
    wenyu|ent) url="$WEIBO_WENYU_URL";;
    comment|cm) weiboComment ${@:2}; return;;
    *) weiboJSON ${@:1}; return;;
  esac
  local cookie='WBtopGlobal_register_version=2022092420; SUB=_2AkMUbAblf8NxqwJRmP8cym7maYVxzA_EieKiMPc-JRMxHRl-yj9jqnYTtRB6P-woCiESbtf6EHlSgKmMG7dCXC4FjogI; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9WFWfCTPhyRMY-ccV7R.KDN9; _s_tentry=-; Apache=4137248597898.631.1664186064613; SINAGLOBAL=4137248597898.631.1664186064613; ULV=1664186064653:1:1:1:4137248597898.631.1664186064613:'

  curl -s "$url" -b "$cookie" | awk '/<table/,/<\/table>/'| grep -oE '<a[^"]*>[^"]*<\/a>' | sed -re 's/([^"]*")//' -e 's/"[^>]*>/ /' -e 's/<\/a>$//' |
  while read line; do
    record "[`expr $i + 1`] ${line##* }" "https://s.weibo.com${line%% *}"
    echo
    i=`expr $i + 1`
  done
}

function resolveLink() {
  local link=${1//\?*/}
  link=${link//\\\?*/}
  link=${link//\#*/}
  link=${link//\\\#*/}
  local parts=(`echo $link | grep -oE '[^\/]+'`)
  echo "${parts[*]}"
}

# https://weibo.com/1600463082/M74GseLpY
function weiboPost() {
  local parts=(`resolveLink $1`)
  local pid=${parts[@]:3:1}
  local posturl=${WEIBO_POST_URL//id=0/id=$pid}
  # cat weibo.post.json
  local post=`curl -s $posturl`
  echo "$post"
}

function weiboComment() {
  local url="$WEIBO_COMMENT_URL"
  local link="$1"
  local count=10
  local parts=(`resolveLink $link`)
  local uid=${parts[@]:2:1}
  local pid=${parts[@]:3:1}
  local post=`weiboPost $link`
  local id=`echo $post | grep -oE '"idstr":".+?"' | head -1 | cut -d'"' -f4`
  url=${url//uid=0/uid=$uid}
  url=${url//id=0/id=$id}
  url=${url//count=0/count=$count}
  local aliases=('内容' '来源' '用户' '粉丝' '空间')
  local fields=('content' 'source' 'user' 'follewers' 'url')
  local patterns=('"text_raw":"[^"]*"' '"source":"[^"]*"' '"screen_name":"[^"]*"' '"followers_count_str":"[^"]*"' '"profile_url":"[^"]*"')
  local indexes=(4 4 4 4 4)
  local transformers=(' ' ' ' ' ' ' ' ' ' 'https://weibo.com${values[@]:4:1}')
  echo Comment: $url
  print_json -u "$url" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}"
}

# 从 三维目标数组 获取地址
function getUrl() {
  local urls=($1)
  local cate=$2
  local length=$((${#urls[@]}-1))
  if [[ -z $cate ]]; then
    for i in `seq 0 3 $length`; do
      [[ $((i/3%6)) -eq 0 ]] && echo 1>&2
      printf '%b %b %b  |  ' "\033[31m$i\033[0m" "\033[32m${urls[@]:$i:1}\033[0m" "\033[37m${urls[@]:$((i+1)):1}\033[0m" 1>&2
    done
    echo 1>&2
    read -p $'\n输入分类：' cate
  fi
  (
  shopt -s nocasematch
  for i in `seq 0 3 $length`; do
    if [[ $cate = $i || "$cate" =~ ^${urls[@]:$i:1}$ || "$cate" =~ ^${urls[@]:$((i+1)):1}$ ]]; then
      printf '%b ' "\033[31m${urls[@]:$i:1}\033[0m" 1>&2
      echo "${urls[@]:$((i+2)):1}"
      exit 0
    fi
  done
  )
}

function weiboJSON() {
  local url
  local -a fields
  local -a indexes
  local -a aliases
  local -a patterns

  case $1 in
    hotpost|hp)
      url=$(getUrl "${WEIBO_HOT_POST_URLS[*]}" $2)
      aliases=('内容' '来源' '用户' '空间' 'mid' '地址' '地域');
      fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
      patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
      indexes=(4 4 4 4 4 4 4);
      transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
      jsonFormat='statuses:(内容)text_raw|red,(来源)source,(博主)user.screen_name,(空间)user.idstr,(地址)mblogid,(地区)region_name,(视频封面)page_info.page_pic,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url,(图片)pic_infos:(地址)original.url'
      ;;
    hottopic|ht)
      url="$WEIBO_TOPIC_URL"
      aliases=('标签' '内容' '分类' '阅读量' '讨论' '地址')
      fields=('topic' 'summary' 'category' 'read' 'mention' 'mid')
      patterns=('"topic":"[^"]*"' '"summary":"[^"]*"'  '"category":"[^"]*"' '"read":[^,]*,' '"mention":[^,]*,' '"mid":"[^"]"*')
      indexes=(4 4 4 3 3 4)
      transformers=('_' '_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
      ;;
    hotsearch|hs)
      url="$WEIBO_HOT_SEARCH_URL";
      aliases=('标题' '分类' '热度' '地址')
      fields=('word' 'category' 'num' 'note')
      patterns=('_' '"(category|ad_type)":"[^"]*"' '"num":[^,]*,' '_')
      indexes=(4 4 3 4)
      transformers=('_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
      ;;
     *) return;;
  esac
  if [[ -z "$url" ]]; then
    echo "没有地址" 1>&2; exit 1;
  fi
  print_json -u "$url" -t "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat"
}

function baidu() {
  local url="$BAIDU_HOT_URL"
  local i=0
  curl -s "$url" | grep -oE '<a[^"]*>[^"]*</a>' | grep -E 'class="title_' | sed -re 's/[^"]*"//' -e 's/"[^>]*>//' -e 's/<[^>]*>//' -e 's/<\/div>.*$//' |
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
  local -a patterns
  local -a indexes
  local type="$1"
  local domain="$2"
  case ${type:=hot} in
    hot|ht|hour) url="$ZHIHU_HOUR_URL"; patterns=('"title":"[^"]*"' '"url":"[^"]*"'); indexes=(4 4);;
    day) url="$ZHIHU_DAY_URL"; patterns=('"title":"[^"]*"' '"url":"[^"]*"'); indexes=(4 4);;
    week) url="$ZHIHU_WEEK_URL"; patterns=('"title":"[^"]*"' '"url":"[^"]*"'); indexes=(4 4);;
  esac
  url=`applyZhihuDomain $url $domain`
  local -a fields=(title link)
  local -a aliases=(标题 链接)
  print_json -u "$url" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}"
}

function toutiao() {
  # https://www.toutiao.comhttps://tsearch.snssdk.com/search/suggest/hot_words/
  local type=$1
  local url=''
  local -a patterns
  local -a indexes
  local -a transformers
  case ${type:=hot} in
    hot|ht) url="$TOUTIAO_HOT_URL";
      patterns=('"Title":"[^"]*"' '"Url":"[^"]*"');
      indexes=(4 4);;
    hs|search) url="$TOUTIAO_HOT_SEARCH_URL";
      patterns=('"query":"[^"]*"' '"query":"[^"]*"');
      indexes=(4 4);
      transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title');;
  esac
  local -a fields=(title link)
  local -a aliases=(标题 链接)
  print_json -u "$url" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}"
}

function json_res() {
  local url
  local -a aliases
  local -a fields
  local -a patterns
  local -a indexes
  local -a transformers
  local -a types
  case $1 in
    bilibili|bb)
      aliases=(标题 作者 分类 浏览 点赞 链接 描述 图片)
      fields=(title name tname view like short_link desc pic)
      patterns=(_ _ _ '"view":[^,]*,' '"like":[^,]*,' _ _ _)
      indexes=(4 4 4 3 3 4 4 4)
      transformers=(_ _ _ _ _ _ _ '${values[@]:7:1}@412w_232h_1c.jpg')
      types=(_ _ _ _ _ _ _ img)
      case $2 in
        hot|ht)
          url='https://api.bilibili.com/x/web-interface/popular?ps=20&pn=1'
          ;;
        week|wk)
          local week=$3
          if [[ $week -eq 0 ]]; then
            week=`curl -s https://api.bilibili.com/x/web-interface/popular/series/list | grep -oE '"number":[^,]*,' | head -1 | grep -oE '\d+'`
          elif [[ -z $week ]]; then
            json_res bb wkl
            read -p '输入周编号:' week
            echo -e "第\033[32m$week\033[0m周"
          fi
          url="https://api.bilibili.com/x/web-interface/popular/series/one?number=$week"
          ;;
        weeklist|wkl)
          url='https://api.bilibili.com/x/web-interface/popular/series/list'
          aliases=(主题 编号 名称)
          fields=(subject number name)
          patterns=(_ '"number":[^,]*,' _)
          indexes=(4 3 4)
          transformers=(_ '\\033[0m第\\033[31m${values[@]:1:1}\\033[0m周' _)
          types=(_ _ _)
          ;;
      esac
      ;;
  esac
  print_json -u "$url" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -y "${types[*]}"
}

case $1 in
  weibo|wb) weibo ${@:2};;
  baidu|bd) baidu ${@:2};;
  zhihu|zh) zhihu ${@:2};;
  toutiao|tt) toutiao ${@:2};;
  -h) echo '
  weibo|wb
    wenyu|wy
    comment|cm [postUrl]
    hotsearch|hs
    hotpost|hp
    hottopic|ht)

  baidu|bd

  zhihu|zh
    hot|ht
    day
    hour
    week

  toutiao|tt
    hot|ht
    hotsearch|hs
    '
    ;;
  *) json_res ${@:1};;
esac

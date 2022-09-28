#! /usr/bin/env bash

WEIBO_HOT_SEARCH_URL='https://s.weibo.com/top/summary?cate=top_hot'
WEIBO_YAOWEN_URL='https://s.weibo.com/top/summary?cate=socialevent'
WEIBO_WENYU_URL='https://s.weibo.com/top/summary?cate=entrank'
# 热门微博：https://weibo.com/hot/weibo/102803
# 热门
WEIBO_HOT_POST_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=0&group_id=102803&containerid=102803&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 同城
WEIBO_HOT_POST_CITY_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032222&containerid=102803_2222&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 榜单
WEIBO_HOT_POST_LIST_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600169&containerid=102803_ctg1_600169_-_ctg1_600169&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 明星
WEIBO_HOT_POST_STAR_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034288&containerid=102803_ctg1_4288_-_ctg1_4288&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 抗疫
WEIBO_HOT_POST_ANTICOVID19_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600115&containerid=102803_ctg1_600115_-_ctg1_600115&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 好物
WEIBO_HOT_POST_GOODTHING_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600094&containerid=102803_ctg1_600094_-_ctg1_600094&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 搞笑
WEIBO_HOT_POST_FUNNY_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034388&containerid=102803_ctg1_4388_-_ctg1_4388&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 颜值
WEIBO_HOT_POST_BEAUTY_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600165&containerid=102803_ctg1_600165_-_ctg1_600165&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 社会
WEIBO_HOT_POST_SOCIETY_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028034188&containerid=102803_ctg1_4188_-_ctg1_4188&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 情感
WEIBO_HOT_POST_EMOTION_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028031988&containerid=102803_ctg1_1988_-_ctg1_1988&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 新时代
WEIBO_HOT_POST_NEWERA_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028037968&containerid=102803_ctg1_7968_-_ctg1_7968&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 电视剧
WEIBO_HOT_POST_TV_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032488&containerid=102803_ctg1_2488_-_ctg1_2488&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 美食
WEIBO_HOT_POST_FOOD_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028032688&containerid=102803_ctg1_2688_-_ctg1_2688&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 国际
WEIBO_HOT_POST_I18N_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036288&containerid=102803_ctg1_6288_-_ctg1_6288&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 深度
WEIBO_HOT_POST_DEEP_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=102803600155&containerid=102803_ctg1_600155_-_ctg1_600155&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 财经
WEIBO_HOT_POST_FINANCE_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028036388&containerid=102803_ctg1_6388_-_ctg1_6388&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 热门榜单：https://weibo.com/hot/list/1028039999
# 小时榜
WEIBO_HOT_HOUR_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&group_id=1028039999&containerid=102803_ctg1_9999_-_ctg1_9999_home&extparam=discover|new_feed&max_id=0&count=50'
# 昨天榜
WEIBO_HOT_DAY1_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038899&containerid=102803_ctg1_8899_-_ctg1_8899&extparam=discover|new_feed&max_id=0&count=50'
# 前天榜
WEIBO_HOT_DAY2_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038799&containerid=102803_ctg1_8799_-_ctg1_8799&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 周榜
WEIBO_HOT_WEEK_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038698&containerid=102803_ctg1_8698_-_ctg1_8698&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 男性榜
WEIBO_HOT_MALE_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038998&containerid=102803_ctg1_8998_-_ctg1_8998&extparam=discover%7Cnew_feed&max_id=0&count=50'
# 女性榜
WEIBO_HOT_FEMALE_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id=1028038997&containerid=102803_ctg1_8997_-_ctg1_8997&extparam=discover%7Cnew_feed&max_id=0&count=50'
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

function weiboJSON() {
  local url
  local -a fields
  local -a indexes
  local -a aliases
  local -a patterns
  aliases=('内容' '来源' '用户' '空间' 'mid' '地址' '地域');
  fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
  patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
  indexes=(4 4 4 4 4 4 4);
  transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
  case $1 in
    hotpost|hp)
      url="$WEIBO_HOT_POST_URL";;
    hothour|hh)
      url="$WEIBO_HOT_HOUR_URL";;
    hotday1|hd1)
      url="$WEIBO_HOT_DAY1_URL";;
    hotday2|hd2)
      url="$WEIBO_HOT_DAY2_URL";;
    hotweek|hw)
      url="$WEIBO_HOT_WEEK_URL";;
    hotmale|hm)
      url="$WEIBO_HOT_MALE_URL";;
    hotfemale|hf)
      url="$WEIBO_HOT_FEMALE_URL";;
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
  print_json -u "$url" -t "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}"
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
    hot|ht) url="$ZHIHU_HOT_URL"; patterns=('"target":{[^"]*}' '"link":{[^"]*}'); indexes=(8 6);;
    hour) url="$ZHIHU_HOUR_URL"; patterns=('"title":"[^"]*"' '"url":"[^"]*"'); indexes=(4 4);;
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
    hothour|hh
    hotday1|hd1
    hotday2|hd2
    hotweek|hw
    hotmale|hm
    hotfemale|hf
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
esac

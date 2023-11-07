#! /usr/bin/env bash

source `dirname $0`/lib.sh

export SHOULD_STORE=${SHOULD_STORE-1}
# 微博 #

WEIBO_RESOU='https://weibo.com/ajax/side/hotSearch'
# 热门微博 https://weibo.com/hot/weibo/102803
# https://weibo.com/5368633408/M7OL9bpQP
WEIBO_HOT_POST_URL='https://weibo.com/ajax/feed/hottimeline?since_id=0&refresh=1&group_id={gid}&containerid={containerid}&extparam=discover%7Cnew_feed&max_id=0&count={count}'
# 话题榜：https://weibo.com/hot/topic
WEIBO_TOPIC_URL='https://weibo.com/ajax/statuses/topic_band?sid=v_weibopro&category=all&page=1&count=50'
# 热搜榜：https://weibo.com/hot/search
WEIBO_HOT_SEARCH_URL='https://weibo.com/ajax/statuses/hot_band'
WEIBO_YAOWEN_URL='https://s.weibo.com/top/summary?cate=socialevent'
WEIBO_WENYU_URL='https://s.weibo.com/top/summary?cate=entrank'
# 单个微博 https://weibo.com/2209943702/LdmCDsWJ1 https://weibo.com/1600463082/M74GseLpY
WEIBO_POST_URL='https://weibo.com/ajax/statuses/show?id={postid}'
# 微博评论
WEIBO_COMMENT_URL='https://weibo.com/ajax/statuses/buildComments?is_reload=1&id={id}&is_show_bulletin=2&is_mix=0&count={count}&uid={uid}'

WEIBO_COOKIE='SUB=_2AkMURLcVf8NxqwJRmf4dxWnibYt1zw7EieKiGEbOJRMxHRl-yj9jqlA5tRB6P8SZ-sVAyb47oXgB6AyfiRc9-7xR7yRm; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9WF4VUMWr7cwiXmHLTNg6r1_; _s_tentry=passport.weibo.com; Apache=8391341077463.448.1662531621404; SINAGLOBAL=8391341077463.448.1662531621404; ULV=1662531621904:1:1:1:8391341077463.448.1662531621404:; XSRF-TOKEN=MkiCz9ExHhEkPHMDe4m_CKo3; UPSTREAM-V-WEIBO-COM=b09171a17b2b5a470c42e2f713edace0; WBPSESS=lNnN0y56c_PyZjitu4VSQuhIDfylTG73R0VCdEVJKXZyq5dLPRyphcDEPWK349cIRnjClFaesjDYwVM73eMe3-cc8Zcjh3TZJa8-EXcQqFnfoyiSAoq-RThcas0JDgdgq8KXZhN2aOvxcyxA5-ctTmAJO8fkNrSnbKOUyezSRYI='

# 知乎 #

ZHIHU_HOT_URL='https://www.zhihu.com/billboard'
#ZHIHU_HOT_SEARCH_URL='https://www.zhihu.com/api/v4/topics/19964449/feeds/top_activity?limit=10'

ZHIHU_DOMAINS=(全部 数码 科技 互联网 商业财经 职场 教育 法律 军事 汽车 人文社科 自然科学 工程技术 情感 心理学 两性 母婴亲子 家居 健康 艺术 音乐 设计 影视娱乐 宠物 体育电竞 运动健身 动漫游戏 美食 旅行 时尚)
ZHIHU_DOMAINS_NUM=(0  100001  100002  100003  100004  100005  100006  100007  100008  100009  100010  100011  100012  100013  100014  100015  100016  100017  100018  100019  100020  100021  100022  100023  100024  100025  100026  100027  100028  100029)

function ask_date_range() {
  local format=${DATE_FORMAT:-%Y-%m-%d}
  local d=($(question2 -q "${_ASK_DATE_RANGE:-起止日期}" -Q "（如\033[4m$(date +$format) $(date +$format)\033[24m，相同可以省略第二个值）" -d "$1 $2"))
  [[ $1 && ! "${d[@]:0:1}" ]] && d[0]=$1
  [[ $2 && ! "${d[@]:1:1}" ]] && d[1]=$2
  echo "${d[@]}"
}

function unknown() {
  printf "\033[31m未知命令\033[0m："
  local index=$(($1 + 1))
  for i in $(seq 2 $#); do
    [[ $index -eq $i ]] && printf "\033[4;31m%s\033[0m " ${@:$i:1} || printf "%s " ${@:$i:1}
  done
  echo
  echo -e '\033[31m可用命令如下\033[0m：'
  help ${@:2:$(($1 - 1))} -h
  exit 1
}

function json_res() {
  local url
  local text
  local -a aliases
  local -a fields
  local -a patterns
  local -a indexes
  local -a transformers
  local -a filters
  local jsonFormat
  local curlparams=(
    -G --compressed
    -H 'cache-control: no-cache'
    -H 'pragma: no-cache'
    -H 'sec-ch-ua: "Google Chrome";v="107", "Chromium";v="107", "Not=A?Brand";v="24"'
    -H 'sec-ch-ua-mobile: ?0'
    -H 'sec-ch-ua-platform: "macOS"'
    -H 'sec-fetch-dest: empty'
    -H 'sec-fetch-mode: cors'
    -H 'sec-fetch-site: same-site'
    -H 'user-agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36'
  )
  local outputfile="$1"
  local tailer=''
  local _today=$(date +%Y-%m-%d)
  local _today2=$(date +%Y%m%d)
  local _last_trade_day=$_today2
  if [[ $(bc <<< "$(date +%H) < 9") ]]; then
    _last_trade_day=$(date -v-1d +%Y%m%d)
  fi
  local jsonp
  case $1 in
    微博|weibo|wb)
      outputfile="$outputfile.$2"
      case $2 in
        分组|groups|gps)
          url='https://weibo.com/ajax/feed/allGroups?is_new_segment=1&fetch_hot=1'
          text=$(curl -s "$url")
          debug $text
          local recording=3
          local -a gids=()
          local -a groups=()
          local -a containerids=()
          local gid
          while read line; do
            if [[ $line =~ ^gid && $recording > 1 ]]; then
              [[ $recording = 2 ]] && containerids+=($gid)
              gid=${line//gid /}
              gids+=($gid)
              recording=1
            elif [[ $line =~ ^title && $recording = 1 ]]; then
              groups+=(${line//title /})
              recording=2
            elif [[ $line =~ ^containerid && $recording = 2 ]]; then
              containerids+=(${line//containerid /})
              recording=3
            fi
          done < <(echo $text | grep -oE '"(gid|containerid|title)":"[^"]*"' | sed -n 's/"//g;s/:/ /p')
          ask "${groups[*]}" $3
          local group=$_ASK_RESULT
          debug $_ASK_RESULT
          debug ${groups[@]}
          debug ${gids[@]}
          debug ${containerids[@]}
          debug ${_ASK_INDEX}
          echo "$group ${gids[@]:$_ASK_INDEX:1} ${containerids[@]:$_ASK_INDEX:1}"
          exit 0
        ;;
        热门微博|hotpost|hp)
          local group=($(json_res weibo groups $3))
          local gid=${group[@]:1:1}
          local containerid=${group[@]:2:1}
          local count=${4:-10}
          url="$WEIBO_HOT_POST_URL"
          url=${url//\{gid\}/$gid}
          url=${url//\{containerid\}/$containerid}
          url=${url//\{count\}/$count}
          aliases=('内容' '来源' '博主' '空间' 'mid' '链接' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat='statuses:(内容)text_raw|red|bold|index|newline(-1),(来源)source|dim,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{statuses:user.idstr}$|dim,(链接)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$|dim,(地区)region_name|dim,(视频封面)page_info.page_pic|image|dim,(视频)page_info.media_info.mp4_sd_url|dim,(图片)pic_infos*.original.url|image|dim'
        ;;
        用户微博|userpost|up) # 用户微博 https://weibo.com/u/2209943702
          uid=$(question2 -q '微博用户ID' -i "$3")
          stat_date=$(question2 -q "微博发布月份" -Q "如$(date +%Y%m)" -i "$4" -d "$(date +%Y%m)")
          feature=$(ask2 -q '分类' -d 0 -1 -a '全部 原创 热门 付费' -a '0 1 2 17')
          url='https://weibo.com/ajax/statuses/mymblog'
          curlparams+=(--data-urlencode uid=$uid)
          curlparams+=(--data-urlencode page=${PAGE:-1})
          curlparams+=(--data-urlencode feature=$feature)
          curlparams+=(--data-urlencode stat_date=$stat_date)
          curlparams+=(-b "$WEIBO_COOKIE")

          aliases=('内容' '来源' '博主' '空间' 'mid' '链接' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat='data.list:(内容)text_raw|red|bold|index,(用户)user.screen_name|magenta,(发布设备)source,(发布地点)region_name,(发布时间)created_at|date,(用户空间)user.idstr|$https://weibo.com/u/{data.list:user.idstr}$|dim,(链接)mblogid|$https://weibo.com/{data.list:user.idstr}/{data.list:mblogid}$|dim,(视频封面)page_info.page_pic|dim|image,(视频)page_info.media_info.mp4_sd_url|dim,(图片)pic_infos*.original.url|dim|image'
        ;;
        话题榜|hottopic|ht)
          url="$WEIBO_TOPIC_URL"
          aliases=('标签' '内容' '分类' '阅读量' '讨论' '链接')
          fields=('topic' 'summary' 'category' 'read' 'mention' 'mid')
          patterns=('"topic":"[^"]*"' '"summary":"[^"]*"'  '"category":"[^"]*"' '"read":[^,]*,' '"mention":[^,]*,' '"mid":"[^"]"*')
          indexes=(4 4 4 3 3 4)
          transformers=('_' '_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.statuses:(标签)topic|red|bold|index,(内容)summary|white|dim,(分类)category|magenta,(阅读量)read|number,(讨论数)mention|number,(链接)mid|$https://s.weibo.com/weibo?q=%23{data.statuses:mid}%23$|dim,(图片)images_url|image|dim'
        ;;
        热搜榜|hotsearch|hs)
          url="$WEIBO_HOT_SEARCH_URL";
          aliases=('标题' '分类' '热度' '原始热度' '链接')
          fields=('word' 'category' 'num' 'raw_hot' 'note')
          patterns=('_' '"(category|ad_type)":"[^"]*"' '"num":[^,]*,' '"raw_hot":[^,]*,' '_')
          indexes=(4 4 3 3 4)
          transformers=('_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.band_list|TABLE:(标题)word|red|bold|index,(分类)category|magenta|dim,(热度)num|number,(原始热度)raw_hot|number,(链接)note|$https://s.weibo.com/weibo?q=%23{data.band_list:word|urlencode}%23$|dim'
        ;;
        微博|post|ps)
          local postid="$3" # M7OL9bpQP
          if [[ $postid =~ ^http ]]; then
            local parts=(`resolveLink $3`)
            postid=${parts[@]:3:1}
          fi
          local posturl=${WEIBO_POST_URL//\{postid\}/$postid}
          text=`curl -s "$posturl"`
          aliases=('内容' '来源' '博主' '空间' 'mid' '链接' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat=':(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{:user.idstr}$|dim,(链接)mblogid|$https://weibo.com/{:user.idstr}/{:mblogid}$|dim,(地区)region_name|dim,(视频封面)page_info.page_pic|image|dim,(视频)page_info.media_info.mp4_sd_url|dim,(图片)pic_infos*.original.url|image|dim'
        ;;
        微博评论|comment|cm)
          local count=${4:-10}
          local post=`RAW=1 json_res weibo post $3`
          # 4816863043518870
          local id=`echo $post | grep -oE '"idstr":".+?"' | head -1 | cut -d'"' -f4`
          # 1600463082
          local uid=`echo $post | grep -oE '"idstr":".+?"' | tail -1 | cut -d'"' -f4`
          url="$WEIBO_COMMENT_URL"
          url=${url//\{uid\}/$uid}
          url=${url//\{id\}/$id}
          url=${url//\{count\}/$count}
          aliases=('内容' '来源' '用户' '粉丝' '空间')
          fields=('content' 'source' 'user' 'follewers' 'url')
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*"' '"screen_name":"[^"]*"' '"followers_count_str":"[^"]*"' '"profile_url":"[^"]*"')
          indexes=(4 4 4 4 4)
          transformers=('_' '_' '_' '_' 'https://weibo.com${values[@]:4:1}')
        ;;
        搜索|search)
          # https://m.weibo.cn/search?containerid=100103type%3D1%26q%3Dhello
          local keyword="$4"
          local types=(1 综合 61 实时 3 用户 62 关注 64 视频 63 图片 21 文章 60 热门 38 话题 98 超话 92 地点 97 商品 32 主页)
          # url="https://weibo.com/ajax/side/search?q=$keyword"
          # jsonFormat='data.hotquery|TABLE:(词条)suggestion|red|bold,(结果数量)count|number'
          # text=$(cat data/weibo.search/2022-11-01.22:58:58.json)
          outputfile="$outputfile.$3"
          case $3 in
            综合|complex)
              type=1
              # text=$(cat data/weibo.search/2022-11-02.20:43:50.json)
              jsonFormat='data.cards:card_group.0|DOWNGRADE:(内容)mblog.text|striptags|red|bold|index,(来源)region_name|${.mblog.region_name} {.mblog.source}$,(用户昵称)mblog.user.screen_name,(粉丝数)mblog.user.followers_count_str,(简介)mblog.user.description,(用户主页)space|$https://weibo.com/u/{.mblog.user.id}$|dim,(链接)url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(页面标题)mblog.page_info.page_title,(页面链接)mblog.page_info.page_url,(图片)mblog.pics*.url|image|dim'
            ;;
            实时|realtime)
              type=61
              jsonFormat='data.cards:(内容)mblog.text|striptags|red|bold|index,(来源)region_name|${.mblog.region_name} {.mblog.source}$,(用户昵称)mblog.user.screen_name,(粉丝数)mblog.user.followers_count_str,(简介)mblog.user.description,(用户主页)space|$https://weibo.com/u/{.mblog.user.id}$|dim,(链接)url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(页面标题)mblog.page_info.page_title,(页面链接)mblog.page_info.page_url,(图片)mblog.pics*.url|image|dim'
            ;;
            用户|user)
              type=3
              jsonFormat='data.cards.1.card_group:(昵称)user.screen_name|red|bold|index,(粉丝数)user.followers_count_str,(认证信息)user.verified_reason|magenta,(链接)user.profile_url|dim,(头像)user.profile_image_url|image|dim'
            ;;
            关注|follow)
              type=62
              jsonFormat='data.cards:(内容)mblog.text|striptags|red|bold|index,(来源)region_name|${.mblog.region_name} {.mblog.source}$,(用户昵称)mblog.user.screen_name,(粉丝数)mblog.user.followers_count_str,(简介)mblog.user.description,(用户主页)space|$https://weibo.com/u/{.mblog.user.id}$|dim,(链接)url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(页面标题)mblog.page_info.page_title,(页面链接)mblog.page_info.page_url,(图片)mblog.pics*.url|image|dim'
            ;;
            视频|video)
              type=64
              jsonFormat='data.cards:card_group:(标题)title,(用户昵称)user.screen_name,(粉丝数)user.followers_count_str,(简介)user.description,(用户主页)space|$https://weibo.com/u/{.user.id}$|dim,(链接)scheme|dim'
            ;;
            图片|image)
              type=63
              jsonFormat='data.cards:card_group:(内容)left_element.desc1|red|bold,(来源)left_element.mblog.source|${.mblog.source} {.mblog.city}$,(链接)left_element.url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(图片)left_element.mblog.original_pic|image|dim,(内容)right_element.desc1|red|bold|index,(来源)right_element.mblog.source|${.mblog.source} {.mblog.city}$,(链接)right_element.url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(图片)right_element.mblog.original_pic|image|dim'
            ;;
            文章|article)
              type=21
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc1|dim,(描述2)desc2|dim,(链接)openurl|dim,(图片)pic|image|dim'
            ;;
            热门|hot)
              type=60
              jsonFormat='data.cards:(内容)mblog.text|striptags|red|bold|index,(来源)region_name|${.mblog.region_name} {.mblog.source}$,(用户昵称)mblog.user.screen_name,(粉丝数)mblog.user.followers_count_str,(简介)mblog.user.description,(用户主页)space|$https://weibo.com/u/{.mblog.user.id}$|dim,(链接)url|$https://weibo.com/{.mblog.user.id}/{.mblog.id}$|dim,(页面标题)mblog.page_info.page_title,(页面链接)mblog.page_info.page_url,(图片)mblog.pics*.url|image|dim'
            ;;
            话题|topic)
              type=38
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc1|dim,(描述2)desc2|dim,(链接)openurl|dim,(图片)pic|image|dim'
            ;;
            超话|super)
              type=98
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc1|dim,(描述2)desc2|dim,(链接)openurl|dim,(图片)pic|image|dim'
            ;;
            地点|position)
              type=92
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc1|dim,(描述2)desc2|dim,(链接)openurl|dim,(图片)pic|image|dim'
            ;;
            地点|position)
              type=92
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc1|dim,(描述2)desc2|dim,(链接)openurl|dim,(图片)pic|image|dim'
            ;;
            商品|good)
              type=97
              jsonFormat='data.cards.1.card_group:items:(标题)title|red|bold,(价格)price2,(描述)desc1|dim,(描述2)desc2|dim,(链接)scheme|dim,(图片)pic|image|dim'
            ;;
            主页|mainpage)
              type=32
              jsonFormat='data.cards:card_group:(标题)title_sub|red|bold,(描述)desc|dim,(描述1)desc1|dim,(描述2)desc2|dim,(链接)scheme|dim,(图片)pic|image|dim'
            ;;
          esac
          url='https://m.weibo.cn/api/container/getIndex'
          curlparams+=(--data-urlencode "containerid=100103type=$type&q=$keyword&t=")
          curlparams+=(--data-urlencode page_type=searchall)
          curlparams+=(--data-urlencode page=${PAGE:-1})
        ;;
        建议|suggest)
          url='https://s.weibo.com/Ajax_Search/suggest'
          curlparams+=(--data-urlencode where=weibo)
          curlparams+=(--data-urlencode type=hot)
          curlparams+=(--data-urlencode key=)
          curlparams+=(--data-urlencode __rnd=$(timestamp))
          jsonFormat=''
        ;;
        *) return;;
      esac
    ;;
    知乎|zhihu|zh)
      outputfile="$outputfile.$2"
      case ${2:-hs} in
        热榜|hot|ht) # https://www.zhihu.com/knowledge-plan/hot-question/hot/0/hour
          url='https://www.zhihu.com/api/v4/creators/rank/hot?domain={domain}&period={period}&limit=50'
          fields=(title link)
          aliases=(标题 链接)
          patterns=('"title":"[^"]*"' '"url":"[^"]*"')
          indexes=(4 4)
          jsonFormat='data:(标题)question.title|red|bold|index,(链接)question.url|dim,(时间)question.created|date|dim,(标签)question.topics*.name|join|dim'
          outputfile="$outputfile.$3"
          case ${3:-hour} in
            日榜|day)
              url=${url//\{period\}/day}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            周榜|week)
              url=${url//\{period\}/week}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            小时榜|hot|ht|hour)
              url=${url//\{period\}/hour}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
          esac
        ;;
        热搜|hotsearch|hs|billboard|bb)
          url='https://www.zhihu.com/billboard'
          text=$(curl -s "$url" | grep -oE '<script id="js-initialData" type="text/json">.*<\/script>' | sed -nE 's/<script[^>]*>//;s/<\/script>.*//p')
          aliases=(标题 描述 热度 链接 图片)
          fields=('title' 'excerpt' 'metricsArea' 'link' 'image')
          patterns=('"titleArea":{"text":"[^"]*"' '"excerptArea":{"text":"[^"]*"' '"metricsArea":{"text":"[^"]*"' '"link":{"url":"[^"]*"' '"imageArea":{"url":"[^"]*"')
          indexes=(6 6 6 6 6)
          jsonFormat="initialState.topstory.hotList:(标题)target.titleArea.text|red|bold|index,(描述)target.excerptArea.text|white|dim,(热度)target.metricsArea.text|magenta,(链接)target.link.url|dim,(图片)target.imageArea.url|dim|image"
        ;;
        搜索建议|searchsuggest|ss)
          local query="$3"
          url="https://www.zhihu.com/api/v4/search/suggest?q=$query"
          jsonFormat='suggest:(关键词)query|red|bold,(链接)id|$https://www.zhihu.com/search?type=content&q={suggest:query}$|dim'
        ;;
        搜索|search)
          _ASK_MSG='请输入搜索类别（默认为综合）：' ask '综合 用户 话题 视频 学术 专栏 盐选内容 电子书' $4
          local categories=(general user topic zvideo scholar column km_general publication)
          local category=${categories[@]:${_ASK_INDEX:-0}:1}
          url="https://www.zhihu.com/api/v4/search_v3?gk_version=gz-gaokao&t=$category"
          curlparams=(-G)
          curlparams+=(--data-urlencode "q=$3")
          curlparams+=(--data-urlencode 'correction=1')
          curlparams+=(--data-urlencode 'offset=0')
          curlparams+=(--data-urlencode 'limit=20')
          curlparams+=(--data-urlencode 'filter_fields=')
          curlparams+=(--data-urlencode 'lc_idx=0')
          curlparams+=(--data-urlencode 'show_all_topics=0')
          curlparams+=(--data-urlencode 'search_source=Normal')
          curlparams+=(-H 'cookie:_zap=56bdfcc3-c246-4680-8e57-a5473b751fb9;_xsrf=ffba990f-3a49-4e9b-b232-cab6496b2d4c;d_c0="AGDdL78gPxSPTkmCNGZifvEjgMhuR-HaOIc=|1640613826";_9755xjdesxxd_=32;YD00517437729195%3AWM_TID=hNCooIXAVRtAFQERAEZ%2BqRSZ6KxiyxVn;Hm_lvt_98beee57fd2ef70ccdd5ca52b9740c49=1666186862;SESSIONID=lIINZ3KHfbMwt2tjxmX2mMVDzbhcX2g9CmQQ0joNtGh;JOID=VlsdAkOQjG6Q5X5pEpcnM1QlW10K-84u17NKKVP66SjumEAac04FNPbucmsSbq2QOHOLDN6v4CTG6o7tfhZ0QkE=;osd=W1gXBEqdj2SW7HNqGJEuPlcvXVQH-MQo3r5JI1Xz5CvknkkXcEQDPfvteG0bY66aPnqGD9Sp6SnF4IjkcxV-REg=;__snaker__id=uv8MRYIw7Fv5KCpg;captcha_session_v2=2|1:0|10:1666878835|18:captcha_session_v2|88:d2taY0xjcU85TG50d1dBaVRVTkR6bU1zb1FkR1MyT0k4UUpTTUpxODlYTnNhWWREaWxjNml0U01qRk92TWp6Lw==|471ef29025ebe894da84eea7f4b7b93962ec65def721c79fc40b29d18cbbba15;YD00517437729195%3AWM_NI=NoF33ptg%2Bgy7L4j7DWexQa0Mu1ETlqe6gpjVWSI%2BoOl7mL%2BNlVHfssWKUEYrQx6fg5Hbk%2BqIlEP3UYSjDgtlk%2Fhg2d1%2F73wgd3M7thIQGBlGn0WOe18Je%2Fyr%2FLxao5%2FfRFU%3D;YD00517437729195%3AWM_NIKE=9ca17ae2e6ffcda170e2e6ee83b633edad9cd1c825b49e8aa6c55f878a8a87d86986a9aeb1d74f8aadff86ea2af0fea7c3b92a8eb18ad4b27cb8b9e588fc3d90eca6d8c75da7a89f82b347b7ef8bb5ef7ba7eaa991e95e958d87ccee45b0e9a3adaa46b08a8887f27995959ba6dc7a93a8fa87e63f8cbea5ccf443b09ba0d4d85391b68c88f768a9f1a888b170f3f1f9d4f66da8ed83d8f7648b8f89a3ef4daef099b0e83bfc96abd0fc7aed94b882ee3fedba9ea7d837e2a3;gdxidpyhxdE=8zWmSlJQ0Cfxz7fvITX0kTJt%2BLKgkc4Nlc1nkRJ9SdOTUI31NnbwoClGmggG%2FIVm%5Cdu9g0qavDl83BJ0u%2FYrEg%5CL%2FBEz%2Fc24EeueRuen59tNL%5C8gSeMGRQHRG1MCs4WolvT8atJEwmOlpP%2BOKI%2FelPD5UMk5HfHznbSDQT1LxZRu74%2BX%3A1667051401315;Hm_lpvt_98beee57fd2ef70ccdd5ca52b9740c49=1667050836;KLBRSID=d017ffedd50a8c265f0e648afe355952|1667050836|1667050636')
          curlparams+=(-H 'x-ab-pb:CsQBCAAbAD8ARwC0AGkBagF0ATsCzALXAtgCTwNQA6ADoQOiA7cD8wP0AzMEjASNBKYE1gQRBVEFiwWMBZ4FMAYxBusGJwd3B3gH2AfcB90HZwh0CHYIeQjaCD8JQglgCY0JwwnECcUJxgnHCcgJyQnKCcsJzAnRCfEJ9AkECkkKZQprCpgKpQqpCr4KxArUCt0K7Qr9Cv4KOws8C0MLRgtxC3YLhQuHC40LwAvXC+AL5QvmCywMOAxxDI8MrAy5DMMMyQz4DBJiAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAA=')
          curlparams+=(-H 'x-api-version:3.0.91')
          curlparams+=(-H 'x-app-za:OS=Web')
          curlparams+=(-H 'x-zse-93:101_3_3.0')
          curlparams+=(-H 'x-zse-96:2.0_GvwwUMkek8=4IKMpxb4X6Vrgz1NcrMLbce=W7rcoQC+TxG0p5vlhR8ariWgX8JxX')
          curlparams+=(-H 'x-zst-81:3_2.0aR_sn77yn6O92wOB8hPZnQr0EMYxc4f18wNBUgpTQ6nxERFZsRY0-4Lm-h3_tufIwJS8gcxTgJS_AuPZNcXCTwxI78YxEM20s4PGDwN8gGcYAupMWufIoLVqr4gxrRPOI0cY7HL8qun9g93mFukyigcmebS_FwOYPRP0E4rZUrN9DDom3hnynAUMnAVPF_PhaueTF03CcUeB0BgBf9LMwq3BggpKe8pmYUOLSbUfEUgKn9HLUrNMCvHLjwCOYcSTVMO9fG7C6qO_agXqAbSLSicLb_LmrbxLZBFqBUX0pCNVSBxLEwC9Fho1WbO_SqLq_UC0huOqkqY99cLZnwgC8rc8AucVwDe9mbXfoeoLkiNYrCH_kGO0Vg_z3bOVxwe_PcLZ3h9KfgYYSwYqQgeYUwS_cwLpcgXyfceMb0Vm9gSKrekV0UXY20c9gcOYeQH9Y7p1cqXqouCpuh3mZrLYzuN9sqV1o4XC8gNmwJxBorSs')
          jsonFormat='data:(标题)object.title|red|bold|index,(摘录)object.excerpt|red|bold,(结果类型)object.type|dim,(内容)object.content|white|dim,(作者)object.author.name|${data:object.author.name} https://www.zhihu.com/people/{.object.author.url_token}$,(时间)object.created_at|date,(链接)url|dim,(视频)object.video_url|dim,(图片)object.cover_url|image|dim'
        ;;
        问题回答|answer)
          local id=$3
          [[ $id = http* ]] && id=$(grep -o '/\d\+' <<< $id); id=${id#/}
          [[ $id ]] && url="https://www.zhihu.com/api/v4/questions/$id/feeds"
          [[ $3 = *cursor=* ]] && url=$3
          text=$(curl -s "$url")
          # text=$(cat zhihu.json)
          fields=('excerpt' 'title' 'voteup_count' 'created_time' 'url')
          patterns=(_ '"title":"[^"]*","type":"question"' _ _ '"url":"[^"]*","visible_only_to_author":')
          indexes=(4 4 3 3 4)
          filters=(_ _ :number: :number:timestamp: _)
          jsonFormat="data:(内容)target.excerpt|red|index(${INDEX_OFFSET:-0}),(问题)target.question.title|white|dim,(作者)target.author.name,(点赞数)target.voteup_count|number|magenta,(评论数)target.comment_count|number|magenta,(发布时间)target.created_time|date|dim,(链接)target.url|dim"

          next=$(echo -e $(escapeUnicode $(grep -oE '"next":"[^"]*"' <<< $text | cut -d'"' -f4)))
          [[ $next && ${SIZE:-10} > 0 ]] && tailer="INDEX_OFFSET=$((5 + ${INDEX_OFFSET:-0})) SIZE=$((${SIZE:-10} - 5)) json_res zhihu question '$next'"
        ;;
      esac
    ;;
    百度|baidu|bd) #
      outputfile="$outputfile.$2"
      case ${2:-hotsearch} in
        热搜|hotsearch|hs)
          url="https://top.baidu.com/board"
          outputfile="$outputfile.$3"
          case ${3:-realtime} in
            实时热搜|realtime|rt)
              url="$url?tab=realtime"
            ;;
            小说|novel|nv)
              url="$url?tab=novel"
              ask "全部类型 都市 玄幻 奇幻 历史 科幻 军事 游戏 武侠 现代言情 古代言情 幻想言情 青春" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            电影|movie|mv)
              url="$url?tab=movie"
              ask "全部类型 爱情 喜剧 动作 剧情 科幻 恐怖 动画 惊悚 犯罪" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国香港 中国台湾 欧美 日本 韩国" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            电视剧|teleplay|tv)
              url="$url?tab=teleplay"
              ask "全部类型 爱情 搞笑 悬疑 古装 犯罪 动作 恐怖 科幻 剧情 都市" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国台湾 中国香港 欧美 韩国 日本" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            汽车|car)
              url="$url?tab=car"
              ask "全部 轿车 SUV 新能源 跑车 MPV" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            游戏|game)
              url="$url?tab=game"
              ask "全部类型 手机游戏 网络游戏 单机游戏" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
          esac
          text=$(curl -s "$url" | grep -oE '<!--s-data:.*}-->' | sed -nE 's/<!--s-data:(.*)-->/\1/p')
          aliases=(关键词 描述 链接 图片)
          fields=(query desc rawUrl img)
          patterns=('_' '_' '_' '_')
          indexes=(4 4 4 4)
          jsonFormat='data.cards.0.content:(关键词)word|red|bold|index,(描述)desc|white|dim,(链接)rawUrl|dim,(图片)img|image'
        ;;
      esac
    ;;
    今日头条|toutiao|tt)
      fields=(title link)
      aliases=(标题 链接)
      case ${2:-hot} in
        热榜|hot|ht)
          url='https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc';
          patterns=('"Title":"[^"]*"' '"Url":"[^"]*"');
          indexes=(4 4)
          jsonFormat='data:(标题)Title|red|bold|index,(链接)Url|dim,(图片)Image.url_list*.url|image|dim'
        ;;
        热搜|hotsearch|hs)
          url='https://tsearch.snssdk.com/search/suggest/hot_words/';
          patterns=('"query":"[^"]*"' '"query":"[^"]*"');
          indexes=(4 4);
          transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title')
          jsonFormat='data:(标题)query|red|bold|index,(链接)query|$https://so.toutiao.com/search?dvpf=pc&source=trending_card&keyword={data:query}$|dim'
        ;;
      esac
    ;;
    哔哩哔哩|bilibili|bb)
      outputfile="$outputfile.$2"
      case $2 in
        热搜|resou) # 搜索框
          url='https://api.bilibili.com/x/web-interface/search/square'
          curlparams+=(--data-urlencode limit=30)
          curlparams+=(--data-urlencode platform=web)
          jsonFormat='data.trending.list|TABLE:(关键词)keyword,(链接)url|$https://search.bilibili.com/all?keyword={.keyword}&from_source=webtop_search$'
        ;;
        热搜|hotsearch) # 热搜 https://www.bilibili.com/blackboard/activity-trending-topic.html
          url='https://app.bilibili.com/x/v2/search/trending/ranking?limit=30'
          aliases=(关键词)
          fields=(show_name)
          indexes=(4)
          jsonFormat='data.list:(关键词)show_name'
        ;;
        搜索建议|searchsuggest) # 搜索建议
          url="https://s.search.bilibili.com/main/suggest?func=suggest&suggest_type=accurate&sub_type=tag&main_ver=v1&highlight=&userid=18358716&bangumi_acc_num=1&special_acc_num=1&topic_acc_num=1&upuser_acc_num=3&tag_num=10&special_num=10&bangumi_num=10&upuser_num=3&rnd=$(date +%s)"
          curlparams="-G --data-urlencode term={term}"
          local term=$(question '输入搜索词：' $3)
          curlparams=${curlparams//\{term\}/$term}
          aliases=(建议词)
          fields=(term)
          indexes=(4)
          jsonFormat='result.tag:(建议词)term'
        ;;
        搜索|search) # 搜索
          url='https://api.bilibili.com/x/web-interface/search/all/v2'
          curlparams+=(-b 'buvid3=oc;')
          curlparams+=(--data-urlencode __refresh__=true)
          curlparams+=(--data-urlencode page=${PAGE:-1})
          curlparams+=(--data-urlencode page_size=${SIZE:-42})
          curlparams+=(--data-urlencode platform=pc)
          jsonFormat='data.result|sort(key=data.result:result_type,sorts=(video,user)):(搜索结果类型)result_type,(结果列表)data|SIMPLE|+hr:(标题)title|red|tag|SIMPLE,(UP主)author,(标签)tag,(类型)typename,(链接)arcurl|SIMPLE,(图片)upic|image|dim'

          local keyword=$(question2 -q '搜索词' -i "$3")
          curlparams+=("--data-urlencode keyword=$keyword")

          local order=$(ask2 -q '排序' -1 -i "$4" -N 2 -A "最多点击 click 最新发布 pubdate 最多弹幕 dm 最多收藏 stow")
          [[ $order ]] && curlparams+=(--data-urlencode "order=$order")

          local time_from=$(question2 -q '起始时间，格式为：%Y%m%d')
          [[ $time_from ]] && curlparams+=(--data-urlencode "time_from=${time_from}")
          local time_to=$(question2 -q '起始时间，格式为：%Y%m%d')
          [[ $time_to ]] && curlparams+=(--data-urlencode "time_to=${time_to}")

          local search_types=(
            视频 video 'data.result:(标题)title|red|bold|index,(简介)description|white|dim,(分类)typename|magenta,(播放量)play|number,(点赞数)favorites|number,(收藏量)video_review|number,(弹幕数)danmaku|number,(UP主)author,(空间)mid|$https://space.bilibili.com/{data.result:mid}$|dim,(发布时间)pubdate|date,(链接)arcurl|dim,(图片)pic|image|dim'
            影视 media_ft 'data.result:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)styles|magenta,(地区)areas,(演职人员)staff,(媒体类型)season_type_name|magenta,(发布时间)pubdate|date,(链接)url|dim,(图片)cover|image|dim'
            番剧 media_bangumi 'data.result:(标题)title|red|bold|index,(分类)styles|magenta,(地区)areas,(简介)desc|white|dim,(演职人员)staff,(媒体类型)season_type_name|magenta,(发布时间)pubdate|date,(链接)url|dim,(图片)cover|image|dim'
            直播 live 'data.result:live_room:(标题)title|red|bold|index,(分类)cate_name|magenta,(标签)tag,(链接)url|dim,(图片)cover|image|dim;live_user:(UP主)uname,(分类)cate_name,(图片)cover|image|dim,(直播时间)live_time,(关注人数)attentions,(直播间)roomid|$https://live.bilibili.com/{data.result:live_user:roomid}$'
            专栏 article 'data.result:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)category_name,(浏览量)view|number,(链接)id|$https://www.bilibili.com/read/cv{data.result:id}$|dim,(发布时间)pubdate|date,(图片)image_urls|image|dim'
            话题 topic 'data.result:(标题)title|red|bold|index,(UP主)author,(空间)mid$https://space.bilibili.com/{data.result:mid}$|dim,(简介)description,(描述)description,(发布时间)pubdate|date,(链接)arcurl|dim,(图片)cover|image|dim'
            用户 bili_user 'data.result:(UP主)uname|red|bold|index,(官方认证)official_verify.desc,(简介)usign,(视频数)videos,(链接)mid|$https://space.bilibili.com/{data.result:mid}$|dim,(头像)upic,(作品)res:(标题)title,(链接)arcurl,(发布时间)pubdate|date'
          )
          ask2 -s -q '类型' -i "$5" -1 -N 3 -S '0 1' -A "${search_types[*]}"
          local search_type=$_ASK_RESULT
          if [[ $search_type ]]; then
            curlparams+=(--data-urlencode "search_type=$search_type")
            jsonFormat=${_ASK_RESULTS[@]:2:1}
          fi
          if [[ $order || $search_type ]]; then
            url='https://api.bilibili.com/x/web-interface/search/type'
          fi
        ;;
        用户投稿|upload) # 用户投稿
          url="https://api.bilibili.com/x/space/arc/search?mid={upid}&pn={PAGE}&ps={SIZE}&index=1&order={order}&order_avoided=true&jsonp=jsonp"
          # 482324117, 在美国的福建人, https://space.bilibili.com/482324117
          local upid=$(question '请输入用户ID、名称或主页链接：' $3)
          if [[ "$upid" = https://space.bilibili.com* ]]; then
            upid=$(sed -n 's/.*\/\([0-9]\+\)\(?\|\/\).*/\1/p' <<<$upid)
          elif [[ ! $upid =~ ^[0-9]+$ ]]; then
            upid=$(RAW=1 json_res bilibili search "$upid" 0 用户 | grep -oE '"mid":\d+' | cut -d: -f2 | head -1)
          fi

          url=${url//\{upid\}/$upid}

          debug $upid

          _ASK_MSG='如果不需要排序，直接回车；请输入排序：' ask "最新发布 最多播放 最多收藏" $4
          local orders=(pubdate click stow)
          local order=${orders[@]:$_ASK_INDEX:1}
          url=${url//\{order\}/$order}
          url=${url//\{PAGE\}/${PAGE:-1}}
          url=${url//\{SIZE\}/${SIZE:-25}}
          jsonFormat='data.list.vlist:(标题)title|red|bold|index,(简介)description|white|dim,(播放量)play|number,(弹幕数)video_review,(评论数)comment|number,(发布时间)created|date(format=md)|magenta,(链接)bvid|$https://www.bilibili.com/video/{data.list.vlist:bvid}$|white|dim,(图片)pic|image|white|dim'
        ;;
        综合热门|hot) # 综合热门 https://www.bilibili.com/v/popular/all
          url="https://api.bilibili.com/x/web-interface/popular?ps=${SIZE:-20}&pn=${PAGE:-1}"
          jsonFormat='data.list:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim,(图片)pic|image|dim'
        ;;
        每周必看|week) # 每周必看 https://www.bilibili.com/v/popular/weekly
          local week=$3
          if [[ $week = 0 ]]; then
            week=`RAW=1 json_res bilibili weeklist | grep -oE '"number":[^,]*,' | head -1 | grep -oE '\d+'`
          elif [[ -z $week ]]; then
            json_res bilibili weeklist
            read -p '输入周编号:' week
            echo -e "第\033[32m$week\033[0m周"
          fi
          url="https://api.bilibili.com/x/web-interface/popular/series/one?number=$week"
        ;;
        周列表|weeklist) # 周列表 https://www.bilibili.com/v/popular/weekly
          url='https://api.bilibili.com/x/web-interface/popular/series/list'
          aliases=(主题 编号 名称)
          fields=(subject number name)
          patterns=(_ '"number":[^,]*,' _)
          indexes=(4 3 4)
          transformers=(_ '\\033[0m第\\033[31m${values[@]:1:1}\\033[0m周' _)
          filters=(_ :number: _)
          jsonFormat=''
        ;;
        入站必刷|precious) # 入站必刷 https://www.bilibili.com/v/popular/history
          url="https://api.bilibili.com/x/web-interface/popular/precious?page_size=${SIZE:-100}&page=${PAGE:-1}"
          jsonFormat='data.list:(标题)title|red|bold|index,(简介)desc|white|dim,(成就)achievement|magenta,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim,(图片)pic|image|dim'
        ;;
        全站音乐榜) # 全站音乐榜 https://www.bilibili.com/v/popular/music
          local week=$3
          if [[ $week = 0 ]]; then
            week=`RAW=1 json_res bilibili musicweeklist | grep -oE '"number":[^,]*,' | head -1 | grep -oE '\d+'`
          elif [[ -z $week ]]; then
            json_res bilibili wkl
            read -p '输入周编号:' week
            echo -e "第\033[32m$week\033[0m周"
          fi
          url="https://api.bilibili.com/x/copyright-music-publicity/toplist/music_list?list_id=$week"
        ;;
        音乐周列表|musicweeklist) # 音乐周列表 https://www.bilibili.com/v/popular/music
          url='https://api.bilibili.com/x/copyright-music-publicity/toplist/all_period?list_type=1'
          aliases=(编号 发布时间)
          fields=(period publish_time)
          patterns=(_ _)
          filters=(:number: :number:timestamp:)
          indexes=(3 3)
          transformers=('\\033[0m第\\033[31m${values[@]:1:1}\\033[0m期' _)
          jsonFormat=''
        ;;
        稿件详情|detail)
          url='https://api.bilibili.com/x/web-interface/view'
          curlparams+=(--data-urlencode aid=733261579)
        ;;
        用户空间|space)
          outputfile="$outputfile.$3"
          local old_cookie=$(store -g bilibili.cookie)
          local cookie=$(question2 -q 'cookie')
          [[ $cookie ]] && store -s bilibili.cookie "$cookie" || cookie=$old_cookie
          curlparams+=(-b "$cookie")
          # 频道
          local channels=(
            # route                                       tid name
            anime                                         13  番剧
            anime-serial                                  33  连载动画
            anime-finish                                  32  完结动画
            anime-information                             51  资讯
            anime-offical                                 152 官方延伸
            anime-timeline                                _   新番时间表
            anime-index                                   _   番剧索引

            movie                                         23  电影

            guochuang                                     167 国创
            guochuang-chinese                             153 国产动画
            guochuang-original                            168 国产原创相关
            guochuang-puppetry                            169 布袋戏
            guochuang-motioncomic                         195 动态漫·广播剧
            guochuang-information                         170 资讯
            guochuang-timeline                            _   新番时间表
            guochuang-index                               _   国产动画索引

            tv                                            11  电视剧

            variety                                       _   综艺

            documentary                                   177 纪录片

            douga                                         1   动画
            douga-mad                                     24  MAD·AMV
            douga-mmd                                     25  MMD·3D
            douga-voice                                   47  短片·手书·配音
            douga-garage_kit                              210 手办·模玩
            douga-tokusatsu                               86  特摄
            douga-acgntalks                               253 动漫杂谈
            douga-other                                   27  综合

            game                                          4   游戏
            game-stand_alone                              17  单机游戏
            game-esports                                  171 电子竞技
            game-mobile                                   172 手机游戏
            game-online                                   65  网络游戏
            game-board                                    173 桌游棋牌
            game-gmv                                      121 GMV
            game-music                                    136 音游
            game-mugen                                    19  Mugen
            game-match                                    _   游戏赛事

            kichiku                                       119 鬼畜
            kichiku-guide                                 22  鬼畜调教
            kichiku-mad                                   26  音MAD
            kichiku-manual_vocaloid                       126 人力VOCALOID
            kichiku-theatre                               216 鬼畜剧场
            kichiku-course                                127 教程演示

            music                                         3   音乐
            music-original                                28  原创音乐
            music-cover                                   31  翻唱
            music-perform                                 59  演奏
            music-vocaloid                                30  VOCALOID·UTAU
            music-live                                    29  音乐现场
            music-mv                                      193 MV
            music-commentary                              243 乐评盘点
            music-tutorial                                244 音乐教学
            music-other                                   130 音乐综合
            rap                                           _   说唱

            dance                                         129 舞蹈
            dance-otaku                                   20  宅舞
            dance-hiphop                                  198 街舞
            dance-star                                    199 明星舞蹈
            dance-china                                   200 中国舞
            dance-three_d                                 154 舞蹈综合
            dance-demo                                    156 舞蹈教程

            cinephile                                     181 影视
            cinephile-cinecism                            182 影视杂谈
            cinephile-montage                             183 影视剪辑
            cinephile-shortfilm                           85  小剧场
            cinephile-trailer_info                        184 预告·资讯

            ent                                           5   娱乐
            ent-variety                                   71  综艺
            ent-talker                                    241 娱乐杂谈
            ent-fans                                      242 粉丝创作
            ent-celebrity                                 137 明星综合

            knowledge                                     36  知识
            knowledge-science                             201 科学科普
            knowledge-social_science                      124 社科·法律·心理
            knowledge-humanity_history                    228 人文历史
            knowledge-business                            207 财经商业
            knowledge-campus                              208 校园学习
            knowledge-career                              209 职业职场
            knowledge-design                              229 设计·创意
            knowledge-skill                               122 野生技能协会

            tech                                          188 科技
            tech-digital                                  95  数码
            tech-application                              230 软件应用
            tech-computer_tech                            231 计算机技术
            tech-industry                                 232 科工机械
            tech-diy                                      _   极客DIY

            information                                   202 资讯
            information-hotspot                           203 热点
            information-global                            204 环球
            information-social                            205 社会
            information-multiple                          206 综合

            food                                          211 美食
            food-make                                     76  美食制作
            food-detective                                212 美食侦探
            food-measurement                              213 美食测评
            food-rural                                    214 田园美食
            food-record                                   215 美食记录

            life                                          160 生活
            life-funny                                    138 搞笑
            life-parenting                                254 亲子
            life-travel                                   250 出行
            life-rurallife                                251 三农
            life-home                                     239 家居房产
            life-handmake                                 161 手工
            life-painting                                 162 绘画
            life-daily                                    21  日常

            car                                           223 汽车
            car-racing                                    245 赛车
            car-modifiedvehicle                           246 改装玩车
            car-newenergyvehicle                          246 新能源车
            car-touringcar                                248 房车
            car-motorcycle                                240 摩托车
            car-strategy                                  227 购车攻略
            car-life                                      176 汽车生活

            fashion                                       155 时尚
            fashion-makeup                                157 美妆护肤
            fashion-cos                                   252 仿妆cos
            fashion-clothing                              158 穿搭
            fashion-trend                                 159 时尚潮流

            sports                                        234 运动
            sports-basketball                             235 篮球
            sports-football                               249 足球
            sports-aerobics                               164 健身
            sports-athletic                               236 竞技体育
            sports-culture                                237 运动文化
            sports-comprehensive                          238 运动综合

            animal                                        217 动物圈
            animal-cat                                    218 喵星人
            animal-dog                                    219 汪星人
            animal-reptiles                               222 小宠异宠
            animal-wild_animal                            221 野生动物
            animal-second_edition                         220 动物二创
            animal-animal_composite                       75  动物综合

            # life-daily                                    _   VLOG

            # virtual                                       _   虚拟UP主

            # _                                             _   公益

            # mooc                                          _   公开课
          )
          case $3 in
            观看历史|history)
              local type=$(ask2 -q '内容类型' -i "$4" -d 0 -N 2 -1 -A '视频 archive 直播 live 专栏 article')
              url='https://api.bilibili.com/x/web-interface/history/cursor'
              curlparams+=(--data-urlencode type=archive)
              curlparams+=(--data-urlencode ps=${SIZE:-20})
              jsonFormat='data.list|TABLE:(id)id,(标题)title|red,(标签)tag_name,(作者)author_name,(作者主页)author_url|$https://space.bilibili.com/{.author_mid}/$|HIDE_IN_TABLE,(观看时间)view_at(date),(链接)url$https://www.bilibili.com/medialist/detail/ml{.id}$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            收藏夹|folder)
              local up_mid=$(question2 -i "$4" -q '用户ID')
              url='https://api.bilibili.com/x/v3/fav/folder/created/list'
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode ps=${SIZE:-20})
              curlparams+=(--data-urlencode up_mid=$up_mid)
              curlparams+=(--data-urlencode jsonp=jsonp)
              # curlparams+=(-H "referer:https://space.bilibili.com/$up_mid")
              jsonFormat='data.list|TABLE:(id)id,(名称)title|red,(数量)media_count,(创建时间)ctime(date),(更新时间)mtime(date),(链接)url$https://www.bilibili.com/medialist/detail/ml{.id}$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            订阅列表|collected)
              local up_mid=$(question2 -i "$4" -q '用户ID')
              url='https://api.bilibili.com/x/v3/fav/folder/collected/list'
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode ps=${SIZE:-20})
              curlparams+=(--data-urlencode up_mid=$up_mid)
              curlparams+=(--data-urlencode platform=web)
              curlparams+=(--data-urlencode jsonp=jsonp)
              # curlparams+=(-H "referer:https://space.bilibili.com/$up_mid/favlist")
              jsonFormat='data.list|TABLE:(id)id,(标题)title|red,(简介)intro|HIDE_IN_TABLE,(作者)upper.name,(作者主页)author_url|$https://space.bilibili.com/{.upper.name}/$|HIDE_IN_TABLE,(链接)url$https://www.bilibili.com/medialist/detail/ml{.id}$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            收藏夹内容|resource)
              local folder_id=$(question2 -i "$4" -q '收藏夹ID')
              url='https://api.bilibili.com/x/v3/fav/resource/list'
              curlparams+=(--data-urlencode media_id=$folder_id)
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode ps=${SIZE:-20})
              curlparams+=(--data-urlencode keyword=)
              curlparams+=(--data-urlencode order=mtime)
              curlparams+=(--data-urlencode type=0)
              curlparams+=(--data-urlencode tid=0)
              curlparams+=(--data-urlencode platform=web)
              curlparams+=(--data-urlencode jsonp=jsonp)
              jsonFormat='data.medias|TABLE:(id)id|HIDE_IN_TABLE,(标题)title|red,(收藏时间)fav_time|date,(简介)intro|HIDE_IN_TABLE,(链接)url|https://www.bilibili.com/video/${.bvid}/$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            订阅项内容|season)
              local season_id=$(question2 -i "$4" -q '订阅项ID')
              url='https://api.bilibili.com/x/space/fav/season/list'
              curlparams+=(--data-urlencode season_id=$season_id)
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode ps=${SIZE:-20})
              curlparams+=(--data-urlencode jsonp=jsonp)
              jsonFormat='data.medias|TABLE:(id)id|HIDE_IN_TABLE,(标题)title|red,(发布时间)pubtime|date,(链接)url|$https://www.bilibili.com/video/${.bvid}/$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            追番列表|follow)
              url='https://api.bilibili.com/x/space/bangumi/follow/list'
              curlparams+=(--data-urlencode vmid=$up_mid)
              curlparams+=(--data-urlencode type=1)
              curlparams+=(--data-urlencode jsonp=jsonp)
              jsonFormat='data.list:'
            ;;
            人气漫画|hotmanga)
              url='https://manga.bilibili.com/twirp/comic.v1.Comic/GetRecommendComics'
              jsonFormat='data|TABLE:(标题)title|red,(标签)styles*.name,(链接)url|$https://manga.bilibili.com/detail/mc{.comic_id}$,(封面)vertical_cover|image|dim|HIDE_IN_TABLE'
            ;;
            推荐漫画|manga) # https://www.bilibili.com/
              url='https://manga.bilibili.com/twirp/comic.v1.Comic/HomeHot'
              curlparams+=(--data-urlencode device=pc)
              curlparams+=(--data-urlencode platform=web)
              jsonFormat='data|TABLE:(标题)title|red,(标签)styles*.name,(作者)author*,(链接)url|$https://manga.bilibili.com/detail/mc{.comic_id}$,(封面)vertical_cover|image|dim|HIDE_IN_TABLE'
            ;;
            公开课|mooc)
              local classifications=(学科课程 1 硬核技能 2 考试考证 3)
              local orders=(最新发布 1 播放最多 2)
              local classification=$(ask2 -q '分类' -i "$4" -d 0 -1 -N 2 -A "${classifications[*]}")
              local order=$(ask2 -q '排序方式' -i "$5" -d 0 -1 -N 2 -A "${orders[*]}")
              url='https://api.bilibili.com/x/open-course/course'
              curlparams+=(--data-urlencode ps=${SIZE:-12})
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode classification=$classification)
              curlparams+=(--data-urlencode sort=$order)
              jsonFormat='data.course|TABLE:(课程)course_name|red,(分类)category_name,(作者)nickname,(播放量)view|number(cn),(链接)url|$https://www.bilibili.com/video/{.bvid}$,(封面)cover|image|dim|HIDE_IN_TABLE'
            ;;
            热门排行榜|ranking) # 排行榜 https://www.bilibili.com/v/popular/rank
              # VueComponent: [index.js]PgcRankList
              local season_types=(
                # slug                 tid   season_type rank_type      name
                all                  0     _           _              全站
                bangumi              13    1           _              番剧
                guochan              168   4           _              国产动画
                guochuang            168   _           _              国创相关
                documentary          177   3           _              纪录片
                douga                1     _           _              动画
                music                3     _           _              音乐
                dance                129   _           _              舞蹈
                game                 4     _           _              游戏
                knowledge            36    _           _              知识
                tech                 188   _           _              科技
                sports               234   _           _              运动
                car                  223   _           _              汽车
                life                 160   _           _              生活
                food                 211   _           _              美食
                animal               217   _           _              动物圈
                kichiku              119   _           _              鬼畜
                fashion              155   _           _              时尚
                ent                  5     _           _              娱乐
                cinephile            181   _           _              影视
                movie                23    2           _              电影
                tv                   11    5           _              电视剧
                variety              _     7           _              综艺
                origin               0     _           origin         原创
                rookie               0     _           rookie         新人
              )
              ask2 -s -q '类型' -1 -i "$4" -d 0 -N 5 -S '-1' -A "${season_types[*]}"
              local tid=${_ASK_RESULT}
              local season_type=${_ASK_RESULTS[@]:2:1}
              local rank_type=${_ASK_RESULTS[@]:3:1}
              if [[ ! $season_type = '_' ]]; then
                [[ $season_type = 1 ]] && url='https://api.bilibili.com/pgc/web/rank/list' || url='https://api.bilibili.com/pgc/season/rank/web/list'
                curlparams+=(--data-urlencode day=3)
                curlparams+=(--data-urlencode season_type=$season_type)
                jsonFormat='result.list|TABLE:(标题)title|red|bold|index,(徽标)badge|magenta,(更新状态)new_ep.index_show,(评分)rating|magenta,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(追番数)stat.follow|number,(总追番数)stat.series_follow|number,(链接)url|HIDE_IN_TABLE,(图片)cover|image|dim|HIDE_IN_TABLE'
              else
                url='https://api.bilibili.com/x/web-interface/ranking/v2'
                curlparams+=(--data-urlencode rid=$rid)
                [[ $rank_type = '_' ]] && rank_type=all
                curlparams+=(--data-urlencode type=$rank_type)
                jsonFormat='data.list|TABLE:(标题)title|red|bold|index,(简介)desc|white|dim|HIDE_IN_TABLE,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim|HIDE_IN_TABLE,(图片)pic|image|dim|HIDE_IN_TABLE'
              fi
            ;;
            首页推流|feed) # 首页推流 https://www.bilibili.com/
              local index=$(question2 -a '页面' -i "$4")
              local fresh_idx_1h=$index
              local fetch_row=$(($index * 3 + 1))
              local fresh_idx=$index
              local brush=$index
              url='https://api.bilibili.com/x/web-interface/index/top/feed/rcmd'
              curlparams+=(--data-urlencode y_num=5)
              curlparams+=(--data-urlencode fresh_type=4)
              curlparams+=(--data-urlencode feed_version=V11) # window.__SERVER_CONFIG__.for_ai_home_version
              curlparams+=(--data-urlencode fresh_idx_1h=$fresh_idx_1h)
              curlparams+=(--data-urlencode fetch_row=$fetch_row)
              curlparams+=(--data-urlencode fresh_idx=$fresh_idx)
              curlparams+=(--data-urlencode brush=$brush)
              curlparams+=(--data-urlencode homepage_ver=1)
              curlparams+=(--data-urlencode ps=${SIZE:-15})
              curlparams+=(--data-urlencode outside_trigger=)
              jsonFormat='item|TABLE:(标题)title|red,(播放量)stat.view|number(cn),(弹幕数)stat.danmaku|number(cn),(链接)url|dim,(作者)owner.name,(链接)url|$https://www.bilibili.com/video/{.bvid}/$|dim,(封面)pic|image|dim|HIDE_IN_TABLE'
            ;;
            频道动态|channel) # 首页频道动态 https://www.bilibili.com/
              local channel=$(ask2 -q '类型'  -1 -i "$4" -d 0 -N 3 -S '-2 -1' -A "${channels[*]}")
              url='https://api.bilibili.com/x/web-interface/dynamic/region'
              curlparams+=(--data-urlencode ps=12)
              curlparams+=(--data-urlencode pn=1)
              curlparams+=(--data-urlencode rid=$channel)
              jsonFormat='[item,data.archives]|TABLE:(标题)title|red,(播放量)stat.view|number(cn),(弹幕数)stat.danmaku|number(cn),(链接)url|dim,(作者)owner.name,(链接)url|$https://www.bilibili.com/video/{.bvid}/$|dim,(封面)pic|image|dim|HIDE_IN_TABLE'
            ;;
            频道排行榜|channelranking) # 首页频道侧边栏排行榜 https://www.bilibili.com/
              # VueComponent: [index.js]VideoRankList
              local channel=$(ask2 -q '类型' -2 -i "$4" -d 0 -N 3 -S '0' -A "${channels[*]}")
              local day=$(question2 -q '统计天数' -i "$5" -d 3)
              url='https://api.bilibili.com/x/web-interface/ranking/region'
              curlparams+=(--data-urlencode day=$day)
              curlparams+=(--data-urlencode original=0)
              curlparams+=(--data-urlencode rid=$channel)
              jsonFormat='data|TABLE:(标题)title|red,(分类)typename,(简介)description|HIDE_IN_TABLE,(播放量)play|number(cn),(弹幕数)video_review|number(cn)|HIDE_IN_TABLE,(收藏量)favorites|number(cn)|HIDE_IN_TABLE,(作者)author,(链接)url|$https://www.bilibili.com/video/{.bvid}/$|dim,(封面)pic|image|dim|HIDE_IN_TABLE'
            ;;
            标签|tag) # 频道下的标签 https://www.bilibili.com/v/life/daily/?tag=66605
              url='https://api.bilibili.com/x/web-interface/dynamic/tag'
              curlparams+=(--data-urlencode ps=${SIZE:-14})
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode rid=21)
              curlparams+=(--data-urlencode tag_id=66605)
            ;;
            标签排行榜|tagranking) # 标签下的排行榜 https://www.bilibili.com/v/life/daily/?tag=66605
              url='https://api.bilibili.com/x/web-interface/ranking/tag'
              curlparams+=(--data-urlencode tag_id=66605)
              curlparams+=(--data-urlencode rid=21)
            ;;
            热门标签|hottag) # 频道热门标签 https://www.bilibili.com/v/life/daily/?tag=66605
              url='http://api.bilibili.com/x/tag/hots'
              curlparams+=(--data-urlencode rid=21)
              curlparams+=(--data-urlencode type=0)
              jsonFormat='tags|TABLE:(标签)tag_name|red,(id)tag_id|dim'
            ;;
            最新列表|newlist) # 标签下的最新列表 https://www.bilibili.com/v/life/daily/?tag=66605
              url='https://api.bilibili.com/x/web-interface/newlist'
              curlparams+=(--data-urlencode rid=21)
              curlparams+=(--data-urlencode type=0)
              curlparams+=(--data-urlencode ps=${SIZE:-30})
              curlparams+=(--data-urlencode pn=${PAGE:-1})
            ;;
          esac
        ;;
      esac
    ;;
    # sogou
    搜狗|sogou|sg)
      outputfile="$outputfile.$2"
      case ${2:-hotsearch} in
        热搜|hotsearch|hs) # https://ie.sogou.com/top/
          url="https://go.ie.sogou.com/hot_ranks?callback=jQuery112403809296729897269_1666168486497&h=0&r=0&v=0&_=$(date +%s)"
          text=$(curl -s "$url" | grep -oE '{.*}')
          aliases=(标题 热度 链接)
          fields=(title num id)
          patterns=(_ '"num":[^,]*,' _)
          indexes=(4 3 4)
          transformers=(_ _ 'https://www.sogou.com/sie?query=${values[@]:0:1}')
          jsonFormat='data:(标题)attributes.title|red|bold|index,(热度)attributes.num|number,(链接)id|$https://www.sogou.com/sie?query={data:attributes.title}$'
        ;;
      esac
    ;;
    # sina
    新浪|sina)
      outputfile="$outputfile.$2"
      case ${2:-rank} in
        排行榜|rank) # https://news.sina.com.cn/hotnews/
          # （历史）首页 http://news.sina.com.cn/head/news20221020am.shtml
          # console.log([...document.querySelectorAll('.loopblk')].reduce((v, e) => {
          #   let name=e.querySelector('h2').textContent
          #   let tabs=[...e.querySelectorAll('.Tabs li')]
          #   let urls=[...e.querySelectorAll('.Cons tbody script[src]')]
          #   tabs.forEach((tab, i) => {
          #       v.push({name: [name, tab.textContent.trim()].join('-'), url: urls[i].src.match(/top_cat=([^&]*)/)[1]})
          #   })
          #   return v
          # }, []).map(e => [e.name, e.url].join(' ')).join('\n'))
          local categories=(
            新闻总排行-点击量排行 www_www_all_suda_suda
            新闻总排行-评论数排行 qbpdpl
            新闻总排行-分享数排行 total_sharenews_48h
            新闻总排行-视频排行 video_news_all_by_vv
            新闻总排行-图片排行 total_slide_suda
            国内新闻-点击量排行 news_china_suda
            国内新闻-评论数排行 gnxwpl
            国内新闻-分享数排行 wbrmzfgnxw
            国际新闻-点击量排行 news_world_suda
            国际新闻-评论数排行 gjxwpl
            国际新闻-分享数排行 wbrmzfgwxw
            社会新闻-点击量排行 news_society_suda
            社会新闻-评论数排行 shxwpl
            社会新闻-分享数排行 wbrmzfshxw
            体育新闻-点击量排行 sports_suda
            体育新闻-评论数排行 tyxwpl
            体育新闻-分享数排行 wbrmzfty
            财经新闻-点击量排行 finance_0_suda
            财经新闻-评论数排行 cjxwpl
            财经新闻-分享数排行 wbrmzfcj
            娱乐新闻-点击量排行 ent_suda
            娱乐新闻-评论数排行 ylxwpl
            娱乐新闻-分享数排行 wbrmzfyl
            科技新闻-点击量排行 tech_news_suda
            科技新闻-评论数排行 kjxwpl
            科技新闻-分享数排行 wbrmzfkj
            军事新闻-点击量排行 news_mil_suda
            军事新闻-评论数排行 jsxwpl
            军事新闻-分享数排行 wbrmzfjsxw
          )
          local category=$(ask2 -q '分类' -d 0  -i "$3" -A "${categories[*]}" -N 2 -1)
          category=${categories[@]:$((_ASK_INDEX * 2 + 1)):1}
          outputfile="$outputfile.$category"

          local type=$(ask2 -q "排行榜类型" -d 0  -i "$4" -A '日排行榜 day 周排行榜 week' -N 2 -1)
          outputfile="$outputfile.$type"

          local date=$(question2 -q "排行榜时间" -d "$_today2" -i "$5")

          url='https://top.news.sina.com.cn/ws/GetTopDataList.php'
          curlparams+=(--data-urlencode top_type=$type)
          curlparams+=(--data-urlencode top_cat=$category)
          curlparams+=(--data-urlencode top_time=$date)
          curlparams+=(--data-urlencode top_show_num=${SIZE:-100})
          curlparams+=(--data-urlencode top_order=DESC)
          curlparams+=(--data-urlencode js_var=channel_)

          text=$(curl -s "$url" "${curlparams[@]}" | grep -o '{.*}')
          aliases=(标题 媒体 链接)
          fields=(title media url)
          patterns=(_ _ _)
          indexes=(4 4 4)
          jsonFormat='data:(标题)title|red|bold|index,(媒体)media|cyan,(链接)url|dim,(时间)time|date|dim'
        ;;
        滚动新闻|roll) # https://news.sina.com.cn/roll
          url="https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid=2509&k=&num=50&page=1&r=$(date +%s)&callback=jQuery111205718232756906676_$(date +%s)&_=$(date +%s)"
          text=$(curl -s "$url" | grep -o '({.*})' | sed -n 's/^.//;s/.$//;p' | tr -d '\n')
          aliases=(标题 简介 媒体 链接)
          fields=(title intro media_name url)
          patterns=(_ _ _ _)
          indexes=(4 4 4 4)
          jsonFormat='result.data:(标题)title|red|bold|index,(简介)intro|white|dim,(媒体)media_name|cyan|dim,(链接)url|dim,(时间)ctime|date|dim,(图片)images*.u|dim'
        ;;
        热榜|hot) # https://sinanews.sina.cn/h5/top_news_list.d.html
          local categories=(top trend ent video baby car fashion trip)
          local category=$(indexof "$3" "${categories[*]}")
          ask "新浪热榜 潮流热榜 娱乐热榜 视频热榜 汽车热榜 育儿热榜 时尚热榜 旅游热榜" $category
          category=${categories[@]:$((_ASK_INDEX)):1}
          outputfile="$outputfile.$category"
          case ${category:-top} in
            新浪热榜|top)
              url='https://sinanews.sina.cn/h5/top_news_list.d.html'
              text=$(curl -s $url | grep -oE '<script>SM = {.*};</script>' | sed 's/<script>SM = //;s/;<\/script>//;')
              jsonFormat='data.data.result:(标题)text|red|bold|index,(分类)queryClass|magenta,(热度)hotValue,(链接)link|dim,(图片)imgUrl|image|dim'
            ;;
            潮流热榜|trend)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-trend&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.hotValue,(图片)info.pic*.url|image|dim,(链接)base.base.url|dim'
            ;;
            娱乐热榜|ent)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-ent&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag|dim,(热度)info.hotValue|dim,(图片)info.pic*.url|image|dim,(链接)base.base.url|dim'
            ;;
            视频热榜|video)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-minivideo&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.intro|dim,(媒体)media_info.name|dim,(视频)stream:(链接)playUrl|dim,(清晰度)definitionType|dim'
            ;;
            汽车热榜|car)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-auto&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag|dim,(热度)info.hotValue|dim,(链接)base.base.url|dim'
            ;;
            育儿热榜|baby)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-mother&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag|dim,(热度)info.hotValue|dim,(链接)base.base.url|dim'
            ;;
            时尚热榜|fashion)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-fashion&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag|dim,(热度)info.hotValue|dim,(链接)base.base.url|dim'
            ;;
            旅游热榜|trip)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-travel&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag|dim,(热度)info.hotValue|dim,(链接)base.base.url|dim'
            ;;
          esac
        ;;
      esac
    ;;
    # eastmoney
    东方财富|eastmoney|em)
      outputfile=$outputfile.$2
      local columns=(
        f2 Close 最新价（元）,
        f3 ChangePercent 涨跌幅（%）,
        f4 Change 涨跌额（元）,
        f5 Volume 成交量（手）,
        f6 Amount 成交额（元）,
        f7 Amplitude 振幅（%）,
        f8 TurnoverRate 换手率（%）,
        f9 PERation 市盈率（动态）,
        f10 VolumeRate 量比,
        f11 FiveMinuteChangePercent 5分钟涨跌（%）,
        f12 Code 证券代码,
        f13 MarketId 市场编号,
        f14 Name 证券名称,
        f15 Hign 最高价（元）,
        f16 Low 最低价（元）,
        f17 Open 开盘价（元）,
        f18 PreviousClose 昨天收盘价（元）,
        f20 MarketValue 总市值（元）,
        f21 FlowCapitalValue 流通市值（元）,
        f22 Speed 涨速（%）,
        f23 PB 市净率,
        f24 ChangePercent60Day 60日涨跌幅（%）,
        f25 ChangePercent360Day 年初至今涨跌幅（%）,
        f26 shtime 上市时间,
        f62 主力净流入,
        f115 PERation 市盈率,
        # 其他
        f104 上涨家数,
        f105 下跌家数,
        f106 平盘家数,
        f128 领涨股票,
        f28 PreviousClose 昨结,
        f30 Change 现量,
        f31 Change 买入价,
        f32 Change 卖出价,
        f108 持仓量,
        f163 Amount 日增,
        f211 buycount 买量,
        f212 sellcount 卖量,
        f136 涨跌幅（%）,
      )
      local markets=(
        # http://quote.eastmoney.com/center/gridlist.html
        A股 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:0+t:81+s:2048'
        上证A股 'm:1+t:2,m:1+t:23'
        深证A股 'm:0+t:6,m:0+t:80'
        北证A股 'm:0+t:81+s:2048'
        新股 'm:0+f:8,m:1+f:8'
        中小板 'm:0+t:13'
        创业板 'm:0+t:80'
        创业板-注册制 'm:0+t:80+s:131072'
        创业板-核准制 'm:0+t:80+s:!131072'
        科创板 'm:1+t:23'
        北向通 'b:BK0707,b:BK0804'
        北向通-沪股通 'b:BK0707'
        北向通-深股通 'b:BK0804'
        风险警示板 'm:0+f:4,m:1+f:4'
        风险警示板-上证 'm:1+f:4'
        风险警示板-深证 'm:0+f:4'
        风险警示板-科创板 'm:1+t:23+f:4'
        风险警示板-创业板 'm:0+t:80+f:4'
        两网及退市 'm:0+s:3'
        新三板 'm:0+t:81+s:!2052'
        新三板-精选层 'm:0+t:81+s:2048'
        新三板-创新层 'm:0+s:512'
        新三板-基础层 'm:0+s:256'
        # http://quote.eastmoney.com/center/hszs.html
        指数-中证系列指数 'm:2'
        指数-指数成分 'm:1+s:3,m:0+t:5'
        指数-深证系列指数 'm:0+t:5'
        指数-上证系列指数 'm:1+s:2'
        # http://quote.eastmoney.com/center/boardlist.html
        板块-概念板块 'm:90+t:3+f:!50'
        板块-地域板块 'm:90+t:1+f:!50'
        板块-行业板块 'm:90+t:2+f:!50'

        港股 'm:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2'
        港股-主板 'm:128+t:3'
        港股-创业板 'm:128+t:4'
        港股-知名港股 'b:DLMK0106'
        港股-港股通 'b:DLMK0146,b:DLMK0144'
        港股-蓝筹股 'b:MK0104'
        港股-红筹股 'b:MK0102'
        港股-红筹指数成分股 'b:MK0111'
        港股-国企股 'b:MK0103'
        港股-国企指数成分股 'b:MK0112'
        港股-港股通成份股 'b:MK0146,b:MK0144'
        港股-ADR 'm:116+s:1'
        港股-香港指数 'm:124,m:125,m:305'
        港股-香港涡轮 'm:116+t:6'
        港股-港股通ETF 'b:MK0837,b:MK0838'
        港股-港股通ETF-沪 'b:MK0838'
        港股-港股通ETF-深 'b:MK0837'
        港股-港股牛熊证 'm:116+t:5'

        美股 'm:105,m:106,m:107'
        美股-中国概念股 'b:MK0201'
        美股-美股指数 'i:100.NDX,i:100.DJIA,i:100.SPX'
        美股-粉单市场 'm:153'
        美股-知名美股 'b:MK0001'
        美股-知名美股-科技类 'b:MK0216'
        美股-知名美股-金融类 'b:MK0217'
        美股-知名美股-医药食品类 'b:MK0218'
        美股-知名美股-媒体类 'b:MK0220'
        美股-知名美股-汽车能源类 'b:MK0219'
        美股-知名美股-制造零售类 'b:MK0221'
        美股-互联网中国 'b:MK0202'

        全球指数-亚洲股市 'i:1.000001,i:0.399001,i:0.399005,i:0.399006,i:1.000300,i:100.HSI,i:100.HSCEI,i:124.HSCCI,i:100.TWII,i:100.N225,i:100.KOSPI200,i:100.KS11,i:100.STI,i:100.SENSEX,i:100.KLSE,i:100.SET,i:100.PSI,i:100.KSE100,i:100.VNINDEX,i:100.JKSE,i:100.CSEALL'
        全球指数-美洲股市 'i:100.DJIA,i:100.SPX,i:100.NDX,i:100.TSX,i:100.BVSP,i:100.MXX'
        全球指数-欧洲股市 'i:100.SX5E,i:100.FTSE,i:100.MCX,i:100.AXX,i:100.FCHI,i:100.GDAXI,i:100.RTS,i:100.IBEX,i:100.PSI20,i:100.OMXC20,i:100.BFX,i:100.AEX,i:100.WIG,i:100.OMXSPI,i:100.SSMI,i:100.HEX,i:100.OSEBX,i:100.ATX,i:100.MIB,i:100.ASE,i:100.ICEXI,i:100.PX,i:100.ISEQ'
        全球指数-澳洲股市 'i:100.AS51,i:100.AORD,i:100.NZ50'
        全球指数-其他指数 'i:100.UDI,i:100.BDI,i:100.CRB'

        期货-中金所 'i:100.UDI,i:100.BDI,i:100.CRB'
        国债 'm:8+s:16+f:!8192'
      )
      local zjCycles="
        今日排行 f62 f12,f14,f2,f3,f62,f184,f66,f69,f72,f75,f78,f81,f84,f87,f204,f205,f124,f1,f13 (主力净流入)f62|number(cn)|indicator,(超大净流入)f66|number(cn)|indicator,(大单净流入)f72|number(cn)|indicator,(中单净流入)f78|number(cn)|indicator,(小单净流入)f84|number(cn)|indicator
        3日排行 f267 f12,f14,f2,f127,f267,f268,f269,f270,f271,f272,f273,f274,f275,f276,f257,f258,f124,f1,f13 (3日涨跌幅)f127|format(+%)|indicator,(主力净流入)f267|number(cn)|indicator,(超大净流入)f269|number(cn)|indicator,(大单净流入)f271|number(cn)|indicator,(中单净流入)f273|number(cn)|indicator,(小单净流入)f275|number(cn)|indicator
        5日排行 f164 f12,f14,f2,f109,f164,f165,f166,f167,f168,f169,f170,f171,f172,f173,f257,f258,f124,f1,f13 (5日涨跌幅)f109|format(+%)|indicator,(主力净流入)f164|number(cn)|indicator,(超大净流入)f166|number(cn)|indicator,(大单净流入)f168|number(cn)|indicator,(中单净流入)f170|number(cn)|indicator,(小单净流入)f172|number(cn)|indicator
        10日排行 f174 f12,f14,f2,f160,f174,f175,f176,f177,f178,f179,f180,f181,f182,f183,f260,f261,f124,f1,f13 (10日涨跌幅)f160|format(+%)|indicator,(主力净流入)f174|number(cn)|indicator,(超大净流入)f176|number(cn)|indicator,(大单净流入)f178|number(cn)|indicator,(中单净流入)f180|number(cn)|indicator,(小单净流入)f182|number(cn)|indicator
      "
      case $2 in
        滚动新闻|7x24直播|roll|kuaixun) # 7x24直播 http://kuaixun.eastmoney.com/
          url="https://newsapi.eastmoney.com/kuaixun/v2/api/list?callback=ajaxResult_102&column=102&limit=${SIZE:-20}&p=${PAGE:-1}&callback=kxall_ajaxResult102&_=$(date +%s)"
          jsonFormat='news|TABLE:(标题)title|red|bold|index,(内容)digest|white|dim|HIDE_IN_TABLE,(时间)showtime,(链接)url_unique|dim'
          jsonp=OBJ
        ;;
        最新播报|zxbb|news) # http://roll.eastmoney.com/
          url="https://emres.dfcfw.com/60/zxbb2018.js?callback=zxbb2018&_=$(date +%s)"
          aliases=(标题 时间 链接)
          fields=(Art_Title Art_Showtime Art_UniqueUrl)
          jsonFormat='Result|TABLE|reverse:(标题)Art_Title|red|bold|index,(时间)Art_Showtime,(链接)Art_UniqueUrl|white|dim'
          jsonp=OBJ
        ;;
        周末消息|zmxx) # https://data.eastmoney.com/xg/xg/calendar.html
          json_res eastmoney search keyword '周末这些重要消息或将影响股市'
        ;;
        每日数据挖掘机|mrwj) # https://data.eastmoney.com/xg/xg/calendar.html
          json_res eastmoney search keyword '每日数据挖掘机'
        ;;
        机构调研|jgdy)
          json_res eastmoney search keyword '机构调研'
        ;;
        龙虎榜解读|lhbjd) # https://data.eastmoney.com/stock/lhb.html
          json_res eastmoney search keyword '龙虎榜'
        ;;
        盘后机构策略|phjgcl)
          json_res eastmoney search keyword '盘后机构策略'
        ;;
        早间机构策略|pqjgcl)
          json_res eastmoney search keyword '早间机构策略'
        ;;
        行情|quote)
          outputfile=$outputfile.$3
          local yd_types=(
            火箭发射 8201 快速反弹 8202 大笔买入 8193 封涨停板 4 打开跌停板 32 有大买盘 64 竞价上涨 8207 高开5日线 8209 向上缺口 8211 60日新高 8213 60日大幅上涨 8215
            加速下跌 8204 高台跳水 8203 大笔卖出 8194 封跌停板 8 打开涨停板 16 有大卖盘 128 竞价下跌 8208 低开5日线 8210 向下缺口 8212 60日新低 8214 60日大幅下跌 8216
          )
          case $3 in
            国内股指|gngz)
              url='https://push2.eastmoney.com/api/qt/clist/get'
              curlparams+=(--data-urlencode pi=0)
              curlparams+=(--data-urlencode pz=10)
              curlparams+=(--data-urlencode po=1)
              curlparams+=(--data-urlencode np=1)
              curlparams+=(--data-urlencode fields=f1,f2,f3,f4,f6,f12,f13,f14,f18)
              curlparams+=(--data-urlencode fltt=2)
              curlparams+=(--data-urlencode invt=2)
              curlparams+=(--data-urlencode ut=433fd2d0e98eaf36ad3d5001f088614d)
              curlparams+=(--data-urlencode fs=i:1.000001,i:1.000047,i:1.000902,i:1.000985,i:2.930903,i:0.399001,i:0.399106,i:0.399006,i:0.399102,i:1.000300,i:1.000016,i:1.000688,i:0.300059)
              curlparams+=(--data-urlencode "cb=jQuery112408605893827100204_$(date +%s)&_=$(date +%s)")
              jsonFormat='data.diff|TABLE:(指数)f14|indicator({.f2},{.f18}),(点数)f2,(涨跌幅)f3|format(%)|indicator,(成交额)f6|number(cn),(代码)f12'
              jsonp=OBJ
            ;;
            国外股指|gwgz)
              url="https://push2.eastmoney.com/api/qt/ulist.np/get?fields=f1,f2,f12,f13,f14,f3,f4,f6,f104,f152&secids=100.ATX,100.FCHI,100.GDAXI,100.HSI,100.N225,100.FTSE,100.NDX,100.DJIA&ut=13697a1cc677c8bfa9a496437bfef419&cb=jQuery112408605893827100204_$(date +%s)&_=$(date +%s)"
              jsonFormat='data.diff|TABLE:(指数)f14|red|bold|index,(点数)f2,(涨跌幅)f3|format(%)|indicator,(成交额)f6|number(cn),(代码)f12'
              jsonp=OBJ
            ;;
            分时图|fst) #
              url='http://push2.eastmoney.com/api/qt/stock/trends2/get'
              local cb=cb_$(timestamp)_$(random 8)
              local code=$(question2 -q '代码' -i "$4")
              curlparams+=(--data-urlencode secid=$code)
              curlparams+=(--data-urlencode fields1=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13)
              curlparams+=(--data-urlencode fields2=f51,f52,f53,f54,f55,f56,f57,f58)
              curlparams+=(--data-urlencode ut=e1e6871893c6386c5ff6967026016627)
              curlparams+=(--data-urlencode iscr=0)
              curlparams+=(--data-urlencode cb=$cb)
              curlparams+=(--data-urlencode isqhquote=)
              curlparams+=(--data-urlencode $cb=$cb)
              jsonFormat='data.trends|plot(type=fst,m:name={/data.name},m:market={/data.market},m:code={/data.code},m:close={/data.preClose})'
              jsonp=OBJ
              export IMGCAT=${IMGCAT-1}
            ;;
            个股资金流|zj) # https://data.eastmoney.com/zjlx/detail.html
              local zjMarkets="
                全部股票 m:0+t:6+f:!2,m:0+t:13+f:!2,m:0+t:80+f:!2,m:1+t:2+f:!2,m:1+t:23+f:!2,m:0+t:7+f:!2,m:1+t:3+f:!2
                沪深A股 m:0+t:6+f:!2,m:0+t:13+f:!2,m:0+t:80+f:!2,m:1+t:2+f:!2,m:1+t:23+f:!2
                沪市A股 m:1+t:2+f:!2,m:1+t:23+f:!2
                科创板 m:1+t:23+f:!2
                深市A股 m:0+t:6+f:!2,m:0+t:13+f:!2,m:0+t:80+f:!2
                创业板 m:0+t:80+f:!2
                沪市B股 m:1+t:3+f:!2
                深市B股 m:0+t:7+f:!2
              "
              ask2 -1 -d '0' -i "$4" -q '统计天数' -A "${zjCycles[*]}" -N 4 -S 0
              local zjCycle=$_ASK_RESULT
              local fields="${_ASK_RESULTS[@]:2:1}"
              local cols="${_ASK_RESULTS[@]:3:1}"
              local market=$(ask2 -1 -d '0' -i "$5" -q '市场' -A "${zjMarkets[*]}" -N 2 -S 0)
              local order=$(whether -q '正序' -i "$5" -y 0 -n 1)
              url='https://push2.eastmoney.com/api/qt/clist/get'
              curlparams+=(--data-urlencode cb=jQuery112305113121161098986_$(timestamp))
              curlparams+=(--data-urlencode fid=$zjCycle)
              curlparams+=(--data-urlencode po=$order)
              curlparams+=(--data-urlencode pz=${SIZE:-10})
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode np=1)
              curlparams+=(--data-urlencode fltt=2)
              curlparams+=(--data-urlencode invt=2)
              curlparams+=(--data-urlencode ut=b2884a393a59ad64002292a3e90d46a5)
              curlparams+=(--data-urlencode fs=$market)
              curlparams+=(--data-urlencode fields=$fields)
              jsonFormat='data.diff|TABLE:(证券)f14|${.f12} {.f14}$|indicator({.f3}),(涨跌幅)f3|format(+%)|indicator,'$cols',(链接)f12|$https://data.eastmoney.com/stockdata/{.f12}.html$'
              jsonp=OBJ
            ;;
            板块资金流|bkzj) # https://data.eastmoney.com/bkzj/
              local boards="
                地域板块 1
                行业板块 2
                概念板块 3
              "
              ask2 -1 -d '0' -i "$4" -q '统计天数' -A "${zjCycles[*]}" -N 4 -S 0
              local zjCycle=$_ASK_RESULT
              local fields="${_ASK_RESULTS[@]:2:1}"
              local cols="${_ASK_RESULTS[@]:3:1}"
              local bkType=$(ask2 -1 -i "$input" -d '1' -i "$5" -q '板块类型' -A "${boards[*]}" -N 2 -S '0')
              local order=$(whether -q '正序' -i "$6" -y 0 -n 1)
              url='https://push2.eastmoney.com/api/qt/clist/get'
              curlparams+=(--data-urlencode cb=jQuery112307932171275575526_$(timestamp))
              curlparams+=(--data-urlencode fid=$zjCycle)
              curlparams+=(--data-urlencode po=$order)
              curlparams+=(--data-urlencode pz=${SIZE:-10})
              curlparams+=(--data-urlencode pn=${PAGE:-1})
              curlparams+=(--data-urlencode np=1)
              curlparams+=(--data-urlencode fltt=2)
              curlparams+=(--data-urlencode invt=2)
              curlparams+=(--data-urlencode "fs=m:90+t:$bkType")
              curlparams+=(--data-urlencode stat=1)
              curlparams+=(--data-urlencode fields=$fields)
              curlparams+=(--data-urlencode ut=b2884a393a59ad64002292a3e90d46a5)
              jsonFormat='data.diff|TABLE:(板块)f14|SIMPLE,(涨跌幅)f3|format(+%)|indicator|SIMPLE,'$cols',(链接)f12|$https://data.eastmoney.com/bkzj/{.f12}.html$|SIMPLE'
              jsonp=OBJ
            ;;
            # kline http://56.push2his.eastmoney.com/api/qt/stock/kline/get?cb=jQuery35108905987798741108_1676431200477&secid=0.300250&ut=fa5fd1943c7b386f172d6893dbfba10b&fields1=f1%2Cf2%2Cf3%2Cf4%2Cf5%2Cf6&fields2=f51%2Cf52%2Cf53%2Cf54%2Cf55%2Cf56%2Cf57%2Cf58%2Cf59%2Cf60%2Cf61&klt=103&fqt=1&beg=0&end=20500101&smplmt=460&lmt=1000000&_=1676431200584
            盘口异动|pkyd) # http://quote.eastmoney.com/changes/
              local input="$4"
              case "$input" in
                up) input="8201 8213 8202 8193 32 8";;
                down) input="8204 8214 8203 8194 16 4";;
              esac
              local type=$(ask2 -1 -m -i "$input" -D 'ALL' -q '异动类型' -Q '默认包含所有类型' -A "${yd_types[*]}" -N 2 | tr ' ' ,)
              url='http://push2ex.eastmoney.com/getAllStockChanges'
              curlparams+=(-d type=$type)
              curlparams+=(--data-urlencode cb=jQuery35109544115898056558_$(timestamp))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode pageindex=${PAGE:-0})
              curlparams+=(--data-urlencode pagesize=${SIZE:-30})
              curlparams+=(--data-urlencode dpt=wzchanges)
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='data.allstock|TABLE:(证券名称)n|red|bold|SIMPLE,(代码)c|dim|SIMPLE,(类型)t|map(bash:arr='${yd_types[*]}',bash:arrdim=2,bash:arridx=0)|cond(handler=red,cond=exp,exp=in,vi=0,bash:arr=8201)|cond(handler=magenta,cond=exp,exp=in,vi=0,bash:arr=8213 8202 8193 32 8211)|SIMPLE,(时间)tm|date(time,from=%H%M%S)|dim|SIMPLE,(链接)url|$http://quote.eastmoney.com/unify/r/{.m}.{.c}$|dim'
              jsonp=OBJ
            ;;
            板块异动|bkyd) # http://quote.eastmoney.com/changes/boardlist.html
              url='http://push2ex.eastmoney.com/getAllBKChanges'
              curlparams+=(--data-urlencode cb=jQuery35109544115898056558_$(timestamp))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wzchanges)
              curlparams+=(--data-urlencode pageindex=${PAGE:-0})
              curlparams+=(--data-urlencode pagesize=${SIZE:-50})
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='data.allbk|TABLE:(证券名称)n|red|bold,(代码)c|dim,(涨跌幅)u|format(+%)|indicator,(主力净流入)zjl|number(cn,base=万)|indicator,(最频繁个股)ms.n|${.ms.t|map(bash:arr='${yd_types[*]}',bash:arrdim=2,bash:arridx=0)|indicator(exp=in,bash:arr='${yd_types[@]:0:22}')} {.ms.c|dim} {.ms.n|magenta}$,(链接)url|$http://quote.eastmoney.com/unify/r/{.m}.{.c}$|dim,(异动情况统计)ydl|TABLE|HIDE_IN_TABLE:(类型)t|map(bash:arr='${yd_types[*]}',bash:arrdim=2,bash:arridx=0)|indicator(exp=in,bash:arr='${yd_types[@]:0:22}'),(次数)ct'
              jsonp=OBJ
            ;;
            盘口异动数据对比|yddb) # 图表 http://quote.eastmoney.com/changes/?from=center
              local types=(
                火箭发射 8201 快速反弹 8202 大笔买入 8193 封涨停板 4 打开跌停板 32 有大买盘 64 竞价上涨 8207 高开5日线 8209 向上缺口 8211 60日新高 8213 60日大幅上涨 8215
                加速下跌 8204 高台跳水 8203 大笔卖出 8194 封跌停板 8 打开涨停板 16 有大卖盘 128 竞价下跌 8208 低开5日线 8210 向下缺口 8212 60日新低 8214 60日大幅下跌 8216
              )
              url='http://push2ex.eastmoney.com/getStockCountChanges'
              curlparams+=(-d type=4,8,16,32,64,128,8193,8194,8201,8204,8202,8203,8207,8208,8209,8210,8211,8212,8213,8214,8215,8216)
              curlparams+=(--data-urlencode cb=jQuery35108645588633523951_$(timestamp))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wzchanges)
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/em.quote.yddb/2022-12-01.16:59:32.json)
              jsonFormat='data.ydlist|plot(type=yddb)'
              export IMGCAT=${IMGCAT-1}
              jsonp=OBJ
            ;;
            行情排行|rank) # https://quote.eastmoney.com/center/gridlist.html
              url='http://push2.eastmoney.com/api/qt/clist/get'
              local sort=$(ask2 -q '排序字段' -i "$4" -1 -d f3 -N 2 -A '涨跌幅 f3 换手率 f8 流通市值 f21 量比 f10 涨速 f22 量比 f10 5分钟涨跌 f11')
              local market=$(ask2 -q '市场' -i "$5" -d 0 -1 -N 2 -S '0' -A "${markets[*]}")
              local order=$(whether -q '正序' -i "$6" -y 0 -n 1)
              local page=${PAGE:-1}
              curlparams+=(--data-urlencode cb=jQuery112404812956954993921_$(timestamp))
              curlparams+=(--data-urlencode pn=$page)
              curlparams+=(--data-urlencode pz=20)
              curlparams+=(--data-urlencode po=$order)
              curlparams+=(--data-urlencode np=1)
              curlparams+=(--data-urlencode ut=bd1d9ddb04089700cf9c27f6f7426281)
              curlparams+=(--data-urlencode fltt=2)
              curlparams+=(--data-urlencode invt=2)
              curlparams+=(--data-urlencode 'wbp2u=9569356073124232|0|0|0|web')
              curlparams+=(--data-urlencode fid=$sort)
              curlparams+=(--data-urlencode "fs=$market")
              curlparams+=(--data-urlencode 'fields=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f13,f14,f15,f16,f17,f18,f20,f21,f23,f24,f25,f22,f11,f62,f128,f136,f115,f152')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='data.diff|TABLE:(证券名称)f14|${.f12} {.f14}$|indicator({.f17},{.f18}),(涨速)f22|format(+%)|indicator|SIMPLE,(5分钟)f11|format(+%)|indicator|SIMPLE,(涨跌幅)f3|format(+%)|indicator|SIMPLE,(量比)f10|cyan,(振幅)f7|format(+%)|SIMPLE,(换手率)f8|format(+%),(最新价)f2|indicator(cmp={.f18}),(PE)f9,(流通市值)f21|number(cn),(链接)url|$http://quote.eastmoney.com/unify/r/{.f13}.{.f12}$|dim$'
              jsonp=OBJ
              local pages=${PAGES:-1}
              local offset=$(($page * 20))
              local next=$(($page + 1))
              [[ $page -lt $pages ]] && tailer="_ASK_NO_VERBOSE=1 PAGES=$pages PAGE=$next OFFSET=$offset json_res ${@:1:3} $sort $market $order"
            ;;
            股池|gc) # http://quote.eastmoney.com/ztb/detail
              local types=(
                涨停板股池 ztgc getTopicZTPool fbt:asc # 首次封板时间
                昨日涨停股池 zrzt getYesterdayZTPool zs:desc # 涨速
                强势股池 qsgc getTopicQSPool zdp:desc # 涨跌幅
                次新股池 cxgc getTopicCXPooll ods:asc # 开板几日
                炸板股池 zbgc getTopicZBPool fbt:asc #
                跌停股池 dtgc getTopicDTPool fund:asc # 封单资金
              )
              ask2 -s -i "$4" -S '0' -N 4 -A "${types[*]}"
              name=${_ASK_RESULTS[@]:1:1}
              sort=${_ASK_RESULTS[@]:3:1}
              url=http://push2ex.eastmoney.com/${_ASK_RESULTS[@]:2:1}
              curlparams+=(--data-urlencode cb=callbackdata$(random 7))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wz.ztzt)
              curlparams+=(--data-urlencode Pageindex=$((${PAGE:-1} - 1)))
              curlparams+=(--data-urlencode pagesize=${SIZE:-20})
              curlparams+=(--data-urlencode sort=$sort)
              curlparams+=(--data-urlencode date=$_last_trade_day)
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/em.quote.ztgc/2022-11-29.12:06:16.json)
              jsonFormat='data.pool|TABLE:(证券名称)n|${.c} {.n}$|red|bold,(板块)hybk|magenta,(连板数)lbc|${.lbc}连板$|yellow,(炸板次数)zbc|yellow,(涨停统计（板/天）)zttj|${.zttj.ct}/{.zttj.days}$,(换手率)hs|number(2)|format(%),(成交额（元）)amount|number(cn),(流通市值（元）)ltsz|number(cn),(涨跌幅)zdp|number(+)|format(%)|indicator,(首次封板时间)fbt|number(fixed,n=6)|date(time,from=%H%M%S),(最后封板时间)lbt|number(fixed,n=6)|date(time,from=%H%M%S)'
              jsonp=OBJ
            ;;
            涨停板股池|ztgc) # http://quote.eastmoney.com/ztb/detail#type=ztgc
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            昨日涨停股池|zrzt) # http://quote.eastmoney.com/ztb/detail#type=zrzt
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            强势股池|qsgc) # https://quote.eastmoney.com/ztb/detail#type=qsgc
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            次新股池|cxgc) # https://quote.eastmoney.com/ztb/detail#type=cxgc
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            炸板股池|zbgc) # https://quote.eastmoney.com/ztb/detail#type=zbgc
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            跌停股池|dtgc) # https://quote.eastmoney.com/ztb/detail#type=dtgc
              json_res eastmoney quote gc ${@:3}
              return
            ;;
            涨跌分布|zdfb) # 图表 http://quote.eastmoney.com/ztb/detail
              url='http://push2ex.eastmoney.com/getTopicZDFenBu'
              curlparams+=(--data-urlencode cb=callbackdata$(random 7))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wz.ztzt)
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/em.quote.zdfb/2022-11-30.17:54:25.json)
              jsonFormat='data.fenbu|plot(type=zdfb)'
              jsonp=OBJ
              export IMGCAT=${IMGCAT-1}
            ;;
            涨跌停对比|zdtdb) # 图表 http://quote.eastmoney.com/ztb/detail
              url='http://push2ex.eastmoney.com/getTopicZDTCount'
              curlparams+=(--data-urlencode cb=callbackdata$(random 7))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wz.ztzt)
              curlparams+=(--data-urlencode time=0)
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/em.quote.zdtdb/2022-11-30.18:03:23.json)
              jsonFormat='data.zdtcount|plot(type=zdtdb)'
              jsonp=OBJ
              export IMGCAT=${IMGCAT-1}
            ;;
            封板未遂|fbws) # 图表 http://quote.eastmoney.com/ztb/detail
              url='http://push2ex.eastmoney.com/getTopicFBFailed'
              curlparams+=(--data-urlencode cb=callbackdata$(random 7))
              curlparams+=(--data-urlencode ut=7eea3edcaed734bea9cbfc24409ed989)
              curlparams+=(--data-urlencode dpt=wz.ztzt)
              curlparams+=(--data-urlencode time=0)
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/em.quote.fbws/2022-11-30.22:13:36.json)
              jsonFormat='data.fbfailed|plot(type=fbws)'
              jsonp=OBJ
              export IMGCAT=${IMGCAT-1}
            ;;
            股吧情绪|gbqx) # 图表 http://quote.eastmoney.com/ztb/detail
              url='http://quote.eastmoney.com/ztb/api/gbtrend'
              curlparams+=(--data-urlencode type=3)
              # text=$(cat data/em.quote.gbqx/2022-11-30.23:00:12.json)
              jsonFormat='result.data|plot(type=gbqx)'
              jsonp=OBJ
              export IMGCAT=${IMGCAT-1}
            ;;
            *) unknown 3 "$@";;
          esac
        ;;
        数据|data)
          outputfile=$outputfile.$3
          case $3 in
            龙虎榜|lhb) # https://data.eastmoney.com/stock/tradedetail.html
              local date_start=($(question2 -q '开始时间' -d $_today -i $4))
              local date_end=($(question2 -q '结束时间' -d $_today -i $5))
              url='https://datacenter-web.eastmoney.com/api/data/v1/get'
              curlparams+=(--data-urlencode callback=jQuery112307241680021281278_$(timestamp))
              curlparams+=(--data-urlencode sortColumns=SECURITY_CODE,TRADE_DATE)
              curlparams+=(--data-urlencode sortTypes=1,-1)
              curlparams+=(--data-urlencode pageSize=${SIZE:-50})
              curlparams+=(--data-urlencode pageNumber=${PAGE:-1})
              curlparams+=(--data-urlencode reportName=RPT_DAILYBILLBOARD_DETAILSNEW)
              curlparams+=(--data-urlencode columns=SECURITY_CODE,SECUCODE,SECURITY_NAME_ABBR,TRADE_DATE,EXPLAIN,CLOSE_PRICE,CHANGE_RATE,BILLBOARD_NET_AMT,BILLBOARD_BUY_AMT,BILLBOARD_SELL_AMT,BILLBOARD_DEAL_AMT,ACCUM_AMOUNT,DEAL_NET_RATIO,DEAL_AMOUNT_RATIO,TURNOVERRATE,FREE_MARKET_CAP,EXPLANATION,D1_CLOSE_ADJCHRATE,D2_CLOSE_ADJCHRATE,D5_CLOSE_ADJCHRATE,D10_CLOSE_ADJCHRATE,SECURITY_TYPE_CODE)
              curlparams+=(--data-urlencode source=WEB)
              curlparams+=(--data-urlencode client=WEB)
              curlparams+=(--data-urlencode "filter=(TRADE_DATE<='${date_start}')(TRADE_DATE>='${date_end}')")
              jsonFormat='result.data|TABLE:(证券名称)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|indicator(cmp={.CHANGE_RATE})|bold|index,(涨跌幅)CHANGE_RATE|number(+)|format(%)|indicator|SIMPLE,(买入)BILLBOARD_BUY_AMT|number(cn)|HIDE_IN_TABLE,(卖出)BILLBOARD_SELL_AMT|number(cn)|HIDE_IN_TABLE,(净买入)BILLBOARD_NET_AMT|number(cn)|indicator|SIMPLE,(龙虎榜成交额)BILLBOARD_DEAL_AMT|number(cn),(总成交额)ACCUM_AMOUNT|number(cn),(换手率)TURNOVERRATE|format(%)|SIMPLE,(交易日)TRADE_DATE|date(date)|HIDE_IN_TABLE,(上榜原因)EXPLANATION|dim|SIMPLE,(其他)EXPLAIN|dim|HIDE_IN_TABLE,(链接)url|$https://data.eastmoney.com/stock/lhb,{.TRADE_DATE|slice(0,10)},{.SECURITY_CODE}.html$|HIDE_IN_TABLE'
              jsonp=OBJ
            ;;
            领涨概念|lzgn)
              url='https://push2.eastmoney.com/api/qt/clist/get'
              curlparams+=(--data-urlencode pn=$PAGE)
              curlparams+=(--data-urlencode pz=$SIZE)
              curlparams+=(--data-urlencode po=1)
              curlparams+=(--data-urlencode np=1)
              curlparams+=(--data-urlencode ut=fa5fd1943c7b386f172d6893dbfba10b)
              curlparams+=(--data-urlencode fltt=2)
              curlparams+=(--data-urlencode invt=2)
              curlparams+=(--data-urlencode fid=f3)
              curlparams+=(--data-urlencode 'fs=m:90 t:3')
              curlparams+=(--data-urlencode fields=f1,f2,f3,f4,f14,f12,f13,f62,f128,f136,f1520e76d4e)
              curlparams+=(--data-urlencode cb=jQuery3510780095733559149_$(timestamp))
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='data.diff|TABLE:(证券名称)f128|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|indicator(cmp={.CHANGE_RATE})|bold|index,(涨跌幅)CHANGE_RATE|number(+)|format(%)|indicator|SIMPLE,(买入)BILLBOARD_BUY_AMT|number(cn)|HIDE_IN_TABLE,(卖出)BILLBOARD_SELL_AMT|number(cn)|HIDE_IN_TABLE,(净买入)BILLBOARD_NET_AMT|number(cn)|indicator|SIMPLE,(龙虎榜成交额)BILLBOARD_DEAL_AMT|number(cn),(总成交额)ACCUM_AMOUNT|number(cn),(换手率)TURNOVERRATE|format(%)|SIMPLE,(交易日)TRADE_DATE|date(date)|HIDE_IN_TABLE,(上榜原因)EXPLANATION|dim|SIMPLE,(其他)EXPLAIN|dim|HIDE_IN_TABLE,(链接)url|$https://data.eastmoney.com/stock/lhb,{.TRADE_DATE|slice(0,10)},{.SECURITY_CODE}.html$|HIDE_IN_TABLE'
              jsonp=OBJ
            ;;
            机构调研) # https://data.eastmoney.com/jgdy/
            ;;
            股东增减持) # https://data.eastmoney.com/executive/gdzjc.html
            ;;
            公告大全) # https://data.eastmoney.com/notices/
            ;;
            大宗交易) # https://data.eastmoney.com/dzjy/
            ;;
            个股北向资金持仓明细|bxcg) # https://data.eastmoney.com/hsgtcg/StockHdDetail/002460.html
              # {
              #   "SECUCODE": "002049.SZ",
              #   "SECURITY_CODE": "002049",
              #   "SECURITY_INNER_CODE": "1000001786",
              #   "SECURITY_NAME_ABBR": "紫光国微",
              #   "HOLD_DATE": "2023-10-27 00:00:00",
              #   "ORG_CODE": "10057606",
              #   "ORG_NAME": "美林远东有限公司",
              #   "HOLD_NUM": 620535,
              #   "MARKET_CODE": "003",
              #   "HOLD_SHARES_RATIO": 0.07,
              #   "HOLD_MARKET_CAP": 45882357.9,
              #   "CLOSE_PRICE": 73.94,
              #   "CHANGE_RATE": 2.9518,
              #   "HOLD_MARKET_CAPONE": 11657183.28,
              #   "HOLD_MARKET_CAPFIVE": 17577656.97,
              #   "HOLD_MARKET_CAPTEN": 22901281.07,
              #   "PARTICIPANT_CODE": "B01224"
              # }
              local columns=(
                "SECUCODE"            "002049.SZ",
                "SECURITY_CODE"       "002049",
                "SECURITY_INNER_CODE" "1000001786",
                "SECURITY_NAME_ABBR"  "紫光国微",
                "HOLD_DATE"           "2023-10-27 00:00:00",
                "ORG_CODE"            "10057606",
                "ORG_NAME"            "美林远东有限公司",
                "HOLD_NUM"            620535,
                "MARKET_CODE"         "003",
                "HOLD_SHARES_RATIO"   0.07,
                "HOLD_MARKET_CAP"     45882357.9,
                "CLOSE_PRICE"         73.94,
                "CHANGE_RATE"         2.9518,
                "HOLD_MARKET_CAPONE"  1日持仓变化
                "HOLD_MARKET_CAPFIVE" 5日持仓变化
                "HOLD_MARKET_CAPTEN"  10日持仓变化
                "PARTICIPANT_CODE"    "B01224"
              )
              local sortTypes=(
                -1 倒序
                1  顺序
              )
              local code=$(question2 -q '证券代码' -i "$4")
              local market=$(ask2 -q '交易市场' -i "$5" -0 -N 3 -A "001 沪市 sh 003 深市 sz")
              local date="$(question2 -q '日期' -d "$_today" -i "$6")"
              local sortColumn=$(ask2 -q '排序字段' -d 'HOLD_MARKET_CAPONE' -i $7 -0 -N 2 -A "${columns[*]}")
              local sortType=$(ask2 -q '排序方式' -d '-1' -i $8 -0 -N 2 -A "${sortTypes[*]}")

              tailer="echo 页面地址 https://data.eastmoney.com/hsgtcg/StockHdDetail/$code/$date.html >&2"

              url='https://datacenter-web.eastmoney.com/api/data/v1/get'
              curlparams+=(--data-urlencode callback=jQuery112307241680021281278_$(timestamp))
              curlparams+=(--data-urlencode sortColumns=$sortColumn)
              curlparams+=(--data-urlencode sortTypes=$sortType)
              curlparams+=(--data-urlencode pageSize=${SIZE:-50})
              curlparams+=(--data-urlencode pageNumber=${PAGE:-1})
              curlparams+=(--data-urlencode reportName=RPT_MUTUAL_HOLD_DET)
              curlparams+=(--data-urlencode columns=ALL)
              curlparams+=(--data-urlencode source=WEB)
              curlparams+=(--data-urlencode client=WEB)
              curlparams+=(--data-urlencode filter="(SECURITY_CODE=\"$code\")(MARKET_CODE=\"$market\")(HOLD_DATE='$date')")
              jsonFormat='result.data|TABLE:(证券名称)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR} {.CHANGE_RATE|number(+)|format(%)}$|indicator(cmp={.CHANGE_RATE})|bold|index,(机构名称)f128|${.PARTICIPANT_CODE} {.ORG_NAME}$|indicator(cmp={.HOLD_MARKET_CAPONE}),(持仓变化)HOLD_MARKET_CAPONE|number(cn)|indicator(cmp={.HOLD_MARKET_CAPONE}),(持股市值)HOLD_MARKET_CAP|number(cn),(链接)url|$https://data.eastmoney.com/hsgtcg/InstitutionHdStatistics/{.PARTICIPANT_CODE}.html$|HIDE_IN_TABLE'
              jsonp=OBJ
            ;;
            个股北向资金历史|bxls)
              local columns=(
                "SECURITY_INNER_CODE"  "1000001786",
                "SECUCODE"             "002049.SZ",
                "TRADE_DATE"           "2023-10-27 00 :00:00",
                "SECURITY_CODE"        "002049",
                "SECURITY_NAME"        "紫光国微",
                "MUTUAL_TYPE"          "003",
                "CHANGE_RATE"          2.951824004456,
                "CLOSE_PRICE"          73.94,
                "HOLD_SHARES"          16548245,
                "HOLD_MARKET_CAP"      1223577235.3,
                "A_SHARES_RATIO"       1.95,
                "HOLD_SHARES_RATIO"    1.94,
                "FREE_SHARES_RATIO"    1.9481,
                "TOTAL_SHARES_RATIO"   1.9477,
                "HOLD_MARKETCAP_CHG1"  43417349.5,
                "HOLD_MARKETCAP_CHG5"  -14849373.35,
                "HOLD_MARKETCAP_CHG10" -97354940.03
              )
              local sortTypes=(
                -1 倒序
                1  顺序
              )
              local code=$(question2 -q '证券代码' -i "$4")
              local date="$(question2 -q '起始日期' -d "$_today" -i "$5")"
              local sortColumn=$(ask2 -q '排序字段' -d 'TRADE_DATE' -i $6 -0 -N 2 -A "${columns[*]}")
              local sortType=$(ask2 -q '排序方式' -d '-1' -i $7 -0 -N 2 -A "${sortTypes[*]}")
              url='https://datacenter-web.eastmoney.com/api/data/v1/get'
              curlparams+=(--data-urlencode callback=jQuery112307241680021281278_$(timestamp))

              tailer="echo 页面地址 https://data.eastmoney.com/hsgtcg/StockHdStatistics/$code.html >&2"

              curlparams+=(--data-urlencode sortColumns=$sortColumn)
              curlparams+=(--data-urlencode sortTypes=$sortType)
              curlparams+=(--data-urlencode pageSize=${SIZE:-50})
              curlparams+=(--data-urlencode pageNumber=${PAGE:-1})
              curlparams+=(--data-urlencode reportName=RPT_MUTUAL_HOLDSTOCKNORTH_STA)
              curlparams+=(--data-urlencode columns=ALL)
              curlparams+=(--data-urlencode source=WEB)
              curlparams+=(--data-urlencode client=WEB)
              curlparams+=(--data-urlencode filter="(SECURITY_CODE=\"$code\")(TRADE_DATE>='$date')")
              jsonFormat='result.data|TABLE:(证券名称)SECURITY_NAME|${.SECURITY_CODE} {.SECURITY_NAME} {.CHANGE_RATE|number(+)|format(%)}$|indicator(cmp={.CHANGE_RATE})|bold|index,(持仓变化)HOLD_MARKETCAP_CHG1|number(cn)|indicator(cmp={.HOLD_MARKETCAP_CHG1}),(持股市值)HOLD_MARKET_CAP|number(cn),(持仓比例)HOLD_SHARES_RATIO|format(%),(交易日期)TRADE_DATE|slice(0,10),(链接)url|$https://data.eastmoney.com/hsgtcg/StockHdDetail/{.SECURITY_CODE}/{.TRADE_DATE|slice(0,10)}.html$|HIDE_IN_TABLE'
              jsonp=OBJ
            ;;
            股吧最新发帖|zxft)
              url="http://guba.eastmoney.com/list,zssz399006,f_$PAGE.html"
            ;;
            股吧最新评论|zxpl)
              url="http://guba.eastmoney.com/list,zssz399006_$PAGE.html"
            ;;
          esac
        ;;
        搜索|search|s) # https://so.eastmoney.com/ann/s?keyword=%E8%99%9A%E6%8B%9F
          outputfile=$outputfile.$3
          local keyword="$4"
          case $3 in
            关键词|keyword) # 新股日历 https://data.eastmoney.com/xg/xg/calendar.html
              url='https://data.eastmoney.com/dataapi/search/article'
              curlparams+=(--data-urlencode page=${PAGE:-1})
              curlparams+=(--data-urlencode pagesize=${SIZE:-50})
              curlparams+=(--data-urlencode keywordPhase=true)
              curlparams+=(--data-urlencode excludeChannels[]=1)
              curlparams+=(--data-urlencode "keyword=$keyword")
              jsonFormat='result.cmsArticleWeb:(标题)title|red|bold|index,(内容)content|white|dim,(媒体)mediaName,(时间)date,(链接)url|dim'
            ;;
            代码2|code2) # https://so.eastmoney.com/quotation/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              local types=(AB_STOCK AB股 INDEX 指数 BK 板块 HK 港股 UN 美股 UK 英股 TB 三板 FUND 基金 DEBT 债券 FU_OR_OP 期货期权 FE 外汇)
              local type=$(ask2 -i "$type" -d 1 -q '市场类型'\
              -a "ALL AB_STOCK INDEX BK HK UN UK TB FUND DEBT FU_OR_OP FE"\
              -a "所有 AB股 指数 板块 港股 美股 英股 三板 基金 债券 期货期权 外汇")

              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["codetableLabelWeb"],"client":"web","clientType":"wap","clientVersion":"curr","param":{"codetableLabelWeb":{"pageIndex":'${PAGE:-1}',"pageSize":'${SIZE:-10}',"preTag":"","postTag":"","isHighlight":false,"label":"'$type'"}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat=':(分类名称)name|red|bold|SIMPLE,(分类)type,(列表)quoteList|TABLE|SIMPLE:(证券名称)shortName|green|SIMPLE,(证券代码)unifiedCode|magenta|SIMPLE,(行情)url|SIMPLE|$http://quote.eastmoney.com/unify/cr/{.unifiedId}$|dim,(股吧)guba|$http://guba.eastmoney.com/interface/GetList.aspx?code={.unifiedId}$|dim'
              jsonp=ARR
            ;;
            资讯|CMS) # https://so.eastmoney.com/news/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://searchapi.eastmoney.com/bussiness/Web/GetCMSSearchList'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode "keyword=$keyword")
              curlparams+=(--data-urlencode type=8193)
              curlparams+=(--data-urlencode pageindex=${PAGE:-1})
              curlparams+=(--data-urlencode pagesize=${SIZE:-10})
              curlparams+=(--data-urlencode name=web)
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='Data:(标题)Art_Title|red|bold,(内容)Art_Content|dim,(时间)Art_CreateTime,(链接)Art_UniqueUrl|dim'
              jsonp=OBJ
            ;;
            公告|notice) # https://so.eastmoney.com/ann/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["noticeWeb"],"client":"web","clientVersion":"curr","clientType":"web","param":{"noticeWeb":{"preTag":"<em class=\"red\">","postTag":"</em>","pageSize":'${SIZE:-10}',"pageIndex":'${PAGE:-1}'}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.noticeWeb:(标题)title|red|bold,(证券)securityFullName|magenta,(内容)content|dim|tag,(时间)date|date(date),(链接)url|dim'
              jsonp=OBJ
            ;;
            研报|report) # https://so.eastmoney.com/yanbao/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["researchReport"],"client":"web","clientVersion":"curr","clientType":"web","param":{"researchReport":{"client":"web","pageSize":'${SIZE:-10}',"pageIndex":'${PAGE:-1}'}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.researchReport:(标题)title|red|bold|tag,(来源)source|dim,(证券)stockName|magenta,(内容)content|dim,(时间)date,(链接)url|$http://data.eastmoney.com/report/zw_stock.jshtml?infocode={.code}$|dim'
              jsonp=OBJ
            ;;
            文章|article) # https://so.eastmoney.com/carticle/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              local searchScope=$(ask2 -q '搜索范围' -i "$5" -d 0 -a 'ALL TITLE CONTENT' -a '全部 标题 正文')
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["article"],"client":"web","clientType":"web","clientVersion":"curr","param":{"article":{"searchScope":"'$searchScope'","sort":"DEFAULT","pageIndex":'${PAGE:-1}',"pageSize":'${SIZE:-10}',"preTag":"","postTag":""}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              # text=$(cat data/eastmoney.search.article2/2022-11-02.17:48:45.json)
              jsonp=OBJ
              jsonFormat='result.article:(标题)title|red|bold|index|tag,(内容)content|dim|tag,(作者)nickname|dim,(作者链接)authorUrl|dim,(时间)date,(链接)url|dim,(图片)listImage|image|dim'
            ;;
            股吧|guba) # https://so.eastmoney.com/tiezi/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["gubaArticleWeb"],"client":"web","clientVersion":"curr","clientType":"web","param":{"gubaArticleWeb":{"pageSize":'${SIZE:-10}',"pageIndex":'${PAGE:-1}',"postTag":"","preTag":"","sortOrder":""}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.gubaArticleWeb:(标题)title|red|bold,(短标题)shortName|dim,(内容)content|dim,(时间)createTime,(链接)url|dim'
              jsonp=OBJ
            ;;
            问董秘|wen) # https://so.eastmoney.com/qa/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["wenDongMiWeb"],"client":"web","clientVersion":"9.8","clientType":"web","param":{"wenDongMiWeb":{"webSearchScope":4,"pageindex":1,"pagesize":10,"gubaId":"","startTime":"","endTime":"","preTag":"","postTag":""}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.wenDongMiWeb:(标题)title|red|bold,(证券)stockName|${.stockName} {.gubaId}$|magenta,(内容)content|dim,(创建时间)createTime,(回复时间)responseTime,(链接)url|dim'
              jsonp=OBJ
            ;;
            博客|blog) # https://so.eastmoney.com/blog/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://searchapi.eastmoney.com/bussiness/Web/GetSearchList'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode "keyword=$keyword")
              curlparams+=(--data-urlencode type=202)
              curlparams+=(--data-urlencode pageindex=${PAGE:-1})
              curlparams+=(--data-urlencode pagesize=${SIZE:-10})
              curlparams+=(--data-urlencode name=normal)
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='Data:(标题)Title|red|bold,(时间)CreateTime,(内容)Content|dim,(作者)UserNickName,(作者链接)AuthorUrl|dim,(头像)Portrait|image|dim,(链接)Url|dim'
              jsonp=OBJ
            ;;
            组合|portfolio) # https://so.eastmoney.com/zuhe/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["portfolio"],"client":"web","clientVersion":"curr","clientType":"web","param":{"portfolio":{"pageSize":'${SIZE:-20}',"pageIndex":'${PAGE:-1}',"postTag":"","preTag":"","type":0}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.portfolio:(名称)zuheName|red|bold,(管理人)userName,(链接)url|$http://group.eastmoney.com/other,{.zhbs}.html$|dim'
              jsonp=OBJ
              # https://spoapi.eastmoney.com/app_moni_zuhe?type=app_reqs&func=search_get_zuhe_infos&plat=2&ver=web20&zuhelist=2810391,12459908,9849886,9346254,7625830,2479770,12760540,12652559,11754189,10406085,9661714,9406269,9297793,7950448,3285676,2614025,1701403,10337217,9228239,9149992&utToken=&ctToken=&cb=jQuery35109401671042551594_1667293154748&_=1667293154792
            ;;
            用户|user) # https://so.eastmoney.com/caccount/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["passportWeb"],"client":"web","clientType":"web","clientVersion":"curr","param":{"passportWeb":{"openBigV":false,"sort":"DEFAULT","pageIndex":'${PAGE:-1}',"pageSize":'${SIZE:-20}',"preTag":"","postTag":""}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.passportWeb:(名称)alias|red|bold,(介绍)introduction|dim,(自选数量)userSelectStockCount|number,(自选股被关注数)stockFollowerCount|number,(关注人数)userFollowingCount|number,(粉丝人数)fansCount|number,(发帖数量)postCount|number,(链接)url|dim,(头像)portrait|image|dim'
              jsonp=OBJ
            ;;
            百科|wiki) # https://so.eastmoney.com/baike/s?keyword=%E6%96%B0%E8%83%BD%E6%BA%90
              url='https://search-api-web.eastmoney.com/search/jsonp'
              curlparams+=(--data-urlencode cb=jQuery35109401671042551594_$(timestamp))
              curlparams+=(--data-urlencode 'param={"uid":"","keyword":"'$keyword'","type":["baikeWeb"],"client":"web","clientVersion":"curr","clientType":"web","param":{"baikeWeb":{"pageSize":'${SIZE:-10}',"pageIndex":'${PAGE:-1}',"postTag":"","preTag":""}}}')
              curlparams+=(--data-urlencode _=$(timestamp))
              jsonFormat='result.baikeWeb:(名称)encyclopediaName|red|bold,(证券)stockName|${.stockName} {.stockCode}$|magenta,(描述)description|dim,(链接)url|$https://baike.eastmoney.com/item/{.encyclopediaName}$|dim'
              jsonp=OBJ
            ;;
            建议词|suggestions)
              url='https://searchapi.eastmoney.com/api/dropdown/get'
              curlparams+=(--data-urlencode count=${SIZE:-10})
              curlparams+=(--data-urlencode cb=jQuery351042763412117835364_$(timestamp))
              curlparams+=(--data-urlencode _=$(timestamp))
              curlparams+=(--data-urlencode "input=$keyword")
              jsonFormat='|TABLE:(关键词)value|red|bold,(链接)url|$https://so.eastmoney.com/web/s?keyword={.value}$|dim'
              jsonp=ARR
            ;;
            建议|suggest) # 输入框的下拉搜索结果
              local keyword="$5"
              url='https://searchapi.eastmoney.com/api/suggest/get'
              curlparams+=(--data-urlencode cb=jQuery1124007392431488856332_$(timestamp))
              curlparams+=(--data-urlencode input=$keyword)
              curlparams+=(--data-urlencode token=D43BF722C8E33BDC906FB84D85E326E8)
              curlparams+=(--data-urlencode markettype=)
              curlparams+=(--data-urlencode mktnum=)
              curlparams+=(--data-urlencode jys=)
              curlparams+=(--data-urlencode classify=)
              curlparams+=(--data-urlencode securitytype=)
              curlparams+=(--data-urlencode status=)
              curlparams+=(--data-urlencode count=${SIZE:-20})
              curlparams+=(--data-urlencode _=$(timestamp))
              local marketTypes=(1 沪A 2 深A 5 指数 _TB 三板 7 美股 8 基金 9 板块)
              local _type
              case $4 in
                证券|代码|QuotationCodeTable|code)
                  _type=14
                  jsonFormat='QuotationCodeTable.Data|TABLE:(股票名称)Name|red|bold,(代码)UnifiedCode|magenta,(市场)SecurityTypeName,(市场2)JYS,(拼音)PinYin|red,(链接)QuoteID|$http://quote.eastmoney.com/unify/r/{.QuoteID}$|dim'
                ;;
                股吧|GubaCodeTable|guba)
                  _type=8
                  jsonFormat='GubaCodeTable.Data|TABLE:(股吧名称)ShortName|red|bold,(关联代码)RelatedCode|magenta,(链接)Url|dim'
                ;;
                专题|CMSTopic|topic)
                  _type=16
                  jsonFormat='CMSTopic.Data|TABLE:(专题名称)Topic_Name,(链接)Topic_PinYin|$http://topic.eastmoney.com/{.Topic_PinYin}/$'
                ;;
                主题|CategoryInvestment|category)
                  _type=43
                  jsonFormat='CategoryInvestment.Data|TABLE:(主题)CategoryName|red|bold,(链接)url|$http://quote.eastmoney.com/zhuti/topic/{.CategoryCode}$|dim'
                ;;
                数据|DataCenter|data)
                  _type=38
                  jsonFormat='DataCenter.Data|TABLE:(数据名称)Name|red|bold,(链接)PageUrl|dim'
                ;;
                财富账号|FortuneAccount|account)
                  _type=35
                  jsonFormat='FortuneAccount.Data|TABLE:'
                ;;
                话题|GubaTopic)
                  _type=501
                  jsonFormat='GubaTopic.Data|TABLE:(话题名称)Name|red|bold,(链接)Id|$http://gubatopic.eastmoney.com/topic_v3.html?htid={.Id}$|dim'
                ;;
                百科|NewEncyclopedia|wiki)
                  _type=2
                  jsonFormat='NewEncyclopedia.Data|TABLE:(词条名称)EncyclopediaName|red|bold,(链接)Url|$http://baike.eastmoney.com/item/{.EncyclopediaName}$|dim'
                ;;
                用户|Passport)
                  _type=7
                  jsonFormat='Passport.Data|TABLE:(用户名称)ualias|red|bold,(链接)url|dim'
                ;;
                组合|Portfolio)
                  _type=3
                  jsonFormat='Portfolio.Data|TABLE:(组合名称)zuheName|red|bold,(链接)url|dim'
                ;;
              esac
              if [[ -n $_type ]]; then
                curlparams+=(--data-urlencode type=$_type)
                jsonp=OBJ
              fi
            ;;
          esac
        ;;
        热门|hot)
          outputfile=$outputfile.$3
          url='https://searchapi.eastmoney.com/api/HotKeyword/Get'
          curlparams+=(--data-urlencode cb=jQuery183047650049523235927_$(timestamp))
          curlparams+=(--data-urlencode count=${SIZE:-30})
          curlparams+=(--data-urlencode token=1D50F6FB3B72F7D5F478A23B9BE911DB)
          curlparams+=(--data-urlencode _=$(timestamp))
          case $3 in
            搜索|search)
              jsonFormat='Data|TABLE:(关键词)KeyPhrase|red|bold,(链接)JumpAddress|dim'
              jsonp=OBJ
            ;;
            个股|guba) # http://guba.eastmoney.com/remenba.aspx?type=1
              curlparams+=(--data-urlencode tag=2)
              jsonFormat='Data|TABLE:(名称)Name|red|bold,(代码)Code,(链接)JumpAddress|dim'
              jsonp=OBJ
            ;;
          esac
        ;;
        新股数据|xg) # https://data.eastmoney.com/xg/
          url="https://datacenter-web.eastmoney.com/api/data/v1/get"
          curlparams=(-G)
          curlparams+=(--data-urlencode callback=jQuery112305747392010999344_$(date +%s))
          curlparams+=(--data-urlencode pageSize=${SIZE:-50})
          curlparams+=(--data-urlencode pageNumber=${PAGE:-1})
          curlparams+=(--data-urlencode source=WEB)
          curlparams+=(--data-urlencode client=WEB)
          curlparams+=(--data-urlencode columns=ALL)
          outputfile=$outputfile.$3
          case $3 in
            新股申购|xg) # https://data.eastmoney.com/xg/xg/default.html
              local apply_date=$(question2 -q '申购日期' -d "$_today" -i "$4" )
              curlparams+=(--data-urlencode sortColumns=APPLY_DATE,SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=1,-1)
              curlparams+=(--data-urlencode reportName=RPTA_APP_IPOAPPLY)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE~NEWEST_PRICE)
              curlparams+=(-d quoteType=0)
              curlparams+=(--data-urlencode filter="(APPLY_DATE>'$apply_date')")

              jsonFormat='result.data|reverse:(证券名称)SECURITY_NAME|red|bold|index|SIMPLE,(证券代码)SECURITY_CODE|SIMPLE,(发行价（元）)ISSUE_PRICE|magenta|SIMPLE,(发行数量（万股）)ISSUE_NUM|magenta|SIMPLE,(连续一字板数量)CONTINUOUS_1WORD_NUM|magenta,(涨幅)TOTAL_CHANGE,(中签获利)PROFIT|number,(预测发行价（元）)PREDICT_ISSUE_PRICE|${.PREDICT_ISSUE_PRICE} {.PREDICT_ISSUE_PRICE1} {.PREDICT_ISSUE_PRICE2}$,(市盈率)AFTER_ISSUE_PE,(发行市盈率)AFTER_ISSUE_PE|SIMPLE,(行业市盈率)INDUSTRY_PE_NEW|SIMPLE,(预测发行市盈率)PREDICT_ISSUE_PE,(预测市盈率)PREDICT_PE,(申购日期)APPLY_DATE|date(date)|SIMPLE,(上市日期)LISTING_DATE|date(date)|magenta,(主营业务)MAIN_BUSINESS|white|dim|SIMPLE,(链接)url|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)info_url|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
            IPO审核|ipo) # https://data.eastmoney.com/xg/ipo
              curlparams+=(--data-urlencode sortColumns=UPDATE_DATE,ORG_CODE)
              curlparams+=(--data-urlencode sortTypes=-1,-1)
              curlparams+=(--data-urlencode reportName=RPT_IPO_INFOALLNEW)
              local market=$(ask2 -i "$4" -d 0 -q '（拟）上市板块' -a "科创板 创业板 上海主板 深圳主板 北交所")
              [[ $market ]] && curlparams+=(--data-urlencode filter="(PREDICT_LISTING_MARKET=\"$market\")")

              jsonFormat='result.data:(企业名称)DECLARE_ORG|red|bold|index|SIMPLE,(行业)CSRC_INDUSTRY|white|dim|SIMPLE,(拟上市板块)PREDICT_LISTING_MARKET|cyan|SIMPLE,(状态)STATE|magenta|SIMPLE,(更新日期)UPDATE_DATE|date(date),(受理日期)ACCEPT_DATE|date(date),(链接)SECURITY_CODE|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim|SIMPLE'
            ;;
            打新收益|dxsy) # https://data.eastmoney.com/xg/xg/dxsyl.html
              curlparams+=(--data-urlencode sortColumns=LISTING_DATE,SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=-1,-1)
              curlparams+=(--data-urlencode reportName=RPTA_APP_IPOAPPLY)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE,f14~01~SECURITY_CODE)
              curlparams+=(--data-urlencode quoteType=0)
              curlparams+=(--data-urlencode filter="((APPLY_DATE>'2010-01-01')(|@APPLY_DATE=\"NULL\"))((LISTING_DATE>'2010-01-01')(|@LISTING_DATE=\"NULL\"))(TRADE_MARKET_CODE!=\"069001017\")")

              jsonFormat='result.data:(证券名称)SECURITY_NAME|red|bold|index|SIMPLE,(证券代码)SECURITY_CODE,(开盘溢价)LD_OPEN_PREMIUM|true|number(+)|format(%)|indicator,(首日最高)LD_HIGH_CHANG|true|number(+)|format(%)|indicator|SIMPLE,(首日收盘)LD_CLOSE_CHANGE|true|number(+)|format(%)|indicator|SIMPLE,(上市日期)LISTING_DATE|date(date)|SIMPLE,(行业)INDUSTRY_NAME|white|dim|SIMPLE,(主营业务)MAIN_BUSINESS|white|dim|SIMPLE,(链接)SECURITY_CODE|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
            增发|qbzf) #
              curlparams+=(--data-urlencode sortColumns=ISSUE_DATE)
              curlparams+=(--data-urlencode sortTypes=-1)
              curlparams+=(--data-urlencode reportName=RPT_SEO_DETAIL)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE~NEW_PRICE)
              curlparams+=(--data-urlencode quoteType=0)

              jsonFormat='result.data:(证券名称)SECURITY_NAME_ABBR|${.SECURITY_NAME_ABBR} {.SECURITY_CODE}$|red|bold|index,(主营业务)MAIN_BUSINESS|white|dim,(增发方式)ISSUE_WAY|magenta,(增发用途)FUND_FOR|magenta|dim,(增发数量)ISSUE_NUM|number(cn),(增发价格)ISSUE_PRICE,(增发上市日期)ISSUE_ON_DATE,(链接)SECURITY_CODE|$https://data.eastmoney.com/stockdata/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
          esac
          jsonp=OBJ
        ;;
        财经日历|cjrl) # https://data.eastmoney.com/cjrl/default.html
          outputfile=$outputfile.$3
          url='https://datacenter-web.eastmoney.com/api/data/v1/get'
          jsonp=OBJ
          curlparams+=(-d callback=datatable$(date +%s))
          curlparams+=(-d pageSize=${SIZE:-50})
          curlparams+=(-d pageNumber=${PAGE:-1})
          curlparams+=(-d source=WEB)
          curlparams+=(-d client=WEB)
          curlparams+=(-d reportName=RPT_CPH_FECALENDAR)
          curlparams+=(-d sortColumns=START_DATE)
          curlparams+=(-d sortTypes=1)
          curlparams+=(--data-urlencode columns=ALL)
          curlparams+=(-d _=$(timestamp))
          local today=$(question '请输入开始日期（默认为今天）：' $4)
          today=${today:-$(date +%Y-%m-%d)}
          local end_date=$(question '请输入结束日期（默认为一个月后）：' $5)
          end_date=${end_date:-$(date -v+1m +%Y-%m-%d)}
          case $3 in
            财经会议|cjhy) # https://data.eastmoney.com/cjrl/default.html
              curlparams+=(--data-urlencode "filter=(END_DATE>='$today')(START_DATE<'$end_date')(STD_TYPE_CODE=\"1\")")
              jsonFormat='result.data|reverse:(会议名称)FE_NAME|red|bold|index,(会议类型)FE_TYPE|magenta,(主办单位)SPONSOR_NAME,(开始时间)START_DATE,(结束时间)END_DATE,(会议地点)CITY,(会议内容)CONTENT|white|dim'
            ;;
            经济数据|jjsj) # https://data.eastmoney.com/cjrl/default.html
              curlparams+=(--data-urlencode "filter=(END_DATE>='$today')(START_DATE<'$end_date')(STD_TYPE_CODE=\"2\")")
              jsonFormat='result.data|reverse:(数据名称)FE_NAME|red|bold|index,(数据类型)FE_TYPE|magenta,(公布时间)START_DATE,(地区)CITY'
            ;;
            其他日程|qtrc) # https://data.eastmoney.com/cjrl/default.html
              curlparams+=(--data-urlencode "filter=(END_DATE>='$today')(START_DATE<'$end_date')(STD_TYPE_CODE=\"3\")")
              jsonFormat='result.data|reverse:(名称)FE_NAME|red|bold|index,(时间)START_DATE'
            ;;
          esac
        ;;
        股市日历|gsrl)
          outputfile=$outputfile.$3
          url='https://datacenter-web.eastmoney.com/api/data/v1/get'
          jsonp=OBJ
          curlparams+=(-d callback=jQuery1123015335331911826122_$(timestamp))
          curlparams+=(-d pageSize=${SIZE:-50})
          curlparams+=(-d pageNumber=${PAGE:-1})
          curlparams+=(-d source=WEB)
          curlparams+=(-d client=WEB)
          curlparams+=(--data-urlencode columns=ALL)
          curlparams+=(-d _=$(timestamp))
          case $3 in
            公司动态|gsdt) # https://data.eastmoney.com/gsrl/gsdt.html
              local type=$(ask2 -q '分类' -i "$4" -d 0 -a 'RPT_ORGOP_ALL RPT_ORGOP_REORGANIZATION RPT_ORGOP_ACQUISITION RPT_ORGOP_GUARANTEE RPT_ORGOP_EQUITYPLEDGE' -a '全部 资产重组 资产收购 对外担保 股份质押')
              curlparams+=(--data-urlencode sortColumns=SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=1)
              curlparams+=(--data-urlencode reportName=$type)
              local trade_date="$(question2 -q '日期' -d "$_today" -i "$5")"
              curlparams+=(--data-urlencode "filter=(TRADE_DATE='$trade_date')")
              jsonFormat='result.data:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(事件类型)EVENT_TYPE|magenta,(内容)EVENT_CONTENT|white|dim,(时间)TRADE_DATE,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$|dim'
            ;;
            股东大会|gddh) # https://data.eastmoney.com/gsrl/gddh.html
              local all_date="$(question2 -q '日期' -d "$_today" -i "$4")"
              curlparams+=(--data-urlencode sortColumns=SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=1)
              curlparams+=(--data-urlencode reportName=RPT_CALENDER_HOLDERSMEETING_HOLDERS)
              curlparams+=(--data-urlencode "filter=(SHARE_REGIST_DATE='$all_date')(|START_DATE='$all_date')(|END_DATE='$all_date')(|VOTE_START_DATE='$all_date')(|VOTE_END_DATE='$all_date')(|DECISION_DATE='$all_date')(|REDGIST_DATE='$all_date')(|UPDATE_DATE='$all_date')")
              jsonFormat='result.data:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(名称)ORG_NAME|magenta,(公告日)UPDATE_DATE,(决议日)DECISION_DATE,(召开日)START_DATE|${.START_DATE} ~ {.END_DATE}$|SIMPLE,(投票日)VOTE_START_DATE|${.VOTE_START_DATE} ~ {.VOTE_END_DATE}$|SIMPLE,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$|dim'
            ;;
            股份上市|gfss) # https://data.eastmoney.com/gsrl/gfss.html
              local all_date="$(question2 -q '日期' -d "$_today" -i "$4")"
              curlparams+=(--data-urlencode sortColumns=SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=1)
              curlparams+=(--data-urlencode reportName=RPT_CALENDER_LISTEDSHARE)
              curlparams+=(--data-urlencode "filter=(NOTICE_DATE='$all_date')(|LISTING_DATE='$all_date')")
              jsonFormat='result.data:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(变动原因)CHANGE_REASON_TYPE|magenta,(公告日)NOTICE_DATE|date(date),(上市日)LISTING_DATE,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$|dim'
            ;;
            增发配股|zfpg) # https://data.eastmoney.com/gsrl/zfpg.html
              outputfile="$outputfile.$4"
              curlparams+=(--data-urlencode sortColumns=SECUCODE)
              curlparams+=(--data-urlencode sortTypes=1)
              curlparams+=(--data-urlencode quoteColumns=f2)
              local all_date="$(question2 -q '日期' -d "$_today" -i "$5")"
              case $4 in
                全部|all)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_ALL)
                  curlparams+=(--data-urlencode "filter=(UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(证券)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(增发类型)EVENT_TYPE|magenta|SIMPLE,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$|dim|SIMPLE'
                ;;
                增发预案|zfya)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_INCRASEPLAN)
                  curlparams+=(--data-urlencode "filter=(LEADERS_PUBLISH_DATE='$all_date')(|HOLDERS_DECISION_DATE='$all_date')(|SEO_REG_DATE='$all_date')")
                  jsonFormat='result.data:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(方案进度)APPROVE_PROCESS|magenta|SIMPLE,(最新价（元）)f2,(预计增发价)PRICE_PRINCIPLE|dim|SIMPLE,(公告日期)UPDATE_DATE|date(date),(预案公告日)LEADERS_PUBLISH_DATE|date(date),(发行规模（万股）)ISSUE_NUM_UPPER|number,(预计募集资金（万元）)FINANCE_AMT_UPPER|SIMPLE'
                ;;
                定向增发|dxzf)
                  curlparams+=(--data-urlencode reportName=PRT_CALENDER_INCREASE_DIRECTIONAL)
                  curlparams+=(--data-urlencode "filter=(SEO_LISTING_DATE='$all_date')(|PUBLISH_DATE='$all_date')(|UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(证券)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(最新价（元）)f2,(增发价（元）)ISSUE_PRICE|indicator({.f2}),(折价)discount|discount({.f2},{.ISSUE_PRICE})|indicator|SIMPLE,(募集资金（万元）)NET_RAISE_FUNDS,(增发对象)ISSUE_OBJECT|SIMPLE'
                ;;
                公开增发|gkzf)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_PUBLIC)
                  curlparams+=(--data-urlencode "filter=(EQUITY_RECORD_DATE='$all_date')(|ONLINE_ISSUE_DATE='$all_date')(|RECEIVE_DATE='$all_date')(|SEO_LISTING_DATE='$all_date')(|EX_DIVIDEND_DATE='$all_date')(|PUBLISH_DATE='$all_date')(|UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(证券)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(最新价（元）)f2,(增发价（元）)ISSUE_PRICE|indicator({.f2}),(折价)discount|discount({.f2},{.ISSUE_PRICE})|indicator|SIMPLE,(实际募集资金（万元）)NET_RAISE_FUNDS,(网上发行日)ONLINE_ISSUE_DATE|date(date)|SIMPLE,(增发股上市日)PUBLISH_DATE|date(date)|SIMPLE,(公告日期)UPDATE_DATE|date(date)'
                ;;
                配股实施|pgss)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_EXECUTE)
                  curlparams+=(--data-urlencode "filter=(REGISTER_DATE='$all_date')(|PAYSTART_DATE='$all_date')(|PAYEND_DATE='$all_date')(|DIVBASE_DATE='$all_date')(|LISTINGPUBLISH_DATE='$all_date')(|LISTING_DATE='$all_date')(|UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(最新价（元）)f2,(配股价格（元）)ISSUE_PRICE|magenta,(折价)discount|discount({.f2},{.ISSUE_PRICE})|indicator|SIMPLE,(配股比例)PLACING_RATIO|SIMPLE,(配股数量)ISSUE_NUM|number(cn),(股权登记日)REGISTER_DATE|date(date)|SIMPLE,(缴款截止日)PAYEND_DATE|date(date)|SIMPLE'
                ;;
                配股预案|pgya)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_RATIONEDPLAN)
                  curlparams+=(--data-urlencode "filter=(DIRECTORS_DATE='$all_date')(|HOLDERS_DECISION_DATE='$all_date')(|HOLDERS_PROVED_DATE='$all_date')")
                  jsonFormat=''
                ;;
                其他发行|qtfx)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_INCREASE_OTHERISSUE)
                  curlparams+=(--data-urlencode "filter=(SEO_LISTING_DATE='$all_date')(|PUBLISH_DATE='$all_date')(|UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(最新价（元）)f2,(发行价（元）)EXERCISE_PRICE,(折价)discount|discount({.f2},{.EXERCISE_PRICE})|indicator|SIMPLE,(公告日期)UPDATE_DATE|date(date),(增发股上市日)SEO_LISTING_DATE|date(date)|SIMPLE,(上市公告日)PUBLISH_DATE|date(date),发行数量（万股）)INCENTIVE_SHARES|SIMPLE,(实际募集资金（万元）)NET_RAISE_FUNDS,(发行对象)ISSUE_OBJECT|SIMPLE'
                ;;
              esac
            ;;
            年报季报|nbjb) # https://data.eastmoney.com/gsrl/nbjb.html
              # local type=$(ask2 -q '分类' -i "$4" -d 0\
              # -a 'RPT_CALENDER_YEARQUARTER_ALL RPT_CALENDER_YEARQUARTER_REPORT RPT_CALENDER_YEARQUARTER_FASTREPORT RPT_CALENDER_YEARQUARTER_PREREPOR RPT_CALENDER_YEARQUARTER_ASSIGNSCHEME'\
              # -a '全部 资产重组 资产收购 对外担保 股份质押')
              curlparams+=(--data-urlencode sortColumns=SECUCODE)
              curlparams+=(--data-urlencode sortTypes=1)
              local all_date="$(question2 -q '日期' -d "$_today" -i "$5")"
              outputfile="$outputfile.$4"
              case $4 in
                全部|all)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_YEARQUARTER_ALL)
                  curlparams+=(--data-urlencode "filter=(UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(事件名称)CONTENT,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$'
                ;;
                业绩报表|yjbb)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_YEARQUARTER_REPORT)
                  curlparams+=(--data-urlencode "filter=(UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(事件名称)CONTENT,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$'
                ;;
                业绩快报|yjkb)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_YEARQUARTER_FASTREPORT)
                  curlparams+=(--data-urlencode "filter=(UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(事件名称)CONTENT,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$'
                ;;
                业绩预告|yjyg)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_YEARQUARTER_PREREPOR)
                  curlparams+=(--data-urlencode "filter=(UPDATE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(事件名称)CONTENT,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$'
                ;;
                分红转增|fhzz)
                  curlparams+=(--data-urlencode reportName=RPT_CALENDER_YEARQUARTER_ASSIGNSCHEME)
                  curlparams+=(--data-urlencode "filter=(LEADERS_PUBLISH_DATE='$all_date')(|HOLDERS_PUBLISH_DATE='$all_date')(|EQUITY_RECORD_DATE='$all_date')(|EX_DIVIDEND_DATE='$all_date')(|PAY_CASH_DATE='$all_date')(|EXECUTE_DATE='$all_date')")
                  jsonFormat='result.data|TABLE:(股票)SECURITY_NAME_ABBR|${.SECURITY_CODE} {.SECURITY_NAME_ABBR}$|red|bold,(方案进度)ASSIGN_PROGRESS|magenta,(实施方案)EXECUTE_CONTENT|magenta|SIMPLE,(股东大会预案)HOLDERS_PUBLISH_CONTENT,(股东大会预案日)HOLDERS_PUBLISH_DATE|date(date),(股权登记日)EQUITY_RECORD_DATE|date(date),(除权除息日)EX_DIVIDEND_DATE|date(date),(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$'
                ;;
              esac
            ;;
            停复牌提示|tfp) # https://data.eastmoney.com/gsrl/tfpts.html
              local all_date=$(question2 -i "$4" -d "$_today" -q '日期')
              curlparams+=(--data-urlencode sortColumns=SUSPEND_START_DATE)
              curlparams+=(--data-urlencode sortTypes=-1)
              curlparams+=(--data-urlencode reportName=RPT_CUSTOM_SUSPEND_DATA_INTERFACE)
              curlparams+=(--data-urlencode "filter=(MARKET=\"全部\")(DATETIME='$all_date')")
              jsonFormat='result.data|TABLE:(证券名称)SECURITY_NAME_ABBR|red|bold,(代码)SECURITY_CODE,(停牌时间)SUSPEND_START_DATE|date(date),(预计复牌时间)PREDICT_RESUME_DATE|date(date),(停牌期限)SUSPEND_EXPIRE,(停牌原因)SUSPEND_REASON|magenta,(链接)url|$https://data.eastmoney.com/notices/stock/{.SECURITY_CODE}.html$|dim'
            ;;
            公告摘要|ggzy) # https://data.eastmoney.com/gsrl/ggzy.html
              local date_range=($(ask_date_range $_today $_today))
              curlparams+=(--data-urlencode sortTypes=-1)
              curlparams+=(--data-urlencode reportName=RPT_CUSTOM_CALENDAR_NOTICE)
              curlparams+=(--data-urlencode "filter=(request=\"websiteSearch\")(type=7)(startDate='${date_range:0:1}')(endDate='${date_range:1:1}')")
              jsonFormat='result.data:(证券名称)secuName|red|bold,(链接)url|$https://data.eastmoney.com/notices/stock/{.secuFullCode|slice(0,6)}.html$'
            ;;
            *) unknown 3 "$@";;
          esac
        ;;
      esac
    ;;
  esac
  if [[ ! $text ]]; then
    case $jsonp in
      OBJ)
        text=$(curl -v $url "${curlparams[@]}" 2>curl.log | grep -o '{.*}')
        ;;
      ARR)
        text=$(curl -v $url "${curlparams[@]}" 2>curl.log | grep -o '\[.*\]')
        ;;
      *)
      ;;
    esac
  fi
  if [[ -z "$text" && -z "$url" ]]; then
    echo "没有地址或数据" 1>&2; exit 1;
  fi
  print_json -u "$url" -s "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat" -q "$(encode_array "${curlparams[@]}")" -o "$outputfile" -y "${filters[*]}"

  debug "$tailer"
  if [[ $tailer ]]; then
    eval $tailer
  fi
}

function check_trading_time() {
  h=$(date +%H)
  m=$(date +%M)
  [[ $h > 9 && $h < 11 ]] && return 0
  [[ $h > 12 && $h < 15 ]] && return 0
  [[ $h = 9 && $m > 14 ]] && return 0
  [[ $h = 11 && $m < 31 ]] && return 0
  return 1
}

declare -a args=()

for op in "$@"; do
  [[ $op == '-t' ]] && TABLE=1 || [[ $op == '-s' ]] && SIMPLE=1 || args+=("$op")
  [[ $op == '-h' ]] && HELP=1
done

help "${args[@]}"

if [[ $HELP ]]; then
echo -e '\033[33;2m环境参数: \033[0m\033[2mSIMPLE, TABLE, TRADING, LOOP, SIZE, PAGE, SHOULD_STORE, DEBUG_LOCAL\033[0m'
echo -e '\033[31;2m概念排行: \033[0m\033[2mSIMPLE=1 resou.sh em quote rank f3 27 n\033[0m'
echo -e '\033[31;2m板块资金: \033[0m\033[2mLOOP=5 resou.sh em quote bkzj\033[0m'
echo -e '\033[31;2m个股异动: \033[0m\033[2mLOOP=5 SIMPLE=1 resou.sh em quote pkyd ALL\033[0m'
echo -e '\033[31;2m板块异动: \033[0m\033[2mLOOP=5 SIMPLE=1 resou.sh em quote bkyd ALL\033[0m'
echo -e '\033[31;2m强势股池: \033[0m\033[2mresou.sh em quote qsgc\033[0m'
echo -e '\033[31;2m涨停股池: \033[0m\033[2mresou.sh em quote ztgc\033[0m'
echo -e '\033[31;2m炸板股池: \033[0m\033[2mresou.sh em quote zbgc\033[0m'
echo -e '\033[31;2m次新股池: \033[0m\033[2mresou.sh em quote cxgc\033[0m'
else
  json_res "${args[@]}"
  echo -e "\033];{TRADING=$TRADING LOOP=$LOOP ${args[@]}}\007"
  if [[ $LOOP ]]; then
    while true; do
      check_trading_time
      [[ $TRADING && $? -eq 1 ]] && continue
      output="$(json_res "${args[@]}" 2>/dev/null)"
      echo -e '\033[2J\033[3J\033[1;1H'
      date '+%H:%M:%S'
      echo -e "$output"
      sleep ${LOOP:-1}
    done
  fi
fi

# console.log([...new URL().searchParams.entries()].map(e => `curlparams+=(--data-urlencode ${e[0]}=${e[1]})`).join('\n'))

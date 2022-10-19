#! /usr/bin/env bash

source `dirname $0`/lib.sh

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
      printf '搜索: %b\n' "\033[31m${urls[@]:$i:1}\033[0m" 1>&2
      echo "${urls[@]:$((i+2)):1}"
      echo
      exit 0
    fi
  done
  )
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
  local values=($1)
  local value="$2"
  for i in "${!values[@]}"; do
    if [[ $value = $i || $value = ${values[@]:$i:1} ]]; then
      printf '值: %b\n' "\033[31m${values[@]:$i:1}\033[0m" 1>&2
      _ASK_RESULT=${values[@]:$i:1}
      _ASK_INDEX=$i
      return
    fi
  done
  for i in "${!values[@]}"; do
    printf '%b %b	' "\033[31m$i\033[0m" "\033[32m${values[@]:$i:1}\033[0m" 1>&2
  done
  read -p $'\n输入值：'
  local revoke=$(shopt -p nocasematch)
  shopt -s nocasematch
  for i in "${!values[@]}"; do
    if [[ "$REPLY" = $i  || "$REPLY" = "${values[@]:$i:1}" ]]; then
      printf '值: %b\n' "\033[31m${values[@]:$i:1}\033[0m" 1>&2
      _ASK_RESULT="${values[@]:$i:1}"
      _ASK_INDEX=$i
      debug $_ASK_RESULT
      break
    fi
  done
  eval $revoke
}

function question() {
  local msg="$1"
  local default="$2"
  if [[ $PROGRESS ]]; then
    read -p $'\033[33m'"【默认值："$default"】"$1$'\033[0m\033[31m'
    debug $REPLY
    [[ -z $REPLY ]] && echo $default || echo $REPLY
  else
    echo $default
  fi
}

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
# 用户微博 https://weibo.com/u/2209943702
WEIBO_USER_POSTS_URL='https://weibo.com/ajax/statuses/mymblog?uid={uid}&page={page}&feature=0'
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

function json_res() {
  local url
  local text
  local -a aliases
  local -a fields
  local -a patterns
  local -a indexes
  local -a transformers
  local -a types
  local jsonFormat
  local curlparams
  case $1 in
    # 微博
    weibo|wb)
      case $2 in
        groups|gps)
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
        hotpost|hp)
          local group=($(json_res wb groups $3))
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
          jsonFormat='statuses:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{statuses:user.idstr}$,(链接)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
        ;;
        userpost|up)
          uid="$3"
          page=${4:-1}
          url="$WEIBO_USER_POSTS_URL"
          url="${url//\{uid\}/$uid}"
          url="${url//\{page\}/$page}"
          curlparams=('-b' "$WEIBO_COOKIE")
          aliases=('内容' '来源' '博主' '空间' 'mid' '链接' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat='data.list:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{data.list:user.idstr}$,(链接)mblogid|$https://weibo.com/{data.list:user.idstr}/{data.list:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
        ;;
        hottopic|ht)
          url="$WEIBO_TOPIC_URL"
          aliases=('标签' '内容' '分类' '阅读量' '讨论' '链接')
          fields=('topic' 'summary' 'category' 'read' 'mention' 'mid')
          patterns=('"topic":"[^"]*"' '"summary":"[^"]*"'  '"category":"[^"]*"' '"read":[^,]*,' '"mention":[^,]*,' '"mid":"[^"]"*')
          indexes=(4 4 4 3 3 4)
          transformers=('_' '_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.statuses:(标签)topic|red|bold|index,(内容)summary|white|dim,(分类)category,(阅读量)read|number,(讨论数)mention|number,(链接)mid|$https://s.weibo.com/weibo?q=%23{data.statuses:mid}%23$,(图片)images_url|image'
        ;;
        hotsearch|hs)
          url="$WEIBO_HOT_SEARCH_URL";
          aliases=('标题' '分类' '热度' '原始热度' '链接')
          fields=('word' 'category' 'num' 'raw_hot' 'note')
          patterns=('_' '"(category|ad_type)":"[^"]*"' '"num":[^,]*,' '"raw_hot":[^,]*,' '_')
          indexes=(4 4 3 3 4)
          transformers=('_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.band_list:(标题)word|red|bold|index,(分类)category,(热度)num|number,(原始热度)raw_hot|number,(链接)note|$https://s.weibo.com/weibo?q=%23{data.band_list:word}%23$'
        ;;
        post|ps)
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
          jsonFormat=':(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{:user.idstr}$,(链接)mblogid|$https://weibo.com/{:user.idstr}/{:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
        ;;
        comment|cm)
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
        *) return;;
      esac
    ;;
    # 知乎
    zhihu|zh)
      case ${2:-hot} in
        hot|ht)
          # https://www.zhihu.com/knowledge-plan/hot-question/hot/0/hour
          url='https://www.zhihu.com/api/v4/creators/rank/hot?domain={domain}&period={period}&limit=50'
          fields=(title link)
          aliases=(标题 链接)
          patterns=('"title":"[^"]*"' '"url":"[^"]*"')
          indexes=(4 4)
          jsonFormat='data:(标题)question.title|red|bold|index,(链接)question.url,(时间)question.created|date,(标签)question.topics*.name'
          case $3 in
            day)
              url=${url//\{period\}/day}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            week)
              url=${url//\{period\}/week}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            hot|ht|hour)
              url=${url//\{period\}/hour}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            *)
              url=${url//\{period\}/hour}
              ask "${ZHIHU_DOMAINS[*]}" "$3"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
          esac
        ;;
        hotsearch|hs|billboard|bb)
          url='https://www.zhihu.com/billboard'
          text=$(curl -s "$url" | grep -oE '<script id="js-initialData" type="text/json">.*<\/script>' | sed -nE 's/<script[^>]*>//;s/<\/script>.*//p')
          aliases=(标题 描述 热度 链接 图片)
          fields=('title' 'excerpt' 'metricsArea' 'link' 'image')
          patterns=('"titleArea":{"text":"[^"]*"' '"excerptArea":{"text":"[^"]*"' '"metricsArea":{"text":"[^"]*"' '"link":{"url":"[^"]*"' '"imageArea":{"url":"[^"]*"')
          indexes=(6 6 6 6 6)
          jsonFormat="initialState.topstory.hotList:(标题)target.titleArea.text|red|bold|index,(描述)target.excerptArea.text|white|dim,(热度)target.metricsArea.text|magenta,(链接)target.link.url,(图片)target.imageArea.url|image"
        ;;
      esac
    ;;
    # 百度
    baidu|bd)
      case ${2:-hotsearch} in
        hotsearch|hs)
          url="https://top.baidu.com/board"
          case ${3:-realtime} in
            realtime|rt)
              url="$url?tab=realtime"
            ;;
            novel|nv)
              url="$url?tab=novel"
              ask "全部类型 都市 玄幻 奇幻 历史 科幻 军事 游戏 武侠 现代言情 古代言情 幻想言情 青春" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            movie|mv)
              url="$url?tab=movie"
              ask "全部类型 爱情 喜剧 动作 剧情 科幻 恐怖 动画 惊悚 犯罪" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国香港 中国台湾 欧美 日本 韩国" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            teleplay|tv)
              url="$url?tab=teleplay"
              ask "全部类型 爱情 搞笑 悬疑 古装 犯罪 动作 恐怖 科幻 剧情 都市" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国台湾 中国香港 欧美 韩国 日本" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            car)
              url="$url?tab=car"
              ask "全部 轿车 SUV 新能源 跑车 MPV" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            game)
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
          jsonFormat='data.cards.0.content:(关键词)word|red|bold|index,(描述)desc|white|dim,(链接)rawUrl,(图片)img|image'
        ;;
      esac
    ;;
    # 头条
    toutiao|tt)
      fields=(title link)
      aliases=(标题 链接)
      case ${2:-hot} in
        hot|ht)
          url='https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc';
          patterns=('"Title":"[^"]*"' '"Url":"[^"]*"');
          indexes=(4 4)
          jsonFormat='data:(标题)Title|red|bold|index,(链接)Url,(图片)Image.url_list*.url|image'
        ;;
        hotsearch|hs)
          url='https://tsearch.snssdk.com/search/suggest/hot_words/';
          patterns=('"query":"[^"]*"' '"query":"[^"]*"');
          indexes=(4 4);
          transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title')
          jsonFormat='data:(标题)query|red|bold|index,(链接)query|$https://so.toutiao.com/search?dvpf=pc&source=trending_card&keyword={data:query}$'
        ;;
      esac
    ;;
    # bilibili
    bilibili|bb)
      aliases=(标题 作者 分类 浏览 点赞 链接 描述 图片)
      fields=(title name tname view like short_link desc pic)
      patterns=(_ _ _ '"view":[^,]*,' '"like":[^,]*,' _ _ _)
      indexes=(4 4 4 3 3 4 4 4)
      transformers=(_ _ _ _ _ _ _ '${values[@]:7:1}@412w_232h_1c.jpg')
      types=(_ _ _ _ _ _ _ img)
      jsonFormat='data.list:(标题)title|red|bold|index,(描述)desc|white|dim,(作者)owner.name,(分类)tname,(浏览)stat.view|number,(点赞)stat.like|number,(链接)short_link,(图片)pic|image,(发布时间)pubdate|date'
      case $2 in
        hot|ht)
          url='https://api.bilibili.com/x/web-interface/popular?ps=20&pn=1'
        ;;
        week|wk)
          local week=$3
          if [[ $week = 0 ]]; then
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
          jsonFormat=''
        ;;
      esac
    ;;
    # sogou
    sogou|sg)
      case ${2:-hotsearch} in
        hotsearch|hs)
          url="https://go.ie.sogou.com/hot_ranks?callback=jQuery112403809296729897269_1666168486497&h=0&r=0&v=0&_=$(date +%s)"
          text=$(curl -s "$url" | grep -oE '{.*}')
          # text=$(cat sogou.hot.json)
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
    sina)
      case ${2:-rank} in
        rank)
          # https://news.sina.com.cn/hotnews/
          url='https://top.news.sina.com.cn/ws/GetTopDataList.php?top_type={type}&top_cat={category}&top_time={date}&top_show_num={count}&top_order=DESC&js_var=channel_'
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
          local category=$3
          ask "$(selectColumns "${categories[*]}" 1)" $category
          category=${categories[@]:$((ASK_INDEX+1)):1}
          debug $category
          url=${url//\{category\}/$category}
          local date=$(question "输入排行榜时间：" "${4:-$(date '+%Y%m%d')}")
          url=${url//\{date\}/$date}
          local type=$(question "输入排行榜类型（可选值：day/week/month，分别代表日/周/月排行榜）：" "${5:-day}")
          url=${url//\{type\}/$type}
          local count=$(question "输入排行榜新闻数量：" "${6:-20}")
          url=${url//\{count\}/$count}
          text=$(curl -s "$url" | grep -oE '{.*}')
          # text=`cat sina.rank.json | grep -oE '{.*}'`
          debug $text
          jsonFormat='data:(标题)title|red|bold|index,(媒体)media|cyan,(链接)url,(时间)time|date'
        ;;
        # https://sinanews.sina.cn/h5/top_news_list.d.html
      esac
    ;;
  esac
  if [[ -z "$text" && -z "$url" ]]; then
    echo "没有地址" 1>&2; exit 1;
  fi
  print_json -u "$url" -s "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat" -q "${curlparams[*]}"
}

case $1 in
  -h) echo '
  weibo|wb
    groups|gps
    hotpost|hp  [category]
    userpost|up [userid] [page=1]
    hottopic|ht
    hotsearch|hs
    post|ps [postUrl|postid]
    comment|cm  [postUrl|postid]

  baidu|bd
    realtime|rt
    novel|nv
    movie|mv
    teleplay|tv
    car
    game

  zhihu|zh
    hot|ht
      hour
      day
      week
    hotsearch|hs|billboard|bb

  toutiao|tt
    hot|ht
    hotsearch|hs

  bilibili|bb
    hot|ht
    week|wk

  sogou|sg
    hotsearch|hs

  sina
    rank [category [date [type [count]]]]
    '
    ;;
  *) json_res ${@:1};;
esac

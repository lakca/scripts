#! /usr/bin/env bash

WEIBO_RESOU='https://weibo.com/ajax/side/hotSearch'

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

# 微博 #

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

WEIBO_COOKIE='XSRF-TOKEN=LJu7ywtXAMJrk23wzwPBSn4D; SUB=_2AkMUbAblf8NxqwJRmP8cym7maYVxzA_EieKiMPc-JRMxHRl-yj9jqnYTtRB6P-woCiESbtf6EHlSgKmMG7dCXC4FjogI; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9WFWfCTPhyRMY-ccV7R.KDN9; UPSTREAM-V-WEIBO-COM=35846f552801987f8c1e8f7cec0e2230; _s_tentry=-; Apache=4137248597898.631.1664186064613; SINAGLOBAL=4137248597898.631.1664186064613; ULV=1664186064653:1:1:1:4137248597898.631.1664186064613:; ariaDefaultTheme=default; ariaFixed=true; ariaReadtype=1; ariaMouseten=null; ariaStatus=false; WBPSESS=5fStQf4aE0d6e7rh9d-P6rAZHIfnn4KMIW6OYN7Abf6Gesg736Dnb_kiyOlc_BgTFoOIoutH2mmNJVt4Q03NE4SRWHVAauIsrCpR-oEcgKDRCbR6ohoMh8B8GMQkrsJdeir3sUwdnTOpVB8WJzK3tAbj0OFt2pHMIUKm8Gh-RiQ='

# 知乎 #

ZHIHU_HOT_URL='https://www.zhihu.com/billboard'
#ZHIHU_HOT_SEARCH_URL='https://www.zhihu.com/api/v4/topics/19964449/feeds/top_activity?limit=10'

ZHIHU_DOMAINS=(全部 数码 科技 互联网 商业财经 职场 教育 法律 军事 汽车 人文社科 自然科学 工程技术 情感 心理学 两性 母婴亲子 家居 健康 艺术 音乐 设计 影视娱乐 宠物 体育电竞 运动健身 动漫游戏 美食 旅行 时尚)
ZHIHU_DOMAINS_NUM=(0  100001  100002  100003  100004  100005  100006  100007  100008  100009  100010  100011  100012  100013  100014  100015  100016  100017  100018  100019  100020  100021  100022  100023  100024  100025  100026  100027  100028  100029)

function json_res() {
  local url
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
          done < <(curl -s "$url" | grep -oE '"(gid|containerid|title)":"[^"]*"' | sed -n 's/"//g;s/:/ /p')
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
          aliases=('内容' '来源' '博主' '空间' 'mid' '地址' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat='statuses:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{statuses:user.idstr}$,(地址)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
          ;;
        userpost|up)
          uid="$3"
          page=${4:-1}
          url="$WEIBO_USER_POSTS_URL"
          url="${url//\{uid\}/$uid}"
          url="${url//\{page\}/$page}"
          curlparams=('-b' "$WEIBO_COOKIE")
          aliases=('内容' '来源' '博主' '空间' 'mid' '地址' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat='data.list:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{data.list:user.idstr}$,(地址)mblogid|$https://weibo.com/{data.list:user.idstr}/{data.list:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
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
        post|ps)
          local postid="$3" # M7OL9bpQP
          if [[ $postid =~ ^http ]]; then
            local parts=(`resolveLink $3`)
            postid=${parts[@]:3:1}
          fi
          local posturl=${WEIBO_POST_URL//\{postid\}/$postid}
          text=`curl -s "$posturl"`
          aliases=('内容' '来源' '博主' '空间' 'mid' '地址' '地域');
          fields=('content' 'source' 'user' 'uid' 'mid' 'mblogid' 'region_name');
          patterns=('"text_raw":"[^"]*"' '"source":"[^"]*","favorited"' '"screen_name":"[^"]*"' '"idstr":"[^"]*","pc_new"' '"mid":"[^"]*","mblogid"' '"mblogid":"[^"]*"' '("region_name":"[^"]*",)?"customIcons"');
          indexes=(4 4 4 4 4 4 4);
          transformers=('_' '_' '_' 'https://weibo.com/u/${values[@]:3:1}' '_' 'https://weibo.com/${values[@]:3:1}/${values[@]:5:1}' '_')
          jsonFormat=':(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{:user.idstr}$,(地址)mblogid|$https://weibo.com/{:user.idstr}/{:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
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
        hot|ht|热搜)
          # https://www.zhihu.com/knowledge-plan/hot-question/hot/0/hour
          url='https://www.zhihu.com/api/v4/creators/rank/hot?domain={domain}&period={period}'
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
      esac
    ;;
    # 百度
    baidu|bd)
      url="https://top.baidu.com/board"
      case ${2:-realtime} in
        realtime|rt)
          url="$url?tab=realtime"
        ;;
        novel|nv)
          url="$url?tab=novel"
          ask "全部类型 都市 玄幻 奇幻 历史 科幻 军事 游戏 武侠 现代言情 古代言情 幻想言情 青春" "$3"
          local category=$_ASK_RESULT
          url="$url&tag={\"category\":\"$category\"}"
        ;;
        movie|mv)
          url="$url?tab=movie"
          ask "全部类型 爱情 喜剧 动作 剧情 科幻 恐怖 动画 惊悚 犯罪" "$3"
          local category=$_ASK_RESULT
          ask "全部地区 中国大陆 中国香港 中国台湾 欧美 日本 韩国" "$3"
          local country=$_ASK_RESULT
          url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
        ;;
        teleplay|tv)
          url="$url?tab=teleplay"
          ask "全部类型 爱情 搞笑 悬疑 古装 犯罪 动作 恐怖 科幻 剧情 都市" "$3"
          local category=$_ASK_RESULT
          ask "全部地区 中国大陆 中国台湾 中国香港 欧美 韩国 日本" "$3"
          local country=$_ASK_RESULT
          url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
        ;;
        car)
          url="$url?tab=car"
          ask "全部 轿车 SUV 新能源 跑车 MPV" "$3"
          local category=$_ASK_RESULT
          url="$url&tag={\"category\":\"$category\"}"
        ;;
        game)
          url="$url?tab=game"
          ask "全部类型 手机游戏 网络游戏 单机游戏" "$3"
          local category=$_ASK_RESULT
          url="$url&tag={\"category\":\"$category\"}"
        ;;
      esac
      text=$(curl -s "$url" | grep -oE '<!--s-data:.*}-->' | sed -nE 's/<!--s-data:(.*)-->/\1/p')
      aliases=(关键词 描述 地址 图片)
      fields=(query desc rawUrl img)
      patterns=('_' '_' '_' '_')
      indexes=(4 4 4 4)
      jsonFormat='data.cards.0.content:(关键词)word|red|bold|index,(描述)desc|white,(地址)rawUrl,(图片)img|image'
    ;;
    # 头条
    toutiao|tt)
      fields=(title link)
      aliases=(标题 链接)
      case ${2:=hot} in
        hot|ht)
          url='https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc';
          patterns=('"Title":"[^"]*"' '"Url":"[^"]*"');
          indexes=(4 4)
          jsonFormat='data:(标题)Title,(链接)Url,(图片)Image.url_list'
          ;;
        hs|search)
          url='https://tsearch.snssdk.com/search/suggest/hot_words/';
          patterns=('"query":"[^"]*"' '"query":"[^"]*"');
          indexes=(4 4);
          transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title')
          jsonFormat='data:(标题)query,(链接)query|$https://so.toutiao.com/search?dvpf=pc&source=trending_card&keyword={data:query}$'
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
  if [[ -z "$text" && -z "$url" ]]; then
    echo "没有地址" 1>&2; exit 1;
  fi
  print_json -u "$url" -s "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat" -q "${curlparams[*]}"
}

case $1 in
  -h) echo '
  weibo|wb
    hotsearch|hs
    hottopic|ht
    hotpost|hp  [category]
    userpost|up [userid] [page=1]
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

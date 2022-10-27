#! /usr/bin/env bash

source `dirname $0`/lib.sh

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
  local outputfile="$1"
  case $1 in
    # 微博
    weibo|wb) # 微博
      outputfile="$outputfile.$2"
      case $2 in
        groups|gps) # 分组
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
        hotpost|hp) # 热门微博
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
          jsonFormat='statuses:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{statuses:user.idstr}$,(链接)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
        ;;
        userpost|up) # 用户微博
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
        hottopic|ht) # 话题榜
          url="$WEIBO_TOPIC_URL"
          aliases=('标签' '内容' '分类' '阅读量' '讨论' '链接')
          fields=('topic' 'summary' 'category' 'read' 'mention' 'mid')
          patterns=('"topic":"[^"]*"' '"summary":"[^"]*"'  '"category":"[^"]*"' '"read":[^,]*,' '"mention":[^,]*,' '"mid":"[^"]"*')
          indexes=(4 4 4 3 3 4)
          transformers=('_' '_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.statuses:(标签)topic|red|bold|index,(内容)summary|white|dim,(分类)category,(阅读量)read|number,(讨论数)mention|number,(链接)mid|$https://s.weibo.com/weibo?q=%23{data.statuses:mid}%23$,(图片)images_url|image'
        ;;
        hotsearch|hs) # 热搜榜
          url="$WEIBO_HOT_SEARCH_URL";
          aliases=('标题' '分类' '热度' '原始热度' '链接')
          fields=('word' 'category' 'num' 'raw_hot' 'note')
          patterns=('_' '"(category|ad_type)":"[^"]*"' '"num":[^,]*,' '"raw_hot":[^,]*,' '_')
          indexes=(4 4 3 3 4)
          transformers=('_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.band_list:(标题)word|red|bold|index,(分类)category,(热度)num|number,(原始热度)raw_hot|number,(链接)note|$https://s.weibo.com/weibo?q=%23{data.band_list:word}%23$'
        ;;
        post|ps) # 微博
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
        comment|cm) # 微博评论
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
    zhihu|zh) # 知乎
      outputfile="$outputfile.$2"
      case ${2:-hs} in
        hot|ht) # 热榜 https://www.zhihu.com/knowledge-plan/hot-question/hot/0/hour
          url='https://www.zhihu.com/api/v4/creators/rank/hot?domain={domain}&period={period}&limit=50'
          fields=(title link)
          aliases=(标题 链接)
          patterns=('"title":"[^"]*"' '"url":"[^"]*"')
          indexes=(4 4)
          jsonFormat='data:(标题)question.title|red|bold|index,(链接)question.url,(时间)question.created|date,(标签)question.topics*.name'
          outputfile="$outputfile.$3"
          case ${3:-hour} in
            day) # 日榜
              url=${url//\{period\}/day}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            week) # 周榜
              url=${url//\{period\}/week}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
            hot|ht|hour) # 小时榜
              url=${url//\{period\}/hour}
              ask "${ZHIHU_DOMAINS[*]}" "$4"
              domain=$_ASK_RESULT
              url=${url//\{domain\}/${ZHIHU_DOMAINS_NUM[@]:$_ASK_INDEX:1}}
            ;;
          esac
        ;;
        hotsearch|hs|billboard|bb) # 热搜
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
    baidu|bd) # 百度
      outputfile="$outputfile.$2"
      case ${2:-hotsearch} in
        hotsearch|hs) # 热搜
          url="https://top.baidu.com/board"
          outputfile="$outputfile.$3"
          case ${3:-realtime} in
            realtime|rt) # 实时热搜
              url="$url?tab=realtime"
            ;;
            novel|nv) # 小说
              url="$url?tab=novel"
              ask "全部类型 都市 玄幻 奇幻 历史 科幻 军事 游戏 武侠 现代言情 古代言情 幻想言情 青春" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            movie|mv) # 电影
              url="$url?tab=movie"
              ask "全部类型 爱情 喜剧 动作 剧情 科幻 恐怖 动画 惊悚 犯罪" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国香港 中国台湾 欧美 日本 韩国" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            teleplay|tv) # 电视剧
              url="$url?tab=teleplay"
              ask "全部类型 爱情 搞笑 悬疑 古装 犯罪 动作 恐怖 科幻 剧情 都市" "$4"
              local category=$_ASK_RESULT
              ask "全部地区 中国大陆 中国台湾 中国香港 欧美 韩国 日本" "$4"
              local country=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\",\"country\":\"$country\"}"
            ;;
            car) # 汽车
              url="$url?tab=car"
              ask "全部 轿车 SUV 新能源 跑车 MPV" "$4"
              local category=$_ASK_RESULT
              url="$url&tag={\"category\":\"$category\"}"
            ;;
            game) # 游戏
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
    toutiao|tt) # 今日头条
      fields=(title link)
      aliases=(标题 链接)
      case ${2:-hot} in
        hot|ht) # 热榜
          url='https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc';
          patterns=('"Title":"[^"]*"' '"Url":"[^"]*"');
          indexes=(4 4)
          jsonFormat='data:(标题)Title|red|bold|index,(链接)Url,(图片)Image.url_list*.url|image'
        ;;
        hotsearch|hs) # 热搜
          url='https://tsearch.snssdk.com/search/suggest/hot_words/';
          patterns=('"query":"[^"]*"' '"query":"[^"]*"');
          indexes=(4 4);
          transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title')
          jsonFormat='data:(标题)query|red|bold|index,(链接)query|$https://so.toutiao.com/search?dvpf=pc&source=trending_card&keyword={data:query}$'
        ;;
      esac
    ;;
    # bilibili
    bilibili|bb) # bilibili
      outputfile="$outputfile.$2"
      case $2 in
        热搜|hotsearch|hs) # 热搜 https://www.bilibili.com/blackboard/activity-trending-topic.html
          url='https://app.bilibili.com/x/v2/search/trending/ranking?limit=30'
          text=$(cat bilibili.hotsearch.json)
          url=${url//\{query\}/$query}
          aliases=(关键词)
          fields=(show_name)
          indexes=(4)
          jsonFormat='data.list:(关键词)show_name'
        ;;
        搜索建议|searchsuggest|suggest) # 搜索建议
          url="https://s.search.bilibili.com/main/suggest?func=suggest&suggest_type=accurate&sub_type=tag&main_ver=v1&highlight=&userid=18358716&bangumi_acc_num=1&special_acc_num=1&topic_acc_num=1&upuser_acc_num=3&tag_num=10&special_num=10&bangumi_num=10&upuser_num=3&rnd=$(date +%s)"
          curlparams="-G --data-urlencode term={term}"
          local term=$(question '输入搜索词：' $3)
          curlparams=${curlparams//\{term\}/$term}
          aliases=(建议词)
          fields=(term)
          indexes=(4)
          jsonFormat='result.tag:(建议词)term'
        ;;
        搜索|search|s) # 搜索
          local args=($@)
          url="https://api.bilibili.com/x/web-interface/search/all/v2?__refresh__=true&page=1&page_size=42&platform=pc"
          curlparams=("-b buvid3=oc; -G")
          local keyword=$(question '输入搜索词：' $3)
          curlparams+=("--data-urlencode keyword=$keyword")
          jsonFormat='data.result|sort(key=data.result:result_type,sorts=[video,user]):(搜索结果类型)result_type,(结果列表)data|hr:(标题)title,(UP主)author,(标签)tag,(类型)typename,(项目类型)type,(链接)arcurl,(图片)upic'

          local orders=(click pubdate dm stow)
          _ASK_MSG='请输入排序（如果不需要排序，直接回车即可）：' ask "最多点击 最新发布 最多弹幕 最多收藏" $4
          local order=${orders[@]:$_ASK_INDEX:1}
          [[ $order ]] && curlparams+=("--data-urlencode order=$order")
          args[4]=$order

          local type=''
          case $5 in
            视频|video)
              type='video'
              jsonFormat='data.result:(标题)title|red|bold|index,(简介)description|white|dim,(分类)typename|magenta,(播放量)play|number,(点赞数)favorites|number,(收藏量)video_review|number,(弹幕数)danmaku|number,(UP主)author,(空间)mid|$https://space.bilibili.com/{data.result:mid}$|dim,(发布时间)pubdate|date,(链接)arcurl|dim,(图片)pic|image|dim'
            ;;
            影视|media_ft|film)
              type='media_ft'
              jsonFormat='data.result:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)styles|magenta,(地区)areas,(演职人员)staff,(媒体类型)season_type_name|magenta,(发布时间)pubdate|date,(链接)url|dim,(图片)cover|image|dim'
            ;;
            番剧|media_bangumi|anime)
              type='media_bangumi'
              jsonFormat='data.result:(标题)title|red|bold|index,(分类)styles|magenta,(地区)areas,(简介)desc|white|dim,(演职人员)staff,(媒体类型)season_type_name|magenta,(发布时间)pubdate|date,(链接)url|dim,(图片)cover|image|dim'
            ;;
            直播|live)
              type='live'
              jsonFormat='data.result:live_room:(标题)title|red|bold|index,(分类)cate_name|magenta,(标签)tag,(链接)url|dim,(图片)cover|image|dim;live_user:(UP主)uname,(分类)cate_name,(图片)cover|image|dim,(直播时间)live_time,(关注人数)attentions,(直播间)roomid|$https://live.bilibili.com/{data.result:live_user:roomid}$'
            ;;
            专栏|article)
              type='article'
              jsonFormat='data.result:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)category_name,(浏览量)view|number,(链接)id|$https://www.bilibili.com/read/cv{data.result:id}$|dim,(发布时间)pubdate|date,(图片)image_urls|image|dim'
            ;;
            话题|topic)
              type='topic'
              jsonFormat='data.result:(标题)title|red|bold|index,(UP主)author,(空间)mid$https://space.bilibili.com/{data.result:mid}$|dim,(简介)description,(描述)description,(发布时间)pubdate|date,(链接)arcurl|dim,(图片)cover|image|dim'
            ;;
            用户|bili_user|user|up)
              type='bili_user'
              jsonFormat='data.result:(UP主)uname|red|bold|index,(官方认证)official_verify.desc,(简介)usign,(视频数)videos,(链接)mid|$https://space.bilibili.com/{data.result:mid}$|dim,(头像)upic,(作品)res:(标题)title,(链接)arcurl,(发布时间)pubdate|date'
            ;;
            *)
              _ASK_MSG='请输入分类（如果不需要分类，直接回车即可）：' ask "视频 番剧 影视 直播 专栏 话题 用户"
              if [[ $_ASK_RESULT ]]; then
                args[5]=$_ASK_RESULT
                json_res "${args[@]}"
                return
              fi
            ;;
          esac
          [[ $type ]] && curlparams+=("--data-urlencode search_type=$type")
          if [[ $order || $type ]]; then
            url="https://api.bilibili.com/x/web-interface/search/type?__refresh__=true&page=1&page_size=42&platform=pc"
          fi
        ;;
        用户投稿|space|up) # 用户投稿
          url="https://api.bilibili.com/x/space/arc/search?mid={upid}&pn={PAGE}&ps={SIZE}&index=1&order={order}&order_avoided=true&jsonp=jsonp"
          curlparams='-H User-Agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36'
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
        综合热门) # 综合热门 https://www.bilibili.com/v/popular/all
          url="https://api.bilibili.com/x/web-interface/popular?ps=${SIZE:-20}&pn=${PAGE:-1}"
          jsonFormat='data.list:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim,(图片)pic|image|dim'
        ;;
        排行榜|rank) # 排行榜 https://www.bilibili.com/v/popular/rank
          local args=($@)
          outputfile="$outputfile.$3"
          local tabs=(全站 番剧 国产动画 国创相关 纪录片 动画 音乐 舞蹈 游戏 知识 科技 运动 汽车 生活 美食 动物圈 鬼畜 时尚 娱乐 影视 电影 电视剧 综艺 原创 新人)
          # 类似 https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=all'
          local jsonFormatTypeOne='data.list:(标题)title|red|bold|index,(简介)desc|white|dim,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim,(图片)pic|image|dim'
          # 类似 https://api.bilibili.com/pgc/web/rank/list?day=3&season_type=1
          local jsonFormatTypeTwo='result.list:(标题)title|red|bold|index,(徽标)badge|magenta,(更新状态)new_ep.index_show,(评分)rating|magenta,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(追番数)stat.follow|number,(总追番数)stat.series_follow|number,(链接)url,(图片)cover|image|dim'
          case $3 in
            全站) # https://www.bilibili.com/v/popular/rank/all
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            番剧) # https://www.bilibili.com/v/popular/rank/bangumi
              url='https://api.bilibili.com/pgc/web/rank/list?day=3&season_type=1'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            国产动画) # https://www.bilibili.com/v/popular/rank/guochan
              url='https://api.bilibili.com/pgc/web/rank/list?day=3&season_type=4'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            纪录片) # https://www.bilibili.com/v/popular/rank/documentary
              url='https://api.bilibili.com/pgc/season/rank/web/list?day=3&season_type=3'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            电影) # https://www.bilibili.com/v/popular/rank/movie
              url='https://api.bilibili.com/pgc/season/rank/web/list?day=3&season_type=2'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            电视剧) # https://www.bilibili.com/v/popular/rank/tv
              url='https://api.bilibili.com/pgc/season/rank/web/list?day=3&season_type=5'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            综艺) # https://www.bilibili.com/v/popular/rank/variety
              url='https://api.bilibili.com/pgc/season/rank/web/list?day=3&season_type=7'
              jsonFormat=$jsonFormatTypeTwo
            ;;
            国产相关) # https://www.bilibili.com/v/popular/rank/guochuang
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=168&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            动画) # https://www.bilibili.com/v/popular/rank/douga
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=1&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            音乐) # https://www.bilibili.com/v/popular/rank/music
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=3&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            舞蹈) # https://www.bilibili.com/v/popular/rank/dance
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=129&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            游戏) # https://www.bilibili.com/v/popular/rank/game
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=4&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            知识) # https://www.bilibili.com/v/popular/rank/knowledge
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=36&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            科技) # https://www.bilibili.com/v/popular/rank/tech
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=188&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            运动) # https://www.bilibili.com/v/popular/rank/sports
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=234&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            汽车) # https://www.bilibili.com/v/popular/rank/car
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=223&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            生活) # https://www.bilibili.com/v/popular/rank/life
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=160&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            美食) # https://www.bilibili.com/v/popular/rank/food
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=160&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            动物圈) # https://www.bilibili.com/v/popular/rank/animal
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=217&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            鬼畜) # https://www.bilibili.com/v/popular/rank/kichiku
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=119&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            时尚) # https://www.bilibili.com/v/popular/rank/fashion
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=155&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            娱乐) # https://www.bilibili.com/v/popular/rank/ent
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=5&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            影视) # https://www.bilibili.com/v/popular/rank/cinephile
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=181&type=all'
              jsonFormat=$jsonFormatTypeOne
            ;;
            原创) # https://www.bilibili.com/v/popular/rank/origin
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=origin'
              jsonFormat=$jsonFormatTypeOne
            ;;
            新人) # https://www.bilibili.com/v/popular/rank/rookie
              url='https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=rookie'
              jsonFormat=$jsonFormatTypeOne
            ;;
            *)
              ask "${tabs[*]}"
              args[2]=${tabs[@]:$_ASK_INDEX:1}
              json_res "${args[@]}"
              return
            ;;
          esac
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
        周列表|weeklist) # 周列表
          url='https://api.bilibili.com/x/web-interface/popular/series/list'
          aliases=(主题 编号 名称)
          fields=(subject number name)
          patterns=(_ '"number":[^,]*,' _)
          indexes=(4 3 4)
          transformers=(_ '\\033[0m第\\033[31m${values[@]:1:1}\\033[0m周' _)
          types=(_ _ _)
          jsonFormat=''
        ;;
        入站必刷|precious) # 入站必刷 https://www.bilibili.com/v/popular/history
          url="https://api.bilibili.com/x/web-interface/popular/precious?page_size=${SIZE:-100}&page=${PAGE:-1}"
          jsonFormat='data.list:(标题)title|red|bold|index,(简介)desc|white|dim,(成就)achievement|magenta,(分类)tname|magenta,(UP主)owner.name|${.owner.name} https://space.bilibili.com/{.owner.mid}$,(观看数)stat.view|number,(弹幕数)stat.danmaku|number,(点赞数)stat.like|number,(评论数)stat.reply|number,(链接)short_link|dim,(图片)pic|image|dim'
        ;;
        全站音乐榜) # https://www.bilibili.com/v/popular/music
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
        音乐周列表|musicweeklist)
          url='https://api.bilibili.com/x/copyright-music-publicity/toplist/all_period?list_type=1'
          aliases=(编号 发布时间)
          fields=(period publish_time)
          patterns=('"period":[^,]*,' '"publish_time":[^,]*,')
          indexes=(3 3)
          transformers=('\\033[0m第\\033[31m${values[@]:1:1}\\033[0m期' _)
          types=(_ date)
          jsonFormat=''
        ;;
      esac
    ;;
    # sogou
    sogou|sg) # 搜狗
      outputfile="$outputfile.$2"
      case ${2:-hotsearch} in
        hotsearch|hs) # 热搜 https://ie.sogou.com/top/
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
    sina) # 新浪
      outputfile="$outputfile.$2"
      case ${2:-rank} in
        rank) # 排行榜 https://sinanews.sina.cn/h5/top_news_list.d.html
          # （历史）首页 http://news.sina.com.cn/head/news20221020am.shtml
          # （历史）排行榜 https://news.sina.com.cn/hotnews/
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
          category=${categories[@]:$((_ASK_INDEX * 2 + 1)):1}
          url=${url//\{category\}/$category}
          outputfile="$outputfile.$category"
          debug $category

          local type=$(question "输入排行榜类型（可选值：day/week，分别代表日/周排行榜）：" "${5:-day}")
          url=${url//\{type\}/$type}
          outputfile="$outputfile.$type"

          local date=$(question "输入排行榜时间：" "${4:-$(date '+%Y%m%d')}")
          url=${url//\{date\}/$date}

          local count=$(question "输入排行榜新闻数量：" "${6:-20}")
          url=${url//\{count\}/$count}

          text=$(curl -s "$url" | grep -o '{.*}')
          debug $text
          aliases=(标题 媒体 链接)
          fields=(title media url)
          patterns=(_ _ _)
          indexes=(4 4 4)
          jsonFormat='data:(标题)title|red|bold|index,(媒体)media|cyan,(链接)url,(时间)time|date'
        ;;
        roll) # 滚动新闻 https://news.sina.com.cn/roll
          url="https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid=2509&k=&num=50&page=1&r=$(date +%s)&callback=jQuery111205718232756906676_$(date +%s)&_=$(date +%s)"
          text=$(curl -s "$url" | grep -o '({.*})' | sed -n 's/^.//;s/.$//;p' | tr -d '\n')
          aliases=(标题 简介 媒体 链接)
          fields=(title intro media_name url)
          patterns=(_ _ _ _)
          indexes=(4 4 4 4)
          jsonFormat='result.data:(标题)title|red|bold|index,(简介)intro|white|dim,(媒体)media_name|cyan,(链接)url,(时间)ctime|date,(图片)images*.u'
        ;;
        hot) # 热榜 https://sinanews.sina.cn/h5/top_news_list.d.html
          local categories=(top trend ent video baby car fashion trip)
          local category=$(index "${categories[*]}" "$3")
          ask "新浪热榜 潮流热榜 娱乐热榜 视频热榜 汽车热榜 育儿热榜 时尚热榜 旅游热榜" $category
          category=${categories[@]:$((_ASK_INDEX)):1}
          outputfile="$outputfile.$category"
          case ${category:-top} in
            top) # 新浪热榜
              url='https://sinanews.sina.cn/h5/top_news_list.d.html'
              text=$(curl -s $url | grep -oE '<script>SM = {.*};</script>' | sed 's/<script>SM = //;s/;<\/script>//;')
              jsonFormat='data.data.result:(标题)text|red|bold|index,(分类)queryClass|magenta,(热度)hotValue,(链接)link|dim,(图片)imgUrl|image|dim'
            ;;
            trend) # 潮流热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-trend&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.hotValue,(图片)info.pic*.url|image|dim,(链接)base.base.url'
            ;;
            ent) # 娱乐热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-ent&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(图片)info.pic*.url|image|dim,(链接)base.base.url'
            ;;
            video) # 视频热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-minivideo&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.intro,(媒体)media_info.name,(视频)stream:(链接)playUrl,(清晰度)definitionType'
            ;;
            car) # 汽车热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-auto&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            baby) # 育儿热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-mother&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            fashion) # 时尚热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-fashion&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            trip) # 旅游热榜
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-travel&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
          esac
        ;;
      esac
    ;;
  esac
  if [[ -z "$text" && -z "$url" ]]; then
    echo "没有地址" 1>&2; exit 1;
  fi
  print_json -u "$url" -s "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat" -q "${curlparams[*]}" -o "$outputfile"
}

for i in $@; do
  if [[ $i == '-h' ]]; then
    echo -e "$(cat $0 | grep -oE '^\s*[^|)( ]+(\|[^|)( ]*)*\)\s*(#.*)?$' | sed 's/    //;s/#\(.*\)/\\033[2;3;37m\1\\033[0m/;s/\([^ |)]\+\)\(|\|)\)/\\033[32m\1\\033[0m\2/g;/^\S/i\ ')"
    exit 0
  fi
done

json_res ${@:1}

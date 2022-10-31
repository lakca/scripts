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
  local -a filters
  local jsonFormat
  local curlparams
  local outputfile="$1"
  local tailer=''
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
          jsonFormat='statuses:(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{statuses:user.idstr}$,(链接)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
        ;;
        用户微博|userpost|up)
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
        话题榜|hottopic|ht)
          url="$WEIBO_TOPIC_URL"
          aliases=('标签' '内容' '分类' '阅读量' '讨论' '链接')
          fields=('topic' 'summary' 'category' 'read' 'mention' 'mid')
          patterns=('"topic":"[^"]*"' '"summary":"[^"]*"'  '"category":"[^"]*"' '"read":[^,]*,' '"mention":[^,]*,' '"mid":"[^"]"*')
          indexes=(4 4 4 3 3 4)
          transformers=('_' '_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.statuses:(标签)topic|red|bold|index,(内容)summary|white|dim,(分类)category|magenta,(阅读量)read|number,(讨论数)mention|number,(链接)mid|$https://s.weibo.com/weibo?q=%23{data.statuses:mid}%23$,(图片)images_url|image'
        ;;
        热搜榜|hotsearch|hs)
          url="$WEIBO_HOT_SEARCH_URL";
          aliases=('标题' '分类' '热度' '原始热度' '链接')
          fields=('word' 'category' 'num' 'raw_hot' 'note')
          patterns=('_' '"(category|ad_type)":"[^"]*"' '"num":[^,]*,' '"raw_hot":[^,]*,' '_')
          indexes=(4 4 3 3 4)
          transformers=('_' '_' '_' '_' 'https://s.weibo.com/weibo?q=%23${values[@]:0:1}%23')
          jsonFormat='data.band_list:(标题)word|red|bold|index,(分类)category|magenta,(热度)num|number,(原始热度)raw_hot|number,(链接)note|$https://s.weibo.com/weibo?q=%23{data.band_list:word}%23$'
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
          jsonFormat=':(内容)text_raw|red|bold|index|newline(-1),(来源)source,(博主)user.screen_name,(空间)user.idstr|$https://weibo.com/u/{:user.idstr}$,(链接)mblogid|$https://weibo.com/{:user.idstr}/{:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image'
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
          jsonFormat='data:(标题)question.title|red|bold|index,(链接)question.url,(时间)question.created|date,(标签)question.topics*.name'
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
          jsonFormat="initialState.topstory.hotList:(标题)target.titleArea.text|red|bold|index,(描述)target.excerptArea.text|white|dim,(热度)target.metricsArea.text|magenta,(链接)target.link.url,(图片)target.imageArea.url|image"
        ;;
        搜索建议|searchsuggest|ss)
          local query="$3"
          url="https://www.zhihu.com/api/v4/search/suggest?q=$query"
          jsonFormat='suggest:(关键词)query|red|bold,(链接)id|$https://www.zhihu.com/search?type=content&q={suggest:query}$'
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
          jsonFormat='data:(标题)object.title|red|bold|index,(摘录)object.excerpt|red|bold,(结果类型)object.type,(内容)object.content|white|dim,(作者)object.author.name|${data:object.author.name} https://www.zhihu.com/people/{.object.author.url_token}$,(时间)object.created_at|date,(链接)url|dim,(视频)object.video_url|dim,(图片)object.cover_url|image|dim'
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
          jsonFormat="data:(内容)target.excerpt|red|index(${INDEX_OFFSET:-0}),(问题)target.question.title|white|dim,(作者)target.author.name,(点赞数)target.voteup_count|number|magenta,(评论数)target.comment_count|number|magenta,(发布时间)target.created_time|date,(链接)target.url|dim"

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
          jsonFormat='data.cards.0.content:(关键词)word|red|bold|index,(描述)desc|white|dim,(链接)rawUrl,(图片)img|image'
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
          jsonFormat='data:(标题)Title|red|bold|index,(链接)Url,(图片)Image.url_list*.url|image'
        ;;
        热搜|hotsearch|hs)
          url='https://tsearch.snssdk.com/search/suggest/hot_words/';
          patterns=('"query":"[^"]*"' '"query":"[^"]*"');
          indexes=(4 4);
          transformers=('$title' 'https://so.toutiao.com/search?dvpf=pc\&source=trending_card\&keyword=$title')
          jsonFormat='data:(标题)query|red|bold|index,(链接)query|$https://so.toutiao.com/search?dvpf=pc&source=trending_card&keyword={data:query}$'
        ;;
      esac
    ;;
    哔哩哔哩|bilibili|bb)
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
          filters=(_ :number: _)
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
          patterns=(_ _)
          filters=(:number: :number:timestamp:)
          indexes=(3 3)
          transformers=('\\033[0m第\\033[31m${values[@]:1:1}\\033[0m期' _)
          jsonFormat=''
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
        排行榜|rank) # https://sinanews.sina.cn/h5/top_news_list.d.html
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
        滚动新闻|roll) # https://news.sina.com.cn/roll
          url="https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid=2509&k=&num=50&page=1&r=$(date +%s)&callback=jQuery111205718232756906676_$(date +%s)&_=$(date +%s)"
          text=$(curl -s "$url" | grep -o '({.*})' | sed -n 's/^.//;s/.$//;p' | tr -d '\n')
          aliases=(标题 简介 媒体 链接)
          fields=(title intro media_name url)
          patterns=(_ _ _ _)
          indexes=(4 4 4 4)
          jsonFormat='result.data:(标题)title|red|bold|index,(简介)intro|white|dim,(媒体)media_name|cyan,(链接)url,(时间)ctime|date,(图片)images*.u'
        ;;
        热榜|hot) # https://sinanews.sina.cn/h5/top_news_list.d.html
          local categories=(top trend ent video baby car fashion trip)
          local category=$(index "${categories[*]}" "$3")
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
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.hotValue,(图片)info.pic*.url|image|dim,(链接)base.base.url'
            ;;
            娱乐热榜|ent)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-ent&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(图片)info.pic*.url|image|dim,(链接)base.base.url'
            ;;
            视频热榜|video)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-minivideo&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(热度)info.intro,(媒体)media_info.name,(视频)stream:(链接)playUrl,(清晰度)definitionType'
            ;;
            汽车热榜|car)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-auto&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            育儿热榜|baby)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-mother&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            时尚热榜|fashion)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-fashion&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
            旅游热榜|trip)
              url='https://newsapp.sina.cn/api/hotlist?newsId=HB-1-snhs%2Ftop_news_list-travel&localCityCode=&wm='
              jsonFormat='data.hotList:(标题)info.title|red|bold|index,(标签)info.showTag,(热度)info.hotValue,(链接)base.base.url'
            ;;
          esac
        ;;
      esac
    ;;
    # eastmoney
    东方财富|eastmoney|em)
      outputfile=$outputfile.$2
      case $2 in
        滚动新闻|roll) # 7x24直播 http://kuaixun.eastmoney.com/
          url="https://newsapi.eastmoney.com/kuaixun/v2/api/list?callback=ajaxResult_102&column=102&limit=20&p=1&callback=kxall_ajaxResult102&_=$(date +%s)"
          text=$(curl -s $url | grep -o '{.*}')
          jsonFormat='news|reverse:(标题)title|red|bold|index,(内容)digest|white|dim,(时间)showtime,(链接)url_unique|dim'
        ;;
        最新播报|zxbb) # http://roll.eastmoney.com/
          url="https://emres.dfcfw.com/60/zxbb2018.js?callback=zxbb2018&_=$(date +%s)"
          text=$(curl -s $url | grep -o '{.*}')
          aliases=(标题 时间 链接)
          fields=(Art_Title Art_Showtime Art_UniqueUrl)
          jsonFormat='Result:(标题)Art_Title|red|bold|index,(时间)Art_Showtime,(链接)Art_UniqueUrl|white|dim'
        ;;
        国内股指|gngz)
          url="https://push2.eastmoney.com/api/qt/clist/get?pi=0&pz=10&po=1&np=1&fields=f1,f2,f3,f4,f6,f12,f13,f14&fltt=2&invt=2&ut=433fd2d0e98eaf36ad3d5001f088614d&fs=i:1.000001,i:0.399001,i:0.399006,i:1.000300,i:0.300059&cb=jQuery112408605893827100204_$(date +%s)&_=$(date +%s)"
          text=$(curl -s $url | grep -o '{.*}')
          jsonFormat='data.diff|SIMPLE:(指数)f14|red|bold|index,(点数)f2,(涨跌幅)f3|append(%)|indicator,(成交额)f6|number(cn),(代码)f12'
        ;;
        国外股指|gwgz)
          url="https://push2.eastmoney.com/api/qt/ulist.np/get?fields=f1,f2,f12,f13,f14,f3,f4,f6,f104,f152&secids=100.ATX,100.FCHI,100.GDAXI,100.HSI,100.N225,100.FTSE,100.NDX,100.DJIA&ut=13697a1cc677c8bfa9a496437bfef419&cb=jQuery112408605893827100204_$(date +%s)&_=$(date +%s)"
          text=$(curl -s $url | grep -o '{.*}')
          jsonFormat='data.diff:(指数)f14|red|bold|index,(点数)f2,(涨跌幅)f3|append(%)|indicator,(成交额)f6|number(cn),(代码)f12'
        ;;
        搜索|search|s) # https://data.eastmoney.com/xg/xg/calendar.html
          outputfile=$outputfile.$3
          case $3 in
            文章|article) # 新股日历解读 https://data.eastmoney.com/xg/xg/calendar.html
              url="https://data.eastmoney.com/dataapi/search/article?page=${PAGE:-1}&pagesize=${SIZE:-50}&keywordPhase=true&excludeChannels%5B%5D=1"
              curlparams=(-G --data-urlencode keyword=$4)
              jsonFormat='result.cmsArticleWeb:(标题)title|red|bold|index,(内容)content|white|dim,(媒体)mediaName,(时间)date,(链接)url|dim'
            ;;
          esac
        ;;
        周末消息|zmxx) # https://data.eastmoney.com/xg/xg/calendar.html
          json_res eastmoney search article '周末这些重要消息或将影响股市'
        ;;
        每日数据挖掘机|mrwj) # https://data.eastmoney.com/xg/xg/calendar.html
          json_res eastmoney search article '每日数据挖掘机'
        ;;
        今日热搜|hotkeyword|hk)
          url="https://searchapi.eastmoney.com/api/hotkeyword/get?count=${PAGE:-20}&token=32A8A21716361A5A387B0D85259A0037&cb=jQuery35108491390379066641_$(date +%s)&_=$(date +%s)"
          text=$(curl -s $url "${curlparams[@]}" | grep -o '{.*}')
          jsonFormat='Data:(关键词)KeyPhrase|red|bold|index,(链接)JumpAddress'
        ;;
        新股数据|xg) # https://data.eastmoney.com/xg/
          url="https://datacenter-web.eastmoney.com/api/data/v1/get"
          curlparams=(-G)
          curlparams+=(--data-urlencode callback=jQuery112305747392010999344_$(date +%s))
          curlparams+=(--data-urlencode pageSize=${SIZE:-50})
          curlparams+=(--data-urlencode pageNumber=${PAGE:-1})
          curlparams+=(--data-urlencode source=WEB)
          curlparams+=(--data-urlencode client=WEB)
          outputfile=$outputfile.$3
          case $3 in
            新股申购|xg) # https://data.eastmoney.com/xg/xg/default.html
              local apply_date=${4:-$(date +%Y-%m-%d)}
              curlparams+=(--data-urlencode sortColumns=APPLY_DATE,SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=1,-1)
              curlparams+=(--data-urlencode reportName=RPTA_APP_IPOAPPLY)
              curlparams+=(--data-urlencode columns=SECURITY_CODE,SECURITY_NAME,TRADE_MARKET_CODE,APPLY_CODE,TRADE_MARKET,MARKET_TYPE,ORG_TYPE,ISSUE_NUM,ONLINE_ISSUE_NUM,OFFLINE_PLACING_NUM,TOP_APPLY_MARKETCAP,PREDICT_ONFUND_UPPER,ONLINE_APPLY_UPPER,PREDICT_ONAPPLY_UPPER,ISSUE_PRICE,LATELY_PRICE,CLOSE_PRICE,APPLY_DATE,BALLOT_NUM_DATE,BALLOT_PAY_DATE,LISTING_DATE,AFTER_ISSUE_PE,ONLINE_ISSUE_LWR,INITIAL_MULTIPLE,INDUSTRY_PE_NEW,OFFLINE_EP_OBJECT,CONTINUOUS_1WORD_NUM,TOTAL_CHANGE,PROFIT,LIMIT_UP_PRICE,INFO_CODE,OPEN_PRICE,LD_OPEN_PREMIUM,LD_CLOSE_CHANGE,TURNOVERRATE,LD_HIGH_CHANG,LD_AVERAGE_PRICE,OPEN_DATE,OPEN_AVERAGE_PRICE,PREDICT_PE,PREDICT_ISSUE_PRICE2,PREDICT_ISSUE_PRICE,PREDICT_ISSUE_PRICE1,PREDICT_ISSUE_PE,PREDICT_PE_THREE,ONLINE_APPLY_PRICE,MAIN_BUSINESS,PAGE_PREDICT_PRICE1,PAGE_PREDICT_PRICE2,PAGE_PREDICT_PRICE3,PAGE_PREDICT_PE1,PAGE_PREDICT_PE2,PAGE_PREDICT_PE3,SELECT_LISTING_DATE,IS_BEIJING,INDUSTRY_PE_RATIO)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE~NEWEST_PRICE)
              curlparams+=(-d quoteType=0)
              curlparams+=(--data-urlencode filter="(APPLY_DATE>'$apply_date')")

              jsonFormat='result.data:(证券名称)SECURITY_NAME|${.SECURITY_NAME} {.SECURITY_CODE}$|red|bold|index,(主营业务)MAIN_BUSINESS|white|dim,(申购日期)APPLY_DATE,(上市日期)LISTING_DATE,(连续一字板数量)CONTINUOUS_1WORD_NUM|cyan,(涨幅)TOTAL_CHANGE,(中签获利)PROFIT|number,(发行价)ISSUE_PRICE|magenta,(预测发行价)PREDICT_ISSUE_PRICE|${.PREDICT_ISSUE_PRICE}/{.PREDICT_ISSUE_PRICE1}/{.PREDICT_ISSUE_PRICE2}$,(市盈率)AFTER_ISSUE_PE,(发行市盈率)AFTER_ISSUE_PE,(行业市盈率)INDUSTRY_PE_NEW,(预测发行市盈率)PREDICT_ISSUE_PE,(预测市盈率)PREDICT_PE,(链接)SECURITY_CODE|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
            IPO审核|ipo) # https://data.eastmoney.com/xg/ipo
              curlparams+=(--data-urlencode sortColumns=UPDATE_DATE,ORG_CODE)
              curlparams+=(--data-urlencode sortTypes=-1,-1)
              curlparams+=(--data-urlencode reportName=RPT_IPO_INFOALLNEW)
              curlparams+=(--data-urlencode columns=SECURITY_CODE,STATE,REG_ADDRESS,INFO_CODE,CSRC_INDUSTRY,ACCEPT_DATE,DECLARE_ORG,PREDICT_LISTING_MARKET,LAW_FIRM,ACCOUNT_FIRM,ORG_CODE,UPDATE_DATE,RECOMMEND_ORG)
              local markets=(科创板 创业板 上海主板 深圳主板 北交所)
              _ASK_MSG='请输入板块（不指定板块回车即可）：' ask "${markets[*]}" $4
              local market=$_ASK_RESULT
              [[ $market ]] && curlparams+=(--data-urlencode filter="(PREDICT_LISTING_MARKET=\"$market\")")

              jsonFormat='result.data:(企业名称)DECLARE_ORG|red|bold|index,(行业)CSRC_INDUSTRY|white|dim,(拟上市板块)PREDICT_LISTING_MARKET|cyan,(状态)STATE|magenta,(更新日期)UPDATE_DATE,(受理日期)ACCEPT_DATE,(链接)SECURITY_CODE|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
            打新收益|dxsy) # https://data.eastmoney.com/xg/xg/dxsyl.html
              curlparams+=(--data-urlencode sortColumns=LISTING_DATE,SECURITY_CODE)
              curlparams+=(--data-urlencode sortTypes=-1,-1)
              curlparams+=(--data-urlencode reportName=RPTA_APP_IPOAPPLY)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE,f14~01~SECURITY_CODE)
              curlparams+=(--data-urlencode quoteType=0)
              curlparams+=(--data-urlencode columns=ALL)
              curlparams+=(--data-urlencode filter="((APPLY_DATE>'2010-01-01')(|@APPLY_DATE=\"NULL\"))((LISTING_DATE>'2010-01-01')(|@LISTING_DATE=\"NULL\"))(TRADE_MARKET_CODE!=\"069001017\")")

              jsonFormat='result.data:(证券名称)SECURITY_NAME|${.SECURITY_NAME} {.SECURITY_CODE}$|red|bold|index,(主营业务)MAIN_BUSINESS|white|dim,(行业)INDUSTRY_NAME|white|dim,(上市日期)LISTING_DATE,(开盘溢价)LD_OPEN_PREMIUM|number(+)|append(%)|indicator,(首日最高)LD_HIGH_CHANG|number(+)|append(%)|indicator,(首日收盘)LD_CLOSE_CHANGE|number(+)|append(%)|indicator,(链接)SECURITY_CODE|$https://data.eastmoney.com/zcz/cyb/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
            增发|qbzf) #
              curlparams+=(--data-urlencode sortColumns=ISSUE_DATE)
              curlparams+=(--data-urlencode sortTypes=-1)
              curlparams+=(--data-urlencode reportName=RPT_SEO_DETAIL)
              curlparams+=(--data-urlencode columns=ALL)
              curlparams+=(--data-urlencode quoteColumns=f2~01~SECURITY_CODE~NEW_PRICE)
              curlparams+=(--data-urlencode quoteType=0)

              jsonFormat='result.data:(证券名称)SECURITY_NAME_ABBR|${.SECURITY_NAME_ABBR} {.SECURITY_CODE}$|red|bold|index,(主营业务)MAIN_BUSINESS|white|dim,(增发方式)ISSUE_WAY|magenta,(增发用途)FUND_FOR|magenta|dim,(增发数量)ISSUE_NUM|number(cn),(增发价格)ISSUE_PRICE,(增发上市日期)ISSUE_ON_DATE,(链接)SECURITY_CODE|$https://data.eastmoney.com/stockdata/{.SECURITY_CODE}.html$|dim,(招股说明书)INFO_CODE|$https://pdf.dfcfw.com/pdf/H2_{.INFO_CODE}_1.pdf$|dim'
            ;;
          esac
          text=$(curl -s $url "${curlparams[@]}" | grep -o '{.*}')
        ;;
        财经日历|cjrl) # https://data.eastmoney.com/cjrl/default.html
          local today=$(date +%Y-%m-%d)
          local end_date=$(date -v+1m +%Y-%m-%d)
          outputfile=$outputfile.$3
          case $3 in
            财经会议|cjhy) # https://data.eastmoney.com/cjrl/default.html
              url="https://datacenter-web.eastmoney.com/api/data/v1/get?callback=datatable$(random 7)&reportName=RPT_CPH_FECALENDAR&pageNumber=${PAGE:-1}&pageSize=${SIZE:-50}&sortColumns=START_DATE&sortTypes=1&filter=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%27$end_date%27)(STD_TYPE_CODE%3D%221%22)&source=WEB&client=WEB&columns=START_DATE%2CEND_DATE%2CFE_CODE%2CFE_NAME%2CFE_TYPE%2CCONTENT%2CSTD_TYPE_CODE%2CSPONSOR_NAME%2CCITY&_=$(date +%s)"
              text=$(curl -s $url | grep -o '{.*}')
              jsonFormat='result.data:(会议名称)FE_NAME|red|bold|index,(会议类型)FE_TYPE|magenta,(主办单位)SPONSOR_NAME,(开始时间)START_DATE,(结束时间)END_DATE,(会议地点)CITY,(会议内容)CONTENT|white|dim'
            ;;
            经济数据|jjsj) # https://data.eastmoney.com/cjrl/default.html
              url="https://datacenter-web.eastmoney.com/api/data/v1/get?callback=datatable$(random 7)&reportName=RPT_CPH_FECALENDAR&pageNumber=${PAGE:-1}&pageSize=${SIZE:-50}&sortColumns=START_DATE&sortTypes=1&filter=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%27$end_date%27)(STD_TYPE_CODE%3D%222%22)&source=WEB&client=WEB&columns=START_DATE%2CEND_DATE%2CFE_CODE%2CFE_NAME%2CFE_TYPE%2CCONTENT%2CSTD_TYPE_CODE%2CSPONSOR_NAME%2CCITY&_=$(date +%s)"
              text=$(curl -s $url | grep -o '{.*}')
              jsonFormat='result.data:(数据名称)FE_NAME|red|bold|index,(数据类型)FE_TYPE|magenta,(公布时间)START_DATE,(地区)CITY'
            ;;
            其他日程|qtrc) # https://data.eastmoney.com/cjrl/default.html
              url="https://datacenter-web.eastmoney.com/api/data/v1/get?callback=datatable$(random 7)&reportName=RPT_CPH_FECALENDAR&pageNumber=${PAGE:-1}&pageSize=${SIZE:-50}&sortColumns=START_DATE&sortTypes=1&filter=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%27$end_date%27)(STD_TYPE_CODE%3D%223%22)&source=WEB&client=WEB&columns=START_DATE%2CEND_DATE%2CFE_CODE%2CFE_NAME%2CFE_TYPE%2CCONTENT%2CSTD_TYPE_CODE%2CSPONSOR_NAME%2CCITY&_=$(date +%s)"
              text=$(curl -s $url | grep -o '{.*}')
              jsonFormat='result.data:(名称)FE_NAME|red|bold|index,(时间)START_DATE'
            ;;
          esac
        ;;
      esac
    ;;
  esac
  if [[ -z "$text" && -z "$url" ]]; then
    echo "没有地址" 1>&2; exit 1;
  fi
  print_json -u "$url" -s "$text" -a "${aliases[*]}" -f "${fields[*]}" -p "${patterns[*]}" -i "${indexes[*]}" -t "${transformers[*]}" -j "$jsonFormat" -q "${curlparams[*]}" -o "$outputfile" -y "${filters[*]}"

  # printf %s "tailer: $tailer" 1>&2
  if [[ $tailer ]]; then
    eval $tailer
  fi
}

for i in $@; do
  if [[ $i == '-h' ]]; then
    echo -e "$(cat $0 | grep -oE '^\s*[^|)( ]+(\|[^|)( ]*)*\)\s*(#.*)?$' | sed 's/    //;s/#\(.*\)/\\033[2;3;37m\1\\033[0m/;s/\([^ |)]\+\)\(|\|)\)/\\033[32m\1\\033[0m\2/g;/^\S/i\ ')"
    exit 0
  fi
done

json_res ${@:1}

# console.log([...new URL().searchParams.entries()].map(e => `curlparams+=(--data-urlencode ${e[0]}=${e[1]})`).join('\n'))

#!/bin/bash
curl 'https://s.weibo.com/top/summary?Refer=top_hot&topnav=1&wvr=6' \
  -H 'cookie: login_sid_t=e209dcee7a5a3e52f24b4b615da4cfe4; cross_origin_proto=SSL; PC_TOKEN=982f516fac; SUB=_2AkMUS4DGf8NxqwJRmf4dxWnibYt1zw7EieKiF3EdJRMxHRl-yT9jql4ztRB6P8uuKTeyGQ7jGCESF8CqfkJmjrZnZd9v; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9WF4VUMWr7cwiXmHLTNg6r1_; _s_tentry=-; Apache=1602442885083.3218.1662455796634; SINAGLOBAL=1602442885083.3218.1662455796634; ULV=1662455796828:1:1:1:1602442885083.3218.1662455796634:' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36' \
  --compressed

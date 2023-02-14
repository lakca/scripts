import json
import os
import sys

sys.path.append(os.path.dirname(__file__))

from lib import tokenize, Pipe

types = "火箭发射 8201 快速反弹 8202 大笔买入 8193 封涨停板 4 打开跌停板 32 有大买盘 64 竞价上涨 8207 高开5日线 8209 向上缺口 8211 60日新高 8213 60日大幅上涨 8215"

jsonFormat = (
    "data.allstock|TABLE:(时间)tm|date(time,from=%H%M%S)|cyan,(链接)url|$http://quote.eastmoney.com/unify/r/{.m}.{.c}$|dim,(异动情况统计)ydl|HIDE_IN_TABLE:(类型)t|map(bash:arr="
    + types
    + ",bash:arrdim=2,bash:arridx=0)|indicator(exp=in,bash:arr="
    + types
    + "),(次数)ct"
)

print(json.dumps(tokenize(jsonFormat).data, indent=2))

print(Pipe.indicator(Pipe.format("-0.5", "%")))

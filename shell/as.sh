#! /bin/bash

source $(dirname $0)/prelude.sh

stamp=`date +%s`
jsonp=jQuery112408605893827100204_$stamp

GS_NODE_HELPERS="$GS_NODE_HELPERS;
Object.assign(FILTERS, {
  indicateColor(v) {
    return useFilter(v, v > 0 ? 'red' : v < 0 ? 'green' : '')
  },
})
"

function send() {
  [[ $GI_VERBOSE -gt 0 ]] && echo "curl -s $@" | red 1>&2;
  [[ $GI_VERBOSE -gt 1 ]] && curl -v $@ || curl -s $@;
}

function getToken() {
  local file=`dirname $0`/cache
  local token
  if [ -f $file ]; then
    token=`sed -n 's/^estoken://p' $file` 
  fi
  if [ -n "$token" ]; then
    printf "$token"
  else
    token=`invoke 'token' -R | grep -m 1 -oE '"[0-9A-F]{32}"' | head -1 | xargs`
    if [ -n "$token" ]; then
      echo "estoken:$token" > $file
      printf "$token"
    else
      echo "token not found"
      exit 1
    fi
  fi
}

function ask() {
  case "$1" in
    *@TOKEN)
      TOKEN="$(getToken)"
      ;;
  esac
}

define -n 'token' -p 'https://emcharts.dfcfw.com/suggest/stocksuggest2017.min.js'

# {
#   "Code": "300059",
#   "Name": "东方财富",
#   "PinYin": "DFCF",
#   "ID": "3000592",
#   "JYS": "80",
#   "Classify": "AStock",
#   "MarketType": "2",
#   "SecurityTypeName": "深A",
#   "SecurityType": "2",
#   "MktNum": "0",
#   "TypeUS": "80",
#   "QuoteID": "0.300059",
#   "UnifiedCode": "300059",
#   "InnerCode": "10581294001978"
# },
define -n 'search' -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=14&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'QuotationCodeTable.Data:SecurityTypeName,Code,PinYin,Name'

# {
#   "ShortName": "东方财富",
#   "Url": "http://guba.eastmoney.com/list,300059.html",
#   "OuterCode": "300059",
#   "HeadCharacter": "dfcf",
#   "RelatedCode": "300059"
# }
define -n 'search:guba' -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=8&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'GubaCodeTable.Data:OuterCode,HeadCharacter,Url,ShortName'

define -n 'xxx' -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=16%2C43%2C38%2C35%2C501%2C2%2C7%2C3&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'QuotationCodeTable.Data:SecurityTypeName,Code,PinYin,Name'

# {
#   "Art_Title": "昇兴股份：2021年净利同比预增1117%-1233%",
#   "Art_Code": "202201212257099936",
#   "Art_Url": "http://finance.eastmoney.com/news/1354,202201212257099936.html",
#   "Art_UniqueUrl": "http://finance.eastmoney.com/a/202201212257099936.html",
#   "Art_Showtime": "2022-01-21 18:05:40"
# }
# 最新播报
define -n 'zxbb' -p "https://emres.dfcfw.com/60/zxbb2018.js?callback=zxbb2018&_=$stamp"\
  -v "JSONP:zxbb2018"\
  -f 'Result:Art_Showtime,Art_UniqueUrl,Art_Title'

# {
#   f1: 2
#   f2: 3522.57
#   f3: -0.91
#   f4: -32.49
#   f12: "000001"
#   f13: 1
#   f14: "上证指数"
# }
# 国内股市
define -n 'market' -p "https://push2.eastmoney.com/api/qt/clist/get?pi=0&pz=10&po=1&np=1&fields=f1,f2,f3,f4,f12,f13,f14&fltt=2&invt=2&ut=433fd2d0e98eaf36ad3d5001f088614d&fs=i:1.000001,i:0.399001,i:0.399006,i:1.000300,i:0.300059&cb=$jsonp&_=$stamp"\
  -v "JSONP:$jsonp"\
  -f 'data.diff:f2,f3|indicateColor,f4|indicateColor,f12,f14'

CMDS_MSG="$CMDS_MSG
          token
          search
          search:guba
          xxx
          zxbb
          market
"

function parseCmds() {
  case $1 in
    token) getToken;;
    *) invoke "$@";;
  esac
}
parseArgs "$@"


# searchModule: function(t, e, n) {
#     if ("searchall" == e)
#         return h.resolve({
#             key: t
#         });
#     var a = [];
#     switch (e) {
#     case "stock":
#         a = [14];
#         break;
#     case "guba":
#         a = [8];
#         break;
#     case "user":
#         a = [2, 7];
#         break;
#     case "group":
#         a = [3];
#         break;
#     case "module":
#         a = [16, 43, 38, 35, 501, 2, 7, 3];
#         break;
#     case "info":
#         a = this.getInfoModules(n.infomodules)
#     }
#     var i = 1;
#     return "stock" == e && (i = n.stockcount),
#     "guba" == e && (i = n.gubacount),
#     s.getdata2({
#         key: t,
#         types: a,
#         count: i,
#         filter: n.filter
#     })
# },

# curl 'https://searchapi.eastmoney.com/api/suggest/get?cb=jQuery112408605893827100204_1642735968060&input=dfc&type=14&token=D43BF722C8E33BDC906FB84D85E326E8&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=5&_=1642735968089' \
#   -H 'Connection: keep-alive' \
#   -H 'Pragma: no-cache' \
#   -H 'Cache-Control: no-cache' \
#   -H 'sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="97", "Chromium";v="97"' \
#   -H 'sec-ch-ua-mobile: ?0' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36' \
#   -H 'sec-ch-ua-platform: "macOS"' \
#   -H 'Accept: */*' \
#   -H 'Sec-Fetch-Site: same-site' \
#   -H 'Sec-Fetch-Mode: no-cors' \
#   -H 'Sec-Fetch-Dest: script' \
#   -H 'Referer: https://www.eastmoney.com/' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
#   -H 'Cookie: HAList=a-sh-601233-%u6850%u6606%u80A1%u4EFD; qgqp_b_id=c1eed7a455c20746fbcca97bf923dd73; st_si=04995025220768; st_pvi=04207278575540; st_sp=2021-09-06%2014%3A53%3A38; st_inirUrl=https%3A%2F%2Fwww.baidu.com%2Flink; st_sn=3; st_psi=20220121113256803-111000300841-1402358517; st_asi=20220121113256803-111000300841-1402358517-Web_so_srk-3' \
#   --compressed

# curl 'https://searchapi.eastmoney.com/api/suggest/get?cb=jQuery112408605893827100204_1642735968080&input=dfc&type=8&token=D43BF722C8E33BDC906FB84D85E326E8&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=4&_=1642735968090' \
#   -H 'Connection: keep-alive' \
#   -H 'Pragma: no-cache' \
#   -H 'Cache-Control: no-cache' \
#   -H 'sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="97", "Chromium";v="97"' \
#   -H 'sec-ch-ua-mobile: ?0' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36' \
#   -H 'sec-ch-ua-platform: "macOS"' \
#   -H 'Accept: */*' \
#   -H 'Sec-Fetch-Site: same-site' \
#   -H 'Sec-Fetch-Mode: no-cors' \
#   -H 'Sec-Fetch-Dest: script' \
#   -H 'Referer: https://www.eastmoney.com/' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
#   -H 'Cookie: HAList=a-sh-601233-%u6850%u6606%u80A1%u4EFD; qgqp_b_id=c1eed7a455c20746fbcca97bf923dd73; st_si=04995025220768; st_pvi=04207278575540; st_sp=2021-09-06%2014%3A53%3A38; st_inirUrl=https%3A%2F%2Fwww.baidu.com%2Flink; st_sn=3; st_psi=20220121113256803-111000300841-1402358517; st_asi=20220121113256803-111000300841-1402358517-Web_so_srk-3' \
#   --compressed

# curl 'https://searchapi.eastmoney.com/api/suggest/get?cb=jQuery112408605893827100204_1642735968062&input=dfc&type=16%2C43%2C38%2C35%2C501%2C2%2C7%2C3&token=D43BF722C8E33BDC906FB84D85E326E8&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=1&_=1642735968091' \
#   -H 'Connection: keep-alive' \
#   -H 'Pragma: no-cache' \
#   -H 'Cache-Control: no-cache' \
#   -H 'sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="97", "Chromium";v="97"' \
#   -H 'sec-ch-ua-mobile: ?0' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36' \
#   -H 'sec-ch-ua-platform: "macOS"' \
#   -H 'Accept: */*' \
#   -H 'Sec-Fetch-Site: same-site' \
#   -H 'Sec-Fetch-Mode: no-cors' \
#   -H 'Sec-Fetch-Dest: script' \
#   -H 'Referer: https://www.eastmoney.com/' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
#   -H 'Cookie: HAList=a-sh-601233-%u6850%u6606%u80A1%u4EFD; qgqp_b_id=c1eed7a455c20746fbcca97bf923dd73; st_si=04995025220768; st_pvi=04207278575540; st_sp=2021-09-06%2014%3A53%3A38; st_inirUrl=https%3A%2F%2Fwww.baidu.com%2Flink; st_sn=3; st_psi=20220121113256803-111000300841-1402358517; st_asi=20220121113256803-111000300841-1402358517-Web_so_srk-3' \
#   --compressed

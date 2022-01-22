#! /bin/bash

source $(dirname $0)/prelude.sh

stamp=`date +%s`
jsonp=jQuery112408605893827100204_$stamp
jsonp2=datatable${stamp:0:7}
today=`date +%Y-%m-%d`
nextMonth=`gdate -d '1 month' +%Y-%m-%d`
ut=`js 'process.stdout.write(crypto.randomBytes(16).toString("hex"));' -i ''`

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
      TOKEN="$(token)"
      ;;
  esac
}

define -N '获取token' -n 'token'\
  -p 'https://emcharts.dfcfw.com/suggest/stocksuggest2017.min.js'

# 基础

# 首页
# https://www.eastmoney.com

define -N '搜索证券' -n 'search'\
  -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=14&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'QuotationCodeTable.Data:SecurityTypeName,Code,PinYin,Name'

define -N '搜索股吧' -n 'search:guba'\
  -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=8&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'GubaCodeTable.Data:OuterCode,HeadCharacter,Url,ShortName'

define -n 'xxx'\
  -p "https://searchapi.eastmoney.com/api/suggest/get?cb=$jsonp&input=\$INPUT&type=16%2C43%2C38%2C35%2C501%2C2%2C7%2C3&token=\$TOKEN&markettype=&mktnum=&jys=&classify=&securitytype=&status=&count=\$SIZE&_=$stamp"\
  -a 'TOKEN!,INPUT!;t:i:' -v "JSONP:$jsonp"\
  -f 'QuotationCodeTable.Data:SecurityTypeName,Code,PinYin,Name'

define -N '最新播报' -n 'zxbb'\
  -p "https://emres.dfcfw.com/60/zxbb2018.js?callback=zxbb2018&_=$stamp"\
  -v "JSONP:zxbb2018"\
  -f 'Result:Art_Showtime,Art_UniqueUrl,Art_Title|red'

define -N '国内主要股指' -n 'market'\
  -p "https://push2.eastmoney.com/api/qt/clist/get?pi=0&pz=10&po=1&np=1&fields=f1,f2,f3,f4,f12,f13,f14&fltt=2&invt=2&ut=433fd2d0e98eaf36ad3d5001f088614d&fs=i:1.000001,i:0.399001,i:0.399006,i:1.000300,i:0.300059&cb=$jsonp&_=$stamp"\
  -v "JSONP:$jsonp"\
  -f 'data.diff:f2,f3|indicateColor,f4|indicateColor,f12,f14|red'

define -N '外国主要股指' -n 'market:foreign'\
  -p "https://push2.eastmoney.com/api/qt/ulist.np/get?fields=f1,f2,f12,f13,f14,f3,f4,f6,f104,f152&secids=100.ATX,100.FCHI,100.GDAXI,100.HSI,100.N225,100.FTSE,100.NDX,100.DJIA&ut=13697a1cc677c8bfa9a496437bfef419&cb=$jsonp&_=$stamp"\
  -v "JSONP:$jsonp"\
  -f 'data.diff:f2,f3|indicateColor,f4|indicateColor,f12,f14|red'

# 数据中心

## 财经日历

### 会议数据, https://data.eastmoney.com/cjrl/default.html
define -N '财经日历-会议数据-财经会议' -n 'cjrl:cjhy'\
  -p "https://datacenter-web.eastmoney.com/api/data/get?callback=\$JSONP&type=RPT_CPH_FECALENDAR&p=\$PAGE&ps=\$SIZE&st=START_DATE&sr=1&filter=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%3D%27\$END_DATE%27)(STD_TYPE_CODE%3D%221%22)&f1=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%3D%27\$END_DATE%27)&f2=(STD_TYPE_CODE%3D%221%22)&source=WEB&client=WEB&sty=START_DATE%2CEND_DATE%2CFE_CODE%2CFE_NAME%2CFE_TYPE%2CCONTENT%2CSTD_TYPE_CODE%2CSPONSOR_NAME%2CCITY&_=$stamp"\
  -a 'END_DATE!,PAGE,SIZE;e:P:S:'\
  -v "JSONP:$jsonp2" -v "END_DATE:$nextMonth" -v "PAGE:1" -v "SIZE:50"\
  -f 'result.data:START_DATE|date,END_DATE|date,CITY|red,FE_TYPE|red,FE_NAME|red,SPONSOR_NAME|red'

define -N '财经日历-会议数据-重要经济数据' -n 'cjrl:zyjjsj'\
  -p "https://datacenter-web.eastmoney.com/api/data/get?callback=\$JSONP&type=RPT_CPH_FECALENDAR&p=\$PAGE&ps=\$SIZE&st=START_DATE&sr=1&filter=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%3D%27\$END_DATE%27)(STD_TYPE_CODE%3D%222%22)&f1=(END_DATE%3E%3D%27$today%27)(START_DATE%3C%3D%27\$END_DATE%27)&f2=(STD_TYPE_CODE%3D%222%22)&source=WEB&client=WEB&sty=START_DATE%2CEND_DATE%2CFE_CODE%2CFE_NAME%2CFE_TYPE%2CCONTENT%2CSTD_TYPE_CODE%2CSPONSOR_NAME%2CCITY&_=$stamp"\
  -a 'END_DATE!,PAGE,SIZE;e:P:S:'\
  -v "JSONP:$jsonp2" -v "END_DATE:$nextMonth" -v "PAGE:1" -v "SIZE:50"\
  -f 'result.data:START_DATE|date,END_DATE|date,CITY|red,FE_TYPE|red,FE_NAME|red,SPONSOR_NAME|red'

### 大事提醒, https://data.eastmoney.com/dcrl/dashi.html?date=2022-01-27
define -N '财经日历-大事提醒-' -n 'cjrl:dstx' -p "https://data.eastmoney.com/dataapi/dcrl/dstx?fromdate=\$DATE&todate=\$DATE&option=xsap,xgsg,tfpxx,hsgg,nbjb,jjsj,hyhy,gddh"\
  -a 'DATE;D:'\
  -v "DATE:$today"\
  -f "xsap.0=休市安排:mkt,sdate,edate,holiday,xs;xgsg.0.Data.kzz=可转债申购:Sname,Scode;xgsg.0.Data.xg=新股申购:Sname,Scode;hsgg.0.Data=沪深公告:Sname,Scode;nbjb.0.Data=年报季报:ReportType,Securities<>;jjsj=经济数据:City,Data<>;hyhy=行业会议:START_DATE|date,END_DATE|date,CITY,SPONSOR_NAME,E_TYPE,FE_NAME;gddh.0.Data=股东大会:Sname,Scode"

### 休市安排, https://data.eastmoney.com/dcrl/close.html
define -N '财经日历-中国休市日历' -n 'cjrl:zgxsrl' -p "https://datacenter-web.eastmoney.com/api/data/get?type=RPTA_WEB_ZGXSRL&sty=ALL&ps=\$SIZE&st=sdate&sr=-1&callback=\$JSONP&_=$stamp"\
  -a 'SIZE;S:'\
  -v "JSONP:$jsonp" -v "SIZE:200"\
  -f 'result.data:sdate|date,edate|date,mkt,holiday|red'

CMDS_MSG="$CMDS_MSG
          token
          search
          search:guba
          xxx
          zxbb
          market
"

function parseCmds() {
  local args=("${@:2}")
  case $1 in
    token) shift; token "$@";;
    *) invoke "$@";;
  esac
}
parseArgs "$@"


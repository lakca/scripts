#! /usr/bin/env bash

source `dirname $0`/lib.sh

function indicate() {
  local v=7
  [[ $2 > $3 ]] && v=1
  [[ $2 < $3 ]] && v=2
  echo -e "\033[3${v}m$1\033[0m"
}

function quote() {
  IFS=',' read -r -a alertHighPrices <<< "$QUOTE_ALERT_HIGH_PRICES"
  IFS=',' read -r -a alertLowPrices <<< "$QUOTE_ALERT_LOW_PRICES"
  IFS=',' read -r -a alertHighPercents <<< "$QUOTE_ALERT_HIGH_PERCENTS"
  IFS=',' read -r -a alertLowPercents <<< "$QUOTE_ALERT_LOW_PERCENTS"
  local prices=($PRICES)

  local url="https://hq.sinajs.cn/list=$1"
  local list=($(curl -s "$url" -H 'Referer:http://finance.sina.com.cn/' | iconv -f gb18030 -t utf8 | cut -d '"' -f2))
  # https://www.jianshu.com/p/fabe3811a01d
  local keys=(name open close price high low buy sell volume amount bv1 bp1 bv2 bp2 bv3 bp3 bv4 bp4 bv5 bp5 sv1 sp1 sv2 sp2 sv3 sp3 sv4 sp4 sv5 sp5 date time)
  local aliases=(名称 开盘价 收盘价 当前价 最高价 最低价 买一价 卖一价 成交量 成交额 买一量 买一价 买二量 买二价 买三量 买三价 买四量 买四价 买五量 买五价 买一量 卖一价 卖二量 卖二价 卖三量 卖三价 卖四量 卖四价 卖五量 卖五价 日期 时间)

  local result=''
  [[ ${#prices[@]} ]] && result=$result"\033[$((1 + ${#prices[@]}))A\033[2K\033[1A\n"
  result=$result'\033[2;37m名称 幅度 价格 成交额 时间\033[0m\n'
  for i in ${!list[@]}; do
    fields=($(sed "s/,/ /g" <<< "${list[@]:$i:1}"))
    name=${fields[@]:0:1}
    open=${fields[@]:1:1}
    close=${fields[@]:2:1}
    price=${fields[@]:3:1}
    amount=${fields[@]:9:1}
    time=${fields[@]:31:1}
    percent=$(bc <<< "scale=2;100*($price-$close)/$close")
    percentText=$(printf "%+.2f" $percent)%
    result=$result"$(indicate $name $open $close) $(indicate $percentText $price $close) $(indicate $price $price ${prices[@]:$i:1}) $(printf "%'.0f" $amount) $time\n"
    prices[$i]=$price
    [[ $i == 0 ]] && echo -en "\033];$percentText\007"

    local alertHighPrice=${alertHighPrices[@]:$i:1}
    local alertLowPrice=${alertLowPrices[@]:$i:1}
    local alertHighPercent=${alertHighPercents[@]:$i:1}
    local alertLowPercent=${alertLowPercents[@]:$i:1}
    local script=''
    if [[ $alertHighPrice && 1 -eq $(bc <<< "$price >= $alertHighPrice") ]]; then
      script="display notification (\"预警：涨超${alertHighPrice}；现价：$price\" as Unicode text) with title (\"📈\" as Unicode text) subtitle (\"$name\" as Unicode text)"
    fi
    if [[ $alertLowPrice && 1 -eq $(bc <<< "$price <= $alertLowPrice") ]]; then
      script="display notification (\"预警：跌超${alertLowPrice}；现价：$price\" as Unicode text) with title (\"📉\" as Unicode text) subtitle (\"$name\" as Unicode text)"
    fi
    if [[ $alertHighPercent && 1 -eq $(bc <<< "$percent >= $alertHighPercent") ]]; then
      script="display notification (\"预警：涨超${alertHighPercent}；现价：$price\" as Unicode text) with title (\"📈\" as Unicode text) subtitle (\"$name\" as Unicode text)"
    fi
    if [[ $alertLowPercent && 1 -eq $(bc <<< "$percent <= $alertLowPercent") ]]; then
      script="display notification (\"预警：跌超${alertLowPercent}；现价：$price\" as Unicode text) with title (\"📉\" as Unicode text) subtitle (\"$name\" as Unicode text)"
    fi
    [[ $script ]] && osascript -e "$script"
  done
  echo -en $result | tabulate -f plain
  sleep 1
  PRICES="${prices[*]}" quote $*
}

QUOTE_ALERT_LOW_PRICES=",17.22" quote sh000001,sz300556,sh600352,sh600678
